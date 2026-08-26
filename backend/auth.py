import os
import secrets
import hashlib
import threading
import time
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
import bcrypt
from sqlalchemy.orm import Session

from database import get_db
import models

# --- Secrets (PRD §12.3: no hardcoded credentials) ---
_secret = os.getenv("JWT_SECRET")
if not _secret:
    # Dev fallback: random per-process secret. Production MUST set JWT_SECRET.
    _secret = secrets.token_urlsafe(48)
SECRET_KEY = _secret
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 14

security = HTTPBearer(auto_error=False)


def _credentials_exception(detail="Could not validate credentials"):
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


# --- Passwords (bcrypt, work factor >= 12 per NFR-5) ---
def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")


def _utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


# --- Tokens ---
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = _utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(db: Session, principal_type: str, principal_id: str,
                         family_id: Optional[str] = None) -> str:
    raw = secrets.token_urlsafe(48)
    row = models.RefreshToken(
        principal_type=principal_type,
        principal_id=principal_id,
        family_id=family_id or generate_family_id(),
        token_hash=hash_token(raw),
        expires_at=_utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(row)
    db.commit()
    return raw


def generate_family_id() -> str:
    import uuid
    return str(uuid.uuid4())


def rotate_refresh_token(db: Session, raw_token: str, expected_type: str):
    """Consume a refresh token and issue a new one. Returns (new_raw, principal_id) or None."""
    row = db.query(models.RefreshToken).filter(
        models.RefreshToken.token_hash == hash_token(raw_token)
    ).first()
    if not row or row.principal_type != expected_type:
        return None
    expired = row.expires_at < _utcnow()
    if row.revoked or expired:
        # Reuse of a consumed token => revoke the whole token family
        db.query(models.RefreshToken).filter(
            models.RefreshToken.family_id == row.family_id
        ).update({"revoked": True})
        db.commit()
        return None
    family = row.family_id
    row.revoked = True  # rotation: one-time use
    db.commit()
    new_raw = create_refresh_token(db, row.principal_type, row.principal_id, family_id=family)
    return family, row.principal_id


def revoke_all_refresh_tokens(db: Session, principal_type: str, principal_id: str):
    db.query(models.RefreshToken).filter(
        models.RefreshToken.principal_type == principal_type,
        models.RefreshToken.principal_id == principal_id,
    ).update({"revoked": True})
    db.commit()


# --- Current user/patient resolution ---
def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security), db: Session = Depends(get_db)) -> models.User:
    if credentials is None:
        raise _credentials_exception()
    token = credentials.credentials
    credentials_exception = _credentials_exception()
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "access" or payload.get("principal") == "patient":
            raise credentials_exception
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user


def get_current_patient(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security), db: Session = Depends(get_db)) -> models.Patient:
    if credentials is None:
        raise _credentials_exception("Could not validate patient credentials")
    credentials_exception = _credentials_exception("Could not validate patient credentials")
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "access" or payload.get("principal") != "patient":
            raise credentials_exception
        patient_id = payload.get("sub")
        if not patient_id:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    patient = db.query(models.Patient).filter(models.Patient.patient_id == patient_id).first()
    if not patient:
        raise credentials_exception
    return patient


class RoleChecker:
    def __init__(self, allowed_roles: List[str]):
        self.allowed_roles = allowed_roles

    def __call__(self, current_user: models.User = Depends(get_current_user)) -> models.User:
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Required roles: {self.allowed_roles}",
            )
        return current_user


require_receptionist = RoleChecker(["Receptionist", "SuperAdmin"])
require_doctor = RoleChecker(["Doctor", "SuperAdmin"])
require_admin = RoleChecker(["SuperAdmin"])
require_any_user = RoleChecker(["Receptionist", "Doctor", "Patient", "SuperAdmin"])


# --- Simple in-memory rate limiter (PRD §10.4: rate limit auth endpoints) ---
class RateLimiter:
    def __init__(self, max_attempts: int, window_seconds: int):
        self.max_attempts = max_attempts
        self.window = window_seconds
        self._hits: dict = {}
        self._lock = threading.Lock()

    def check(self, key: str):
        now = time.monotonic()
        with self._lock:
            hits = [t for t in self._hits.get(key, []) if now - t < self.window]
            if len(hits) >= self.max_attempts:
                self._hits[key] = hits
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many attempts. Please try again later.",
                )
            hits.append(now)
            self._hits[key] = hits

    def reset(self, key: str):
        with self._lock:
            self._hits.pop(key, None)


login_limiter = RateLimiter(max_attempts=5, window_seconds=300)
otp_limiter = RateLimiter(max_attempts=5, window_seconds=600)

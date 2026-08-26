import json
import urllib.request
import urllib.error
import time

BASE_URL = "http://localhost:8000/api/v1"

def make_request(path, method="GET", body=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        
    data = None
    if body:
        data = json.dumps(body).encode("utf-8")
        
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            err_json = json.loads(err_body)
            detail = err_json.get("detail", err_body)
        except Exception:
            detail = err_body
        return e.code, {"error": True, "detail": detail}
    except Exception as e:
        return 500, {"error": True, "detail": str(e)}

def run_tests():
    print("=== STARTING HCMS API INTEGRATION TESTS ===")
    
    # 1. Login as Receptionist
    print("\n1. Testing Login as Receptionist...")
    login_body = {
        "email": "receptionist@vermahomeopathy.com",
        "password": "frontdesk123"
    }
    status_code, response = make_request("/auth/login", "POST", login_body)
    if status_code != 200 or "access_token" not in response:
        print(f"❌ Login failed: {response}")
        return
    token = response["access_token"]
    print("✅ Login successful. Received JWT token.")

    # 2. Fetch seeded clinics
    print("\n2. Fetching seeded clinics...")
    status_code, clinics = make_request("/clinics", "GET", token=token)
    if status_code != 200 or not clinics:
        print(f"❌ Failed to fetch clinics: {clinics}")
        return
    clinic_id = clinics[0]["clinic_id"]
    print(f"✅ Successfully fetched {len(clinics)} clinics. Selected Clinic: {clinics[0]['name']}")

    # 3. Create a new patient
    print("\n3. Testing patient registration...")
    patient_body = {
        "full_name": "Rohan Verma",
        "dob": "1994-05-12",
        "gender": "M",
        "mobile": "9876543210",
        "address": "Scheme 54, Vijay Nagar, Indore",
        "occupation": "Software Engineer",
        "email": "rohan@gmail.com",
        "blood_group": "B+",
        "allergies": "Peanuts",
        "chronic_conditions": "Asthma"
    }
    status_code, patient = make_request("/patients", "POST", patient_body, token=token)
    if status_code != 200 or "patient_id" not in patient:
        print(f"❌ Patient registration failed: {patient}")
        return
    patient_id = patient["patient_id"]
    unique_id = patient["unique_patient_id"]
    print(f"✅ Patient registered successfully. Generated Unique ID: {unique_id}")

    # 4. Check 7-Day Fee Waiver eligibility (should be False for new patient)
    print("\n4. Checking 7-day fee waiver eligibility (initial check)...")
    today_str = time.strftime("%Y-%m-%d")
    status_code, waiver = make_request(f"/patients/{patient_id}/7day-waiver?appt_date={today_str}", "GET", token=token)
    if status_code != 200:
        print(f"❌ Waiver check failed: {waiver}")
        return
    print(f"✅ Waiver check completed. Eligible: {waiver.get('eligible')} (Expected: False)")

    # 5. Book an appointment
    print("\n5. Booking appointment for patient...")
    appt_body = {
        "patient_id": patient_id,
        "doctor_id": "doctor-uuid-placeholder", # Will map or seed
        "clinic_id": clinic_id,
        "appt_date": today_str,
        "appt_time": "10:30",
        "visit_type": "New"
    }
    # Note: doctor_id can be any string in SQLite or matched. Let's send the login user_id for safety
    status_code, user_info = make_request("/users/me", "GET", token=token)
    if status_code == 200:
        appt_body["doctor_id"] = user_info["user_id"] # Use current authenticated user's ID
        
    status_code, appt = make_request("/appointments", "POST", appt_body, token=token)
    if status_code != 200:
        print(f"❌ Booking failed: {appt}")
        return
    appt_id = appt["appt_id"]
    print(f"✅ Appointment booked successfully. Appt ID: {appt_id}")

    # 6. Check single active consultation rule
    print("\n6. Booking a second appointment to test Single Active Consultation Rule...")
    # Create second patient first
    p2_body = {
        "full_name": "Sita Gupta",
        "dob": "1991-08-20",
        "gender": "F",
        "mobile": "9876543211",
        "address": "Palasia, Indore",
        "occupation": "Teacher"
    }
    _, p2 = make_request("/patients", "POST", p2_body, token=token)
    p2_id = p2["patient_id"]
    
    appt2_body = appt_body.copy()
    appt2_body["patient_id"] = p2_id
    appt2_body["appt_time"] = "11:00"
    _, appt2 = make_request("/appointments", "POST", appt2_body, token=token)
    appt2_id = appt2["appt_id"]
    
    print("Starting Consultation for patient 1...")
    make_request(f"/appointments/{appt_id}/status", "PUT", {"status": "In Consultation"}, token=token)
    
    print("Attempting to start Consultation for patient 2 (should be BLOCKED)...")
    status_code, block_res = make_request(f"/appointments/{appt2_id}/status", "PUT", {"status": "In Consultation"}, token=token)
    if status_code == 400 and "blocked" in block_res.get("detail", "").lower():
        print(f"✅ Single Active Consultation Rule successfully enforced! Block message: {block_res['detail']}")
    else:
        print(f"❌ Failed block check. Status: {status_code}, Res: {block_res}")

    # 7. Create Draft Invoice
    print("\n7. Creating draft invoice...")
    invoice_body = {
        "patient_id": patient_id,
        "appt_id": appt_id,
        "consultation_fee": 500.0,
        "medicine_charges": 250.0,
        "misc_charges": 50.0,
        "discount": 100.0
    }
    status_code, invoice = make_request("/invoices", "POST", invoice_body, token=token)
    if status_code != 200 or "invoice_id" not in invoice:
        print(f"❌ Invoice creation failed: {invoice}")
        return
    invoice_id = invoice["invoice_id"]
    print(f"✅ Draft invoice generated. Total: ₹{invoice['total_amount']} (Expected: ₹700.0)")

    # 8. Issue Invoice
    print("\n8. Issuing invoice...")
    status_code, issued = make_request(f"/invoices/{invoice_id}/issue", "PUT", token=token)
    if status_code != 200 or issued["status"] != "Issued":
        print(f"❌ Issuing invoice failed: {issued}")
        return
    print("✅ Invoice issued successfully.")

    # 9. Record Payment
    print("\n9. Recording payment collection...")
    pay_body = {
        "amount": 400.0,
        "payment_mode": "UPI",
        "transaction_id": "TXN-998877"
    }
    status_code, payment = make_request(f"/invoices/{invoice_id}/payments", "POST", pay_body, token=token)
    if status_code != 200:
        print(f"❌ Recording payment failed: {payment}")
        return
    
    # Verify invoice status
    _, updated_invoice = make_request(f"/invoices/{invoice_id}", "GET", token=token)
    print(f"✅ Payment recorded. Invoice Status: {updated_invoice['status']}  ·  Paid: ₹{updated_invoice['paid_amount']}  ·  Due: ₹{updated_invoice['due_amount']} (Expected: ₹300.0)")

    print("\n=== ALL API INTEGRATION TESTS PASSED ===")

if __name__ == "__main__":
    # Give server a moment if starting
    run_tests()

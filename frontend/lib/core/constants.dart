import 'package:flutter/material.dart';

/// Canonical domain constants (PRD §5.3.2, §5.5.4, §5.6.3).
/// Single source of truth for status strings shared with the backend.
class AppointmentStatus {
  static const scheduled = 'Scheduled';
  static const confirmed = 'Confirmed';
  static const arrived = 'Arrived';
  static const inConsultation = 'In Consultation';
  static const completed = 'Completed';
  static const noShow = 'No-Show';
  static const cancelled = 'Cancelled';
}

/// Queue board columns map to appointment statuses (PRD §5.4.1).
class QueueColumn {
  static const waiting = AppointmentStatus.arrived; // "Waiting" == Arrived
  static const inConsultation = AppointmentStatus.inConsultation;
  static const completed = AppointmentStatus.completed;
  static const noShow = AppointmentStatus.noShow;
}

class InvoiceStatus {
  static const draft = 'Draft';
  static const issued = 'Issued';
  static const partiallyPaid = 'Partially Paid';
  static const paid = 'Paid';
}

class VisitType {
  static const newVisit = 'New';
  static const followUp = 'Follow-Up';
  static const walkIn = 'Walk-In';

  static const all = [newVisit, followUp, walkIn];
}

class PaymentMode {
  static const cash = 'Cash';
  static const card = 'Card';
  static const upi = 'UPI';
  static const online = 'Online';

  static const all = [cash, card, upi, online];
}

class UserRoles {
  static const receptionist = 'Receptionist';
  static const doctor = 'Doctor';
  static const patient = 'Patient';
  static const superAdmin = 'SuperAdmin';
}

// ─── Shorthand palette (used by all dashboards & portal) ──────
const cBg       = Color(0xFFF8FAFC);
const cCard     = Color(0xFFFFFFFF);
const cBorder   = Color(0x1A000000);
const cFg       = Color(0xFF0F172A);
const cMuted    = Color(0xFF717182);
const cMutedBg  = Color(0xFFECECF0);
const cAccent   = Color(0xFFE9EBEF);
const cPrimary  = Color(0xFF0F766E);

const cAmber50  = Color(0xFFFFFBEB);
const cAmber200 = Color(0xFFFDE68A);
const cAmber700 = Color(0xFFB45309);
const cBlue50   = Color(0xFFEFF6FF);
const cBlue100  = Color(0xFFDBEAFE);
const cBlue200  = Color(0xFFBFDBFE);
const cBlue700  = Color(0xFF1D4ED8);
const cEm50     = Color(0xFFECFDF5);
const cEm100    = Color(0xFFD1FAE5);
const cEm200    = Color(0xFFA7F3D0);
const cEm600    = Color(0xFF059669);
const cEm700    = Color(0xFF047857);
const cRed50    = Color(0xFFFEF2F2);
const cRed100   = Color(0xFFFEE2E2);
const cRed600   = Color(0xFFDC2626);
const cSlate50  = Color(0xFFF8FAFC);
const cSlate100 = Color(0xFFF1F5F9);
const cSlate200 = Color(0xFFE2E8F0);
const cSlate400 = Color(0xFF94A3B8);
const cSlate600 = Color(0xFF475569);
const cPurple50 = Color(0xFFFAF5FF);
const cPurple100= Color(0xFFEDE9FE);
const cPurple700= Color(0xFF7E22CE);

/// Shared palette extracted from the duplicated per-file color blocks.
class AppColors {
  static const bg = Color(0xFFF8FAFC);
  static const sidebar = Color(0xFF0F172A);
  static const cardBorder = Color(0xFFE2E8F0);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const primary = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const green100 = Color(0xFFDCFCE7);
  static const green600 = Color(0xFF16A34A);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber700 = Color(0xFFB45309);
  static const red100 = Color(0xFFFEE2E2);
  static const red600 = Color(0xFFDC2626);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue700 = Color(0xFF1D4ED8);
  static const violet100 = Color(0xFFEDE9FE);
  static const violet700 = Color(0xFF6D28D9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
}

Color statusColor(String status) {
  switch (status) {
    case AppointmentStatus.scheduled:
    case InvoiceStatus.draft:
      return AppColors.slate400;
    case AppointmentStatus.confirmed:
      return AppColors.blue700;
    case AppointmentStatus.arrived:
      return AppColors.amber700;
    case AppointmentStatus.inConsultation:
      return AppColors.primary;
    case AppointmentStatus.completed:
    case InvoiceStatus.paid:
      return AppColors.green600;
    case AppointmentStatus.noShow:
    case AppointmentStatus.cancelled:
      return AppColors.red600;
    case InvoiceStatus.issued:
      return AppColors.blue700;
    case InvoiceStatus.partiallyPaid:
      return AppColors.amber700;
    default:
      return AppColors.textMuted;
  }
}

Color statusBg(String status) {
  final c = statusColor(status);
  if (c == AppColors.green600) return AppColors.green100;
  if (c == AppColors.amber700) return AppColors.amber100;
  if (c == AppColors.red600) return AppColors.red100;
  if (c == AppColors.blue700) return AppColors.blue100;
  if (c == AppColors.primary) return AppColors.violet100;
  return AppColors.slate200;
}

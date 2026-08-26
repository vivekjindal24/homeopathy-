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

  static const all = [scheduled, confirmed, arrived, inConsultation, completed, noShow, cancelled];
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

  static const all = [draft, issued, partiallyPaid, paid];
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
  static const orange500 = Color(0xFFF97316);
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

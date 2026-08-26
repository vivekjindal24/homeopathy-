import 'package:flutter/material.dart';
import 'constants.dart';

// --- Parse helpers ---
double parseAmount(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String shortId(String? id) => (id != null && id.length >= 8) ? id.substring(0, 8) : (id ?? '—');

// --- Reusable button widgets ---
Widget smallBtn(String label, Color bg, Color fg, VoidCallback onTap) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(6),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  ),
);

Widget primaryBtn(String label, IconData? icon, VoidCallback onTap) => ElevatedButton(
  onPressed: onTap,
  style: ElevatedButton.styleFrom(
    backgroundColor: cPrimary, foregroundColor: Colors.white, elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  ),
  child: icon != null
    ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label)])
    : Text(label),
);

Widget outlineBtn(String label, IconData? icon, VoidCallback onTap) => OutlinedButton(
  onPressed: onTap,
  style: OutlinedButton.styleFrom(
    foregroundColor: cFg, side: const BorderSide(color: cBorder),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
  child: icon != null
    ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label)])
    : Text(label),
);

Widget settingsRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(children: [
    SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 11, color: cMuted))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
  ]),
);

// ─── Reusable Search Field ──────────────────────────────────
Widget searchField({
  required String hint,
  required ValueChanged<String> onChanged,
  double width = 240,
}) {
  return SizedBox(
    width: width,
    height: 34,
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 11, color: cFg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11, color: cMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 14, color: cMuted),
        filled: true,
        fillColor: cMutedBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: cBorder), borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

// ─── Client-side Patient Filter ─────────────────────────────
List<dynamic> filterPatientsLocal(List<dynamic> patients, String query) {
  if (query.isEmpty) return patients;
  final q = query.toLowerCase();
  return patients.where((p) {
    final name = (p['full_name'] ?? '').toString().toLowerCase();
    final mobile = (p['mobile_number'] ?? p['mobile'] ?? '').toString().toLowerCase();
    return name.contains(q) || mobile.contains(q);
  }).toList();
}

import { useState } from "react";
import { Toaster } from "sonner";

/* ── Admin (Doctor) imports ── */
import { Sidebar, NavKey } from "./components/hcms/sidebar";
import { TopBar } from "./components/hcms/topbar";
import { AdminDashboard } from "./components/hcms/dashboard";
import { PatientsScreen } from "./components/hcms/patients";
import { AppointmentsScreen } from "./components/hcms/appointments";
import { ConsultationScreen } from "./components/hcms/consultation";
import { PrescriptionsScreen } from "./components/hcms/prescriptions";
import { BillingScreen } from "./components/hcms/billing";
import {
  InventoryScreen,
  ReportsScreen,
  AuditScreen,
  NotificationsScreen,
  SettingsScreen,
  PaymentsScreen,
  ExpensesScreen,
} from "./components/hcms/other-screens";

/* ── Receptionist imports ── */
import { ReceptionistSidebar, ReceptionistTopBar, RNavKey } from "./components/hcms/receptionist-layout";
import { ReceptionistDashboard } from "./components/hcms/receptionist-dashboard";
import { ReceptionistQueue } from "./components/hcms/receptionist-queue";
import { ReceptionistBillingScreen, ReceptionistPaymentsScreen } from "./components/hcms/receptionist-billing";
import {
  ReceptionistPatientsScreen,
  ReceptionistAppointmentsScreen,
  ReceptionistInventoryScreen,
  ReceptionistReportsScreen,
  ReceptionistNotificationsScreen,
  ReceptionistSettingsScreen,
} from "./components/hcms/receptionist-screens";

/* ─── Role Selection ─────────────────────────────────── */
type Role = "admin" | "receptionist" | null;

function RoleSelection({ onSelect }: { onSelect: (role: "admin" | "receptionist") => void }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-teal-50/30 to-blue-50/40 flex flex-col items-center justify-center p-6">
      {/* Brand */}
      <div className="mb-10 text-center">
        <div className="w-16 h-16 rounded-2xl bg-primary text-primary-foreground flex items-center justify-center mx-auto mb-4 shadow-lg shadow-primary/20">
          <svg viewBox="0 0 24 24" fill="none" className="w-9 h-9" stroke="currentColor" strokeWidth={1.5}>
            <path d="M4.5 12.75l6 6 9-13.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-foreground tracking-tight">Verma Homeopathy Clinic</h1>
        <p className="text-sm text-muted-foreground mt-1.5">Clinic OS · Indore · Healthcare Management System</p>
      </div>

      {/* Role Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-2xl">
        {/* Doctor Card */}
        <button
          onClick={() => onSelect("admin")}
          className="group relative bg-card border border-border rounded-2xl p-8 text-left hover:border-primary/40 hover:shadow-xl hover:shadow-primary/10 transition-all duration-200 overflow-hidden"
        >
          <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
          <div className="relative">
            <div className="w-14 h-14 rounded-xl bg-primary/10 text-primary flex items-center justify-center mb-5 group-hover:bg-primary group-hover:text-white transition-colors">
              <svg viewBox="0 0 24 24" fill="none" className="w-7 h-7" stroke="currentColor" strokeWidth={1.5}>
                <path d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <h2 className="text-xl font-bold text-foreground mb-1.5">Doctor / Admin</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">Full clinical access — consultations, prescriptions, analytics, billing management, and system administration.</p>
            <div className="mt-5 flex flex-wrap gap-1.5">
              {["Consultations", "Prescriptions", "Analytics", "Admin"].map(tag => (
                <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-primary/10 text-primary font-medium">{tag}</span>
              ))}
            </div>
            <div className="mt-5 flex items-center gap-2 text-sm font-medium text-primary">
              Open Doctor Portal
              <svg viewBox="0 0 24 24" fill="none" className="w-4 h-4 group-hover:translate-x-1 transition-transform" stroke="currentColor" strokeWidth={2}>
                <path d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
        </button>

        {/* Receptionist Card */}
        <button
          onClick={() => onSelect("receptionist")}
          className="group relative bg-card border border-border rounded-2xl p-8 text-left hover:border-blue-400/40 hover:shadow-xl hover:shadow-blue-500/10 transition-all duration-200 overflow-hidden"
        >
          <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
          <div className="relative">
            <div className="w-14 h-14 rounded-xl bg-blue-500/10 text-blue-600 flex items-center justify-center mb-5 group-hover:bg-blue-500 group-hover:text-white transition-colors">
              <svg viewBox="0 0 24 24" fill="none" className="w-7 h-7" stroke="currentColor" strokeWidth={1.5}>
                <path d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <h2 className="text-xl font-bold text-foreground mb-1.5">Receptionist</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">Front-desk operations — patient registration, appointments, queue management, billing, and inventory.</p>
            <div className="mt-5 flex flex-wrap gap-1.5">
              {["Queue", "Appointments", "Billing", "Inventory"].map(tag => (
                <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-600 font-medium">{tag}</span>
              ))}
            </div>
            <div className="mt-5 flex items-center gap-2 text-sm font-medium text-blue-600">
              Open Receptionist Portal
              <svg viewBox="0 0 24 24" fill="none" className="w-4 h-4 group-hover:translate-x-1 transition-transform" stroke="currentColor" strokeWidth={2}>
                <path d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
        </button>
      </div>

      <p className="mt-8 text-xs text-muted-foreground">HCMS v2.0 · Verma Homeopathy · Indore</p>
    </div>
  );
}

/* ─── Admin titles ───────────────────────────────────── */
const adminTitles: Record<NavKey, { title: string; subtitle: string }> = {
  dashboard: { title: "Admin Dashboard", subtitle: "Operations overview" },
  patients: { title: "Patients", subtitle: "Registry & profiles" },
  appointments: { title: "Appointments", subtitle: "Schedule & queue" },
  consultations: { title: "Consultation", subtitle: "Case taking · Visit in progress" },
  prescriptions: { title: "Prescriptions", subtitle: "Digital Rx · A5 print-ready" },
  billing: { title: "Billing", subtitle: "Invoice & payment collection" },
  payments: { title: "Payments", subtitle: "Collections & refunds" },
  inventory: { title: "Inventory", subtitle: "Pharmacy stock & batches" },
  expenses: { title: "Expenses", subtitle: "Operational ledger" },
  reports: { title: "Reports", subtitle: "Analytics & financial oversight" },
  notifications: { title: "Notifications", subtitle: "Alerts & system messages" },
  audit: { title: "Audit Logs", subtitle: "Immutable event trail" },
  settings: { title: "Settings", subtitle: "Configuration & user management" },
};

/* ─── Receptionist titles ───────────────────────────── */
const receptionistTitles: Record<RNavKey, { title: string; subtitle: string }> = {
  dashboard: { title: "Receptionist Dashboard", subtitle: "Command center · Front desk overview" },
  patients: { title: "Patients", subtitle: "Registry, profiles & history" },
  appointments: { title: "Appointments", subtitle: "Schedule, walk-ins & calendar" },
  queue: { title: "Queue Management", subtitle: "Real-time patient flow board" },
  billing: { title: "Billing & Invoices", subtitle: "Invoice builder & collection" },
  payments: { title: "Payments", subtitle: "Collections, modes & refund requests" },
  inventory: { title: "Inventory", subtitle: "Medicine stock & movements" },
  reports: { title: "Reports", subtitle: "Day-end summary & analytics" },
  notifications: { title: "Notifications", subtitle: "Alerts & system messages" },
  settings: { title: "Settings", subtitle: "Profile & preferences" },
};

/* ─── Admin Portal ───────────────────────────────────── */
function AdminPortal({ onSwitchRole }: { onSwitchRole: () => void }) {
  const [active, setActive] = useState<NavKey>("dashboard");
  const meta = adminTitles[active];

  return (
    <div className="min-h-screen bg-background text-foreground flex">
      <Sidebar active={active} onChange={setActive} />
      <div className="flex-1 min-w-0 flex flex-col">
        <TopBar title={meta.title} subtitle={meta.subtitle} />
        <main className="flex-1 min-w-0">
          {active === "dashboard" && <AdminDashboard />}
          {active === "patients" && <PatientsScreen />}
          {active === "appointments" && <AppointmentsScreen />}
          {active === "consultations" && <ConsultationScreen />}
          {active === "prescriptions" && <PrescriptionsScreen />}
          {active === "billing" && <BillingScreen />}
          {active === "payments" && <PaymentsScreen />}
          {active === "inventory" && <InventoryScreen />}
          {active === "expenses" && <ExpensesScreen />}
          {active === "reports" && <ReportsScreen />}
          {active === "notifications" && <NotificationsScreen />}
          {active === "audit" && <AuditScreen />}
          {active === "settings" && <SettingsScreen />}
        </main>
      </div>
    </div>
  );
}

/* ─── Receptionist Portal ────────────────────────────── */
function ReceptionistPortal({ onSwitchRole }: { onSwitchRole: () => void }) {
  const [active, setActive] = useState<RNavKey>("dashboard");
  const meta = receptionistTitles[active];

  return (
    <div className="min-h-screen bg-background text-foreground flex">
      <ReceptionistSidebar active={active} onChange={setActive} onRoleSwitch={onSwitchRole} />
      <div className="flex-1 min-w-0 flex flex-col">
        <ReceptionistTopBar title={meta.title} subtitle={meta.subtitle} />
        <main className="flex-1 min-w-0">
          {active === "dashboard" && <ReceptionistDashboard onNav={setActive} />}
          {active === "patients" && <ReceptionistPatientsScreen />}
          {active === "appointments" && <ReceptionistAppointmentsScreen />}
          {active === "queue" && <ReceptionistQueue />}
          {active === "billing" && <ReceptionistBillingScreen />}
          {active === "payments" && <ReceptionistPaymentsScreen />}
          {active === "inventory" && <ReceptionistInventoryScreen />}
          {active === "reports" && <ReceptionistReportsScreen />}
          {active === "notifications" && <ReceptionistNotificationsScreen />}
          {active === "settings" && <ReceptionistSettingsScreen />}
        </main>
      </div>
    </div>
  );
}

/* ─── Root ───────────────────────────────────────────── */
export default function App() {
  const [role, setRole] = useState<Role>(null);

  return (
    <>
      <Toaster position="top-right" richColors closeButton />
      {!role && <RoleSelection onSelect={setRole} />}
      {role === "admin" && <AdminPortal onSwitchRole={() => setRole(null)} />}
      {role === "receptionist" && <ReceptionistPortal onSwitchRole={() => setRole(null)} />}
    </>
  );
}

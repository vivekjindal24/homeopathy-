import {
  LayoutDashboard,
  Users,
  CalendarDays,
  Stethoscope,
  FileText,
  Receipt,
  Wallet,
  Package,
  TrendingDown,
  BarChart3,
  Bell,
  ShieldCheck,
  Settings,
  Activity,
} from "lucide-react";
import { cn } from "../ui/utils";

export type NavKey =
  | "dashboard"
  | "patients"
  | "appointments"
  | "consultations"
  | "prescriptions"
  | "billing"
  | "payments"
  | "inventory"
  | "expenses"
  | "reports"
  | "notifications"
  | "audit"
  | "settings";

const groups: { label: string; items: { key: NavKey; label: string; icon: any }[] }[] = [
  {
    label: "Overview",
    items: [{ key: "dashboard", label: "Dashboard", icon: LayoutDashboard }],
  },
  {
    label: "Clinical",
    items: [
      { key: "patients", label: "Patients", icon: Users },
      { key: "appointments", label: "Appointments", icon: CalendarDays },
      { key: "consultations", label: "Consultations", icon: Stethoscope },
      { key: "prescriptions", label: "Prescriptions", icon: FileText },
    ],
  },
  {
    label: "Finance",
    items: [
      { key: "billing", label: "Billing / Invoices", icon: Receipt },
      { key: "payments", label: "Payments / Refunds", icon: Wallet },
      { key: "inventory", label: "Inventory", icon: Package },
      { key: "expenses", label: "Expenses", icon: TrendingDown },
    ],
  },
  {
    label: "Operations",
    items: [
      { key: "reports", label: "Reports", icon: BarChart3 },
      { key: "notifications", label: "Notifications", icon: Bell },
      { key: "audit", label: "Audit Logs", icon: ShieldCheck },
      { key: "settings", label: "Settings", icon: Settings },
    ],
  },
];

export function Sidebar({
  active,
  onChange,
}: {
  active: NavKey;
  onChange: (k: NavKey) => void;
}) {
  return (
    <aside className="w-60 shrink-0 border-r border-border bg-card flex flex-col h-screen sticky top-0">
      <div className="px-4 py-4 border-b border-border flex items-center gap-2.5">
        <div className="w-8 h-8 rounded-md bg-primary text-primary-foreground flex items-center justify-center">
          <Activity className="w-4 h-4" />
        </div>
        <div className="leading-tight">
          <div className="text-sm">Verma Homeopathy</div>
          <div className="text-xs text-muted-foreground">Clinic OS · Indore</div>
        </div>
      </div>
      <nav className="flex-1 overflow-y-auto py-3 px-2">
        {groups.map((g) => (
          <div key={g.label} className="mb-4">
            <div className="px-2 py-1 text-[11px] uppercase tracking-wider text-muted-foreground">
              {g.label}
            </div>
            <ul className="mt-1 space-y-0.5">
              {g.items.map((it) => {
                const Icon = it.icon;
                const isActive = active === it.key;
                return (
                  <li key={it.key}>
                    <button
                      onClick={() => onChange(it.key)}
                      className={cn(
                        "w-full flex items-center gap-2.5 px-2.5 py-2 rounded-md text-sm transition-colors",
                        isActive
                          ? "bg-accent text-accent-foreground"
                          : "text-foreground/80 hover:bg-muted",
                      )}
                    >
                      <Icon className={cn("w-4 h-4", isActive && "text-primary")} />
                      <span>{it.label}</span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>
      <div className="px-3 py-3 border-t border-border text-xs text-muted-foreground flex items-center gap-2">
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
        Synced · 2s ago
      </div>
    </aside>
  );
}

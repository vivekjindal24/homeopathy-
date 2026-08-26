import {
  LayoutDashboard,
  Users,
  CalendarDays,
  ListOrdered,
  Receipt,
  Wallet,
  Package,
  BarChart3,
  Bell,
  Settings,
  Activity,
  Search,
  ChevronDown,
  LogOut,
} from "lucide-react";
import { cn } from "../ui/utils";
import { useState } from "react";

export type RNavKey =
  | "dashboard"
  | "patients"
  | "appointments"
  | "queue"
  | "billing"
  | "payments"
  | "inventory"
  | "reports"
  | "notifications"
  | "settings";

const navGroups: { label: string; items: { key: RNavKey; label: string; icon: any }[] }[] = [
  {
    label: "Overview",
    items: [{ key: "dashboard", label: "Dashboard", icon: LayoutDashboard }],
  },
  {
    label: "Front Desk",
    items: [
      { key: "patients", label: "Patients", icon: Users },
      { key: "appointments", label: "Appointments", icon: CalendarDays },
      { key: "queue", label: "Queue Management", icon: ListOrdered },
    ],
  },
  {
    label: "Finance",
    items: [
      { key: "billing", label: "Billing & Invoices", icon: Receipt },
      { key: "payments", label: "Payments", icon: Wallet },
    ],
  },
  {
    label: "Clinic",
    items: [
      { key: "inventory", label: "Inventory", icon: Package },
      { key: "reports", label: "Reports", icon: BarChart3 },
      { key: "notifications", label: "Notifications", icon: Bell },
      { key: "settings", label: "Settings", icon: Settings },
    ],
  },
];

export function ReceptionistSidebar({
  active,
  onChange,
  onRoleSwitch,
}: {
  active: RNavKey;
  onChange: (k: RNavKey) => void;
  onRoleSwitch: () => void;
}) {
  return (
    <aside className="w-60 shrink-0 border-r border-border bg-card flex flex-col h-screen sticky top-0">
      <div className="px-4 py-4 border-b border-border">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-md bg-primary text-primary-foreground flex items-center justify-center">
            <Activity className="w-4 h-4" />
          </div>
          <div className="leading-tight flex-1 min-w-0">
            <div className="text-sm font-medium truncate">Verma Homeopathy</div>
            <div className="text-xs text-muted-foreground">Receptionist Portal</div>
          </div>
        </div>
        <div className="mt-3 flex items-center gap-2 bg-blue-50 border border-blue-100 rounded-md px-2.5 py-1.5">
          <div className="w-5 h-5 rounded-full bg-blue-500 text-white flex items-center justify-center text-[10px] font-bold">P</div>
          <div className="flex-1 min-w-0">
            <div className="text-xs font-medium text-blue-900 truncate">Priya Sharma</div>
            <div className="text-[10px] text-blue-600">Receptionist</div>
          </div>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto py-3 px-2">
        {navGroups.map((g) => (
          <div key={g.label} className="mb-4">
            <div className="px-2 py-1 text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">
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
                          ? "bg-primary/10 text-primary font-medium"
                          : "text-foreground/70 hover:bg-muted hover:text-foreground",
                      )}
                    >
                      <Icon className={cn("w-4 h-4 shrink-0", isActive ? "text-primary" : "text-muted-foreground")} />
                      <span className="truncate">{it.label}</span>
                      {it.key === "queue" && (
                        <span className="ml-auto bg-amber-500 text-white text-[10px] font-bold rounded-full w-4 h-4 flex items-center justify-center">4</span>
                      )}
                      {it.key === "notifications" && (
                        <span className="ml-auto bg-red-500 text-white text-[10px] font-bold rounded-full w-4 h-4 flex items-center justify-center">3</span>
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      <div className="px-3 py-3 border-t border-border space-y-1">
        <button
          onClick={onRoleSwitch}
          className="w-full flex items-center gap-2 px-2.5 py-2 rounded-md text-xs text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
        >
          <LogOut className="w-3.5 h-3.5" />
          Switch Role
        </button>
        <div className="flex items-center gap-2 px-2.5 py-1 text-[11px] text-muted-foreground">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
          Synced · 2s ago
        </div>
      </div>
    </aside>
  );
}

export function ReceptionistTopBar({
  title,
  subtitle,
  onSearch,
}: {
  title: string;
  subtitle: string;
  onSearch?: (q: string) => void;
}) {
  const [q, setQ] = useState("");
  const today = new Date().toLocaleDateString("en-IN", {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
  });

  return (
    <header className="h-14 border-b border-border bg-card px-6 flex items-center gap-4 shrink-0 sticky top-0 z-10">
      <div className="flex-1 min-w-0">
        <h1 className="text-base font-semibold text-foreground leading-tight">{title}</h1>
        <p className="text-xs text-muted-foreground leading-tight">{subtitle}</p>
      </div>

      <div className="relative w-60">
        <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" />
        <input
          value={q}
          onChange={(e) => { setQ(e.target.value); onSearch?.(e.target.value); }}
          placeholder="Search patients, invoices…"
          className="w-full pl-8 pr-3 py-1.5 text-xs rounded-md border border-border bg-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-primary"
        />
      </div>

      <span className="text-xs text-muted-foreground whitespace-nowrap hidden xl:block">{today}</span>

      <button className="relative w-8 h-8 flex items-center justify-center rounded-md hover:bg-muted transition-colors">
        <Bell className="w-4 h-4 text-muted-foreground" />
        <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-red-500" />
      </button>

      <button className="flex items-center gap-2 px-2.5 py-1.5 rounded-md hover:bg-muted transition-colors">
        <div className="w-6 h-6 rounded-full bg-blue-500 text-white flex items-center justify-center text-[10px] font-bold">P</div>
        <span className="text-xs font-medium hidden xl:block">Priya</span>
        <ChevronDown className="w-3.5 h-3.5 text-muted-foreground hidden xl:block" />
      </button>
    </header>
  );
}

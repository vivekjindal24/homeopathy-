import {
  Users,
  ListOrdered,
  IndianRupee,
  AlertTriangle,
  Package,
  CalendarCheck,
  Clock,
  CheckCircle2,
  TrendingUp,
  TrendingDown,
  ChevronRight,
  UserPlus,
  CalendarPlus,
  FileText,
  Banknote,
  PackagePlus,
} from "lucide-react";

/* ─── Mock data ─────────────────────────────────────── */
const kpis = [
  {
    label: "Today's Patients",
    value: "38",
    delta: "+4 vs yesterday",
    deltaUp: true,
    icon: Users,
    iconColor: "text-blue-600",
    iconBg: "bg-blue-50",
  },
  {
    label: "Active Queue",
    value: "4",
    delta: "2 waiting · 2 in consult",
    deltaUp: null,
    icon: ListOrdered,
    iconColor: "text-amber-600",
    iconBg: "bg-amber-50",
  },
  {
    label: "Today's Revenue",
    value: "₹18,450",
    delta: "+₹2,100 vs avg",
    deltaUp: true,
    icon: IndianRupee,
    iconColor: "text-emerald-600",
    iconBg: "bg-emerald-50",
  },
  {
    label: "Pending Payments",
    value: "₹5,200",
    delta: "6 invoices due",
    deltaUp: false,
    icon: AlertTriangle,
    iconColor: "text-red-500",
    iconBg: "bg-red-50",
  },
  {
    label: "Low Stock Medicines",
    value: "7",
    delta: "Reorder needed",
    deltaUp: false,
    icon: Package,
    iconColor: "text-orange-500",
    iconBg: "bg-orange-50",
  },
  {
    label: "Near Expiry",
    value: "3",
    delta: "Expiring in 30 days",
    deltaUp: false,
    icon: CalendarCheck,
    iconColor: "text-purple-600",
    iconBg: "bg-purple-50",
  },
];

const queueData = [
  {
    col: "Waiting",
    color: "text-amber-700",
    bg: "bg-amber-50",
    border: "border-amber-200",
    count: 2,
    items: [
      { token: "T-21", name: "Anita Verma", arrival: "10:45 AM", type: "Follow Up" },
      { token: "T-22", name: "Raj Patel", arrival: "11:00 AM", type: "New" },
    ],
  },
  {
    col: "In Consultation",
    color: "text-blue-700",
    bg: "bg-blue-50",
    border: "border-blue-200",
    count: 1,
    items: [{ token: "T-19", name: "Sunita Mehta", arrival: "10:15 AM", type: "Follow Up" }],
  },
  {
    col: "Completed",
    color: "text-emerald-700",
    bg: "bg-emerald-50",
    border: "border-emerald-200",
    count: 18,
    items: [
      { token: "T-17", name: "Kavya Sharma", arrival: "09:30 AM", type: "Follow Up" },
      { token: "T-18", name: "Deepak Joshi", arrival: "09:45 AM", type: "New" },
    ],
  },
  {
    col: "No Show",
    color: "text-slate-600",
    bg: "bg-slate-50",
    border: "border-slate-200",
    count: 2,
    items: [
      { token: "T-12", name: "Meera Gupta", arrival: "08:30 AM", type: "Follow Up" },
    ],
  },
];

const appointmentStats = [
  { label: "Total Today", value: 42, color: "bg-primary" },
  { label: "Walk-Ins", value: 12, color: "bg-blue-400" },
  { label: "Follow Ups", value: 18, color: "bg-purple-400" },
  { label: "Cancelled", value: 4, color: "bg-red-400" },
];

const recentPayments = [
  { receipt: "RCP-1042", patient: "Anita Verma", amount: "₹850", mode: "UPI", time: "10:52 AM" },
  { receipt: "RCP-1041", patient: "Raj Patel", amount: "₹1,200", mode: "Cash", time: "10:31 AM" },
  { receipt: "RCP-1040", patient: "Kavya Sharma", amount: "₹650", mode: "Card", time: "09:48 AM" },
  { receipt: "RCP-1039", patient: "Deepak Joshi", amount: "₹2,100", mode: "UPI", time: "09:22 AM" },
];

const recentPatients = [
  { id: "P-2041", name: "Anita Verma", mobile: "98765-43210", type: "Follow Up", time: "10:45 AM" },
  { id: "P-2042", name: "Raj Patel", mobile: "87654-32109", type: "New", time: "11:00 AM" },
  { id: "P-1998", name: "Sunita Mehta", mobile: "76543-21098", type: "Follow Up", time: "10:15 AM" },
];

const recentInventory = [
  { medicine: "Arnica Montana 200C", action: "Stock In", qty: "+50 units", by: "Priya", time: "09:00 AM" },
  { medicine: "Belladonna 30C", action: "Dispensed", qty: "-2 units", by: "Dr. Verma", time: "10:22 AM" },
  { medicine: "Nux Vomica 1M", action: "Low Stock Alert", qty: "3 left", by: "System", time: "10:00 AM" },
];

const quickActions = [
  { label: "Register Patient", icon: UserPlus, color: "text-blue-600", bg: "bg-blue-50 hover:bg-blue-100 border-blue-100", navKey: "patients" },
  { label: "Book Appointment", icon: CalendarPlus, color: "text-primary", bg: "bg-primary/5 hover:bg-primary/10 border-primary/20", navKey: "appointments" },
  { label: "Walk-In", icon: Users, color: "text-amber-600", bg: "bg-amber-50 hover:bg-amber-100 border-amber-100", navKey: "appointments" },
  { label: "Generate Invoice", icon: FileText, color: "text-slate-700", bg: "bg-slate-50 hover:bg-slate-100 border-slate-200", navKey: "billing" },
  { label: "Record Payment", icon: Banknote, color: "text-emerald-600", bg: "bg-emerald-50 hover:bg-emerald-100 border-emerald-100", navKey: "payments" },
  { label: "Add Stock", icon: PackagePlus, color: "text-purple-600", bg: "bg-purple-50 hover:bg-purple-100 border-purple-100", navKey: "inventory" },
];

const modeColors: Record<string, string> = {
  UPI: "bg-purple-100 text-purple-700",
  Cash: "bg-emerald-100 text-emerald-700",
  Card: "bg-blue-100 text-blue-700",
};

/* ─── Component ─────────────────────────────────────── */
export function ReceptionistDashboard({ onNav }: { onNav?: (key: any) => void }) {
  return (
    <div className="p-6 space-y-6 bg-background min-h-full">

      {/* KPI Row — white cards, colored icons */}
      <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4">
        {kpis.map((k) => {
          const Icon = k.icon;
          return (
            <div
              key={k.label}
              className="bg-card border border-border rounded-xl p-4 flex flex-col gap-3 shadow-sm hover:shadow-md transition-shadow"
            >
              <div className="flex items-center justify-between">
                <div className={`w-8 h-8 rounded-lg ${k.iconBg} flex items-center justify-center`}>
                  <Icon className={`w-4 h-4 ${k.iconColor}`} />
                </div>
                {k.deltaUp === true && <TrendingUp className="w-3.5 h-3.5 text-emerald-500" />}
                {k.deltaUp === false && <TrendingDown className="w-3.5 h-3.5 text-red-400" />}
              </div>
              <div>
                <p className="text-xl font-black text-foreground leading-none">{k.value}</p>
                <p className="text-[11px] text-muted-foreground mt-1 leading-tight">{k.label}</p>
              </div>
              <p className={`text-[10px] font-medium ${k.deltaUp === true ? "text-emerald-600" : k.deltaUp === false ? "text-red-500" : "text-muted-foreground"}`}>
                {k.delta}
              </p>
            </div>
          );
        })}
      </div>

      {/* Middle: Queue + Appointment Overview */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">

        {/* Live Queue Board */}
        <div className="xl:col-span-2 bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center justify-between">
            <div>
              <h2 className="text-sm font-semibold">Live Queue Board</h2>
              <p className="text-xs text-muted-foreground mt-0.5">Real-time patient flow</p>
            </div>
            <button
              onClick={() => onNav?.("queue")}
              className="text-xs text-primary hover:underline flex items-center gap-1"
            >
              Full Queue <ChevronRight className="w-3 h-3" />
            </button>
          </div>
          <div className="grid grid-cols-2 lg:grid-cols-4 divide-x divide-border">
            {queueData.map((col) => (
              <div key={col.col} className="p-3">
                <div className="flex items-center justify-between mb-3">
                  <span className={`text-[11px] font-semibold uppercase tracking-wide ${col.color}`}>{col.col}</span>
                  <span className={`text-xs font-bold px-1.5 py-0.5 rounded-full ${col.bg} ${col.color} border ${col.border}`}>{col.count}</span>
                </div>
                <div className="space-y-2">
                  {col.items.map((item) => (
                    <div key={item.token} className={`rounded-lg border ${col.border} ${col.bg} p-2.5`}>
                      <div className="flex items-center justify-between mb-1">
                        <span className={`text-lg font-black ${col.color}`}>{item.token}</span>
                        <span className="text-[10px] bg-white/80 border border-border px-1.5 py-0.5 rounded-full text-muted-foreground">{item.type}</span>
                      </div>
                      <p className="text-xs font-medium text-foreground truncate">{item.name}</p>
                      <p className="text-[10px] text-muted-foreground flex items-center gap-1 mt-0.5">
                        <Clock className="w-3 h-3" />{item.arrival}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Appointment Overview */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border">
            <h2 className="text-sm font-semibold">Today's Appointments</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Overview by type</p>
          </div>
          <div className="p-5 space-y-4">
            {appointmentStats.map((s) => (
              <div key={s.label} className="flex items-center gap-3">
                <div className={`w-2.5 h-2.5 rounded-full ${s.color} shrink-0`} />
                <div className="flex-1 flex items-center justify-between">
                  <span className="text-sm text-foreground/80">{s.label}</span>
                  <span className="text-sm font-semibold">{s.value}</span>
                </div>
              </div>
            ))}
            <div className="pt-2 border-t border-border">
              <div className="flex items-center justify-between text-sm">
                <span className="font-medium">Completion Rate</span>
                <span className="text-emerald-600 font-bold">81%</span>
              </div>
              <div className="mt-2 h-1.5 rounded-full bg-muted overflow-hidden">
                <div className="h-full rounded-full bg-emerald-500 w-[81%]" />
              </div>
            </div>
            <button
              onClick={() => onNav?.("appointments")}
              className="w-full mt-2 py-2 text-xs text-primary border border-primary/30 rounded-md hover:bg-primary/5 transition-colors"
            >
              View All Appointments
            </button>
          </div>
        </div>
      </div>

      {/* Bottom: Recent + Quick Actions */}
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">

        {/* Recent Payments */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center justify-between">
            <h2 className="text-sm font-semibold">Recent Payments</h2>
            <button onClick={() => onNav?.("payments")} className="text-xs text-primary hover:underline">View all</button>
          </div>
          <div className="divide-y divide-border">
            {recentPayments.map((p) => (
              <div key={p.receipt} className="px-5 py-3 flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-xs font-medium truncate">{p.patient}</p>
                  <p className="text-[10px] text-muted-foreground">{p.receipt} · {p.time}</p>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-sm font-semibold text-emerald-700">{p.amount}</p>
                  <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${modeColors[p.mode] ?? "bg-slate-100 text-slate-600"}`}>{p.mode}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Patients */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center justify-between">
            <h2 className="text-sm font-semibold">Recent Patients</h2>
            <button onClick={() => onNav?.("patients")} className="text-xs text-primary hover:underline">View all</button>
          </div>
          <div className="divide-y divide-border">
            {recentPatients.map((p) => (
              <div key={p.id} className="px-5 py-3 flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center text-xs font-bold shrink-0">
                  {p.name.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium truncate">{p.name}</p>
                  <p className="text-[10px] text-muted-foreground">{p.mobile}</p>
                </div>
                <div className="text-right shrink-0">
                  <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${p.type === "New" ? "bg-blue-100 text-blue-700" : "bg-purple-100 text-purple-700"}`}>{p.type}</span>
                  <p className="text-[10px] text-muted-foreground mt-0.5">{p.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Inventory */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center justify-between">
            <h2 className="text-sm font-semibold">Inventory Activity</h2>
            <button onClick={() => onNav?.("inventory")} className="text-xs text-primary hover:underline">View all</button>
          </div>
          <div className="divide-y divide-border">
            {recentInventory.map((it, i) => (
              <div key={i} className="px-5 py-3">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-medium leading-tight truncate">{it.medicine}</p>
                    <p className="text-[10px] text-muted-foreground mt-0.5">{it.by} · {it.time}</p>
                  </div>
                  <div className="text-right shrink-0">
                    <span className={`text-xs font-medium ${it.qty.startsWith("+") ? "text-emerald-600" : it.qty.startsWith("-") ? "text-red-600" : "text-amber-600"}`}>{it.qty}</span>
                    <p className="text-[10px] text-muted-foreground mt-0.5">{it.action}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Actions — navigates to screens */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border">
            <h2 className="text-sm font-semibold">Quick Actions</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Common front-desk tasks</p>
          </div>
          <div className="p-4 grid grid-cols-2 gap-2.5">
            {quickActions.map((a) => {
              const Icon = a.icon;
              return (
                <button
                  key={a.label}
                  onClick={() => onNav?.(a.navKey)}
                  className={`${a.bg} border rounded-lg p-3 flex flex-col items-center gap-2 text-center transition-colors`}
                >
                  <Icon className={`w-5 h-5 ${a.color}`} />
                  <span className={`text-[11px] font-medium leading-tight ${a.color}`}>{a.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

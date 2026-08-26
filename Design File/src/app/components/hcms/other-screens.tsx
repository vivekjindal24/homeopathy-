import {
  Package,
  AlertTriangle,
  Plus,
  Download,
  Search,
  ShieldCheck,
  Bell,
  Settings as SettingsIcon,
  TrendingDown,
  RotateCcw,
} from "lucide-react";
import {
  LineChart,
  Line,
  ResponsiveContainer,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { KpiCard, SectionHeader, StatusPill } from "./primitives";

/* ------------ Inventory ------------- */

const stock = [
  { med: "Belladonna", pot: "200", batch: "BLD-2401", qty: 24, expiry: "Mar 2027", supplier: "SBL Pvt Ltd", status: "active" },
  { med: "Bryonia Alba", pot: "30", batch: "BRY-2331", qty: 6, expiry: "Aug 2026", supplier: "Schwabe", status: "low" },
  { med: "Nat. Mur", pot: "200", batch: "NTM-2412", qty: 18, expiry: "Jul 2026", supplier: "SBL Pvt Ltd", status: "expiring" },
  { med: "Pulsatilla", pot: "30", batch: "PUL-2402", qty: 32, expiry: "Nov 2027", supplier: "Reckeweg", status: "active" },
  { med: "Sepia", pot: "1M", batch: "SEP-2371", qty: 4, expiry: "Dec 2026", supplier: "Schwabe", status: "low" },
  { med: "Sulphur", pot: "200", batch: "SUL-2455", qty: 41, expiry: "Sep 2027", supplier: "SBL Pvt Ltd", status: "active" },
];

export function InventoryScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Inventory</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            142 SKUs · 8 low stock · 3 expiring within 90 days
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm"><Download className="w-3.5 h-3.5" /> Export</Button>
          <Button size="sm"><Plus className="w-3.5 h-3.5" /> Add stock</Button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <KpiCard label="Total SKUs" value="142" icon={<Package className="w-4 h-4" />} />
        <KpiCard label="Low stock" value="8" tone="warning" icon={<AlertTriangle className="w-4 h-4" />} hint="Reorder soon" />
        <KpiCard label="Expiring" value="3" tone="danger" icon={<AlertTriangle className="w-4 h-4" />} hint="Within 90 days" />
        <KpiCard label="Stock value" value="₹2.46L" icon={<TrendingDown className="w-4 h-4" />} />
      </div>

      <Card className="p-0 overflow-hidden">
        <div className="px-4 py-2.5 border-b border-border flex items-center gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="w-4 h-4 absolute left-2.5 top-2.5 text-muted-foreground" />
            <input
              placeholder="Search medicine, batch, supplier"
              className="w-full h-9 pl-8 pr-3 rounded-md bg-muted text-sm border border-transparent outline-none"
            />
          </div>
          <div className="text-xs text-muted-foreground ml-auto">142 results</div>
        </div>
        <table className="w-full text-sm">
          <thead className="bg-muted/60 text-xs text-muted-foreground">
            <tr>
              <th className="text-left px-4 py-2">Medicine</th>
              <th className="text-left px-4 py-2">Potency</th>
              <th className="text-left px-4 py-2">Batch</th>
              <th className="text-right px-4 py-2">Qty</th>
              <th className="text-left px-4 py-2">Expiry</th>
              <th className="text-left px-4 py-2">Supplier</th>
              <th className="text-left px-4 py-2">Status</th>
            </tr>
          </thead>
          <tbody>
            {stock.map((s) => (
              <tr key={s.batch} className="border-t border-border hover:bg-muted/40">
                <td className="px-4 py-2.5">{s.med}</td>
                <td className="px-4 py-2.5">{s.pot}</td>
                <td className="px-4 py-2.5 font-mono text-xs">{s.batch}</td>
                <td className="px-4 py-2.5 text-right tabular-nums">{s.qty}</td>
                <td className="px-4 py-2.5 text-muted-foreground">{s.expiry}</td>
                <td className="px-4 py-2.5 text-muted-foreground">{s.supplier}</td>
                <td className="px-4 py-2.5"><StatusPill status={s.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

/* ------------ Reports ------------- */

const trend = Array.from({ length: 30 }).map((_, i) => ({
  d: i + 1,
  rev: 8000 + Math.round(Math.sin(i / 3) * 3500 + Math.random() * 4000),
  exp: 3500 + Math.round(Math.cos(i / 4) * 1200 + Math.random() * 1200),
}));

const services = [
  { name: "Consultation", value: 42, fill: "#0f766e" },
  { name: "Medicines", value: 31, fill: "#14b8a6" },
  { name: "Follow-up pkg", value: 18, fill: "#5eead4" },
  { name: "Procedures", value: 9, fill: "#99f6e4" },
];

export function ReportsScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Reports & Analytics</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            May 2026 · MTD performance
          </p>
        </div>
        <div className="flex items-center gap-2">
          <select className="h-9 px-3 text-sm rounded-md border border-border bg-card">
            <option>This month</option>
            <option>Last 30 days</option>
            <option>This quarter</option>
            <option>Custom…</option>
          </select>
          <Button variant="outline" size="sm"><Download className="w-3.5 h-3.5" /> Export PDF</Button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <KpiCard label="Revenue (MTD)" value="₹4,12,500" delta={{ value: "8.3%", up: true }} tone="primary" />
        <KpiCard label="Expenses" value="₹1,28,400" delta={{ value: "2.1%", up: false }} />
        <KpiCard label="Net P/L" value="₹2,84,100" delta={{ value: "11.7%", up: true }} />
        <KpiCard label="Patient retention" value="68%" delta={{ value: "3pp", up: true }} hint="90-day window" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-4 lg:col-span-2 gap-3">
          <SectionHeader title="Revenue trend" description="Daily · last 30 days" />
          <div className="h-72">
            <ResponsiveContainer>
              <LineChart data={trend} margin={{ left: -10, right: 8 }}>
                <CartesianGrid stroke="#eef1f3" vertical={false} />
                <XAxis dataKey="d" stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip contentStyle={{ background: "#fff", border: "1px solid #e6ebec", borderRadius: 8, fontSize: 12 }} />
                <Line type="monotone" dataKey="rev" stroke="#0f766e" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="exp" stroke="#94a3b8" strokeWidth={1.5} strokeDasharray="4 4" dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-4 gap-3">
          <SectionHeader title="Top services" description="Share of revenue" />
          <div className="h-44">
            <ResponsiveContainer>
              <PieChart>
                <Pie data={services} innerRadius={48} outerRadius={70} paddingAngle={2} dataKey="value">
                  {services.map((s, i) => <Cell key={i} fill={s.fill} />)}
                </Pie>
                <Tooltip contentStyle={{ background: "#fff", border: "1px solid #e6ebec", borderRadius: 8, fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-1.5 text-xs">
            {services.map((s) => (
              <div key={s.name} className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-sm" style={{ background: s.fill }} />
                <span className="text-muted-foreground">{s.name}</span>
                <span className="ml-auto">{s.value}%</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

/* ------------ Audit ------------- */

const audit = [
  { ts: "14 May · 10:14:22", user: "reception_meena", action: "INVOICE_ISSUED", entity: "INV-2042", before: "draft", after: "issued" },
  { ts: "14 May · 10:09:01", user: "dr_verma", action: "PRESCRIPTION_FINALIZED", entity: "RX-1872", before: "draft", after: "finalized" },
  { ts: "14 May · 10:04:55", user: "dr_verma", action: "CONSULTATION_STARTED", entity: "VHC-00821 · v5", before: "—", after: "in_consultation" },
  { ts: "14 May · 09:48:10", user: "reception_meena", action: "PATIENT_CREATED", entity: "VHC-00827", before: "—", after: "active" },
  { ts: "14 May · 09:32:44", user: "admin_root", action: "SETTINGS_UPDATED", entity: "razorpay.webhook_url", before: "https://…/v1", after: "https://…/v2" },
  { ts: "13 May · 18:55:02", user: "reception_meena", action: "PAYMENT_RECORDED", entity: "PAY-3349", before: "—", after: "₹1,250 · UPI" },
];

export function AuditScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl flex items-center gap-2"><ShieldCheck className="w-5 h-5 text-primary" /> Audit Log</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Immutable · all financial and clinical events traced
          </p>
        </div>
        <div className="flex items-center gap-2">
          <select className="h-9 px-3 text-sm rounded-md border border-border bg-card">
            <option>All entities</option>
            <option>Invoice</option>
            <option>Prescription</option>
            <option>Patient</option>
            <option>Settings</option>
          </select>
          <select className="h-9 px-3 text-sm rounded-md border border-border bg-card">
            <option>All users</option>
            <option>dr_verma</option>
            <option>reception_meena</option>
            <option>admin_root</option>
          </select>
          <Button variant="outline" size="sm"><Download className="w-3.5 h-3.5" /> Export CSV</Button>
        </div>
      </div>

      <Card className="p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/60 text-xs text-muted-foreground">
            <tr>
              <th className="text-left px-4 py-2">Timestamp</th>
              <th className="text-left px-4 py-2">Actor</th>
              <th className="text-left px-4 py-2">Action</th>
              <th className="text-left px-4 py-2">Entity</th>
              <th className="text-left px-4 py-2">Before</th>
              <th className="text-left px-4 py-2">After</th>
            </tr>
          </thead>
          <tbody className="font-mono text-xs">
            {audit.map((a, i) => (
              <tr key={i} className="border-t border-border hover:bg-muted/40">
                <td className="px-4 py-2.5 text-muted-foreground">{a.ts}</td>
                <td className="px-4 py-2.5">{a.user}</td>
                <td className="px-4 py-2.5">
                  <span className="px-1.5 py-0.5 rounded bg-muted">{a.action}</span>
                </td>
                <td className="px-4 py-2.5">{a.entity}</td>
                <td className="px-4 py-2.5 text-red-700">{a.before}</td>
                <td className="px-4 py-2.5 text-emerald-700">{a.after}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

/* ------------ Generic placeholder ------------- */

export function PlaceholderScreen({
  title,
  icon: Icon = SettingsIcon,
  description,
}: {
  title: string;
  icon?: any;
  description?: string;
}) {
  return (
    <div className="p-6">
      <div className="mb-4">
        <h2 className="text-xl">{title}</h2>
        {description && <p className="text-xs text-muted-foreground mt-0.5">{description}</p>}
      </div>
      <Card className="p-12 flex flex-col items-center justify-center text-center gap-3">
        <div className="w-12 h-12 rounded-xl bg-accent text-primary flex items-center justify-center">
          <Icon className="w-6 h-6" />
        </div>
        <div>
          <div className="text-sm">Module ready for Phase 2</div>
          <p className="text-xs text-muted-foreground mt-1 max-w-md">
            This module follows the same design language. Forms, tables, status pills, KPI
            cards and timelines are reused from the shared component library.
          </p>
        </div>
        <Button variant="outline" size="sm">
          <RotateCcw className="w-3.5 h-3.5" /> Configure module
        </Button>
      </Card>
    </div>
  );
}

export function NotificationsScreen() {
  const items = [
    { t: "Stock low: Bryonia 30 (6 vials)", time: "2m ago", tone: "warning" },
    { t: "Refund approved · PAY-3318 · ₹540", time: "1h ago", tone: "default" },
    { t: "Daily reconciliation completed · 98.2%", time: "3h ago", tone: "default" },
    { t: "New patient registered · VHC-00827", time: "4h ago", tone: "default" },
    { t: "Invoice INV-2031 overdue · ₹1,180", time: "Yesterday", tone: "danger" },
  ];
  return (
    <div className="p-6 space-y-4">
      <div>
        <h2 className="text-xl flex items-center gap-2"><Bell className="w-5 h-5 text-primary" /> Notifications</h2>
        <p className="text-xs text-muted-foreground mt-0.5">12 new · last 24 hours</p>
      </div>
      <Card className="p-0 overflow-hidden">
        <ul className="divide-y divide-border">
          {items.map((n, i) => (
            <li key={i} className="px-4 py-3 flex items-center gap-3 hover:bg-muted/40">
              <span className={`w-2 h-2 rounded-full ${
                n.tone === "danger" ? "bg-red-500" :
                n.tone === "warning" ? "bg-amber-500" : "bg-emerald-500"
              }`} />
              <div className="flex-1 text-sm">{n.t}</div>
              <div className="text-xs text-muted-foreground">{n.time}</div>
            </li>
          ))}
        </ul>
      </Card>
    </div>
  );
}

export function SettingsScreen() {
  const groups = [
    { title: "Clinic profile", desc: "Name, address, branding, GSTIN, contact" },
    { title: "Doctor profile", desc: "Registration number, qualifications, signature" },
    { title: "Staff users & roles", desc: "Doctor, Receptionist, Admin · permissions" },
    { title: "Payment gateway", desc: "Razorpay keys, webhook, reconciliation rules" },
    { title: "Notification preferences", desc: "SMS, WhatsApp, email triggers" },
    { title: "Prescription templates", desc: "Reusable Rx, case-taking templates" },
    { title: "Session timeout", desc: "Auto-lock, biometric trust on iPad" },
    { title: "Backup & export", desc: "Daily backup schedule, data export" },
  ];
  return (
    <div className="p-6 space-y-4">
      <div>
        <h2 className="text-xl">Settings</h2>
        <p className="text-xs text-muted-foreground mt-0.5">System configuration & user management</p>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {groups.map((g) => (
          <Card key={g.title} className="p-4 hover:border-primary/40 transition-colors cursor-pointer">
            <div className="text-sm">{g.title}</div>
            <div className="text-xs text-muted-foreground mt-1">{g.desc}</div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function PaymentsScreen() {
  const list = [
    { id: "PAY-3349", inv: "INV-2041", patient: "Anita Sharma", mode: "UPI", amt: "₹1,250", status: "completed", time: "10:09" },
    { id: "PAY-3348", inv: "INV-2042", patient: "Rohit Mehra", mode: "Cash", amt: "₹500", status: "partial", time: "09:55" },
    { id: "PAY-3347", inv: "INV-2043", patient: "Sunita Tiwari", mode: "Card", amt: "₹2,400", status: "completed", time: "09:42" },
    { id: "PAY-3346", inv: "INV-2031", patient: "Mehul Patel", mode: "UPI", amt: "₹860", status: "refunded", time: "Yesterday" },
  ];
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Payments & Refunds</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            ₹18,450 collected today · 1 refund pending approval
          </p>
        </div>
        <Button size="sm"><Plus className="w-3.5 h-3.5" /> Initiate refund</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <KpiCard label="Collected today" value="₹18,450" tone="primary" />
        <KpiCard label="Pending dues" value="₹24,860" tone="warning" />
        <KpiCard label="Refunds (MTD)" value="₹3,200" />
        <KpiCard label="Reconciled" value="98.2%" />
      </div>

      <Card className="p-0 overflow-hidden">
        <div className="px-4 py-2.5 border-b border-border text-sm">Recent payments</div>
        <table className="w-full text-sm">
          <thead className="bg-muted/60 text-xs text-muted-foreground">
            <tr>
              <th className="text-left px-4 py-2">Payment</th>
              <th className="text-left px-4 py-2">Invoice</th>
              <th className="text-left px-4 py-2">Patient</th>
              <th className="text-left px-4 py-2">Mode</th>
              <th className="text-right px-4 py-2">Amount</th>
              <th className="text-left px-4 py-2">Status</th>
              <th className="text-left px-4 py-2">Time</th>
            </tr>
          </thead>
          <tbody>
            {list.map((p) => (
              <tr key={p.id} className="border-t border-border hover:bg-muted/40">
                <td className="px-4 py-2.5 font-mono text-xs">{p.id}</td>
                <td className="px-4 py-2.5 font-mono text-xs">{p.inv}</td>
                <td className="px-4 py-2.5">{p.patient}</td>
                <td className="px-4 py-2.5 text-muted-foreground">{p.mode}</td>
                <td className="px-4 py-2.5 text-right tabular-nums">{p.amt}</td>
                <td className="px-4 py-2.5"><StatusPill status={p.status === "completed" ? "paid" : p.status} /></td>
                <td className="px-4 py-2.5 text-muted-foreground">{p.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

export function ExpensesScreen() {
  const list = [
    { d: "14 May", cat: "Pharmacy stock", desc: "Belladonna, Pulsatilla — SBL", by: "admin_root", amt: "₹4,820" },
    { d: "13 May", cat: "Utilities", desc: "Electricity bill May", by: "admin_root", amt: "₹6,400" },
    { d: "12 May", cat: "Salaries", desc: "Reception staff — partial", by: "admin_root", amt: "₹18,000" },
    { d: "10 May", cat: "Maintenance", desc: "AC servicing", by: "reception_meena", amt: "₹1,200" },
  ];
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Expenses</h2>
          <p className="text-xs text-muted-foreground mt-0.5">May MTD ₹1,28,400 · 4 categories</p>
        </div>
        <Button size="sm"><Plus className="w-3.5 h-3.5" /> Add expense</Button>
      </div>
      <Card className="p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/60 text-xs text-muted-foreground">
            <tr>
              <th className="text-left px-4 py-2">Date</th>
              <th className="text-left px-4 py-2">Category</th>
              <th className="text-left px-4 py-2">Description</th>
              <th className="text-left px-4 py-2">Recorded by</th>
              <th className="text-right px-4 py-2">Amount</th>
            </tr>
          </thead>
          <tbody>
            {list.map((e, i) => (
              <tr key={i} className="border-t border-border hover:bg-muted/40">
                <td className="px-4 py-2.5 text-muted-foreground">{e.d}</td>
                <td className="px-4 py-2.5">{e.cat}</td>
                <td className="px-4 py-2.5 text-muted-foreground">{e.desc}</td>
                <td className="px-4 py-2.5 font-mono text-xs">{e.by}</td>
                <td className="px-4 py-2.5 text-right tabular-nums">{e.amt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

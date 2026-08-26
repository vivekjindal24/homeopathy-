import {
  IndianRupee,
  Users,
  CalendarCheck,
  AlertTriangle,
  Download,
  ArrowRight,
} from "lucide-react";
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { KpiCard, SectionHeader, StatusPill } from "./primitives";

const revenue = [
  { d: "Mon", v: 12400, e: 4200 },
  { d: "Tue", v: 14800, e: 3800 },
  { d: "Wed", v: 11200, e: 4600 },
  { d: "Thu", v: 16900, e: 5100 },
  { d: "Fri", v: 18450, e: 4800 },
  { d: "Sat", v: 22100, e: 5400 },
  { d: "Sun", v: 9800, e: 2900 },
];

const modes = [
  { name: "UPI", value: 48, fill: "#0f766e" },
  { name: "Cash", value: 26, fill: "#14b8a6" },
  { name: "Card", value: 18, fill: "#5eead4" },
  { name: "Net Banking", value: 8, fill: "#99f6e4" },
];

const apptTrend = [
  { d: "W1", n: 142 },
  { d: "W2", n: 168 },
  { d: "W3", n: 156 },
  { d: "W4", n: 191 },
  { d: "W5", n: 204 },
  { d: "W6", n: 188 },
];

const recent = [
  { id: "INV-2041", patient: "Anita Sharma", amount: "₹1,250", status: "paid", mode: "UPI" },
  { id: "INV-2042", patient: "Rohit Mehra", amount: "₹860", status: "partial", mode: "Cash" },
  { id: "INV-2043", patient: "Sunita Tiwari", amount: "₹2,400", status: "paid", mode: "Card" },
  { id: "INV-2044", patient: "Vikas Yadav", amount: "₹540", status: "due", mode: "—" },
  { id: "INV-2045", patient: "Priya Nair", amount: "₹1,180", status: "paid", mode: "UPI" },
];

export function AdminDashboard() {
  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Today · Thursday, 14 May 2026</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Operational snapshot for Vijay Nagar branch
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm">
            <Download className="w-3.5 h-3.5" /> Export EOD
          </Button>
          <Button size="sm">Open Reconciliation</Button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        <KpiCard
          label="Daily revenue"
          value="₹18,450"
          delta={{ value: "12.4%", up: true }}
          hint="vs. 7-day average"
          icon={<IndianRupee className="w-4 h-4" />}
          tone="primary"
        />
        <KpiCard
          label="Patients today"
          value="46"
          delta={{ value: "6 walk-ins", up: true }}
          hint="32 follow-ups · 14 new"
          icon={<Users className="w-4 h-4" />}
        />
        <KpiCard
          label="Appointments"
          value="58"
          delta={{ value: "4 no-show", up: false }}
          hint="51 completed · 3 in queue"
          icon={<CalendarCheck className="w-4 h-4" />}
        />
        <KpiCard
          label="Pending dues"
          value="₹24,860"
          delta={{ value: "₹3,200", up: false }}
          hint="9 invoices · 2 overdue"
          icon={<AlertTriangle className="w-4 h-4" />}
          tone="warning"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-4 lg:col-span-2 gap-4">
          <SectionHeader
            title="Revenue vs. Expenses"
            description="Last 7 days · in ₹"
            action={
              <div className="flex items-center gap-1.5 text-xs">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-sm bg-primary" /> Revenue
                </span>
                <span className="inline-flex items-center gap-1.5 ml-3">
                  <span className="w-2.5 h-2.5 rounded-sm bg-slate-300" /> Expenses
                </span>
              </div>
            }
          />
          <div className="h-64">
            <ResponsiveContainer>
              <AreaChart data={revenue} margin={{ left: -10, right: 8, top: 4 }}>
                <defs>
                  <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#0f766e" stopOpacity={0.35} />
                    <stop offset="100%" stopColor="#0f766e" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#eef1f3" vertical={false} />
                <XAxis dataKey="d" stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    background: "#fff",
                    border: "1px solid #e6ebec",
                    borderRadius: 8,
                    fontSize: 12,
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="e"
                  stroke="#94a3b8"
                  strokeWidth={1.5}
                  fill="transparent"
                  strokeDasharray="4 4"
                  dot={false}
                  activeDot={false}
                  isAnimationActive={false}
                />
                <Area
                  type="monotone"
                  dataKey="v"
                  stroke="#0f766e"
                  strokeWidth={2}
                  fill="url(#rev)"
                  dot={false}
                  activeDot={{ r: 3 }}
                  isAnimationActive={false}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-4 gap-3">
          <SectionHeader
            title="Collections by mode"
            description="Today · ₹18,450 collected"
          />
          <div className="h-44">
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={modes}
                  innerRadius={48}
                  outerRadius={70}
                  paddingAngle={2}
                  dataKey="value"
                >
                  {modes.map((m) => (
                    <Cell key={m.name} fill={m.fill} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: "#fff",
                    border: "1px solid #e6ebec",
                    borderRadius: 8,
                    fontSize: 12,
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="grid grid-cols-2 gap-2 text-xs">
            {modes.map((m) => (
              <div key={m.name} className="flex items-center gap-2">
                <span
                  className="w-2 h-2 rounded-sm"
                  style={{ background: m.fill }}
                />
                <span className="text-muted-foreground">{m.name}</span>
                <span className="ml-auto">{m.value}%</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-4 gap-3 lg:col-span-2">
          <SectionHeader
            title="Recent invoices"
            description="Latest 5 transactions"
            action={
              <Button variant="ghost" size="sm" className="text-primary">
                View all <ArrowRight className="w-3.5 h-3.5" />
              </Button>
            }
          />
          <div className="overflow-hidden rounded-md border border-border">
            <table className="w-full text-sm">
              <thead className="bg-muted/60 text-xs text-muted-foreground">
                <tr>
                  <th className="text-left px-3 py-2">Invoice</th>
                  <th className="text-left px-3 py-2">Patient</th>
                  <th className="text-left px-3 py-2">Mode</th>
                  <th className="text-right px-3 py-2">Amount</th>
                  <th className="text-left px-3 py-2">Status</th>
                </tr>
              </thead>
              <tbody>
                {recent.map((r) => (
                  <tr key={r.id} className="border-t border-border hover:bg-muted/40">
                    <td className="px-3 py-2 font-mono text-xs">{r.id}</td>
                    <td className="px-3 py-2">{r.patient}</td>
                    <td className="px-3 py-2 text-muted-foreground">{r.mode}</td>
                    <td className="px-3 py-2 text-right tabular-nums">{r.amount}</td>
                    <td className="px-3 py-2">
                      <StatusPill status={r.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        <Card className="p-4 gap-3">
          <SectionHeader title="Appointment trend" description="Last 6 weeks" />
          <div className="h-44">
            <ResponsiveContainer>
              <BarChart data={apptTrend} margin={{ left: -10, right: 4 }}>
                <CartesianGrid stroke="#eef1f3" vertical={false} />
                <XAxis dataKey="d" stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    background: "#fff",
                    border: "1px solid #e6ebec",
                    borderRadius: 8,
                    fontSize: 12,
                  }}
                />
                <Bar dataKey="n" fill="#0f766e" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="grid grid-cols-3 gap-2 pt-2 border-t border-border">
            <div>
              <div className="text-xs text-muted-foreground">Retention</div>
              <div className="text-sm">68%</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground">P/L (MTD)</div>
              <div className="text-sm text-emerald-700">+₹1.84L</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground">Reconciled</div>
              <div className="text-sm">98.2%</div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

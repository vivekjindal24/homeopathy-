import { useState } from "react";
import {
  Receipt,
  Plus,
  Search,
  X,
  Trash2,
  AlertCircle,
  CheckCircle2,
  Clock,
  RefreshCw,
  Banknote,
  CreditCard,
  Smartphone,
  Globe,
  Wallet,
  Send,
  IndianRupee,
  FileText,
  ChevronRight,
  Eye,
  Download,
} from "lucide-react";
import { cn } from "../ui/utils";
import { toast } from "sonner";

/* ─── BILLING ────────────────────────────────────────── */
type InvoiceStatus = "Paid" | "Partial" | "Overdue" | "Draft" | "Refunded";

interface Invoice {
  id: string;
  number: string;
  patient: string;
  patientId: string;
  date: string;
  amount: number;
  paid: number;
  status: InvoiceStatus;
  items: { description: string; qty: number; rate: number }[];
}

const invoices: Invoice[] = [
  { id: "i1", number: "INV-2241", patient: "Anita Verma", patientId: "P-2041", date: "19 Jun 2025", amount: 1200, paid: 1200, status: "Paid", items: [{ description: "Consultation Fee", qty: 1, rate: 500 }, { description: "Medicine Charges", qty: 1, rate: 700 }] },
  { id: "i2", number: "INV-2240", patient: "Raj Patel", patientId: "P-2042", date: "19 Jun 2025", amount: 850, paid: 500, status: "Partial", items: [{ description: "Consultation Fee", qty: 1, rate: 500 }, { description: "Registration Fee", qty: 1, rate: 350 }] },
  { id: "i3", number: "INV-2239", patient: "Sunita Mehta", patientId: "P-1998", date: "18 Jun 2025", amount: 2100, paid: 0, status: "Overdue", items: [{ description: "Consultation Fee", qty: 1, rate: 500 }, { description: "Procedure Charges", qty: 2, rate: 800 }] },
  { id: "i4", number: "INV-2238", patient: "Vikram Singh", patientId: "P-2010", date: "18 Jun 2025", amount: 650, paid: 650, status: "Paid", items: [{ description: "Consultation Fee", qty: 1, rate: 500 }, { description: "Medicine Charges", qty: 1, rate: 150 }] },
  { id: "i5", number: "INV-2237", patient: "Kavya Sharma", patientId: "P-1985", date: "17 Jun 2025", amount: 3200, paid: 3200, status: "Paid", items: [{ description: "Follow Up Package", qty: 1, rate: 3200 }] },
  { id: "i6", number: "INV-2236", patient: "Deepak Joshi", patientId: "P-2005", date: "17 Jun 2025", amount: 900, paid: 0, status: "Overdue", items: [{ description: "Consultation Fee", qty: 1, rate: 500 }, { description: "Medicine Charges", qty: 1, rate: 400 }] },
  { id: "i7", number: "INV-2235", patient: "Priti Gupta", patientId: "P-1920", date: "16 Jun 2025", amount: 1500, paid: 1500, status: "Refunded", items: [{ description: "Consultation Fee", qty: 1, rate: 1500 }] },
  { id: "i8", number: "INV-2234", patient: "Ravi Kumar", patientId: "P-2031", date: "16 Jun 2025", amount: 750, paid: 0, status: "Draft", items: [{ description: "Consultation Fee", qty: 1, rate: 750 }] },
];

const billingMetrics = [
  { label: "Total Invoices", value: 42, icon: Receipt, iconColor: "text-primary", iconBg: "bg-primary/10" },
  { label: "Paid", value: 28, icon: CheckCircle2, iconColor: "text-emerald-600", iconBg: "bg-emerald-50" },
  { label: "Partial", value: 6, icon: Clock, iconColor: "text-amber-600", iconBg: "bg-amber-50" },
  { label: "Overdue", value: 5, icon: AlertCircle, iconColor: "text-red-500", iconBg: "bg-red-50" },
  { label: "Refunded", value: 3, icon: RefreshCw, iconColor: "text-purple-600", iconBg: "bg-purple-50" },
];

const statusStyle: Record<InvoiceStatus, string> = {
  Paid: "bg-emerald-100 text-emerald-700",
  Partial: "bg-amber-100 text-amber-700",
  Overdue: "bg-red-100 text-red-700",
  Draft: "bg-slate-100 text-slate-600",
  Refunded: "bg-purple-100 text-purple-700",
};

const lineItemTypes = [
  "Consultation Fee",
  "Medicine Charges",
  "Registration Fee",
  "Procedure Charges",
  "Follow Up Package",
  "Miscellaneous",
];

interface LineItem {
  id: string;
  description: string;
  qty: number;
  rate: number;
}

/* ─── Invoice Detail Drawer ─────────────────────────── */
function InvoiceDetailDrawer({ invoice, onClose, onPay }: { invoice: Invoice; onClose: () => void; onPay: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex justify-end">
      <div className="bg-card w-full max-w-md h-full flex flex-col shadow-2xl">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">{invoice.number}</h2>
            <p className="text-xs text-muted-foreground mt-0.5">{invoice.patient} · {invoice.date}</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* Status banner */}
          <div className={`px-3 py-2 rounded-lg border text-xs font-medium flex items-center gap-2 ${statusStyle[invoice.status]}`}>
            <span className="w-1.5 h-1.5 rounded-full bg-current" />
            {invoice.status}
            {invoice.status === "Overdue" && " — Payment overdue"}
            {invoice.status === "Partial" && ` — ₹${(invoice.amount - invoice.paid).toLocaleString()} remaining`}
          </div>

          {/* Invoice Info */}
          <div className="space-y-2 text-xs">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Invoice Information</h3>
            <div className="bg-muted/30 rounded-lg p-3 grid grid-cols-2 gap-2">
              {[["Invoice No", invoice.number], ["Patient", invoice.patient], ["Patient ID", invoice.patientId], ["Date", invoice.date]].map(([l, v]) => (
                <div key={l}><p className="text-muted-foreground text-[10px]">{l}</p><p className="font-medium mt-0.5">{v}</p></div>
              ))}
            </div>
          </div>

          {/* Line Items */}
          <div className="space-y-2">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Line Items</h3>
            <div className="border border-border rounded-lg overflow-hidden">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/30 border-b border-border">
                  <th className="px-3 py-2 text-left text-muted-foreground">Description</th>
                  <th className="px-3 py-2 text-center text-muted-foreground">Qty</th>
                  <th className="px-3 py-2 text-right text-muted-foreground">Amount</th>
                </tr></thead>
                <tbody className="divide-y divide-border">
                  {invoice.items.map((item, i) => (
                    <tr key={i}><td className="px-3 py-2">{item.description}</td><td className="px-3 py-2 text-center text-muted-foreground">{item.qty}</td><td className="px-3 py-2 text-right font-medium">₹{(item.qty * item.rate).toLocaleString()}</td></tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Summary */}
          <div className="border border-border rounded-lg p-4 space-y-2 text-xs">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold mb-3">Payment Summary</h3>
            <div className="flex justify-between"><span className="text-muted-foreground">Total Amount</span><span className="font-semibold">₹{invoice.amount.toLocaleString()}</span></div>
            <div className="flex justify-between"><span className="text-muted-foreground">Amount Paid</span><span className="text-emerald-600 font-semibold">₹{invoice.paid.toLocaleString()}</span></div>
            <div className="border-t border-border pt-2 flex justify-between">
              <span className="font-semibold">Balance Due</span>
              <span className={`font-black text-base ${(invoice.amount - invoice.paid) > 0 ? "text-red-600" : "text-emerald-600"}`}>₹{(invoice.amount - invoice.paid).toLocaleString()}</span>
            </div>
          </div>

          {/* Payment History placeholder */}
          <div className="space-y-2">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Payment History</h3>
            {invoice.paid > 0 ? (
              <div className="border border-border rounded-lg p-3 text-xs flex items-center justify-between">
                <div><p className="font-medium">RCP-1042</p><p className="text-muted-foreground">19 Jun · UPI</p></div>
                <span className="text-emerald-600 font-semibold">₹{invoice.paid.toLocaleString()}</span>
              </div>
            ) : (
              <div className="py-4 text-center text-xs text-muted-foreground">No payments recorded yet</div>
            )}
          </div>
        </div>
        <div className="p-4 border-t border-border flex gap-2">
          <button className="flex items-center gap-1.5 px-3 py-2 border border-border text-xs rounded-md hover:bg-muted">
            <Download className="w-3.5 h-3.5" /> Download PDF
          </button>
          {(invoice.status === "Partial" || invoice.status === "Overdue" || invoice.status === "Draft") && (
            <button onClick={onPay} className="flex-1 py-2 bg-emerald-600 text-white text-sm font-medium rounded-md hover:bg-emerald-700">
              Collect Payment
            </button>
          )}
          <button onClick={onClose} className="px-3 py-2 border border-border text-xs rounded-md hover:bg-muted">Close</button>
        </div>
      </div>
    </div>
  );
}

/* ─── Create Invoice Modal ───────────────────────────── */
function CreateInvoiceModal({ onClose }: { onClose: () => void }) {
  const [items, setItems] = useState<LineItem[]>([
    { id: "li1", description: "Consultation Fee", qty: 1, rate: 500 },
  ]);
  const [discount, setDiscount] = useState({ type: "percent" as "percent" | "fixed", value: 0, reason: "" });
  const [mode, setMode] = useState<"draft" | "issue">("draft");

  const subtotal = items.reduce((s, i) => s + i.qty * i.rate, 0);
  const discountAmt = discount.type === "percent" ? Math.round(subtotal * discount.value / 100) : discount.value;
  const total = subtotal - discountAmt;

  const addItem = () => setItems(p => [...p, { id: `li${Date.now()}`, description: "Consultation Fee", qty: 1, rate: 0 }]);
  const removeItem = (id: string) => setItems(p => p.filter(i => i.id !== id));
  const updateItem = (id: string, field: keyof LineItem, val: string | number) =>
    setItems(p => p.map(i => i.id === id ? { ...i, [field]: val } : i));

  const handleSave = (type: "draft" | "issue" | "pdf") => {
    if (type === "draft") toast.success("Invoice saved as draft.");
    else if (type === "issue") toast.success("Invoice issued successfully. INV-2242 created.");
    else toast.success("Invoice PDF generated and ready to download.");
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-4xl my-4">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Create Invoice</h2>
            <p className="text-xs text-muted-foreground mt-0.5">New billing entry</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>

        <div className="grid grid-cols-3 gap-0 divide-x divide-border">
          {/* Left: Patient Info */}
          <div className="p-5 space-y-4">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Patient Information</h3>
            <div className="space-y-2">
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
                <input placeholder="Search patient…" className="w-full pl-8 pr-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
              </div>
              <div className="bg-primary/5 border border-primary/20 rounded-lg p-3 text-xs space-y-1">
                <p className="font-semibold text-sm">Anita Verma</p>
                <p className="text-muted-foreground">P-2041 · 34y · Female</p>
                <p className="text-muted-foreground">98765-43210</p>
              </div>
            </div>
            <div>
              <label className="text-xs text-muted-foreground">Invoice Date</label>
              <input type="date" defaultValue="2025-06-19" className="mt-1 w-full px-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground">Visit Reference</label>
              <input defaultValue="VISIT-1234" className="mt-1 w-full px-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground">Notes</label>
              <textarea rows={3} className="mt-1 w-full px-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary resize-none" placeholder="Optional notes…" />
            </div>
          </div>

          {/* Center: Line Items */}
          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Line Items</h3>
              <button onClick={addItem} className="flex items-center gap-1 text-xs text-primary hover:underline">
                <Plus className="w-3 h-3" /> Add Item
              </button>
            </div>
            <div className="space-y-2">
              <div className="grid grid-cols-[1fr_40px_72px_24px] gap-1.5 text-[10px] text-muted-foreground px-1">
                <span>Description</span><span className="text-center">Qty</span><span className="text-right">Rate ₹</span><span />
              </div>
              {items.map((item) => (
                <div key={item.id} className="grid grid-cols-[1fr_40px_72px_24px] gap-1.5 group items-center">
                  <select
                    value={item.description}
                    onChange={e => updateItem(item.id, "description", e.target.value)}
                    className="px-2 py-1.5 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    {lineItemTypes.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                  <input type="number" min={1} value={item.qty} onChange={e => updateItem(item.id, "qty", parseInt(e.target.value) || 1)} className="px-2 py-1.5 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary text-center" />
                  <input type="number" value={item.rate} onChange={e => updateItem(item.id, "rate", parseInt(e.target.value) || 0)} className="px-2 py-1.5 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary text-right" />
                  <button onClick={() => removeItem(item.id)} className="opacity-0 group-hover:opacity-100 p-1 hover:bg-red-50 hover:text-red-600 rounded-md transition-all">
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>

            {/* Discount */}
            <div className="border border-border rounded-lg p-3 space-y-2 bg-muted/20">
              <p className="text-xs font-medium">Discount</p>
              <div className="flex gap-2">
                <select value={discount.type} onChange={e => setDiscount(p => ({ ...p, type: e.target.value as any }))} className="flex-1 px-2 py-1.5 text-xs rounded-md border border-border bg-background focus:outline-none">
                  <option value="percent">Percentage (%)</option>
                  <option value="fixed">Fixed Amount (₹)</option>
                </select>
                <input type="number" value={discount.value} onChange={e => setDiscount(p => ({ ...p, value: parseFloat(e.target.value) || 0 }))} className="w-20 px-2 py-1.5 text-xs rounded-md border border-border bg-background focus:outline-none" />
              </div>
              {discount.value > 0 && (
                <input
                  placeholder="Reason for discount (required)"
                  value={discount.reason}
                  onChange={e => setDiscount(p => ({ ...p, reason: e.target.value }))}
                  className="w-full px-2 py-1.5 text-xs rounded-md border border-amber-300 bg-amber-50 focus:outline-none focus:ring-1 focus:ring-amber-400 placeholder:text-amber-400"
                />
              )}
            </div>
          </div>

          {/* Right: Summary */}
          <div className="p-5 space-y-4">
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Invoice Summary</h3>
            <div className="space-y-2.5">
              {items.map((item) => (
                <div key={item.id} className="flex items-center justify-between text-xs">
                  <span className="text-muted-foreground truncate max-w-[140px]">{item.description} ×{item.qty}</span>
                  <span className="font-medium">₹{(item.qty * item.rate).toLocaleString()}</span>
                </div>
              ))}
              <div className="border-t border-border pt-2 flex justify-between text-xs">
                <span className="text-muted-foreground">Subtotal</span>
                <span className="font-medium">₹{subtotal.toLocaleString()}</span>
              </div>
              {discountAmt > 0 && (
                <div className="flex justify-between text-xs text-emerald-600">
                  <span>Discount</span>
                  <span>-₹{discountAmt.toLocaleString()}</span>
                </div>
              )}
              <div className="border-t-2 border-foreground/20 pt-2 flex justify-between">
                <span className="text-sm font-semibold">Total</span>
                <span className="text-2xl font-black text-primary">₹{total.toLocaleString()}</span>
              </div>
            </div>

            <div className="space-y-2 pt-2">
              <button onClick={() => handleSave("draft")} className="w-full py-2.5 border border-border text-sm font-medium rounded-lg hover:bg-muted transition-colors">
                Save Draft
              </button>
              <button onClick={() => handleSave("issue")} className="w-full py-2.5 bg-primary text-primary-foreground text-sm font-medium rounded-lg hover:bg-primary/90 transition-colors">
                Issue Invoice
              </button>
              <button onClick={() => handleSave("pdf")} className="w-full py-2.5 bg-slate-700 text-white text-sm font-medium rounded-lg hover:bg-slate-800 transition-colors flex items-center justify-center gap-2">
                <Download className="w-4 h-4" /> Generate PDF
              </button>
              <button onClick={onClose} className="w-full py-2 text-sm text-muted-foreground hover:text-foreground transition-colors">Cancel</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ─── Pay Invoice Modal ──────────────────────────────── */
function PayInvoiceModal({ invoice, onClose }: { invoice: Invoice; onClose: () => void }) {
  const [mode, setMode] = useState("upi");
  const due = invoice.amount - invoice.paid;

  const handleRecord = () => {
    toast.success("Payment recorded successfully.");
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Collect Payment</h2>
            <p className="text-xs text-muted-foreground mt-0.5">{invoice.number} · {invoice.patient}</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div className="bg-muted/30 rounded-lg px-4 py-3 flex justify-between items-center">
            <span className="text-xs text-muted-foreground">Balance Due</span>
            <span className="text-xl font-black text-red-600">₹{due.toLocaleString()}</span>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Amount</label>
            <div className="mt-1.5 relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm font-medium">₹</span>
              <input type="number" defaultValue={due} className="w-full pl-7 pr-3 py-2.5 text-lg font-bold border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground mb-2 block">Payment Mode</label>
            <div className="grid grid-cols-3 gap-2">
              {[{ id: "cash", label: "Cash", icon: Banknote }, { id: "upi", label: "UPI", icon: Smartphone }, { id: "card", label: "Card", icon: CreditCard }].map(m => {
                const Icon = m.icon;
                return (
                  <button key={m.id} onClick={() => setMode(m.id)} className={cn("flex flex-col items-center gap-1.5 p-2.5 rounded-lg border text-[10px] font-medium transition-all", mode === m.id ? "border-primary bg-primary/5 text-primary" : "border-border text-muted-foreground hover:border-primary/40")}>
                    <Icon className={cn("w-4 h-4", mode === m.id ? "text-primary" : "text-muted-foreground")} />
                    {m.label}
                  </button>
                );
              })}
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Transaction Reference</label>
            <input placeholder="UTR / Txn ID (optional)" className="mt-1.5 w-full px-3 py-2 text-xs border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Notes</label>
            <input placeholder="Optional notes" className="mt-1.5 w-full px-3 py-2 text-xs border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <button onClick={handleRecord} className="w-full py-2.5 bg-emerald-600 text-white text-sm font-semibold rounded-lg hover:bg-emerald-700">
            Record Payment
          </button>
          <button onClick={onClose} className="w-full py-2 text-sm text-muted-foreground hover:text-foreground">Cancel</button>
        </div>
      </div>
    </div>
  );
}

export function ReceptionistBillingScreen() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<InvoiceStatus | "All">("All");
  const [showCreate, setShowCreate] = useState(false);
  const [viewInvoice, setViewInvoice] = useState<Invoice | null>(null);
  const [payInvoice, setPayInvoice] = useState<Invoice | null>(null);

  const filtered = invoices.filter(inv => {
    const matchSearch = inv.patient.toLowerCase().includes(search.toLowerCase()) || inv.number.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === "All" || inv.status === statusFilter;
    return matchSearch && matchStatus;
  });

  return (
    <div className="p-6 space-y-6 bg-background min-h-full">
      {/* Metrics — white cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        {billingMetrics.map((m) => {
          const Icon = m.icon;
          return (
            <div key={m.label} className="bg-card border border-border rounded-xl p-4 flex items-center gap-3 shadow-sm hover:shadow-md transition-shadow">
              <div className={`w-9 h-9 rounded-lg ${m.iconBg} flex items-center justify-center shrink-0`}>
                <Icon className={`w-4.5 h-4.5 ${m.iconColor}`} />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">{m.label}</p>
                <p className={`text-xl font-black ${m.iconColor} mt-0.5`}>{m.value}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="px-5 py-4 border-b border-border flex items-center gap-4 flex-wrap">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search invoices, patients…" className="w-full pl-8 pr-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <div className="flex gap-1 flex-wrap">
            {(["All", "Paid", "Partial", "Overdue", "Draft", "Refunded"] as const).map(s => (
              <button key={s} onClick={() => setStatusFilter(s)} className={cn("px-3 py-1.5 rounded-md text-xs font-medium transition-colors", statusFilter === s ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:bg-muted/80")}>{s}</button>
            ))}
          </div>
          <button onClick={() => setShowCreate(true)} className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground text-xs font-medium rounded-md hover:bg-primary/90 ml-auto">
            <Plus className="w-3.5 h-3.5" /> New Invoice
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {["Invoice #", "Patient", "Date", "Amount", "Paid", "Due", "Status", "Actions"].map(h => (
                  <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.map((inv) => (
                <tr key={inv.id} className="hover:bg-muted/30 transition-colors group">
                  <td className="px-4 py-3 font-mono font-medium text-primary">{inv.number}</td>
                  <td className="px-4 py-3">
                    <p className="font-medium text-foreground">{inv.patient}</p>
                    <p className="text-muted-foreground text-[10px]">{inv.patientId}</p>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{inv.date}</td>
                  <td className="px-4 py-3 font-medium">₹{inv.amount.toLocaleString()}</td>
                  <td className="px-4 py-3 text-emerald-700 font-medium">₹{inv.paid.toLocaleString()}</td>
                  <td className="px-4 py-3 text-red-600 font-medium">₹{(inv.amount - inv.paid).toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${statusStyle[inv.status]}`}>{inv.status}</span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => setViewInvoice(inv)}
                        className="flex items-center gap-1 px-2 py-1 text-[10px] bg-muted text-foreground rounded hover:bg-muted/80 transition-colors"
                      >
                        <Eye className="w-3 h-3" /> View
                      </button>
                      {(inv.status === "Partial" || inv.status === "Overdue" || inv.status === "Draft") && (
                        <button
                          onClick={() => setPayInvoice(inv)}
                          className="flex items-center gap-1 px-2 py-1 text-[10px] bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200 transition-colors"
                        >
                          <IndianRupee className="w-3 h-3" /> Pay
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="px-5 py-3 border-t border-border flex items-center justify-between text-xs text-muted-foreground">
          <span>Showing {filtered.length} of {invoices.length} invoices</span>
          <span>Total Due: <span className="text-red-600 font-semibold">₹{invoices.filter(i => i.status !== "Paid" && i.status !== "Refunded").reduce((s, i) => s + (i.amount - i.paid), 0).toLocaleString()}</span></span>
        </div>
      </div>

      {showCreate && <CreateInvoiceModal onClose={() => setShowCreate(false)} />}
      {viewInvoice && <InvoiceDetailDrawer invoice={viewInvoice} onClose={() => setViewInvoice(null)} onPay={() => { setPayInvoice(viewInvoice); setViewInvoice(null); }} />}
      {payInvoice && <PayInvoiceModal invoice={payInvoice} onClose={() => setPayInvoice(null)} />}
    </div>
  );
}

/* ─── PAYMENTS ───────────────────────────────────────── */
type PaymentStatus = "Completed" | "Pending" | "Failed" | "Refund Requested" | "Refunded";

interface Payment {
  id: string;
  receipt: string;
  patient: string;
  invoice: string;
  amount: number;
  mode: string;
  status: PaymentStatus;
  date: string;
}

const payments: Payment[] = [
  { id: "p1", receipt: "RCP-1042", patient: "Anita Verma", invoice: "INV-2241", amount: 1200, mode: "UPI", status: "Completed", date: "19 Jun · 10:52" },
  { id: "p2", receipt: "RCP-1041", patient: "Raj Patel", invoice: "INV-2240", amount: 500, mode: "Cash", status: "Completed", date: "19 Jun · 10:31" },
  { id: "p3", receipt: "RCP-1040", patient: "Kavya Sharma", invoice: "INV-2237", amount: 650, mode: "Card", status: "Completed", date: "19 Jun · 09:48" },
  { id: "p4", receipt: "RCP-1039", patient: "Deepak Joshi", invoice: "INV-2236", amount: 200, mode: "UPI", status: "Completed", date: "19 Jun · 09:22" },
  { id: "p5", receipt: "RCP-1038", patient: "Priti Gupta", invoice: "INV-2235", amount: 1500, mode: "Net Banking", status: "Refund Requested", date: "18 Jun · 14:15" },
  { id: "p6", receipt: "RCP-1037", patient: "Sunita Mehta", invoice: "INV-2239", amount: 400, mode: "Cash", status: "Pending", date: "18 Jun · 11:00" },
];

const paymentModes = [
  { id: "cash", label: "Cash", icon: Banknote },
  { id: "upi", label: "UPI", icon: Smartphone },
  { id: "card", label: "Card", icon: CreditCard },
  { id: "netbanking", label: "Net Banking", icon: Globe },
  { id: "wallet", label: "Wallet", icon: Wallet },
  { id: "link", label: "Payment Link", icon: Send },
  { id: "advance", label: "Advance", icon: IndianRupee },
];

const payStatusStyle: Record<PaymentStatus, string> = {
  Completed: "bg-emerald-100 text-emerald-700",
  Pending: "bg-amber-100 text-amber-700",
  Failed: "bg-red-100 text-red-700",
  "Refund Requested": "bg-orange-100 text-orange-700",
  Refunded: "bg-purple-100 text-purple-700",
};

const modeStyle: Record<string, string> = {
  UPI: "bg-purple-100 text-purple-700",
  Cash: "bg-emerald-100 text-emerald-700",
  Card: "bg-blue-100 text-blue-700",
  "Net Banking": "bg-indigo-100 text-indigo-700",
  Wallet: "bg-orange-100 text-orange-700",
  Advance: "bg-amber-100 text-amber-700",
};

/* ─── Receipt Preview Modal ─────────────────────────── */
function ReceiptModal({ payment, onClose }: { payment: Payment; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-xs">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="font-semibold">Payment Receipt</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          {/* Receipt */}
          <div className="border-2 border-dashed border-border rounded-xl p-5 text-center space-y-3">
            <p className="text-xs text-muted-foreground uppercase tracking-widest">Verma Homeopathy Clinic</p>
            <h3 className="text-lg font-black">{payment.receipt}</h3>
            <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <p className="text-2xl font-black text-emerald-600">₹{payment.amount.toLocaleString()}</p>
            <div className="text-xs text-muted-foreground space-y-1">
              <p><span className="font-medium text-foreground">{payment.patient}</span></p>
              <p>{payment.invoice} · {payment.mode}</p>
              <p>{payment.date}</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button className="flex-1 py-2 border border-border text-xs rounded-lg hover:bg-muted flex items-center justify-center gap-1.5">
              <Download className="w-3.5 h-3.5" /> Download
            </button>
            <button onClick={onClose} className="flex-1 py-2 bg-primary text-primary-foreground text-xs rounded-lg hover:bg-primary/90">Close</button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ─── Refund Request Modal ───────────────────────────── */
function RefundModal({ payment, onClose }: { payment: Payment; onClose: () => void }) {
  const handleSubmit = () => {
    toast.success("Refund request submitted. Awaiting Admin approval.");
    onClose();
  };
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="font-semibold">Request Refund</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 text-xs text-amber-800 flex items-start gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-amber-500" />
            <p>Refund requests require Admin or Doctor approval. You can submit the request but cannot approve it.</p>
          </div>
          <div className="bg-muted/30 rounded-lg p-3 text-xs space-y-1">
            <div className="flex justify-between"><span className="text-muted-foreground">Receipt</span><span className="font-medium">{payment.receipt}</span></div>
            <div className="flex justify-between"><span className="text-muted-foreground">Patient</span><span className="font-medium">{payment.patient}</span></div>
            <div className="flex justify-between"><span className="text-muted-foreground">Original Amount</span><span className="font-medium text-emerald-700">₹{payment.amount.toLocaleString()}</span></div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Refund Amount</label>
            <div className="mt-1 relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">₹</span>
              <input type="number" defaultValue={payment.amount} className="w-full pl-7 pr-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Reason for Refund</label>
            <textarea rows={3} className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary resize-none" placeholder="Explain the reason for refund…" />
          </div>
          <div className="space-y-1.5">
            <button onClick={handleSubmit} className="w-full py-2.5 bg-amber-500 text-white text-sm font-semibold rounded-lg hover:bg-amber-600">Submit Refund Request</button>
            <button onClick={onClose} className="w-full py-2 text-sm text-muted-foreground hover:text-foreground">Cancel</button>
          </div>
          <p className="text-center text-[10px] text-muted-foreground">Status after submission: <span className="font-semibold text-amber-600">Pending Approval</span></p>
        </div>
      </div>
    </div>
  );
}

/* ─── Record Payment Modal ───────────────────────────── */
function RecordPaymentModal({ onClose }: { onClose: () => void }) {
  const [mode, setMode] = useState("upi");
  const [payType, setPayType] = useState<"full" | "partial" | "split">("full");
  const handleRecord = () => { toast.success("Payment recorded successfully."); onClose(); };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-md">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Record Payment</h2>
            <p className="text-xs text-muted-foreground mt-0.5">INV-2240 · Raj Patel · ₹350 due</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-2">Payment Type</p>
            <div className="grid grid-cols-3 gap-1.5 bg-muted/30 rounded-lg p-1">
              {(["full", "partial", "split"] as const).map(t => (
                <button key={t} onClick={() => setPayType(t)} className={cn("py-1.5 rounded-md text-xs font-medium capitalize transition-colors", payType === t ? "bg-card shadow-sm text-foreground" : "text-muted-foreground")}>{t}</button>
              ))}
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-muted-foreground">Amount</label>
            <div className="mt-1.5 relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm font-medium">₹</span>
              <input type="number" defaultValue={350} className="w-full pl-7 pr-3 py-2.5 text-lg font-bold border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          </div>
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-2">Payment Mode</p>
            <div className="grid grid-cols-4 gap-2">
              {paymentModes.map((m) => {
                const Icon = m.icon;
                return (
                  <button key={m.id} onClick={() => setMode(m.id)} className={cn("flex flex-col items-center gap-1.5 p-2.5 rounded-lg border text-[10px] font-medium transition-all", mode === m.id ? "border-primary bg-primary/5 text-primary" : "border-border text-muted-foreground hover:border-primary/50")}>
                    <Icon className={cn("w-4 h-4", mode === m.id ? "text-primary" : "text-muted-foreground")} />
                    {m.label}
                  </button>
                );
              })}
            </div>
          </div>
          <input placeholder="Transaction Reference (optional)" className="w-full px-3 py-2 text-xs border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          <button onClick={handleRecord} className="w-full py-2.5 bg-emerald-600 text-white text-sm font-semibold rounded-lg hover:bg-emerald-700">
            Confirm Payment & Generate Receipt
          </button>
          <button onClick={onClose} className="w-full py-2 text-sm text-muted-foreground hover:text-foreground">Cancel</button>
        </div>
      </div>
    </div>
  );
}

export function ReceptionistPaymentsScreen() {
  const [showPay, setShowPay] = useState(false);
  const [receiptPayment, setReceiptPayment] = useState<Payment | null>(null);
  const [refundPayment, setRefundPayment] = useState<Payment | null>(null);

  const payMetrics = [
    { label: "Cash Collections", value: "₹8,200", icon: Banknote, iconColor: "text-emerald-600", iconBg: "bg-emerald-50" },
    { label: "UPI Collections", value: "₹6,400", icon: Smartphone, iconColor: "text-purple-600", iconBg: "bg-purple-50" },
    { label: "Card Collections", value: "₹3,850", icon: CreditCard, iconColor: "text-blue-600", iconBg: "bg-blue-50" },
    { label: "Pending Dues", value: "₹5,200", icon: AlertCircle, iconColor: "text-red-500", iconBg: "bg-red-50" },
  ];

  return (
    <div className="p-6 space-y-6 bg-background min-h-full">
      {/* Metrics — white cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {payMetrics.map((m) => {
          const Icon = m.icon;
          return (
            <div key={m.label} className="bg-card border border-border rounded-xl p-4 flex items-center gap-3 shadow-sm hover:shadow-md transition-shadow">
              <div className={`w-9 h-9 rounded-lg ${m.iconBg} flex items-center justify-center shrink-0`}>
                <Icon className={`w-4.5 h-4.5 ${m.iconColor}`} />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">{m.label}</p>
                <p className={`text-lg font-black ${m.iconColor} mt-0.5`}>{m.value}</p>
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="px-5 py-4 border-b border-border flex items-center gap-3 flex-wrap">
          <h2 className="text-sm font-semibold">Payment Records</h2>
          <div className="ml-auto flex gap-2">
            <button onClick={() => setShowPay(true)} className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white text-xs font-medium rounded-md hover:bg-emerald-700">
              <Plus className="w-3.5 h-3.5" /> Record Payment
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {["Receipt No", "Patient", "Invoice", "Amount", "Mode", "Status", "Date", "Actions"].map(h => (
                  <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {payments.map((p) => (
                <tr key={p.id} className="hover:bg-muted/30 transition-colors group">
                  <td className="px-4 py-3 font-mono font-medium text-primary">{p.receipt}</td>
                  <td className="px-4 py-3 font-medium">{p.patient}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono">{p.invoice}</td>
                  <td className="px-4 py-3 font-semibold text-emerald-700">₹{p.amount.toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <span className={`px-1.5 py-0.5 rounded-full text-[10px] font-medium ${modeStyle[p.mode] ?? "bg-slate-100 text-slate-600"}`}>{p.mode}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${payStatusStyle[p.status]}`}>{p.status}</span>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{p.date}</td>
                  <td className="px-4 py-3">
                    <div className="flex gap-1.5">
                      <button onClick={() => setReceiptPayment(p)} className="px-2 py-1 text-[10px] bg-muted text-foreground rounded hover:bg-muted/80 flex items-center gap-1">
                        <Eye className="w-3 h-3" /> Receipt
                      </button>
                      {p.status === "Completed" && (
                        <button onClick={() => setRefundPayment(p)} className="px-2 py-1 text-[10px] bg-orange-100 text-orange-700 rounded hover:bg-orange-200 flex items-center gap-1">
                          <RefreshCw className="w-3 h-3" /> Refund
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showPay && <RecordPaymentModal onClose={() => setShowPay(false)} />}
      {receiptPayment && <ReceiptModal payment={receiptPayment} onClose={() => setReceiptPayment(null)} />}
      {refundPayment && <RefundModal payment={refundPayment} onClose={() => setRefundPayment(null)} />}
    </div>
  );
}

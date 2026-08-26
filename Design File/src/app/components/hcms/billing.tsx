import { Plus, Trash2, IndianRupee, Smartphone, Banknote, CreditCard, Building2, Link as LinkIcon } from "lucide-react";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { StatusPill, SectionHeader } from "./primitives";

const lines = [
  { label: "Consultation fee", qty: 1, rate: 800, total: 800 },
  { label: "Belladonna 200 (15ml)", qty: 1, rate: 180, total: 180 },
  { label: "Nat. Mur 30 (15ml)", qty: 1, rate: 160, total: 160 },
  { label: "Follow-up package", qty: 1, rate: 300, total: 300 },
];

const subtotal = lines.reduce((a, b) => a + b.total, 0);
const discount = 90;
const total = subtotal - discount;
const paid = 1000;
const due = total - paid;

const invoices = [
  { id: "INV-2041", patient: "Anita Sharma", amount: "₹1,250", status: "paid" },
  { id: "INV-2042", patient: "Rohit Mehra", amount: "₹860", status: "partial" },
  { id: "INV-2043", patient: "Sunita Tiwari", amount: "₹2,400", status: "paid" },
  { id: "INV-2044", patient: "Vikas Yadav", amount: "₹540", status: "due" },
  { id: "INV-2045", patient: "Priya Nair", amount: "₹1,180", status: "issued" },
  { id: "INV-2046", patient: "Aman Verma", amount: "₹720", status: "draft" },
];

export function BillingScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Billing & Payments</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Draft invoice for Anita Sharma · VHC-00821
          </p>
        </div>
        <div className="flex items-center gap-2">
          <StatusPill status="partial" />
          <Button variant="outline" size="sm">Save draft</Button>
          <Button size="sm">Issue invoice & collect</Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <Card className="p-0 lg:col-span-3 overflow-hidden">
          <div className="px-4 py-2.5 border-b border-border flex items-center justify-between">
            <div className="text-sm">Invoice line items</div>
            <Button size="sm" variant="ghost" className="text-primary">
              <Plus className="w-3.5 h-3.5" /> Add line
            </Button>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/60 text-xs text-muted-foreground">
              <tr>
                <th className="text-left px-3 py-2">Item</th>
                <th className="text-right px-3 py-2 w-16">Qty</th>
                <th className="text-right px-3 py-2 w-24">Rate</th>
                <th className="text-right px-3 py-2 w-24">Total</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {lines.map((l, i) => (
                <tr key={i} className="border-t border-border">
                  <td className="px-3 py-2.5">{l.label}</td>
                  <td className="px-3 py-2.5 text-right tabular-nums">{l.qty}</td>
                  <td className="px-3 py-2.5 text-right tabular-nums">₹{l.rate}</td>
                  <td className="px-3 py-2.5 text-right tabular-nums">₹{l.total}</td>
                  <td className="px-2">
                    <button className="text-muted-foreground hover:text-red-600">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="grid grid-cols-2 gap-6 p-4 border-t border-border">
            <div className="space-y-3">
              <div>
                <div className="text-xs text-muted-foreground mb-1">Discount type</div>
                <div className="flex gap-1.5">
                  {["Flat", "Percent", "None"].map((d, i) => (
                    <button
                      key={d}
                      className={`px-3 py-1.5 text-xs rounded-md border ${
                        i === 0
                          ? "bg-accent text-accent-foreground border-emerald-200"
                          : "border-border text-muted-foreground hover:bg-muted"
                      }`}
                    >
                      {d}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <div className="text-xs text-muted-foreground mb-1">Discount reason</div>
                <input
                  className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border outline-none"
                  defaultValue="Returning patient — courtesy"
                />
              </div>
            </div>
            <div className="space-y-1.5 text-sm">
              <Row label="Subtotal" value={`₹${subtotal.toLocaleString()}`} />
              <Row label="Discount" value={`− ₹${discount}`} />
              <Row label="Total" value={`₹${total.toLocaleString()}`} bold />
              <Row label="Paid" value={`₹${paid.toLocaleString()}`} muted />
              <Row label="Due" value={`₹${due.toLocaleString()}`} accent />
            </div>
          </div>
        </Card>

        <div className="lg:col-span-2 space-y-4">
          <Card className="p-4 gap-3">
            <SectionHeader
              title="Collect payment"
              description={`Outstanding ₹${due}`}
            />
            <div className="grid grid-cols-2 gap-2">
              {[
                { label: "UPI", icon: Smartphone, accent: true },
                { label: "Cash", icon: Banknote },
                { label: "Card", icon: CreditCard },
                { label: "Net banking", icon: Building2 },
                { label: "Payment link", icon: LinkIcon },
                { label: "Advance", icon: IndianRupee },
              ].map((m) => {
                const I = m.icon;
                return (
                  <button
                    key={m.label}
                    className={`flex items-center gap-2 px-3 py-2.5 rounded-md border text-sm ${
                      m.accent
                        ? "border-emerald-200 bg-accent text-accent-foreground"
                        : "border-border hover:bg-muted"
                    }`}
                  >
                    <I className="w-4 h-4" /> {m.label}
                  </button>
                );
              })}
            </div>
            <div className="grid grid-cols-2 gap-2 pt-2">
              <div>
                <div className="text-xs text-muted-foreground mb-1">Amount</div>
                <input
                  className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border outline-none"
                  defaultValue="₹450"
                />
              </div>
              <div>
                <div className="text-xs text-muted-foreground mb-1">Reference</div>
                <input
                  className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border outline-none"
                  defaultValue="UPI · 312041****"
                />
              </div>
            </div>
            <Button className="w-full mt-1">Record payment & send receipt</Button>
            <div className="text-[11px] text-muted-foreground text-center">
              Receipt auto-emailed and SMS-linked · Razorpay reconciliation enabled
            </div>
          </Card>

          <Card className="p-0 overflow-hidden">
            <div className="px-4 py-2.5 border-b border-border text-sm">Recent invoices</div>
            <ul className="divide-y divide-border text-sm">
              {invoices.map((i) => (
                <li key={i.id} className="flex items-center gap-2 px-4 py-2.5">
                  <div className="font-mono text-xs text-muted-foreground w-20">{i.id}</div>
                  <div className="flex-1 truncate">{i.patient}</div>
                  <div className="tabular-nums text-sm">{i.amount}</div>
                  <StatusPill status={i.status} />
                </li>
              ))}
            </ul>
          </Card>
        </div>
      </div>
    </div>
  );
}

function Row({
  label,
  value,
  bold,
  muted,
  accent,
}: {
  label: string;
  value: string;
  bold?: boolean;
  muted?: boolean;
  accent?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between px-3 py-1.5 rounded-md ${
        accent ? "bg-amber-50 text-amber-900" : ""
      }`}
    >
      <span className={muted ? "text-muted-foreground" : "text-foreground/80"}>
        {label}
      </span>
      <span className={`tabular-nums ${bold ? "text-base" : ""}`}>{value}</span>
    </div>
  );
}

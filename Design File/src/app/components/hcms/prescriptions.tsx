import { Plus, Trash2, Download, Printer, Pencil } from "lucide-react";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { StatusPill } from "./primitives";

const items = [
  { name: "Belladonna", potency: "200", dose: "5 globules", freq: "OD", duration: "7 days", instr: "Empty stomach, morning" },
  { name: "Nat. Mur", potency: "30", dose: "4 globules", freq: "BD", duration: "5 days", instr: "After meals" },
  { name: "Placebo", potency: "—", dose: "5 globules", freq: "TDS", duration: "14 days", instr: "Continue till review" },
];

export function PrescriptionsScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Digital Prescription</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Patient: Anita Sharma · VHC-00821 · Visit on 14 May 2026
          </p>
        </div>
        <div className="flex items-center gap-2">
          <StatusPill status="draft" />
          <Button variant="outline" size="sm">
            <Pencil className="w-3.5 h-3.5" /> Switch to handwritten
          </Button>
          <Button variant="outline" size="sm">
            <Printer className="w-3.5 h-3.5" /> Print
          </Button>
          <Button size="sm">
            <Download className="w-3.5 h-3.5" /> Finalize & sign
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <Card className="p-0 lg:col-span-3 overflow-hidden">
          <div className="px-4 py-2.5 border-b border-border flex items-center justify-between">
            <div className="text-sm">Rx — Medicine table</div>
            <Button size="sm" variant="ghost" className="text-primary">
              <Plus className="w-3.5 h-3.5" /> Add medicine
            </Button>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/60 text-xs text-muted-foreground">
              <tr>
                <th className="text-left px-3 py-2">Medicine</th>
                <th className="text-left px-3 py-2 w-20">Potency</th>
                <th className="text-left px-3 py-2 w-28">Dose</th>
                <th className="text-left px-3 py-2 w-20">Freq</th>
                <th className="text-left px-3 py-2 w-28">Duration</th>
                <th className="text-left px-3 py-2">Instructions</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {items.map((it, i) => (
                <tr key={i} className="border-t border-border">
                  <td className="px-3 py-2.5">{it.name}</td>
                  <td className="px-3 py-2.5">{it.potency}</td>
                  <td className="px-3 py-2.5">{it.dose}</td>
                  <td className="px-3 py-2.5">{it.freq}</td>
                  <td className="px-3 py-2.5">{it.duration}</td>
                  <td className="px-3 py-2.5 text-muted-foreground">{it.instr}</td>
                  <td className="px-2">
                    <button className="text-muted-foreground hover:text-red-600">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="grid grid-cols-2 gap-3 p-4 border-t border-border">
            <div>
              <div className="text-xs text-muted-foreground mb-1">General advice</div>
              <textarea
                className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border min-h-[64px] outline-none"
                defaultValue="Avoid bright sunlight, maintain hydration log, sleep 7+ hrs."
              />
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-1">Review</div>
              <input
                className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border outline-none"
                defaultValue="28 May 2026 (in 14 days)"
              />
              <div className="text-xs text-muted-foreground mt-2">
                Signature locked on finalize · prescription becomes immutable
              </div>
            </div>
          </div>
        </Card>

        <Card className="p-0 lg:col-span-2 overflow-hidden bg-white">
          <div className="px-4 py-2 border-b border-border bg-muted/40 text-xs text-muted-foreground flex items-center justify-between">
            <span>PDF preview · A5 portrait</span>
            <span>Page 1 of 1</span>
          </div>
          <div className="p-5 text-[12px] leading-relaxed">
            <div className="text-center pb-3 border-b border-border">
              <div className="text-base">Dr. Vishvesh Kumar Verma</div>
              <div className="text-[10px] text-muted-foreground">
                B.H.M.S, M.D. (Hom) · Reg. MP-HC-12489
              </div>
              <div className="text-[10px] text-muted-foreground">
                Verma Homeopathy Clinic · Vijay Nagar, Indore · +91 731 4001 234
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2 py-2 text-[11px]">
              <div>
                <div className="text-muted-foreground">Patient</div>
                Anita Sharma · 42F
              </div>
              <div className="text-right">
                <div className="text-muted-foreground">Date</div>
                14 May 2026
              </div>
              <div>
                <div className="text-muted-foreground">Patient ID</div>
                VHC-00821
              </div>
              <div className="text-right">
                <div className="text-muted-foreground">Visit</div>
                #5 · Follow-up
              </div>
            </div>
            <div className="border-t border-border pt-2">
              <div className="text-base mb-1">℞</div>
              <ol className="space-y-1.5 list-decimal pl-4">
                {items.map((it, i) => (
                  <li key={i}>
                    <div>
                      <strong>{it.name}</strong> {it.potency} — {it.dose}, {it.freq} × {it.duration}
                    </div>
                    <div className="text-muted-foreground text-[11px]">{it.instr}</div>
                  </li>
                ))}
              </ol>
            </div>
            <div className="mt-3 pt-2 border-t border-border">
              <div className="text-muted-foreground text-[11px]">Advice</div>
              Avoid bright sunlight, maintain hydration log, sleep 7+ hrs.
            </div>
            <div className="mt-2 text-[11px]">
              <span className="text-muted-foreground">Review on:</span> 28 May 2026
            </div>
            <div className="mt-8 text-right">
              <div className="inline-block border-t border-border pt-1 text-[11px]">
                Dr. V. K. Verma
              </div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

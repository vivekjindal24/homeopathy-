import { Fragment } from "react";
import { Plus, ChevronLeft, ChevronRight } from "lucide-react";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { StatusPill, SectionHeader } from "./primitives";

const queue = [
  { token: "T-12", time: "10:00", patient: "Anita Sharma", code: "VHC-00821", reason: "Follow-up · Migraine", status: "in consultation" },
  { token: "T-13", time: "10:15", patient: "Rohit Mehra", code: "VHC-00822", reason: "Eczema review", status: "arrived" },
  { token: "T-14", time: "10:30", patient: "Sunita Tiwari", code: "VHC-00823", reason: "BP follow-up", status: "arrived" },
  { token: "T-15", time: "10:45", patient: "Vikas Yadav", code: "VHC-00824", reason: "Anxiety initial", status: "scheduled" },
  { token: "T-16", time: "11:00", patient: "Priya Nair", code: "VHC-00825", reason: "PCOD follow-up", status: "scheduled" },
  { token: "T-17", time: "11:15", patient: "Aman Verma", code: "VHC-00826", reason: "Asthma review", status: "scheduled" },
];

const days = ["Mon 11", "Tue 12", "Wed 13", "Thu 14", "Fri 15", "Sat 16", "Sun 17"];
const hours = ["09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00"];

const slots: { d: number; h: number; label: string; status: string }[] = [
  { d: 0, h: 1, label: "A. Sharma", status: "completed" },
  { d: 0, h: 3, label: "K. Joshi", status: "completed" },
  { d: 1, h: 0, label: "R. Mehra", status: "completed" },
  { d: 1, h: 2, label: "S. Tiwari", status: "completed" },
  { d: 2, h: 4, label: "P. Nair", status: "completed" },
  { d: 3, h: 1, label: "A. Sharma", status: "in consultation" },
  { d: 3, h: 1, label: "R. Mehra", status: "arrived" },
  { d: 3, h: 2, label: "V. Yadav", status: "scheduled" },
  { d: 3, h: 3, label: "Aman V.", status: "scheduled" },
  { d: 4, h: 2, label: "M. Khan", status: "scheduled" },
  { d: 5, h: 4, label: "N. Gupta", status: "scheduled" },
];

const statusBg: Record<string, string> = {
  completed: "bg-emerald-100/70 border-emerald-300 text-emerald-900",
  "in consultation": "bg-amber-100 border-amber-300 text-amber-900",
  arrived: "bg-blue-100 border-blue-300 text-blue-900",
  scheduled: "bg-slate-100 border-slate-300 text-slate-700",
};

export function AppointmentsScreen() {
  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Appointments</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Week of 11 — 17 May 2026 · Dr. V. K. Verma
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center rounded-md border border-border overflow-hidden">
            <button className="px-3 py-1.5 text-xs hover:bg-muted">Day</button>
            <button className="px-3 py-1.5 text-xs bg-accent text-accent-foreground border-x border-border">
              Week
            </button>
            <button className="px-3 py-1.5 text-xs hover:bg-muted">Queue</button>
          </div>
          <Button variant="outline" size="sm">
            <ChevronLeft className="w-3.5 h-3.5" />
          </Button>
          <Button variant="outline" size="sm">
            Today
          </Button>
          <Button variant="outline" size="sm">
            <ChevronRight className="w-3.5 h-3.5" />
          </Button>
          <Button size="sm">
            <Plus className="w-3.5 h-3.5" /> Book
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-3 lg:col-span-2 gap-2">
          <div className="grid" style={{ gridTemplateColumns: "60px repeat(7, 1fr)" }}>
            <div />
            {days.map((d, i) => (
              <div
                key={d}
                className={`text-xs text-center px-2 py-2 rounded-md ${
                  i === 3 ? "bg-accent text-accent-foreground" : "text-muted-foreground"
                }`}
              >
                {d}
              </div>
            ))}
            {hours.map((h, hi) => (
              <Fragment key={hi}>
                <div className="text-[11px] text-muted-foreground py-2 pr-2 text-right border-t border-border">
                  {h}
                </div>
                {days.map((_, di) => {
                  const items = slots.filter((s) => s.d === di && s.h === hi);
                  return (
                    <div
                      key={`${hi}-${di}`}
                      className="border-t border-l border-border min-h-[44px] p-1 space-y-1"
                    >
                      {items.map((it, ii) => (
                        <div
                          key={ii}
                          className={`text-[11px] px-1.5 py-1 rounded border-l-2 truncate ${statusBg[it.status]}`}
                        >
                          {it.label}
                        </div>
                      ))}
                    </div>
                  );
                })}
              </Fragment>
            ))}
          </div>
        </Card>

        <Card className="p-4 gap-3">
          <SectionHeader
            title="Today's queue"
            description="6 in queue · avg wait 8 min"
          />
          <ul className="space-y-2">
            {queue.map((q) => (
              <li
                key={q.token}
                className="flex items-center gap-3 p-2.5 rounded-md border border-border hover:border-primary/40 transition-colors"
              >
                <div className="w-10 text-center">
                  <div className="text-[11px] text-muted-foreground">{q.time}</div>
                  <div className="text-sm tracking-tight">{q.token}</div>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm truncate">{q.patient}</div>
                  <div className="text-xs text-muted-foreground truncate">
                    {q.code} · {q.reason}
                  </div>
                </div>
                <StatusPill status={q.status} />
              </li>
            ))}
          </ul>
        </Card>
      </div>
    </div>
  );
}

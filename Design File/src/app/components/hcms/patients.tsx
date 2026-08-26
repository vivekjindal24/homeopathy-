import { useState } from "react";
import {
  Plus,
  Filter,
  Download,
  ChevronRight,
  Phone,
  MapPin,
  Calendar,
  FileText,
  Paperclip,
  AlertCircle,
} from "lucide-react";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { StatusPill, SectionHeader } from "./primitives";

const patients = [
  { code: "VHC-00821", name: "Anita Sharma", age: 42, sex: "F", phone: "+91 98260 11234", last: "12 May", status: "active", chronic: "Migraine" },
  { code: "VHC-00822", name: "Rohit Mehra", age: 35, sex: "M", phone: "+91 99814 56012", last: "11 May", status: "follow-up", chronic: "Eczema" },
  { code: "VHC-00823", name: "Sunita Tiwari", age: 58, sex: "F", phone: "+91 90035 88001", last: "09 May", status: "active", chronic: "Hypertension" },
  { code: "VHC-00824", name: "Vikas Yadav", age: 28, sex: "M", phone: "+91 98931 77821", last: "07 May", status: "active", chronic: "Anxiety" },
  { code: "VHC-00825", name: "Priya Nair", age: 31, sex: "F", phone: "+91 70001 23410", last: "05 May", status: "follow-up", chronic: "PCOD" },
  { code: "VHC-00826", name: "Aman Verma", age: 9, sex: "M", phone: "+91 88829 10004", last: "02 May", status: "active", chronic: "Asthma" },
];

const filters = ["All", "Active", "Follow-up due", "New this week", "Pediatric", "Archived"];

export function PatientsScreen() {
  const [active, setActive] = useState("All");
  const [selected, setSelected] = useState(patients[0]);

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl">Patients</h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            1,284 total · 42 added this week
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm">
            <Download className="w-3.5 h-3.5" /> Export
          </Button>
          <Button size="sm">
            <Plus className="w-3.5 h-3.5" /> New patient
          </Button>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        {filters.map((f) => (
          <button
            key={f}
            onClick={() => setActive(f)}
            className={`px-3 py-1 rounded-full text-xs ring-1 ring-inset transition-colors ${
              active === f
                ? "bg-accent text-accent-foreground ring-emerald-200"
                : "bg-card text-muted-foreground ring-border hover:bg-muted"
            }`}
          >
            {f}
          </button>
        ))}
        <div className="ml-auto flex items-center gap-2 text-xs text-muted-foreground">
          <Filter className="w-3.5 h-3.5" /> Sort: Recently visited
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <Card className="p-0 lg:col-span-3 overflow-hidden gap-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/60 text-xs text-muted-foreground sticky top-0">
                <tr>
                  <th className="text-left px-4 py-2.5">Patient</th>
                  <th className="text-left px-4 py-2.5">Code</th>
                  <th className="text-left px-4 py-2.5">Phone</th>
                  <th className="text-left px-4 py-2.5">Last visit</th>
                  <th className="text-left px-4 py-2.5">Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {patients.map((p) => {
                  const active = selected.code === p.code;
                  return (
                    <tr
                      key={p.code}
                      onClick={() => setSelected(p)}
                      className={`border-t border-border cursor-pointer ${
                        active ? "bg-accent/60" : "hover:bg-muted/40"
                      }`}
                    >
                      <td className="px-4 py-2.5">
                        <div className="flex items-center gap-2.5">
                          <Avatar className="w-8 h-8">
                            <AvatarFallback className="bg-muted text-xs">
                              {p.name
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <div className="leading-tight">
                            <div>{p.name}</div>
                            <div className="text-xs text-muted-foreground">
                              {p.age} · {p.sex} · {p.chronic}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-2.5 font-mono text-xs">{p.code}</td>
                      <td className="px-4 py-2.5 text-muted-foreground">{p.phone}</td>
                      <td className="px-4 py-2.5 text-muted-foreground">{p.last}</td>
                      <td className="px-4 py-2.5">
                        <StatusPill status={p.status} />
                      </td>
                      <td className="px-2 py-2.5 text-muted-foreground">
                        <ChevronRight className="w-4 h-4" />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="px-4 py-2.5 border-t border-border flex items-center justify-between text-xs text-muted-foreground">
            <span>Showing 1–6 of 1,284</span>
            <div className="flex items-center gap-1">
              <button className="px-2 py-1 rounded hover:bg-muted">Prev</button>
              <span className="px-2">1 / 214</span>
              <button className="px-2 py-1 rounded hover:bg-muted">Next</button>
            </div>
          </div>
        </Card>

        <Card className="p-0 lg:col-span-2 overflow-hidden">
          <div className="p-4 border-b border-border">
            <div className="flex items-start gap-3">
              <Avatar className="w-12 h-12">
                <AvatarFallback className="bg-primary text-primary-foreground">
                  {selected.name
                    .split(" ")
                    .map((n) => n[0])
                    .join("")}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="text-sm">{selected.name}</h3>
                  <StatusPill status={selected.status} />
                </div>
                <div className="text-xs text-muted-foreground mt-0.5">
                  {selected.code} · {selected.age}{selected.sex.toLowerCase()} · {selected.chronic}
                </div>
                <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-muted-foreground">
                  <span className="inline-flex items-center gap-1">
                    <Phone className="w-3 h-3" /> {selected.phone}
                  </span>
                  <span className="inline-flex items-center gap-1">
                    <MapPin className="w-3 h-3" /> Vijay Nagar, Indore
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="px-4 pt-3 flex items-center gap-1 border-b border-border text-xs">
            {["Timeline", "Prescriptions", "Billing", "Files"].map((t, i) => (
              <button
                key={t}
                className={`px-3 py-2 -mb-px border-b-2 ${
                  i === 0
                    ? "border-primary text-primary"
                    : "border-transparent text-muted-foreground hover:text-foreground"
                }`}
              >
                {t}
              </button>
            ))}
          </div>

          <div className="p-4 space-y-3">
            {[
              { date: "12 May 2026", title: "Follow-up consultation", note: "Improvement in headache frequency. Continue Belladonna 200.", icon: Calendar },
              { date: "28 Apr 2026", title: "Digital prescription issued", note: "INV-1992 · ₹1,250", icon: FileText },
              { date: "14 Apr 2026", title: "Case taking — initial", note: "Chief complaint: Recurrent migraine 4y", icon: Calendar },
              { date: "14 Apr 2026", title: "Lab report attached", note: "CBC, Vitamin D · 2 files", icon: Paperclip },
            ].map((e, i) => {
              const I = e.icon;
              return (
                <div key={i} className="flex gap-3">
                  <div className="flex flex-col items-center">
                    <div className="w-7 h-7 rounded-full bg-accent text-primary flex items-center justify-center">
                      <I className="w-3.5 h-3.5" />
                    </div>
                    {i < 3 && <div className="w-px flex-1 bg-border mt-1" />}
                  </div>
                  <div className="pb-3">
                    <div className="text-xs text-muted-foreground">{e.date}</div>
                    <div className="text-sm">{e.title}</div>
                    <div className="text-xs text-muted-foreground">{e.note}</div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="px-4 py-3 border-t border-border bg-amber-50/40 flex items-start gap-2">
            <AlertCircle className="w-4 h-4 text-amber-700 mt-0.5" />
            <div className="text-xs text-amber-900">
              <strong>Allergy:</strong> Sulphonamides · noted on intake form.
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

import { Save, FileSignature, Pencil, History, Maximize2 } from "lucide-react";
import { Card } from "../ui/card";
import { Button } from "../ui/button";
import { StatusPill } from "./primitives";

const sections = [
  { label: "Chief complaints", value: "Recurrent migraine, throbbing left temporal region. Onset: 4 years. Aggravated by sun exposure, mental exertion." },
  { label: "Modalities", value: "Worse: heat, light, noise. Better: dark room, cold application, sleep." },
  { label: "Mental symptoms", value: "Anxious, irritable during episodes. Wants to be alone. Aversion to consolation." },
  { label: "Physical generals", value: "Thermal: hot patient. Thirst: large quantity, infrequent. Perspiration: scanty. Sleep: disturbed during episodes." },
  { label: "Cravings / aversions", value: "Cravings: salty, cold drinks. Aversions: sweets." },
  { label: "Past history", value: "Tonsillectomy (2008). Recurrent UTI 2018-19." },
  { label: "Family history", value: "Mother — migraine. Father — hypertension." },
];

const previous = [
  { date: "28 Apr 2026", remedy: "Belladonna 200, OD × 7d", note: "Frequency reduced from 5 → 2 episodes/week" },
  { date: "14 Apr 2026", remedy: "Bryonia 30, BD × 5d", note: "Initial — partial relief" },
];

export function ConsultationScreen() {
  return (
    <div className="flex flex-col h-[calc(100vh-3.5rem)]">
      <div className="px-6 py-3 border-b border-border bg-card flex items-center gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base">Anita Sharma</h2>
            <StatusPill status="in consultation" />
            <span className="text-xs text-muted-foreground">VHC-00821 · 42F · Visit #5</span>
          </div>
          <div className="text-xs text-muted-foreground mt-0.5">
            Token T-12 · Started 10:04 · Followup of 28 Apr 2026
          </div>
        </div>
        <div className="ml-auto flex items-center gap-2">
          <Button variant="outline" size="sm">
            <Maximize2 className="w-3.5 h-3.5" /> Distraction-free
          </Button>
          <Button variant="outline" size="sm">
            <Pencil className="w-3.5 h-3.5" /> Handwritten
          </Button>
          <Button variant="outline" size="sm">
            <Save className="w-3.5 h-3.5" /> Save draft
          </Button>
          <Button size="sm">
            <FileSignature className="w-3.5 h-3.5" /> Finalize & prescribe
          </Button>
        </div>
      </div>

      <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-4 p-6 overflow-auto">
        <div className="lg:col-span-2 space-y-3">
          <Card className="p-0 overflow-hidden">
            <div className="px-4 py-2.5 border-b border-border flex items-center justify-between">
              <div className="text-sm">Case taking · Visit on 14 May 2026</div>
              <div className="text-xs text-muted-foreground">Template: Migraine — Chronic</div>
            </div>
            <div className="divide-y divide-border">
              {sections.map((s) => (
                <div key={s.label} className="px-4 py-3 grid grid-cols-1 md:grid-cols-4 gap-3">
                  <div className="text-xs text-muted-foreground md:pt-1">{s.label}</div>
                  <div className="md:col-span-3">
                    <div className="text-sm bg-muted/50 rounded-md px-3 py-2 border border-border min-h-[40px]">
                      {s.value}
                    </div>
                  </div>
                </div>
              ))}
              <div className="px-4 py-3">
                <div className="text-xs text-muted-foreground mb-1.5">Doctor notes</div>
                <textarea
                  className="w-full text-sm bg-muted/50 rounded-md px-3 py-2 border border-border min-h-[80px] outline-none focus:border-primary/40"
                  defaultValue="Continue Belladonna 200; review in 14 days. Advise sleep hygiene + hydration log."
                />
              </div>
            </div>
          </Card>
        </div>

        <div className="space-y-3">
          <Card className="p-4 gap-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <History className="w-4 h-4 text-muted-foreground" />
                <div className="text-sm">Previous visits</div>
              </div>
              <button className="text-xs text-primary">Compare</button>
            </div>
            <ul className="space-y-2.5">
              {previous.map((p, i) => (
                <li key={i} className="text-xs border border-border rounded-md p-2.5">
                  <div className="flex items-center justify-between text-muted-foreground">
                    <span>{p.date}</span>
                    <span>Visit #{4 - i}</span>
                  </div>
                  <div className="mt-1 text-sm">{p.remedy}</div>
                  <div className="text-xs text-muted-foreground mt-1">{p.note}</div>
                </li>
              ))}
            </ul>
          </Card>

          <Card className="p-4 gap-2">
            <div className="text-sm">Quick remedies</div>
            <div className="flex flex-wrap gap-1.5">
              {["Belladonna 200", "Bryonia 30", "Nat. Mur 200", "Pulsatilla 30", "Sepia 200", "Ignatia 1M"].map((r) => (
                <span key={r} className="text-xs px-2 py-1 rounded-md bg-muted hover:bg-accent cursor-pointer">
                  {r}
                </span>
              ))}
            </div>
          </Card>

          <Card className="p-4 gap-2 border-amber-200 bg-amber-50/50">
            <div className="text-xs text-amber-900">
              <strong>Allergy:</strong> Sulphonamides
            </div>
            <div className="text-xs text-amber-900">
              <strong>Chronic:</strong> Migraine · 4y
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

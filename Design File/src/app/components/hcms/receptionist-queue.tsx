import { useState } from "react";
import {
  Clock,
  CheckCircle2,
  UserX,
  RotateCcw,
  Play,
  Timer,
  Users,
  TrendingUp,
  ListOrdered,
  X,
  Stethoscope,
  IndianRupee,
  FileText,
} from "lucide-react";
import { cn } from "../ui/utils";
import { toast } from "sonner";

/* ─── Types ─────────────────────────────────────────── */
type QueueStatus = "waiting" | "consultation" | "completed" | "no_show";
type FeeStatus = "Pending Payment" | "Paid" | "Follow-Up Exempt";

interface QueueEntry {
  id: string;
  token: string;
  name: string;
  age: number;
  gender: string;
  arrivalTime: string;
  startTime?: string;
  type: "New" | "Follow Up" | "Walk-In";
  waitMins: number;
  status: QueueStatus;
  mobile: string;
  feeStatus: FeeStatus;
  doctor: string;
}

/* ─── Mock data ─────────────────────────────────────── */
const initialQueue: QueueEntry[] = [
  { id: "q1", token: "T-21", name: "Anita Verma", age: 34, gender: "F", arrivalTime: "10:45 AM", type: "Follow Up", waitMins: 22, status: "waiting", mobile: "98765-43210", feeStatus: "Follow-Up Exempt", doctor: "Dr. Verma" },
  { id: "q2", token: "T-22", name: "Raj Patel", age: 28, gender: "M", arrivalTime: "11:00 AM", type: "New", waitMins: 7, status: "waiting", mobile: "87654-32109", feeStatus: "Pending Payment", doctor: "Dr. Verma" },
  { id: "q3", token: "T-23", name: "Priti Gupta", age: 52, gender: "F", arrivalTime: "11:10 AM", type: "New", waitMins: 0, status: "waiting", mobile: "76543-21098", feeStatus: "Paid", doctor: "Dr. Verma" },
  { id: "q4", token: "T-19", name: "Sunita Mehta", age: 41, gender: "F", arrivalTime: "10:15 AM", startTime: "10:52 AM", type: "Follow Up", waitMins: 52, status: "consultation", mobile: "65432-10987", feeStatus: "Follow-Up Exempt", doctor: "Dr. Verma" },
  { id: "q6", token: "T-17", name: "Kavya Sharma", age: 29, gender: "F", arrivalTime: "09:30 AM", type: "Follow Up", waitMins: 0, status: "completed", mobile: "43210-98765", feeStatus: "Paid", doctor: "Dr. Verma" },
  { id: "q7", token: "T-18", name: "Deepak Joshi", age: 44, gender: "M", arrivalTime: "09:45 AM", type: "New", waitMins: 0, status: "completed", mobile: "32109-87654", feeStatus: "Paid", doctor: "Dr. Verma" },
  { id: "q8", token: "T-16", name: "Mona Patel", age: 38, gender: "F", arrivalTime: "09:15 AM", type: "Follow Up", waitMins: 0, status: "completed", mobile: "21098-76543", feeStatus: "Follow-Up Exempt", doctor: "Dr. Verma" },
  { id: "q10", token: "T-12", name: "Meera Gupta", age: 31, gender: "F", arrivalTime: "08:30 AM", type: "Follow Up", waitMins: 0, status: "no_show", mobile: "09876-54321", feeStatus: "Follow-Up Exempt", doctor: "Dr. Verma" },
  { id: "q11", token: "T-15", name: "Ashok Kumar", age: 47, gender: "M", arrivalTime: "09:00 AM", type: "New", waitMins: 0, status: "no_show", mobile: "98765-11223", feeStatus: "Pending Payment", doctor: "Dr. Verma" },
];

const feeStatusStyle: Record<FeeStatus, string> = {
  "Paid": "bg-emerald-100 text-emerald-700",
  "Pending Payment": "bg-amber-100 text-amber-700",
  "Follow-Up Exempt": "bg-slate-100 text-slate-600",
};

const typeColors: Record<string, string> = {
  "New": "bg-blue-100 text-blue-700",
  "Follow Up": "bg-purple-100 text-purple-700",
  "Walk-In": "bg-amber-100 text-amber-700",
};

/* ─── Complete Consultation Modal ───────────────────── */
function CompleteModal({ entry, onClose, onComplete }: { entry: QueueEntry; onClose: () => void; onComplete: (id: string) => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h3 className="font-semibold">Complete Consultation</h3>
          <button onClick={onClose} className="p-1 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-xs space-y-1.5">
            <div className="flex gap-2"><span className="text-muted-foreground w-20">Token</span><span className="font-bold text-blue-700 text-base">{entry.token}</span></div>
            <div className="flex gap-2"><span className="text-muted-foreground w-20">Patient</span><span className="font-medium">{entry.name}</span></div>
            <div className="flex gap-2"><span className="text-muted-foreground w-20">Started</span><span>{entry.startTime ?? "–"}</span></div>
            <div className="flex gap-2"><span className="text-muted-foreground w-20">Doctor</span><span>{entry.doctor}</span></div>
          </div>
          <p className="text-xs text-muted-foreground">Completing this consultation will generate a visit record and prompt invoice creation.</p>
          <div className="flex gap-2">
            <button onClick={onClose} className="flex-1 py-2 border border-border rounded-lg text-sm text-muted-foreground hover:bg-muted">Cancel</button>
            <button
              onClick={() => { onComplete(entry.id); onClose(); }}
              className="flex-1 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700"
            >
              Complete Consultation
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ─── Waiting Card ───────────────────────────────────── */
function WaitingCard({ entry, onStart, onNoShow }: { entry: QueueEntry; onStart: (id: string) => void; onNoShow: (id: string) => void }) {
  const isConsultBusy = false;
  return (
    <div className="bg-card border border-border rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div>
          <span className="text-2xl font-black text-amber-600 leading-none">{entry.token}</span>
          <div className="mt-1">
            <p className="text-sm font-semibold text-foreground">{entry.name}</p>
            <p className="text-[11px] text-muted-foreground">{entry.age}y · {entry.gender === "M" ? "Male" : "Female"}</p>
          </div>
        </div>
        <div className="flex flex-col items-end gap-1.5">
          <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${typeColors[entry.type]}`}>{entry.type}</span>
          <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${feeStatusStyle[entry.feeStatus]}`}>{entry.feeStatus}</span>
        </div>
      </div>
      <div className="flex items-center gap-1 text-[11px] text-muted-foreground mb-3">
        <Clock className="w-3 h-3" />{entry.arrivalTime}
        {entry.waitMins > 0 && (
          <span className={cn("ml-2 flex items-center gap-0.5 font-medium", entry.waitMins > 20 ? "text-red-600" : "text-amber-600")}>
            <Timer className="w-3 h-3" />{entry.waitMins}m wait
          </span>
        )}
      </div>
      <div className="flex gap-2">
        <button
          onClick={() => onStart(entry.id)}
          className="flex-1 flex items-center justify-center gap-1.5 py-1.5 bg-primary text-primary-foreground text-xs font-medium rounded-lg hover:bg-primary/90 transition-colors"
        >
          <Play className="w-3.5 h-3.5" /> Start
        </button>
        <button
          onClick={() => onNoShow(entry.id)}
          className="flex-1 flex items-center justify-center gap-1.5 py-1.5 border border-border text-xs font-medium rounded-lg text-muted-foreground hover:bg-muted transition-colors"
        >
          <UserX className="w-3.5 h-3.5" /> No Show
        </button>
      </div>
    </div>
  );
}

/* ─── Active Consultation Card ───────────────────────── */
function ActiveConsultationCard({ entry, onComplete }: { entry: QueueEntry; onComplete: () => void }) {
  return (
    <div className="bg-blue-50 border-2 border-blue-300 rounded-xl p-5 shadow-md">
      <div className="flex items-center gap-2 mb-4">
        <span className="flex items-center gap-1.5 text-[11px] font-semibold text-blue-700 uppercase tracking-wider">
          <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
          Active Consultation
        </span>
      </div>
      <div className="text-4xl font-black text-blue-700 mb-2 leading-none">{entry.token}</div>
      <p className="text-base font-bold text-foreground">{entry.name}</p>
      <p className="text-xs text-muted-foreground mt-0.5">{entry.age}y · {entry.gender === "M" ? "Male" : "Female"} · {entry.mobile}</p>
      <div className="mt-4 grid grid-cols-2 gap-3 text-xs">
        <div className="bg-white/80 rounded-lg p-2.5">
          <p className="text-muted-foreground">Started</p>
          <p className="font-semibold mt-0.5">{entry.startTime ?? "–"}</p>
        </div>
        <div className="bg-white/80 rounded-lg p-2.5">
          <p className="text-muted-foreground">Doctor</p>
          <p className="font-semibold mt-0.5">{entry.doctor}</p>
        </div>
        <div className="bg-white/80 rounded-lg p-2.5">
          <p className="text-muted-foreground">Type</p>
          <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${typeColors[entry.type]}`}>{entry.type}</span>
        </div>
        <div className="bg-white/80 rounded-lg p-2.5">
          <p className="text-muted-foreground">Fee Status</p>
          <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${feeStatusStyle[entry.feeStatus]}`}>{entry.feeStatus}</span>
        </div>
      </div>
      <button
        onClick={onComplete}
        className="mt-4 w-full flex items-center justify-center gap-2 py-2.5 bg-emerald-600 text-white text-sm font-semibold rounded-lg hover:bg-emerald-700 transition-colors"
      >
        <CheckCircle2 className="w-4 h-4" /> Complete Consultation
      </button>
    </div>
  );
}

/* ─── Completed Card ─────────────────────────────────── */
function CompletedCard({ entry, onRequeue }: { entry: QueueEntry; onRequeue: (id: string) => void }) {
  return (
    <div className="bg-card border border-border rounded-xl p-3.5 hover:shadow-sm transition-shadow">
      <div className="flex items-start justify-between mb-1.5">
        <span className="text-xl font-black text-emerald-600 leading-none">{entry.token}</span>
        <div className="flex gap-1">
          <button className="p-1 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-md transition-colors" title="View Invoice">
            <FileText className="w-3.5 h-3.5" />
          </button>
          <button className="p-1 text-muted-foreground hover:text-emerald-600 hover:bg-emerald-50 rounded-md transition-colors" title="Record Payment">
            <IndianRupee className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
      <p className="text-xs font-medium text-foreground truncate">{entry.name}</p>
      <p className="text-[10px] text-muted-foreground mt-0.5">{entry.arrivalTime}</p>
      <span className={`mt-1.5 inline-block text-[10px] px-1.5 py-0.5 rounded-full font-medium ${feeStatusStyle[entry.feeStatus]}`}>{entry.feeStatus}</span>
    </div>
  );
}

/* ─── No Show Card ───────────────────────────────────── */
function NoShowCard({ entry, onRequeue }: { entry: QueueEntry; onRequeue: (id: string) => void }) {
  return (
    <div className="bg-card border border-border rounded-xl p-3.5 opacity-75 hover:opacity-100 hover:shadow-sm transition-all">
      <div className="flex items-start justify-between mb-1.5">
        <span className="text-xl font-black text-slate-400 leading-none">{entry.token}</span>
        <button
          onClick={() => onRequeue(entry.id)}
          className="p-1 text-muted-foreground hover:text-amber-600 hover:bg-amber-50 rounded-md transition-colors"
          title="Requeue"
        >
          <RotateCcw className="w-3.5 h-3.5" />
        </button>
      </div>
      <p className="text-xs font-medium text-foreground truncate">{entry.name}</p>
      <p className="text-[10px] text-muted-foreground mt-0.5">{entry.arrivalTime}</p>
    </div>
  );
}

/* ─── Main Component ─────────────────────────────────── */
export function ReceptionistQueue() {
  const [queue, setQueue] = useState<QueueEntry[]>(initialQueue);
  const [completeTarget, setCompleteTarget] = useState<QueueEntry | null>(null);

  const waiting      = queue.filter(e => e.status === "waiting");
  const consultation = queue.filter(e => e.status === "consultation");
  const completed    = queue.filter(e => e.status === "completed");
  const noShow       = queue.filter(e => e.status === "no_show");
  const activeConsult = consultation[0] ?? null;

  const startConsultation = (id: string) => {
    if (consultation.length >= 1) {
      toast.error("A consultation is already in progress. Complete it first.");
      return;
    }
    const now = new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", hour12: true });
    setQueue(prev => prev.map(e => e.id === id ? { ...e, status: "consultation", startTime: now } : e));
    const entry = queue.find(e => e.id === id);
    toast.success(`Consultation started for ${entry?.name} (${entry?.token})`);
  };

  const markNoShow = (id: string) => {
    setQueue(prev => prev.map(e => e.id === id ? { ...e, status: "no_show" } : e));
    const entry = queue.find(e => e.id === id);
    toast.info(`${entry?.name} marked as No Show`);
  };

  const completeConsultation = (id: string) => {
    setQueue(prev => prev.map(e => e.id === id ? { ...e, status: "completed" } : e));
    const entry = queue.find(e => e.id === id);
    toast.success(`Consultation completed for ${entry?.name}. Visit record generated.`);
  };

  const requeue = (id: string) => {
    setQueue(prev => prev.map(e => e.id === id ? { ...e, status: "waiting", waitMins: 0 } : e));
    const entry = queue.find(e => e.id === id);
    toast.success(`${entry?.name} requeued to Waiting`);
  };

  const avgWait = waiting.length > 0
    ? Math.round(waiting.reduce((s, e) => s + e.waitMins, 0) / waiting.length)
    : 0;

  const summaryStats = [
    { label: "Total Waiting", value: waiting.length, icon: ListOrdered, color: "text-amber-600" },
    { label: "Avg Wait Time", value: `${avgWait}m`, icon: Timer, color: "text-blue-600" },
    { label: "Completed Today", value: completed.length, icon: CheckCircle2, color: "text-emerald-600" },
    { label: "Total Seen", value: queue.length, icon: Users, color: "text-primary" },
    { label: "No Shows", value: noShow.length, icon: UserX, color: "text-slate-500" },
    { label: "In Progress", value: consultation.length, icon: Stethoscope, color: "text-purple-600" },
  ];

  return (
    <div className="p-6 space-y-5 bg-background min-h-full">

      {/* Summary Stats — white cards */}
      <div className="grid grid-cols-3 md:grid-cols-6 gap-3">
        {summaryStats.map((s) => {
          const Icon = s.icon;
          return (
            <div key={s.label} className="bg-card border border-border rounded-xl p-3.5 flex flex-col gap-1.5 shadow-sm">
              <div className="flex items-center justify-between">
                <p className="text-[11px] text-muted-foreground">{s.label}</p>
                <Icon className={`w-3.5 h-3.5 ${s.color}`} />
              </div>
              <p className={`text-2xl font-black ${s.color}`}>{s.value}</p>
            </div>
          );
        })}
      </div>

      {/* Queue Board — 4 columns */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">

        {/* ── WAITING ── */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-4 py-3 border-b border-border flex items-center justify-between bg-amber-50">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-amber-500" />
              <span className="text-xs font-bold uppercase tracking-wider text-amber-700">Waiting</span>
            </div>
            <span className="text-sm font-black text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full border border-amber-200">{waiting.length}</span>
          </div>
          <div className="p-3 space-y-3 max-h-[520px] overflow-y-auto">
            {waiting.length === 0 ? (
              <div className="py-8 text-center text-xs text-muted-foreground">
                <Users className="w-6 h-6 mx-auto mb-2 opacity-30" />No patients waiting
              </div>
            ) : waiting.map(e => (
              <WaitingCard key={e.id} entry={e} onStart={startConsultation} onNoShow={markNoShow} />
            ))}
          </div>
        </div>

        {/* ── IN CONSULTATION (max 1) ── */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-4 py-3 border-b border-border flex items-center justify-between bg-blue-50">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
              <span className="text-xs font-bold uppercase tracking-wider text-blue-700">In Consultation</span>
            </div>
            <span className="text-sm font-black text-blue-700 bg-blue-100 px-2 py-0.5 rounded-full border border-blue-200">{consultation.length}/1</span>
          </div>
          <div className="p-3">
            {!activeConsult ? (
              <div className="py-12 text-center text-xs text-muted-foreground">
                <Stethoscope className="w-8 h-8 mx-auto mb-2 opacity-20" />
                <p className="font-medium">No active consultation</p>
                <p className="mt-1 text-[10px]">Start a patient from the waiting queue</p>
              </div>
            ) : (
              <ActiveConsultationCard
                entry={activeConsult}
                onComplete={() => setCompleteTarget(activeConsult)}
              />
            )}
          </div>
        </div>

        {/* ── COMPLETED ── */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-4 py-3 border-b border-border flex items-center justify-between bg-emerald-50">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-700">Completed</span>
            </div>
            <span className="text-sm font-black text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full border border-emerald-200">{completed.length}</span>
          </div>
          <div className="p-3 space-y-2.5 max-h-[520px] overflow-y-auto">
            {completed.length === 0 ? (
              <div className="py-8 text-center text-xs text-muted-foreground">
                <CheckCircle2 className="w-6 h-6 mx-auto mb-2 opacity-30" />No completions yet
              </div>
            ) : completed.map(e => (
              <CompletedCard key={e.id} entry={e} onRequeue={requeue} />
            ))}
          </div>
        </div>

        {/* ── NO SHOW ── */}
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-4 py-3 border-b border-border flex items-center justify-between bg-slate-50">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-slate-400" />
              <span className="text-xs font-bold uppercase tracking-wider text-slate-600">No Show</span>
            </div>
            <span className="text-sm font-black text-slate-600 bg-slate-100 px-2 py-0.5 rounded-full border border-slate-200">{noShow.length}</span>
          </div>
          <div className="p-3 space-y-2.5 max-h-[520px] overflow-y-auto">
            {noShow.length === 0 ? (
              <div className="py-8 text-center text-xs text-muted-foreground">
                <UserX className="w-6 h-6 mx-auto mb-2 opacity-30" />None
              </div>
            ) : noShow.map(e => (
              <NoShowCard key={e.id} entry={e} onRequeue={requeue} />
            ))}
          </div>
        </div>
      </div>

      {/* Complete Consultation Modal */}
      {completeTarget && (
        <CompleteModal
          entry={completeTarget}
          onClose={() => setCompleteTarget(null)}
          onComplete={completeConsultation}
        />
      )}
    </div>
  );
}

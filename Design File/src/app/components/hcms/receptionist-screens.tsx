import { useState } from "react";
import {
  Search,
  Plus,
  ChevronLeft,
  ChevronRight,
  X,
  CheckCircle2,
  Package,
  AlertTriangle,
  Download,
  Bell,
  UserPlus,
  Clock,
  CalendarPlus,
  FileText,
  PackagePlus,
  RefreshCw,
  Eye,
  Calendar,
  RotateCcw,
  XCircle,
  IndianRupee,
} from "lucide-react";
import { cn } from "../ui/utils";
import { toast } from "sonner";
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart as RPieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

/* ═══════════════════════════════════════════════════════
   ADD PATIENT MODAL
═══════════════════════════════════════════════════════ */
function AddPatientModal({ onClose, onSaveAndBook }: { onClose: () => void; onSaveAndBook?: () => void }) {
  const handleSave = () => {
    toast.success("Patient successfully registered.");
    onClose();
  };
  const handleSaveBook = () => {
    toast.success("Patient successfully registered.");
    onSaveAndBook?.();
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-lg my-4">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Add New Patient</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Register a new patient in the system</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-6 space-y-5 overflow-y-auto max-h-[70vh]">
          {/* Mandatory fields */}
          <div>
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold mb-3">Required Information</h3>
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="text-xs font-medium text-foreground">Full Name <span className="text-red-500">*</span></label>
                <input className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="e.g. Ramesh Kumar" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground">Date of Birth / Age <span className="text-red-500">*</span></label>
                <input type="date" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground">Gender <span className="text-red-500">*</span></label>
                <select className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary">
                  <option value="">Select gender</option>
                  <option>Male</option><option>Female</option><option>Other</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-foreground">Mobile Number <span className="text-red-500">*</span></label>
                <input type="tel" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="98765-43210" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground">Occupation <span className="text-red-500">*</span></label>
                <input className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="e.g. Teacher" />
              </div>
              <div className="col-span-2">
                <label className="text-xs font-medium text-foreground">Address <span className="text-red-500">*</span></label>
                <textarea rows={2} className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary resize-none" placeholder="Full address" />
              </div>
            </div>
          </div>

          {/* Optional fields */}
          <div>
            <h3 className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold mb-3">Optional Information</h3>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-medium text-foreground/70">Email</label>
                <input type="email" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="email@example.com" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground/70">Blood Group</label>
                <select className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none">
                  <option value="">Select</option>
                  {["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"].map(g => <option key={g}>{g}</option>)}
                </select>
              </div>
              <div className="col-span-2">
                <label className="text-xs font-medium text-foreground/70">Emergency Contact</label>
                <input className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="Name & mobile" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground/70">Known Allergies</label>
                <input className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="e.g. Penicillin" />
              </div>
              <div>
                <label className="text-xs font-medium text-foreground/70">Chronic Conditions</label>
                <input className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="e.g. Diabetes" />
              </div>
            </div>
          </div>
        </div>

        <div className="px-6 py-4 border-t border-border flex gap-2">
          <button onClick={onClose} className="px-4 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted transition-colors">Cancel</button>
          <button onClick={handleSave} className="flex-1 py-2 bg-primary text-primary-foreground text-sm font-medium rounded-lg hover:bg-primary/90 transition-colors">Save Patient</button>
          <button onClick={handleSaveBook} className="flex-1 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors">Save & Book Appointment</button>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   BOOK APPOINTMENT MODAL
═══════════════════════════════════════════════════════ */
function BookAppointmentModal({ onClose }: { onClose: () => void }) {
  const handleBook = () => {
    toast.success("Appointment booked successfully.");
    onClose();
  };
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-md">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Book Appointment</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Schedule a new appointment</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="text-xs font-medium text-foreground">Search Patient <span className="text-red-500">*</span></label>
            <div className="mt-1 relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
              <input className="w-full pl-8 pr-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" placeholder="Search by name, mobile, or ID…" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-foreground">Appointment Date <span className="text-red-500">*</span></label>
              <input type="date" defaultValue="2025-06-20" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
            <div>
              <label className="text-xs font-medium text-foreground">Appointment Time <span className="text-red-500">*</span></label>
              <input type="time" defaultValue="10:00" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-foreground">Appointment Type <span className="text-red-500">*</span></label>
            <select className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary">
              <option>New Visit</option>
              <option>Follow Up</option>
              <option>Walk-In</option>
            </select>
          </div>
          <div>
            <label className="text-xs font-medium text-foreground/70">Notes</label>
            <textarea rows={2} className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary resize-none" placeholder="Chief complaint or notes (optional)" />
          </div>
          <div className="flex gap-2 pt-1">
            <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted">Cancel</button>
            <button onClick={handleBook} className="flex-1 py-2.5 bg-primary text-primary-foreground text-sm font-semibold rounded-lg hover:bg-primary/90">Book Appointment</button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   CONFIRM APPOINTMENT DIALOG
═══════════════════════════════════════════════════════ */
function ConfirmDialog({ token, patient, onClose, onConfirm }: { token: string; patient: string; onClose: () => void; onConfirm: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="p-6 text-center space-y-4">
          <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <div>
            <h3 className="font-semibold text-base">Confirm this appointment?</h3>
            <p className="text-sm text-muted-foreground mt-1">{token} · {patient}</p>
          </div>
          <div className="flex gap-2 pt-2">
            <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted">Go Back</button>
            <button onClick={() => { onConfirm(); onClose(); }} className="flex-1 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700">Yes, Confirm</button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   RESCHEDULE MODAL
═══════════════════════════════════════════════════════ */
function RescheduleModal({ token, patient, onClose }: { token: string; patient: string; onClose: () => void }) {
  const handleSave = () => { toast.success("Appointment rescheduled successfully."); onClose(); };
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Reschedule Appointment</h2>
            <p className="text-xs text-muted-foreground mt-0.5">{token} · {patient}</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="text-xs font-medium text-foreground">New Date <span className="text-red-500">*</span></label>
            <input type="date" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <div>
            <label className="text-xs font-medium text-foreground">New Time <span className="text-red-500">*</span></label>
            <input type="time" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <div>
            <label className="text-xs font-medium text-foreground">Reason</label>
            <textarea rows={2} className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-lg bg-background focus:outline-none focus:ring-1 focus:ring-primary resize-none" placeholder="Reason for rescheduling" />
          </div>
          <div className="flex gap-2">
            <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted">Cancel</button>
            <button onClick={handleSave} className="flex-1 py-2 bg-primary text-primary-foreground text-sm font-medium rounded-lg hover:bg-primary/90">Save</button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   CANCEL APPOINTMENT DIALOG
═══════════════════════════════════════════════════════ */
function CancelDialog({ token, patient, onClose, onCancel }: { token: string; patient: string; onClose: () => void; onCancel: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-sm">
        <div className="p-6 text-center space-y-4">
          <div className="w-12 h-12 rounded-full bg-red-100 text-red-500 flex items-center justify-center mx-auto">
            <XCircle className="w-6 h-6" />
          </div>
          <div>
            <h3 className="font-semibold text-base">Cancel this appointment?</h3>
            <p className="text-sm text-muted-foreground mt-1">{token} · {patient}</p>
            <p className="text-xs text-muted-foreground mt-2">This action cannot be undone. The patient will be notified.</p>
          </div>
          <div className="flex gap-2 pt-2">
            <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted">Keep Appointment</button>
            <button onClick={() => { onCancel(); onClose(); }} className="flex-1 py-2 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700">Yes, Cancel</button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   PATIENTS
═══════════════════════════════════════════════════════ */
type PatientFilter = "All" | "New" | "Follow Up" | "Active" | "Archived";

const patientsData = [
  { id: "P-2041", name: "Anita Verma", mobile: "98765-43210", age: 34, gender: "F", lastVisit: "19 Jun", due: 0, status: "Active", type: "Follow Up" },
  { id: "P-2042", name: "Raj Patel", mobile: "87654-32109", age: 28, gender: "M", lastVisit: "19 Jun", due: 350, status: "Active", type: "New" },
  { id: "P-1998", name: "Sunita Mehta", mobile: "76543-21098", age: 41, gender: "F", lastVisit: "18 Jun", due: 2100, status: "Active", type: "Follow Up" },
  { id: "P-2010", name: "Vikram Singh", mobile: "65432-10987", age: 35, gender: "M", lastVisit: "18 Jun", due: 0, status: "Active", type: "New" },
  { id: "P-1985", name: "Kavya Sharma", mobile: "54321-09876", age: 29, gender: "F", lastVisit: "17 Jun", due: 0, status: "Active", type: "Follow Up" },
  { id: "P-2005", name: "Deepak Joshi", mobile: "43210-98765", age: 44, gender: "M", lastVisit: "17 Jun", due: 900, status: "Active", type: "New" },
  { id: "P-1920", name: "Priti Gupta", mobile: "32109-87654", age: 52, gender: "F", lastVisit: "16 Jun", due: 0, status: "Archived", type: "Follow Up" },
  { id: "P-2031", name: "Ravi Kumar", mobile: "21098-76543", age: 55, gender: "M", lastVisit: "16 Jun", due: 750, status: "Active", type: "New" },
];

const profileTabs = ["Overview", "Timeline", "Attachments", "Billing History", "Payment History"];

function PatientProfile({ patient, onBack }: { patient: typeof patientsData[0]; onBack: () => void }) {
  const [tab, setTab] = useState("Overview");
  const [showBookAppt, setShowBookAppt] = useState(false);

  return (
    <div className="p-6 bg-background min-h-full">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground mb-5 transition-colors">
        <ChevronLeft className="w-3.5 h-3.5" /> Back to Patients
      </button>
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
        <div className="xl:col-span-3 space-y-5">
          <div className="bg-card border border-border rounded-xl p-5 flex items-start gap-4 shadow-sm">
            <div className="w-14 h-14 rounded-full bg-primary/10 text-primary flex items-center justify-center text-xl font-black shrink-0">{patient.name.charAt(0)}</div>
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-3 flex-wrap">
                <div>
                  <h2 className="text-lg font-bold">{patient.name}</h2>
                  <p className="text-sm text-muted-foreground">{patient.id} · {patient.age}y · {patient.gender === "F" ? "Female" : "Male"} · {patient.mobile}</p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => setShowBookAppt(true)} className="flex items-center gap-1.5 px-3 py-1.5 text-xs bg-primary text-primary-foreground rounded-md hover:bg-primary/90">
                    <CalendarPlus className="w-3.5 h-3.5" /> Book Appointment
                  </button>
                  <button className="flex items-center gap-1.5 px-3 py-1.5 text-xs border border-border rounded-md hover:bg-muted">
                    <FileText className="w-3.5 h-3.5" /> Generate Invoice
                  </button>
                </div>
              </div>
              <div className="mt-3 flex gap-2 flex-wrap">
                <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded-full">{patient.type}</span>
                <span className={`text-xs px-2 py-1 rounded-full ${patient.status === "Active" ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-500"}`}>{patient.status}</span>
                {patient.due > 0 && <span className="text-xs px-2 py-1 bg-red-100 text-red-700 rounded-full">Due: ₹{patient.due}</span>}
              </div>
            </div>
          </div>

          <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
            <div className="flex border-b border-border overflow-x-auto">
              {profileTabs.map(t => (
                <button key={t} onClick={() => setTab(t)} className={cn("px-4 py-3 text-xs font-medium whitespace-nowrap transition-colors border-b-2", tab === t ? "border-primary text-primary" : "border-transparent text-muted-foreground hover:text-foreground")}>{t}</button>
              ))}
            </div>
            <div className="p-5">
              {tab === "Overview" && (
                <div className="grid grid-cols-2 gap-3 text-xs">
                  {[["Blood Group", "O+"], ["Allergies", "None known"], ["Chief Complaint", "Chronic fatigue, headaches"], ["Doctor", "Dr. Verma"], ["Registered On", "12 Jan 2024"], ["Total Visits", "8"]].map(([l, v]) => (
                    <div key={l} className="bg-muted/30 rounded-lg p-3"><p className="text-muted-foreground mb-1">{l}</p><p className="font-medium">{v}</p></div>
                  ))}
                </div>
              )}
              {tab === "Timeline" && (
                <div className="space-y-3">
                  {[["19 Jun 2025", "Follow-up · Dr. Verma"], ["05 Jun 2025", "Consultation · Dr. Verma"], ["22 May 2025", "New Visit · Dr. Verma"]].map(([d, e], i) => (
                    <div key={i} className="flex items-start gap-3 text-xs">
                      <div className="w-2 h-2 rounded-full bg-primary mt-1 shrink-0" />
                      <div><p className="font-medium">{d}</p><p className="text-muted-foreground">{e}</p></div>
                    </div>
                  ))}
                </div>
              )}
              {(tab === "Attachments" || tab === "Billing History" || tab === "Payment History") && (
                <div className="py-10 text-center text-muted-foreground text-xs">
                  <FileText className="w-8 h-8 mx-auto mb-2 opacity-30" />
                  <p>No {tab.toLowerCase()} records found</p>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-card border border-border rounded-xl p-4 shadow-sm">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">Upcoming Appointment</h3>
            <div className="bg-primary/5 border border-primary/20 rounded-lg p-3 text-xs">
              <p className="font-semibold text-sm">26 Jun 2025, 10:00 AM</p>
              <p className="text-muted-foreground mt-0.5">Follow Up · Dr. Verma</p>
              <button onClick={() => setShowBookAppt(true)} className="mt-2 w-full py-1.5 text-xs border border-primary/30 text-primary rounded-md hover:bg-primary/5 transition-colors">Reschedule</button>
            </div>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 shadow-sm">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">Pending Dues</h3>
            {patient.due > 0 ? (
              <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-xs">
                <p className="text-red-700 font-semibold text-lg">₹{patient.due}</p>
                <p className="text-red-600 mt-0.5">INV-2239 · Overdue</p>
                <button className="mt-2 w-full py-1.5 bg-emerald-600 text-white rounded-md text-xs hover:bg-emerald-700">Collect Now</button>
              </div>
            ) : (
              <div className="flex items-center gap-2 text-emerald-600 text-xs">
                <CheckCircle2 className="w-4 h-4" /> All paid up
              </div>
            )}
          </div>
          <div className="bg-card border border-border rounded-xl p-4 shadow-sm">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">Recent Activity</h3>
            <div className="space-y-2 text-xs text-muted-foreground">
              <div className="flex gap-2"><span className="text-primary">·</span>Visited 19 Jun</div>
              <div className="flex gap-2"><span className="text-primary">·</span>Invoice INV-2241 generated</div>
              <div className="flex gap-2"><span className="text-primary">·</span>Payment ₹1,200 received</div>
            </div>
          </div>
        </div>
      </div>

      {showBookAppt && <BookAppointmentModal onClose={() => setShowBookAppt(false)} />}
    </div>
  );
}

export function ReceptionistPatientsScreen() {
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<PatientFilter>("All");
  const [viewing, setViewing] = useState<typeof patientsData[0] | null>(null);
  const [showAddPatient, setShowAddPatient] = useState(false);
  const [showBookAppt, setShowBookAppt] = useState(false);

  if (viewing) return <PatientProfile patient={viewing} onBack={() => setViewing(null)} />;

  const filtered = patientsData.filter(p => {
    const matchSearch = p.name.toLowerCase().includes(search.toLowerCase()) || p.mobile.includes(search) || p.id.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === "All" || p.type === filter || p.status === filter;
    return matchSearch && matchFilter;
  });

  return (
    <div className="p-6 space-y-5 bg-background min-h-full">
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="px-5 py-4 border-b border-border flex items-center gap-4 flex-wrap">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search by name, ID, mobile…" className="w-full pl-8 pr-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
          </div>
          <div className="flex gap-1 flex-wrap">
            {(["All", "New", "Follow Up", "Active", "Archived"] as PatientFilter[]).map(f => (
              <button key={f} onClick={() => setFilter(f)} className={cn("px-3 py-1.5 rounded-md text-xs font-medium transition-colors", filter === f ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:bg-muted/80")}>{f}</button>
            ))}
          </div>
          <button
            onClick={() => setShowAddPatient(true)}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground text-xs font-medium rounded-md hover:bg-primary/90 ml-auto"
          >
            <UserPlus className="w-3.5 h-3.5" /> Add New Patient
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {["Patient ID", "Name", "Mobile", "Age", "Last Visit", "Due Balance", "Status", "Actions"].map(h => (
                  <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.map(p => (
                <tr key={p.id} className="hover:bg-muted/30 transition-colors group">
                  <td className="px-4 py-3 font-mono text-muted-foreground">{p.id}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2.5">
                      <div className="w-7 h-7 rounded-full bg-primary/10 text-primary flex items-center justify-center text-[10px] font-bold shrink-0">{p.name.charAt(0)}</div>
                      <span className="font-medium">{p.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{p.mobile}</td>
                  <td className="px-4 py-3">{p.age}y</td>
                  <td className="px-4 py-3 text-muted-foreground">{p.lastVisit}</td>
                  <td className="px-4 py-3">
                    <span className={p.due > 0 ? "text-red-600 font-semibold" : "text-emerald-600"}>{p.due > 0 ? `₹${p.due}` : "Nil"}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-1.5 py-0.5 rounded-full text-[10px] font-medium ${p.status === "Active" ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-500"}`}>{p.status}</span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1.5">
                      <button onClick={() => setViewing(p)} className="px-2 py-1 bg-muted text-foreground text-[10px] rounded hover:bg-muted/80 flex items-center gap-1">
                        <Eye className="w-3 h-3" /> View
                      </button>
                      <button className="px-2 py-1 bg-blue-100 text-blue-700 text-[10px] rounded hover:bg-blue-200" onClick={() => setShowBookAppt(true)}>Appt</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="px-5 py-3 border-t border-border text-xs text-muted-foreground">{filtered.length} patients</div>
      </div>

      {showAddPatient && <AddPatientModal onClose={() => setShowAddPatient(false)} onSaveAndBook={() => setShowBookAppt(true)} />}
      {showBookAppt && <BookAppointmentModal onClose={() => setShowBookAppt(false)} />}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   APPOINTMENTS
═══════════════════════════════════════════════════════ */
const initialAppointments = [
  { id: "a1", token: "T-21", patient: "Anita Verma", time: "10:45 AM", status: "Waiting", doctor: "Dr. Verma", type: "Follow Up" },
  { id: "a2", token: "T-22", patient: "Raj Patel", time: "11:00 AM", status: "Confirmed", doctor: "Dr. Verma", type: "New" },
  { id: "a3", token: "T-23", patient: "Priti Gupta", time: "11:15 AM", status: "Confirmed", doctor: "Dr. Verma", type: "Follow Up" },
  { id: "a4", token: "T-24", patient: "Ashok Kumar", time: "11:30 AM", status: "Pending", doctor: "Dr. Verma", type: "New" },
  { id: "a5", token: "T-25", patient: "Meera Singh", time: "12:00 PM", status: "Cancelled", doctor: "Dr. Verma", type: "Follow Up" },
];

const apptStatusStyle: Record<string, string> = {
  Waiting: "bg-amber-100 text-amber-700",
  Confirmed: "bg-emerald-100 text-emerald-700",
  Pending: "bg-blue-100 text-blue-700",
  Cancelled: "bg-red-100 text-red-700",
};

const walkinSteps = ["Search Patient", "Create/Confirm Patient", "Create Appointment", "Mark Arrived", "Generate Token"];

function WalkInModal({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  const [query, setQuery] = useState("");
  const [foundPatient, setFoundPatient] = useState(false);
  const [token] = useState("T-26");
  const isComplete = step >= walkinSteps.length;

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-lg">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <div>
            <h2 className="font-semibold">Walk-In Registration</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Step {Math.min(step + 1, walkinSteps.length)} of {walkinSteps.length} — {walkinSteps[Math.min(step, walkinSteps.length - 1)]}</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="px-5 pt-4">
          <div className="flex gap-1">
            {walkinSteps.map((_, i) => (
              <div key={i} className={cn("flex-1 h-1 rounded-full transition-colors", i < step ? "bg-primary" : i === step ? "bg-primary/40" : "bg-muted")} />
            ))}
          </div>
        </div>
        <div className="p-5">
          {isComplete ? (
            <div className="text-center py-4">
              <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-4"><CheckCircle2 className="w-8 h-8" /></div>
              <h3 className="text-lg font-bold">Walk-In Registered!</h3>
              <p className="text-sm text-muted-foreground mt-1">Token generated successfully</p>
              <div className="mt-5 bg-primary/5 border-2 border-primary rounded-xl p-6 inline-block">
                <p className="text-xs text-muted-foreground uppercase tracking-widest mb-1">Token Number</p>
                <p className="text-5xl font-black text-primary">{token}</p>
                <p className="text-xs text-muted-foreground mt-2">Raj Patel · New Visit</p>
              </div>
              <div className="mt-5 flex gap-2">
                <button className="flex-1 py-2 bg-primary text-primary-foreground text-sm rounded-lg hover:bg-primary/90">Print Token</button>
                <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg hover:bg-muted">Close</button>
              </div>
            </div>
          ) : step === 0 ? (
            <div className="space-y-4">
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input value={query} onChange={e => { setQuery(e.target.value); setFoundPatient(e.target.value.length > 2); }} placeholder="Search by name, mobile, or patient ID…" className="w-full pl-9 pr-3 py-2.5 border border-border rounded-lg bg-background text-sm focus:outline-none focus:ring-1 focus:ring-primary" />
              </div>
              {foundPatient && (
                <div className="border border-primary/20 rounded-lg overflow-hidden">
                  <div className="flex items-center gap-3 p-3 hover:bg-muted cursor-pointer" onClick={() => setStep(2)}>
                    <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center text-xs font-bold">R</div>
                    <div className="flex-1 text-xs"><p className="font-medium">Raj Patel</p><p className="text-muted-foreground">P-2042 · 28y · Male</p></div>
                    <ChevronRight className="w-4 h-4 text-muted-foreground" />
                  </div>
                </div>
              )}
              <button onClick={() => setStep(1)} className="w-full py-2 border border-dashed border-primary/40 text-primary text-sm rounded-lg hover:bg-primary/5 flex items-center justify-center gap-2">
                <UserPlus className="w-4 h-4" /> Register New Patient
              </button>
            </div>
          ) : step === 1 ? (
            <div className="space-y-3">
              <h3 className="text-sm font-medium">New Patient Details</h3>
              {[["Full Name", "text"], ["Mobile", "tel"], ["Age", "number"], ["Gender", "select"]].map(([l, t]) => (
                <div key={l}>
                  <label className="text-xs text-muted-foreground">{l}</label>
                  {t === "select" ? <select className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background"><option>Male</option><option>Female</option></select>
                    : <input type={t} className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background focus:outline-none focus:ring-1 focus:ring-primary" />}
                </div>
              ))}
              <button onClick={() => setStep(2)} className="w-full py-2 bg-primary text-primary-foreground text-sm rounded-lg hover:bg-primary/90">Save & Continue</button>
            </div>
          ) : step === 2 ? (
            <div className="space-y-3">
              <div className="bg-primary/5 border border-primary/20 rounded-lg p-3 text-xs"><p className="font-semibold">Raj Patel · P-2042</p><p className="text-muted-foreground">28y Male · 87654-32109</p></div>
              <div><label className="text-xs text-muted-foreground">Visit Type</label>
                <select className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background"><option>New Visit</option><option>Follow Up</option></select></div>
              <div><label className="text-xs text-muted-foreground">Doctor</label>
                <select className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background"><option>Dr. Verma</option></select></div>
              <button onClick={() => setStep(3)} className="w-full py-2 bg-primary text-primary-foreground text-sm rounded-lg hover:bg-primary/90">Create Appointment</button>
            </div>
          ) : step === 3 ? (
            <div className="space-y-4">
              <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4 text-center">
                <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2" />
                <p className="text-sm font-semibold">Appointment Created</p>
                <p className="text-xs text-muted-foreground mt-0.5">Raj Patel · New Visit · Dr. Verma</p>
              </div>
              <button onClick={() => setStep(walkinSteps.length)} className="w-full py-2.5 bg-amber-500 text-white text-sm font-semibold rounded-lg hover:bg-amber-600">
                Mark Arrived & Generate Token
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function ReceptionistAppointmentsScreen() {
  const [view, setView] = useState<"table" | "calendar">("table");
  const [showWalkIn, setShowWalkIn] = useState(false);
  const [showBook, setShowBook] = useState(false);
  const [appointments, setAppointments] = useState(initialAppointments);

  const [confirmTarget, setConfirmTarget] = useState<typeof initialAppointments[0] | null>(null);
  const [rescheduleTarget, setRescheduleTarget] = useState<typeof initialAppointments[0] | null>(null);
  const [cancelTarget, setCancelTarget] = useState<typeof initialAppointments[0] | null>(null);

  const handleConfirm = (id: string) => {
    setAppointments(prev => prev.map(a => a.id === id ? { ...a, status: "Confirmed" } : a));
    toast.success("Patient appointment confirmed successfully.");
  };
  const handleCancel = (id: string) => {
    setAppointments(prev => prev.map(a => a.id === id ? { ...a, status: "Cancelled" } : a));
    toast.success("Appointment cancelled successfully.");
  };

  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <div className="p-6 space-y-5 bg-background min-h-full">
      <div className="flex items-center gap-3 flex-wrap">
        <div className="bg-muted/30 rounded-lg p-1 flex gap-1">
          {(["table", "calendar"] as const).map(v => (
            <button key={v} onClick={() => setView(v)} className={cn("px-3 py-1.5 rounded-md text-xs font-medium capitalize transition-colors", view === v ? "bg-card shadow-sm text-foreground" : "text-muted-foreground")}>{v === "table" ? "Table View" : "Calendar View"}</button>
          ))}
        </div>
        <div className="ml-auto flex gap-2">
          <button onClick={() => setShowWalkIn(true)} className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white text-xs font-medium rounded-md hover:bg-amber-600">
            <UserPlus className="w-3.5 h-3.5" /> Walk-In
          </button>
          <button onClick={() => setShowBook(true)} className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground text-xs font-medium rounded-md hover:bg-primary/90">
            <CalendarPlus className="w-3.5 h-3.5" /> Book Appointment
          </button>
        </div>
      </div>

      {view === "calendar" ? (
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center justify-between">
            <h2 className="text-sm font-semibold">Week of 16 Jun – 21 Jun, 2025</h2>
            <div className="flex gap-2">
              <button className="p-1.5 hover:bg-muted rounded-md"><ChevronLeft className="w-4 h-4" /></button>
              <button className="px-3 py-1.5 text-xs border border-border rounded-md hover:bg-muted">Today</button>
              <button className="p-1.5 hover:bg-muted rounded-md"><ChevronRight className="w-4 h-4" /></button>
            </div>
          </div>
          <div className="grid grid-cols-6 divide-x divide-border">
            {days.map((d, i) => (
              <div key={d} className={cn("p-3", i === 3 && "bg-primary/5")}>
                <div className={cn("text-xs font-semibold text-center mb-3", i === 3 ? "text-primary" : "text-muted-foreground")}>{d}<br />{16 + i} Jun</div>
                {i === 3 && appointments.slice(0, 4).map(a => (
                  <div key={a.token} className={`mb-1.5 p-1.5 rounded-md text-[10px] cursor-pointer hover:opacity-80 ${apptStatusStyle[a.status] ?? "bg-muted"}`}>
                    <p className="font-semibold">{a.time}</p>
                    <p className="truncate">{a.patient}</p>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-border flex items-center gap-3">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
              <input placeholder="Search appointments…" className="w-full pl-8 pr-3 py-2 text-xs rounded-md border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  {["Token", "Patient", "Time", "Status", "Doctor", "Type", "Actions"].map(h => (
                    <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {appointments.map(a => (
                  <tr key={a.id} className="hover:bg-muted/30 transition-colors group">
                    <td className="px-4 py-3 font-bold text-primary">{a.token}</td>
                    <td className="px-4 py-3 font-medium">{a.patient}</td>
                    <td className="px-4 py-3 text-muted-foreground flex items-center gap-1.5"><Clock className="w-3.5 h-3.5" />{a.time}</td>
                    <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${apptStatusStyle[a.status]}`}>{a.status}</span></td>
                    <td className="px-4 py-3 text-muted-foreground">{a.doctor}</td>
                    <td className="px-4 py-3"><span className={`px-1.5 py-0.5 rounded-full text-[10px] ${a.type === "New" ? "bg-blue-100 text-blue-700" : "bg-purple-100 text-purple-700"}`}>{a.type}</span></td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1.5">
                        {a.status !== "Confirmed" && a.status !== "Cancelled" && (
                          <button onClick={() => setConfirmTarget(a)} className="px-2 py-1 text-[10px] bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200">Confirm</button>
                        )}
                        {a.status !== "Cancelled" && (
                          <button onClick={() => setRescheduleTarget(a)} className="px-2 py-1 text-[10px] bg-blue-100 text-blue-700 rounded hover:bg-blue-200">Reschedule</button>
                        )}
                        {a.status !== "Cancelled" && (
                          <button onClick={() => setCancelTarget(a)} className="px-2 py-1 text-[10px] bg-red-100 text-red-600 rounded hover:bg-red-200">Cancel</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showWalkIn && <WalkInModal onClose={() => setShowWalkIn(false)} />}
      {showBook && <BookAppointmentModal onClose={() => setShowBook(false)} />}
      {confirmTarget && <ConfirmDialog token={confirmTarget.token} patient={confirmTarget.patient} onClose={() => setConfirmTarget(null)} onConfirm={() => handleConfirm(confirmTarget.id)} />}
      {rescheduleTarget && <RescheduleModal token={rescheduleTarget.token} patient={rescheduleTarget.patient} onClose={() => setRescheduleTarget(null)} />}
      {cancelTarget && <CancelDialog token={cancelTarget.token} patient={cancelTarget.patient} onClose={() => setCancelTarget(null)} onCancel={() => handleCancel(cancelTarget.id)} />}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   INVENTORY
═══════════════════════════════════════════════════════ */
const medicines = [
  { name: "Arnica Montana 200C", potency: "200C", form: "Pellets", qty: 50, unit: "g", batch: "B2401", expiry: "Dec 2026", alert: false },
  { name: "Belladonna 30C", potency: "30C", form: "Drops", qty: 8, unit: "ml", batch: "B2389", expiry: "Mar 2026", alert: true },
  { name: "Nux Vomica 1M", potency: "1M", form: "Pellets", qty: 3, unit: "g", batch: "B2392", expiry: "Jun 2025", alert: true },
  { name: "Sulphur 6C", potency: "6C", form: "Pellets", qty: 120, unit: "g", batch: "B2415", expiry: "Sep 2027", alert: false },
  { name: "Rhus Tox 30C", potency: "30C", form: "Liquid", qty: 5, unit: "ml", batch: "B2401", expiry: "Jul 2025", alert: true },
  { name: "Pulsatilla 200C", potency: "200C", form: "Pellets", qty: 45, unit: "g", batch: "B2420", expiry: "Jan 2027", alert: false },
];

function StockInwardModal({ onClose }: { onClose: () => void }) {
  const handleSave = () => { toast.success("Stock inward recorded successfully."); onClose(); };
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div className="bg-card rounded-xl shadow-2xl border border-border w-full max-w-md">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="font-semibold">Stock Inward</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-muted rounded-md"><X className="w-4 h-4" /></button>
        </div>
        <div className="p-5 space-y-3">
          {[["Medicine", "select"], ["Supplier", "text"], ["Quantity", "number"], ["Batch No.", "text"], ["Expiry Date", "date"], ["Purchase Rate (₹)", "number"]].map(([l, t]) => (
            <div key={l}>
              <label className="text-xs text-muted-foreground">{l}</label>
              {t === "select" ? (
                <select className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background focus:outline-none">
                  {medicines.map(m => <option key={m.name}>{m.name}</option>)}
                </select>
              ) : (
                <input type={t} className="mt-1 w-full px-3 py-2 text-xs border border-border rounded-md bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
              )}
            </div>
          ))}
          <div className="flex gap-2 pt-1">
            <button onClick={onClose} className="flex-1 py-2 border border-border text-sm rounded-lg text-muted-foreground hover:bg-muted">Cancel</button>
            <button onClick={handleSave} className="flex-1 py-2 bg-primary text-primary-foreground text-sm rounded-lg hover:bg-primary/90">Save Stock Inward</button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function ReceptionistInventoryScreen() {
  const [showInward, setShowInward] = useState(false);
  const [alertTab, setAlertTab] = useState<"low" | "expiry" | "all">("all");
  const inventoryMetrics = [
    { label: "Total Medicines", value: 84, iconColor: "text-primary", iconBg: "bg-primary/10" },
    { label: "Low Stock", value: 7, iconColor: "text-orange-600", iconBg: "bg-orange-50" },
    { label: "Near Expiry", value: 3, iconColor: "text-amber-600", iconBg: "bg-amber-50" },
    { label: "Expired", value: 2, iconColor: "text-red-500", iconBg: "bg-red-50" },
  ];
  return (
    <div className="p-6 space-y-5 bg-background min-h-full">
      <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-2.5 flex items-center gap-3 text-xs text-blue-800">
        <AlertTriangle className="w-4 h-4 shrink-0 text-blue-400" />
        Adding new medicines, editing pricing, or deleting records requires Admin access.
      </div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {inventoryMetrics.map(m => (
          <div key={m.label} className={`bg-card border border-border rounded-xl p-4 shadow-sm`}>
            <p className="text-xs text-muted-foreground">{m.label}</p>
            <p className={`text-2xl font-black ${m.iconColor} mt-1`}>{m.value}</p>
          </div>
        ))}
      </div>
      <div className="flex gap-2 flex-wrap items-center">
        <div className="bg-muted/30 rounded-lg p-1 flex gap-1">
          {(["all", "low", "expiry"] as const).map(t => (
            <button key={t} onClick={() => setAlertTab(t)} className={cn("px-3 py-1.5 rounded-md text-xs font-medium capitalize transition-colors", alertTab === t ? "bg-card shadow-sm text-foreground" : "text-muted-foreground")}>
              {t === "all" ? "All Stock" : t === "low" ? "Low Stock" : "Near Expiry"}
            </button>
          ))}
        </div>
        <div className="ml-auto flex gap-2">
          <button onClick={() => setShowInward(true)} className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground text-xs font-medium rounded-md hover:bg-primary/90">
            <PackagePlus className="w-3.5 h-3.5" /> Stock Inward
          </button>
          <button className="flex items-center gap-2 px-4 py-2 border border-border text-xs font-medium rounded-md hover:bg-muted">Stock Outward</button>
        </div>
      </div>
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {["Medicine", "Potency", "Form", "Qty", "Unit", "Batch", "Expiry", "Status"].map(h => (
                  <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {medicines.filter(m => alertTab === "all" || (alertTab === "low" && m.alert) || (alertTab === "expiry" && (m.expiry.includes("2025") || m.expiry.includes("Mar 2026")))).map(m => (
                <tr key={m.name} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{m.name}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono">{m.potency}</td>
                  <td className="px-4 py-3 text-muted-foreground">{m.form}</td>
                  <td className={cn("px-4 py-3 font-bold", m.qty <= 10 ? "text-red-600" : m.qty <= 20 ? "text-amber-600" : "text-foreground")}>{m.qty}</td>
                  <td className="px-4 py-3 text-muted-foreground">{m.unit}</td>
                  <td className="px-4 py-3 font-mono text-muted-foreground">{m.batch}</td>
                  <td className={cn("px-4 py-3", m.expiry.includes("2025") ? "text-red-600 font-semibold" : m.expiry.includes("Mar 2026") ? "text-amber-600 font-medium" : "text-muted-foreground")}>{m.expiry}</td>
                  <td className="px-4 py-3">
                    {m.qty <= 10 ? <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-red-100 text-red-700 font-medium">Low Stock</span>
                      : m.expiry.includes("2025") ? <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-amber-100 text-amber-700 font-medium">Near Expiry</span>
                        : <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-emerald-100 text-emerald-700 font-medium">OK</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      {showInward && <StockInwardModal onClose={() => setShowInward(false)} />}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   REPORTS
═══════════════════════════════════════════════════════ */
const revenueData = [
  { day: "Mon", revenue: 14200 }, { day: "Tue", revenue: 16800 }, { day: "Wed", revenue: 12500 },
  { day: "Thu", revenue: 18450 }, { day: "Fri", revenue: 20100 }, { day: "Sat", revenue: 9800 },
];
const modeData = [
  { name: "Cash", value: 8200, color: "#10b981" },
  { name: "UPI", value: 6400, color: "#8b5cf6" },
  { name: "Card", value: 3850, color: "#3b82f6" },
];
const patientCountData = [
  { day: "Mon", count: 28 }, { day: "Tue", count: 34 }, { day: "Wed", count: 22 },
  { day: "Thu", count: 38 }, { day: "Fri", count: 41 }, { day: "Sat", count: 18 },
];

export function ReceptionistReportsScreen() {
  const reportMetrics = [
    { label: "Today's Revenue", value: "₹18,450", color: "text-emerald-600" },
    { label: "Collections", value: "₹13,250", color: "text-primary" },
    { label: "Outstanding Dues", value: "₹5,200", color: "text-red-600" },
    { label: "Refund Requests", value: "₹1,500", color: "text-amber-600" },
  ];
  return (
    <div className="p-6 space-y-5 bg-background min-h-full">
      <div className="flex items-center justify-between">
        <div><h2 className="text-base font-semibold">Day-End Summary</h2><p className="text-xs text-muted-foreground mt-0.5">Thursday, 19 June 2025</p></div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 px-4 py-2 border border-border text-xs rounded-md hover:bg-muted"><Download className="w-3.5 h-3.5" /> Export PDF</button>
          <button className="flex items-center gap-2 px-4 py-2 border border-border text-xs rounded-md hover:bg-muted"><Download className="w-3.5 h-3.5" /> Export Excel</button>
        </div>
      </div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {reportMetrics.map(m => (
          <div key={m.label} className="bg-card border border-border rounded-xl p-4 shadow-sm">
            <p className="text-xs text-muted-foreground">{m.label}</p>
            <p className={`text-xl font-black ${m.color} mt-1`}>{m.value}</p>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        <div className="xl:col-span-2 bg-card border border-border rounded-xl p-5 shadow-sm">
          <h3 className="text-sm font-semibold mb-4">Weekly Revenue Trend</h3>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={revenueData}>
              <defs>
                <linearGradient id="revenueGrad2" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#0d9488" stopOpacity={0.25} />
                  <stop offset="100%" stopColor="#0d9488" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis dataKey="day" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} />
              <Tooltip formatter={(v: number) => [`₹${v.toLocaleString()}`, "Revenue"]} />
              <Area type="monotone" dataKey="revenue" stroke="#0d9488" strokeWidth={2} fill="url(#revenueGrad2)" dot={false} isAnimationActive={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-card border border-border rounded-xl p-5 shadow-sm">
          <h3 className="text-sm font-semibold mb-4">Collection by Mode</h3>
          <ResponsiveContainer width="100%" height={160}>
            <RPieChart>
              <Pie data={modeData} cx="50%" cy="50%" outerRadius={60} dataKey="value" isAnimationActive={false}>
                {modeData.map((d) => <Cell key={d.name} fill={d.color} />)}
              </Pie>
              <Tooltip formatter={(v: number) => [`₹${v.toLocaleString()}`, ""]} />
            </RPieChart>
          </ResponsiveContainer>
          <div className="mt-2 space-y-1.5">
            {modeData.map(d => (
              <div key={d.name} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2"><span className="w-2 h-2 rounded-full" style={{ background: d.color }} />{d.name}</div>
                <span className="font-semibold">₹{d.value.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="bg-card border border-border rounded-xl p-5 shadow-sm">
        <h3 className="text-sm font-semibold mb-4">Daily Patient Count</h3>
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={patientCountData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="day" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
            <Tooltip />
            <Bar dataKey="count" fill="#0d9488" radius={[4, 4, 0, 0]} isAnimationActive={false} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   NOTIFICATIONS
═══════════════════════════════════════════════════════ */
const initialNotifications = [
  { id: 1, type: "alert", title: "Low Stock: Nux Vomica 1M", body: "Only 3 units remaining. Reorder recommended.", time: "10 min ago", read: false },
  { id: 2, type: "payment", title: "Payment Received", body: "₹1,200 received from Anita Verma (INV-2241)", time: "52 min ago", read: false },
  { id: 3, type: "queue", title: "Token T-22 Waiting", body: "Raj Patel has been waiting for 22 minutes", time: "1h ago", read: false },
  { id: 4, type: "alert", title: "Near Expiry: Rhus Tox 30C", body: "Expires July 2025. Please review.", time: "2h ago", read: true },
  { id: 5, type: "appointment", title: "3 Cancellations Today", body: "Tokens T-25, T-08, T-03 marked as cancelled", time: "3h ago", read: true },
  { id: 6, type: "payment", title: "Refund Request Submitted", body: "Refund of ₹1,500 for Priti Gupta is pending Admin approval", time: "5h ago", read: true },
];

const notifDot: Record<string, string> = {
  alert: "bg-orange-500", payment: "bg-emerald-500", queue: "bg-amber-500", appointment: "bg-blue-500",
};

export function ReceptionistNotificationsScreen() {
  const [notifs, setNotifs] = useState(initialNotifications);
  const markAllRead = () => { setNotifs(n => n.map(x => ({ ...x, read: true }))); toast.success("All notifications marked as read."); };
  return (
    <div className="p-6 space-y-5 bg-background min-h-full">
      <div className="flex items-center justify-between">
        <div><h2 className="text-base font-semibold">Notifications</h2><p className="text-xs text-muted-foreground mt-0.5">{notifs.filter(n => !n.read).length} unread</p></div>
        <button onClick={markAllRead} className="text-xs text-primary hover:underline flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> Mark all read</button>
      </div>
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm divide-y divide-border">
        {notifs.map(n => (
          <div key={n.id} className={cn("flex items-start gap-4 px-5 py-4 transition-colors hover:bg-muted/30 cursor-pointer", !n.read && "bg-blue-50/40")}>
            <div className={`w-2 h-2 rounded-full mt-1.5 shrink-0 ${n.read ? "bg-transparent border border-border" : notifDot[n.type]}`} />
            <div className="flex-1 min-w-0">
              <p className={cn("text-sm font-medium", !n.read ? "text-foreground" : "text-muted-foreground")}>{n.title}</p>
              <p className="text-xs text-muted-foreground mt-0.5">{n.body}</p>
            </div>
            <span className="text-[10px] text-muted-foreground whitespace-nowrap shrink-0">{n.time}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   SETTINGS
═══════════════════════════════════════════════════════ */
export function ReceptionistSettingsScreen() {
  const handleSave = () => toast.success("Profile updated successfully.");
  const handlePassword = () => toast.success("Password changed successfully.");
  return (
    <div className="p-6 space-y-5 bg-background min-h-full max-w-2xl">
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="px-5 py-4 border-b border-border"><h2 className="text-sm font-semibold">Profile Settings</h2></div>
        <div className="p-5 space-y-4">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-blue-500 text-white flex items-center justify-center text-xl font-black">P</div>
            <div><p className="font-semibold">Priya Sharma</p><p className="text-xs text-muted-foreground">Receptionist · Verma Homeopathy Clinic</p></div>
          </div>
          {[["Full Name", "Priya Sharma"], ["Email", "priya@vermahomeo.in"], ["Mobile", "+91 98765-11111"]].map(([l, v]) => (
            <div key={l}>
              <label className="text-xs text-muted-foreground">{l}</label>
              <input defaultValue={v} className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-md bg-background focus:outline-none focus:ring-1 focus:ring-primary" />
            </div>
          ))}
          <button onClick={handleSave} className="px-4 py-2 bg-primary text-primary-foreground text-sm rounded-md hover:bg-primary/90">Save Profile</button>
        </div>
      </div>
      <div className="bg-card border border-border rounded-xl overflow-hidden shadow-sm">
        <div className="px-5 py-4 border-b border-border"><h2 className="text-sm font-semibold">Change Password</h2></div>
        <div className="p-5 space-y-3">
          {["Current Password", "New Password", "Confirm New Password"].map(l => (
            <div key={l}><label className="text-xs text-muted-foreground">{l}</label><input type="password" className="mt-1 w-full px-3 py-2 text-sm border border-border rounded-md bg-background focus:outline-none focus:ring-1 focus:ring-primary" /></div>
          ))}
          <button onClick={handlePassword} className="px-4 py-2 bg-primary text-primary-foreground text-sm rounded-md hover:bg-primary/90">Update Password</button>
        </div>
      </div>
      <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 text-xs text-amber-800 flex items-start gap-2">
        <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5 text-amber-500" />
        Clinic settings, user management, and system configuration are managed by Admin only.
      </div>
    </div>
  );
}

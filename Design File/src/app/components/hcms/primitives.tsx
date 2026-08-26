import { ReactNode } from "react";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";
import { Card } from "../ui/card";
import { cn } from "../ui/utils";

export function KpiCard({
  label,
  value,
  delta,
  hint,
  icon,
  tone = "default",
}: {
  label: string;
  value: string;
  delta?: { value: string; up?: boolean };
  hint?: string;
  icon?: ReactNode;
  tone?: "default" | "primary" | "warning" | "danger";
}) {
  const toneRing: Record<string, string> = {
    default: "bg-muted text-foreground/70",
    primary: "bg-accent text-primary",
    warning: "bg-amber-50 text-amber-700",
    danger: "bg-red-50 text-red-600",
  };
  return (
    <Card className="p-4 gap-3">
      <div className="flex items-start justify-between">
        <div className="text-xs text-muted-foreground">{label}</div>
        {icon && (
          <div
            className={cn(
              "w-7 h-7 rounded-md flex items-center justify-center",
              toneRing[tone],
            )}
          >
            {icon}
          </div>
        )}
      </div>
      <div className="flex items-end gap-2">
        <div className="text-2xl tracking-tight">{value}</div>
        {delta && (
          <div
            className={cn(
              "flex items-center text-xs gap-0.5 mb-1",
              delta.up ? "text-emerald-600" : "text-red-600",
            )}
          >
            {delta.up ? (
              <ArrowUpRight className="w-3 h-3" />
            ) : (
              <ArrowDownRight className="w-3 h-3" />
            )}
            {delta.value}
          </div>
        )}
      </div>
      {hint && <div className="text-xs text-muted-foreground">{hint}</div>}
    </Card>
  );
}

const statusMap: Record<string, string> = {
  scheduled: "bg-slate-100 text-slate-700 ring-slate-200",
  arrived: "bg-blue-50 text-blue-700 ring-blue-100",
  "in consultation": "bg-amber-50 text-amber-800 ring-amber-100",
  completed: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  "follow-up": "bg-violet-50 text-violet-700 ring-violet-100",
  cancelled: "bg-red-50 text-red-700 ring-red-100",
  "no show": "bg-zinc-100 text-zinc-600 ring-zinc-200",
  paid: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  partial: "bg-amber-50 text-amber-800 ring-amber-100",
  due: "bg-red-50 text-red-700 ring-red-100",
  draft: "bg-slate-100 text-slate-700 ring-slate-200",
  issued: "bg-blue-50 text-blue-700 ring-blue-100",
  refunded: "bg-zinc-100 text-zinc-700 ring-zinc-200",
  active: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  low: "bg-amber-50 text-amber-800 ring-amber-100",
  expiring: "bg-red-50 text-red-700 ring-red-100",
};

export function StatusPill({ status }: { status: string }) {
  const cls = statusMap[status.toLowerCase()] || "bg-muted text-foreground/70 ring-border";
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs ring-1 ring-inset capitalize",
        cls,
      )}
    >
      <span className="w-1.5 h-1.5 rounded-full bg-current opacity-70" />
      {status}
    </span>
  );
}

export function SectionHeader({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex items-end justify-between gap-4 mb-3">
      <div>
        <h3 className="text-sm">{title}</h3>
        {description && (
          <p className="text-xs text-muted-foreground mt-0.5">{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}

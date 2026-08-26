import { Search, Bell, HelpCircle, ChevronDown } from "lucide-react";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { Badge } from "../ui/badge";

export function TopBar({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <header className="sticky top-0 z-10 bg-card/80 backdrop-blur border-b border-border">
      <div className="h-14 px-6 flex items-center gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="text-base">{title}</h1>
            {subtitle && (
              <span className="text-xs text-muted-foreground">· {subtitle}</span>
            )}
          </div>
        </div>
        <div className="relative w-80 max-w-[40vw]">
          <Search className="w-4 h-4 absolute left-2.5 top-2.5 text-muted-foreground" />
          <input
            placeholder="Search patients, invoices, MRN…"
            className="w-full h-9 pl-8 pr-3 rounded-md bg-muted text-sm border border-transparent focus:bg-card focus:border-border outline-none"
          />
          <kbd className="absolute right-2 top-1.5 text-[10px] px-1.5 py-0.5 rounded border border-border text-muted-foreground bg-card">
            ⌘K
          </kbd>
        </div>
        <button className="relative w-9 h-9 rounded-md hover:bg-muted flex items-center justify-center text-muted-foreground">
          <Bell className="w-4 h-4" />
          <span className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-red-500" />
        </button>
        <button className="w-9 h-9 rounded-md hover:bg-muted flex items-center justify-center text-muted-foreground">
          <HelpCircle className="w-4 h-4" />
        </button>
        <Badge variant="outline" className="hidden md:inline-flex gap-1.5 font-normal">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" /> Branch · Vijay Nagar
        </Badge>
        <button className="flex items-center gap-2 pl-2 pr-1 h-9 rounded-md hover:bg-muted">
          <Avatar className="w-7 h-7">
            <AvatarFallback className="bg-primary text-primary-foreground text-xs">
              VV
            </AvatarFallback>
          </Avatar>
          <div className="text-left leading-tight hidden sm:block">
            <div className="text-xs">Dr. V. K. Verma</div>
            <div className="text-[10px] text-muted-foreground">Administrator</div>
          </div>
          <ChevronDown className="w-3.5 h-3.5 text-muted-foreground" />
        </button>
      </div>
    </header>
  );
}

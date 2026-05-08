import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/utils/supabase/server";
import { signOut } from "@/app/login/actions";

type SessionRecord = {
  id: string;
  task_name: string | null;
  planned_duration: number | null;
  duration_minutes: number | null;
  energy_level: number | null;
  status: string | null;
  failure_reason: string | null;
  interruptions: number | null;
  emergency_breaks: number | null;
  lock_level: string | null;
  started_at: string | null;
  ended_at: string | null;
  completed_at: string | null;
};

function formatDate(value: string | null) {
  if (!value) return "Not finished";
  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value));
}

export default async function DashboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, task_name, planned_duration, duration_minutes, energy_level, status, failure_reason, interruptions, emergency_breaks, lock_level, started_at, ended_at, completed_at",
    )
    .order("started_at", { ascending: false })
    .limit(20)
    .returns<SessionRecord[]>();

  const completed = sessions?.filter((session) => session.status === "completed") ?? [];
  const failed = sessions?.filter((session) => session.status === "failed") ?? [];
  const totalMinutes = completed.reduce(
    (sum, session) =>
      sum + (session.duration_minutes ?? session.planned_duration ?? 0),
    0,
  );
  const successRate =
    sessions && sessions.length > 0
      ? Math.round((completed.length / sessions.length) * 100)
      : 0;

  return (
    <main className="min-h-screen bg-[#111015] text-[#e6e0e9]">
      <div className="mx-auto w-full max-w-7xl px-6 py-6">
        <nav className="flex flex-wrap items-center justify-between gap-4 border-b border-white/10 pb-5">
          <Link href="/" className="text-sm font-semibold tracking-[0.35em] text-[#d6d3cc]">
            BIO-LOCKED
          </Link>
          <div className="flex items-center gap-3">
            <span className="max-w-[220px] truncate text-sm text-[#a7a0ad]">
              {user.email}
            </span>
            <form action={signOut}>
              <button className="rounded-md border border-white/15 px-4 py-2 text-sm font-semibold text-white transition hover:bg-white/10">
                Sign out
              </button>
            </form>
          </div>
        </nav>

        <header className="py-10">
          <p className="text-sm font-semibold uppercase tracking-[0.28em] text-[#7ec8e3]">
            Synced dashboard
          </p>
          <h1 className="mt-3 text-4xl font-semibold text-white">
            Your focus command center
          </h1>
        </header>

        <section className="grid gap-4 md:grid-cols-4">
          {[
            ["Focus minutes", totalMinutes],
            ["Completed", completed.length],
            ["Failed", failed.length],
            ["Success rate", `${successRate}%`],
          ].map(([label, value]) => (
            <article key={label} className="rounded-lg border border-white/10 bg-white/[0.04] p-5">
              <div className="text-3xl font-semibold text-white">{value}</div>
              <div className="mt-2 text-sm text-[#a7a0ad]">{label}</div>
            </article>
          ))}
        </section>

        <section className="mt-8 rounded-lg border border-white/10 bg-white/[0.04]">
          <div className="border-b border-white/10 p-5">
            <h2 className="text-xl font-semibold text-white">Recent sessions</h2>
            <p className="mt-1 text-sm text-[#a7a0ad]">
              These rows come from the shared Supabase `sessions` table.
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead className="text-[#a7a0ad]">
                <tr className="border-b border-white/10">
                  <th className="px-5 py-4 font-medium">Task</th>
                  <th className="px-5 py-4 font-medium">Status</th>
                  <th className="px-5 py-4 font-medium">Duration</th>
                  <th className="px-5 py-4 font-medium">Energy</th>
                  <th className="px-5 py-4 font-medium">Lock</th>
                  <th className="px-5 py-4 font-medium">When</th>
                </tr>
              </thead>
              <tbody>
                {sessions && sessions.length > 0 ? (
                  sessions.map((session) => (
                    <tr key={session.id} className="border-b border-white/5">
                      <td className="px-5 py-4 text-white">
                        {session.task_name || "Untitled focus block"}
                        {session.failure_reason ? (
                          <div className="mt-1 text-xs text-[#ef8686]">
                            {session.failure_reason}
                          </div>
                        ) : null}
                      </td>
                      <td className="px-5 py-4">
                        <span className="rounded-full border border-white/10 px-3 py-1 text-xs uppercase tracking-wide text-[#d6d3cc]">
                          {session.status ?? "unknown"}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-[#d6d3cc]">
                        {session.duration_minutes ?? session.planned_duration ?? 0}m
                      </td>
                      <td className="px-5 py-4 text-[#d6d3cc]">
                        {session.energy_level ?? "-"}%
                      </td>
                      <td className="px-5 py-4 text-[#d6d3cc]">
                        {session.lock_level ?? "standard"}
                      </td>
                      <td className="px-5 py-4 text-[#a7a0ad]">
                        {formatDate(session.completed_at ?? session.ended_at ?? session.started_at)}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td className="px-5 py-10 text-center text-[#a7a0ad]" colSpan={6}>
                      No synced sessions yet. Sign into Android with this account and complete a focus session.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </main>
  );
}

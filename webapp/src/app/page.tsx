import Link from "next/link";
import { createClient } from "@/utils/supabase/server";

export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <main className="min-h-screen bg-[#111015] text-[#e6e0e9]">
      <section className="mx-auto flex min-h-screen w-full max-w-7xl flex-col px-6 py-6">
        <nav className="flex items-center justify-between border-b border-white/10 pb-5">
          <div className="text-sm font-semibold tracking-[0.35em] text-[#d6d3cc]">
            BIO-LOCKED
          </div>
          <div className="flex items-center gap-3">
            {user ? (
              <Link
                href="/dashboard"
                className="rounded-md bg-[#d6d3cc] px-4 py-2 text-sm font-semibold text-[#141218]"
              >
                Dashboard
              </Link>
            ) : (
              <Link
                href="/login"
                className="rounded-md bg-[#d6d3cc] px-4 py-2 text-sm font-semibold text-[#141218]"
              >
                Sign in
              </Link>
            )}
          </div>
        </nav>

        <div className="grid flex-1 gap-12 py-12 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.28em] text-[#7ec8e3]">
              Android lock engine plus web dashboard
            </p>
            <h1 className="mt-5 max-w-4xl text-5xl font-semibold leading-tight text-white md:text-7xl">
              BIO-LOCKED
            </h1>
            <p className="mt-6 max-w-2xl text-xl leading-9 text-[#b9b2bf]">
              A strict focus system that locks your phone during deep work and
              syncs your history, streaks, presets, and rewards to the web.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                href={user ? "/dashboard" : "/login"}
                className="rounded-md bg-[#d6d3cc] px-6 py-3 text-center font-semibold text-[#141218] transition hover:bg-white"
              >
                {user ? "Open dashboard" : "Start syncing"}
              </Link>
              <a
                href="#web"
                className="rounded-md border border-white/15 px-6 py-3 text-center font-semibold text-white transition hover:bg-white/10"
              >
                See what syncs
              </a>
            </div>
          </div>

          <div className="rounded-lg border border-white/10 bg-white/[0.04] p-5">
            <div className="rounded-md border border-[#7ec8e3]/20 bg-[#7ec8e3]/10 p-5">
              <p className="text-sm uppercase tracking-[0.25em] text-[#7ec8e3]">
                Today
              </p>
              <div className="mt-6 grid grid-cols-2 gap-4">
                {[
                  ["Focus", "90m"],
                  ["Streak", "7 days"],
                  ["Coins", "184"],
                  ["Interruptions", "0"],
                ].map(([label, value]) => (
                  <div key={label} className="rounded-md bg-black/25 p-4">
                    <div className="text-2xl font-semibold text-white">{value}</div>
                    <div className="mt-1 text-sm text-[#a7a0ad]">{label}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        <section id="web" className="grid gap-4 pb-12 md:grid-cols-3">
          {[
            ["Same account", "Supabase Auth powers Android and web sign-in."],
            ["Shared history", "Completed and failed sessions flow into one timeline."],
            ["Web visibility", "Review analytics without weakening the phone lock."],
          ].map(([title, body]) => (
            <article key={title} className="rounded-lg border border-white/10 p-5">
              <h2 className="text-lg font-semibold text-white">{title}</h2>
              <p className="mt-2 leading-7 text-[#a7a0ad]">{body}</p>
            </article>
          ))}
        </section>
      </section>
    </main>
  );
}

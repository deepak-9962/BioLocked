import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/utils/supabase/server";
import { signIn, signInWithGoogle, signUp } from "./actions";

type LoginPageProps = {
  searchParams: Promise<{ message?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    redirect("/dashboard");
  }

  const params = await searchParams;

  return (
    <main className="min-h-screen bg-[#111015] text-[#e6e0e9]">
      <div className="mx-auto flex min-h-screen w-full max-w-6xl items-center px-6 py-12">
        <section className="grid w-full gap-10 lg:grid-cols-[1fr_440px] lg:items-center">
          <div>
            <Link href="/" className="text-sm font-semibold tracking-[0.35em] text-[#d6d3cc]">
              BIO-LOCKED
            </Link>
            <h1 className="mt-8 max-w-2xl text-5xl font-semibold leading-tight text-white">
              Sign in to sync your focus life across Android and web.
            </h1>
            <p className="mt-5 max-w-xl text-lg leading-8 text-[#a7a0ad]">
              Your phone stays the strict lock engine. The web dashboard keeps
              your sessions, streaks, coins, presets, and schedules visible
              from the same Supabase account.
            </p>
          </div>

          <div className="rounded-lg border border-white/10 bg-white/[0.04] p-6 shadow-2xl shadow-black/30">
            <h2 className="text-2xl font-semibold text-white">Account access</h2>
            <p className="mt-2 text-sm text-[#a7a0ad]">
              Use the same email and password on Android and web.
            </p>

            {params.message ? (
              <div className="mt-5 rounded-md border border-[#d4af37]/30 bg-[#d4af37]/10 px-4 py-3 text-sm text-[#f3d98a]">
                {params.message}
              </div>
            ) : null}

            <form className="mt-6 grid gap-4">
              <button
                formAction={signInWithGoogle}
                className="rounded-md border border-white/15 bg-white px-5 py-3 font-semibold text-[#141218] transition hover:bg-[#d6d3cc]"
              >
                Continue with Google
              </button>

              <div className="flex items-center gap-3 text-xs uppercase tracking-[0.22em] text-[#7c7484]">
                <span className="h-px flex-1 bg-white/10" />
                Email
                <span className="h-px flex-1 bg-white/10" />
              </div>

              <label className="grid gap-2 text-sm text-[#d6d3cc]">
                Email
                <input
                  name="email"
                  type="email"
                  required
                  className="rounded-md border border-white/10 bg-black/30 px-4 py-3 text-white outline-none transition focus:border-[#7ec8e3]"
                  placeholder="you@example.com"
                />
              </label>
              <label className="grid gap-2 text-sm text-[#d6d3cc]">
                Password
                <input
                  name="password"
                  type="password"
                  required
                  minLength={6}
                  className="rounded-md border border-white/10 bg-black/30 px-4 py-3 text-white outline-none transition focus:border-[#7ec8e3]"
                  placeholder="At least 6 characters"
                />
              </label>

              <div className="mt-2 grid gap-3 sm:grid-cols-2">
                <button
                  formAction={signIn}
                  className="rounded-md bg-[#d6d3cc] px-5 py-3 font-semibold text-[#141218] transition hover:bg-white"
                >
                  Sign in
                </button>
                <button
                  formAction={signUp}
                  className="rounded-md border border-white/15 px-5 py-3 font-semibold text-white transition hover:bg-white/10"
                >
                  Create account
                </button>
              </div>
            </form>
          </div>
        </section>
      </div>
    </main>
  );
}

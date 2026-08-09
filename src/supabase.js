import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL;
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

export const isSupabaseConfigured = Boolean(
  url && publishableKey && !url.includes("YOUR_PROJECT_REF") && !publishableKey.includes("REPLACE_ME"),
);

export const supabase = isSupabaseConfigured
  ? createClient(url, publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    })
  : null;

export async function currentUser() {
  if (!supabase) return null;
  const { data } = await supabase.auth.getUser();
  return data.user ?? null;
}

export async function sendMagicLink(email) {
  if (!supabase) throw new Error("Supabase is not configured yet.");
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: window.location.origin },
  });
  if (error) throw error;
}

export async function saveAnalysis({ state, result, mode, profile }) {
  const user = await currentUser();
  if (!supabase || !user) {
    const saved = JSON.parse(localStorage.getItem("dwellingiq_saved") || "[]");
    saved.unshift({ id: crypto.randomUUID(), created_at: new Date().toISOString(), state, result, mode, profile });
    localStorage.setItem("dwellingiq_saved", JSON.stringify(saved.slice(0, 20)));
    return { local: true, count: saved.length };
  }

  const { error } = await supabase.from("property_analyses").insert({
    user_id: user.id,
    address_label: state.address,
    decision_mode: mode,
    location_profile: profile,
    property_inputs: state,
    model_output: result,
    model_version: "housing-moneyball-0.1",
  });
  if (error) throw error;
  const { count } = await supabase.from("property_analyses").select("id", { count: "exact", head: true });
  return { local: false, count: count || 1 };
}

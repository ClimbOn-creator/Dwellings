import "./styles.css";
import { analyze, locationProfiles, nearestProfile } from "./model.js";
import { currentUser, isSupabaseConfigured, saveAnalysis, sendMagicLink, supabase } from "./supabase.js";

const $ = (s, root = document) => root.querySelector(s);
const money = n => new Intl.NumberFormat("en-CA", { style: "currency", currency: "CAD", maximumFractionDigits: 0 }).format(n || 0);
const pct = (n, d = 1) => `${(n * 100).toFixed(d)}%`;
const num = (n, d = 1) => Number(n).toFixed(d);

let mode = "home";
let profile = locationProfiles[0];
let lastResult;
const state = { address: "Kitsilano, Vancouver, BC", price: 1200000, finishedArea: 1800, lotArea: 6500, buildable: 0, bedrooms: 3, bathrooms: 2, yearBuilt: 1988, repairs: 25000, rent: 5000, operatingCosts: 12500, redevelopment: 55, scarcity: 64, daysOnMarket: 28, downPayment: 20, amortization: 25, holdingPeriod: 5, rentalOffset: 0 };

document.querySelector("#app").innerHTML = `
  <header class="topbar">
    <a class="brand" href="#"><span class="brand-mark"><i></i><i></i><i></i></span><span>Dwelling<span>IQ</span></span></a>
    <nav><a href="#workspace">Analyze</a><a href="#method">How it works</a><button class="ghost" id="savedBtn">Saved <span>0</span></button><button class="avatar" id="accountBtn" aria-label="Account">${isSupabaseConfigured ? "Sign in" : "Demo"}</button></nav>
  </header>
  <main>
    <section class="hero">
      <div class="eyebrow"><span></span> Property decision intelligence</div>
      <h1>Know the property.<br><em>See the whole picture.</em></h1>
      <p>Location-aware analysis for buying a home or evaluating an investment—built from transparent fundamentals, not sales language.</p>
      <div class="hero-stats"><div><b>22</b><span>factors scored</span></div><div><b>2</b><span>decision lenses</span></div><div><b>100%</b><span>explainable</span></div></div>
    </section>

    <section class="workspace" id="workspace">
      <div class="panel input-panel">
        <div class="panel-head"><div><small>01 / SET YOUR GOAL</small><h2>What are you buying?</h2></div><span class="status-dot">Model ready</span></div>
        <div class="mode-switch" role="tablist"><button class="active" data-mode="home"><span>⌂</span><b>A home to live in</b><small>Affordability + long-term value</small></button><button data-mode="invest"><span>↗</span><b>An investment</b><small>Yield + risk-adjusted growth</small></button></div>
        <div class="step-label"><span>02</span><div><small>PROPERTY LOCATION</small><b>Let the location do the heavy lifting</b></div></div>
        <div class="address-box"><div class="pin">⌖</div><label>Address or neighbourhood<input id="address" value="${state.address}" autocomplete="street-address" /></label><button id="scanBtn"><span>✦</span> Scan location</button></div>
        <button class="locate" id="locateBtn">◎ Use my current location</button>
        <div class="scan-result" id="scanResult"><div class="scan-map"><span class="map-road r1"></span><span class="map-road r2"></span><span class="map-road r3"></span><i></i></div><div><small>LOCATION PROFILE</small><h3>${profile.city}, ${profile.region}</h3><p>Urban market profile loaded · ${profile.transit}/100 transit · ${profile.inventory} months inventory</p></div><span class="verified">✓ Scanned</span></div>
        <div class="step-label"><span>03</span><div><small>PROPERTY DETAILS</small><b>Add what you know — estimates are okay</b></div></div>
        <div class="form-grid">
          ${field("price", "Purchase price", state.price, "$", 10000)}
          ${field("downPayment", "Down payment", state.downPayment, "%", 1)}
          ${field("finishedArea", "Finished area", state.finishedArea, "sq ft", 50)}
          ${field("lotArea", "Lot size", state.lotArea, "sq ft", 100)}
          ${field("bedrooms", "Bedrooms", state.bedrooms, "", 1)}
          ${field("bathrooms", "Bathrooms", state.bathrooms, "", .5)}
          ${field("yearBuilt", "Year built", state.yearBuilt, "", 1)}
          ${field("repairs", "Immediate repairs", state.repairs, "$", 1000)}
          ${field("rent", "Monthly market rent", state.rent, "$", 100)}
          ${field("operatingCosts", "Annual operating costs", state.operatingCosts, "$", 500)}
          ${field("holdingPeriod", "Holding period", state.holdingPeriod, "years", 1)}
          ${field("buildable", "Buildable floor area", state.buildable, "sq ft", 100, "Optional")}
        </div>
        <details><summary>Advanced assumptions <span>Optional model controls</span></summary><div class="form-grid advanced">${field("redevelopment", "Redevelopment feasibility", state.redevelopment, "/100", 1)}${field("scarcity", "Comparable scarcity", state.scarcity, "/100", 1)}${field("daysOnMarket", "Expected days on market", state.daysOnMarket, "days", 1)}${field("amortization", "Amortization", state.amortization, "years", 1)}</div></details>
        <button class="analyze" id="analyzeBtn"><span>Run full analysis</span><i>→</i></button>
        <p class="privacy">⌁ Location is used for this analysis only. This prototype does not store your address.</p>
      </div>

      <aside class="panel results-panel" id="results">
        <div class="empty-state"><div class="orb"><span></span></div><h2>Your decision brief will appear here</h2><p>Scan a location, add property details, and run the model.</p><ul><li>Risk-adjusted appreciation outlook</li><li>Monthly affordability or cash flow</li><li>Top strengths, risks, and next actions</li></ul></div>
      </aside>
    </section>

    <section class="method" id="method"><div><small>BUILT FOR BETTER QUESTIONS</small><h2>AI helps with the research.<br>You stay in control of the decision.</h2></div><div class="method-grid"><article><b>01</b><h3>Scan the location</h3><p>Connect municipal, market, transit, hazard, and demographic sources to the parcel.</p></article><article><b>02</b><h3>Score fundamentals</h3><p>Normalize upside and risk factors using transparent, testable benchmarks.</p></article><article><b>03</b><h3>Explain the result</h3><p>Show the assumptions, strongest drivers, missing data, and diligence questions.</p></article></div></section>
  </main>
  <footer><span>DwellingIQ prototype · Based on Housing Moneyball model v0.1</span><span>Research tool, not financial advice</span></footer>
`;

function field(id, label, value, suffix, step, badge = "") { return `<label class="field"><span>${label}${badge ? `<i>${badge}</i>` : ""}</span><div><input id="${id}" type="number" value="${value}" step="${step}" /><em>${suffix}</em></div></label>`; }
function hydrateProfile(p) { profile = p; Object.assign(state, p); }
function collect() { Object.keys(state).forEach(k => { const el = document.getElementById(k); if (el && el.type === "number") state[k] = Number(el.value); }); state.address = $("#address").value; Object.assign(state, profile); }
function profileCard(p, label) { $("#scanResult").innerHTML = `<div class="scan-map"><span class="map-road r1"></span><span class="map-road r2"></span><span class="map-road r3"></span><i></i></div><div><small>LOCATION PROFILE · ${label}</small><h3>${p.city}, ${p.region}</h3><p>${p.transit}/100 transit · ${p.inventory} months inventory · ${pct(p.appreciation)} benchmark growth</p></div><span class="verified">✓ Scanned</span>`; }

async function scanAddress() {
  const btn = $("#scanBtn"); btn.classList.add("loading"); btn.innerHTML = "<span>✦</span> Scanning…";
  let picked = locationProfiles.find(p => state.address.toLowerCase().includes(p.city.toLowerCase()));
  try {
    if (!picked) { const q = encodeURIComponent($("#address").value); const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${q}`, { headers: { "Accept-Language": "en" } }); const [geo] = await res.json(); if (geo) picked = nearestProfile(Number(geo.lat), Number(geo.lon)); }
  } catch { /* fall through to the baseline */ }
  hydrateProfile(picked || locationProfiles[0]); profileCard(profile, picked ? "nearest demo market" : "baseline estimate");
  btn.classList.remove("loading"); btn.innerHTML = "<span>✓</span> Location scanned"; setTimeout(() => btn.innerHTML = "<span>✦</span> Scan again", 1800);
}

$("#scanBtn").addEventListener("click", scanAddress);
$("#locateBtn").addEventListener("click", () => navigator.geolocation ? navigator.geolocation.getCurrentPosition(async pos => { const p = nearestProfile(pos.coords.latitude, pos.coords.longitude); hydrateProfile(p); $("#address").value = `Near ${p.city}, ${p.region}`; profileCard(p, "nearest demo market"); }, () => $("#locateBtn").textContent = "Location permission was not granted") : null);
document.querySelectorAll("[data-mode]").forEach(btn => btn.addEventListener("click", () => { mode = btn.dataset.mode; document.querySelectorAll("[data-mode]").forEach(x => x.classList.toggle("active", x === btn)); if (lastResult) renderResults(lastResult); }));
$("#analyzeBtn").addEventListener("click", () => { collect(); lastResult = analyze(state, mode); renderResults(lastResult); $("#results").scrollIntoView({ behavior: "smooth", block: "start" }); });
$("#accountBtn").addEventListener("click", async () => {
  if (!isSupabaseConfigured) return alert("Demo mode is active. Add the Supabase variables described in README.md to enable accounts.");
  const user = await currentUser();
  if (user) {
    if (confirm(`Signed in as ${user.email}. Sign out?`)) { await supabase.auth.signOut(); location.reload(); }
    return;
  }
  const email = prompt("Enter your email address for a secure sign-in link:");
  if (!email) return;
  try { await sendMagicLink(email); alert("Check your email for the DwellingIQ sign-in link."); }
  catch (error) { alert(error.message); }
});
currentUser().then(user => { if (user) $("#accountBtn").textContent = user.email.slice(0, 2).toUpperCase(); });

function renderResults(r) {
  const verdict = r.net >= 55 ? "Strong candidate" : r.net >= 42 ? "Worth a closer look" : "Proceed with caution";
  const tone = r.net >= 55 ? "good" : r.net >= 42 ? "medium" : "risk";
  const carryTitle = mode === "invest" ? "Est. monthly cash flow" : "Est. monthly housing cost";
  const carry = mode === "invest" ? state.rent - r.monthlyMortgage - state.operatingCosts / 12 : r.monthlyCarry;
  const top = r.ranked.slice(0, 5);
  $("#results").innerHTML = `
    <div class="result-head"><div><small>DECISION BRIEF</small><h2>${state.address}</h2><p>${profile.city}, ${profile.region} · ${mode === "home" ? "Homebuyer" : "Investor"} lens</p></div><button class="save" id="saveResult">☆ Save</button></div>
    <div class="verdict ${tone}"><span>${verdict}</span><div class="score-ring" style="--score:${r.net * 3.6}deg"><b>${Math.round(r.net)}</b><small>/100</small></div><p>${Math.round(r.probability * 100)}% modelled chance of outperforming the local benchmark over ${state.holdingPeriod} years.</p></div>
    <div class="kpi-grid"><div><span>Expected growth</span><b>${pct(r.annualAppreciation)}</b><small>annualized estimate</small></div><div><span>${carryTitle}</span><b class="${carry < 0 ? "negative" : ""}">${mode === "invest" && carry >= 0 ? "+" : ""}${money(carry)}</b><small>${mode === "invest" ? "after mortgage + expenses" : `${state.downPayment}% down, ${state.amortization} yr`}</small></div><div><span>Projected value</span><b>${money(r.projected)}</b><small>in ${state.holdingPeriod} years</small></div><div><span>${mode === "invest" ? "Net cap rate" : "Mortgage payment"}</span><b>${mode === "invest" ? pct(r.capRate) : money(r.monthlyMortgage)}</b><small>${mode === "invest" ? "before financing" : "per month"}</small></div></div>
    <section class="breakdown"><div class="section-title"><h3>What’s driving the score</h3><span>${r.confidence}% input confidence</span></div>${top.map(x => `<div class="driver"><span class="driver-icon ${x.type}">${x.type === "upside" ? "↗" : "!"}</span><div><b>${x.name}</b><small>${x.type === "upside" ? "Supports the opportunity score" : "Reduces the risk-adjusted score"}</small></div><em>${x.type === "upside" ? "+" : "−"}${Math.abs(x.impact).toFixed(1)}</em></div>`).join("")}</section>
    <section class="score-bars"><h3>Model composition</h3><label><span>Opportunity</span><b>${Math.round(r.opportunity)}/100</b></label><i><u style="width:${r.opportunity}%"></u></i><label><span>Risk</span><b>${Math.round(r.risk)}/100</b></label><i class="riskbar"><u style="width:${r.risk}%"></u></i></section>
    <section class="ai-brief"><div class="spark">✦</div><div><small>AI DILIGENCE COACH</small><h3>Your next three questions</h3><ol><li>${state.buildable <= 0 ? "Confirm buildable floor area and permitted density with the municipality." : "Verify that the assumed buildable area is achievable after setbacks and servicing."}</li><li>Request an insurance quote that explicitly covers the mapped local hazards.</li><li>${mode === "invest" ? "Validate rent and operating costs using three recent comparables." : "Stress-test your monthly budget at a mortgage rate two points higher."}</li></ol></div></section>
    <div class="disclaimer"><b>Prototype estimate</b><p>Market profiles are illustrative seed data, not a live data feed. The workbook weights are hypotheses until calibrated on historical outcomes. Always verify financing, inspection, title, zoning, tax, and insurance details.</p></div>`;
  $("#saveResult").addEventListener("click", async e => {
    const button = e.currentTarget;
    button.textContent = "Saving…";
    try {
      const saved = await saveAnalysis({ state: { ...state }, result: r, mode, profile });
      button.textContent = saved.local ? "★ Saved on device" : "★ Saved to account";
      $("#savedBtn span").textContent = String(saved.count || 1);
    } catch (error) {
      button.textContent = "Try save again";
      alert(error.message);
    }
  });
}

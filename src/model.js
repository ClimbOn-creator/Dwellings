export const locationProfiles = [
  { city: "Vancouver", region: "BC", lat: 49.2827, lon: -123.1207, appreciation: .039, priceIncome: 12.1, population: .014, employment: .012, inventory: 3.1, saleList: 1.00, infrastructure: 78, rezoning: 74, mortgage: .045, delinquency: .003, mbs: .011, renewal: .14, debtService: .15, unemployment: .059, investor: .24, insurance: 18, regulatory: 38, transit: 88, walkability: 84, amenities: 91, school: 82, flood: 27, wildfire: 8, geo: 10, nuisance: 31 },
  { city: "Victoria", region: "BC", lat: 48.4284, lon: -123.3656, appreciation: .037, priceIncome: 10.7, population: .013, employment: .011, inventory: 3.4, saleList: .996, infrastructure: 68, rezoning: 70, mortgage: .045, delinquency: .003, mbs: .011, renewal: .14, debtService: .15, unemployment: .048, investor: .23, insurance: 17, regulatory: 36, transit: 73, walkability: 80, amenities: 88, school: 83, flood: 23, wildfire: 7, geo: 9, nuisance: 24 },
  { city: "Kelowna", region: "BC", lat: 49.888, lon: -119.496, appreciation: .034, priceIncome: 9.2, population: .022, employment: .018, inventory: 4.4, saleList: .985, infrastructure: 66, rezoning: 63, mortgage: .045, delinquency: .004, mbs: .011, renewal: .14, debtService: .15, unemployment: .057, investor: .26, insurance: 37, regulatory: 34, transit: 52, walkability: 57, amenities: 76, school: 78, flood: 19, wildfire: 48, geo: 8, nuisance: 20 },
  { city: "Calgary", region: "AB", lat: 51.0447, lon: -114.0719, appreciation: .042, priceIncome: 5.5, population: .029, employment: .021, inventory: 2.3, saleList: 1.01, infrastructure: 72, rezoning: 67, mortgage: .045, delinquency: .005, mbs: .011, renewal: .13, debtService: .14, unemployment: .071, investor: .20, insurance: 24, regulatory: 24, transit: 70, walkability: 61, amenities: 81, school: 80, flood: 16, wildfire: 4, geo: 3, nuisance: 26 },
  { city: "Toronto", region: "ON", lat: 43.6532, lon: -79.3832, appreciation: .032, priceIncome: 10.5, population: .018, employment: .013, inventory: 4.8, saleList: .987, infrastructure: 82, rezoning: 69, mortgage: .045, delinquency: .004, mbs: .011, renewal: .15, debtService: .155, unemployment: .072, investor: .28, insurance: 16, regulatory: 42, transit: 86, walkability: 83, amenities: 92, school: 84, flood: 14, wildfire: 1, geo: 2, nuisance: 36 },
];

const positiveFactors = [
  ["Land value / buildable area", .12, 150, 500, "lower", d => d.buildable > 0 ? d.price / d.buildable : null],
  ["Redevelopment feasibility", .10, 20, 90, "higher", d => d.redevelopment],
  ["Transit access", .07, 20, 95, "higher", d => d.transit],
  ["Walkability", .05, 20, 95, "higher", d => d.walkability],
  ["Amenity & school access", .05, 30, 95, "higher", d => (d.amenities + d.school) / 2],
  ["Comparable scarcity", .10, 20, 95, "higher", d => d.scarcity],
  ["Rental net yield", .08, .01, .06, "higher", d => ((d.rent * 12) - d.operatingCosts) / d.price],
  ["Population & jobs growth", .10, 0, .04, "higher", d => (d.population + d.employment) / 2],
  ["Market supply pressure", .08, 8, 1, "lower", d => d.inventory],
  ["Market momentum", .07, .94, 1.05, "higher", d => d.saleList],
  ["Infrastructure catalyst", .09, 10, 95, "higher", d => d.infrastructure],
  ["Rezoning catalyst", .09, 10, 95, "higher", d => d.rezoning],
];

const riskFactors = [
  ["Physical hazard", .20, 0, 100, d => (d.flood + d.wildfire + d.geo + d.nuisance) / 4],
  ["Property condition", .12, 0, .10, d => d.repairs / d.price],
  ["Resale liquidity", .10, 15, 90, d => d.daysOnMarket],
  ["Local affordability", .12, 4, 14, d => d.priceIncome],
  ["Mortgage pressure", .12, .02, .09, d => d.mortgage],
  ["Credit stress", .12, 0, 100, d => 100 * ((d.delinquency / .03) + (d.mbs / .03) + (d.renewal / .40)) / 3],
  ["Household leverage", .10, .08, .22, d => d.debtService],
  ["Labour market", .08, .03, .12, d => d.unemployment],
  ["Investor-cycle exposure", .07, .05, .45, d => d.investor],
  ["Insurance & regulation", .07, 0, 100, d => (d.insurance + d.regulatory) / 2],
];

const clamp = n => Math.max(0, Math.min(100, n));
const normalize = (raw, low, high, direction = "higher") => {
  const n = direction === "lower" ? ((low - raw) / (low - high)) * 100 : ((raw - low) / (high - low)) * 100;
  return clamp(n);
};

export function nearestProfile(lat, lon) {
  return locationProfiles.map(p => ({ ...p, distance: Math.hypot((p.lat - lat) * 111, (p.lon - lon) * 75) })).sort((a, b) => a.distance - b.distance)[0];
}

export function analyze(d, mode = "home") {
  const positives = positiveFactors.map(([name, weight, low, high, direction, getter]) => {
    const raw = getter(d); const available = Number.isFinite(raw); const score = available ? normalize(raw, low, high, direction) : null;
    return { name, weight, raw, score, available, contribution: available ? score * weight : 0 };
  });
  const risks = riskFactors.map(([name, weight, low, high, getter]) => {
    const raw = getter(d); const score = normalize(raw, low, high); return { name, weight, raw, score, contribution: score * weight };
  });
  const availableWeight = positives.filter(x => x.available).reduce((s, x) => s + x.weight, 0);
  const opportunity = positives.reduce((s, x) => s + x.contribution, 0) / availableWeight;
  const risk = risks.reduce((s, x) => s + x.contribution, 0);
  const net = clamp(opportunity - .55 * risk);
  const probability = 1 / (1 + Math.exp(-.09 * (net - 50)));
  const annualAppreciation = d.appreciation + ((opportunity - 50) / 50) * .04 - (risk / 100) * .03;
  const years = d.holdingPeriod || 5;
  const projected = d.price * Math.pow(1 + annualAppreciation, years);
  const noi = d.rent * 12 - d.operatingCosts;
  const capRate = noi / d.price;
  const principal = d.price * (1 - d.downPayment / 100);
  const monthlyRate = d.mortgage / 12;
  const payments = (d.amortization || 25) * 12;
  const monthlyMortgage = monthlyRate ? principal * monthlyRate * Math.pow(1 + monthlyRate, payments) / (Math.pow(1 + monthlyRate, payments) - 1) : principal / payments;
  const monthlyCarry = monthlyMortgage + d.operatingCosts / 12 - (mode === "invest" ? d.rent : d.rent * (d.rentalOffset || 0) / 100);
  const ranked = [
    ...positives.filter(x => x.available).map(x => ({...x, type: "upside", impact: x.contribution})),
    ...risks.map(x => ({...x, type: "risk", impact: -x.contribution * .55})),
  ].sort((a, b) => Math.abs(b.impact) - Math.abs(a.impact));
  const confidence = Math.round((.66 + availableWeight * .22) * 100);
  return { opportunity, risk, net, probability, annualAppreciation, projected, noi, capRate, monthlyMortgage, monthlyCarry, positives, risks, ranked, confidence };
}

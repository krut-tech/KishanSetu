import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-sync-token",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const AGMARKNET_BASE_URL = "https://api.agmarknet.gov.in/v1";
const FILTERS_URL = AGMARKNET_BASE_URL + "/daily-price-arrival/filters";
const REQUEST_TIMEOUT_MS = 4500;
const MARKETS_PER_BATCH = 6;
const MAX_CONCURRENCY = 6;

// Prioritize common crops that are already relevant to Gujarat farmers.
// Their IDs are resolved from the live filters response instead of hardcoding IDs.
const TARGET_COMMODITIES = [
  { name: "Groundnut", aliases: ["groundnut"] },
  { name: "Cotton", aliases: ["cotton"] },
  { name: "Onion", aliases: ["onion"] },
  { name: "Tomato", aliases: ["tomato"] },
  { name: "Wheat", aliases: ["wheat"] },
  { name: "Bajra", aliases: ["bajra"] },
  { name: "Potato", aliases: ["potato"] },
  { name: "Cumin", aliases: ["cumin", "jeera"] },
];

const GUJARAT_MARKET_PRIORITY = [
  "Rajkot",
  "Gondal",
  "Jamnagar",
  "Jetpur(Dist.Rajkot)",
  "Junagadh",
  "Morbi",
  "Upleta",
  "Amreli",
  "Bhavnagar",
  "Surendranagar",
  "Ahmedabad",
  "Mehsana",
  "Patan",
  "Deesa",
  "Palanpur",
  "Porbandar",
  "Veraval",
  "Dhoraji",
  "Botad",
  "Keshod",
];

const INDIA_MARKET_PRIORITY = [
  "Azadpur",
  "Lasalgaon",
  "Vashi",
  "Kurnool",
  "Guntur",
  "Bengaluru",
  "Indore",
  "Bhopal",
  "Jaipur",
  "Ludhiana",
  "Amritsar",
  "Kanpur",
  "Lucknow",
  "Kota",
  "Nashik",
  "Pune",
  "Hyderabad",
  "Nagpur",
  "Sriganganagar",
  "Bikaner",
  "Rajkot",
  "Gondal",
  "Jamnagar",
  "Jetpur(Dist.Rajkot)",
  "Junagadh",
  "Morbi",
  "Upleta",
  "Amreli",
  "Bhavnagar",
  "Surendranagar",
  "Ahmedabad",
  "Mehsana",
  "Deesa",
  "Palanpur",
  "Patna",
  "Raipur",
  "Sangli",
  "Solapur",
  "Erode",
  "Hubli",
  "Mysore",
  "Warangal",
  "Nizamabad",
];

const CATEGORY_KEYWORDS: Record<string, string[]> = {
  Cereals: ["wheat", "rice", "paddy", "maize", "jowar", "bajra", "barley", "ragi"],
  Pulses: ["gram", "moong", "masur", "lentil", "arhar", "tur", "urad", "peas", "rajma", "cowpea"],
  Vegetables: [
    "onion", "potato", "tomato", "brinjal", "cabbage", "cauliflower", "carrot", "cucumber",
    "peas", "bean", "lady finger", "bhindi", "chilli", "capsicum", "gourd", "spinach", "methi",
  ],
  Fruits: [
    "mango", "banana", "apple", "grape", "orange", "papaya", "guava", "pomegranate",
    "watermelon", "muskmelon", "lemon", "sapota", "pineapple",
  ],
  Oilseeds: ["groundnut", "mustard", "soyabean", "soybean", "sunflower", "sesame", "til", "castor", "copra"],
  Spices: ["turmeric", "chilli", "coriander", "cumin", "jeera", "garlic", "ginger", "cardamom", "pepper"],
};

type AnyRecord = Record<string, unknown>;

interface MarketRef {
  id: number;
  mkt_name: string;
  state_id: number;
  district_id: number | null;
}

interface CommodityRef {
  id: number;
  name: string;
}

interface MarketCommodityResult {
  market: MarketRef;
  commodity: CommodityRef;
  rows: AnyRecord[];
  error?: string;
}

function jsonResponse(body: AnyRecord, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function resolveCategory(name: string): string | null {
  const lower = name.toLowerCase();
  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((keyword) => lower.includes(keyword))) return category;
  }
  return null;
}

function parsePositivePrice(value: unknown): number | null {
  if (typeof value !== "number" && typeof value !== "string") return null;
  const parsed = typeof value === "number"
    ? value
    : Number(value.replace(/,/g, "").trim());
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function rowsFromPayload(payload: unknown): AnyRecord[] {
  if (Array.isArray(payload)) return payload.filter((row) => row && typeof row === "object") as AnyRecord[];
  if (!payload || typeof payload !== "object") return [];
  const data = (payload as AnyRecord).data;
  if (Array.isArray(data)) return data.filter((row) => row && typeof row === "object") as AnyRecord[];
  if (data && typeof data === "object") return [data as AnyRecord];
  return [];
}

async function fetchJson(url: string): Promise<unknown> {
  const response = await fetch(url, {
    headers: {
      "Accept": "application/json, text/plain, */*",
      "Origin": "https://agmarknet.gov.in",
      "Referer": "https://agmarknet.gov.in/",
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/135.0.0.0 Safari/537.36",
    },
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const body = await response.text();
  if (!response.ok) {
    throw new Error("HTTP " + response.status + ": " + body.slice(0, 180));
  }
  try {
    return JSON.parse(body);
  } catch {
    throw new Error("Agmarknet returned a non-JSON response.");
  }
}

function selectMarkets(
  rawMarkets: AnyRecord[],
  targetStateId: number | null,
  batch: number,
): MarketRef[] {
  const eligible: MarketRef[] = rawMarkets.flatMap((raw) => {
    const id = Number(raw.id);
    const stateId = Number(raw.state_id);
    const name = typeof raw.mkt_name === "string" ? raw.mkt_name.trim() : "";
    const districtId = raw.district_id === null || raw.district_id === undefined
      ? null
      : Number(raw.district_id);
    if (!Number.isFinite(id) || id <= 0 || !Number.isFinite(stateId) || stateId <= 0 || !name) return [];
    if (/^all markets?$/i.test(name)) return [];
    if (targetStateId !== null && stateId !== targetStateId) return [];
    return [{ id, mkt_name: name, state_id: stateId, district_id: districtId }];
  });

  const ordered: MarketRef[] = [];
  const seen = new Set<number>();
  const priority = targetStateId === null ? INDIA_MARKET_PRIORITY : GUJARAT_MARKET_PRIORITY;

  for (const term of priority) {
    const matches = eligible
      .filter((market) => !seen.has(market.id) && market.mkt_name.toLowerCase().includes(term.toLowerCase()))
      .sort((a, b) => {
        const score = (market: MarketRef) =>
          (market.mkt_name.toLowerCase().startsWith(term.toLowerCase()) ? 0 : 10) +
          (/veg|vegetable/i.test(market.mkt_name) ? 3 : 0);
        return score(a) - score(b) || a.mkt_name.localeCompare(b.mkt_name);
      });
    if (matches.length > 0) {
      ordered.push(matches[0]);
      seen.add(matches[0].id);
    }
  }

  const remaining = eligible
    .filter((market) => !seen.has(market.id))
    .sort((a, b) => a.state_id - b.state_id || a.mkt_name.localeCompare(b.mkt_name));

  ordered.push(...remaining);
  const start = batch * MARKETS_PER_BATCH;
  return ordered.slice(start, start + MARKETS_PER_BATCH);
}

function selectCommodities(rawCommodities: AnyRecord[]): CommodityRef[] {
  const output: CommodityRef[] = [];
  const seen = new Set<number>();
  for (const target of TARGET_COMMODITIES) {
    const names = rawCommodities
      .filter((item) => typeof item.cmdt_name === "string")
      .map((item) => ({ item, name: String(item.cmdt_name).trim().toLowerCase() }));
    let match = names.find((candidate) => target.aliases.includes(candidate.name));
    if (!match) {
      match = names.find((candidate) =>
        target.aliases.some((alias) =>
          candidate.name.startsWith(alias + " ") || candidate.name.startsWith(alias + "(")
        )
      );
    }
    if (!match) continue;
    const id = Number(match.item.cmdt_id);
    if (!Number.isFinite(id) || id <= 0 || seen.has(id)) continue;
    output.push({ id, name: target.name });
    seen.add(id);
  }
  return output;
}

function normalizeProduceName(commodityName: string, varietyRaw: string): string {
  if (!varietyRaw || /^unknown$/i.test(varietyRaw)) return commodityName;
  if (/^other$/i.test(varietyRaw)) return commodityName + " (Other)";
  if (varietyRaw.toLowerCase().startsWith(commodityName.toLowerCase())) {
    const suffix = varietyRaw.slice(commodityName.length).replace(/^\s*[-–:]\s*/, "").trim();
    return suffix ? commodityName + " (" + suffix + ")" : commodityName;
  }
  return commodityName + " (" + varietyRaw + ")";
}

async function fetchMarketCommodity(market: MarketRef, commodity: CommodityRef): Promise<MarketCommodityResult> {
  const query = new URLSearchParams({
    marketId: String(market.id),
    stateId: String(market.state_id),
    commodityId: String(commodity.id),
    includeExcel: "false",
  });
  const url = AGMARKNET_BASE_URL + "/prices-and-arrivals/commodity-price/lastweek?" + query.toString();
  try {
    const payload = await fetchJson(url);
    return { market, commodity, rows: rowsFromPayload(payload) };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.warn("Agmarknet request failed for " + market.mkt_name + " / " + commodity.name + ": " + message);
    return { market, commodity, rows: [], error: message.slice(0, 180) };
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const requestedState = url.searchParams.get("state")?.trim() ?? "";
    const batchValue = Number.parseInt(url.searchParams.get("batch") ?? "0", 10);
    const batch = Number.isFinite(batchValue) ? Math.max(0, Math.min(batchValue, 100)) : 0;
    const dryRun = url.searchParams.get("dryRun") === "true";

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ success: false, error: "Missing Supabase server environment." }, 500);
    }

    // pg_cron uses a private token so the public endpoint cannot be used to trigger expensive syncs.
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const suppliedToken = req.headers.get("x-sync-token") ?? "";
    const { data: syncControl, error: syncControlError } = await supabase
      .from("market_sync_control")
      .select("sync_token")
      .eq("id", true)
      .maybeSingle();
    if (syncControlError || !syncControl?.sync_token) {
      console.error("Market sync token is not configured:", syncControlError?.message ?? "missing token");
      return jsonResponse({ success: false, error: "Market sync trigger is not configured." }, 503);
    }
    if (suppliedToken.length === 0 || suppliedToken !== syncControl.sync_token) {
      return jsonResponse({ success: false, error: "Unauthorized sync trigger." }, 401);
    }

    let filterPayload: unknown;
    try {
      filterPayload = await fetchJson(FILTERS_URL);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      return jsonResponse({ success: false, provider: "Agmarknet", error: "Could not fetch Agmarknet filters: " + message }, 502);
    }

    if (!filterPayload || typeof filterPayload !== "object") {
      return jsonResponse({ success: false, provider: "Agmarknet", error: "Agmarknet filters response was invalid." }, 502);
    }
    const filterData = (filterPayload as AnyRecord).data;
    if (!filterData || typeof filterData !== "object") {
      return jsonResponse({ success: false, provider: "Agmarknet", error: "Agmarknet filters did not contain data." }, 502);
    }
    const filterSets = filterData as AnyRecord;
    const rawStates = Array.isArray(filterSets.state_data) ? filterSets.state_data as AnyRecord[] : [];
    const rawMarkets = Array.isArray(filterSets.market_data) ? filterSets.market_data as AnyRecord[] : [];
    const rawCommodities = Array.isArray(filterSets.cmdt_data) ? filterSets.cmdt_data as AnyRecord[] : [];
    const rawDistricts = Array.isArray(filterSets.district_data) ? filterSets.district_data as AnyRecord[] : [];

    let targetStateId: number | null = null;
    let targetStateName = "All India (selected markets)";
    if (requestedState) {
      const state = rawStates.find((item) =>
        typeof item.state_name === "string" &&
        item.state_name.toLowerCase() === requestedState.toLowerCase()
      );
      if (!state) return jsonResponse({ success: false, error: "State not found in Agmarknet filters: " + requestedState }, 400);
      targetStateId = Number(state.state_id);
      targetStateName = String(state.state_name);
    }

    const markets = selectMarkets(rawMarkets, targetStateId, batch);
    const commodities = selectCommodities(rawCommodities);
    if (markets.length === 0) {
      return jsonResponse({ success: false, provider: "Agmarknet", state: targetStateName, batch, error: "No markets found for this batch." }, 404);
    }
    if (commodities.length === 0) {
      return jsonResponse({ success: false, provider: "Agmarknet", error: "None of the configured commodities were present in the filters response." }, 502);
    }

    const stateNames = new Map<number, string>();
    for (const state of rawStates) {
      const id = Number(state.state_id);
      if (Number.isFinite(id) && typeof state.state_name === "string") stateNames.set(id, state.state_name);
    }
    const districtNames = new Map<number, string>();
    for (const district of rawDistricts) {
      const id = Number(district.id);
      if (Number.isFinite(id) && typeof district.district_name === "string") districtNames.set(id, district.district_name);
    }

    const work: Array<{ market: MarketRef; commodity: CommodityRef }> = [];
    for (const market of markets) {
      for (const commodity of commodities) work.push({ market, commodity });
    }
    const results: MarketCommodityResult[] = new Array(work.length);
    let cursor = 0;
    const workerCount = Math.min(MAX_CONCURRENCY, work.length);
    await Promise.all(Array.from({ length: workerCount }, async () => {
      while (true) {
        const index = cursor++;
        if (index >= work.length) break;
        results[index] = await fetchMarketCommodity(work[index].market, work[index].commodity);
      }
    }));

    const priceMap = new Map<string, AnyRecord>();
    let successfulRequests = 0;
    let failedRequests = 0;
    for (const result of results) {
      if (!result.error) successfulRequests++;
      else failedRequests++;

      for (const item of result.rows) {
        const varietyRaw = typeof item.variety === "string" ? item.variety.trim() : "";
        const produceName = normalizeProduceName(result.commodity.name, varietyRaw);
        const districtName = result.market.district_id === null
          ? ""
          : districtNames.get(result.market.district_id) ?? "";
        const stateName = stateNames.get(result.market.state_id) ?? "";
        const location = [districtName, stateName].filter(Boolean).join(", ");

        for (const [key, value] of Object.entries(item)) {
          if (!/^20\d{2}-\d{2}-\d{2}$/.test(key)) continue;
          const parsedDate = new Date(key + "T00:00:00Z");
          if (Number.isNaN(parsedDate.getTime())) continue;
          const price = parsePositivePrice(value);
          // Agmarknet uses "NR" when no report exists. Never store NR as a price.
          if (price === null) continue;

          const unique = [produceName, result.market.mkt_name, key].join("|");
          if (priceMap.has(unique)) continue;
          priceMap.set(unique, {
            produce_name: produceName,
            category: resolveCategory(result.commodity.name),
            market_name: result.market.mkt_name,
            location: location || null,
            price,
            unit: "Quintal",
            price_date: key,
            trend: "stable",
            source: "Agmarknet 2.0 API",
          });
        }
      }
    }

    const priceRows = Array.from(priceMap.values());
    if (dryRun) {
      return jsonResponse({
        success: priceRows.length > 0,
        dryRun: true,
        provider: "Agmarknet",
        state: targetStateName,
        batch,
        marketsSelected: markets.length,
        marketNames: markets.map((market) => market.mkt_name),
        commoditiesSelected: commodities.map((commodity) => commodity.name),
        requestsAttempted: work.length,
        successfulRequests,
        failedRequests,
        validPriceRows: priceRows.length,
        sample: priceRows.slice(0, 12),
        failures: results.filter((result) => result.error).slice(0, 5).map((result) => ({
          market: result.market.mkt_name,
          commodity: result.commodity.name,
          error: result.error,
        })),
      }, priceRows.length > 0 ? 200 : 502);
    }

    if (priceRows.length === 0) {
      return jsonResponse({
        success: false,
        provider: "Agmarknet",
        state: targetStateName,
        batch,
        marketsSelected: markets.length,
        commoditiesSelected: commodities.length,
        requestsAttempted: work.length,
        successfulRequests,
        failedRequests,
        upserted: 0,
        message: "No numeric market prices were returned. Existing market_prices data was left unchanged.",
        failures: results.filter((result) => result.error).slice(0, 5).map((result) => ({
          market: result.market.mkt_name,
          commodity: result.commodity.name,
          error: result.error,
        })),
      }, failedRequests === work.length ? 502 : 200);
    }

    let upserted = 0;
    const chunkSize = 100;
    for (let index = 0; index < priceRows.length; index += chunkSize) {
      const chunk = priceRows.slice(index, index + chunkSize);
      const { error } = await supabase
        .from("market_prices")
        .upsert(chunk, { onConflict: "produce_name,market_name,price_date" });
      if (error) {
        console.error("Agmarknet upsert failed:", error.message);
        return jsonResponse({
          success: false,
          provider: "Agmarknet",
          state: targetStateName,
          requestsAttempted: work.length,
          successfulRequests,
          failedRequests,
          attemptedRows: priceRows.length,
          upserted,
          error: "Database upsert failed: " + error.message,
        }, 500);
      }
      upserted += chunk.length;
    }

    const { error: trendError } = await supabase.rpc("recompute_market_price_trends");
    if (trendError) console.warn("Market-price trend recompute failed:", trendError.message);

    const responseBody: AnyRecord = {
      success: true,
      provider: "Agmarknet",
      state: targetStateName,
      batch,
      marketsSelected: markets.length,
      marketNames: markets.map((market) => market.mkt_name),
      commoditiesSelected: commodities.map((commodity) => commodity.name),
      requestsAttempted: work.length,
      successfulRequests,
      failedRequests,
      numericPriceRows: priceRows.length,
      upserted,
      trendRecomputed: !trendError,
      message: "Agmarknet prices synchronized. NR values were skipped; prior rows were preserved.",
    };
    console.log("Agmarknet sync summary:", JSON.stringify(responseBody));
    return jsonResponse(responseBody);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("sync-market-prices unexpected error:", message);
    return jsonResponse({ success: false, provider: "Agmarknet", error: message.slice(0, 250) }, 500);
  }
});

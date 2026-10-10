import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const RESOURCE_ID = "9ef84268-d588-465a-a308-a864a43d0070";
// Public sample key from data.gov.in's own docs. It works but is capped at
// 10 records per request. Set the DATA_GOV_IN_API_KEY secret with your own
// free key (https://data.gov.in -> My Account -> Generate API Key) to pull
// full pages of real data.
const FALLBACK_SAMPLE_KEY = "579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b";

// data.gov.in has been observed hanging or returning 503 for extended
// periods (upstream government API instability, and possibly heavier
// throttling on the shared public FALLBACK_SAMPLE_KEY). Without a client-
// side timeout, a single slow/hung page request could block the whole
// function until the platform's own execution limit, wasting the entire
// run on one bad page and giving callers (pg_cron/pg_net) no clean signal
// to retry sooner. Setting a dedicated DATA_GOV_IN_API_KEY secret (instead
// of relying on the shared fallback) is the most effective fix for the
// underlying reliability issue; this timeout just makes failures fail
// fast and clearly instead of hanging.
const PER_PAGE_TIMEOUT_MS = 15000;

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

function resolveCategory(commodity: string): string | null {
  const lower = commodity.toLowerCase();
  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((k) => lower.includes(k))) return category;
  }
  return null;
}

function parsePrice(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  const n = typeof value === "number" ? value : parseFloat(String(value).replace(/,/g, ""));
  return Number.isFinite(n) && n > 0 ? n : null;
}

function parseArrivalDate(value: unknown): string | null {
  // data.gov.in returns dates as "DD/MM/YYYY"
  if (typeof value !== "string") return null;
  const parts = value.split("/");
  if (parts.length !== 3) return null;
  const [dd, mm, yyyy] = parts;
  if (!dd || !mm || !yyyy) return null;
  return `${yyyy}-${mm.padStart(2, "0")}-${dd.padStart(2, "0")}`;
}

interface DataGovRecord {
  state?: string;
  district?: string;
  market?: string;
  commodity?: string;
  variety?: string;
  grade?: string;
  arrival_date?: string;
  min_price?: string | number;
  max_price?: string | number;
  modal_price?: string | number;
}

// Never leak the data.gov.in API key: fetch() errors embed the full request
// URL (including ?api-key=...), and this function's error text is returned to
// any caller, so strip the key from every message.
function redactKey(text: string): string {
  return text.replace(/api-key=[^&\s)"']+/gi, "api-key=REDACTED");
}

async function fetchDataGovPage(apiKey: string, limit: number, offset: number, state?: string, commodity?: string) {
  const params = new URLSearchParams({
    "api-key": apiKey,
    format: "json",
    limit: String(limit),
    offset: String(offset),
  });
  if (state) params.set("filters[state.keyword]", state);
  if (commodity) params.set("filters[commodity]", commodity);

  const url = `https://api.data.gov.in/resource/${RESOURCE_ID}?${params.toString()}`;

  let res: Response;
  try {
    res = await fetch(url, { signal: AbortSignal.timeout(PER_PAGE_TIMEOUT_MS) });
  } catch (err) {
    if (err instanceof Error && err.name === "TimeoutError") {
      throw new Error(`data.gov.in request timed out after ${PER_PAGE_TIMEOUT_MS}ms (offset ${offset})`);
    }
    throw new Error(`data.gov.in request errored (offset ${offset}): ${redactKey(err instanceof Error ? err.message : String(err))}`);
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`data.gov.in request failed (${res.status}): ${redactKey(text)}`);
  }
  return await res.json();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const state = url.searchParams.get("state") ?? undefined;
    const commodity = url.searchParams.get("commodity") ?? undefined;
    const maxPages = Math.min(parseInt(url.searchParams.get("pages") ?? "5", 10) || 5, 10);
    const pageSize = 100;

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const apiKey = Deno.env.get("DATA_GOV_IN_API_KEY") || FALLBACK_SAMPLE_KEY;
    const usingSampleKey = !Deno.env.get("DATA_GOV_IN_API_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const allRecords: DataGovRecord[] = [];
    const pageErrors: string[] = [];
    for (let page = 0; page < maxPages; page++) {
      const offset = page * pageSize;
      try {
        const json = await fetchDataGovPage(apiKey, pageSize, offset, state, commodity);
        const records: DataGovRecord[] = json.records ?? [];
        allRecords.push(...records);
        if (records.length < pageSize) break; // no more pages
        if (usingSampleKey) break; // sample key ignores paging, avoid useless repeat calls
      } catch (pageErr) {
        // Stop paginating on first failure (subsequent pages of the same
        // upstream call almost always fail the same way), but keep
        // whatever earlier pages already succeeded instead of discarding
        // the whole run.
        pageErrors.push(pageErr instanceof Error ? pageErr.message : String(pageErr));
        console.error(`sync-market-prices: page ${page} failed, stopping pagination:`, pageErr);
        break;
      }
    }

    console.log(`Fetched ${allRecords.length} records from data.gov.in (sample key: ${usingSampleKey})`);

    if (allRecords.length === 0) {
      const message = pageErrors.length > 0
        ? `data.gov.in did not return any usable data: ${pageErrors[0]}`
        : "No valid records returned from data.gov.in";
      return new Response(
        JSON.stringify({ success: pageErrors.length === 0, message, fetched: 0, upserted: 0, usingSampleKey }),
        { status: pageErrors.length > 0 ? 502 : 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Map raw records to our schema, then de-duplicate on the same key our
    // unique constraint uses (produce_name, market_name, price_date).
    // data.gov.in sometimes returns multiple rows for the same
    // commodity+market+date that only differ by grade, which would otherwise
    // make a single upsert() call fail with "ON CONFLICT DO UPDATE command
    // cannot affect row a second time". We keep the average price across
    // duplicates.
    const byKey = new Map<
      string,
      {
        produce_name: string;
        category: string | null;
        market_name: string;
        location: string | null;
        price: number;
        unit: string;
        price_date: string;
        source: string;
        _sum: number;
        _count: number;
      }
    >();

    for (const r of allRecords) {
      const commodityName = (r.commodity || "").trim();
      const marketName = (r.market || "").trim();
      const priceDate = parseArrivalDate(r.arrival_date) ?? new Date().toISOString().slice(0, 10);
      const modal = parsePrice(r.modal_price);
      const min = parsePrice(r.min_price);
      const max = parsePrice(r.max_price);
      const price = modal ?? (min !== null && max !== null ? (min + max) / 2 : null);

      if (!commodityName || !marketName || price === null) continue;

      const produceName = r.variety && r.variety.trim() && r.variety.trim().toLowerCase() !== "other"
        ? `${commodityName} (${r.variety.trim()})`
        : commodityName;

      const location = [r.district, r.state].filter(Boolean).join(", ");
      const key = `${produceName}|${marketName}|${priceDate}`;

      const existing = byKey.get(key);
      if (existing) {
        existing._sum += price;
        existing._count += 1;
        existing.price = existing._sum / existing._count;
      } else {
        byKey.set(key, {
          produce_name: produceName,
          category: resolveCategory(commodityName),
          market_name: marketName,
          location: location || null,
          price,
          unit: "Quintal",
          price_date: priceDate,
          source: "data.gov.in (Agmarknet)",
          _sum: price,
          _count: 1,
        });
      }
    }

    const rows = Array.from(byKey.values()).map(({ _sum, _count, ...rest }) => rest);

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: "No valid records returned from data.gov.in", fetched: allRecords.length, upserted: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { error: upsertError } = await supabase
      .from("market_prices")
      .upsert(rows, { onConflict: "produce_name,market_name,price_date" });

    if (upsertError) {
      throw new Error(`Upsert failed: ${upsertError.message}`);
    }

    const { error: trendError } = await supabase.rpc("recompute_market_price_trends");
    if (trendError) {
      console.warn("Trend recompute failed:", trendError.message);
    }

    return new Response(
      JSON.stringify({
        success: true,
        fetched: allRecords.length,
        upserted: rows.length,
        usingSampleKey,
        partialFailure: pageErrors.length > 0 ? pageErrors[0] : undefined,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("sync-market-prices error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

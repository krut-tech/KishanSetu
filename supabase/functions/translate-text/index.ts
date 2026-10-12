import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text.trim().toLowerCase());
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

interface TranslationResult {
  translatedText: string;
  detectedSourceLang: string;
}

async function translateSingleText(
  text: string,
  targetLang: string,
  sourceLang: string
): Promise<TranslationResult> {
  const trimmed = text.trim();
  if (!trimmed) {
    return { translatedText: text, detectedSourceLang: sourceLang };
  }

  const src = sourceLang === "auto" ? "auto" : sourceLang;

  // 1. Try Google Translate public endpoint first with a 3s timeout
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${src}&tl=${targetLang}&dt=t&q=${encodeURIComponent(trimmed)}`;
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && Array.isArray(data[0])) {
        const translated = data[0]
          .map((part: any) => (Array.isArray(part) ? part[0] ?? "" : ""))
          .join("");
        const detectedSrc = typeof data[2] === "string" ? data[2] : sourceLang;
        if (translated && translated.trim().length > 0) {
          return {
            translatedText: translated.trim(),
            detectedSourceLang: detectedSrc,
          };
        }
      }
    }
  } catch (e) {
    console.warn("Google translate error, trying MyMemory fallback:", e);
  }

  // 2. Fallback to MyMemory API with a 3s timeout
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);
    const pair = `${sourceLang === "auto" ? "en" : sourceLang}|${targetLang}`;
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(trimmed)}&langpair=${pair}`;
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      const rawRes = data?.responseData?.translatedText;
      if (
        rawRes &&
        typeof rawRes === "string" &&
        !rawRes.startsWith("MYMEMORY WARNING:") &&
        data?.responseStatus === 200
      ) {
        return {
          translatedText: rawRes.trim(),
          detectedSourceLang: sourceLang,
        };
      }
    }
  } catch (e) {
    console.warn("MyMemory translate error:", e);
  }

  return { translatedText: trimmed, detectedSourceLang: sourceLang };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json().catch(() => ({}));
    const targetLang = (body.target_lang ?? body.targetLang ?? "en").toLowerCase();
    const sourceLang = (body.source_lang ?? body.sourceLang ?? "auto").toLowerCase();
    const rawText = body.text ?? body.source_text ?? "";
    const rawTexts = body.texts ?? [];

    const supportedLangs = ["en", "hi", "gu"];
    if (!supportedLangs.includes(targetLang)) {
      return new Response(
        JSON.stringify({ error: `Unsupported target_lang: ${targetLang}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (rawText && typeof rawText === "string") {
      const text = rawText.trim();
      if (!text || text.length > 2000) {
        return new Response(
          JSON.stringify({ translated_text: rawText, cached: false }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const textHash = await sha256Hex(text);

      // Check translation_cache table
      const { data: cached } = await supabase
        .from("translation_cache")
        .select("translated_text, source_lang")
        .eq("text_hash", textHash)
        .eq("target_lang", targetLang)
        .maybeSingle();

      if (cached && cached.translated_text) {
        return new Response(
          JSON.stringify({
            translated_text: cached.translated_text,
            cached: true,
            source_lang: cached.source_lang ?? sourceLang,
            target_lang: targetLang,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // If source and target language match explicitly, return directly
      if (sourceLang !== "auto" && sourceLang === targetLang) {
        return new Response(
          JSON.stringify({
            translated_text: text,
            cached: false,
            source_lang: sourceLang,
            target_lang: targetLang,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { translatedText, detectedSourceLang } = await translateSingleText(
        text,
        targetLang,
        sourceLang
      );

      // Insert into cache
      if (translatedText && translatedText !== text) {
        await supabase.from("translation_cache").upsert(
          {
            text_hash: textHash,
            source_text: text,
            source_lang: detectedSourceLang ?? sourceLang,
            target_lang: targetLang,
            translated_text: translatedText,
          },
          { onConflict: "text_hash,target_lang" }
        );
      }

      return new Response(
        JSON.stringify({
          translated_text: translatedText,
          cached: false,
          source_lang: detectedSourceLang ?? sourceLang,
          target_lang: targetLang,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (Array.isArray(rawTexts) && rawTexts.length > 0) {
      const results: Record<string, string> = {};
      const validItems = rawTexts
        .filter((t) => typeof t === "string" && t.trim().length > 0)
        .map((t) => (t as String).trim());

      if (validItems.length === 0) {
        return new Response(
          JSON.stringify({ translations: {}, target_lang: targetLang }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Batch hash calculation
      const itemHashes: Array<{ text: string; hash: string }> = await Promise.all(
        validItems.map(async (text) => ({ text, hash: await sha256Hex(text) }))
      );

      const hashes = itemHashes.map((i) => i.hash);

      // Batch query DB cache
      const { data: cachedList } = await supabase
        .from("translation_cache")
        .select("text_hash, translated_text")
        .in("text_hash", hashes)
        .eq("target_lang", targetLang);

      const cacheMap = new Map<string, string>();
      if (cachedList) {
        for (const row of cachedList) {
          if (row.text_hash && row.translated_text) {
            cacheMap.set(row.text_hash, row.translated_text);
          }
        }
      }

      const uncachedItems: Array<{ text: string; hash: string }> = [];

      for (const item of itemHashes) {
        if (cacheMap.has(item.hash)) {
          results[item.text] = cacheMap.get(item.hash)!;
        } else {
          uncachedItems.push(item);
        }
      }

      // Parallel batch translation for uncached items
      if (uncachedItems.length > 0) {
        await Promise.all(
          uncachedItems.map(async (item) => {
            const { translatedText, detectedSourceLang } = await translateSingleText(
              item.text,
              targetLang,
              sourceLang
            );
            results[item.text] = translatedText;

            if (translatedText && translatedText !== item.text) {
              await supabase.from("translation_cache").upsert(
                {
                  text_hash: item.hash,
                  source_text: item.text,
                  source_lang: detectedSourceLang ?? sourceLang,
                  target_lang: targetLang,
                  translated_text: translatedText,
                },
                { onConflict: "text_hash,target_lang" }
              );
            }
          })
        );
      }

      return new Response(
        JSON.stringify({ translations: results, target_lang: targetLang }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Missing text or texts parameter" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error?.message ?? "Translation internal error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

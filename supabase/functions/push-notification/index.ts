import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/**
 * Generates an OAuth2 Access Token for FCM HTTP v1 using Service Account Credentials.
 */
async function getFcmAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  let cleanedKey = privateKey.trim();
  if (
    (cleanedKey.startsWith('"') && cleanedKey.endsWith('"')) ||
    (cleanedKey.startsWith("'") && cleanedKey.endsWith("'"))
  ) {
    cleanedKey = cleanedKey.substring(1, cleanedKey.length - 1);
  }
  const formattedPrivateKey = cleanedKey.replace(/\\n/g, "\n");

  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = formattedPrivateKey
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const paddedPem = pemContents.padEnd(
    pemContents.length + ((4 - (pemContents.length % 4)) % 4),
    "="
  );
  const binaryDer = Uint8Array.from(atob(paddedPem), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const now = Math.floor(Date.now() / 1000);
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: getNumericDate(now + 3600),
      iat: getNumericDate(now),
    },
    key
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-id:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Failed to obtain FCM OAuth token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

/**
 * Maps notification type to KisanSetu application route.
 */
function resolveRoute(type: string, relatedType?: string): string {
  switch (type) {
    case "new_offer":
    case "offer_accepted":
    case "offer_rejected":
    case "counter_offer":
    case "offer_updated":
    case "offer_cancelled":
      return "/offers";
    case "produce":
    case "produce_interest":
      return "/my-produce";
    case "market_price":
    case "market_price_update":
      return "/market-prices";
    default:
      return "/notifications";
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    console.log("Received notification webhook payload:", JSON.stringify(body));

    const record = body.record || body;
    if (!record || !record.user_id || !record.title) {
      return new Response(
        JSON.stringify({ error: "Invalid webhook payload: missing record or record.user_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const fcmProjectId = Deno.env.get("FCM_PROJECT_ID");
    const fcmClientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
    const fcmPrivateKey = Deno.env.get("FCM_PRIVATE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.");
    }

    if (!fcmProjectId || !fcmClientEmail || !fcmPrivateKey) {
      console.warn("FCM credentials missing. Skipping push dispatch.");
      return new Response(
        JSON.stringify({ message: "Push credentials not configured. Payload logged.", recordId: record.id }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Fetch active device push tokens for target user from public.user_devices
    const { data: devices, error: deviceError } = await supabase
      .from("user_devices")
      .select("id, push_token")
      .eq("user_id", record.user_id)
      .eq("is_active", true);

    if (deviceError) {
      throw new Error(`Error fetching user devices: ${deviceError.message}`);
    }

    if (!devices || devices.length === 0) {
      console.log(`No active push tokens found for user: ${record.user_id}`);
      return new Response(
        JSON.stringify({ message: "No active devices registered for user", userId: record.user_id }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const accessToken = await getFcmAccessToken(fcmClientEmail, fcmPrivateKey);
    const route = record.route ? String(record.route) : resolveRoute(String(record.type || ""), String(record.related_type || ""));

    let sentCount = 0;
    let deactivatedCount = 0;

    for (const device of devices) {
      const fcmMessage = {
        message: {
          token: device.push_token,
          notification: {
            title: String(record.title || "KisanSetu Notification"),
            body: String(record.message || ""),
          },
          data: {
            notification_id: String(record.id || ""),
            type: String(record.type || "system"),
            related_id: String(record.related_id || ""),
            related_type: String(record.related_type || ""),
            route: route,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "kisansetu_notifications",
              sound: "default",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        },
      };

      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`;
      const fcmResponse = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmMessage),
      });

      if (fcmResponse.ok) {
        sentCount++;
      } else {
        const errorJson = await fcmResponse.json();
        console.error(`FCM send error for token ${device.push_token}:`, JSON.stringify(errorJson));

        const status = errorJson?.error?.status;
        const details = errorJson?.error?.details || [];
        const isUnregistered =
          status === "UNREGISTERED" ||
          status === "NOT_FOUND" ||
          status === "INVALID_ARGUMENT" ||
          details.some(
            (d: any) =>
              d.errorCode === "UNREGISTERED" ||
              d.errorCode === "INVALID_ARGUMENT" ||
              d.errorCode === "SENDER_ID_MISMATCH" ||
              (d["@type"] && String(d["@type"]).includes("UNREGISTERED"))
          );

        if (isUnregistered) {
          console.log(`Deactivating invalid token: ${device.push_token}`);
          await supabase
            .from("user_devices")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("id", device.id);
          deactivatedCount++;
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        notificationId: record.id,
        userId: record.user_id,
        sentCount,
        deactivatedCount,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Push notification Edge Function error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

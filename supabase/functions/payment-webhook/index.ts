import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

function verifyRazorpaySignature(body: string, signature: string, secret: string) {
  const crypto = globalThis.crypto;
  const encoder = new TextEncoder();
  return crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  ).then(key =>
    crypto.subtle.sign("HMAC", key, encoder.encode(body))
  ).then(sig =>
    Buffer.from(sig).toString("hex") === signature
  );
}

serve(async (req) => {
  const body = await req.text();
  const signature = req.headers.get("x-razorpay-signature") || "";

  const isValid = await verifyRazorpaySignature(
    body,
    signature,
    Deno.env.get("RAZORPAY_WEBHOOK_SECRET")!
  );

  if (!isValid) {
    return new Response("Invalid signature", { status: 401 });
  }

  const payload = JSON.parse(body);
  const userId = payload?.payload?.payment?.entity?.notes?.user_id;

  if (!userId) {
    return new Response("User not found", { status: 400 });
  }

  await supabase.from("subscriptions").upsert({
    user_id: userId,
    is_active: true,
    provider: "razorpay",
    updated_at: new Date().toISOString(),
  });

  return new Response("OK", { status: 200 });
});

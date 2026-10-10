-- Reliability fixes for the daily market price sync (Agmarknet).
--  1. make sure pg_net/pg_cron exist (cron jobs silently fail without pg_net)
--  2. run log table so a failed/missed sync can be diagnosed with plain SQL
--  3. windowed trend recompute (the old one rewrote the WHOLE table every run)
--  4. one helper that calls the Edge Function with the private sync token
--  5. cron jobs now go through that helper (+ a second Gujarat batch)
--  6. run_market_price_sync() to trigger everything by hand from the SQL editor

CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. run log -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.market_sync_log (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ran_at timestamptz NOT NULL DEFAULT now(),
  ok boolean NOT NULL,
  provider text,
  state text,
  batch integer,
  markets integer,
  requests integer,
  successful integer,
  failed integer,
  rows_upserted integer,
  duration_ms integer,
  error text
);
CREATE INDEX IF NOT EXISTS market_sync_log_ran_at_idx ON public.market_sync_log (ran_at DESC);
ALTER TABLE public.market_sync_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.market_sync_log FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.market_sync_log TO service_role;

-- 3. cheaper trend recompute ---------------------------------------------
CREATE OR REPLACE FUNCTION public.recompute_market_price_trends()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH ranked AS (
    SELECT
      id,
      price,
      price_date,
      LAG(price) OVER (
        PARTITION BY produce_name, market_name
        ORDER BY price_date
      ) AS prev_price
    FROM public.market_prices
    WHERE price_date >= current_date - 60
  )
  UPDATE public.market_prices mp
  SET trend = CASE
    WHEN ranked.prev_price IS NULL THEN 'stable'
    WHEN mp.price > ranked.prev_price THEN 'up'
    WHEN mp.price < ranked.prev_price THEN 'down'
    ELSE 'stable'
  END
  FROM ranked
  WHERE mp.id = ranked.id
    AND ranked.price_date >= current_date - 14;
$$;
REVOKE EXECUTE ON FUNCTION public.recompute_market_price_trends() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recompute_market_price_trends() TO service_role;

-- 4. one place that knows how to call the function ------------------------
CREATE OR REPLACE FUNCTION public.market_sync_call(p_query text)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT net.http_post(
    url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices' || p_query,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-sync-token', (SELECT sync_token FROM public.market_sync_control WHERE id = true)
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 55000
  );
$$;
REVOKE EXECUTE ON FUNCTION public.market_sync_call(text) FROM PUBLIC, anon, authenticated;

-- 6. manual trigger (SQL editor): select * from public.run_market_price_sync();
CREATE OR REPLACE FUNCTION public.run_market_price_sync()
RETURNS TABLE (target text, request_id bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  q text;
BEGIN
  FOREACH q IN ARRAY ARRAY[
    '?state=Gujarat&batch=0',
    '?state=Gujarat&batch=1',
    '?batch=0',
    '?batch=1',
    '?batch=2'
  ]
  LOOP
    target := q;
    request_id := public.market_sync_call(q);
    RETURN NEXT;
  END LOOP;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.run_market_price_sync() FROM PUBLIC, anon, authenticated;

-- 5. (re)schedule the jobs ------------------------------------------------
DO $migration$
DECLARE existing_job RECORD;
BEGIN
  FOR existing_job IN
    SELECT jobid FROM cron.job
    WHERE jobname IN (
      'sync-market-prices-general',
      'sync-market-prices-gujarat',
      'sync-market-prices-gujarat-2',
      'sync-market-prices-retry-1',
      'sync-market-prices-retry-2'
    )
  LOOP
    PERFORM cron.unschedule(existing_job.jobid);
  END LOOP;
END
$migration$;

SELECT cron.schedule('sync-market-prices-gujarat',   '0 6 * * *',  $job$ SELECT public.market_sync_call('?state=Gujarat&batch=0'); $job$);
SELECT cron.schedule('sync-market-prices-gujarat-2', '5 6 * * *',  $job$ SELECT public.market_sync_call('?state=Gujarat&batch=1'); $job$);
SELECT cron.schedule('sync-market-prices-general',   '10 6 * * *', $job$ SELECT public.market_sync_call('?batch=0'); $job$);
SELECT cron.schedule('sync-market-prices-retry-1',   '0 10 * * *', $job$ SELECT public.market_sync_call('?batch=1'); $job$);
SELECT cron.schedule('sync-market-prices-retry-2',   '0 14 * * *', $job$ SELECT public.market_sync_call('?batch=2'); $job$);

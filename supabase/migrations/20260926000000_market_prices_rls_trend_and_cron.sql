-- Market Prices feature: fix RLS (it had zero policies, blocking all reads),
-- add an upsert-friendly unique constraint, add a trend-recompute function,
-- and schedule the sync-market-prices Edge Function to run daily via pg_cron.

-- 1. market_prices had RLS enabled but no policies at all, so no one --
--    not even authenticated users -- could read it. Market prices are
--    public reference data; writes stay server-side only (the
--    sync-market-prices Edge Function uses the service role key, which
--    bypasses RLS).
CREATE POLICY "Authenticated users can read market prices"
  ON public.market_prices FOR SELECT
  TO authenticated
  USING (true);

-- 2. Needed so the sync job can upsert (insert new / update existing)
--    rather than creating duplicate rows every time it runs for the same
--    produce+market+day.
ALTER TABLE public.market_prices
  ADD CONSTRAINT market_prices_produce_market_date_key
  UNIQUE (produce_name, market_name, price_date);

-- 3. Recomputes the 'trend' column for every row by comparing its price to
--    the most recent earlier price for the same produce+market. Called by
--    the sync-market-prices Edge Function after every upsert.
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
      LAG(price) OVER (
        PARTITION BY produce_name, market_name
        ORDER BY price_date
      ) AS prev_price
    FROM public.market_prices
  )
  UPDATE public.market_prices mp
  SET trend = CASE
    WHEN ranked.prev_price IS NULL THEN 'stable'
    WHEN mp.price > ranked.prev_price THEN 'up'
    WHEN mp.price < ranked.prev_price THEN 'down'
    ELSE 'stable'
  END
  FROM ranked
  WHERE mp.id = ranked.id;
$$;

-- 4. Schedule daily refreshes via pg_cron + pg_net.
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Broad/general mandi prices, every day at 6:00 AM UTC (11:30 AM IST)
SELECT cron.schedule(
  'sync-market-prices-general',
  '0 6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?pages=5',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- Gujarat-specific mandi prices, same schedule +5 min
SELECT cron.schedule(
  'sync-market-prices-gujarat',
  '5 6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?state=Gujarat&pages=3',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

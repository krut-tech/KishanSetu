-- Protect the scheduled market-price sync from arbitrary public invocations.
-- The token is generated inside Postgres and is never committed or returned to callers.
CREATE TABLE IF NOT EXISTS public.market_sync_control (
  id boolean PRIMARY KEY DEFAULT true CHECK (id = true),
  sync_token text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.market_sync_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.market_sync_control FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.market_sync_control TO service_role;

INSERT INTO public.market_sync_control (id, sync_token)
VALUES (true, encode(extensions.gen_random_bytes(32), 'hex'))
ON CONFLICT (id) DO NOTHING;

-- Recreate the scheduled jobs so each request sends the private trigger token.
DO $migration$
DECLARE existing_job RECORD;
BEGIN
  FOR existing_job IN
    SELECT jobid
    FROM cron.job
    WHERE jobname IN (
      'sync-market-prices-general',
      'sync-market-prices-gujarat',
      'sync-market-prices-retry-1',
      'sync-market-prices-retry-2'
    )
  LOOP
    PERFORM cron.unschedule(existing_job.jobid);
  END LOOP;
END
$migration$;

SELECT cron.schedule(
  'sync-market-prices-general',
  '0 6 * * *',
  $job$
    SELECT net.http_post(
      url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?batch=0',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-sync-token', (SELECT sync_token FROM public.market_sync_control WHERE id = true)
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 55000
    );
  $job$
);

SELECT cron.schedule(
  'sync-market-prices-gujarat',
  '5 6 * * *',
  $job$
    SELECT net.http_post(
      url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?state=Gujarat&batch=0',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-sync-token', (SELECT sync_token FROM public.market_sync_control WHERE id = true)
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 55000
    );
  $job$
);

SELECT cron.schedule(
  'sync-market-prices-retry-1',
  '0 10 * * *',
  $job$
    SELECT net.http_post(
      url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?batch=1',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-sync-token', (SELECT sync_token FROM public.market_sync_control WHERE id = true)
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 55000
    );
  $job$
);

SELECT cron.schedule(
  'sync-market-prices-retry-2',
  '0 14 * * *',
  $job$
    SELECT net.http_post(
      url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?batch=2',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-sync-token', (SELECT sync_token FROM public.market_sync_control WHERE id = true)
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 55000
    );
  $job$
);

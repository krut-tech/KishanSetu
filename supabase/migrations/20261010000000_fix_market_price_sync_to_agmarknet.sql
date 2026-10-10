-- Replace the failing data.gov.in sync schedule with the working Agmarknet weekly-price sync.
-- The Edge Function batches six markets per run to keep request volume bounded.
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

-- Three daily India-wide batches (18 selected markets/day).
SELECT cron.schedule(
  'sync-market-prices-general',
  '0 6 * * *',
  $job$
    SELECT net.http_post(
      url := 'https://dpbuhtverikgcaieucdp.supabase.co/functions/v1/sync-market-prices?batch=0',
      headers := '{"Content-Type":"application/json"}'::jsonb,
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
      headers := '{"Content-Type":"application/json"}'::jsonb,
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
      headers := '{"Content-Type":"application/json"}'::jsonb,
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
      headers := '{"Content-Type":"application/json"}'::jsonb,
      body := '{}'::jsonb,
      timeout_milliseconds := 55000
    );
  $job$
);

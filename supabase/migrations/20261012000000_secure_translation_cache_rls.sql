-- Migration: 20261012000000_secure_translation_cache_rls.sql
-- Description: Enable RLS on translation_cache, revoke public direct read/write grants,
--              grant full access to service_role (used by translate-text Edge Function),
--              and add a UNIQUE constraint on (text_hash, target_lang) for upsert reliability.

-- 1. Ensure UNIQUE constraint exists for (text_hash, target_lang) upserting
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.translation_cache'::regclass
          AND conname = 'translation_cache_text_hash_target_lang_key'
    ) THEN
        ALTER TABLE public.translation_cache
            ADD CONSTRAINT translation_cache_text_hash_target_lang_key UNIQUE (text_hash, target_lang);
    END IF;
END $$;

-- 2. Enable Row Level Security on translation_cache
ALTER TABLE public.translation_cache ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing insecure public policies
DROP POLICY IF EXISTS translation_cache_select_policy ON public.translation_cache;
DROP POLICY IF EXISTS translation_cache_insert_policy ON public.translation_cache;
DROP POLICY IF EXISTS translation_cache_update_policy ON public.translation_cache;
DROP POLICY IF EXISTS translation_cache_delete_policy ON public.translation_cache;

-- 4. Revoke direct access from anon, authenticated, and public roles
REVOKE ALL ON public.translation_cache FROM anon, authenticated, public;

-- 5. Grant full table access to service_role for Edge Function execution
GRANT ALL ON public.translation_cache TO service_role;

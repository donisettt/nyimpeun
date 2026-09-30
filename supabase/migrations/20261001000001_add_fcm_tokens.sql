CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  device_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

-- RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies first
DROP POLICY IF EXISTS "Users manage own tokens" ON public.user_fcm_tokens;

-- Explicit separate policies
DROP POLICY IF EXISTS "Users can insert own tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can insert own tokens"
  ON public.user_fcm_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can select own tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can select own tokens"
  ON public.user_fcm_tokens FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can update own tokens"
  ON public.user_fcm_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can delete own tokens"
  ON public.user_fcm_tokens FOR DELETE
  USING (auth.uid() = user_id);

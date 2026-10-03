-- =============================================================================
-- Nyimpeun — Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- =============================================================================

-- =============================================================================
-- 1. PROFILES (extends auth.users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name        TEXT NOT NULL DEFAULT '',
  avatar_url       TEXT,
  currency         TEXT NOT NULL DEFAULT 'IDR',
  has_pin          BOOLEAN NOT NULL DEFAULT FALSE,
  pin_attempts     INTEGER NOT NULL DEFAULT 0,
  pin_locked_until TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: select own"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles: insert own"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: update own"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Auto-create profile row when a new user registers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 2. WALLETS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.wallets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'cash',   -- cash | bank | e-wallet
  balance     BIGINT NOT NULL DEFAULT 0,       -- stored in smallest currency unit (IDR)
  currency    TEXT NOT NULL DEFAULT 'IDR',
  color       TEXT,
  icon        TEXT,
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wallets: select own"
  ON public.wallets FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "wallets: insert own"
  ON public.wallets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "wallets: update own"
  ON public.wallets FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "wallets: delete own"
  ON public.wallets FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. CATEGORIES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- NULL = system default
  name        TEXT NOT NULL,
  type        TEXT NOT NULL,          -- income | expense
  icon        TEXT,
  color       TEXT NOT NULL DEFAULT '#7C3AED',
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "categories: select own or default"
  ON public.categories FOR SELECT
  USING (auth.uid() = user_id OR is_default = TRUE);

CREATE POLICY "categories: insert own"
  ON public.categories FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "categories: delete own non-default"
  ON public.categories FOR DELETE
  USING (auth.uid() = user_id AND is_default = FALSE);

-- =============================================================================
-- 4. TRANSACTIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id   UUID REFERENCES public.wallets(id) ON DELETE SET NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  type        TEXT NOT NULL,          -- income | expense | transfer
  amount      BIGINT NOT NULL,        -- stored in smallest currency unit (IDR)
  note        TEXT,
  date        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transactions: select own"
  ON public.transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "transactions: insert own"
  ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "transactions: update own"
  ON public.transactions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "transactions: delete own"
  ON public.transactions FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 5. SAVINGS GOALS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.savings_goals (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  target_amount         BIGINT NOT NULL,
  current_amount        BIGINT NOT NULL DEFAULT 0,
  linked_wallet_id      UUID REFERENCES public.wallets(id) ON DELETE SET NULL,
  deadline              DATE,
  icon                  TEXT,
  color                 TEXT,
  status                TEXT NOT NULL DEFAULT 'active',  -- active | completed | paused
  auto_allocate_percent INTEGER NOT NULL DEFAULT 0,       -- 0-100
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "savings_goals: select own"
  ON public.savings_goals FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "savings_goals: insert own"
  ON public.savings_goals FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "savings_goals: update own"
  ON public.savings_goals FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "savings_goals: delete own"
  ON public.savings_goals FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 6. SAVINGS CONTRIBUTIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.savings_contributions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id    UUID NOT NULL REFERENCES public.savings_goals(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount     BIGINT NOT NULL,
  note       TEXT,
  type       TEXT NOT NULL DEFAULT 'manual',  -- manual | auto
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.savings_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "savings_contributions: select own"
  ON public.savings_contributions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "savings_contributions: insert own"
  ON public.savings_contributions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- 7. TELEGRAM BINDINGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.telegram_bindings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  telegram_chat_id BIGINT,
  otp_code         TEXT,
  status           TEXT NOT NULL DEFAULT 'PENDING',  -- PENDING | LINKED
  expires_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.telegram_bindings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "telegram_bindings: select own"
  ON public.telegram_bindings FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "telegram_bindings: insert own"
  ON public.telegram_bindings FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "telegram_bindings: update own"
  ON public.telegram_bindings FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "telegram_bindings: delete own"
  ON public.telegram_bindings FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 8. USER FCM TOKENS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  device_name TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, fcm_token)
);

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_fcm_tokens: select own"
  ON public.user_fcm_tokens FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_fcm_tokens: insert own"
  ON public.user_fcm_tokens FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_fcm_tokens: update own"
  ON public.user_fcm_tokens FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "user_fcm_tokens: delete own"
  ON public.user_fcm_tokens FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 9. SHARED: auto-update updated_at trigger
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_wallets_updated_at
  BEFORE UPDATE ON public.wallets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 10. SUPABASE STORAGE — avatars bucket
-- =============================================================================
-- Run this separately via Supabase Dashboard → Storage, or via the CLI.
-- The app uploads to: storage/v1/object/avatars/<user_id>/<filename>.jpg
--
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('avatars', 'avatars', TRUE)
-- ON CONFLICT (id) DO NOTHING;
--
-- CREATE POLICY "avatars: upload own"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
--
-- CREATE POLICY "avatars: public read"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'avatars');

-- =============================================================================
-- Nyimpeun — Supabase Database Schema
-- Jalankan di: Supabase Dashboard → SQL Editor
-- =============================================================================

-- ─── 1. PROFILES (extends auth.users) ───────────────────────────────────────
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

-- ─── 2. ROW LEVEL SECURITY ───────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users: select own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users: update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users: insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ─── 3. AUTO-CREATE PROFILE ON REGISTER ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Trigger otomatis saat user baru register
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── 4. AUTO-UPDATE updated_at ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- FASE 2: Tabel-tabel ini untuk modul transaksi (dibuat nanti)
-- =============================================================================

-- ─── 5. WALLETS ──────────────────────────────────────────────────────────────
-- CREATE TABLE IF NOT EXISTS public.wallets (
--   id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   name        TEXT NOT NULL,
--   type        TEXT NOT NULL DEFAULT 'cash',  -- cash, bank, ewallet, investment
--   balance     NUMERIC(15,2) NOT NULL DEFAULT 0,
--   color       TEXT DEFAULT '#7C3AED',
--   icon        TEXT DEFAULT 'wallet',
--   is_active   BOOLEAN NOT NULL DEFAULT TRUE,
--   created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--   updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- ─── 6. CATEGORIES ───────────────────────────────────────────────────────────
-- CREATE TABLE IF NOT EXISTS public.categories (
--   id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- NULL = default
--   name        TEXT NOT NULL,
--   type        TEXT NOT NULL,  -- income | expense
--   icon        TEXT NOT NULL,
--   color       TEXT NOT NULL DEFAULT '#7C3AED',
--   is_default  BOOLEAN NOT NULL DEFAULT FALSE,
--   created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- ─── 7. TRANSACTIONS ─────────────────────────────────────────────────────────
-- CREATE TABLE IF NOT EXISTS public.transactions (
--   id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   wallet_id       UUID NOT NULL REFERENCES public.wallets(id),
--   category_id     UUID NOT NULL REFERENCES public.categories(id),
--   type            TEXT NOT NULL,  -- income | expense | transfer
--   amount          NUMERIC(15,2) NOT NULL,
--   note            TEXT,
--   date            DATE NOT NULL DEFAULT CURRENT_DATE,
--   created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--   updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

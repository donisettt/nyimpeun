-- Create telegram_bindings table
CREATE TABLE IF NOT EXISTS public.telegram_bindings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    telegram_chat_id bigint,
    otp_code text UNIQUE NOT NULL,
    status text DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'LINKED')),
    created_at timestamptz DEFAULT now(),
    expires_at timestamptz DEFAULT (now() + interval '10 minutes')
);

-- Enable RLS
ALTER TABLE public.telegram_bindings ENABLE ROW LEVEL SECURITY;

-- Allow user to view their own bindings
DROP POLICY IF EXISTS "Users can view their own bindings" ON public.telegram_bindings;
CREATE POLICY "Users can view their own bindings"
ON public.telegram_bindings
FOR SELECT
USING (auth.uid() = user_id);

-- Allow user to insert their own bindings
DROP POLICY IF EXISTS "Users can insert their own bindings" ON public.telegram_bindings;
CREATE POLICY "Users can insert their own bindings"
ON public.telegram_bindings
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow user to delete their own bindings
DROP POLICY IF EXISTS "Users can delete their own bindings" ON public.telegram_bindings;
CREATE POLICY "Users can delete their own bindings"
ON public.telegram_bindings
FOR DELETE
USING (auth.uid() = user_id);

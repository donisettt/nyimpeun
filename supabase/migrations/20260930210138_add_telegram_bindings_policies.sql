-- Allow user to delete their own bindings
DROP POLICY IF EXISTS "Users can delete their own bindings" ON public.telegram_bindings;
CREATE POLICY "Users can delete their own bindings"
ON public.telegram_bindings
FOR DELETE
USING (auth.uid() = user_id);

-- Allow user to update their own bindings
DROP POLICY IF EXISTS "Users can update their own bindings" ON public.telegram_bindings;
CREATE POLICY "Users can update their own bindings"
ON public.telegram_bindings
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

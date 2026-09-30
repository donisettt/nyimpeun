-- Allow user to delete their own bindings
CREATE POLICY "Users can delete their own bindings"
ON public.telegram_bindings
FOR DELETE
USING (auth.uid() = user_id);

-- Allow user to update their own bindings
CREATE POLICY "Users can update their own bindings"
ON public.telegram_bindings
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Function to update wallet balance automatically
CREATE OR REPLACE FUNCTION public.update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Jika transaksi BARU (INSERT)
    IF (TG_OP = 'INSERT') THEN
        IF upper(NEW.type) = 'INCOME' THEN
            UPDATE public.wallets SET balance = balance + NEW.amount WHERE id = NEW.wallet_id;
        ELSIF upper(NEW.type) = 'EXPENSE' THEN
            UPDATE public.wallets SET balance = balance - NEW.amount WHERE id = NEW.wallet_id;
        END IF;
        RETURN NEW;
    
    -- Jika transaksi DIHAPUS (DELETE)
    ELSIF (TG_OP = 'DELETE') THEN
        IF upper(OLD.type) = 'INCOME' THEN
            UPDATE public.wallets SET balance = balance - OLD.amount WHERE id = OLD.wallet_id;
        ELSIF upper(OLD.type) = 'EXPENSE' THEN
            UPDATE public.wallets SET balance = balance + OLD.amount WHERE id = OLD.wallet_id;
        END IF;
        RETURN OLD;
        
    -- Jika transaksi DIUBAH (UPDATE)
    ELSIF (TG_OP = 'UPDATE') THEN
        -- 1. Kembalikan saldo dari transaksi lama
        IF upper(OLD.type) = 'INCOME' THEN
            UPDATE public.wallets SET balance = balance - OLD.amount WHERE id = OLD.wallet_id;
        ELSIF upper(OLD.type) = 'EXPENSE' THEN
            UPDATE public.wallets SET balance = balance + OLD.amount WHERE id = OLD.wallet_id;
        END IF;
        
        -- 2. Terapkan saldo dari transaksi baru
        IF upper(NEW.type) = 'INCOME' THEN
            UPDATE public.wallets SET balance = balance + NEW.amount WHERE id = NEW.wallet_id;
        ELSIF upper(NEW.type) = 'EXPENSE' THEN
            UPDATE public.wallets SET balance = balance - NEW.amount WHERE id = NEW.wallet_id;
        END IF;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pasang Trigger ke tabel transactions
DROP TRIGGER IF EXISTS update_wallet_balance_trigger ON public.transactions;
CREATE TRIGGER update_wallet_balance_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION public.update_wallet_balance();

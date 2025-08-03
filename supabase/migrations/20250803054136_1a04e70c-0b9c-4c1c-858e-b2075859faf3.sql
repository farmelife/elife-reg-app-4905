-- Enable RLS on tables that are missing it
ALTER TABLE public.cash_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Create policies for cash_summary (admin only)
CREATE POLICY "Admins can manage cash summary" 
ON public.cash_summary 
FOR ALL 
USING (is_admin_context())
WITH CHECK (is_admin_context());

-- Create policies for cash_transactions (admin only)
CREATE POLICY "Admins can manage cash transactions" 
ON public.cash_transactions 
FOR ALL 
USING (is_admin_context())
WITH CHECK (is_admin_context());

-- Create policies for expenses (admin only)
CREATE POLICY "Admins can manage expenses" 
ON public.expenses 
FOR ALL 
USING (is_admin_context())
WITH CHECK (is_admin_context());
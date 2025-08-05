-- Enhanced approval system with complete fee and cash management

-- Create approval tracking table
CREATE TABLE IF NOT EXISTS public.approval_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID NOT NULL REFERENCES public.registrations(id) ON DELETE CASCADE,
  previous_status application_status,
  new_status application_status NOT NULL,
  approved_by TEXT NOT NULL,
  fee_collected NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  remarks TEXT
);

-- Enable RLS on approval_logs
ALTER TABLE public.approval_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for approval_logs
CREATE POLICY "Admins can manage approval logs"
ON public.approval_logs
FOR ALL
USING (is_admin_context())
WITH CHECK (is_admin_context());

-- Enhanced function for complete approval workflow
CREATE OR REPLACE FUNCTION public.approve_registration(
  p_registration_id UUID,
  p_admin_username TEXT,
  p_fee_collected NUMERIC DEFAULT 0,
  p_remarks TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_registration RECORD;
  v_previous_status application_status;
  v_cash_summary_exists BOOLEAN;
BEGIN
  -- Set admin operation context
  PERFORM set_config('app.is_admin_operation', 'true', true);
  
  -- Get current registration details
  SELECT * INTO v_registration
  FROM public.registrations 
  WHERE id = p_registration_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Registration not found'
    );
  END IF;
  
  -- Store previous status
  v_previous_status := v_registration.status;
  
  -- Update registration status to approved
  UPDATE public.registrations 
  SET 
    status = 'approved',
    approved_date = now(),
    approved_by = p_admin_username,
    fee_paid = COALESCE(p_fee_collected, v_registration.fee_paid, 0),
    updated_at = now()
  WHERE id = p_registration_id;
  
  -- Log the approval
  INSERT INTO public.approval_logs (
    registration_id,
    previous_status,
    new_status,
    approved_by,
    fee_collected,
    remarks
  ) VALUES (
    p_registration_id,
    v_previous_status,
    'approved',
    p_admin_username,
    p_fee_collected,
    p_remarks
  );
  
  -- Initialize cash summary if it doesn't exist
  SELECT EXISTS(SELECT 1 FROM public.cash_summary) INTO v_cash_summary_exists;
  
  IF NOT v_cash_summary_exists THEN
    INSERT INTO public.cash_summary (cash_in_hand, cash_at_bank)
    VALUES (0, 0);
  END IF;
  
  -- Update cash in hand with collected fee
  IF p_fee_collected > 0 THEN
    UPDATE public.cash_summary 
    SET 
      cash_in_hand = cash_in_hand + p_fee_collected,
      updated_at = now();
  END IF;
  
  -- Return success with updated data
  RETURN json_build_object(
    'success', true,
    'message', 'Registration approved successfully',
    'data', json_build_object(
      'registration_id', p_registration_id,
      'previous_status', v_previous_status,
      'new_status', 'approved',
      'fee_collected', p_fee_collected,
      'approved_by', p_admin_username,
      'approved_date', now()
    )
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Function to reject registration
CREATE OR REPLACE FUNCTION public.reject_registration(
  p_registration_id UUID,
  p_admin_username TEXT,
  p_remarks TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_registration RECORD;
  v_previous_status application_status;
BEGIN
  -- Set admin operation context
  PERFORM set_config('app.is_admin_operation', 'true', true);
  
  -- Get current registration details
  SELECT * INTO v_registration
  FROM public.registrations 
  WHERE id = p_registration_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Registration not found'
    );
  END IF;
  
  -- Store previous status
  v_previous_status := v_registration.status;
  
  -- Update registration status to rejected
  UPDATE public.registrations 
  SET 
    status = 'rejected',
    approved_date = NULL,
    approved_by = NULL,
    updated_at = now()
  WHERE id = p_registration_id;
  
  -- Log the rejection
  INSERT INTO public.approval_logs (
    registration_id,
    previous_status,
    new_status,
    approved_by,
    fee_collected,
    remarks
  ) VALUES (
    p_registration_id,
    v_previous_status,
    'rejected',
    p_admin_username,
    0,
    p_remarks
  );
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'message', 'Registration rejected successfully',
    'data', json_build_object(
      'registration_id', p_registration_id,
      'previous_status', v_previous_status,
      'new_status', 'rejected',
      'approved_by', p_admin_username
    )
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Function to get total fees collected (for reports)
CREATE OR REPLACE FUNCTION public.get_total_fees_collected(
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_total NUMERIC DEFAULT 0;
BEGIN
  SELECT COALESCE(SUM(fee_collected), 0) INTO v_total
  FROM public.approval_logs
  WHERE new_status = 'approved'
    AND (p_start_date IS NULL OR created_at::date >= p_start_date)
    AND (p_end_date IS NULL OR created_at::date <= p_end_date);
    
  RETURN v_total;
END;
$$;
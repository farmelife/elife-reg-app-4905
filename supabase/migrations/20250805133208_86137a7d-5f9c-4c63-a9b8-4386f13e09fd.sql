-- Fix the approve_registration function to handle cash_summary updates properly
CREATE OR REPLACE FUNCTION public.approve_registration(
  p_registration_id uuid, 
  p_admin_username text, 
  p_fee_collected numeric DEFAULT 0, 
  p_remarks text DEFAULT NULL::text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
  
  -- Handle cash summary updates only if fee is collected
  IF p_fee_collected > 0 THEN
    -- Check if cash summary exists
    SELECT EXISTS(SELECT 1 FROM public.cash_summary) INTO v_cash_summary_exists;
    
    IF NOT v_cash_summary_exists THEN
      -- Create initial cash summary record
      INSERT INTO public.cash_summary (cash_in_hand, cash_at_bank)
      VALUES (p_fee_collected, 0);
    ELSE
      -- Update existing cash summary
      UPDATE public.cash_summary 
      SET 
        cash_in_hand = cash_in_hand + p_fee_collected,
        updated_at = now()
      WHERE id IN (SELECT id FROM public.cash_summary LIMIT 1);
    END IF;
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
$function$;
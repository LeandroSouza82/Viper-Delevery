-- Migration: approve_specific_user
-- Purpose: Approve the test driver by email.
-- Action: Update profile status to 'approved'.

UPDATE public.profiles
SET status = 'approved'
WHERE id IN (
    SELECT id FROM auth.users 
    WHERE email = 'lsouza557@gmail.com'
);

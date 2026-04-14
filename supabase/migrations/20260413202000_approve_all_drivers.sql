-- Migration: approve_all_drivers
-- Purpose: Approve all existing drivers for testing purposes.
-- Action: Update profile status to 'approved'.

UPDATE profiles 
SET status = 'approved' 
WHERE status IN ('pending_vehicle', 'pending_approval');

-- Migration: 03_update_vehicle_inspection
-- Adds vehicle inspection photo columns and document URL columns

-- Add model and 4-angle photo URLs to vehicles table
ALTER TABLE public.vehicles
ADD COLUMN IF NOT EXISTS model TEXT,
ADD COLUMN IF NOT EXISTS photo_front_url TEXT,
ADD COLUMN IF NOT EXISTS photo_side_right_url TEXT,
ADD COLUMN IF NOT EXISTS photo_side_left_url TEXT,
ADD COLUMN IF NOT EXISTS photo_rear_url TEXT;

-- Add document URLs to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS crlv_url TEXT,
ADD COLUMN IF NOT EXISTS criminal_record_url TEXT,
ADD COLUMN IF NOT EXISTS address_proof_url TEXT;

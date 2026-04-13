-- Migration: 05_reorganize_vehicle_data
-- Goals: 
-- 1. Align column names to official specs (cnh_front_url)
-- 2. Move personal docs to profiles
-- 3. Move vehicle docs and inspection photos to vehicles
-- 4. Clean up residue from previous migrations

-- 1. CLEANUP VEHICLES TABLE 
-- Remove columns that should be in profiles or have old names
ALTER TABLE public.vehicles 
DROP COLUMN IF EXISTS cnh_url,
DROP COLUMN IF EXISTS photo_url,
DROP COLUMN IF EXISTS doc_url,
DROP COLUMN IF EXISTS photo_front_url,
DROP COLUMN IF EXISTS photo_side_right_url,
DROP COLUMN IF EXISTS photo_side_left_url,
DROP COLUMN IF EXISTS photo_rear_url;

-- Add correct columns to vehicles
ALTER TABLE public.vehicles
ADD COLUMN IF NOT EXISTS model TEXT,
ADD COLUMN IF NOT EXISTS color TEXT,
ADD COLUMN IF NOT EXISTS crlv_url TEXT,
ADD COLUMN IF NOT EXISTS inspection_front_url TEXT,
ADD COLUMN IF NOT EXISTS inspection_back_url TEXT,
ADD COLUMN IF NOT EXISTS inspection_left_url TEXT,
ADD COLUMN IF NOT EXISTS inspection_right_url TEXT;

-- 2. CLEANUP PROFILES TABLE
-- Add personal documents to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS cnh_front_url TEXT,
ADD COLUMN IF NOT EXISTS criminal_record_url TEXT,
ADD COLUMN IF NOT EXISTS address_proof_url TEXT;

-- Remove crlv_url from profiles (it moved to vehicles)
ALTER TABLE public.profiles
DROP COLUMN IF EXISTS crlv_url;

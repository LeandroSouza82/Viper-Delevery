-- Migration: 04_add_vehicle_color
-- Adds vehicle color column to the vehicles table

ALTER TABLE public.vehicles
ADD COLUMN IF NOT EXISTS color TEXT;

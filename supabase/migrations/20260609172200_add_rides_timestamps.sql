-- Migration: Add updated_at and completed_at columns to rides table
ALTER TABLE rides 
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NULL,
  ADD COLUMN IF NOT EXISTS completed_at timestamptz NULL;

-- Expand vehicles table to include more safety documents
ALTER TABLE public.vehicles 
ADD COLUMN IF NOT EXISTS cnh_url TEXT,
ADD COLUMN IF NOT EXISTS criminal_record_url TEXT,
ADD COLUMN IF NOT EXISTS address_proof_url TEXT,
ADD COLUMN IF NOT EXISTS crlv_url TEXT;

-- Update RLS policies (just in case they need to be more permissive, 
-- but they already allow insert by driver_id)

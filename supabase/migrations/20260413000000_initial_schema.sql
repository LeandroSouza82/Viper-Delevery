-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUM for driver status
CREATE TYPE driver_status AS ENUM (
  'pending_vehicle',
  'pending_approval',
  'approved',
  'rejected'
);

-- Profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  cpf TEXT UNIQUE NOT NULL,
  city TEXT,
  neighborhood TEXT,
  state TEXT,
  phone TEXT,
  email TEXT,
  status driver_status DEFAULT 'pending_vehicle'::driver_status NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_type TEXT CHECK (vehicle_type IN ('moto', 'carro')),
  plate TEXT NOT NULL,
  doc_url TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Storage bucket for driver documents
INSERT INTO storage.buckets (id, name, public) VALUES ('driver_documents', 'driver_documents', false);

-- Enable RLS for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT
  USING ( true );

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT
  WITH CHECK ( auth.uid() = id );

CREATE POLICY "Users can update own profile."
  ON profiles FOR UPDATE
  USING ( auth.uid() = id );

-- Enable RLS for vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vehicles are viewable by owner."
  ON vehicles FOR SELECT
  USING ( auth.uid() = driver_id );

CREATE POLICY "Users can insert their own vehicle."
  ON vehicles FOR INSERT
  WITH CHECK ( auth.uid() = driver_id );

CREATE POLICY "Users can update own vehicle."
  ON vehicles FOR UPDATE
  USING ( auth.uid() = driver_id );

-- Storage policies for driver_documents
CREATE POLICY "Users can view their own documents"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'driver_documents' AND auth.uid() = owner );

CREATE POLICY "Users can upload their own documents"
  ON storage.objects FOR INSERT
  WITH CHECK ( bucket_id = 'driver_documents' AND auth.uid() = owner );

-- Create driver_settings table
CREATE TABLE driver_settings (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  dest_filter_active BOOLEAN DEFAULT FALSE,
  dest_filter_location TEXT,
  destination_uses INTEGER DEFAULT 3,
  last_reset TIMESTAMPTZ DEFAULT NOW(),
  accepts_cash BOOLEAN DEFAULT TRUE,
  accepts_debit BOOLEAN DEFAULT TRUE,
  accepts_credit BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE driver_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own settings"
  ON driver_settings FOR SELECT
  USING ( auth.uid() = id );

CREATE POLICY "Users can insert their own settings"
  ON driver_settings FOR INSERT
  WITH CHECK ( auth.uid() = id );

CREATE POLICY "Users can update their own settings"
  ON driver_settings FOR UPDATE
  USING ( auth.uid() = id );

-- Function to handle updated_at
CREATE OR REPLACE FUNCTION update_driver_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_settings_updated_at
BEFORE UPDATE ON driver_settings
FOR EACH ROW
EXECUTE FUNCTION update_driver_settings_updated_at();

-- Insert settings for existing profiles
INSERT INTO driver_settings (id)
SELECT id FROM profiles
ON CONFLICT (id) DO NOTHING;

-- Add accepts_prepaid column to driver_settings
ALTER TABLE driver_settings 
ADD COLUMN accepts_prepaid BOOLEAN DEFAULT TRUE;

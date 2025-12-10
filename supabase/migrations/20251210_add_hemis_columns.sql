-- Add HEMIS-related columns to profiles table
-- These columns store HEMIS student data for integration

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS hemis_id TEXT,
ADD COLUMN IF NOT EXISTS hemis_login TEXT,
ADD COLUMN IF NOT EXISTS hemis_token TEXT;

-- Create index for faster HEMIS ID lookups
CREATE INDEX IF NOT EXISTS idx_profiles_hemis_id ON profiles(hemis_id);
CREATE INDEX IF NOT EXISTS idx_profiles_hemis_login ON profiles(hemis_login);

-- Add comment
COMMENT ON COLUMN profiles.hemis_id IS 'HEMIS student ID for integration';
COMMENT ON COLUMN profiles.hemis_login IS 'HEMIS login username';
COMMENT ON COLUMN profiles.hemis_token IS 'HEMIS JWT token for API calls';

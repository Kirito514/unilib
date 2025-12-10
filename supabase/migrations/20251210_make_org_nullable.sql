-- Make organization_id nullable in profiles table
-- HEMIS students may not have an organization initially

ALTER TABLE profiles
ALTER COLUMN organization_id DROP NOT NULL;

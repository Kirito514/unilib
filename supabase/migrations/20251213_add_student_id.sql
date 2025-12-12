-- Migration: Add Student Short ID System (Year-Based)
-- Date: 2025-12-13
-- Purpose: Add short numeric student IDs with year prefix for manual fallback when scanner fails
-- Format: YYXXX (e.g., 24001, 25001)

-- Add student_id column to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS student_id TEXT UNIQUE;

-- Create sequences for each year (we'll create them dynamically)
-- Function to get or create sequence for a year
CREATE OR REPLACE FUNCTION get_year_sequence(year_suffix TEXT)
RETURNS TEXT AS $$
DECLARE
    seq_name TEXT;
BEGIN
    seq_name := 'student_id_seq_' || year_suffix;
    
    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', seq_name);
    
    RETURN seq_name;
END;
$$ LANGUAGE plpgsql;

-- Function to generate year-based student ID (YYXXX format)
CREATE OR REPLACE FUNCTION generate_student_id()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    year_suffix TEXT;
    seq_name TEXT;
    next_id INTEGER;
    student_id TEXT;
BEGIN
    -- Get current year (last 2 digits)
    current_year := to_char(CURRENT_DATE, 'YY');
    year_suffix := current_year;
    
    -- Get or create sequence for this year
    seq_name := get_year_sequence(year_suffix);
    
    -- Get next sequence value for this year
    EXECUTE format('SELECT nextval(%L)', seq_name) INTO next_id;
    
    -- Format as YYXXX (year + 3-digit sequential)
    student_id := year_suffix || LPAD(next_id::TEXT, 3, '0');
    
    RETURN student_id;
END;
$$ LANGUAGE plpgsql;

-- Update existing users with student IDs
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT id FROM profiles WHERE student_id IS NULL ORDER BY created_at
    LOOP
        UPDATE profiles 
        SET student_id = generate_student_id()
        WHERE id = user_record.id;
    END LOOP;
END $$;

-- Create index for fast student ID lookups
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);

-- Add comment
COMMENT ON COLUMN profiles.student_id IS 'Short 5-digit student ID for manual input (00001, 00002, etc.)';

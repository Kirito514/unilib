-- Remove unique constraint from student_number
-- Allow multiple profiles with same student number (for testing/migration)

ALTER TABLE profiles
DROP CONSTRAINT IF EXISTS profiles_student_number_key;

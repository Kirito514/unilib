-- Add trigger to auto-generate student_id on profile creation
-- Date: 2025-12-13

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_auto_generate_student_id ON profiles;

-- Create trigger function
CREATE OR REPLACE FUNCTION auto_generate_student_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate if student_id is NULL
    IF NEW.student_id IS NULL THEN
        NEW.student_id := generate_student_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_auto_generate_student_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_student_id();

-- Verify trigger was created
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles' 
AND trigger_name = 'trigger_auto_generate_student_id';

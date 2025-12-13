-- Check and assign student IDs to existing users
-- Run this in Supabase SQL Editor

-- First, check how many users don't have student_id
SELECT COUNT(*) as users_without_id
FROM profiles
WHERE student_id IS NULL;

-- Assign student IDs to users without them
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT id FROM profiles 
        WHERE student_id IS NULL 
        ORDER BY created_at
    LOOP
        UPDATE profiles 
        SET student_id = generate_student_id()
        WHERE id = user_record.id;
        
        RAISE NOTICE 'Assigned student_id to user: %', user_record.id;
    END LOOP;
END $$;

-- Verify all users have student_id
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- Show some sample student IDs
SELECT id, name, student_id, student_number, created_at
FROM profiles
ORDER BY created_at
LIMIT 10;

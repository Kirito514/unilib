-- Check and fix student_id for all users
-- Date: 2025-12-13

-- 1. Check how many users don't have student_id
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- 2. Show users without student_id
SELECT id, name, email, student_id, created_at
FROM profiles
WHERE student_id IS NULL
ORDER BY created_at
LIMIT 10;

-- 3. Assign student_id to all users who don't have one
UPDATE profiles
SET student_id = generate_student_id()
WHERE student_id IS NULL;

-- 4. Verify all users now have student_id
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- 5. Show sample of assigned IDs
SELECT id, name, email, student_id, created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

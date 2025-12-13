-- Create missing profiles for existing auth users
-- This fixes users who were created before the trigger was working

INSERT INTO public.profiles (id, email, name, role)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', split_part(au.email, '@', 1)) as name,
    'student' as role
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Verify the fix
SELECT 
    COUNT(*) as users_without_profile
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

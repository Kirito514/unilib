-- Migration: 05_fix_auth_trigger
-- Description: Ensure handle_new_user trigger sets organization_id and role

-- 1. Create or Replace the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_org_id UUID;
BEGIN
    -- Get the default organization ID
    SELECT id INTO default_org_id FROM organizations WHERE slug = 'unilib-platform';

    -- Insert into profiles
    INSERT INTO public.profiles (
        id,
        email,
        name,
        role,
        organization_id,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        'student', -- Default role
        default_org_id,
        true,
        NOW(),
        NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

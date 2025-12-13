-- Migration: 08_fix_handle_new_user_trigger
-- Description: Recreate handle_new_user trigger with better error handling

-- 1. Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Create improved function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_org_id UUID;
BEGIN
    -- Get the default organization ID
    SELECT id INTO default_org_id
    FROM public.organizations
    WHERE slug = 'unilib-platform'
    LIMIT 1;

    -- If no default org found, create one
    IF default_org_id IS NULL THEN
        INSERT INTO public.organizations (name, slug, type, subscription_tier, subscription_status, max_students)
        VALUES ('UniLib Platform', 'unilib-platform', 'platform', 'free', 'active', 200)
        RETURNING id INTO default_org_id;
    END IF;

    -- Insert profile with default values
    INSERT INTO public.profiles (
        id,
        email,
        name,
        organization_id,
        role,
        is_active
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        default_org_id,
        'student',
        true
    );

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 4. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.organizations TO postgres, anon, authenticated, service_role;

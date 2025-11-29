import { supabaseAdmin } from '@/lib/supabase/admin';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
    try {
        // Get request body
        const body = await request.json();
        const { email, password, name, organization_id, role } = body;

        if (!email || !password || !name || !organization_id || !role) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        console.log('Creating user with email:', email);

        // Create user using Admin Client
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name }
        });

        if (createError) {
            console.error('User creation error:', createError);
            return NextResponse.json({
                error: createError.message,
                code: createError.code,
                details: createError
            }, { status: 400 });
        }

        if (!newUser.user) {
            return NextResponse.json({ error: 'Failed to create user' }, { status: 500 });
        }

        console.log('User created successfully:', newUser.user.id);

        // Wait for trigger to create profile
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Check if profile exists
        const { data: existingProfile, error: profileCheckError } = await supabaseAdmin
            .from('profiles')
            .select('*')
            .eq('id', newUser.user.id)
            .single();

        if (profileCheckError) {
            console.error('Profile check error:', profileCheckError);
        } else {
            console.log('Existing profile found:', existingProfile);
        }

        // Update profile with correct organization and role
        console.log('Updating profile with:', { organization_id, role, name });

        const { data: updatedProfile, error: updateError } = await supabaseAdmin
            .from('profiles')
            .update({
                organization_id,
                role,
                name
            })
            .eq('id', newUser.user.id)
            .select()
            .single();

        if (updateError) {
            console.error('Profile update error:', updateError);
            return NextResponse.json({
                error: 'User created but profile update failed: ' + updateError.message,
                details: updateError,
                userId: newUser.user.id
            }, { status: 500 });
        }

        console.log('Profile updated successfully:', updatedProfile);
        return NextResponse.json({
            success: true,
            user: newUser.user,
            profile: updatedProfile
        });

    } catch (error: any) {
        console.error('Error creating user:', error);
        return NextResponse.json({
            error: error.message || 'Internal Server Error'
        }, { status: 500 });
    }
}

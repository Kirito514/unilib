import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { createClient } from '@supabase/supabase-js';

export async function POST(request: NextRequest) {
    try {
        const { userId } = await request.json();

        if (!userId) {
            return NextResponse.json(
                { success: false, error: 'User ID is required' },
                { status: 400 }
            );
        }

        // Create admin client with service role key
        const supabaseAdmin = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.SUPABASE_SERVICE_ROLE_KEY!,
            {
                auth: {
                    autoRefreshToken: false,
                    persistSession: false
                }
            }
        );

        // Delete user profile first (cascade will handle related data)
        const { error: profileError } = await supabaseAdmin
            .from('profiles')
            .delete()
            .eq('id', userId);

        if (profileError) {
            console.error('Profile deletion error:', profileError);
            // Continue even if profile deletion fails
        }

        // Delete auth user using admin API
        const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(userId);

        if (authError) {
            console.error('Auth deletion error:', authError);
            return NextResponse.json(
                { success: false, error: authError.message },
                { status: 500 }
            );
        }

        return NextResponse.json({
            success: true,
            message: 'Account deleted successfully'
        });

    } catch (error: any) {
        console.error('Delete account error:', error);
        return NextResponse.json(
            { success: false, error: error.message || 'Failed to delete account' },
            { status: 500 }
        );
    }
}

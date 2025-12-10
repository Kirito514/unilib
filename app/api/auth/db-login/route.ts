import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * Direct login using database credentials (bypass HEMIS)
 * For users who are already registered
 */
export async function POST(request: NextRequest) {
    try {
        const { login } = await request.json();

        if (!login) {
            return NextResponse.json(
                { success: false, error: 'Login kiritilishi shart' },
                { status: 400 }
            );
        }

        console.log('[DB Login API] Looking up user:', login);

        // Find user by student_number
        const supabase = await createClient();

        const { data: profile } = await supabase
            .from('profiles')
            .select('id, email, student_number')
            .eq('student_number', login)
            .maybeSingle();

        if (!profile) {
            return NextResponse.json(
                { success: false, error: 'Foydalanuvchi topilmadi. Avval HEMIS orqali ro\'yxatdan o\'ting.' },
                { status: 404 }
            );
        }

        console.log('[DB Login API] ✓ User found:', profile.email);

        // Generate password (same as HEMIS login)
        const userPassword = `hemis_${login}_${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.slice(0, 10)}`;

        return NextResponse.json({
            success: true,
            data: {
                email: profile.email,
                password: userPassword,
            },
        });

    } catch (error) {
        console.error('[DB Login API] Error:', error);
        return NextResponse.json(
            { success: false, error: 'Server xatosi' },
            { status: 500 }
        );
    }
}

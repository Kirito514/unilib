import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * Sync HEMIS data to user profile
 * Updates profile with latest HEMIS information
 */
export async function POST(request: NextRequest) {
    try {
        const { userId } = await request.json();

        if (!userId) {
            return NextResponse.json(
                { success: false, error: 'User ID kiritilishi shart' },
                { status: 400 }
            );
        }

        const supabase = await createClient();

        // Get user's HEMIS token from profile
        const { data: profile } = await supabase
            .from('profiles')
            .select('hemis_token, student_number')
            .eq('id', userId)
            .single();

        if (!profile?.hemis_token || !profile?.student_number) {
            return NextResponse.json(
                { success: false, error: 'HEMIS ma\'lumotlari topilmadi. Avval HEMIS orqali login qiling.' },
                { status: 404 }
            );
        }

        console.log('[HEMIS Sync] Syncing data for student:', profile.student_number);

        // Fetch latest data from HEMIS
        const HEMIS_API_URL = 'https://student.umft.uz/rest/v1/';
        const meResponse = await fetch(`${HEMIS_API_URL}account/me`, {
            headers: { 'Authorization': `Bearer ${profile.hemis_token}` },
        });

        if (!meResponse.ok) {
            return NextResponse.json(
                { success: false, error: 'HEMIS\'dan ma\'lumot olib bo\'lmadi. Qaytadan login qiling.' },
                { status: 500 }
            );
        }

        const meData = await meResponse.json();
        const student = meData.data || meData;

        // Format name
        const formatName = (name: string) => {
            if (!name) return '';
            return name.toLowerCase().split(' ').map(word =>
                word.charAt(0).toUpperCase() + word.slice(1)
            ).join(' ');
        };

        const formattedName = formatName(
            student.full_name || student.name || `${student.first_name} ${student.second_name}`.trim()
        );

        // Update profile with latest HEMIS data
        const { error: updateError } = await supabase
            .from('profiles')
            .update({
                name: formattedName,
                avatar_url: student.image || student.picture || null,
                phone: student.phone || null,
                faculty: student.faculty?.name || null,
                student_group: student.group?.name || null,
                course: student.level?.name || null,
                education_form: student.educationForm?.name || null,
                specialty: student.specialty?.name || null,
                gpa: student.avg_gpa || null,
                last_synced_at: new Date().toISOString(),
            })
            .eq('id', userId);

        if (updateError) {
            console.error('[HEMIS Sync] Update error:', updateError);
            return NextResponse.json(
                { success: false, error: 'Ma\'lumotlarni yangilashda xatolik' },
                { status: 500 }
            );
        }

        console.log('[HEMIS Sync] ✓ Profile updated successfully');

        return NextResponse.json({
            success: true,
            message: 'Ma\'lumotlar muvaffaqiyatli yangilandi',
        });

    } catch (error) {
        console.error('[HEMIS Sync] Error:', error);
        return NextResponse.json(
            { success: false, error: 'Server xatosi' },
            { status: 500 }
        );
    }
}

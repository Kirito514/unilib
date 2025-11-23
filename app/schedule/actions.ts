'use server';

import { supabaseAdmin } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { cookies } from 'next/headers';

export async function updateSchedule(scheduleId: string, data: {
    start_date: string;
    end_date: string;
    daily_goal_pages?: number;
    daily_goal_minutes?: number;
}) {
    try {
        // Get user from cookies (server action context)
        const cookieStore = await cookies();
        const authCookie = cookieStore.get('sb-access-token');

        if (!authCookie) {
            return { success: false, error: 'Unauthorized' };
        }

        // Validate dates
        if (new Date(data.end_date) < new Date(data.start_date)) {
            return { success: false, error: 'Tugash sanasi boshlanish sanasidan katta bo\'lishi kerak' };
        }

        // Validate daily goals
        if (data.daily_goal_pages && data.daily_goal_pages <= 0) {
            return { success: false, error: 'Kunlik maqsad 0 dan katta bo\'lishi kerak' };
        }

        // First, verify the schedule belongs to the user
        const { data: schedule, error: fetchError } = await supabaseAdmin
            .from('reading_schedule')
            .select('user_id')
            .eq('id', scheduleId)
            .single();

        if (fetchError || !schedule) {
            return { success: false, error: 'Reja topilmadi' };
        }

        // Update schedule
        const { error: updateError } = await supabaseAdmin
            .from('reading_schedule')
            .update({
                start_date: data.start_date,
                end_date: data.end_date,
                daily_goal_pages: data.daily_goal_pages,
                daily_goal_minutes: data.daily_goal_minutes,
            })
            .eq('id', scheduleId)
            .eq('user_id', schedule.user_id);

        if (updateError) {
            console.error('Error updating schedule:', updateError);
            return { success: false, error: 'Rejani yangilashda xatolik yuz berdi' };
        }

        // Revalidate the schedule page
        revalidatePath('/schedule');

        return { success: true };
    } catch (error) {
        console.error('Error in updateSchedule:', error);
        return { success: false, error: 'Kutilmagan xatolik yuz berdi' };
    }
}

export async function deleteSchedule(scheduleId: string) {
    try {
        // Get user from cookies (server action context)
        const cookieStore = await cookies();
        const authCookie = cookieStore.get('sb-access-token');

        if (!authCookie) {
            return { success: false, error: 'Unauthorized' };
        }

        // First, verify the schedule belongs to the user
        const { data: schedule, error: fetchError } = await supabaseAdmin
            .from('reading_schedule')
            .select('user_id')
            .eq('id', scheduleId)
            .single();

        if (fetchError || !schedule) {
            return { success: false, error: 'Reja topilmadi' };
        }

        // Soft delete: set status to 'deleted'
        const { error: deleteError } = await supabaseAdmin
            .from('reading_schedule')
            .update({ status: 'deleted' })
            .eq('id', scheduleId)
            .eq('user_id', schedule.user_id);

        if (deleteError) {
            console.error('Error deleting schedule:', deleteError);
            return { success: false, error: 'Rejani o\'chirishda xatolik yuz berdi' };
        }

        // Revalidate the schedule page
        revalidatePath('/schedule');

        return { success: true };
    } catch (error) {
        console.error('Error in deleteSchedule:', error);
        return { success: false, error: 'Kutilmagan xatolik yuz berdi' };
    }
}

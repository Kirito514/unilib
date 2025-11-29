'use server';

import { supabaseAdmin } from '@/lib/supabase/admin';
import { revalidatePath } from 'next/cache';

export async function markAchievementsAsSeen(achievementIds: string[], userId: string) {
    try {
        const { error } = await supabaseAdmin
            .from('user_achievements')
            .update({ seen: true })
            .in('achievement_id', achievementIds)
            .eq('user_id', userId);

        if (error) throw error;

        revalidatePath('/achievements');
    } catch (error) {
        console.error('Error marking achievements as seen:', error);
    }
}

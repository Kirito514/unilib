'use server';

import { supabaseAdmin } from '@/lib/supabase/admin';
import { revalidatePath } from 'next/cache';

export type NotificationType = 'info' | 'success' | 'warning' | 'achievement' | 'reminder';

export async function getNotifications(userId: string) {
    try {
        const { data, error } = await supabaseAdmin
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(20);

        if (error) {
            console.error('Error fetching notifications:', error);
            return { success: false, error: 'Xabarlarni yuklashda xatolik' };
        }

        return { success: true, data };
    } catch (error) {
        console.error('Error in getNotifications:', error);
        return { success: false, error: 'Kutilmagan xatolik' };
    }
}

export async function markAsRead(notificationId: string, userId: string) {
    try {
        const { error } = await supabaseAdmin
            .from('notifications')
            .update({ is_read: true })
            .eq('id', notificationId)
            .eq('user_id', userId);

        if (error) {
            console.error('Error marking notification as read:', error);
            return { success: false, error: 'Xatolik yuz berdi' };
        }

        revalidatePath('/');
        return { success: true };
    } catch (error) {
        console.error('Error in markAsRead:', error);
        return { success: false, error: 'Kutilmagan xatolik' };
    }
}

export async function markAllAsRead(userId: string) {
    try {
        const { error } = await supabaseAdmin
            .from('notifications')
            .update({ is_read: true })
            .eq('user_id', userId)
            .eq('is_read', false);

        if (error) {
            console.error('Error marking all notifications as read:', error);
            return { success: false, error: 'Xatolik yuz berdi' };
        }

        revalidatePath('/');
        return { success: true };
    } catch (error) {
        console.error('Error in markAllAsRead:', error);
        return { success: false, error: 'Kutilmagan xatolik' };
    }
}

export async function createNotification(
    userId: string,
    title: string,
    message: string,
    type: NotificationType,
    link?: string
) {
    try {
        const { error } = await supabaseAdmin
            .from('notifications')
            .insert({
                user_id: userId,
                title,
                message,
                type,
                link,
                is_read: false
            });

        if (error) {
            console.error('Error creating notification:', error);
            return { success: false, error: 'Xabar yaratishda xatolik' };
        }

        revalidatePath('/');
        return { success: true };
    } catch (error) {
        console.error('Error in createNotification:', error);
        return { success: false, error: 'Kutilmagan xatolik' };
    }
}

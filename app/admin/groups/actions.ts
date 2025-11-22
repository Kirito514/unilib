'use server';

import { supabaseAdmin } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';

export async function deleteGroup(groupId: string) {
    try {
        const { error } = await supabaseAdmin
            .from('groups')
            .delete()
            .eq('id', groupId);

        if (error) throw error;

        // Log the action
        await supabaseAdmin.from('admin_logs').insert({
            action: 'Group Deleted',
            details: { groupId },
            admin_id: 'system'
        });

        revalidatePath('/admin/groups');
        return { success: true };
    } catch (error) {
        console.error('Error deleting group:', error);
        return { success: false, error: 'Failed to delete group' };
    }
}

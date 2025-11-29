import { supabaseAdmin } from '@/lib/supabase/admin';
import { GroupsTable } from '@/components/admin/GroupsTable';
import { MessageSquare } from 'lucide-react';

export const dynamic = 'force-dynamic';

async function getGroups() {
    const { data: groups, error } = await supabaseAdmin
        .from('groups')
        .select('*, books(title)')
        .order('created_at', { ascending: false });

    if (error) {
        console.error('Error fetching groups:', error);
        return [];
    }

    return groups;
}

export default async function GroupsPage() {
    const groups = await getGroups();

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-2">
                        <MessageSquare className="w-8 h-8 text-primary" />
                        Guruhlar
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        O'quv guruhlarini boshqarish
                    </p>
                </div>
                <div className="bg-card border border-border px-4 py-2 rounded-lg font-medium">
                    Jami: <span className="text-primary">{groups.length}</span>
                </div>
            </div>

            <GroupsTable groups={groups} />
        </div>
    );
}

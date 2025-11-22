import { supabaseAdmin } from '@/lib/supabase/server';
import { UsersTable } from '@/components/admin/UsersTable';
import { Users } from 'lucide-react';

export const dynamic = 'force-dynamic';

async function getUsers() {
    const { data: users, error } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

    if (error) {
        console.error('Error fetching users:', error);
        return [];
    }

    return users;
}

export default async function UsersPage() {
    const users = await getUsers();

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-2">
                        <Users className="w-8 h-8 text-primary" />
                        Foydalanuvchilar
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Tizimdagi barcha foydalanuvchilarni boshqarish
                    </p>
                </div>
                <div className="bg-card border border-border px-4 py-2 rounded-lg font-medium">
                    Jami: <span className="text-primary">{users.length}</span>
                </div>
            </div>

            <UsersTable users={users} />
        </div>
    );
}

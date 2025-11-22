import { supabaseAdmin } from '@/lib/supabase/server';
import { BooksTable } from '@/components/admin/BooksTable';
import { BookOpen, Plus } from 'lucide-react';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

async function getBooks(page: number = 1, limit: number = 10) {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    // Get total count
    const { count, error: countError } = await supabaseAdmin
        .from('books')
        .select('*', { count: 'exact', head: true });

    if (countError) {
        console.error('Error fetching books count:', countError);
        return { books: [], totalBooks: 0, totalPages: 0 };
    }

    // Get paginated data
    const { data: books, error } = await supabaseAdmin
        .from('books')
        .select('id, title, author, category, rating, cover_color, cover_url, created_at')
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        console.error('Error fetching books:', error);
        return { books: [], totalBooks: 0, totalPages: 0 };
    }

    return {
        books: books || [],
        totalBooks: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
    };
}

interface PageProps {
    searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function BooksManagementPage({ searchParams }: PageProps) {
    const params = await searchParams;
    const page = Number(params?.page) || 1;
    const limit = 10;
    const { books, totalBooks, totalPages } = await getBooks(page, limit);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-2">
                        <BookOpen className="w-8 h-8 text-primary" />
                        Kitoblar Boshqaruvi
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Tizimdagi barcha kitoblarni boshqarish
                    </p>
                </div>
                <Link
                    href="/admin/books/create"
                    className="flex items-center gap-2 px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-all shadow-lg hover:shadow-xl"
                >
                    <Plus className="w-5 h-5" />
                    Yangi Kitob
                </Link>
            </div>

            <BooksTable
                books={books}
                page={page}
                totalPages={totalPages}
                totalBooks={totalBooks}
            />
        </div>
    );
}

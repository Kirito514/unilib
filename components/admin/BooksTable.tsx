"use client";

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
    BookOpen,
    Search,
    Edit,
    Trash2
} from 'lucide-react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase/client';

interface Book {
    id: string;
    title: string;
    author: string;
    category: string;
    rating: number;
    cover_color: string;
    cover_url?: string;
    created_at: string;
}

interface BooksTableProps {
    books: Book[];
    page: number;
    totalPages: number;
    totalBooks: number;
}

export function BooksTable({ books: initialBooks, page, totalPages, totalBooks }: BooksTableProps) {
    const [books, setBooks] = useState(initialBooks);
    const [search, setSearch] = useState('');
    const [isLoading, setIsLoading] = useState<string | null>(null);
    const router = useRouter();

    useEffect(() => {
        setBooks(initialBooks);
    }, [initialBooks]);

    const filteredBooks = books.filter(book =>
        book.title.toLowerCase().includes(search.toLowerCase()) ||
        book.author.toLowerCase().includes(search.toLowerCase())
    );

    const handleDelete = async (id: string) => {
        if (!confirm('Bu kitobni o\'chirishga ishonchingiz komilmi?')) return;

        setIsLoading(id);
        try {
            const { error } = await supabase
                .from('books')
                .delete()
                .eq('id', id);

            if (error) throw error;
            setBooks(books.filter(book => book.id !== id));
        } catch (error) {
            console.error('Error deleting book:', error);
            alert('Kitobni o\'chirishda xatolik yuz berdi');
        } finally {
            setIsLoading(null);
        }
    };

    const handlePageChange = (newPage: number) => {
        if (newPage < 1 || newPage > totalPages) return;
        router.push(`/admin/books?page=${newPage}`);
    };

    return (
        <div className="space-y-4">
            {/* Search */}
            <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
                    type="text"
                    placeholder="Kitob yoki muallif nomi bo'yicha qidirish..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full pl-11 pr-4 py-3 rounded-lg bg-card border border-border focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all outline-none"
                />
            </div>

            {/* Books Table */}
            <div className="bg-card border border-border rounded-xl overflow-hidden">
                <table className="w-full">
                    <thead className="bg-muted/50">
                        <tr>
                            <th className="text-left p-4 font-semibold">Kitob</th>
                            <th className="text-left p-4 font-semibold">Muallif</th>
                            <th className="text-left p-4 font-semibold">Kategoriya</th>
                            <th className="text-left p-4 font-semibold">Reyting</th>
                            <th className="text-right p-4 font-semibold">Amallar</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredBooks.length === 0 ? (
                            <tr>
                                <td colSpan={5} className="text-center py-12 text-muted-foreground">
                                    Kitoblar topilmadi
                                </td>
                            </tr>
                        ) : (
                            filteredBooks.map((book) => (
                                <tr key={book.id} className="border-t border-border hover:bg-muted/30 transition-colors">
                                    <td className="p-4">
                                        <div className="flex items-center gap-3">
                                            <div className={`w-10 h-14 rounded ${book.cover_color} flex items-center justify-center text-white shadow-sm overflow-hidden relative`}>
                                                {book.cover_url ? (
                                                    <img src={book.cover_url} alt={book.title} className="w-full h-full object-cover" />
                                                ) : (
                                                    <BookOpen className="w-5 h-5" />
                                                )}
                                            </div>
                                            <span className="font-medium">{book.title}</span>
                                        </div>
                                    </td>
                                    <td className="p-4 text-muted-foreground">{book.author}</td>
                                    <td className="p-4">
                                        <span className="px-2 py-1 bg-primary/10 text-primary rounded text-sm">
                                            {book.category}
                                        </span>
                                    </td>
                                    <td className="p-4">
                                        <span className="font-semibold">{book.rating}</span>
                                    </td>
                                    <td className="p-4">
                                        <div className="flex items-center justify-end gap-2">
                                            <Link
                                                href={`/admin/books/${book.id}`}
                                                className="p-2 hover:bg-blue-500/10 text-blue-500 rounded-lg transition-colors"
                                                title="Tahrirlash"
                                            >
                                                <Edit className="w-4 h-4" />
                                            </Link>
                                            <button
                                                onClick={() => handleDelete(book.id)}
                                                disabled={isLoading === book.id}
                                                className="p-2 hover:bg-red-500/10 text-red-500 rounded-lg transition-colors"
                                                title="O'chirish"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>

                {/* Pagination Controls */}
                <div className="p-4 border-t border-border flex items-center justify-between">
                    <div className="text-sm text-muted-foreground">
                        Jami: <span className="font-medium text-foreground">{totalBooks}</span> ta kitob
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => handlePageChange(page - 1)}
                            disabled={page <= 1}
                            className="px-3 py-1 text-sm border border-border rounded hover:bg-muted disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Oldingi
                        </button>
                        <span className="text-sm font-medium">
                            {page} / {totalPages}
                        </span>
                        <button
                            onClick={() => handlePageChange(page + 1)}
                            disabled={page >= totalPages}
                            className="px-3 py-1 text-sm border border-border rounded hover:bg-muted disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Keyingi
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}

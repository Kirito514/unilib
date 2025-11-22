"use client";

import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';
import { AdminRoute } from '@/components/admin/AdminRoute';
import {
    BookOpen,
    Plus,
    Search,
    Edit,
    Trash2,
    Upload,
    X
} from 'lucide-react';

interface Book {
    id: string;
    title: string;
    author: string;
    category: string;
    rating: number;
    cover_color: string;
    created_at: string;
}

export default function BooksManagementPage() {
    const [books, setBooks] = useState<Book[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showAddModal, setShowAddModal] = useState(false);
    const [editingBook, setEditingBook] = useState<Book | null>(null);

    useEffect(() => {
        fetchBooks();
    }, []);

    const fetchBooks = async () => {
        try {
            const { data, error } = await supabase
                .from('books')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;
            setBooks(data || []);
        } catch (error) {
            console.error('Error fetching books:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Bu kitobni o\'chirishga ishonchingiz komilmi?')) return;

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
        }
    };

    const filteredBooks = books.filter(book =>
        book.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        book.author.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <AdminRoute requiredPermission="books:read">
            <div className="space-y-6">
                {/* Header */}
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold flex items-center gap-2">
                            <BookOpen className="w-8 h-8 text-primary" />
                            Kitoblar Boshqaruvi
                        </h1>
                        <p className="text-muted-foreground mt-1">
                            Jami {books.length} ta kitob
                        </p>
                    </div>
                    <button
                        onClick={() => setShowAddModal(true)}
                        className="flex items-center gap-2 px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-all shadow-lg hover:shadow-xl"
                    >
                        <Plus className="w-5 h-5" />
                        Yangi Kitob
                    </button>
                </div>

                {/* Search */}
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                    <input
                        type="text"
                        placeholder="Kitob yoki muallif nomi bo'yicha qidirish..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-11 pr-4 py-3 rounded-lg bg-card border border-border focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all outline-none"
                    />
                </div>

                {/* Books Table */}
                {isLoading ? (
                    <div className="flex items-center justify-center py-20">
                        <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : (
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
                                                    <div className={`w-10 h-14 rounded ${book.cover_color} flex items-center justify-center text-white shadow-sm`}>
                                                        <BookOpen className="w-5 h-5" />
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
                                                    <button
                                                        onClick={() => setEditingBook(book)}
                                                        className="p-2 hover:bg-blue-500/10 text-blue-500 rounded-lg transition-colors"
                                                        title="Tahrirlash"
                                                    >
                                                        <Edit className="w-4 h-4" />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDelete(book.id)}
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
                    </div>
                )}

                {/* Add/Edit Modal - Placeholder */}
                {(showAddModal || editingBook) && (
                    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                        <div className="bg-card border border-border rounded-2xl p-6 max-w-md w-full">
                            <div className="flex items-center justify-between mb-6">
                                <h2 className="text-xl font-bold">
                                    {editingBook ? 'Kitobni Tahrirlash' : 'Yangi Kitob Qo\'shish'}
                                </h2>
                                <button
                                    onClick={() => {
                                        setShowAddModal(false);
                                        setEditingBook(null);
                                    }}
                                    className="p-2 hover:bg-muted rounded-lg transition-colors"
                                >
                                    <X className="w-5 h-5" />
                                </button>
                            </div>
                            <p className="text-muted-foreground text-center py-8">
                                Form tez orada qo'shiladi...
                            </p>
                        </div>
                    </div>
                )}
            </div>
        </AdminRoute>
    );
}

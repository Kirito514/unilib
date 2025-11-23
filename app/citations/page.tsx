"use client";

import { ProtectedRoute } from '@/components/auth/ProtectedRoute';
import { Quote, Sparkles, BookOpen, Copy, FileText } from 'lucide-react';

export default function CitationsPage() {
    return (
        <ProtectedRoute>
            <div className="container py-16 px-4 md:px-6 max-w-4xl mx-auto">
                <div className="text-center">
                    {/* Icon */}
                    <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center mx-auto mb-6 relative">
                        <div className="absolute inset-0 rounded-full bg-gradient-to-br from-blue-500/10 to-purple-500/10 blur-xl" />
                        <Quote className="w-10 h-10 text-blue-500 relative z-10" />
                    </div>

                    {/* Title */}
                    <h1 className="text-4xl font-bold mb-4">
                        Iqtibos Generatori
                    </h1>

                    {/* Coming Soon Badge */}
                    <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/10 text-blue-500 rounded-full border border-blue-500/20 mb-6">
                        <Sparkles className="w-4 h-4" />
                        <span className="font-medium">Tez orada</span>
                    </div>

                    {/* Description */}
                    <p className="text-lg text-muted-foreground mb-12 max-w-2xl mx-auto">
                        Kitoblar uchun avtomatik iqtibos yarating. APA, MLA, Chicago va Harvard formatlarini qo'llab-quvvatlaydi.
                    </p>

                    {/* Features Preview */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
                        <div className="bg-card border border-border rounded-xl p-6">
                            <div className="w-12 h-12 rounded-lg bg-blue-500/10 flex items-center justify-center mb-4 mx-auto">
                                <FileText className="w-6 h-6 text-blue-500" />
                            </div>
                            <h3 className="font-bold mb-2">Ko'p formatlar</h3>
                            <p className="text-sm text-muted-foreground">
                                APA, MLA, Chicago, Harvard
                            </p>
                        </div>

                        <div className="bg-card border border-border rounded-xl p-6">
                            <div className="w-12 h-12 rounded-lg bg-purple-500/10 flex items-center justify-center mb-4 mx-auto">
                                <Copy className="w-6 h-6 text-purple-500" />
                            </div>
                            <h3 className="font-bold mb-2">Tez nusxalash</h3>
                            <p className="text-sm text-muted-foreground">
                                Bir bosishda nusxalang
                            </p>
                        </div>

                        <div className="bg-card border border-border rounded-xl p-6">
                            <div className="w-12 h-12 rounded-lg bg-green-500/10 flex items-center justify-center mb-4 mx-auto">
                                <BookOpen className="w-6 h-6 text-green-500" />
                            </div>
                            <h3 className="font-bold mb-2">Kutubxonadan</h3>
                            <p className="text-sm text-muted-foreground">
                                O'qigan kitoblaringizdan
                            </p>
                        </div>
                    </div>

                    {/* Example */}
                    <div className="bg-gradient-to-br from-blue-500/5 to-purple-500/5 border border-blue-500/10 rounded-2xl p-8 mb-8">
                        <h3 className="text-xl font-bold mb-4">Misol</h3>
                        <div className="bg-card border border-border rounded-lg p-4 text-left">
                            <p className="text-sm font-mono text-muted-foreground">
                                Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009).
                                <span className="italic"> Introduction to Algorithms</span> (3rd ed.).
                                MIT Press.
                            </p>
                        </div>
                        <p className="text-xs text-muted-foreground mt-2">APA format</p>
                    </div>

                    {/* CTA */}
                    <div className="bg-gradient-to-br from-primary/5 to-accent/5 border border-primary/10 rounded-2xl p-8">
                        <h3 className="text-xl font-bold mb-2">Hozircha boshqa funksiyalardan foydalaning</h3>
                        <p className="text-muted-foreground mb-4">
                            Iqtibos generatori ustida ishlanmoqda. Shu vaqtda Reyting va Yutuqlar bilan o'zingizni sinab ko'ring!
                        </p>
                        <div className="flex gap-3 justify-center">
                            <a
                                href="/library"
                                className="px-6 py-2.5 bg-primary text-primary-foreground rounded-lg font-medium hover:bg-primary/90 transition-colors"
                            >
                                Kutubxonaga o'tish
                            </a>
                            <a
                                href="/achievements"
                                className="px-6 py-2.5 bg-card border border-border rounded-lg font-medium hover:bg-accent/5 transition-colors"
                            >
                                Yutuqlarni ko'rish
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </ProtectedRoute>
    );
}

"use client";

import { Settings, Save } from 'lucide-react';
import { useState } from 'react';

export default function SettingsPage() {
    const [isLoading, setIsLoading] = useState(false);
    const [settings, setSettings] = useState({
        maintenanceMode: false,
        allowRegistration: true,
        emailNotifications: true,
        autoApproveBooks: false
    });

    const handleSave = () => {
        setIsLoading(true);
        // Simulate API call
        setTimeout(() => {
            setIsLoading(false);
            alert('Sozlamalar saqlandi');
        }, 1000);
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-2">
                        <Settings className="w-8 h-8 text-primary" />
                        Sozlamalar
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Platforma konfiguratsiyasi
                    </p>
                </div>
                <button
                    onClick={handleSave}
                    disabled={isLoading}
                    className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2 rounded-lg font-medium hover:bg-primary/90 transition-colors disabled:opacity-50"
                >
                    <Save className="w-4 h-4" />
                    {isLoading ? 'Saqlanmoqda...' : 'Saqlash'}
                </button>
            </div>

            <div className="grid gap-6">
                {/* General Settings */}
                <div className="bg-card border border-border rounded-xl p-6">
                    <h2 className="text-xl font-bold mb-4">Umumiy Sozlamalar</h2>
                    <div className="space-y-4">
                        <div className="flex items-center justify-between p-4 rounded-lg bg-muted/30">
                            <div>
                                <h3 className="font-medium">Texnik Xizmat Rejimi</h3>
                                <p className="text-sm text-muted-foreground">
                                    Saytni vaqtincha yopish (faqat adminlar kira oladi)
                                </p>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                                <input
                                    type="checkbox"
                                    className="sr-only peer"
                                    checked={settings.maintenanceMode}
                                    onChange={(e) => setSettings({ ...settings, maintenanceMode: e.target.checked })}
                                />
                                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/30 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>

                        <div className="flex items-center justify-between p-4 rounded-lg bg-muted/30">
                            <div>
                                <h3 className="font-medium">Ro'yxatdan o'tish</h3>
                                <p className="text-sm text-muted-foreground">
                                    Yangi foydalanuvchilar ro'yxatdan o'tishiga ruxsat berish
                                </p>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                                <input
                                    type="checkbox"
                                    className="sr-only peer"
                                    checked={settings.allowRegistration}
                                    onChange={(e) => setSettings({ ...settings, allowRegistration: e.target.checked })}
                                />
                                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/30 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>
                    </div>
                </div>

                {/* Content Settings */}
                <div className="bg-card border border-border rounded-xl p-6">
                    <h2 className="text-xl font-bold mb-4">Kontent Sozlamalari</h2>
                    <div className="space-y-4">
                        <div className="flex items-center justify-between p-4 rounded-lg bg-muted/30">
                            <div>
                                <h3 className="font-medium">Avtomatik Tasdiqlash</h3>
                                <p className="text-sm text-muted-foreground">
                                    Yangi yuklangan kitoblarni avtomatik tasdiqlash
                                </p>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                                <input
                                    type="checkbox"
                                    className="sr-only peer"
                                    checked={settings.autoApproveBooks}
                                    onChange={(e) => setSettings({ ...settings, autoApproveBooks: e.target.checked })}
                                />
                                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/30 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

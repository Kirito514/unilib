"use client";

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import { Role, hasPermission, ROLES } from '@/lib/permissions';

interface User {
    id: string;
    name: string;
    email: string;
    university?: string;
    role: Role;
    avatar_url?: string;
}

interface AuthContextType {
    user: User | null;
    login: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
    register: (name: string, email: string, password: string, university?: string) => Promise<{ success: boolean; error?: string }>;
    logout: () => void;
    isLoading: boolean;
    hasPermission: (permission: Role) => boolean;
    isAdmin: () => boolean;
    isSuperAdmin: () => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const router = useRouter();

    // Check for existing session on mount
    useEffect(() => {
        checkUser();

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_OUT') {
                setUser(null);
                router.push('/login');
                router.refresh();
                return;
            }

            if (event === 'TOKEN_REFRESHED') {
                if (!session) {
                    setUser(null);
                    return;
                }
            }

            if (session?.user) {
                await setUserFromSupabase(session.user);
            } else {
                setUser(null);
            }
        });

        return () => subscription.unsubscribe();
    }, [router]);

    const checkUser = async () => {
        try {
            const { data: { session }, error } = await supabase.auth.getSession();

            // If there's an error (like invalid refresh token), clear the session
            if (error) {
                console.warn('Session error:', error.message);
                await supabase.auth.signOut();
                setUser(null);
                setIsLoading(false);
                return;
            }

            if (session?.user) {
                // Set loading false immediately to show UI faster
                setIsLoading(false);
                await setUserFromSupabase(session.user);
            } else {
                setIsLoading(false);
            }
        } catch (error) {
            console.error('Error checking user:', error);
            // Clear any invalid session
            await supabase.auth.signOut();
            setUser(null);
            setIsLoading(false);
        }
    };

    const setUserFromSupabase = async (supabaseUser: SupabaseUser) => {
        try {
            // Get user profile from profiles table
            const { data: profile, error } = await supabase
                .from('profiles')
                .select('name, university, role, avatar_url')
                .eq('id', supabaseUser.id)
                .maybeSingle(); // Use maybeSingle to avoid errors

            if (error) {
                console.error('Profile fetch error:', error);
            }

            setUser({
                id: supabaseUser.id,
                email: supabaseUser.email || '',
                name: profile?.name || supabaseUser.user_metadata?.name || 'User',
                university: profile?.university,
                role: (profile?.role as Role) || 'student',
                avatar_url: profile?.avatar_url,
            });
        } catch (error) {
            console.error('Error setting user:', error);
            // Set user with minimal data if profile fetch fails
            setUser({
                id: supabaseUser.id,
                email: supabaseUser.email || '',
                name: supabaseUser.user_metadata?.name || 'User',
                university: undefined,
                role: 'student',
                avatar_url: undefined,
            });
        }
    };

    const login = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
        try {
            const { data, error } = await supabase.auth.signInWithPassword({ email, password });
            if (error) {
                console.error('Login error:', error.message);
                return { success: false, error: error.message };
            }
            if (data.user) {
                // Let onAuthStateChange listener fetch profile and set user
                return { success: true };
            }
            return { success: false, error: 'Login failed' };
        } catch (err: any) {
            console.error('Login error:', err);
            return { success: false, error: err.message || 'An unexpected error occurred' };
        }
    };

    const register = async (name: string, email: string, password: string, university?: string): Promise<{ success: boolean; error?: string }> => {
        try {
            // Sign up the user with metadata
            const { data, error } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        name,
                        university
                    }
                }
            });

            if (error) {
                console.error('Registration error:', error.message);
                return { success: false, error: error.message };
            }

            if (data.user) {
                // Wait a bit for trigger to execute
                await new Promise(resolve => setTimeout(resolve, 500));

                // Check if profile was created by trigger
                const { data: existingProfile, error: checkError } = await supabase
                    .from('profiles')
                    .select('id')
                    .eq('id', data.user.id)
                    .maybeSingle(); // Use maybeSingle to avoid error if profile doesn't exist

                if (checkError) {
                    console.error('Error checking profile:', checkError);
                }

                // If trigger didn't create profile, create it manually
                if (!existingProfile) {
                    console.log('Trigger did not create profile, creating manually...');

                    // Try to get default organization (may not exist in fresh database)
                    const { data: defaultOrg } = await supabase
                        .from('organizations')
                        .select('id')
                        .eq('slug', 'unilib-platform')
                        .maybeSingle(); // Use maybeSingle to avoid error if not found

                    const organizationId = defaultOrg?.id || null;

                    // Create profile manually
                    const { error: profileError } = await supabase
                        .from('profiles')
                        .insert({
                            id: data.user.id,
                            email: data.user.email!,
                            name: name,
                            university: university,
                            organization_id: organizationId, // Can be null if org doesn't exist
                            role: ROLES.STUDENT,
                            xp: 0,
                            level: 1,
                            streak_days: 0,
                            total_pages_read: 0,
                            total_books_completed: 0,
                            is_active: true
                        });

                    if (profileError) {
                        console.error('Profile creation error:', profileError);
                        // If it's a foreign key constraint error, try without organization_id
                        if (profileError.code === '23503' || profileError.code === '23502') {
                            console.log('Retrying without organization_id...');
                            const { error: retryError } = await supabase
                                .from('profiles')
                                .insert({
                                    id: data.user.id,
                                    email: data.user.email!,
                                    name: name,
                                    university: university,
                                    organization_id: null,
                                    role: ROLES.STUDENT,
                                    xp: 0,
                                    level: 1,
                                    streak_days: 0,
                                    total_pages_read: 0,
                                    total_books_completed: 0,
                                    is_active: true
                                });

                            if (retryError) {
                                console.error('Retry profile creation error:', retryError);
                                return { success: false, error: 'Failed to create user profile. Please contact support.' };
                            }
                        } else {
                            return { success: false, error: 'Failed to create user profile. Please try again.' };
                        }
                    }
                }

                // Set the user state
                setUser({
                    id: data.user.id,
                    email: data.user.email!,
                    name: name,
                    university: university,
                    role: ROLES.STUDENT
                });

                return { success: true };
            }

            return { success: false, error: 'Registration failed' };
        } catch (error: any) {
            console.error('Registration error:', error);
            return { success: false, error: error.message || 'An unexpected error occurred' };
        }
    };

    const logout = async () => {
        try {
            // Sign out from Supabase
            await supabase.auth.signOut();

            // Clear all local storage
            if (typeof window !== 'undefined') {
                localStorage.clear();
                sessionStorage.clear();
            }
        } catch (error) {
            console.error('Error signing out:', error);
        } finally {
            setUser(null);

            // Force full page reload to clear all state
            if (typeof window !== 'undefined') {
                window.location.href = '/login';
            } else {
                router.push('/login');
                router.refresh();
            }
        }
    };

    const checkPermission = (requiredRole: Role): boolean => {
        if (!user) return false;
        return hasPermission(user.role, requiredRole);
    };

    const checkIsAdmin = (): boolean => {
        if (!user) return false;
        // Include admins, librarians, and head librarians
        return ([
            ROLES.SUPER_ADMIN,
            ROLES.SYSTEM_ADMIN,
            ROLES.ORG_ADMIN,
            ROLES.HEAD_LIBRARIAN,
            ROLES.LIBRARIAN
        ] as string[]).includes(user.role);
    };

    const checkIsSuperAdmin = (): boolean => {
        if (!user) return false;
        return user.role === ROLES.SUPER_ADMIN;
    };

    return (
        <AuthContext.Provider value={{
            user,
            login,
            register,
            logout,
            isLoading,
            hasPermission: checkPermission,
            isAdmin: checkIsAdmin,
            isSuperAdmin: checkIsSuperAdmin
        }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}

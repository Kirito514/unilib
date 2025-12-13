# Admin Panel Role-Based Access

## Maqsad

HEMIS orqali kirgan foydalanuvchilar ham admin role berilsa, admin panelga kira olishi.

## Yechim

### 1. AdminRoute Component Yangilandi

**Fayl:** `components/admin/AdminRoute.tsx`

**o'zgarishlar:**
- ✅ Permissions system ishlatiladi (`lib/permissions.ts`)
- ✅ `isAdmin()`, `isLibrarian()`, `canManageBooks()` funksiyalari
- ✅ Role-based access control

**Ruxsat berilgan rollar:**
- `super_admin` - Super Administrator
- `system_admin` - Tizim Administratori  
- `org_admin` - Tashkilot Administratori
- `head_librarian` - Bosh Kutubxonachi
- `librarian` - Kutubxonachi

### 2. Qanday Ishlaydi

1. **Login:** Foydalanuvchi email yoki HEMIS orqali kiradi
2. **Role Check:** `AdminRoute` component foydalanuvchi rolesini tekshiradi
3. **Access:** Agar admin/librarian bo'lsa - ruxsat beriladi
4. **Redirect:** Agar yo'q bo'lsa - dashboard ga yo'naltiriladi

### 3. HEMIS Foydalanuvchilar

HEMIS orqali kirgan foydalanuvchilar ham:
- ✅ Database da `profiles` jadvalida saqlanadi
- ✅ `role` ustuni orqali role beriladi
- ✅ Admin role berilsa, admin panelga kiradi

**Role o'zgartirish (SQL):**
```sql
-- HEMIS foydalanuvchiga admin role berish
UPDATE profiles 
SET role = 'librarian' 
WHERE email = 'hemis_user@example.com';

-- Yoki org_admin
UPDATE profiles 
SET role = 'org_admin' 
WHERE email = 'hemis_user@example.com';
```

### 4. Test Qilish

1. **HEMIS orqali kirish:**
   - Login page → "HEMIS orqali kirish"
   - HEMIS login va parol kiriting
   - Dashboard ochiladi

2. **Role berish:**
   - Supabase Dashboard → Table Editor → profiles
   - Foydalanuvchini toping
   - `role` ustunini `librarian` yoki `org_admin` ga o'zgartiring

3. **Admin panel:**
   - `/admin` ga o'ting
   - Agar role to'g'ri bo'lsa - admin panel ochiladi
   - Agar yo'q bo'lsa - "Ruxsat yo'q" xabari

## Permissions System

**Fayl:** `lib/permissions.ts`

**Funksiyalar:**
- `isAdmin(role)` - Admin ekanligini tekshiradi
- `isLibrarian(role)` - Kutubxonachi ekanligini tekshiradi
- `canManageBooks(role)` - Kitob boshqara oladimi
- `canManageUsers(role)` - Foydalanuvchi boshqara oladimi
- `hasPermission(userRole, requiredRole)` - Role hierarchy

**Role Hierarchy:**
```
8. super_admin (eng yuqori)
7. system_admin
6. org_admin
5. head_librarian
4. librarian / teacher
2. parent
1. student (eng past)
```

## Xavfsizlik

- ✅ Client-side va server-side tekshirish
- ✅ Role-based access control
- ✅ Redirect agar ruxsat yo'q bo'lsa
- ✅ Loading state

## Fayllar

1. ✅ `components/admin/AdminRoute.tsx` - Yangilandi
2. ✅ `components/auth/AdminRoute.tsx` - Yaratildi (backup)
3. ✅ `lib/permissions.ts` - Mavjud (ishlatildi)

---

**Status:** ✅ Tayyor
**Test:** Kerak - HEMIS user ga role bering va test qiling

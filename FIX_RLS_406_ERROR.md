# 🔧 RLS Muammosini Hal Qilish

## Muammo

Console da quyidagi xato ko'rinmoqda:
```
GET https://...supabase.co/rest/v1/profiles?... 406 (Not Acceptable)
```

Bu **Row Level Security (RLS)** muammosi - yangi foydalanuvchi o'z profilini o'qiy olmayapti.

## ✅ Yechim

### 1. Supabase SQL Editor da RLS ni To'g'rilash

1. [Supabase Dashboard](https://supabase.com/dashboard) ga kiring
2. Loyihangizni tanlang
3. **SQL Editor** ni oching
4. `supabase/fix_rls_for_registration.sql` faylini oching
5. Barcha kodni nusxalang va SQL Editor ga joylashtiring
6. **Run** tugmasini bosing

### 2. Kod O'zgarishlari (Allaqachon Qilindi)

AuthContext.tsx da:
- ✅ `.single()` → `.maybeSingle()` (406 xatosini oldini oladi)
- ✅ Error handling qo'shildi
- ✅ Retry logic mavjud

## 📋 Tekshirish

### SQL Editor da:

```sql
-- RLS policies ni ko'rish
SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename = 'profiles';

-- Natija:
-- "Users can view own profile" | authenticated | SELECT
-- "Users can insert own profile" | authenticated | INSERT
-- "Users can update own profile" | authenticated | UPDATE
```

### Permissions ni tekshirish:

```sql
-- Permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='profiles';
```

## 🧪 Qayta Test Qilish

1. **Eski foydalanuvchini o'chirish** (agar kerak bo'lsa):
   ```sql
   -- Supabase SQL Editor da
   DELETE FROM auth.users WHERE email = 'test@example.com';
   DELETE FROM profiles WHERE email = 'test@example.com';
   ```

2. **Brauzer cache ni tozalash**:
   - F12 → Application → Clear storage → Clear site data
   - Yoki Ctrl+Shift+Delete

3. **Qayta ro'yxatdan o'tish**:
   - http://localhost:3000/register
   - Yangi email bilan ro'yxatdan o'ting
   - Console da xatolar bo'lmasligi kerak

## 🎯 Kutilayotgan Natija

### ✅ Muvaffaqiyatli:

Console da:
```
Trigger did not create profile, creating manually...
Profile created successfully
```

Yoki:
```
Profile already exists (created by trigger)
```

Dashboard ga yo'naltiriladi, xato yo'q.

### ❌ Hali ham xato bo'lsa:

1. **RLS policies tekshiring**:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'profiles';
   ```

2. **Permissions tekshiring**:
   ```sql
   SELECT * FROM information_schema.role_table_grants 
   WHERE table_name='profiles';
   ```

3. **Manual profile yaratish**:
   ```sql
   -- Auth user ID ni oling
   SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 1;
   
   -- Profile yarating
   INSERT INTO profiles (id, email, name, role, organization_id)
   VALUES (
     'user-id-from-above',
     'test@example.com',
     'Test User',
     'student',
     (SELECT id FROM organizations WHERE slug = 'unilib-platform')
   );
   ```

## 🔍 Debug

### Console Logs:

Brauzerda F12 → Console:
- ✅ "Trigger did not create profile, creating manually..."
- ✅ "Profile created successfully"
- ❌ "406 Not Acceptable" → RLS muammosi
- ❌ "Profile creation error" → Database muammosi

### Network Tab:

F12 → Network → Filter: Fetch/XHR
- Profile SELECT request → 200 OK (muvaffaqiyatli)
- Profile SELECT request → 406 (RLS muammosi)

## 📝 Qo'shimcha

### Organization yaratish (agar yo'q bo'lsa):

```sql
INSERT INTO organizations (name, slug, type, subscription_tier, subscription_status, max_students, max_books)
VALUES (
    'UniLib Platform',
    'unilib-platform',
    'public_library',
    'enterprise',
    'active',
    999999,
    999999
)
ON CONFLICT (slug) DO NOTHING;
```

### Barcha migratsiyalarni ishlatish:

Agar hali ishlatmagan bo'lsangiz:
```
supabase/consolidated_migration.sql
```

---

## ✅ Keyingi Qadamlar

1. ✅ `fix_rls_for_registration.sql` ni ishlating
2. ✅ Brauzer cache ni tozalang
3. ✅ Qayta ro'yxatdan o'ting
4. ✅ Dashboard ochilishini tekshiring

**Hammasi ishlashi kerak!** 🚀

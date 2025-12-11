# ✅ Register Funksiyasi Test Qo'llanmasi

## O'zgarishlar

### AuthContext.tsx da qilingan yaxshilanishlar:

1. **Trigger tekshirish** - 500ms kutib, trigger profile yaratganini tekshiradi
2. **Manual profile yaratish** - Agar trigger ishlamasa, qo'lda yaratadi
3. **Organization handling** - Organization mavjud bo'lmasa ham ishlaydi
4. **Retry logic** - Agar xatolik bo'lsa, organization_id siz qayta urinadi
5. **Xato xabarlari** - Foydalanuvchiga tushunarli xato xabarlari

## Test Qilish

### 1. Development Server Ishga Tushirish

Server allaqachon ishlamoqda:
```
http://localhost:3000
```

### 2. Register Sahifasiga O'tish

Brauzerda quyidagi manzilga o'ting:
```
http://localhost:3000/register
```

### 3. Ro'yxatdan O'tish

Formani to'ldiring:
- **To'liq ism**: Test User
- **Email**: test@example.com
- **Universitet**: Toshkent Davlat Universiteti (ixtiyoriy)
- **Parol**: test123 (kamida 6 ta belgi)
- **Parolni tasdiqlang**: test123
- **Shartlarni qabul qilish**: ✓

"Ro'yxatdan o'tish" tugmasini bosing.

### 4. Kutilayotgan Natija

#### ✅ Muvaffaqiyatli:
1. Toast notification: "Muvaffaqiyatli! Hisobingiz yaratildi..."
2. Avtomatik dashboard ga yo'naltirish
3. Header da foydalanuvchi nomi ko'rinadi

#### ❌ Xatolik bo'lsa:
- Qizil xato xabari ko'rinadi
- Console da batafsil log (F12 → Console)

## Console Loglarni Ko'rish

Brauzerda F12 bosing va Console tabini oching. Quyidagi loglarni ko'rasiz:

### Trigger ishlasa:
```
Registration successful
```

### Trigger ishlamasa:
```
Trigger did not create profile, creating manually...
Profile creation successful (manual)
```

### Organization mavjud bo'lmasa:
```
Retrying without organization_id...
Profile creation successful (retry)
```

## Muammolarni Hal Qilish

### "Email already registered"
Bu email bilan allaqachon ro'yxatdan o'tilgan. Boshqa email ishlatib ko'ring.

### "Failed to create user profile"
1. Console da xato logini ko'ring
2. Supabase Dashboard → SQL Editor ga o'ting
3. `consolidated_migration.sql` ni ishlating
4. Qayta urinib ko'ring

### Profile yaratilmadi
1. Supabase Dashboard → Table Editor → profiles ga o'ting
2. Yangi profile yaratilganini tekshiring
3. Agar yo'q bo'lsa, qo'lda qo'shing:
   ```sql
   INSERT INTO profiles (id, email, name, role)
   VALUES (
     'user-id-from-auth-users',
     'test@example.com',
     'Test User',
     'student'
   );
   ```

## Database Tekshirish

### Supabase SQL Editor da:

```sql
-- Foydalanuvchilar ro'yxati
SELECT id, email, name, role, organization_id 
FROM profiles 
ORDER BY created_at DESC 
LIMIT 10;

-- Auth users
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- Organizations
SELECT id, name, slug 
FROM organizations;
```

## Keyingi Qadamlar

Ro'yxatdan o'tgandan keyin:

1. **Dashboard** - Asosiy sahifa
2. **Library** - Kitoblar ro'yxati
3. **Profile** - Profil sozlamalari
4. **Settings** - Sozlamalar

## Xususiyatlar

### ✅ Ishlaydi:
- Email/Password ro'yxatdan o'tish
- Profile avtomatik yaratish
- Organization bilan bog'lash
- Dashboard ga yo'naltirish
- Toast notifications

### 🔄 Fallback mexanizmlari:
- Trigger ishlamasa - manual yaratish
- Organization yo'q bo'lsa - null bilan yaratish
- Xatolik bo'lsa - retry logic

### 🛡️ Xavfsizlik:
- Password validation (min 6 chars)
- Email format validation
- Password strength indicator
- Terms agreement required

---

## Test Natijalari

Test qilgandan keyin quyidagilarni tekshiring:

- [ ] Ro'yxatdan o'tish muvaffaqiyatli
- [ ] Profile yaratildi (Supabase da)
- [ ] Dashboard ochildi
- [ ] Header da ism ko'rinmoqda
- [ ] Logout ishlayapti
- [ ] Qayta login qilish ishlayapti

---

**Eslatma:** Agar muammo bo'lsa, console loglarni va Supabase Dashboard ni tekshiring!

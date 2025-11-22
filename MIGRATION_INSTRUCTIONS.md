# Supabase Migration - Admin Panel Setup

## Migration faylini qo'llash

Supabase CLI local loyihaga ulanmaganligi sababli, migratsiyani qo'lda qo'llashimiz kerak.

### Usul 1: Supabase Dashboard (Tavsiya etiladi)

1. **Supabase Dashboard**ga kiring: https://supabase.com/dashboard
2. Loyihangizni tanlang
3. Chap menuda **SQL Editor** ni bosing
4. **New query** tugmasini bosing
5. Quyidagi faylning mazmunini nusxalang va joylashtiring:
   - `d:\unilib2\supabase\migrations\20250122_add_roles_and_admin_log.sql`
6. **Run** tugmasini bosing

### Usul 2: Supabase CLI orqali (Agar link qilmoqchi bo'lsangiz)

```bash
# Loyihani link qilish
supabase link --project-ref YOUR_PROJECT_REF

# Keyin migration qo'llash
supabase db push
```

**PROJECT_REF** ni topish:
- Supabase Dashboard > Settings > General > Reference ID

---

## Test qilish

Migration muvaffaqiyatli qo'llanganidan keyin:

### 1. Rolni o'zgartirish

Supabase Dashboard > Table Editor > `profiles` jadvalida:
- Bir foydalanuvchini tanlang
- `role` ustunini `SUPER_ADMIN` ga o'zgartiring

### 2. Admin panelga kirish

Brauzerda:
```
http://localhost:3000/admin
```

Agar role `USER` bo'lsa, dashboard ga yo'naltirilasiz.
Agar role admin bo'lsa, admin panel ochiladi!

---

## Qo'shimcha ma'lumot

Agar migration xatolik bersa, quyidagi buyruqni ishlatib ko'ring:

```sql
-- Avval role ustunini tekshirish
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'role';
```

Agar `role` ustuni allaqachon mavjud bo'lsa, migration faylidan `ALTER TABLE profiles ADD COLUMN` qatorini o'chirib tashlang.

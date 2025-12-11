# ✅ Account Deletion - To'g'rilandi

## Muammo

"Akkount o'chirilmoqda..." xabari ko'rinib, lekin hech narsa bo'lmayapti.

**Sabab:** Client-side da `supabase.auth.admin.deleteUser()` ishlamaydi - bu faqat server-side (service_role key) bilan ishlaydi.

## ✅ Yechim

### 1. API Endpoint Yaratildi

**Fayl:** `app/api/auth/delete-account/route.ts`

Bu endpoint:
- ✅ Service role key ishlatadi
- ✅ Profile ni o'chiradi
- ✅ Auth user ni o'chiradi
- ✅ Xatolarni to'g'ri handle qiladi

### 2. Settings Page Yangilandi

**Fayl:** `app/settings/page.tsx`

O'zgarishlar:
- ✅ API endpoint chaqiradi
- ✅ Client-side admin call o'chirildi
- ✅ Sign out va redirect to'g'rilandi

## 🧪 Test Qilish

### 1. Settings Sahifasiga O'tish

```
http://localhost:3000/settings
```

### 2. Account O'chirish

1. **"Akkauntni O'chirish"** tugmasini bosing
2. Tasdiqlash oynasi ochiladi
3. **"O'CHIRISH"** deb yozing (katta harflar bilan)
4. **"Akkauntni O'chirish"** tugmasini bosing

### 3. Kutilayotgan Natija

✅ **Muvaffaqiyatli:**
1. "Akkount o'chirilmoqda..." toast ko'rinadi
2. "Akkount o'chirildi. Xayr!" toast ko'rinadi
3. Login sahifasiga yo'naltiriladi
4. Eski email bilan login qilib bo'lmaydi

❌ **Xatolik bo'lsa:**
- Console da xato xabari (F12 → Console)
- Toast da xato xabari

## 🔍 Debug

### Console Logs

Brauzerda F12 → Console:
- ✅ "Account deleted successfully"
- ❌ "Delete error: ..." → API muammosi
- ❌ "Failed to delete account" → Server muammosi

### Network Tab

F12 → Network → Filter: Fetch/XHR:
- `POST /api/auth/delete-account` → 200 OK (muvaffaqiyatli)
- `POST /api/auth/delete-account` → 500 (server xatosi)

### Supabase Dashboard

1. **Auth Users:**
   ```
   Dashboard → Authentication → Users
   ```
   User ro'yxatdan o'chirilgan bo'lishi kerak

2. **Profiles Table:**
   ```
   Dashboard → Table Editor → profiles
   ```
   Profile o'chirilgan bo'lishi kerak

## 🛡️ Xavfsizlik

### Service Role Key

API endpoint `SUPABASE_SERVICE_ROLE_KEY` ishlatadi. Bu key:
- ✅ `.env.local` da saqlanadi
- ✅ Faqat server-side ishlatiladi
- ✅ Client-side ga expose qilinmaydi
- ✅ RLS policylarni bypass qiladi

### Tasdiqlash

Foydalanuvchi:
1. "O'CHIRISH" deb yozishi kerak (katta harflar)
2. Tugma disabled bo'ladi (agar to'g'ri yozmasa)
3. Ikki marta tasdiqlash kerak (modal + input)

## 📝 Qo'shimcha

### Agar Service Role Key Yo'q Bo'lsa

`.env.local` da qo'shing:
```env
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

**Service Role Key ni topish:**
1. Supabase Dashboard → Settings → API
2. "service_role" key ni nusxalang
3. `.env.local` ga joylashtiring
4. Serverni qayta ishga tushiring

### Cascade Delete

Profile o'chirilganda, quyidagilar ham o'chiriladi (database cascade):
- User achievements
- Reading schedule
- Daily progress
- Notifications
- Citations
- va boshqalar...

## ✅ Tayyor!

Endi account deletion to'liq ishlaydi:
- ✅ API endpoint (server-side)
- ✅ Service role key ishlatadi
- ✅ Profile va auth user o'chiriladi
- ✅ Xatolar to'g'ri handle qilinadi
- ✅ Foydalanuvchi login sahifasiga yo'naltiriladi

**Test qiling va natijani ayting!** 🚀

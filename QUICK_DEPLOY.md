# 🚀 Tezkor Deployment Qo'llanmasi

## 1️⃣ Docker Deployment (5 daqiqa)

### Boshlash

```bash
# 1. Environment faylini yaratish
cp env.production.template .env.production

# 2. .env.production ni tahrirlash (Supabase ma'lumotlarini kiriting)
nano .env.production

# 3. Docker build
docker build -t unilib2:latest .

# 4. Ishga tushirish
docker-compose up -d

# 5. Loglarni ko'rish
docker logs -f unilib2-app
```

### Tekshirish

```bash
# Container ishlayaptimi?
docker ps | grep unilib2

# Brauzerda ochish
http://localhost:3000
```

---

## 2️⃣ Database Migration (3 daqiqa)

### Variant 1: Consolidated Script (Tavsiya etiladi)

1. [Supabase Dashboard](https://supabase.com/dashboard) ga kiring
2. Loyihangizni tanlang
3. **SQL Editor** ni oching
4. `supabase/consolidated_migration.sql` faylini oching
5. Barcha kodni nusxalang va SQL Editor ga joylashtiring
6. **Run** tugmasini bosing
7. "Migration completed successfully!" xabarini kuting

### Variant 2: Supabase CLI

```bash
# Loyihani link qilish
supabase link --project-ref YOUR_PROJECT_REF

# Migratsiyalarni qo'llash
supabase db push
```

**PROJECT_REF:** Supabase Dashboard → Settings → General → Reference ID

---

## 3️⃣ Keng Uchraydigan Muammolar

### ❌ Docker build xatolik beradi

```bash
# node_modules ni tozalash
rm -rf node_modules package-lock.json
npm install

# Qayta build
docker build --no-cache -t unilib2:latest .
```

### ❌ Container ishga tushmayapti

```bash
# Loglarni tekshirish
docker logs unilib2-app

# .env.production ni tekshirish
cat .env.production

# Qayta ishga tushirish
docker-compose restart
```

### ❌ Migration xatolik beradi: "column already exists"

**Yechim:** Bu normal! Consolidated script mavjud ustunlarni tekshiradi va faqat yo'q bo'lganlarini qo'shadi.

### ❌ Migration xatolik beradi: "relation does not exist"

**Yechim:** 
1. Avval `supabase/schema.sql` ni ishlating
2. Keyin `supabase/consolidated_migration.sql` ni ishlating

### ❌ "Cannot connect to Supabase"

**Yechim:**
1. `.env.production` da URL va keys to'g'ri ekanligini tekshiring
2. Supabase Dashboard → Settings → API dan qayta nusxalang
3. Container ni qayta ishga tushiring: `docker-compose restart`

---

## 4️⃣ Production Checklist

### Deployment Oldidan

- [ ] `.env.production` to'ldirilgan
- [ ] Supabase loyihasi yaratilgan
- [ ] Docker server da o'rnatilgan

### Deployment

- [ ] `docker build` muvaffaqiyatli
- [ ] `docker-compose up -d` ishladi
- [ ] Container running: `docker ps`
- [ ] Logs xatosiz: `docker logs unilib2-app`

### Deployment Keyin

- [ ] Sayt ochilmoqda: `http://your-server:3000`
- [ ] Database migration bajarildi
- [ ] Ro'yxatdan o'tish ishlayapti
- [ ] Login ishlayapti

---

## 5️⃣ Foydali Buyruqlar

```bash
# Container statusini ko'rish
docker ps

# Loglarni real-time ko'rish
docker logs -f unilib2-app

# Container ichiga kirish
docker exec -it unilib2-app sh

# Container ni to'xtatish
docker-compose down

# Container ni qayta ishga tushirish
docker-compose restart

# Container va image ni o'chirish
docker-compose down
docker rmi unilib2:latest

# Qayta build va ishga tushirish
docker-compose down
docker build --no-cache -t unilib2:latest .
docker-compose up -d
```

---

## 6️⃣ Yordam

### Loglarni tekshirish

```bash
# Docker logs
docker logs --tail 100 unilib2-app

# Real-time logs
docker logs -f unilib2-app
```

### Database tekshirish

Supabase SQL Editor da:

```sql
-- Jadvallar ro'yxati
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Profiles jadvali ustunlari
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'profiles';
```

### Container ichida debugging

```bash
# Container ichiga kirish
docker exec -it unilib2-app sh

# Ichida:
ls -la                    # Fayllarni ko'rish
cat .env.production       # Environment variables
node -v                   # Node versiyasi
npm list                  # Packages
```

---

## 📞 Qo'shimcha Yordam

Agar muammo hal bo'lmasa:

1. **Loglarni saqlang:**
   ```bash
   docker logs unilib2-app > logs.txt
   ```

2. **GitHub Issues:** [github.com/Kirito514/unilib/issues](https://github.com/Kirito514/unilib/issues)

3. **Batafsil qo'llanma:** `DEPLOYMENT_GUIDE.md` faylini o'qing

---

## ✅ Muvaffaqiyatli Deployment!

Agar hammasi ishlayotgan bo'lsa:

- ✅ Container running
- ✅ Logs xatosiz
- ✅ Sayt ochilmoqda
- ✅ Database connected
- ✅ Login/Register ishlayapti

**🎉 Tabriklaymiz! UniLib2 tayyor!**

---

## 🔄 Yangilanishlar

Yangi kod deploy qilish:

```bash
# 1. Git pull
git pull origin main

# 2. Rebuild
docker-compose down
docker build --no-cache -t unilib2:latest .
docker-compose up -d

# 3. Loglarni tekshirish
docker logs -f unilib2-app
```

---

**Eslatma:** Agar pull request yuborgan bo'lsangiz, o'zgarishlaringizni tavsiflab yozing!

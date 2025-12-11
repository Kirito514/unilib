# 🚀 UniLib2 - Server Deployment Guide

Bu qo'llanma UniLib2 loyihasini serverga deploy qilish uchun to'liq ko'rsatma.

---

## 📋 Mundarija

1. [Docker Deployment](#docker-deployment)
2. [Database Migration](#database-migration)
3. [Troubleshooting](#troubleshooting)
4. [Production Checklist](#production-checklist)

---

## 🐳 Docker Deployment

### 1. Tayyorgarlik

#### Environment Variables Sozlash

```bash
# env.production.template dan nusxa oling
cp env.production.template .env.production

# .env.production ni tahrirlang
nano .env.production
```

**Kerakli o'zgaruvchilar:**

```env
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
NEXT_PUBLIC_APP_URL=https://your-domain.com
```

> **Muhim:** Supabase kalitlarini [Supabase Dashboard](https://supabase.com/dashboard) → Settings → API dan oling.

### 2. Docker Build

```bash
# Image yaratish
docker build -t unilib2:latest .

# Build jarayonini tekshirish
docker images | grep unilib2
```

**Build muammolari:**

Agar build xatolik bersa:
- `node_modules` va `.next` papkalarini o'chiring
- `npm install` ni qayta ishlating
- `package-lock.json` ni tekshiring

### 3. Docker Compose bilan Ishga Tushirish

```bash
# Container yaratish va ishga tushirish
docker-compose up -d

# Loglarni ko'rish
docker-compose logs -f app

# Container statusini tekshirish
docker-compose ps
```

### 4. Container Boshqaruvi

```bash
# To'xtatish
docker-compose down

# Qayta ishga tushirish
docker-compose restart

# Container ichiga kirish (debugging uchun)
docker exec -it unilib2-app sh

# Loglarni real-time ko'rish
docker logs -f unilib2-app
```

### 5. Health Check

Container ishga tushgandan keyin:

```bash
# Health endpoint tekshirish
curl http://localhost:3000/api/health

# Yoki brauzerda
http://your-server-ip:3000
```

---

## 🗄️ Database Migration

### Muammo: Migration Xatolari

Agar SQL migration xatolik bersa, quyidagi yechimlarni sinab ko'ring:

#### Yechim 1: Consolidated Migration Script

Barcha kerakli migratsiyalarni bitta faylda to'pladik. Foydalanish:

1. Supabase Dashboard ga kiring: https://supabase.com/dashboard
2. Loyihangizni tanlang
3. **SQL Editor** ni oching
4. `supabase/consolidated_migration.sql` faylini ishlating

#### Yechim 2: Bosqichma-bosqich Migration

Agar consolidated script ishlamasa, quyidagi tartibda migration qiling:

**1-bosqich: Asosiy jadvallar**
```bash
supabase/migrations/20251129_01_create_organizations.sql
supabase/migrations/20251129_02_update_profiles.sql
supabase/migrations/20251129_create_books_table.sql
```

**2-bosqich: Gamification**
```bash
supabase/migrations/20241123_gamification.sql
supabase/migrations/20241123_notifications.sql
supabase/migrations/20241123_notification_triggers.sql
```

**3-bosqich: RLS va Security**
```bash
supabase/migrations/20251129_03_secure_tables.sql
supabase/migrations/20251129_06_nuke_and_fix_rls.sql
supabase/migrations/20251210_complete_rls_fix.sql
```

**4-bosqich: Qo'shimcha funksiyalar**
```bash
supabase/migrations/20241123_leaderboard_functions.sql
supabase/migrations/20241123_reading_schedule.sql
supabase/migrations/20241123_streak_logic.sql
```

**5-bosqich: So'nggi yangilanishlar**
```bash
supabase/migrations/20251210_add_hemis_columns.sql
supabase/migrations/20251211_add_last_synced_at.sql
```

#### Yechim 3: Supabase CLI orqali

```bash
# Loyihani link qilish
supabase link --project-ref YOUR_PROJECT_REF

# Migratsiyalarni qo'llash
supabase db push

# Yoki bitta migration
supabase db execute -f supabase/migrations/filename.sql
```

**PROJECT_REF topish:**
- Supabase Dashboard → Settings → General → Reference ID

### Migration Tekshirish

Barcha jadvallar yaratilganini tekshirish:

```sql
-- Jadvallar ro'yxati
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Funksiyalar ro'yxati
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Profiles jadvali ustunlari
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
```

**Kutilayotgan jadvallar:**
- `profiles`
- `organizations`
- `books`
- `book_reviews`
- `offline_library_books`
- `study_groups`
- `group_members`
- `reading_schedule`
- `daily_progress`
- `achievements`
- `user_achievements`
- `notifications`
- `admin_logs`

---

## 🔧 Troubleshooting

### 1. Docker Build Xatolari

#### Xato: "npm ci failed"

**Yechim:**
```bash
# node_modules ni o'chirish
rm -rf node_modules package-lock.json

# Qayta o'rnatish
npm install

# Build qilish
docker build --no-cache -t unilib2:latest .
```

#### Xato: "COPY failed"

**Sabab:** Dockerfile path noto'g'ri

**Yechim:**
```bash
# .dockerignore ni tekshiring
cat .dockerignore

# Kerakli fayllar ignore qilinmaganini tekshiring
```

### 2. Container Ishga Tushmayapti

#### Loglarni tekshirish:

```bash
docker logs unilib2-app

# Yoki real-time
docker logs -f unilib2-app
```

#### Keng uchraydigan xatolar:

**"Cannot find module 'next'"**
```bash
# Dockerfile da dependencies to'g'ri copy qilinganini tekshiring
# Rebuild qiling
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**"ECONNREFUSED Supabase"**
```bash
# .env.production ni tekshiring
# Supabase URL va keys to'g'ri ekanligini tasdiqlang
docker-compose down
# .env.production ni tahrirlang
docker-compose up -d
```

### 3. Database Migration Xatolari

#### Xato: "column already exists"

**Yechim:**
```sql
-- Mavjud ustunni tekshirish
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'role';

-- Agar mavjud bo'lsa, migration dan o'sha qatorni o'chirib tashlang
```

#### Xato: "function does not exist"

**Yechim:**
```bash
# Leaderboard functions ni qayta ishlating
supabase/migrations/20241123_leaderboard_functions.sql
```

#### Xato: "relation does not exist"

**Sabab:** Jadval yaratilmagan

**Yechim:**
```bash
# Asosiy schema ni ishlating
supabase/schema.sql

# Keyin migratsiyalarni tartib bilan
```

### 4. Performance Muammolari

#### Sekin ishlayapti

**Yechim:**
```bash
# Resource limitlarni oshirish (docker-compose.yml)
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

#### Memory leak

**Yechim:**
```bash
# Container ni qayta ishga tushirish
docker-compose restart app

# Loglarni monitoring qilish
docker stats unilib2-app
```

---

## ✅ Production Checklist

### Pre-deployment

- [ ] `.env.production` to'liq to'ldirilgan
- [ ] Supabase loyihasi yaratilgan
- [ ] Database migratsiyalari ishlatilgan
- [ ] Storage buckets yaratilgan (`books`, `avatars`)
- [ ] Authentication sozlangan
- [ ] Docker installed on server

### Deployment

- [ ] Docker image build qilindi
- [ ] Container ishga tushdi
- [ ] Health check muvaffaqiyatli
- [ ] Logs xatosiz
- [ ] Database connection ishlayapti

### Post-deployment

- [ ] Ro'yxatdan o'tish ishlayapti
- [ ] Login ishlayapti
- [ ] Kitoblar ko'rinmoqda
- [ ] PDF o'qish ishlayapti
- [ ] Gamification ishlayapti
- [ ] Admin panel accessible (agar kerak bo'lsa)

### Security

- [ ] HTTPS sozlangan (production uchun)
- [ ] Environment variables xavfsiz saqlangan
- [ ] Supabase RLS yoqilgan
- [ ] CORS to'g'ri sozlangan
- [ ] Rate limiting sozlangan (agar kerak bo'lsa)

### Monitoring

- [ ] Logs monitoring setup
- [ ] Error tracking (Sentry, etc.)
- [ ] Performance monitoring
- [ ] Database backup sozlangan
- [ ] Uptime monitoring

---

## 🆘 Yordam

Muammo yuzaga kelsa:

1. **Loglarni tekshiring:**
   ```bash
   docker logs unilib2-app
   ```

2. **Container ichiga kiring:**
   ```bash
   docker exec -it unilib2-app sh
   # Ichida:
   ls -la
   cat .env.production
   ```

3. **Database connection tekshiring:**
   ```bash
   # Supabase Dashboard → SQL Editor
   SELECT version();
   ```

4. **GitHub Issues:** [github.com/Kirito514/unilib/issues](https://github.com/Kirito514/unilib/issues)

---

## 📝 Qo'shimcha Maslahatlar

### Nginx Reverse Proxy (Tavsiya etiladi)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### SSL/HTTPS (Let's Encrypt)

```bash
# Certbot o'rnatish
sudo apt install certbot python3-certbot-nginx

# SSL sertifikat olish
sudo certbot --nginx -d your-domain.com
```

### Backup Strategy

```bash
# Database backup
pg_dump -h db.supabase.co -U postgres -d postgres > backup.sql

# Docker volume backup
docker run --rm -v unilib2_data:/data -v $(pwd):/backup alpine tar czf /backup/data-backup.tar.gz /data
```

---

**🎉 Muvaffaqiyatli deployment!**

Agar qo'shimcha savol bo'lsa, GitHub Issues da yozing yoki pull request yuboring.

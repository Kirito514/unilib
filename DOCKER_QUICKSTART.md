# UniLib2 Docker Quick Start

## Tezkor Boshlash

### 1. Environment Sozlash
```bash
# Template nusxalash
copy env.docker-template .env

# .env ni tahrirlash va Supabase ma'lumotlarini kiriting
```

### 2. Docker Build
```bash
docker build -t unilib2:latest .
```

### 3. Ishga Tushirish
```bash
docker-compose up -d
```

### 4. Ochish
Brauzer: http://localhost:3000

## To'xtatish
```bash
docker-compose down
```

## Batafsil Ko'rsatma
DOCKER_DEPLOYMENT.md faylini o'qing.

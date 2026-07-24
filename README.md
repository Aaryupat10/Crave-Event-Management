# Evenza — Event & Lifestyle Management App
## Setup Guide

---

## Prerequisites
- Node.js v18+ → https://nodejs.org
- MySQL 8.0+ running locally
- Your schema already loaded in `event_lifestyle_db`

---

## Step 1 — Load the database

Open MySQL Workbench or terminal and run **in this order**:

```sql
-- 1. Your schema (already done)
source /path/to/event_lifestyle_mysql.sql

-- 2. Sample data (optional but recommended for testing)
source /path/to/eventapp/seed.sql
```

---

## Step 2 — Configure environment

Edit `.env` in this folder:

```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=YOUR_MYSQL_PASSWORD_HERE
DB_NAME=event_lifestyle_db
JWT_SECRET=change_this_to_any_long_random_string
PORT=5000
```

---

## Step 3 — Install dependencies & start

```bash
cd eventapp
npm install
npm start
```

You should see:
```
✅  Server running at http://localhost:5000
📦  DB: event_lifestyle_db @ localhost
```

Open **http://localhost:5000** in your browser.

---

## Demo Credentials (from seed.sql)

| Role      | Email                  | Password   |
|-----------|------------------------|------------|
| User      | demo@evenza.in         | demo1234   |
| Organiser | organiser@evenza.in    | demo1234   |

---

## API Endpoints Reference

| Method | Endpoint                        | Auth | Description              |
|--------|---------------------------------|------|--------------------------|
| POST   | /api/auth/register              | —    | Register new user        |
| POST   | /api/auth/login                 | —    | Login                    |
| GET    | /api/events                     | —    | List published events    |
| GET    | /api/events/:id                 | —    | Event detail + tiers     |
| POST   | /api/events                     | ✓    | Create event (organiser) |
| POST   | /api/events/:id/schedule        | ✓    | Add schedule             |
| POST   | /api/events/:id/tiers           | ✓    | Add ticket tier          |
| GET    | /api/categories                 | —    | List categories          |
| GET    | /api/venues                     | —    | List venues              |
| POST   | /api/bookings                   | ✓    | Create booking           |
| GET    | /api/bookings/my                | ✓    | My bookings              |
| POST   | /api/bookings/:id/cancel        | ✓    | Cancel booking           |
| POST   | /api/payments                   | ✓    | Record payment           |
| GET    | /api/wishlist                   | ✓    | Get wishlist             |
| POST   | /api/wishlist/:eventid          | ✓    | Add to wishlist          |
| DELETE | /api/wishlist/:eventid          | ✓    | Remove from wishlist     |
| POST   | /api/reviews                    | ✓    | Submit review            |
| POST   | /api/organisers/register        | ✓    | Register as organiser    |

Auth header format: `Authorization: Bearer <token>`

---

## Folder Structure

```
eventapp/
├── server.js          ← Express backend (all API routes)
├── package.json
├── .env               ← Your DB credentials (DO NOT commit)
├── seed.sql           ← Sample data
└── public/
    └── index.html     ← Complete SPA frontend
```

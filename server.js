require("dotenv").config();
const express = require("express");
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ─── DB POOL ────────────────────────────────────────────────
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "event_lifestyle_db",
  waitForConnections: true,
  connectionLimit: 10,
});

// ─── AUTH MIDDLEWARE ─────────────────────────────────────────
function auth(req, res, next) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ error: "No token provided" });
  const token = header.split(" ")[1];
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || "secret");
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

// ─── HELPER ──────────────────────────────────────────────────
const query = (sql, params) => pool.execute(sql, params);

// ════════════════════════════════════════════════════════════
// AUTH ROUTES
// ════════════════════════════════════════════════════════════

// POST /api/auth/register
app.post("/api/auth/register", async (req, res) => {
  try {
    const { firstname, lastname, email, phone, password, username } = req.body;
    if (!firstname || !lastname || !email || !password)
      return res.status(400).json({ error: "Required fields missing" });

    const [existing] = await query("SELECT userid FROM users WHERE email = ?", [email]);
    if (existing.length > 0)
      return res.status(409).json({ error: "Email already registered" });

    const hash = await bcrypt.hash(password, 10);
    const [result] = await query(
      "INSERT INTO users (firstname, lastname, email, phone, passwordhash, username) VALUES (?,?,?,?,?,?)",
      [firstname, lastname, email, phone || null, hash, username || null]
    );
    const userId = result.insertId;

    // auto-create wishlist
    await query("INSERT INTO wishlist (userid) VALUES (?)", [userId]);

    const token = jwt.sign(
      { userId, email, firstname, lastname },
      process.env.JWT_SECRET || "secret",
      { expiresIn: "7d" }
    );
    res.status(201).json({ token, user: { userId, firstname, lastname, email } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Registration failed", detail: err.message });
  }
});

// POST /api/auth/login
app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: "Email and password required" });

    const [rows] = await query(
      "SELECT userid, firstname, lastname, email, passwordhash FROM users WHERE email = ?",
      [email]
    );
    if (rows.length === 0)
      return res.status(401).json({ error: "Invalid credentials" });

    const user = rows[0];
    const match = await bcrypt.compare(password, user.passwordhash);
    if (!match)
      return res.status(401).json({ error: "Invalid credentials" });

    // log login
    await query("INSERT INTO login (userid) VALUES (?)", [user.userid]);

    const token = jwt.sign(
      { userId: user.userid, email: user.email, firstname: user.firstname, lastname: user.lastname },
      process.env.JWT_SECRET || "secret",
      { expiresIn: "7d" }
    );
    res.json({
      token,
      user: {
        userId: user.userid,
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed", detail: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// CATEGORIES
// ════════════════════════════════════════════════════════════

app.get("/api/categories", async (req, res) => {
  try {
    const [rows] = await query("SELECT * FROM categories ORDER BY name", []);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════

// GET /api/events  — with optional ?category=&search=&status=
app.get("/api/events", async (req, res) => {
  try {
    const { category, search, status } = req.query;
    let sql = `
      SELECT e.eventid, e.title, e.description, e.coverimageurl, e.isonline, e.status,
             e.createdat,
             c.name AS categoryname, c.iconurl AS categoryicon,
             o.companyname AS organizername, o.verifiedstatus,
             u.firstname, u.lastname,
             MIN(es.startdatetime) AS nextstart,
             MIN(tt.price) AS startingprice,
             v.name AS venuename, v.address AS venueaddress
      FROM event e
      LEFT JOIN categories c ON e.categoryid = c.categoryid
      LEFT JOIN organisers o ON e.organizerid = o.organizerid
      LEFT JOIN users u ON o.userid = u.userid
      LEFT JOIN event_schedule es ON e.eventid = es.eventid
      LEFT JOIN venue v ON es.venueid = v.venueid
      LEFT JOIN ticket_tier tt ON e.eventid = tt.eventid
      WHERE 1=1
    `;
    const params = [];

    if (status) { sql += " AND e.status = ?"; params.push(status); }
    else { sql += " AND e.status = 'published'"; }

    if (category) { sql += " AND e.categoryid = ?"; params.push(category); }
    if (search) {
      sql += " AND (e.title LIKE ? OR e.description LIKE ?)";
      params.push(`%${search}%`, `%${search}%`);
    }

    sql += " GROUP BY e.eventid, c.name, c.iconurl, o.companyname, o.verifiedstatus, u.firstname, u.lastname, v.name, v.address ORDER BY nextstart ASC";

    const [rows] = await query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/events/:id
app.get("/api/events/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await query(
      `SELECT e.*, c.name AS categoryname,
              o.companyname, o.verifiedstatus, o.bio AS orgbio,
              u.firstname, u.lastname, u.profilepictureurl
       FROM event e
       LEFT JOIN categories c ON e.categoryid = c.categoryid
       LEFT JOIN organisers o ON e.organizerid = o.organizerid
       LEFT JOIN users u ON o.userid = u.userid
       WHERE e.eventid = ?`,
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: "Event not found" });

    const event = rows[0];

    // schedules
    const [schedules] = await query(
      `SELECT es.*, v.name AS venuename, v.address, v.maxcapacity
       FROM event_schedule es
       LEFT JOIN venue v ON es.venueid = v.venueid
       WHERE es.eventid = ? ORDER BY es.startdatetime`,
      [id]
    );

    // tiers
    const [tiers] = await query(
      "SELECT * FROM ticket_tier WHERE eventid = ? ORDER BY price",
      [id]
    );

    // reviews
    const [reviews] = await query(
      `SELECT r.*, u.firstname, u.lastname, u.profilepictureurl
       FROM review r
       JOIN users u ON r.userid = u.userid
       WHERE r.eventid = ? ORDER BY r.createdat DESC`,
      [id]
    );

    // avg rating
    const [rating] = await query(
      "SELECT COUNT(*) AS total, ROUND(AVG(rating),1) AS avg FROM review WHERE eventid = ?",
      [id]
    );

    res.json({ ...event, schedules, tiers, reviews, rating: rating[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/events  (organiser only)
app.post("/api/events", auth, async (req, res) => {
  try {
    const { title, description, coverimageurl, isonline, categoryid, termsandconditions } = req.body;
    if (!title) return res.status(400).json({ error: "Title required" });

    const [org] = await query(
      "SELECT organizerid FROM organisers WHERE userid = ?",
      [req.user.userId]
    );
    if (org.length === 0)
      return res.status(403).json({ error: "Only organisers can create events" });

    const [result] = await query(
      `INSERT INTO event (organizerid, categoryid, title, description, coverimageurl, isonline, termsandconditions, status)
       VALUES (?,?,?,?,?,?,?,'published')`,
      [org[0].organizerid, categoryid || null, title, description || null,
       coverimageurl || null, isonline ? 1 : 0, termsandconditions || null]
    );
    res.status(201).json({ eventid: result.insertId, message: "Event created" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// BOOKINGS
// ════════════════════════════════════════════════════════════

// POST /api/bookings
app.post("/api/bookings", auth, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { scheduleid, tierid, quantity } = req.body;
    if (!scheduleid || !tierid || !quantity)
      return res.status(400).json({ error: "scheduleid, tierid, quantity required" });

    await conn.beginTransaction();

    // lock the schedule row
    const [schedRows] = await conn.execute(
      `SELECT es.currentcapacity, v.maxcapacity
       FROM event_schedule es
       LEFT JOIN venue v ON es.venueid = v.venueid
       WHERE es.scheduleid = ? FOR UPDATE`,
      [scheduleid]
    );
    if (schedRows.length === 0) throw new Error("Schedule not found");

    const { currentcapacity, maxcapacity } = schedRows[0];
    const available = (maxcapacity || 999999) - currentcapacity;
    if (available < quantity) {
      await conn.rollback();
      conn.release();
      return res.status(409).json({ error: `Only ${available} seats available` });
    }

    // get price
    const [tierRows] = await conn.execute(
      "SELECT price FROM ticket_tier WHERE tierid = ?",
      [tierid]
    );
    if (tierRows.length === 0) throw new Error("Tier not found");
    const total = (parseFloat(tierRows[0].price) * quantity).toFixed(2);

    // insert booking
    const [bookResult] = await conn.execute(
      `INSERT INTO bookings (userid, scheduleid, bookingstatus, totalamount)
       VALUES (?, ?, 'confirmed', ?)`,
      [req.user.userId, scheduleid, total]
    );
    const bookingId = bookResult.insertId;

    // insert tickets
    for (let i = 1; i <= quantity; i++) {
      const crypto = require("crypto");
      const qr = crypto
        .createHash("sha256")
        .update(`${bookingId}-${i}-${Date.now()}-${Math.random()}`)
        .digest("hex");
      await conn.execute(
        "INSERT INTO ticket (bookingid, tierid, qrcodehash) VALUES (?,?,?)",
        [bookingId, tierid, qr]
      );
    }

    // update capacity
    await conn.execute(
      "UPDATE event_schedule SET currentcapacity = currentcapacity + ? WHERE scheduleid = ?",
      [quantity, scheduleid]
    );

    await conn.commit();
    conn.release();
    res.status(201).json({ bookingid: bookingId, totalamount: total, message: "Booking confirmed" });
  } catch (err) {
    await conn.rollback();
    conn.release();
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/bookings/my  — logged-in user's bookings
app.get("/api/bookings/my", auth, async (req, res) => {
  try {
    const [rows] = await query(
      `SELECT b.bookingid, b.bookingstatus, b.totalamount, b.createdat,
              e.eventid, e.title AS eventtitle, e.coverimageurl,
              es.startdatetime, es.enddatetime,
              v.name AS venuename, v.address,
              COALESCE(p.paymentstatus, 'completed') AS paymentstatus,
              COALESCE(p.paymentmethod, 'Card') AS paymentmethod,
              GROUP_CONCAT(DISTINCT tt.tiername ORDER BY tt.price SEPARATOR ', ') AS tiernames
       FROM bookings b
       JOIN event_schedule es ON b.scheduleid = es.scheduleid
       JOIN event e ON es.eventid = e.eventid
       LEFT JOIN venue v ON es.venueid = v.venueid
       LEFT JOIN payments p ON b.bookingid = p.bookingid
       LEFT JOIN ticket t ON t.bookingid = b.bookingid
       LEFT JOIN ticket_tier tt ON t.tierid = tt.tierid
       WHERE b.userid = ?
       GROUP BY b.bookingid, b.bookingstatus, b.totalamount, b.createdat,
                e.eventid, e.title, e.coverimageurl,
                es.startdatetime, es.enddatetime,
                v.name, v.address, p.paymentstatus, p.paymentmethod
       ORDER BY b.createdat DESC`,
      [req.user.userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/bookings/:id/cancel
app.post("/api/bookings/:id/cancel", auth, async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await query(
      "SELECT scheduleid FROM bookings WHERE bookingid = ? AND userid = ? AND bookingstatus = 'confirmed'",
      [id, req.user.userId]
    );
    if (rows.length === 0)
      return res.status(404).json({ error: "Booking not found or not cancellable" });

    const scheduleId = rows[0].scheduleid;
    const [tickets] = await query("SELECT COUNT(*) AS cnt FROM ticket WHERE bookingid = ?", [id]);
    const cnt = tickets[0].cnt;

    await query("UPDATE bookings SET bookingstatus = 'cancelled' WHERE bookingid = ?", [id]);
    await query(
      "UPDATE event_schedule SET currentcapacity = GREATEST(0, currentcapacity - ?) WHERE scheduleid = ?",
      [cnt, scheduleId]
    );
    res.json({ message: "Booking cancelled" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// PAYMENTS
// ════════════════════════════════════════════════════════════

app.post("/api/payments", auth, async (req, res) => {
  try {
    const { bookingid, amount, paymentmethod } = req.body;
    if (!bookingid || !amount) return res.status(400).json({ error: "bookingid and amount required" });

    const txnid = `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
    await query(
      `INSERT INTO payments (bookingid, transactionid, amount, paymentmethod, paymentstatus)
       VALUES (?, ?, ?, ?, 'completed')`,
      [bookingid, txnid, amount, paymentmethod || "Card"]
    );
    res.status(201).json({ transactionid: txnid, status: "completed" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// WISHLIST
// ════════════════════════════════════════════════════════════

app.get("/api/wishlist", auth, async (req, res) => {
  try {
    const [wl] = await query("SELECT wishlistid FROM wishlist WHERE userid = ?", [req.user.userId]);
    if (wl.length === 0) return res.json([]);

    const [rows] = await query(
      `SELECT e.eventid, e.title, e.coverimageurl, e.isonline, e.status,
              MIN(es.startdatetime) AS nextstart,
              MIN(tt.price) AS startingprice,
              c.name AS categoryname,
              wi.addedat
       FROM wishlist_item wi
       JOIN event e ON wi.eventid = e.eventid
       LEFT JOIN categories c ON e.categoryid = c.categoryid
       LEFT JOIN event_schedule es ON e.eventid = es.eventid
       LEFT JOIN ticket_tier tt ON e.eventid = tt.eventid
       WHERE wi.wishlistid = ?
       GROUP BY e.eventid, e.title, e.coverimageurl, e.isonline, e.status, c.name, wi.addedat
       ORDER BY wi.addedat DESC`,
      [wl[0].wishlistid]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/wishlist/:eventid", auth, async (req, res) => {
  try {
    const [wl] = await query("SELECT wishlistid FROM wishlist WHERE userid = ?", [req.user.userId]);
    if (wl.length === 0) return res.status(404).json({ error: "Wishlist not found" });

    await query(
      "INSERT IGNORE INTO wishlist_item (wishlistid, eventid) VALUES (?, ?)",
      [wl[0].wishlistid, req.params.eventid]
    );
    res.json({ message: "Added to wishlist" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/wishlist/:eventid", auth, async (req, res) => {
  try {
    const [wl] = await query("SELECT wishlistid FROM wishlist WHERE userid = ?", [req.user.userId]);
    if (wl.length === 0) return res.status(404).json({ error: "Wishlist not found" });

    await query(
      "DELETE FROM wishlist_item WHERE wishlistid = ? AND eventid = ?",
      [wl[0].wishlistid, req.params.eventid]
    );
    res.json({ message: "Removed from wishlist" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// REVIEWS
// ════════════════════════════════════════════════════════════

app.post("/api/reviews", auth, async (req, res) => {
  try {
    const { eventid, rating, comment } = req.body;
    if (!eventid || !rating) return res.status(400).json({ error: "eventid and rating required" });
    if (rating < 1 || rating > 5) return res.status(400).json({ error: "Rating must be 1-5" });

    await query(
      "INSERT INTO review (userid, eventid, rating, comment) VALUES (?,?,?,?)",
      [req.user.userId, eventid, rating, comment || null]
    );
    res.status(201).json({ message: "Review submitted" });
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY")
      return res.status(409).json({ error: "You have already reviewed this event" });
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// ORGANISER ROUTES
// ════════════════════════════════════════════════════════════

// GET /api/organisers/my-events — returns all events for the logged-in organiser
app.get("/api/organisers/my-events", auth, async (req, res) => {
  try {
    const [org] = await query("SELECT organizerid FROM organisers WHERE userid = ?", [req.user.userId]);
    if (org.length === 0) return res.json([]);

    const [events] = await query(
      `SELECT e.eventid, e.title, e.coverimageurl, e.isonline, e.status,
              c.name AS categoryname,
              MIN(es.startdatetime) AS nextstart,
              MIN(tt.price) AS startingprice,
              v.name AS venuename,
              COUNT(DISTINCT tt.tierid) AS tiercount
       FROM event e
       LEFT JOIN categories c ON e.categoryid = c.categoryid
       LEFT JOIN event_schedule es ON e.eventid = es.eventid
       LEFT JOIN venue v ON es.venueid = v.venueid
       LEFT JOIN ticket_tier tt ON e.eventid = tt.eventid
       WHERE e.organizerid = ?
       GROUP BY e.eventid, e.title, e.coverimageurl, e.isonline, e.status, c.name, v.name
       ORDER BY e.createdat DESC`,
      [org[0].organizerid]
    );

    // attach tiers to each event
    for (const ev of events) {
      const [tiers] = await query("SELECT * FROM ticket_tier WHERE eventid = ? ORDER BY price", [ev.eventid]);
      ev.tiers = tiers;
    }

    res.json(events);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/events/:id — organiser deletes their own event
app.delete("/api/events/:id", auth, async (req, res) => {
  try {
    const [org] = await query("SELECT organizerid FROM organisers WHERE userid = ?", [req.user.userId]);
    if (org.length === 0) return res.status(403).json({ error: "Not an organiser" });

    const [ev] = await query("SELECT eventid FROM event WHERE eventid = ? AND organizerid = ?", [req.params.id, org[0].organizerid]);
    if (ev.length === 0) return res.status(404).json({ error: "Event not found or not yours" });

    await query("DELETE FROM event WHERE eventid = ?", [req.params.id]);
    res.json({ message: "Event deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/organisers/me — returns the logged-in user's organiser profile
app.get("/api/organisers/me", auth, async (req, res) => {
  try {
    const [rows] = await query(
      "SELECT organizerid, companyname, bio, verifiedstatus FROM organisers WHERE userid = ?",
      [req.user.userId]
    );
    if (rows.length === 0) return res.status(404).json({ error: "Not an organiser" });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/organisers/register", auth, async (req, res) => {
  try {
    const { bio, companyname, payoutdetails } = req.body;
    const [existing] = await query(
      "SELECT organizerid FROM organisers WHERE userid = ?",
      [req.user.userId]
    );
    if (existing.length > 0)
      return res.status(409).json({ error: "Already registered as organiser" });

    await query(
      "INSERT INTO organisers (userid, bio, companyname, payoutdetails) VALUES (?,?,?,?)",
      [req.user.userId, bio || null, companyname || null, payoutdetails || null]
    );
    res.status(201).json({ message: "Organiser profile created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/events/:id/schedule
app.post("/api/events/:id/schedule", auth, async (req, res) => {
  try {
    const { venueid, startdatetime, enddatetime } = req.body;
    if (!startdatetime || !enddatetime)
      return res.status(400).json({ error: "startdatetime and enddatetime required" });

    await query(
      "INSERT INTO event_schedule (eventid, venueid, startdatetime, enddatetime) VALUES (?,?,?,?)",
      [req.params.id, venueid || null, startdatetime, enddatetime]
    );
    res.status(201).json({ message: "Schedule added" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/events/:id/tiers
app.post("/api/events/:id/tiers", auth, async (req, res) => {
  try {
    const { tiername, description, price, maxavailable, startsalesdate, endsaledate } = req.body;
    if (!tiername || !price || !maxavailable)
      return res.status(400).json({ error: "tiername, price, maxavailable required" });

    await query(
      `INSERT INTO ticket_tier (eventid, tiername, description, price, maxavailable, startsalesdate, endsaledate)
       VALUES (?,?,?,?,?,?,?)`,
      [req.params.id, tiername, description || null, price, maxavailable,
       startsalesdate || null, endsaledate || null]
    );
    res.status(201).json({ message: "Ticket tier added" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/venues
app.get("/api/venues", async (req, res) => {
  try {
    const [rows] = await query("SELECT * FROM venue ORDER BY name", []);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// FLIGHTS
// ════════════════════════════════════════════════════════════

// GET /api/flights
app.get("/api/flights", async (req, res) => {
  try {
    const { from, to } = req.query;
    let sql = `
      SELECT f.*, fc.classid, fc.classname, fc.price, fc.seatsavailable
      FROM flight f
      LEFT JOIN flight_class fc ON f.flightid = fc.flightid
      WHERE 1=1
    `;
    const params = [];
    if (from) { sql += " AND LOWER(f.source) = LOWER(?)"; params.push(from); }
    if (to)   { sql += " AND LOWER(f.destination) = LOWER(?)"; params.push(to); }
    sql += " ORDER BY f.departure ASC";
    const [rows] = await query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/flights/book
app.post("/api/flights/book", auth, async (req, res) => {
  try {
    const { flightid, classid, quantity } = req.body;
    if (!flightid || !classid || !quantity)
      return res.status(400).json({ error: "flightid, classid, quantity required" });

    const [cls] = await query(
      "SELECT price, seatsavailable FROM flight_class WHERE classid = ? AND flightid = ?",
      [classid, flightid]
    );
    if (cls.length === 0) return res.status(404).json({ error: "Flight class not found" });
    if (cls[0].seatsavailable < quantity)
      return res.status(409).json({ error: "Not enough seats available" });

    const total = (parseFloat(cls[0].price) * quantity).toFixed(2);

    const [result] = await query(
      `INSERT INTO flight_booking (userid, flightid, classid, quantity, bookingstatus, totalamount)
       VALUES (?, ?, ?, ?, 'confirmed', ?)`,
      [req.user.userId, flightid, classid, quantity, total]
    );

    await query(
      "UPDATE flight_class SET seatsavailable = seatsavailable - ? WHERE classid = ?",
      [quantity, classid]
    );

    // auto-create payment record
    const txnid = `FLT-${Date.now()}-${Math.random().toString(36).substr(2,6).toUpperCase()}`;
    await query(
      `INSERT INTO flight_payment (flightbookingid, transactionid, amount, paymentmethod, paymentstatus)
       VALUES (?, ?, ?, 'Card', 'completed')`,
      [result.insertId, txnid, total]
    );

    res.status(201).json({ flightbookingid: result.insertId, totalamount: total, message: "Flight booked" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/flights/my
app.get("/api/flights/my", auth, async (req, res) => {
  try {
    const [rows] = await query(
      `SELECT fb.flightbookingid, fb.bookingstatus, fb.totalamount, fb.createdat,
              fb.quantity,
              f.airline, f.flightnumber, f.source, f.destination, f.departure, f.arrival,
              fc.classname,
              fp.paymentmethod, fp.paymentstatus
       FROM flight_booking fb
       JOIN flight f ON fb.flightid = f.flightid
       JOIN flight_class fc ON fb.classid = fc.classid
       LEFT JOIN flight_payment fp ON fb.flightbookingid = fp.flightbookingid
       WHERE fb.userid = ?
       ORDER BY fb.createdat DESC`,
      [req.user.userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── SERVE FRONTEND ─────────────────────────────────────────
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// ─── START ───────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`\n✅  Server running at http://localhost:${PORT}`);
  console.log(`📦  DB: ${process.env.DB_NAME} @ ${process.env.DB_HOST}\n`);
});

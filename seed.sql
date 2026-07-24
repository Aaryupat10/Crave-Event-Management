USE event_lifestyle_db;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE review;
TRUNCATE TABLE ticket_tier;
TRUNCATE TABLE event_schedule;
TRUNCATE TABLE event;
TRUNCATE TABLE organisers;
TRUNCATE TABLE wishlist;
TRUNCATE TABLE users;
TRUNCATE TABLE venue;
TRUNCATE TABLE categories;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO categories (name, description, iconurl) VALUES
('Music', 'Concerts, live gigs and festivals', NULL),
('Comedy', 'Stand-up comedy shows and tours', NULL),
('Tech', 'Conferences, AI and startup events', NULL),
('Food & Drink', 'Food festivals and experiences', NULL),
('Art', 'Art walks and exhibitions', NULL),
('Wellness', 'Yoga and fitness sessions', NULL);

INSERT INTO venue (name, address, maxcapacity) VALUES
('NSCI Dome', 'Worli, Mumbai - 400018', 5000),
('Jio World Convention Centre', 'BKC, Mumbai - 400051', 3000),
('NESCO Exhibition Centre', 'Goregaon East, Mumbai - 400063', 8000),
('The Habitat', 'Khar West, Mumbai - 400052', 150),
('St. Andrews Auditorium', 'Bandra West, Mumbai - 400050', 800),
('Mehboob Studios', 'Bandra West, Mumbai - 400050', 1200),
('Phoenix Palladium Courtyard', 'Lower Parel, Mumbai', 1000),
('Online / Virtual', 'Virtual', 9999);

INSERT INTO users (firstname, lastname, email, phone, passwordhash, username) VALUES
('Demo', 'User', 'demo@evenza.in', '9999999999',
'$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh.S',
'demouser');

INSERT INTO wishlist (userid) VALUES (1);

INSERT INTO users (firstname, lastname, email, phone, passwordhash, username) VALUES
('Arjun', 'Mehta', 'organiser@evenza.in', '8888888888',
'$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh.S',
'arjunmehta');

INSERT INTO wishlist (userid) VALUES (2);

INSERT INTO organisers (userid, bio, companyname, verifiedstatus) VALUES
(2, 'Top-tier Mumbai event curator hosting premium experiences.', 'Evenza Live Pvt Ltd', 1);

INSERT INTO event (organizerid, categoryid, title, description, coverimageurl, isonline, status) VALUES

(1, 1, 'Coldplay: Music of the Spheres World Tour - Mumbai',
 'Coldplay returns to Mumbai with a spectacular stadium-level show featuring lasers, fireworks and immersive visuals.',
 'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=1200',
 0, 'published'),

(1, 1, 'AP Dhillon Live India Tour - Mumbai',
 'Experience AP Dhillon performing Brown Munde and global hits live.',
 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
 0, 'published'),

(1, 2, 'Zakir Khan Live: Papa Yaar',
 'India’s most loved storyteller brings his iconic show to Mumbai.',
 'https://images.unsplash.com/photo-1527224538127-2104bb71c51b?w=1200',
 0, 'published'),

(1, 2, 'Samay Raina Unfiltered',
 'Dark humor, crowd work and chaos — a full Samay Raina experience.',
 'https://images.unsplash.com/photo-1515169067868-5387ec356754?w=1200',
 0, 'published'),

(1, 3, 'Mumbai AI & Web3 Summit 2026',
 'Top founders, developers and investors discuss the future of AI, blockchain and startups.',
 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=1200',
 0, 'published'),

(1, 4, 'Smaaash Food & Beer Festival',
 'Craft beer, gourmet food trucks and live music across 50+ stalls.',
 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200',
 0, 'published'),

(1, 5, 'Bandra Art & Graffiti Walk',
 'Discover hidden murals and street art culture in Bandra.',
 'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=1200',
 0, 'published'),

(1, 6, 'Sunrise Yoga by the Bay',
 'Morning yoga session with a sea view at Marine Drive.',
 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1200',
 0, 'published'),

(1, 1, 'Alan Walker Live Mumbai',
 'Global EDM sensation Alan Walker performs his biggest hits live.',
 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1200',
 0, 'published');

INSERT INTO event_schedule (eventid, venueid, startdatetime, enddatetime) VALUES
(1, 1, '2026-11-20 18:00:00', '2026-11-20 23:00:00'),
(2, 1, '2026-09-15 19:00:00', '2026-09-15 23:00:00'),
(3, 5, '2026-06-10 20:00:00', '2026-06-10 22:30:00'),
(4, 4, '2026-05-25 20:30:00', '2026-05-25 22:00:00'),
(5, 3, '2026-08-05 09:00:00', '2026-08-05 18:00:00'),
(6, 7, '2026-07-18 12:00:00', '2026-07-18 22:00:00'),
(7, 6, '2026-05-05 10:00:00', '2026-05-05 13:00:00'),
(8, 8, '2026-04-20 06:30:00', '2026-04-20 07:30:00'),
(9, 1, '2026-12-10 19:00:00', '2026-12-10 23:30:00');

INSERT INTO ticket_tier (eventid, tiername, description, price, maxavailable) VALUES
(1, 'General', 'Standing access', 2999, 3000),
(1, 'VIP', 'Premium seating + lounge', 8999, 500),
(2, 'General', 'Standing', 1999, 2000),
(2, 'Fan Pit', 'Near stage', 3999, 500),
(3, 'Regular', 'Standard seating', 799, 500),
(3, 'Front Row', 'Closest seats', 1499, 100),
(4, 'Entry', 'General entry', 499, 120),
(5, 'Standard', 'Full access pass', 1999, 1000),
(5, 'VIP', 'Networking + lounge', 4999, 200),
(6, 'Entry', 'Festival entry', 399, 1500),
(6, 'Food Pass', '₹1000 redeemable', 999, 800),
(7, 'Walk Ticket', 'Guided tour', 499, 100),
(8, 'Session Pass', 'Single session', 299, 300),
(9, 'General', 'Standing', 2499, 2500),
(9, 'VIP', 'Premium experience', 6999, 300);

INSERT INTO review (userid, eventid, rating, comment) VALUES
(1, 1, 5, 'Coldplay live was once in a lifetime experience!'),
(1, 3, 5, 'Zakir Khan storytelling is unmatched.'),
(1, 5, 4, 'Great networking and speakers.'),
(1, 6, 5, 'Amazing food and vibes.'),
(1, 9, 5, 'Alan Walker set was insane!');

INSERT INTO flight (airline, flightnumber, source, destination, departure, arrival, baseprice, totalcapacity) VALUES
('IndiGo', '6E-5123', 'Mumbai', 'Delhi', '2026-04-25 06:00:00', '2026-04-25 08:10:00', 4500, 180),
('Air India', 'AI-101', 'Mumbai', 'London', '2026-05-10 13:00:00', '2026-05-10 19:30:00', 55000, 250),
('Vistara', 'UK-955', 'Mumbai', 'Bangalore', '2026-04-28 09:30:00', '2026-04-28 11:15:00', 5200, 160),
('Emirates', 'EK-501', 'Mumbai', 'Dubai', '2026-05-02 04:00:00', '2026-05-02 05:45:00', 30000, 220);

INSERT INTO flight_class (flightid, classname, price, seatsavailable) VALUES

(1, 'Economy', 4500, 120),
(1, 'Business', 9000, 60),

(2, 'Economy', 55000, 180),
(2, 'Business', 120000, 70),

(3, 'Economy', 5200, 120),
(3, 'Business', 11000, 40),

(4, 'Economy', 30000, 150),
(4, 'Business', 75000, 70);

SELECT * FROM event;

-- Events by ccategory: comedy
SELECT * 
FROM event 
WHERE categoryid = (
    SELECT categoryid FROM categories WHERE name = 'Comedy'
);

-- Events in Mumbai
SELECT e.title, v.name AS venue
FROM event e
JOIN event_schedule s ON e.eventid = s.eventid
JOIN venue v ON s.venueid = v.venueid;

-- Select event by keyword
SELECT * 
FROM event 
WHERE title LIKE '%live%' OR description LIKE '%live%';

-- Upcoming Events
SELECT e.title, s.startdatetime
FROM event e
JOIN event_schedule s ON e.eventid = s.eventid
WHERE s.startdatetime > NOW()
ORDER BY s.startdatetime;

-- Event and Organizer
SELECT e.title, o.companyname
FROM event e
JOIN organisers o ON e.organizerid = o.organizerid;

-- Which user booked which event and how much they paid
SELECT u.firstname, e.title, b.totalamount
FROM bookings b
JOIN users u ON b.userid = u.userid
JOIN event_schedule s ON b.scheduleid = s.scheduleid
JOIN event e ON s.eventid = e.eventid;

-- Total revenue per event
SELECT e.title, SUM(b.totalamount) AS revenue
FROM bookings b
JOIN event_schedule s ON b.scheduleid = s.scheduleid
JOIN event e ON s.eventid = e.eventid
GROUP BY e.eventid;

-- Avg. rating per event
SELECT e.title, AVG(r.rating) AS avg_rating
FROM review r
JOIN event e ON r.eventid = e.eventid
GROUP BY e.eventid;

-- Most popular events
SELECT e.title, COUNT(b.bookingid) AS total_bookings
FROM bookings b
JOIN event_schedule s ON b.scheduleid = s.scheduleid
JOIN event e ON s.eventid = e.eventid
GROUP BY e.eventid
ORDER BY total_bookings DESC;

USE event_lifestyle_db;

-- Event 1: Mumbai Indians Preseason Camp (Sports = category 7, but we only have 6 categories, so use closest = 1 Music or add Sports)
-- First, add Sports category since your seed only has 6
INSERT INTO categories (name, description) VALUES ('Sports', 'Sports and fitness events');

-- Event 1: Mumbai Indians Preseason Camp
INSERT INTO event (organizerid, categoryid, title, description, isonline, status)
VALUES (2, 7, 'Mumbai Indians Preseason Camp', 'Watch your favorite players play before the start of the season.', 0, 'published');
INSERT INTO event_schedule (eventid, startdatetime, enddatetime) VALUES (LAST_INSERT_ID(), '2026-05-01 09:00:00', '2026-05-01 18:00:00');
INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (LAST_INSERT_ID(), 'General', 999, 100);


-- Verify all events
SELECT eventid, title, status, createdat FROM event ORDER BY eventid;


DELETE FROM ticket_tier WHERE eventid = 11;
INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES
(11, 'General Access', 2000, 20000),
(11, 'VIP', 5000, 10000),
(11, 'Lounge Access', 10000, 9999),
(11, 'Executive Lounge', 20000, 1500),
(11, 'Dugout Pass', 50000, 500);

USE event_lifestyle_db;

DROP PROCEDURE IF EXISTS insert_events;

DELIMITER $$

CREATE PROCEDURE insert_events()
BEGIN
  DECLARE v_vikhyat INT;
  DECLARE v_aaryesh INT;
  DECLARE v_lakshya INT;

  -- Vikhyat
  INSERT INTO event (organizerid, categoryid, title, description, isonline, status)
  VALUES (2, 5, 'Meet and Greet with manga writer Vikhyat', 'Hear insights from your not so favorite manga writer Vikhyat', 0, 'published');
  SET v_vikhyat = LAST_INSERT_ID();
  INSERT INTO event_schedule (eventid, startdatetime, enddatetime) VALUES (v_vikhyat, '2026-05-10 17:00:00', '2026-05-10 20:00:00');
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_vikhyat, 'General', 1000, 300);
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_vikhyat, 'VIP', 2000, 193);

  -- Aaryesh
  INSERT INTO event (organizerid, categoryid, title, description, isonline, status)
  VALUES (2, 5, 'Meet & Greet with Great Film Director Aaryesh', 'Aaryesh will meet his few fans over the world and give insights on the current state of filmmaking.', 0, 'published');
  SET v_aaryesh = LAST_INSERT_ID();
  INSERT INTO event_schedule (eventid, startdatetime, enddatetime) VALUES (v_aaryesh, '2026-05-15 18:00:00', '2026-05-15 21:00:00');
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_aaryesh, 'General', 1000, 300);
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_aaryesh, 'VIP', 2000, 200);

  -- Lakshya
  INSERT INTO event (organizerid, categoryid, title, description, isonline, status)
  VALUES (2, 5, 'Insights from Lakshya', 'Listen from the great wedding planner Lakshya Somani about his experiences in the wedding industry.', 0, 'published');
  SET v_lakshya = LAST_INSERT_ID();
  INSERT INTO event_schedule (eventid, startdatetime, enddatetime) VALUES (v_lakshya, '2026-05-20 17:00:00', '2026-05-20 19:00:00');
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_lakshya, 'General', 1000, 300);
  INSERT INTO ticket_tier (eventid, tiername, price, maxavailable) VALUES (v_lakshya, 'VIP', 2000, 200);

END$$

DELIMITER ;

CALL insert_events();
DROP PROCEDURE IF EXISTS insert_events;

-- Verify
SELECT e.eventid, e.title, tt.tiername, tt.price, tt.maxavailable
FROM event e
JOIN ticket_tier tt ON e.eventid = tt.eventid
WHERE e.eventid >= 11
ORDER BY e.eventid, tt.price;

SELECT u.userid, u.email, o.organizerid 
FROM users u 
LEFT JOIN organisers o ON u.userid = o.userid
WHERE u.email IN ('aaryupat@gmail.com', 'janedoe@gmail.com', 'vikhyat@gmail.com');

INSERT INTO organisers (userid, bio, companyname, verifiedstatus)
SELECT userid, 'Event Creator', 'My Organisation', 1
FROM users 
WHERE email IN ('aaryupat@gmail.com', 'janedoe@gmail.com', 'vikhyat@gmail.com')
AND userid NOT IN (SELECT userid FROM organisers);

SELECT eventid, title FROM event ORDER BY eventid;


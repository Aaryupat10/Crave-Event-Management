USE event_lifestyle_db;

-- Insert a new event
insert into event (organizerid, categoryid, title, description, isonline, status)
values (1, 1, 'Nucleya Live Mumbai',
        'Bass-heavy EDM headliner at NSCI Dome.',
        0, 'published');
        
-- Update — mark an event as completed
update event
set   status = 'completed'
where  eventid = 8;

-- Delete — remove all cancelled bookings for a user
delete from bookings
where  bookingstatus = 'cancelled'
  and  userid = 1;
  
-- Select all published events (ORDER BY)
select eventid, title, status, createdat
from   event
where  status = 'published'
order by createdat desc;

-- DISTINCT — Unique ticket tier names across all events
select distinct tiername
from   ticket_tier
order by tiername;

-- LIKE — Keyword search in event title or description
select eventid, title, description
from   event
where  title like '%live%'
   or  description like '%live%';
   
-- BETWEEN — Ticket tiers in a price range
select tiername, price, maxavailable
from   ticket_tier
where  price between 500 and 5000
order by price;

-- IN — Events belonging to specific categories
select e.title, c.name as category
from   event e
join   categories c on e.categoryid = c.categoryid
where  c.name in ('Music', 'Comedy', 'Tech')
order by c.name, e.title;

-- Logical Operators (AND / OR / NOT) — Filter events
select title, isonline, status
from   event
where  status = 'published'
  and  not isonline = 1;
  
-- COUNT — Total number of published events
select count(*) as total_published_events
from   event
where  status = 'published';

-- SUM & AVG — Total and average ticket price per event
select e.title,
       sum(tt.price * tt.maxavailable) as total_ticket_value,
       avg(tt.price)                   as avg_ticket_price
from   ticket_tier tt
join   event e on tt.eventid = e.eventid
group by e.eventid, e.title
order by avg_ticket_price desc;

-- MIN & MAX — Cheapest and most expensive ticket per event
select e.title,
       min(tt.price) as cheapest_ticket,
       max(tt.price) as most_expensive_ticket
from   ticket_tier tt
join   event e on tt.eventid = e.eventid
group by e.eventid, e.title;

-- GROUP BY — Event count per category
select c.name as category,
       count(e.eventid) as total_events
from   categories c
left join event e on c.categoryid = e.categoryid
group by c.categoryid, c.name
order by total_events desc;

-- HAVING — Events with average rating above 4
select e.title,
       avg(r.rating)    as avg_rating,
       count(r.reviewid) as total_reviews
from   review r
join   event e on r.eventid = e.eventid
group by e.eventid, e.title
having avg(r.rating) > 4
order by avg_rating desc;

-- GROUP BY + HAVING — Venues hosting more than one event
select v.name as venue,
       count(s.scheduleid) as scheduled_events
from   event_schedule s
join   venue v on s.venueid = v.venueid
group by v.venueid, v.name
having count(s.scheduleid) > 1
order by scheduled_events desc;

-- INNER JOIN — Events with venue and schedule details
select e.title,
       v.name        as venue,
       s.startdatetime,
       s.enddatetime
from   event e
inner join event_schedule s on e.eventid  = s.eventid
inner join venue v          on s.venueid  = v.venueid
where  e.status = 'published'
order by s.startdatetime;

-- LEFT OUTER JOIN — All categories including those with no events
select c.name as category,
       e.title as event_title
from   categories c
left outer join event e on c.categoryid = e.categoryid
order by c.name, e.title;

-- RIGHT OUTER JOIN — All venues including those with no bookings
select e.title         as event_title,
       v.name          as venue,
       v.maxcapacity
from   event_schedule s
right outer join venue v on s.venueid = v.venueid
left  join event e       on s.eventid = e.eventid
order by v.name;

-- Three-table JOIN — Booking details (user + event + amount)
select u.firstname, u.lastname,
       e.title          as event_name,
       b.totalamount,
       b.bookingstatus
from   bookings b
join   users u          on b.userid    = u.userid
join   event_schedule s on b.scheduleid = s.scheduleid
join   event e          on s.eventid   = e.eventid
order by b.createdat desc;

-- Subquery — Events in the Comedy category
select title, description
from   event
where  categoryid = (
    select categoryid
    from   categories
    where  name = 'Comedy'
);

-- Subquery with IN — Users who have NOT made any booking
select userid, firstname, lastname, email
from   users
where  userid not in (
    select distinct userid from bookings
);

-- Subquery — Ticket tiers above the average price
select tt.tiername, tt.price, e.title as event_name
from   ticket_tier tt
join   event e on tt.eventid = e.eventid
where  tt.price > (
    select avg(price) from ticket_tier
)
order by tt.price desc;

-- UNION — Combine usernames from users and organiser company names
select username as name, 'User' as type
from   users
union
select companyname as name, 'Organiser' as type
from   organisers
where  companyname is not null
order by name;

-- UNION ALL — All event titles from both Music and Comedy categories
select title from event
where categoryid = (select categoryid from categories where name = 'Music')
union all
select title from event
where categoryid = (select categoryid from categories where name = 'Comedy');

-- INTERSECT — Users who have both a booking and a review
SELECT userid 
FROM bookings 
WHERE userid IN (SELECT userid FROM review);

-- Query the upcoming events view
select *
from   vw_upcoming_events
order by startdatetime;

-- Create a view for organiser revenue summary
create view vw_organiser_revenue as
    select o.organizerid,
           o.companyname,
           count(b.bookingid)     as total_bookings,
           sum(b.totalamount)     as total_revenue
    from   organisers o
    join   event e          on o.organizerid = e.organizerid
    join   event_schedule s on e.eventid     = s.eventid
    join   bookings b       on s.scheduleid  = b.scheduleid
    where  b.bookingstatus in ('confirmed', 'attended')
    group by o.organizerid, o.companyname;


-- Drop a view
drop view vw_organiser_revenue;

















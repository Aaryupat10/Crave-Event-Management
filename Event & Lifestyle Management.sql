create database if not exists event_lifestyle_db
    character set utf8mb4
    collate utf8mb4_unicode_ci;

use event_lifestyle_db;

create table users (
    userid int not null auto_increment,
    firstname varchar(100) not null,
    lastname varchar(100) not null,
    email varchar(255) not null,
    phone varchar(20) default null,
    passwordhash varchar(255) not null,
    username varchar(50) unique,
    profilepictureurl varchar(500) default null,
    createdat datetime not null default current_timestamp,
    primary key (userid),
    unique key uq_users_email (email)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table organisers (
    organizerid int not null auto_increment,
    userid int not null,
    bio text default null,
    companyname varchar(255) default null,
    payoutdetails text default null,
    verifiedstatus tinyint(1) not null default 0,
    createdat datetime not null default current_timestamp,
    primary key (organizerid),
    unique key uq_organisers_user (userid),
    constraint fk_organiser_user
        foreign key (userid) references users (userid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table login (
    loginid int not null auto_increment,
    userid int not null,
    logintime datetime not null default current_timestamp,
    ipaddress varchar(45) default null,
    primary key (loginid),
    key idx_login_user (userid),
    constraint fk_login_user
        foreign key (userid) references users (userid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table categories (
    category_id int not null auto_increment,
    name varchar(100) not null,
    description text default null,
    iconurl varchar(500) default null,
    primary key (categoryid)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table venue (
    venueid int not null auto_increment,
    name varchar(255) not null,
    address varchar(500) not null,
    maxcapacity int not null,
    primary key (venueid)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table event (
    eventid int not null auto_increment,
    organizerid int not null,
    categoryid int default null,
    title varchar(255) not null,
    description text default null,
    coverimageurl varchar(500) default null,
    isonline tinyint(1) not null default 0,
    status enum('draft','published','cancelled','completed') not null default 'draft',
    termsandconditions text default null,
    createdat datetime not null default current_timestamp,
    primary key (eventid),
    key idx_event_organiser (organizerid),
    key idx_event_category (categoryid),
    key idx_event_status (status),
    constraint fk_event_organiser
        foreign key (organizerid) references organisers (organizerid)
        on delete restrict on update cascade,
    constraint fk_event_category
        foreign key (categoryid) references categories (categoryid)
        on delete set null on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table event_schedule (
    scheduleid int not null auto_increment,
    eventid int not null,
    venueid int default null,
    startdatetime datetime not null,
    enddatetime datetime not null,
    currentcapacity int not null default 0,
    primary key (scheduleid),
    key idx_schedule_event (eventid),
    key idx_schedule_venue (venueid),
    constraint fk_schedule_event
        foreign key (eventid) references event (eventid)
        on delete cascade on update cascade,
    constraint fk_schedule_venue
        foreign key (venueid) references venue (venueid)
        on delete set null on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table ticket_tier (
    tierid int not null auto_increment,
    eventid int not null,
    tiername varchar(100) not null,
    description text default null,
    price decimal(10,2) not null,
    maxavailable int not null,
    startsalesdate date default null,
    endsaledate date default null,
    primary key (tierid),
    key idx_tier_event (eventid),
    constraint fk_tier_event
        foreign key (eventid) references event (eventid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table bookings (
    bookingid int not null auto_increment,
    userid int not null,
    scheduleid int not null,
    bookingstatus enum('pending','confirmed','cancelled','attended') not null default 'pending',
    totalamount decimal(10,2) not null,
    createdat datetime not null default current_timestamp,
    primary key (bookingid),
    key idx_booking_user (userid),
    key idx_booking_schedule (scheduleid),
    constraint fk_booking_user
        foreign key (userid) references users (userid)
        on delete restrict on update cascade,
    constraint fk_booking_schedule
        foreign key (scheduleid) references event_schedule (scheduleid)
        on delete restrict on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table payments (
    paymentid int not null auto_increment,
    bookingid int not null,
    transactionid varchar(255) default null,
    amount decimal(10,2) not null,
    paymentmethod varchar(50) default null,
    paymentstatus enum('pending','completed','failed','refunded') not null default 'pending',
    timestamp datetime not null default current_timestamp,
    primary key (paymentid),
    unique key uq_payment_txn (transactionid),
    key idx_payment_booking (bookingid),
    constraint fk_payment_booking
        foreign key (bookingid) references bookings (bookingid)
        on delete restrict on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table ticket (
    ticketid int not null auto_increment,
    bookingid int not null,
    tierid int not null,
    qrcodehash varchar(500) default null,
    checkinstatus tinyint(1) not null default 0,
    primary key (ticketid),
    unique key uq_ticket_qr (qrcodehash),
    key idx_ticket_booking (bookingid),
    key idx_ticket_tier (tierid),
    constraint fk_ticket_booking
        foreign key (bookingid) references bookings (bookingid)
        on delete cascade on update cascade,
    constraint fk_ticket_tier
        foreign key (tierid) references ticket_tier (tierid)
        on delete restrict on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table wishlist (
    wishlistid int not null auto_increment,
    userid int not null,
    primary key (wishlistid),
    unique key uq_wishlist_user (userid),
    constraint fk_wishlist_user
        foreign key (userid) references users (userid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table wishlist_item (
    wishlistid int not null,
    eventid int not null,
    addedat datetime not null default current_timestamp,
    primary key (wishlistid, eventid),
    key idx_wli_event (eventid),
    constraint fk_wli_wishlist
        foreign key (wishlistid) references wishlist (wishlistid)
        on delete cascade on update cascade,
    constraint fk_wli_event
        foreign key (eventid) references event (eventid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

create table review (
    reviewid int not null auto_increment,
    userid int not null,
    eventid int not null,
    rating tinyint not null,
    comment text default null,
    createdat datetime not null default current_timestamp,
    primary key (reviewid),
    unique key uq_review_user_event (userid, eventid),
    key idx_review_event (eventid),
    constraint chk_rating check (rating between 1 and 5),
    constraint fk_review_user
        foreign key (userid) references users (userid)
        on delete cascade on update cascade,
    constraint fk_review_event
        foreign key (eventid) references event (eventid)
        on delete cascade on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

CREATE TABLE flight (
    flightid INT NOT NULL AUTO_INCREMENT,
    airline VARCHAR(100) NOT NULL,
    flightnumber VARCHAR(20) NOT NULL,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    departure DATETIME NOT NULL,
    arrival DATETIME NOT NULL,
    baseprice DECIMAL(10,2) NOT NULL,
    totalcapacity INT NOT NULL,
    createdat DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (flightid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE flight_class (
    classid INT NOT NULL AUTO_INCREMENT,
    flightid INT NOT NULL,
    classname VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    seatsavailable INT NOT NULL,
    PRIMARY KEY (classid),
    KEY idx_class_flight (flightid),
    CONSTRAINT fk_class_flight
        FOREIGN KEY (flightid) REFERENCES flight (flightid)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE flight_booking (
    flightbookingid INT NOT NULL AUTO_INCREMENT,
    userid INT NOT NULL,
    flightid INT NOT NULL,
    classid INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    bookingstatus ENUM('pending','confirmed','cancelled') DEFAULT 'pending',
    totalamount DECIMAL(10,2) NOT NULL,
    createdat DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (flightbookingid),

    KEY idx_fb_user (userid),
    KEY idx_fb_flight (flightid),

    CONSTRAINT fk_fb_user
        FOREIGN KEY (userid) REFERENCES users(userid)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_fb_flight
        FOREIGN KEY (flightid) REFERENCES flight(flightid)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_fb_class
        FOREIGN KEY (classid) REFERENCES flight_class(classid)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE flight_payment (
    paymentid INT NOT NULL AUTO_INCREMENT,
    flightbookingid INT NOT NULL,
    transactionid VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    paymentmethod VARCHAR(50),
    paymentstatus ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (paymentid),

    CONSTRAINT fk_fp_booking
        FOREIGN KEY (flightbookingid) REFERENCES flight_booking(flightbookingid)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



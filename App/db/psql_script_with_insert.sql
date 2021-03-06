DROP TABLE IF EXISTS Promotion CASCADE;
DROP TABLE IF EXISTS FDSpromo CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Restpromo CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Food CASCADE;
DROP TABLE IF EXISTS PaymentOption CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS FromMenu CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS FDSManagers CASCADE;
DROP TABLE IF EXISTS RestaurantStaff CASCADE;
DROP TABLE IF EXISTS Place CASCADE;
DROP TABLE IF EXISTS DeliveryRiders CASCADE;
DROP TABLE IF EXISTS PartTime CASCADE;
DROP TABLE IF EXISTS FullTime CASCADE;
DROP TABLE IF EXISTS WorkingDays CASCADE;
DROP TABLE IF EXISTS ShiftOptions CASCADE;
DROP TABLE IF EXISTS WorkingWeeks CASCADE;
DROP TABLE IF EXISTS Delivers CASCADE; 

CREATE TABLE Promotion (
    promoID     INTEGER GENERATED ALWAYS AS IDENTITY,
    startDate   DATE NOT NULL,
    endDate     DATE NOT NULL,
    startTime   TIME,
    endTime     TIME,
    discPerc    NUMERIC check(discPerc > 0) DEFAULT NULL,
    discAmt     NUMERIC check(discAmt > 0) DEFAULT NULL,
    type        VARCHAR(255) NOT NULL CHECK (type in ('FDSpromo', 'Restpromo')),
	PRIMARY KEY (promoID)
);


CREATE TABLE FDSpromo (
    promoID     INTEGER,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE
);

CREATE TABLE Restaurants ( 
	restaurantID    INTEGER GENERATED ALWAYS AS IDENTITY,
	name            VARCHAR(100)         NOT NULL,
	location        VARCHAR(255)  UNIQUE NOT NUll,
	minThreshold   	NUMERIC  DEFAULT 0   NOT NULL,
	PRIMARY KEY (RestaurantID)
);

CREATE TABLE Restpromo (
    promoID     INT, 
    restID      INT NOT NULL,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
    FOREIGN KEY (restID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);

CREATE TABLE Categories (
	category    VARCHAR(100),
	PRIMARY KEY (category)
);

CREATE TABLE Food ( --availability removed
	foodName        VARCHAR(100)         NOT NULL,
	price           NUMERIC              NOT NULL CHECK (price > 0),
	dailyLimit      INTEGER DEFAULT '50' NOT NULL,
	RestaurantID    INTEGER,
	category        VARCHAR(255)		 NOT NULL,
    archive         BOOLEAN         DEFAULT FALSE NOT NULL,
	PRIMARY KEY (RestaurantID, foodName),
	FOREIGN KEY (RestaurantID) REFERENCES Restaurants (RestaurantID) ON DELETE CASCADE,
	FOREIGN KEY	(category) REFERENCES Categories (category)
);

CREATE TABLE PaymentOption (
    payOption   VARCHAR(100),
    PRIMARY KEY (payOption)
);

CREATE TABLE Orders (
	orderID             INT GENERATED ALWAYS AS IDENTITY,
	deliveryFee         INTEGER                           NOT NULL DEFAULT 4,
	cost                NUMERIC      DEFAULT 0            NOT NULL,
	location            VARCHAR(255)                      NOT NULL,
	date                DATE DEFAULT CURRENT_DATE         NOT NULL,
	payOption	    VARCHAR(50)			    		  NOT NULL,
	area                CHAR (1)					  NOT NULL CHECK (area in ('N','S','E','W')),
	orderStatus         VARCHAR(50) DEFAULT 'Pending'     NOT NULL CHECK (orderStatus in ('Pending','Confirmed','Completed','Failed')),
	deliveryDuration    VARCHAR(50)  				    NOT NULL DEFAULT '-',
	timeOrderPlace      TIME DEFAULT CURRENT_TIME,
	timeDepartToRest    TIME,
	timeArriveRest      TIME,
	timeDepartFromRest  TIME,
	timeOrderDelivered  TIME,
	PRIMARY KEY (orderID),
	FOREIGN KEY (payOption) REFERENCES PaymentOption (payOption)
);

CREATE TABLE FromMenu (
	quantity        INTEGER      NOT NULL,
	orderID         INT         NOT NULL,
	restaurantID    INTEGER         NOT NULL,
	foodName        VARCHAR(100)    NOT NULL,
    hide            BOOLEAN         DEFAULT FALSE NOT NULL,
	PRIMARY KEY (restaurantID,foodName,orderID),
	FOREIGN KEY (orderID) REFERENCES Orders (orderID),
	FOREIGN KEY (restaurantID, foodName) REFERENCES Food (restaurantID, foodName) ON DELETE CASCADE
);

CREATE TABLE Users (
	uid         INT GENERATED ALWAYS AS IDENTITY,
	name        VARCHAR(255)     NOT NULL,
	username    VARCHAR(255)     UNIQUE NOT NULL,
	password    VARCHAR(255)     NOT NULL,
	type    VARCHAR(255) NOT NULL CHECK (type in ('Customers', 'FDSManagers', 'RestaurantStaff', 'DeliveryRiders')), 
	PRIMARY KEY (uid)
);

CREATE TABLE Customers (
	uid         INTEGER,
	rewardPts   INTEGER DEFAULT '0' NOT NULL,
	signUpDate  DATE    DEFAULT CURRENT_DATE NOT NULL,
	cardDetails VARCHAR(255),
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users(uid) ON DELETE CASCADE
);

CREATE TABLE FDSManagers (
	uid         INTEGER,
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE
);

CREATE TABLE RestaurantStaff (
	uid         INTEGER,
	restaurantID INTEGER NOT NULL, 
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users(uid) ON DELETE CASCADE,
    FOREIGN KEY (restaurantID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);

CREATE TABLE DeliveryRiders (
    uid             INTEGER PRIMARY KEY,
	baseDeliveryFee NUMERIC NOT NULL DEFAULT 2,
	availability BOOLEAN DEFAULT TRUE,  -- free by default
	type    VARCHAR(255)  NOT NULL CHECK (type in ('FullTime', 'PartTime')),
    FOREIGN KEY (uid) REFERENCES Users(uid) ON DELETE CASCADE
);

CREATE TABLE Place (
	uid            INT,
	orderid        INT,  
	review         VARCHAR(255),
	star           INTEGER      DEFAULT NULL CHECK (star >= 0 AND star <= 5), 
	promoid        INT,
	PRIMARY KEY (orderid),
	FOREIGN KEY (uid) REFERENCES Customers ON DELETE CASCADE,
	FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
	FOREIGN KEY (orderid) REFERENCES Orders ON DELETE CASCADE
);

CREATE TABLE PartTime (
	uid            INTEGER PRIMARY KEY,
	weeklyBasePay   NUMERIC NOT NULL DEFAULT 100, /* $10 times minimum 10 hours in each WWS*/
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE FullTime (
	uid              INTEGER PRIMARY KEY,
	monthlyBasePay   INTEGER NOT NULL DEFAULT 1800,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE  WorkingDays ( -- Part Timer
	uid             INTEGER, 
	workDate        DATE NOT NULL,
	intervalStart   TIME NOT NULL,
	intervalEnd     TIME NOT NULL,
	numCompleted    INTEGER DEFAULT 0,
	PRIMARY KEY (uid, workDate, intervalStart, intervalEnd),
	FOREIGN KEY (uid) REFERENCES PartTime(uid) ON DELETE CASCADE,
	CHECK (intervalEnd > intervalStart),
	CHECK (intervalStart>='10:00:00' and intervalEnd<='22:00:00'),
	CHECK (CAST(CONCAT(CAST(EXTRACT(HOUR from intervalStart) AS VARCHAR),':00:00') AS TIME)=intervalStart),
	CHECK (CAST(CONCAT(CAST(EXTRACT(HOUR from intervalEnd) AS VARCHAR),':00:00') AS TIME)=intervalEnd),
	CHECK ((EXTRACT(HOUR FROM intervalEnd) - EXTRACT(HOUR FROM intervalStart))< 5)
);

CREATE TABLE ShiftOptions (
	shiftID         INTEGER, 
	shiftDetail1    VARCHAR(30) NOT NULL,
	shiftDetail2    VARCHAR(30) NOT NULL,
	PRIMARY KEY (shiftID)
);

CREATE TABLE  WorkingWeeks (-- Full Timer
	uid             INTEGER,
	workDate        DATE NOT NULL,
	shiftID         INTEGER NOT NULL,
	numCompleted    INTEGER DEFAULT 0,
	PRIMARY KEY (uid, workDate),
	FOREIGN KEY (uid) REFERENCES FullTime ON DELETE CASCADE,
	FOREIGN KEY (shiftID) REFERENCES ShiftOptions(shiftID)
);


CREATE TABLE Delivers (
    orderID         INTEGER,
    uid             INTEGER,
    rating          INTEGER      DEFAULT NULL CHECK (rating >= 0 AND rating <= 5), 
    PRIMARY KEY (orderID),
    FOREIGN KEY (orderID) REFERENCES Orders(orderID) ON DELETE CASCADE,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

/* Insert Data for 12 Customers*/
INSERT INTO Users (name, username, password, type) VALUES ('Alano', 'asunock0', 'SuKnMdGlSZv', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Ugo', 'uhumphery5', 'zzWtpV6x1W5','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Theo', 'tadkina', 'mXQVb8fG','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Jocelyn', 'jdodshund', '8XnPDwZN', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Paddie', 'ppaulline', 'Ake9PyGlLEh6', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('qwerty', 'qwerty123', '123qwe','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('queenie', 'queen', '123456','Customers'); 
INSERT INTO Users (name, username, password, type) VALUES ('ariel', 'ariel123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('belle', 'belle123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('jasmine', 'jas123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('mulan', 'mulan123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('snow white', 'snow123', '123456','Customers'); 

INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (1,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (2,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (3,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (4,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (5,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (6,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (7,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (8,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (9,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (10,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (11,NULL);
INSERT INTO CUSTOMERS (uid,cardDetails) VALUES (12,NULL);

/* Insert Data for 4 Restaurant Staff - staff to be inserted below restaurants insert*/
INSERT INTO Users (name, username, password, type) VALUES ('Ariela', 'arodolfi1', '6W8jV0Un','RestaurantStaff');
INSERT INTO Users (name, username, password, type) VALUES ('Kitti', 'kbelding6', 'CDvLeT','RestaurantStaff');
INSERT INTO Users (name, username, password, type) VALUES ('Antony', 'aclausenthue4', 'LS5CtMmb','RestaurantStaff'); 
INSERT INTO Users (name, username, password, type) VALUES ('Mr Minestrone', 'minestrone', '12345', 'RestaurantStaff');

/* Insert Data for 4 FDSManager */
INSERT INTO Users (name, username, password, type) VALUES ('Taddeusz', 'tmanketell2', 'PjIpgl7J', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Dodie', 'dfermerb', 'SLKtg2Q7kGn', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Nyan', 'desmond', '123abc', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Kesin', 'itskesin', '123abc', 'FDSManagers'); 

INSERT INTO FDSManagers (uid) VALUES (17);
INSERT INTO FDSManagers (uid) VALUES (18);
INSERT INTO FDSManagers (uid) VALUES (19);
INSERT INTO FDSManagers (uid) VALUES (20);

/* Insert Data for 20 FT Riders */
INSERT INTO Users (name, username, password, type) VALUES ('Adrea', 'aveldens3', 'cdqUwd81YzX','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Adan', 'alaise7', 'blVy4LzR','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Elenore', 'epiatto8', 'jiWxXTs4Jjp','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('NyanCat', 'asdfgh', 'asdfghjkl','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Oona', 'oprevettc', 'xeLkYRLNSkJ' ,'DeliveryRiders'); 
INSERT INTO Users (name, username, password, type) VALUES ('Sig', 'sdavidavidovics0', 'CWuewKYHY', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Valaree', 'valvar1', 'mpHV81w', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Jillian', 'jclick2', 'CGNf82IdSQf', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Meaghan', 'mmuggeridge3', 'PIF1lee0N', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Richie', 'rmerrington4', 'La3UidF1x1Ba', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Patrizius', 'pgail5', 'gq2I70w', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Jordain', 'jryves6', 'RxGRxziDK', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Nestor', 'nfinnemore7', 'HXoa31jOth6y', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Norby', 'ncramb8', 'XPYTg1', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Jock', 'jreynard9', 'hcK6wHQ5m', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Laurens', 'lmcnallya', 'opd7sA', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Rennie', 'rszimonb', 'YWeoea0', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Dianemarie', 'dcrookshankc', 'JeXCIsmuhfq', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Lorry', 'lcovertd', 'xWhikfYExb1P', 'DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Thor', 'tlattimere', 'ihMDOvmHIKFv', 'DeliveryRiders'); 

INSERT INTO DeliveryRiders(uid,type) VALUES (21,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (22,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (23,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (24,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (25,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (26,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (27,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (28,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (29,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (30,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (31,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (32,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (33,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (34,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (35,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (36,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (37,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (38,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (39,'FullTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (40,'FullTime');

INSERT INTO FullTime(uid) VALUES (21);
INSERT INTO FullTime(uid) VALUES (22);
INSERT INTO FullTime(uid) VALUES (23);
INSERT INTO FullTime(uid) VALUES (24);
INSERT INTO FullTime(uid) VALUES (25);
INSERT INTO FullTime(uid) VALUES (26);
INSERT INTO FullTime(uid) VALUES (27);
INSERT INTO FullTime(uid) VALUES (28);
INSERT INTO FullTime(uid) VALUES (29);
INSERT INTO FullTime(uid) VALUES (30);
INSERT INTO FullTime(uid) VALUES (31);
INSERT INTO FullTime(uid) VALUES (32);
INSERT INTO FullTime(uid) VALUES (33);
INSERT INTO FullTime(uid) VALUES (34);
INSERT INTO FullTime(uid) VALUES (35);
INSERT INTO FullTime(uid) VALUES (36);
INSERT INTO FullTime(uid) VALUES (37);
INSERT INTO FullTime(uid) VALUES (38);
INSERT INTO FullTime(uid) VALUES (39);
INSERT INTO FullTime(uid) VALUES (40);

/* Insert Data for 20 PT Riders */
INSERT INTO Users (name, username, password, type) VALUES ('Gary', 'gtarrier9', 'G92FSUJuvL9e','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Nadiah', 'wasd', 'zxcvbnm','DeliveryRiders');
INSERT INTO Users (name, username, password, type) VALUES ('Jan', 'qwerty', 'qwertyuiop','DeliveryRiders'); 
insert into Users (name, username, password, type) values ('Appolonia', 'afoat0', 'hUBKbNmZ1', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Richardo', 'rcicutto1', 'PEL5dQom', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Anette', 'asantostefano2', '0u6h702yagzK', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Tucker', 'tcuschieri3', 'm7KEqz', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Zebadiah', 'zgrinley4', 'kGOyHFJ5Dt', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Elysia', 'ewheadon5', 'QKLUdYs1', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Tamarah', 'tchazette6', 'AwQSj8HsX', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Zaneta', 'zasch7', 'QyvMGu7hOMED', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Tudor', 'tmeus8', '42RPpdczIMR', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Casi', 'cgoodbar9', 'UwnBKg', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Wendel', 'wtieraneya', 'Tyij54pW3S', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Jason', 'jbrownriggb', 'c7RxC7', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Goldina', 'gjodrellec', 'DsD9nv07HgB', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Alex', 'aandrysekd', 'xpgR3HMDXTrU', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Arel', 'afirebracee', 'lFJFXM', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Mariana', 'mferierf', '3qNqdMhn', 'DeliveryRiders');
insert into Users (name, username, password, type) values ('Lulita', 'lconnalg', 'AF3DHUM6', 'DeliveryRiders'); 

INSERT INTO DeliveryRiders(uid,type) VALUES (41,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (42,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (43,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (44,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (45,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (46,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (47,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (48,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (49,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (50,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (51,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (52,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (53,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (54,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (55,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (56,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (57,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (58,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (59,'PartTime');
INSERT INTO DeliveryRiders(uid,type) VALUES (60,'PartTime');

INSERT INTO PartTime(uid) VALUES(41);
INSERT INTO PartTime(uid) VALUES(42);
INSERT INTO PartTime(uid) VALUES(43);
INSERT INTO PartTime(uid) VALUES(44);
INSERT INTO PartTime(uid) VALUES(45);
INSERT INTO PartTime(uid) VALUES(46);
INSERT INTO PartTime(uid) VALUES(47);
INSERT INTO PartTime(uid) VALUES(48);
INSERT INTO PartTime(uid) VALUES(49);
INSERT INTO PartTime(uid) VALUES(50);
INSERT INTO PartTime(uid) VALUES(51);
INSERT INTO PartTime(uid) VALUES(52);
INSERT INTO PartTime(uid) VALUES(53);
INSERT INTO PartTime(uid) VALUES(54);
INSERT INTO PartTime(uid) VALUES(55);
INSERT INTO PartTime(uid) VALUES(56);
INSERT INTO PartTime(uid) VALUES(57);
INSERT INTO PartTime(uid) VALUES(58);
INSERT INTO PartTime(uid) VALUES(59);
INSERT INTO PartTime(uid) VALUES(60);

/*Insert Shifts for Full Time Schedule */
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (1, '10am-2pm','3pm-7pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (2, '11am-3pm','4pm-8pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (3, '12pm-4pm','5pm-9pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (4, '1pm-5pm','6pm-10pm');

/*Insert Schedule for Riders */
BEGIN;
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-06', '10:00', '14:00', 7);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-06', '15:00', '19:00', 6);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-07', '10:00', '14:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-07', '15:00', '19:00', 4);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-08', '10:00', '14:00', 5);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-08', '15:00', '19:00', 9);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-13', '10:00', '14:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-13', '15:00', '19:00', 9);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-14', '10:00', '14:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-14', '15:00', '19:00', 7);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-15', '10:00', '14:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-15', '15:00', '19:00', 6);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-20', '10:00', '14:00', 6);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-20', '15:00', '19:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-21', '10:00', '14:00', 9);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-21', '15:00', '19:00', 6);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-22', '10:00', '14:00', 4);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-22', '15:00', '19:00', 7);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-27', '10:00', '14:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-27', '15:00', '19:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-28', '10:00', '14:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-28', '15:00', '19:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-29', '10:00', '14:00', 6);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-04-29', '15:00', '19:00', 9);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-04', '10:00', '14:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-04', '15:00', '19:00', 7);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-05', '10:00', '14:00', 7);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-05', '15:00', '19:00', 9);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-06', '10:00', '14:00', 6);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-06', '15:00', '19:00', 10);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-11', '10:00', '14:00', 0);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-11', '15:00', '19:00', 0);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-12', '10:00', '14:00', 0);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-12', '15:00', '19:00', 0);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-13', '10:00', '14:00', 0);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(41, '2020-05-13', '15:00', '19:00', 0);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-01-08', '11:00', '15:00', 10); /*Include others*/
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-01-08', '16:00', '20:00', 12);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-01-09', '11:00', '15:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-01-09', '16:00', '20:00', 10);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-03-19', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-03-20', '16:00', '20:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-03-21', '16:00', '20:00', 12);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-04-20', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-04-20', '16:00', '20:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-04-21', '11:00', '15:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-04-21', '16:00', '20:00', 12);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-05-12', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-05-13', '16:00', '20:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-05-14', '11:00', '15:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(42, '2020-05-15', '16:00', '20:00', 12);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-01-08', '11:00', '15:00', 10); /*Include others*/
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-01-08', '16:00', '20:00', 12);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-01-09', '11:00', '15:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-01-09', '16:00', '20:00', 10);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-03-19', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-03-20', '16:00', '20:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-03-21', '16:00', '20:00', 12);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-04-20', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-04-20', '16:00', '20:00', 8);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-04-21', '11:00', '15:00', 11);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(43, '2020-04-21', '16:00', '20:00', 12);
COMMIT;

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-23', 1, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-24', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-25', 1, 16);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-26', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-27', 1, 14);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-03-31', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-01', 3, 11);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-02', 3, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-03', 3, 18);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-04', 3, 15);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-07', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-08', 3, 16);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-09', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-10', 3, 20);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-11', 3, 8);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-14', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-15', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-16', 3, 11);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-17', 3, 22);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-18', 3, 15);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-21', 3, 14);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-22', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-23', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-24', 3, 17);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-25', 3, 13);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-28', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-29', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-04-30', 3, 14);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-01', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-02', 3, 17);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-05', 3, 14);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-06', 3, 18);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-07', 3, 19);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-08', 3, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-09', 3, 11);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-11', 1, 0);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-12', 1, 0);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-13', 1, 0);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-14', 1, 0);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(21, '2020-05-15', 1, 0);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(22, '2020-04-20', 1, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(22, '2020-04-21', 1, 14);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(22, '2020-04-22', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(22, '2020-04-23', 1, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(22, '2020-04-24', 1, 17);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2020-04-20', 2, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2020-04-21', 2, 14);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2020-04-22', 2, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2020-04-23', 2, 12);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2020-04-24', 2, 17);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2019-12-13', 1, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2019-12-25', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(23, '2019-12-26', 1, 16);


/* Insert Data for restaurants */
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Noma', '456 Madhouse Road #11-26 Singapore 123456', 5);
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Odette', '456 Database Road #01-27 Singapore 123456', 5);
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Wolfgang Puck', '567 Gowhere Road #01-27 Singapore 456567', 3);
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Crystal Jade','123 Gowhere Road #01-27 Singapore 123456',4);
INSERT INTO Restaurants (name, location) VALUES ('Minestrone King','313 Orchard Rd #B2-05 Singapore 238895');
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Zen food','456 Hungry Road #01-36 Singapore 456789',5);


INSERT INTO RestaurantStaff (uid, restaurantID) VALUES (13,1);
INSERT INTO RestaurantStaff (uid, restaurantID) VALUES (14,2);
INSERT INTO RestaurantStaff (uid, restaurantID) VALUES (15,3); 
INSERT INTO RestaurantStaff (uid, restaurantID) VALUES (16,5); 

/* Insert Data for categories */
INSERT INTO Categories(category) VALUES ('Malay Cuisine');
INSERT INTO Categories(category) VALUES ('Chinese Cuisine');
INSERT INTO Categories(category) VALUES ('Indian Cuisine');
INSERT INTO Categories(category) VALUES ('Japanese Cuisine');
INSERT INTO Categories(category) VALUES ('Korean Cuisine');
INSERT INTO Categories(category) VALUES ('Western Cuisine');

/* Insert Data for food */
/*Restaurant 1*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Nasi Briyani', 12.9, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tandoori Chicken', 22.8, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Butter Chicken', 27.3, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tikka Masala', 27.8, 1, 'Indian Cuisine');

/*Restaurant 2*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Ayam Penyet', 5.0, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Gado Gado', 13.0, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Lontong', 6.3, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Nasi Lemak', 9.2, 2, 'Malay Cuisine');

/*Restaurant 3*/
INSERT INTO Food (foodName, price, dailyLimit, RestaurantID, category) VALUES ('Tteokbokki', 14.9,100,3, 'Korean Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Kimchi Fried Rice', 10.5, 3, 'Korean Cuisine');

/*Restaurant 4*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Yang Zhou Fried Rice', 8, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Sweet and Sour Pork', 14, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Steam Egg', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Hot and Sour Soup', 7, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Spring Rolls', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Stir Fried Tofu', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Chicken with Chestnuts', 15, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Chicken Soup', 12, 4, 'Chinese Cuisine');

/*Restaurant 5*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Minestrone Soup', 2.50, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Onion Soup', 3.50, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Mushroom Soup', 3.00, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Corn Soup', 3.20, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Chicken Chop', 4.00, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Pork Chop', 4.20, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Steak', 4.50, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Creamy Pasta', 3.50, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tomato Pasta', 3.00, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Aglio Olio', 3.30, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category, archive) VALUES ('Seafood Pasta', 4.00, 5, 'Western Cuisine', 'TRUE');

/*Restaurant 6*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Sushi', 29.9, 6, 'Japanese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tempura', 19.7, 6, 'Japanese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Char Siew Ramen', 8.5, 6, 'Japanese Cuisine');

/* Insert Data for Promo.*/
INSERT INTO Promotion (startDate,endDate,discAmt,type) VALUES ('2020-02-01','2020-02-28',5,'FDSpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,type) VALUES ('2020-03-01','2020-05-30',0.2,'FDSpromo'); 
INSERT INTO Promotion (startDate,endDate,discAmt,type) VALUES ('2020-06-01','2020-06-30',5,'FDSpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,type) VALUES ('2020-03-01','2020-05-30',0.2,'Restpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,type) VALUES ('2020-06-01','2020-07-01',0.2,'Restpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,type) VALUES ('2020-08-01','2020-09-01',0.15,'Restpromo');
/*Rest Staff Pages Dummy Data: Promotions 7-10*/
INSERT INTO Promotion (startDate,endDate, startTime, endTime, discPerc, type) VALUES ('2020-03-10','2020-03-10', '09:55', '13:00', 0.05,'Restpromo');
INSERT INTO Promotion (startDate,endDate, startTime, endTime, discAmt, type) VALUES ('2020-01-01','2020-01-01', '15:00', '17:00', 1.00,'Restpromo');
INSERT INTO Promotion (startDate,endDate, startTime, endTime, discAmt, type) VALUES ('2020-01-28','2020-01-31', '18:00', '20:00', 1.50,'Restpromo');
INSERT INTO Promotion (startDate,endDate, startTime, endTime, discPerc, type) VALUES ('2019-12-24','2019-12-26', '12:30', '12:30', 0.10,'Restpromo');

INSERT INTO FDSpromo(promoID) VALUES(1);
INSERT INTO FDSpromo(promoID) VALUES(2);
INSERT INTO FDSpromo(promoID) VALUES(3);
INSERT INTO Restpromo(promoID, restID) VALUES(4,1);
INSERT INTO Restpromo(promoID, restID) VALUES(5,3);
INSERT INTO Restpromo(promoID, restID) VALUES(6,4);
INSERT INTO Restpromo(promoID, restID) VALUES(7,5);
INSERT INTO Restpromo(promoID, restID) VALUES(8,5);
INSERT INTO Restpromo(promoID, restID) VALUES(9,5);
INSERT INTO Restpromo(promoID, restID) VALUES(10,5);

/* Insert Data into Payment Option */
INSERT INTO PaymentOption(payOption) VALUES ('Cash');
INSERT INTO PaymentOption(payOption) VALUES ('Credit');
INSERT INTO PaymentOption(payOption) VALUES ('RewardPts');					      


-- deliveryduration is in integer?
/* Insert Data into orders and fromMenu think of how to make it happen*/ 
/* Order 1: Confirmed */
INSERT INTO Orders(location,date,payOption,area) VALUES ('81 Goodland Road','2020-04-20','Cash','N'); /* let cost be initially deffered*/

INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (5,1,3,'Tteokbokki');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (3,1,3,'Kimchi Fried Rice');   

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (1,1,'no comments',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 1) WHERE orderID = 1; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 1 LIMIT 1)) WHERE orderID = 1; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 1 LIMIT 1) WHERE orderID = 1; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 1;
UPDATE Orders SET timeOrderPlace = '11:00:00' WHERE orderID = 1;
UPDATE Orders SET timeDepartToRest = '11:05:00' WHERE orderID = 1;
UPDATE Orders SET timeArriveRest = '11:11:00' WHERE orderID = 1;
UPDATE Orders SET timeDepartFromRest = '11:22:00' WHERE orderID = 1;
UPDATE Orders SET timeOrderDelivered = '11:45:00'  WHERE orderID = 1;

/*Order 2: Completed by .... */ 
INSERT INTO Orders(location,date,payOption,area) VALUES ('346 Dennis Trail','2020-01-08','Credit','S'); /* let cost be initially deffered*/
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,2,4,'Steam Egg');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,2,4,'Sweet and Sour Pork');   
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (3,2,4,'Yang Zhou Fried Rice');
        
/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (3,2,'Nice food',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 2) WHERE orderID = 2; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 2 LIMIT 1)) WHERE orderID = 2; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 2 LIMIT 1) WHERE orderID = 2; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 2;
UPDATE Orders SET timeOrderPlace = '10:50:00' WHERE orderID = 2;
UPDATE Orders SET timeDepartToRest = '11:00:00' WHERE orderID = 2;
UPDATE Orders SET timeArriveRest = '11:15:00' WHERE orderID = 2;

/* Order 3: Confirmed */
--partial order completion possible (quantity < availQty)
INSERT INTO Orders(location,payOption,area) VALUES ('333 Canberra Road','Cash','S'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (4,3,3,'Tteokbokki');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (3,3,3,'Kimchi Fried Rice');  

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (7,3,'Tastes great',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 3) WHERE orderID = 3; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 3 LIMIT 1)) WHERE orderID = 3; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 3 LIMIT 1) WHERE orderID = 3; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 3;
UPDATE Orders SET timeOrderPlace = '13:00:00' WHERE orderID = 3;
UPDATE Orders SET timeDepartToRest = '13:05:00' WHERE orderID = 3;
UPDATE Orders SET timeArriveRest = '13:11:00' WHERE orderID = 3;
UPDATE Orders SET timeDepartFromRest = '13:22:00' WHERE orderID = 3;
UPDATE Orders SET timeOrderDelivered = '13:45:00'  WHERE orderID = 3;

/* Order 4: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('311 Canberra Road','Cash','N'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (4,4,3,'Tteokbokki');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (4,4,3,'Kimchi Fried Rice');  

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (8,4,'Tastes great',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 4) WHERE orderID = 4; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 4 LIMIT 1)) WHERE orderID = 4; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 4 LIMIT 1) WHERE orderID = 4; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 4;
UPDATE Orders SET timeOrderPlace = '13:00:00' WHERE orderID = 4;
UPDATE Orders SET timeDepartToRest = '13:05:00' WHERE orderID = 4;
UPDATE Orders SET timeArriveRest = '13:11:00' WHERE orderID = 4;
UPDATE Orders SET timeDepartFromRest = '13:22:00' WHERE orderID = 4;
UPDATE Orders SET timeOrderDelivered = '13:45:00'  WHERE orderID = 4;

/* Order 5: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('911 Yishun Road','Credit','N'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (2,5,'Food slightly cold when arrived',1);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 5) WHERE orderID = 5; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 5 LIMIT 1)) WHERE orderID = 5; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 5 LIMIT 1) WHERE orderID = 5; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 5;
UPDATE Orders SET timeOrderPlace = '15:00:00' WHERE orderID = 5;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 5;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 5;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 5;
UPDATE Orders SET timeOrderDelivered = '15:55:00'  WHERE orderID = 5;


/* Order 6: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('987 Tampines Road','Cash','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,6,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,6,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,6,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (8,6,'Taste great',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 6) WHERE orderID = 6; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 6 LIMIT 1)) WHERE orderID = 6; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 6 LIMIT 1) WHERE orderID = 6; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 6;
UPDATE Orders SET timeOrderPlace = '15:20:00' WHERE orderID = 6;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 6;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 6;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 6;
UPDATE Orders SET timeOrderDelivered = '15:55:00'  WHERE orderID = 6;


/* Order 7: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('988 Tampines Road','Cash','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,7,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,7,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,7,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (11,7,'Taste great',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 7) WHERE orderID = 7; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 7 LIMIT 1)) WHERE orderID = 7; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 7 LIMIT 1) WHERE orderID = 7; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 7;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 7;


/* Order 8: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('988 Tampines Road','Credit','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (1,8,'Great Sushi',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 8) WHERE orderID = 8; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 8 LIMIT 1)) WHERE orderID = 8; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 8 LIMIT 1) WHERE orderID = 8; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 8;
UPDATE Orders SET timeOrderPlace = '15:00:00' WHERE orderID = 8;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 8;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 8;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 8;
UPDATE Orders SET timeOrderDelivered = '15:58:00'  WHERE orderID = 8;

/*Rest Staff Pages Dummy Data: Orders 9 to 27 (Using CUSTOMER 6)*/
/*Order 9: Confirmed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-55','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(2, 9, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 9, 5, 'Mushroom Soup');
INSERT INTO Place (uid,orderID) VALUES (6,9);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 9) WHERE orderID = 9; /*Food costs*/

UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 9;
UPDATE Orders SET timeOrderPlace = '10:20:00' WHERE orderID = 9;

/*Order 10: Confirmed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-56','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(2, 10, 5, 'Chicken Chop');
INSERT INTO Place (uid,orderID) VALUES (6,10);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 10) WHERE orderID = 10; /*Food costs*/

UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 10;
UPDATE Orders SET timeOrderPlace = '10:20:00' WHERE orderID = 10;



/*Order 11: Confirmed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-56','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 11, 5, 'Corn Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 11, 5, 'Pork Chop');
INSERT INTO Place (uid,orderID) VALUES (6,11);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 11) WHERE orderID = 11; /*Food costs*/

UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 11;
UPDATE Orders SET timeOrderPlace = '10:29:00' WHERE orderID = 11;


  
/*Order 12: Confirmed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-57','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 12, 5, 'Onion Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 12, 5, 'Mushroom Soup');
INSERT INTO Place (uid,orderID) VALUES (6,12);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 12) WHERE orderID = 12; /*Food costs*/

UPDATE Orders SET date = '2020-05-10' WHERE orderID = 12;
UPDATE Orders SET orderStatus = 'Confirmed' WHERE orderID = 12;
UPDATE Orders SET timeOrderPlace = '12:35:00' WHERE orderID = 12;
UPDATE Orders SET timeDepartToRest = '12:36:00' WHERE orderID = 12;
UPDATE Orders SET timeArriveRest = '12:55:00' WHERE orderID = 12;
UPDATE Orders SET timeDepartFromRest = '13:00:00' WHERE orderID = 12;

/*Order 13: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 13, 5, 'Steak');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 13, 5, 'Creamy Pasta');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 13, 5, 'Tomato Pasta');
INSERT INTO Place (uid,orderID, promoid) VALUES (6,13,10);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 13) WHERE orderID = 13; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 13 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 13; /*For percentage promo*/

UPDATE Orders SET date = '2019-12-25' WHERE orderID = 13;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 13;
UPDATE Orders SET timeOrderPlace = '11:00:00' WHERE orderID = 13;
UPDATE Orders SET timeDepartToRest = '11:01:00' WHERE orderID = 13;
UPDATE Orders SET timeArriveRest = '11:25:00' WHERE orderID = 13;
UPDATE Orders SET timeDepartFromRest = '11:30:00' WHERE orderID = 13;
UPDATE Orders SET timeOrderDelivered = '12:00:00' WHERE orderID = 13;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 13) WHERE orderID = 13;


/*Order 14: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 14, 5, 'Steak');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 14, 5, 'Creamy Pasta');
INSERT INTO Place (uid,orderID,promoid) VALUES (6,14,10);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 14) WHERE orderID = 14; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 14 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 14; /*For percentage promo*/

UPDATE Orders SET date = '2019-12-26' WHERE orderID = 14;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 14;
UPDATE Orders SET timeOrderPlace = '10:20:00' WHERE orderID = 14;
UPDATE Orders SET timeDepartToRest = '11:00:00' WHERE orderID = 14;
UPDATE Orders SET timeArriveRest = '11:14:00' WHERE orderID = 14;
UPDATE Orders SET timeDepartFromRest = '11:15:00' WHERE orderID = 14;
UPDATE Orders SET timeOrderDelivered = '12:00:00' WHERE orderID = 14;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 14) WHERE orderID = 14;


/*Order 15: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 

INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 15, 5, 'Steak');
INSERT INTO Place (uid,orderID) VALUES (6,15);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 15) WHERE orderID = 15; /*Food costs*/

UPDATE Orders SET date = '2019-12-13' WHERE orderID = 15; 
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 15;
UPDATE Orders SET timeOrderPlace = '16:00:00' WHERE orderID = 15;
UPDATE Orders SET timeDepartToRest = '16:01:00' WHERE orderID = 15;
UPDATE Orders SET timeArriveRest = '16:15:00' WHERE orderID = 15;
UPDATE Orders SET timeDepartFromRest = '16:20:00' WHERE orderID = 15;
UPDATE Orders SET timeOrderDelivered = '16:30:00' WHERE orderID = 15;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 15) WHERE orderID = 15;


/*Order 16: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 16, 5, 'Aglio Olio');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 16, 5, 'Creamy Pasta');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,16,7);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 16) WHERE orderID = 16; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 16 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 16; /*For percentage promo*/

UPDATE Orders SET date = '2020-03-10' WHERE orderID = 16;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 16;
UPDATE Orders SET timeOrderPlace = '10:00:00' WHERE orderID = 16;
UPDATE Orders SET timeDepartToRest = '10:45:00' WHERE orderID = 16;
UPDATE Orders SET timeArriveRest = '10:50:00' WHERE orderID = 16;
UPDATE Orders SET timeDepartFromRest = '11:00:00' WHERE orderID = 16;
UPDATE Orders SET timeOrderDelivered = '11:30:00' WHERE orderID = 16;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 16) WHERE orderID = 16;



/*Order 17: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Onion Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Mushroom Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Corn Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Chicken Chop');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 17, 5, 'Pork Chop');
INSERT INTO Place (uid,orderID) VALUES (6,17);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 17) WHERE orderID = 17; /*Food costs*/

UPDATE Orders SET date = '2020-01-15' WHERE orderID = 17; 
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 17;
UPDATE Orders SET timeOrderPlace = '18:30:00' WHERE orderID = 17;
UPDATE Orders SET timeDepartToRest = '18:31:00' WHERE orderID = 17;
UPDATE Orders SET timeArriveRest = '18:55:00' WHERE orderID = 17;
UPDATE Orders SET timeDepartFromRest = '19:00:00' WHERE orderID = 17;
UPDATE Orders SET timeOrderDelivered = '19:30:00' WHERE orderID = 17;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 17) WHERE orderID = 17;


/*Order 18: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 18, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 18, 5, 'Onion Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 18, 5, 'Mushroom Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 18, 5, 'Corn Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 18, 5, 'Chicken Chop');
INSERT INTO Place (uid,orderID) VALUES (6,18);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 18) WHERE orderID = 18; /*Food costs*/

UPDATE Orders SET date = '2020-01-25' WHERE orderID = 18;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 18;
UPDATE Orders SET timeOrderPlace = '12:30:00' WHERE orderID = 18;
UPDATE Orders SET timeDepartToRest = '12:31:00' WHERE orderID = 18;
UPDATE Orders SET timeArriveRest = '12:55:00' WHERE orderID = 18;
UPDATE Orders SET timeDepartFromRest = '13:00:00' WHERE orderID = 18;
UPDATE Orders SET timeOrderDelivered = '13:30:00' WHERE orderID = 18;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 18) WHERE orderID = 18;



/*Order 19: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 19, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 19, 5, 'Onion Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 19, 5, 'Mushroom Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 19, 5, 'Corn Soup');
INSERT INTO Place (uid,orderID) VALUES (6,19);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 19) WHERE orderID = 19; /*Food costs*/

UPDATE Orders SET date = '2020-01-06' WHERE orderID = 19;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 19;
UPDATE Orders SET timeOrderPlace = '10:10:00' WHERE orderID = 19;
UPDATE Orders SET timeDepartToRest = '10:11:00' WHERE orderID = 19;
UPDATE Orders SET timeArriveRest = '10:34:00' WHERE orderID = 19;
UPDATE Orders SET timeDepartFromRest = '10:35:00' WHERE orderID = 19;
UPDATE Orders SET timeOrderDelivered = '13:00:00' WHERE orderID = 19;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 19) WHERE orderID = 19;



/*Order 20: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 20, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 20, 5, 'Onion Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 20, 5, 'Mushroom Soup');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,20,8);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 20) WHERE orderID = 20; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 20 LIMIT 1)::NUMERIC, 2) WHERE orderID = 20; /*For amt promo*/

UPDATE Orders SET date = '2020-01-01' WHERE orderID = 20;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 20;
UPDATE Orders SET timeOrderPlace = '15:30:00' WHERE orderID = 20;
UPDATE Orders SET timeDepartToRest = '15:31:00' WHERE orderID = 20;
UPDATE Orders SET timeArriveRest = '15:34:00' WHERE orderID = 20;
UPDATE Orders SET timeDepartFromRest = '16:00:00' WHERE orderID = 20;
UPDATE Orders SET timeOrderDelivered = '16:30:00' WHERE orderID = 20;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 20) WHERE orderID = 20;

/*Order 21: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 21, 5, 'Minestrone Soup');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 21, 5, 'Onion Soup');
INSERT INTO Place (uid,orderID) VALUES (6,21);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 21) WHERE orderID = 21; /*Food costs*/

UPDATE Orders SET date = '2020-01-13' WHERE orderID = 21;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 21;
UPDATE Orders SET timeOrderPlace = '20:00:00' WHERE orderID = 21;
UPDATE Orders SET timeDepartToRest = '20:11:00' WHERE orderID = 21;
UPDATE Orders SET timeArriveRest = '20:15:00' WHERE orderID = 21;
UPDATE Orders SET timeDepartFromRest = '20:30:00' WHERE orderID = 21;
UPDATE Orders SET timeOrderDelivered = '20:40:00' WHERE orderID = 21;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 21) WHERE orderID = 21;


/*Order 22: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-50','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 22, 5, 'Minestrone Soup');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,22,9);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 22) WHERE orderID = 22; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 22 LIMIT 1)::NUMERIC, 2) WHERE orderID = 22; /*For amt promo*/

UPDATE Orders SET date = '2020-01-30' WHERE orderID = 22;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 22;
UPDATE Orders SET timeOrderPlace = '21:00:00' WHERE orderID = 22;
UPDATE Orders SET timeDepartToRest = '21:11:00' WHERE orderID = 22;
UPDATE Orders SET timeArriveRest = '21:15:00' WHERE orderID = 22;
UPDATE Orders SET timeDepartFromRest = '21:30:00' WHERE orderID = 22;
UPDATE Orders SET timeOrderDelivered = '21:40:00' WHERE orderID = 22;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 22) WHERE orderID = 22;

/* Order 23: Completed */
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-51','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 23, 5, 'Aglio Olio');
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 23, 5, 'Creamy Pasta');
INSERT INTO Place (uid,orderID,promoID) VALUES (6, 23, 7);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 23) WHERE orderID = 23; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 23 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 23; /*For percentage promo*/

UPDATE Orders SET date = '2020-03-10' WHERE orderID = 23;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 23;
UPDATE Orders SET timeOrderPlace = '12:00:00' WHERE orderID = 23;
UPDATE Orders SET timeDepartToRest = '12:01:00' WHERE orderID = 23;
UPDATE Orders SET timeArriveRest = '12:25:00' WHERE orderID = 23;
UPDATE Orders SET timeDepartFromRest = '12:30:00' WHERE orderID = 23;
UPDATE Orders SET timeOrderDelivered = '12:40:00' WHERE orderID = 23;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 23) WHERE orderID = 23;

/*Order 24: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-51','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 24, 5, 'Minestrone Soup');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,24,8);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 24) WHERE orderID = 24; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 24 LIMIT 1)::NUMERIC, 2) WHERE orderID = 24; /*For amt promo*/

UPDATE Orders SET date = '2020-01-01' WHERE orderID = 24;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 24;
UPDATE Orders SET timeOrderPlace = '16:30:00' WHERE orderID = 24;
UPDATE Orders SET timeDepartToRest = '16:31:00' WHERE orderID = 24;
UPDATE Orders SET timeArriveRest = '16:34:00' WHERE orderID = 24;
UPDATE Orders SET timeDepartFromRest = '17:00:00' WHERE orderID = 24;
UPDATE Orders SET timeOrderDelivered = '17:30:00' WHERE orderID = 24;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 24) WHERE orderID = 24;


/*Order 25: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-52','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 25, 5, 'Minestrone Soup');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,25,8);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 25) WHERE orderID = 25; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 25 LIMIT 1)::NUMERIC, 2) WHERE orderID = 25; /*For amt promo*/

UPDATE Orders SET date = '2020-01-01' WHERE orderID = 25;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 25;
UPDATE Orders SET timeOrderPlace = '15:15:00' WHERE orderID = 25;
UPDATE Orders SET timeDepartToRest = '16:31:00' WHERE orderID = 25;
UPDATE Orders SET timeArriveRest = '16:34:00' WHERE orderID = 25;
UPDATE Orders SET timeDepartFromRest = '17:00:00' WHERE orderID = 25;
UPDATE Orders SET timeOrderDelivered = '17:30:00' WHERE orderID = 25;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 25) WHERE orderID = 25;

/*Order 26: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-52','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 26, 5, 'Steak');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,26,10);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 26) WHERE orderID = 26; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 26 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 26; /*For percentage promo*/

UPDATE Orders SET date = '2019-12-25' WHERE orderID = 26;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 26;
UPDATE Orders SET timeOrderPlace = '10:00:00' WHERE orderID = 26;
UPDATE Orders SET timeDepartToRest = '11:01:00' WHERE orderID = 26;
UPDATE Orders SET timeArriveRest = '11:25:00' WHERE orderID = 26;
UPDATE Orders SET timeDepartFromRest = '11:30:00' WHERE orderID = 26;
UPDATE Orders SET timeOrderDelivered = '12:00:00' WHERE orderID = 26;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 26) WHERE orderID = 26;


/*Order 27: Completed*/
INSERT INTO Orders(location,payOption,area) VALUES ('333 Pasir Ris Rd #05-52','Cash','E'); 
INSERT INTO FromMenu(quantity, orderID, restaurantID, foodName) VALUES(1, 27, 5, 'Creamy Pasta');
INSERT INTO Place (uid,orderID,promoID) VALUES (6,27,10);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 27) WHERE orderID = 27; /*Food costs*/
UPDATE Orders SET cost = ROUND(cost*(1-(SELECT COALESCE(P.discPerc,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 27 LIMIT 1))::NUMERIC, 2 ) WHERE orderID = 27; /*For percentage promo*/

UPDATE Orders SET date = '2019-12-26' WHERE orderID = 27;
UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 27;
UPDATE Orders SET timeOrderPlace = '10:00:00' WHERE orderID = 27;
UPDATE Orders SET timeDepartToRest = '11:00:00' WHERE orderID = 27;
UPDATE Orders SET timeArriveRest = '11:14:00' WHERE orderID = 27;
UPDATE Orders SET timeDepartFromRest = '11:15:00' WHERE orderID = 27;
UPDATE Orders SET timeOrderDelivered = '12:00:00' WHERE orderID = 27;

UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), 'HH24 h MI "min"') FROM Orders WHERE orderID = 27) WHERE orderID = 27;


/* Insert Data into delivers */
INSERT INTO Delivers (orderID,uid,rating) VALUES (1,22,2);
INSERT INTO Delivers (orderID,uid,rating) VALUES (2,21,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (3,21,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (4,21,3);
INSERT INTO Delivers (orderID,uid,rating) VALUES (5,41,1);
INSERT INTO Delivers (orderID,uid,rating) VALUES (6,41,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (7,41,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (8,42,5);
/*Rest Staff Pages Dummy Data: For orders 9 to 27, the rider 23 does not have an existing schedule.*/
INSERT INTO Delivers (orderID,uid) VALUES (9,23);
INSERT INTO Delivers (orderID,uid) VALUES (10,23);
INSERT INTO Delivers (orderID,uid) VALUES (11,23);
INSERT INTO Delivers (orderID,uid) VALUES (12,23);
INSERT INTO Delivers (orderID,uid,rating) VALUES (13,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (14,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (15,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (16,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (17,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (18,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (19,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (20,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (21,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (22,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (23,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (24,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (25,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (26,23,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (27,23,5);

/*Update WorkingDays SET intervalEnd = '22:00' WHERE uid = 18 AND workDate = '2020-01-08' AND intervalStart = '15:00'; 
UPDATE users SET cardDetails = '5200828282828210' WHERE uid = 4;*/


/*Rest Staff Pages Dummy Data: Reset Daily Limit after manual order insertion*/
UPDATE food set dailyLimit = 50 where foodName = 'Minestrone Soup' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Onion Soup' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Mushroom Soup' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Corn Soup' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Chicken Chop' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Pork Chop' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Steak' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Creamy Pasta' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Tomato Pasta' and RestaurantID = 5;
UPDATE food set dailyLimit = 50 where foodName = 'Aglio Olio' and RestaurantID = 5;

/* Create views */

/*PARTTIME. Consolidate shows for each parttime rider, how many weeks they actually worked in a month (If they
work one day in a week, it will be counted in totalWeeksWorked) and how many deliveries completed in a month */
CREATE OR REPLACE VIEW ConsolidateP AS (
SELECT distinct P1.uid as pUid, 
P1.weeklyBasePay as pBasePay, 
EXTRACT(YEAR FROM WD1.workDate) as pYear, 
EXTRACT(Month FROM WD1.workDate) as pMonth,
count( distinct EXTRACT(WEEK FROM WD1.workDate)) as totalWeeksWorked, 
sum(WD1.numCompleted) as pComplete
FROM PartTime P1
INNER JOIN WorkingDays WD1 on P1.uid = WD1.uid
WHERE WD1.numCompleted > 0 /**Filter out weeks without any worked days at all for count(Extract(WEEK FROM WD.workDate))**/
GROUP BY P1.uid, EXTRACT(YEAR FROM WD1.workDate), EXTRACT(Month FROM WD1.workDate)
);

/*FULLTIME. ConsolidateF shows for each fulltime rider, how many months they actually worked (even if they worked one day in a month) 
and how many deliveries completed in a month */
CREATE OR REPLACE VIEW ConsolidateF AS (
SELECT distinct F1.uid as fUid,
F1.monthlyBasePay as fBasePay,
EXTRACT(YEAR FROM WW1.workDate) as fYear,
EXTRACT(MONTH FROM WW1.workDate) as fMonth,
sum(WW1.numCompleted) as fCompleted
FROM FullTime F1
INNER JOIN WorkingWeeks WW1 on F1.uid = WW1.uid
WHERE WW1.numCompleted > 0  /**Filter out months without any worked days at all**/
GROUP BY F1.uid, EXTRACT(YEAR FROM WW1.workDate), EXTRACT(MONTH FROM WW1.workDate) 
);

CREATE OR REPLACE VIEW workDetails AS(
SELECT DISTINCT p.uid as uid,
		EXTRACT(YEAR FROM WD.workDate) as year, 
        EXTRACT(Month FROM WD.workDate) as month, 
        sum(DATE_PART('hour', WD.intervalEnd - WD.intervalStart)) as totalHours,
		sum(WD.numCompleted) as numCompleted
FROM PartTime P INNER JOIN WorkingDays WD USING (uid) 
-- WHERE WD.numCompleted > 0 
GROUP BY P.uid, EXTRACT(YEAR FROM WD.workDate), EXTRACT(Month FROM WD.workDate)
UNION
SELECT distinct F.uid as uid,
		EXTRACT(YEAR FROM WW.workDate) as year, 
		EXTRACT(Month FROM WW.workDate) as month, 
		count(shiftID) * 8 as totalHours,
		sum(WW.numCompleted) as numCompleted
FROM FullTime F INNER JOIN WorkingWeeks WW USING (uid) 
-- WHERE WW.numCompleted > 0 
GROUP BY F.uid, EXTRACT(YEAR FROM WW.workDate), EXTRACT(Month FROM WW.workDate)
);

CREATE OR REPLACE VIEW driverSalary AS (
SELECT CP.puid as uid,
	   CP.pYear as year, 
       CP.pMonth as month, 
       CP.pComplete * DR.baseDeliveryFee + CP.totalWeeksWorked * CP.pBasePay as monthSalary 
FROM ConsolidateP CP RIGHT JOIN DeliveryRiders DR on DR.uid = CP.pUid 
UNION
SELECT CF.fuid as uid,
       CF.fYear as year, 
       CF.fMonth as month, 
       CF.fCompleted * DR.baseDeliveryFee + CF.fBasePay as monthSalary 
FROM DeliveryRiders DR LEFT JOIN ConsolidateF CF on DR.uid = CF.fUid 
);

/* To view individual schedule on a monthly basis */
CREATE OR REPLACE VIEW IndiRiderShed AS(
	with Alldate as(
		select generate_series(
           	(date '2019-01-01')::timestamp,
           	(date '2022-12-31')::timestamp,
           	interval '1 day'
         	) as ddate
        )
	SELECT distinct A.ddate as ddate,WD.uid as uid,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='10:00:00' AND W.intervalEnd>'10:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t10,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='11:00:00' AND W.intervalEnd>'11:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t11,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='12:00:00' AND W.intervalEnd>'12:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t12,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='13:00:00' AND W.intervalEnd>'13:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t13,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='14:00:00' AND W.intervalEnd>'14:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t14,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='15:00:00' AND W.intervalEnd>'15:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t15,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='16:00:00' AND W.intervalEnd>'16:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t16,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='17:00:00' AND W.intervalEnd>'17:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t17,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='18:00:00' AND W.intervalEnd>'18:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t18,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='19:00:00' AND W.intervalEnd>'19:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t19,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='20:00:00' AND W.intervalEnd>'20:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t20,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='21:00:00' AND W.intervalEnd>'21:00:00' and W.workDate = A.ddate and WD.uid=W.uid) as t21
	FROM AllDate A Join WorkingDays WD ON (A.ddate = WD.workDate)
	UNION 
	SELECT distinct A.ddate as ddate,WW.uid as uid,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND W.shiftID = 1) as t10,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2)) as t11,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3)) as t12,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3 OR W.shiftID =4)) as t13,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 2 OR W.shiftID =3 OR W.shiftID =4)) as t14,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =3 OR W.shiftID =4)) as t15,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =4)) as t16,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3)) as t17,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3 OR W.shiftID =4)) as t18,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 2 OR W.shiftID =3 OR W.shiftID =4)) as t19,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 3 OR W.shiftID =4)) as t20,
		(SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = A.ddate AND WW.uid=W.uid AND (W.shiftID = 4)) as t21
	FROM AllDate A Join WorkingWeeks WW ON (A.ddate = WW.workDate)
    UNION
    SELECT 	distinct A.ddate, 0 as uid, 0 as t10, 0 as t11,0 as t12,0 as t13,0 as t14,0 as t15,0 as t16,0 as t17,0 as t18,0 as t19,0 as t20,0 as t21
	FROM AllDate A 
);

-- Rider's Schedule Overview
CREATE OR REPLACE VIEW Overview AS(
	with Alldate as(
	select generate_series(
           (date '2019-01-01')::timestamp,
           (date '2022-12-31')::timestamp,
           interval '1 day'
         ) as ddate
	)

	SELECT ddate as ddate,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='10:00:00' AND W.intervalEnd>'10:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND W.shiftID = 1) as t10,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='11:00:00' AND W.intervalEnd>'11:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2)) as t11,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='12:00:00' AND W.intervalEnd>'12:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3)) as t12,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='13:00:00' AND W.intervalEnd>'13:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3 OR W.shiftID =4)) as t13,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='14:00:00' AND W.intervalEnd>'14:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 2 OR W.shiftID =3 OR W.shiftID =4)) as t14,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='15:00:00' AND W.intervalEnd>'15:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =3 OR W.shiftID =4)) as t15,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='16:00:00' AND W.intervalEnd>'16:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =4)) as t16,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='17:00:00' AND W.intervalEnd>'17:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3)) as t17,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='18:00:00' AND W.intervalEnd>'18:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 1 OR W.shiftID =2 OR W.shiftID =3 OR W.shiftID =4)) as t18,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='19:00:00' AND W.intervalEnd>'19:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 2 OR W.shiftID =3 OR W.shiftID =4)) as t19,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='20:00:00' AND W.intervalEnd>'20:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 3 OR W.shiftID =4)) as t20,
		(SELECT count(*) FROM WorkingDays W WHERE W.intervalStart<='21:00:00' AND W.intervalEnd>'21:00:00' and W.workDate = D.ddate) +  (SELECT count(*) FROM WorkingWeeks W WHERE W.workDate = D.ddate AND (W.shiftID = 4)) as t21
	FROM AllDate D	
);

-- Rider's Overall Review
CREATE OR REPLACE VIEW ReviewInfo AS (
SELECT distinct DR.uid, EXTRACT(Year FROM (O.date)) AS year, EXTRACT(Month FROM 
(O.date)) as month, count(D.rating) as totalRatings, ROUND(avg(D.rating),1) as avgRatings,  
to_char(avg(O.timeOrderDelivered - O.timeOrderPlace), 'HH24:MI:SS') as avgDuration
FROM DeliveryRiders DR LEFT JOIN Delivers D on DR.uid = D.uid LEFT JOIN Orders O on D.orderID = O.orderID 
GROUP BY DR.uid, year, month
);

CREATE OR REPLACE VIEW monthlyWorkingHours AS (
SELECT W.uid, EXTRACT(year from W.workdate) as year, EXTRACT(month from W.workdate) as month, W.workdate, W.intervalstart, W.intervalend, WD.totalhours as monthlytotalhours 
FROM workingdays W JOIN workdetails WD 
ON W.uid = WD.uid 
AND extract(year from W.workdate) = WD.year 
AND extract(month from W.workdate) = WD.month
);

CREATE OR REPLACE VIEW weekSummary AS (
SELECT DISTINCT p.uid as uid,
EXTRACT(YEAR FROM WD.workDate) as year, 
EXTRACT(Week FROM WD.workDate) as week, 
SUM(DATE_PART('hour', WD.intervalEnd - WD.intervalStart)) as totalHours
FROM PartTime P INNER JOIN WorkingDays WD USING (uid) 
GROUP BY P.uid, EXTRACT(YEAR FROM WD.workDate),EXTRACT(Week FROM WD.workDate)
);

CREATE OR REPLACE VIEW PartTimeOverview AS (
select T.uid as uid, 
W.workDate as date, 
W.intervalStart as start , 
W.intervalEnd as end, 
coalesce((SELECT totalHours From weekSummary S where S.uid = W.uid and EXTRACT(YEAR FROM W.workDate) = S.year AND EXTRACT(Week FROM W.workDate) = S.week),0) as weekhours
FROM PartTime T LEFT JOIN WorkingDays W USING (uid) order by uid
);

/* Deliery rider Summary in another form */
create view allocate as(
SELECT uid, ddate, TIME'10:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t10=1
UNION
SELECT uid, ddate, TIME'11:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t11=1
UNION
SELECT uid, ddate, TIME'12:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t12=1
UNION
SELECT uid, ddate, TIME'13:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t13=1
UNION
SELECT uid, ddate, TIME'14:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t14=1
UNION
SELECT uid, ddate, TIME'15:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t15=1
UNION
SELECT uid, ddate, TIME'16:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t16=1
UNION
SELECT uid, ddate, TIME'17:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t17=1
UNION
SELECT uid, ddate, TIME'18:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t18=1
UNION
SELECT uid, ddate, TIME'19:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t19=1
UNION
SELECT uid, ddate, TIME'20:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t20=1
UNION
SELECT uid, ddate, TIME'21:00:00' as worktime
FROM IndiRiderShed
WHERE uid !=0 and t21=1);

/*Leave this trigger at the bottom to prevent interference with manual insert statements*/
CREATE OR REPLACE FUNCTION check_riders()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;

BEGIN
    IF (NEW.type = 'FullTime') THEN
        SELECT COUNT(*) INTO count 
        FROM PartTime 
        WHERE NEW.uid = PartTime.uid;
        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO FullTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Full time rider added';
            RETURN NEW;
        END IF;

    ELSIF (NEW.type = 'PartTime') THEN
        SELECT COUNT(*) INTO count 
        FROM FullTime 
        WHERE NEW.uid = FullTime.uid;

        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO PartTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Part time rider added';
            RETURN NEW;
        END IF;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER riders_trigger
AFTER INSERT ON DeliveryRiders 
FOR EACH ROW
EXECUTE FUNCTION check_riders();

/*check whether order placed during operational hours*/
CREATE OR REPLACE FUNCTION check_operational_hours() 
RETURNS TRIGGER AS $$
DECLARE currHour NUMERIC;
DECLARE openingHour NUMERIC;
DECLARE closingHour NUMERIC;

BEGIN
    openingHour := 10; --10am
    closingHour := 22; --10pm
    
    SELECT EXTRACT(HOUR from timeOrderPlace) INTO currHour
    FROM Orders
    WHERE NEW.orderID = Orders.OrderID;

    IF currHour < openingHour THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE NEW.orderID = Orders.OrderID;
        RAISE NOTICE 'Not within Opening Hours';
        RETURN NULL; 
    ELSIF currHour >= closingHour THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE NEW.orderID = Orders.OrderID; 
        RAISE NOTICE 'Not within Opening Hours';
        RETURN NULL; --RETURN NULL instead of RETURN NEW to just abort the inserted row silently without raising an exception and without rolling anything back.
    ELSE 
        RAISE NOTICE 'Within Opening Hours';
        RETURN NEW; 
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER operating_trigger
BEFORE INSERT ON Place
FOR EACH ROW
EXECUTE FUNCTION check_operational_hours();

/*check availability*/
CREATE OR REPLACE FUNCTION check_availability()
RETURNS TRIGGER AS $$
DECLARE currAvailability INTEGER;
DECLARE qtyOrdered INTEGER;
DECLARE oDate Date;
DECLARE oTime INTEGER;
DECLARE riderID INTEGER;
DECLARE checker INTEGER;

BEGIN
    qtyOrdered := NEW.quantity;

    SELECT dailyLimit into currAvailability 
    FROM Food 
    WHERE Food.foodname = NEW.foodName
    AND Food.restaurantID = NEW.restaurantID;

    SELECT EXTRACT(HOUR FROM O.timeOrderPlace) INTO oTime
    FROM Orders O 
    WHERE O.orderID = NEW.orderID;

    SELECT O.date INTO oDate
    FROM Orders O 
    WHERE O.orderID = NEW.orderID;

    SELECT A.uid INTO riderID
    FROM allocate A 
    WHERE A.ddate = oDate
    AND EXTRACT(HOUR FROM A.worktime) = oTime
    AND A.uid NOT IN (
        SELECT D.uid
        FROM Delivers D JOIN Orders O USING (orderID)
        WHERE O.date = oDate 
        AND (O.orderStatus = 'Confirmed' OR O.orderStatus = 'Pending')
        AND orderID != NEW.orderID
    )
    LIMIT 1;

    SELECT 1 INTO checker
    FROM Delivers DD 
    WHERE DD.orderID = NEW.orderID;

    IF NEW.quantity > currAvailability THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE Orders.orderID = NEW.orderID;
        RAISE NOTICE 'Exceed Daily Limit';
        RETURN NULL;
    ELSIF riderID IS NULL THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE Orders.orderID = NEW.orderID;
        RAISE NOTICE 'No Rider Available';
        RETURN NULL;
    ELSE
        UPDATE Orders SET orderStatus = 'Confirmed' WHERE Orders.orderID = NEW.orderID;
        UPDATE Food SET dailyLimit = dailyLimit - qtyOrdered WHERE Food.foodname = NEW.foodName AND Food.restaurantID = NEW.restaurantID;
        
        IF checker  IS NULL THEN
            INSERT INTO Delivers(orderID,uid) VALUES (NEW.orderID, riderID );
            RAISE NOTICE 'Driver Assigned';
        END IF;

        RAISE NOTICE 'Order Confirmed';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER availability_trigger
AFTER INSERT ON FromMenu
FOR EACH ROW
EXECUTE FUNCTION check_availability();


/*Update reward point after order completion*/
CREATE OR REPLACE FUNCTION update_rewards()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE customerId INTEGER;

BEGIN 
    currStatus := NEW.orderStatus;

    SELECT uid INTO customerId
    FROM Place
    WHERE NEW.orderid = Place.orderid;

    IF currStatus = 'Completed' THEN
        UPDATE Customers 
        SET rewardPts = rewardPts + TRUNC(NEW.cost)
        WHERE customerId = Customers.uid;
    END IF;
    RETURN NULL;


END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reward_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE FUNCTION update_rewards();


/*Update delivery rider number of complete orders after order completion*/
CREATE OR REPLACE FUNCTION update_bonus()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE riderId Integer;
DECLARE riderType VARCHAR(255);

BEGIN
    currStatus := NEW.orderStatus;

    SELECT uid INTO riderId
    FROM Delivers
    WHERE NEW.orderid = Delivers.orderid;

    SELECT type INTO riderType
    FROM DeliveryRiders
    WHERE riderId = DeliveryRiders.uid;

    IF (currStatus = 'Completed') THEN
        IF (riderType = 'FullTime') THEN
            UPDATE WorkingWeeks
            SET numCompleted = numCompleted + 1
            WHERE riderId = WorkingWeeks.uid;
        ELSIF (riderType = 'PartTime') THEN
            UPDATE WorkingDays 
            SET numCompleted = numCompleted + 1
            WHERE riderId = WorkingDays.uid;
        END IF;
    END IF;
    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bonus_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE FUNCTION update_bonus(); 

/*ensure one hour shift, check overlap*/
CREATE OR REPLACE FUNCTION check_shift()
RETURNS TRIGGER AS $$
DECLARE currShiftEnd NUMERIC;
DECLARE newShiftStart NUMERIC;

BEGIN
    IF EXISTS(
          SELECT 1 
          FROM workingDays W 
          WHERE NEW.uid = W.uid
          AND NEW.WorkDate = w.workDate
          AND ((W.intervalStart <= NEW.intervalStart AND NEW.intervalStart<(W.intervalEnd + INTERVAL'1 hour'))
          OR (W.intervalStart<(NEW.intervalEnd + INTERVAL'1 hour') AND NEW.intervalEnd<=W.intervalEnd))
          )
    THEN
        RAISE EXCEPTION 'Overlap in Time or 1 hour break not enforced';
    ELSE 
        RAISE NOTICE 'Successfully Inserted';
        RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_shift_trigger
BEFORE INSERT ON WorkingDays
FOR EACH ROW
EXECUTE FUNCTION check_shift();

/* Check that the hour inserted must be >= 10h or <=48h*/
CREATE OR REPLACE FUNCTION check_hours()
RETURNS TRIGGER AS $$
DECLARE hour_in INTEGER;


BEGIN
    SELECT sum(EXTRACT(HOUR FROM w.intervalEnd) - EXTRACT(HOUR FROM w.intervalStart)) INTO hour_in
    FROM workingDays W
    WHERE EXTRACT(WEEK FROM w.WorkDate) = EXTRACT(WEEK FROM NEW.WorkDate)
    AND NEW.uid = W.uid;

    IF (hour_in) < 10 THEN
        RAISE EXCEPTION 'Insufficient hours for the week (<10h)';
    ELSIF (hour_in) >48 THEN 
        RAISE EXCEPTION '<Exceeded hours for the week (>48h)';
    ELSE
        RAISE NOTICE 'Succesfully Inserted';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;
        
        
CREATE CONSTRAINT TRIGGER work_hours_trigger
AFTER INSERT ON WorkingDays
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_hours();

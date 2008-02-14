CREATE TABLE karma (
  karma_id    INTEGER PRIMARY KEY,
  subject     VARCHAR (255),
  user        VARCHAR (255),
  amount      INTEGER
);

CREATE TABLE factoid (
  factoid_id  INTEGER PRIMARY KEY,
  is_or       INTEGER,
  is_plural   INTEGER,
  created     INTEGER,
  updated     INTEGER,
  silent      INTEGER,
  subject     VARCHAR (255)
);

CREATE TABLE factoid_description (
  factoid_id  INTEGER,
  updated     INTEGER,
  hash        CHAR (40),
  user        VARCHAR (255),
  description TEXT
);

CREATE TABLE factoid_ignore (
  subject     VARCHAR (255)
);

CREATE TABLE seen (
  seen_id     INTEGER PRIMARY KEY,
  timestamp   INTEGER,
  user        VARCHAR (255),
  message     TEXT
);

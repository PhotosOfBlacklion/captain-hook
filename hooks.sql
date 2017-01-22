DROP TABLE IF EXISTS files;
CREATE TABLE files (
  id int(11)NOT NULL AUTO_INCREMENT,
  path varchar(255) NOT NULL UNIQUE,
  processed bool NOT NULL DEFAULT FALSE,
  created_at datetime,
  updated_at datetime,
  PRIMARY KEY(id)
);

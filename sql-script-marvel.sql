####
database-1.crfo6vjrtboh.eu-west-3.rds.amazonaws.com
postgres


CREATE TABLE marvell_employees (
  id INT PRIMARY KEY,
  name VARCHAR(50),
  salary INT CHECK (salary > 0),
  hire_date DATE CHECK (hire_date >= '1970-01-01')
);

INSERT INTO marvell_employees Values (1, 'John', 	50000, '2000-01-12');
INSERT INTO marvell_employees Values  (2, 'Sara',	60000, '2005-05-24');
INSERT INTO marvell_employees Values (3, 'Jack', 	45000, '1989-08-09');
INSERT INTO marvell_employees Values  (4, 'Sam',	70000, '1998-05-14');
INSERT INTO marvell_employees Values  (42, 'Godwin tete',	72300, '1978-05-14');
INSERT INTO marvell_employees Values  (21, 'Diego Akodegnon',	90000, '1988-09-24');
INSERT INTO marvell_employees Values (22, 'Barnabe Chucky', 	25800, '2002-07-05');


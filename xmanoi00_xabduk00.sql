--Making sure no table exist at the time we start working
DROP TABLE LETENKA;
DROP TABLE POZADAVEK;
DROP TABLE LETISTE;
DROP TABLE KLIENT;
DROP SEQUENCE pozadavek_id_seq;
DROP PROCEDURE cancel_flights;
DROP PROCEDURE give_discount;
DROP INDEX indexExplain;
DROP MATERIALIZED VIEW addresses;

--Creating tables
CREATE TABLE Klient (
  email    varchar(45) not null,
  jmeno    varchar(45) not null,
  prijmeni varchar(45) not null,
  adresa   varchar(45) not null,
  CONSTRAINT pk_klient PRIMARY KEY (email)
);

CREATE TABLE Letiste (
  zkratka       varchar(3)  not null,
  dalsi_letiste varchar(3),
  lokace        varchar(45) not null,
  CONSTRAINT pk_letiste PRIMARY KEY (zkratka),
  CONSTRAINT dalsi_letiste_fk FOREIGN KEY (dalsi_letiste) REFERENCES Letiste (zkratka)
);

CREATE TABLE Pozadavek (
  id                 numeric(10),
  email_klienta      varchar(45) not null,
  zkratka_letiste_od varchar(3)  not null,
  zkratka_letiste_do varchar(3)  not null,
  datum              date        not null,
  cas                varchar(8)  not null,
  kategorie          smallint    not null,
  pocet_lidi         smallint    not null,
  potvrzena          varchar(1)  not null,
  CONSTRAINT pk_pozadavek PRIMARY KEY (id),
  CONSTRAINT email_cons FOREIGN KEY (email_klienta) REFERENCES Klient (email),
  CONSTRAINT letiste_od_cons FOREIGN KEY (zkratka_letiste_od) REFERENCES Letiste (zkratka),
  CONSTRAINT letiste_do_cons FOREIGN KEY (zkratka_letiste_do) REFERENCES Letiste (zkratka)

);

CREATE SEQUENCE pozadavek_id_seq
  START WITH 1;

CREATE TABLE Letenka (
  id_pozadavek  numeric PRIMARY KEY  REFERENCES Pozadavek (id) ON DELETE CASCADE,
  email_klienta varchar(45) not null,
  zaplacena     varchar(1)  not null,
  cena          numeric(10) not null,
  CONSTRAINT letenka_klient_cons FOREIGN KEY (email_klienta) REFERENCES KLIENT (email)
);

--TRIGGER
create or replace TRIGGER trigger_klient
  BEFORE INSERT OR UPDATE OF email
  ON klient
  FOR EACH ROW
  DECLARE
    klientEM        varchar(45);
    unikatni_cast   varchar(45);
    at_pos          int(20);
    dot_pos         int(20);
    schranka        varchar(15);
    domena_schranky varchar(10);
  BEGIN
    klientEM := :NEW.email;
    at_pos := INSTR(klientEM, '@');
    unikatni_cast := SUBSTR(klientEM, 1, at_pos - 1);
    dot_pos := INSTR(klientEM, '.', -1);
    domena_schranky := SUBSTR(klientEM, INSTR(klientEM, '.', -1) + 1);
    schranka := SUBSTR(klientEM, at_pos + 1, dot_pos - at_pos - 1);

    IF (LENGTH(schranka) IS NULL)
    THEN
      Raise_Application_Error(-1999, 'Your email must contain an mailbox name');
    END IF;
    IF (LENGTH(domena_schranky) IS NULL)
    THEN
      Raise_Application_Error(-1999, 'Your email must contain a domen address');
    END IF;
    IF (LENGTH(unikatni_cast) IS NULL)
    THEN
      Raise_Application_Error(-1999, 'Your email must contain an user mail');
    END IF;
  END;
/

CREATE OR REPLACE TRIGGER pozadavek_id_inc
  BEFORE INSERT
  ON Pozadavek
  FOR EACH ROW
  BEGIN
    SELECT pozadavek_id_seq.nextval
    INTO :new.id
    FROM dual;
  end;
/
--FILLING EM TABLES
INSERT INTO Letiste
VALUES ('BRQ', NULL, 'Brno, Czechia');

INSERT INTO LETISTE
VALUES ('STN', NULL, 'London Stansted');

INSERT INTO KLIENT
values ('ivan@gmail.com', 'Ivan', 'NeManoilov', 'Bozetechova 2');

INSERT INTO KLIENT
values ('abduk@gmail.com', 'NeFarrukh', 'Abdukhalikov', 'Kolejni 4');

INSERT INTO KLIENT
values ('xmanoi00@stud.fit.vutbr.cz', 'Ivan', 'Manoilov', 'Kolejni 2');

INSERT INTO KLIENT
values ('xabduk00@stud.fit.vutbr.cz', 'Farrukh', 'Abdukhalikov', 'Kolejni 2');

INSERT INTO pozadavek
values (NULL, 'xmanoi00@stud.fit.vutbr.cz', 'BRQ', 'STN', TO_DATE('2018-04-01', 'YYYY-MM-DD'), '16:00', 1, 2, '1');

INSERT INTO pozadavek
values (NULL, 'xmanoi00@stud.fit.vutbr.cz', 'BRQ', 'STN', TO_DATE('2018-04-03', 'YYYY-MM-DD'), '16:00', 1, 1, '1');

INSERT INTO pozadavek
values (NULL, 'abduk@gmail.com', 'BRQ', 'STN', TO_DATE('2018-04-12', 'YYYY-MM-DD'), '16:00', 1, 2, '1');

INSERT INTO pozadavek
values (NULL, 'abduk@gmail.com', 'STN', 'BRQ', TO_DATE('2018-04-05', 'YYYY-MM-DD'), '16:00', 1, 1, '1');

INSERT INTO pozadavek
values (NULL, 'ivan@gmail.com', 'STN', 'BRQ', TO_DATE('2018-04-16', 'YYYY-MM-DD'), '16:00', 1, 2, '1');

INSERT INTO letenka
values (1, 'xmanoi00@stud.fit.vutbr.cz', '1', 2050);

INSERT INTO letenka
values (2, 'xmanoi00@stud.fit.vutbr.cz', '1', 322);

INSERT INTO letenka
values (3, 'abduk@gmail.com', '1', 4000);

INSERT INTO letenka
values (4, 'abduk@gmail.com', '1', 1564);

INSERT INTO letenka
values (5, 'ivan@gmail.com', '1', 3245);

--Vybere email vsech klientu, ktery leti z Brna do Londyna Stansted
SELECT DISTINCT K.email
FROM KLIENT K, POZADAVEK P
WHERE P.EMAIL_KLIENTA = K.EMAIL and P.ZKRATKA_LETISTE_OD = 'BRQ' and P.ZKRATKA_LETISTE_DO = 'STN';

--Vybere email vsech klientu, ktery leti z Brna 12.04.2018
SELECT DISTINCT K.email
FROM KLIENT K, POZADAVEK P
WHERE P.EMAIL_KLIENTA = K.EMAIL and P.ZKRATKA_LETISTE_OD = 'BRQ' and P.DATUM = TO_DATE('2018-04-12', 'YYYY-MM-DD');

--Vybere email vsech klientu, ktery zaplatili za letenku do Londyna vic nez 3000
SELECT DISTINCT K.email
FROM KLIENT K, POZADAVEK P, LETENKA L
WHERE K.EMAIL = P.EMAIL_KLIENTA and P.ZKRATKA_LETISTE_DO = 'STN' and P.ID = L.ID_POZADAVEK and L.CENA > 3000;

--Vybere email vsech klientu, ktery leti z Brna a bydli na Kolejni 2
SELECT DISTINCT COUNT(K.email)
FROM KLIENT K, POZADAVEK P
WHERE P.EMAIL_KLIENTA = K.EMAIL and P.ZKRATKA_LETISTE_OD = 'BRQ' and K.ADRESA = 'Kolejni 2'
GROUP BY K.EMAIL;

--Slozi dohromady vsechny letenky lide, ktery bydli na Kolejni 2
SELECT DISTINCT SUM(L.CENA)
FROM KLIENT K, POZADAVEK P, LETENKA L
WHERE P.EMAIL_KLIENTA = K.EMAIL and K.ADRESA = 'Kolejni 2' and P.ID = L.ID_POZADAVEK
GROUP BY K.EMAIL;

--Vybere email vsech klientu, ktery zaplatili za letenku do Londyna vic nez 3000
SELECT DISTINCT K.email
FROM KLIENT K
WHERE EXISTS(SELECT P.ID
             FROM POZADAVEK P, LETENKA L
             WHERE
               K.EMAIL = P.EMAIL_KLIENTA and P.ZKRATKA_LETISTE_DO = 'STN' and P.ID = L.ID_POZADAVEK and L.CENA < 599);


Vybere emaily vsech klientu, ktery maji jmeno mezi timi jmeny, co maji lide ktery bydli na Bozetechove 2....
SELECT DISTINCT K.email
FROM KLIENT K
WHERE K.JMENO IN (SELECT K.JMENO
                  FROM KLIENT K
                  WHERE K.adresa = 'Bozetechova 2');


SELECT DISTINCT
  p.id,
  p.zkratka_letiste_od,
  l.id_pozadavek,
  l.cena
FROM Pozadavek p, Letenka l;


CREATE OR REPLACE PROCEDURE give_discount(
  adresa_klienta in Klient.adresa%type,
  discount       in float
) is

  l_id Letenka.id_pozadavek%type;
    negative_discount exception;

  BEGIN

    if discount >= 1.0
    then
      RAISE negative_discount;
    end if;

    UPDATE Letenka
    SET Letenka.cena = Letenka.cena * discount
    where id_pozadavek in (SELECT DISTINCT p.id
                           FROM KLIENT K, POZADAVEK P, LETENKA L
                           WHERE K.ADRESA = adresa_klienta and P.EMAIL_KLIENTA = K.EMAIL and P.ID = L.ID_POZADAVEK);

    commit;

    exception
    WHEN OTHERS
    then
      DBMS_OUTPUT.PUT_LINE('DISCOUNT IS GOING TO INCREASE THE PRICE');
  end;
/

CREATE OR REPLACE PROCEDURE cancel_flights(
  letiste_od Letiste.zkratka%type
) is

  poz_id Pozadavek.id%type;

  CURSOR flights_id
  IS
    SELECT p.id
    FROM Pozadavek p
    WHERE p.zkratka_letiste_od = letiste_od;

  begin
    open flights_id;

    LOOP
      FETCH flights_id INTO poz_id;
      EXIT WHEN flights_id%NOTFOUND;

      delete from Letenka
      where id_pozadavek = poz_id;

      delete from Pozadavek
      where id = poz_id;

    end loop;
    close flights_id;
  end;
/

begin
  give_discount('Kolejni 2', 0.5);
end;
/

begin
  cancel_flights('STN');
end;
/

SELECT DISTINCT
  p.id,
  p.zkratka_letiste_od,
  l.id_pozadavek,
  l.cena
FROM Pozadavek p, Letenka l;

--EXPLAIN + INDEX
EXPLAIN PLAN FOR
SELECT k.jmeno,l.cena
FROM Klient k NATURAL JOIN Letenka l
GROUP BY jmeno,cena;
SELECT * FROM TABLE(DBMS_XPLAN.display);

CREATE INDEX indexExplain ON Klient (jmeno) ;

--EXPLAIN PLAN FOR --WITH INDEX
SELECT k.jmeno,l.cena
FROM Klient k NATURAL JOIN Letenka l
GROUP BY jmeno,cena;
--SELECT * FROM TABLE(DBMS_XPLAN.display);

--RIGHTS
GRANT ALL ON Klient TO xabduk00;
GRANT ALL ON Letenka TO xabduk00;
GRANT ALL ON Letiste TO xabduk00;
GRANT ALL ON Pozadavek TO xabduk00;

GRANT EXECUTE ON CANCEL_FLIGHTS TO xabduk00;
GRANT EXECUTE ON GIVE_DISCOUNT TO xabduk00;

--VIEW
CREATE MATERIALIZED VIEW LOG ON Klient with ROWID(email,jmeno,prijmeni,adresa) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW addresses
CACHE
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
ENABLE QUERY REWRITE
AS SELECT k.adresa
FROM Klient k
GROUP BY k.adresa;

GRANT ALL ON addresses TO xabduk00;

SELECT * from addresses;
INSERT INTO Klient
VALUES('abc@abq.com','AB', 'CD', 'Masarykova 4');
COMMIT;
SELECT * from addresses;
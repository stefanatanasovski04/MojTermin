--------------------------------------------------------------------Kreiranje Tabeli----------------------------------------------------------------------------------------------
-- Doktor ( id_doktor, embg, ime, prezime )
create table Doktor(
   id_doktor serial primary key,
   embg char(13) not null unique ,
   ime varchar(100) not null,
   prezime varchar(100) not null
);


--Specijalizacija ( id_Specijalizacija, oblastSpecijalizacija )
create table Specijalizacija(
   id_specijalizacija serial primary key,
   oblast_specijalizacija varchar(50) not null
);


-- Specijalist ( id_doktor *(Doktor), institutSpecijalizacija, datumSpecijalizacija ,
--id_Specijalizacija * ( Specijalizacija ) )
create table Specijalist(
   id_doktor integer primary key,
   institut_Specijalizacija varchar(100) not null,
   datum_specijalizacija date not null,
   id_specijalizacija integer not null ,
   constraint fk_specijalist_doktor foreign key (id_doktor)
      references Doktor(id_doktor),
   constraint fk_specijalizacija_specijalist foreign key (id_specijalizacija)
        references Specijalizacija(id_specijalizacija)
);


--Matichen ( id_doktor*(Doktor), zamenaMaticen, adresaOrdinacija  )
create table Matichen(
   id_doktor integer primary key,
   zamena_matichen varchar(100) not null,
   adresa_ordinacija varchar(100) not null,
   constraint fk_matichen_doktor foreign key (id_doktor)
      references Doktor(id_doktor)
);


--Pacient ( id_Pacient , embg, ime, prezime, id_Doktor *(Matichen)  )
create table Pacient(
   id_pacient serial primary key,
   embg char(13) not null unique ,
   ime varchar(100) not null,
   prezime varchar(100) not null,
   id_matichen_pacient integer not null,
   constraint fk_matichen_pacient foreign key (id_matichen_pacient)
      references Matichen(id_doktor)
);


--Termin ( id_Termin, vreme, datum, daliEZakazan, id_Upat*(Upat), id_Doktor *( Specijalist ))
create table Termin(
    id_termin serial primary key ,
    vreme time not null ,
    datum date not null ,
    daliEZakazan bit,
    id_doktor_specijalist integer not null ,
    constraint fk_upat_specijalist foreign key (id_doktor_specijalist)
        references Specijalist(id_doktor)

);


--Upat ( id_Upat, id_Termin *( Termin ), id_Pacient *( Pacient ),
-- id_Doktor_Matichen *( Matichen ), id_Doktor_Specijalist *( Specijalist ) )
create table Upat(
    id_upat serial primary key ,
    id_termin integer not null ,
    id_pacient integer not null ,
    id_matichen_doktor integer not null ,
    id_specijalist_doktor integer not null ,
    dijagnoza_matichen varchar(300),
    dijagnoza_specijalist varchar(300),
    izveshtaj varchar(300),

    constraint fk_termin_upat foreign key (id_termin)
                 references Termin(id_termin),
    constraint fk_pacient_upat foreign key (id_pacient)
                 references Pacient(id_pacient),
    constraint fk_matichen_upat foreign key (id_matichen_doktor)
                 references Matichen(id_doktor),
    constraint fk_specijalist_upat foreign key (id_specijalist_doktor)
                 references Specijalist(id_doktor)
);


--TelefonskiBroj ( id_Doktor*(Matichen) , telefonskiBroj)
create table Telefon(
    id_doktor integer,
    telefonski_broj varchar(20),
    constraint pk_telefonski_broj primary key (id_doktor,telefonski_broj),
    constraint fk_telefonski_broj foreign key (id_doktor)
                    references Matichen(id_doktor)
);


--------------------------------------------------------------------------------Views--------------------------------------------------------------------------------------------------
--Матичниот може да ги добие сите слободни термини за да може да закаже--
create view termini_za_matichen as select t.id_termin as id_t,t.datum,t.vreme,t.daliEZakazan,d.prezime as specijalist,spec.id_doktor as id,s.oblast_specijalizacija as specijalizacija from Termin  as t
join doktor as d on t.id_doktor_specijalist = d.id_doktor
join specijalist as spec on d.id_doktor = spec.id_doktor
join specijalizacija s on spec.id_specijalizacija = s.id_specijalizacija
where daliEZakazan = '0' and t.datum::date > now()::date
group by t.id_termin,t.datum,t.vreme,t.daliEZakazan,d.prezime,spec.id_doktor,s.oblast_specijalizacija
order by s.oblast_specijalizacija asc ,t.datum  ,t.vreme asc;

select  * from termini_za_matichen;

--Пациентот може да ги добие сите термини и упати кои му припаѓаат нему--
create view listaj_termini_i_upati_za_pacient  as select p.ime as Ime_P,p.prezime as Prezime_P,
                t.vreme,t.datum,d.prezime as Specijalist, u.dijagnoza_matichen as dijagnoza  from upat as u
join pacient p on u.id_pacient = p.id_pacient
join termin t on u.id_termin = t.id_termin
join specijalist s on t.id_doktor_specijalist = s.id_doktor
join doktor d on s.id_doktor = d.id_doktor;

select * from listaj_mesecni_termini_kaj_specijalist;




--Специјалистот да може да ги добие сите термини со тоа на кој пациент припаѓаат за тековниот ден.
create view  listaj_mesecni_termini_kaj_specijalist as
select D.prezime as Specijalist,t.id_termin,t.vreme,t.datum,extract(Day from now()) as Den ,u.id_upat,p.ime as PacientIme,
       p.prezime as PacientPrezime, u.dijagnoza_matichen as Dijagnoza from Specijalist as s
join Doktor D on D.id_doktor = s.id_doktor
join  Termin T on s.id_doktor = T.id_doktor_specijalist
join Upat U on u.id_termin = T.id_termin
join Pacient P on U.id_pacient = P.id_pacient
where --extract(DAY from t.datum) = extract(DAY from now())  and
extract(Month from t.datum) = extract(Month from now())
        and extract(Year from t.datum) = extract(Year from now());















----------------------------------------------------------------------------Formi so Proceduri---------------------------------------------------------------------------------------------------

create or replace procedure vnesi_doktor(
    m_broj char(13),
    name varchar(50),
    last_name varchar(50)
)
language plpgsql
as $$
    begin
        insert into doktor(embg, ime, prezime)
        values (
                m_broj,
                name,
                last_name
                );
        commit;
    end;
$$;

create or replace procedure vnesi_specijalizacija(
    tip_specijalizacija varchar(50)
    )
    language plpgsql
    as $$
    begin
    insert into specijalizacija(oblast_specijalizacija)
    values (tip_specijalizacija);

    commit;
    end;
$$;

create or replace procedure vnesi_specijalist_doktor(
    id integer,
    kade_specijaliziral varchar(100),
    datum date,
    shto_specijaliziral integer
    )
    language plpgsql
    as $$
    begin
        insert into specijalist(id_doktor, institut_Specijalizacija,
                                datum_specijalizacija, id_specijalizacija)
        values (id,kade_specijaliziral,datum,shto_specijaliziral);
    end;
$$;

create or replace procedure vnesi_marichen_doktor(
    id integer,
    zamena varchar(100),
    adresa varchar(100)
    )
    language plpgsql
    as $$
    begin
        insert into matichen(id_doktor, zamena_matichen, adresa_ordinacija)
        values (id,zamena,adresa);
    end;
$$;

create or replace procedure vnesi_pacient(
    m_broj char(13),
    name varchar(100),
    last_name varchar(100),
    matichen integer
    )
    language plpgsql
    as $$
    begin
        insert into pacient(embg, ime, prezime, id_matichen_pacient)
        values (m_broj,name,last_name,matichen);
    end;
$$;

create or replace procedure vnesi_mobilen_telefon(
    maticen integer,
    broj varchar(20)
    )
    language plpgsql
    as $$
    begin
        insert into telefon(id_doktor, telefonski_broj)
        values (maticen,broj);
    end;
$$;

create or replace procedure objavi_termini(
    vo_kolku time,
    koga date,
    zakazan bit,
    specijalist integer
    )
    language plpgsql
    as $$
    begin
        insert into termin(vreme, datum, daliEZakazan, id_doktor_specijalist)
        values (vo_kolku,koga,zakazan,specijalist);
    end;
$$;

create or replace procedure generiraj_upat(
    termin integer,
    pac integer,
    mat integer,
    specijalist integer,
    dijagnoza_m varchar(300)
    )
    language plpgsql
    as $$
    #variable_conflict use_variable
    begin

       -- insert into upat (id_matichen_doktor) values ((select id_matichen_pacient from pacient where id_pacient = pac));
        insert into upat(id_termin, id_pacient,id_matichen_doktor, id_specijalist_doktor,
                         dijagnoza_matichen)
        values (termin,pac, mat,specijalist,dijagnoza_m);

        update termin set daliezakazan = '1'
        where id_termin = termin;

    end;
$$;



create or replace procedure specijalist_vnesuva_izveshtaj(
    id integer,
    koj_vnesuva integer,
    dijagnoza_s varchar(300),
    izveshtaj_s varchar(300)
    )
    language plpgsql
    as $$
    begin
        update upat set dijagnoza_specijalist = dijagnoza_s,
                    izveshtaj = izveshtaj_s
        where id_specijalist_doktor = koj_vnesuva and id = id_upat;
    end;
$$;








-----------------------------------------------------------------------------------Inserti----------------------------------------------------------------------------------------
--Doktori--
call vnesi_doktor('0101966410001', 'Petko', 'Petkovski' );
call vnesi_doktor('0202966410002', 'Trajko', 'Trajkovski');
call vnesi_doktor('1202977415033', 'Jana', 'Janevska');
call vnesi_doktor('0407990415017', 'Jovana', 'Jovanovska');
call vnesi_doktor('0101969410021', 'Jonko', 'Jonkovski');
call vnesi_doktor('0504980415202', 'Angela', 'Angelovska');
call vnesi_doktor('0301969410005', 'Mile', 'Milevski');
call vnesi_doktor('0103969410063', 'Dzvonko', 'Dzvonkovski');
call vnesi_doktor('0705989415013', 'Milka', 'Milkovska');
call vnesi_doktor('2111978415015', 'Eva', 'Evovska');


--Matichni--
call vnesi_marichen_doktor( 1, 'Pavle Bozinovski', 'Partizanski Odredi 44' );
call vnesi_marichen_doktor( 2, 'Blazo Blazevski', 'Ruzveltova 28' );
call vnesi_marichen_doktor( 3, 'Jonce Presilski', 'Solunska 13A' );
call vnesi_marichen_doktor( 4, 'Gabriela Gavranovska', 'Deveani 105' );
call vnesi_marichen_doktor( 5, 'Jule Julevska', 'Ilindenska 234' );


--Tipovi Na Specijalizacija--
call vnesi_specijalizacija('Kozno');
call vnesi_specijalizacija('Ocno');
call vnesi_specijalizacija('Hirurgija');
call vnesi_specijalizacija('Pedijatrija');
call vnesi_specijalizacija('Nevrologija');


--Specijalisti--
call vnesi_specijalist_doktor(6, 'Bolnica Trifun Panovski', '2005-10-23'::date, 1);
call vnesi_specijalist_doktor(7, 'Bolnica Filip II','1989-03-21'::date , 3);
call vnesi_specijalist_doktor(8, 'Bolnica 8 Semptemvri', '1998-07-01'::date, 3);
call vnesi_specijalist_doktor(9,'Bolnica Trifun Panovski', '2000-05-18'::date, 2);
call vnesi_specijalist_doktor(10, 'Bolnica Plodost', (now()-interval '7 years')::date, 5);


--Telefonski broevi na Matichen--
call vnesi_mobilen_telefon(1, '075555468');
call vnesi_mobilen_telefon(2, '076666499');
call vnesi_mobilen_telefon(3, '071555333');
call vnesi_mobilen_telefon(4, '077525411');
call vnesi_mobilen_telefon(5, '072525399');
call vnesi_mobilen_telefon(2, '075525502');
call vnesi_mobilen_telefon(2, '074333444');
call vnesi_mobilen_telefon(4, '076111015');


--Vnesuvanje na Pacienti--
call vnesi_pacient( '2905000410007', 'Leo', 'Trajcev', 1 );
call vnesi_pacient( '2905000410008', 'Teo', 'Teonov', 2 );
call vnesi_pacient( '2905000410009', 'Todor', 'Todorov', 3 );
call vnesi_pacient( '2905000415010', 'Marija', 'Ristevska', 4 );
call vnesi_pacient( '2905000415011', 'Tea', 'Trajanovska', 5 );
call vnesi_pacient( '2905999410001', 'Risto', 'Jonchevski', 5 );
call vnesi_pacient( '2905999410002', 'Jonko', 'Jonkovski', 4 );
call vnesi_pacient( '2905999410003', 'Chento', 'Chentovski', 3 );
call vnesi_pacient( '2905999415001', 'Ana', 'Zdravkova', 3 );
call vnesi_pacient( '2905999415002', 'Melila', 'Krstevska', 1 );


--Objavi Termini__
call objavi_termini('08:00','2022-12-25','0',6);
call objavi_termini('08:30','2022-12-25','0',6 );
call objavi_termini('09:00','2022-12-25','0',6 );
call objavi_termini('09:30','2022-12-25','0',6 );
call objavi_termini('09:00','2022-12-25','0',7 );
call objavi_termini('09:30','2022-12-25','0',7 );
call objavi_termini('10:00','2022-12-25','0',7 );
call objavi_termini('10:30','2022-12-25','0',7 );
call objavi_termini('11:00','2022-12-25','0',7 );
call objavi_termini('09:30','2022-12-26','0',8 );
call objavi_termini('10:00','2022-12-26','0',8 );
call objavi_termini('10:30','2022-12-26','0',8 );
call objavi_termini('11:00','2022-12-26','0',8 );
call objavi_termini('08:00','2023-01-08','0',9 );
call objavi_termini('08:30','2023-01-08','0',9 );
call objavi_termini('09:00','2023-01-08','0',9 );
call objavi_termini('09:30','2023-01-08','0',9 );
call objavi_termini('08:00','2022-11-25','0',6 );
call objavi_termini('08:30','2022-11-25','0',6 );
call objavi_termini('09:00','2022-11-25','0',6 );
call objavi_termini('09:30','2022-11-25','0',6 );
call objavi_termini('09:00','2022-11-25','0',7 );
call objavi_termini('09:30','2022-11-25','0',7 );
call objavi_termini('10:00','2022-11-25','0',7 );
call objavi_termini('10:30','2022-11-25','0',7 );
call objavi_termini('11:00','2022-11-25','0',7 );
call objavi_termini('09:30','2022-11-26','0',8 );
call objavi_termini('10:00','2022-11-26','0',8 );
call objavi_termini('10:30','2022-11-26','0',8 );
call objavi_termini('11:00','2022-11-26','0',8 );


--Generiraj Upat--
call generiraj_upat(5,1,1,7,'Pojaveno topche nad cipata');
call generiraj_upat(14,1,1,9,'Problemi so vidot');
call generiraj_upat(7,2,2,7,'Bolki vo stomak');
call generiraj_upat(6,3,3,7,'Bolki vo koleno');
call generiraj_upat(23,3,3,7,'Bolki vo grb');


--Vnesi Izveshtaj--
call specijalist_vnesuva_izveshtaj(4,7,'Skinat meniskus','Treba da se napravi operacija na meniskusot');
call specijalist_vnesuva_izveshtaj(1,9,'Oshteten vid', 'Pacientot treba da nosi naochari so diopter 2');


--app properties validate
---------------------------------------------------------------------------------Izveshtai---------------------------------------------------
--Колку упати се спроведени од специјалистот на месечно ниво--
select d.prezime as specijalist, extract(month from t.datum) as mesec, count(*) as sprovedeni_upati from upat as u
left join termin t on u.id_termin = t.id_termin
join specijalist s on t.id_doktor_specijalist = s.id_doktor
join doktor d on s.id_doktor = d.id_doktor
where u.dijagnoza_specijalist is not null and extract(year from t.datum) = 2022
group by 1,2;


--Колку упати се генерирани на ниво на месец од матичниот лекар--
select d.prezime as matichen, extract(month from t.datum) as mesec, count(*) as generirani_upati from upat as up
left join Matichen on up.id_matichen_doktor = Matichen.id_doktor
join doktor d on Matichen.id_doktor = d.id_doktor
join termin t on up.id_termin = t.id_termin
where extract(year from t.datum) = 2022
group by 1,2;


--Колку термини останале слободни по специјалист на месечно ниво
select d.prezime as specijalist,extract(month from ter.datum) as mesec,count(*) as slobodni_termini from termin as ter
left join specijalist as s on ter.id_doktor_specijalist = s.id_doktor
join doktor d on s.id_doktor = d.id_doktor
where ter.daliEZakazan ='0' and extract(year from ter.datum) = 2022
group by 1,2
order by 2;




--Resetiranje Sekvenci--
alter sequence specijalizacija_id_specijalizacija_seq restart ;
alter sequence doktor_id_doktor_seq restart ;
alter sequence pacient_id_pacient_seq restart ;
alter sequence termin_id_termin_seq restart ;
alter sequence upat_id_upat_seq restart with 4;


drop table dolgozo2;
create table dolgozo2 as 
  select 1 sorszam, dolgozo.* from dolgozo;

declare
    cursor curs1 is select * from dolgozo2 natural join osztaly
        order by dnev
        for update of sorszam;
    rec curs1%ROWTYPE;
    i int := 0;
begin
    for rec in curs1 loop
        i := i+1;
        update dolgozo2 set sorszam = i where current of cus1; /*ahol aktu�lsian �llunk csak oda �rv�nyes*/
        --delete from dolgozo2 where curent of curs1;
    end loop;
end;
select * from dolgozo2;


/*�rj PL/SQL n�v n�lk�li blokkot, ami a k�perny�re ki�rja a Dolgoz� t�bla azon dolgoz�inak nev�t, akik foglalkoz�sa
megegyezik azzal, amit a felhaszn�l� INPUTk�nt megadott, a foglalkoz�s�t, �s azt hogy:
 'csoro' ha a fizet�s  < 900	
 a fizet�st, ha az >=900 de <1200	
 'gazdag' ha az >=4000*/

set serveroutput on
ACCEPT foglalkozas CHAR PROMPT 'Add meg a dolgozo foglalkoztasat';
declare
    cursor curs1 is select * from dolgozo where foglalkozas = '&foglalkozas';
    rec curs1%ROWTYPE; 
    --foglalkozas CHAR := foglalkozas;
begin
    for rec in curs1 loop
            if rec.fizetes <900 then
                dbms_output.put_line(rec.dnev || 'csoro');
            elsif (rec.fizetes >=900) and (rec.fizetes <1200) then
                dbms_output.put_line(rec.dnev || rec.fizetes);
            elsif (rec.fizetes >=4000)then
                dbms_output.put_line(rec.dnev || 'gazdag');
            end if;
    end loop;
end;

/*N�velj�k meg a dolgozo 2 t�bl�ban a pr�msz�m sorsz�m� dolgoz�k fizeteset 50%-kal.*/

declare
    cursor curs1 is select * from dolgozo2
                            where prim(sorszam) = 1
                            for update;
    rec curs1%ROWTYPE; 
    --foglalkozas CHAR := foglalkozas;
begin
    for rec in curs1 loop
        --if(prim(rec.sorszam) = 1) then
            update dolgozo2 set fizetes = fizetes*1.5  where current of curs1;
            dbms_output.put_line(rec.dnev || ' * ' || rec.fizetes);
        --end if;
    end loop;
end;

/*T�r�lj�k a dolgoz�k k�z�l a 3-mas fizet�si kateg�ri�j� fizet�s�eket.*/
declare
    cursor curs1 is select * from dolgozo2 join fiz_kategoria
                            on fizetes between also and felso
                            where kategoria = 3
                            for update of sorszam;
    rec curs1%ROWTYPE; 
    --foglalkozas CHAR := foglalkozas;
begin
    for rec in curs1 loop
        delete from dolgozo2 where current of curs1;
    end loop;
end;
select * from dolgozo2 join fiz_kategoria
                            on fizetes between also and felso;

/*�rjunk meg egy proced�r�t, amelyik megn�veli azoknak a dolgoz�knak a fizet�s�t 1-el,
akiknek a fizet�si kateg�ri�ja ugyanaz, mint a proced�ra param�tere.
A proced�ra a m�dos�t�s ut�n �rja ki a m�dos�tott (�j) fizet�sek �tlag�t k�t tizedesjegyre kerek�tve.*/

CREATE OR REPLACE PROCEDURE kat_novel(p_kat NUMBER) IS 
    cursor curs1 is select * from dolgozo2 join fiz_kategoria
                            on fizetes between also and felso
                            where kategoria = p_kat
                            for update of sorszam;
    rec curs1%ROWTYPE;
    db int := 0;
    osszeg int := 0;
begin
    for rec in curs1 loop
    update dolgozo2 set fizetes = fizetes +1
        where current of curs1;
        db := db+1;
        osszeg := osszeg + rec.fizetes+1;
    end loop;
     dbms_output.put_line(round(osszeg/db,2));
end kat_novel;


set serveroutput on
call kat_novel(1);


/*�rjunk meg egy proced�r�t, amelyik m�dos�tja a param�ter�ben megadott oszt�lyon a fizet�seket, �s 
ki�rja a dolgoz� nev�t �s �j fizet�s�t.  A m�dos�t�s mindenki fizet�s�hez adjon hozz� n*10 ezret, 
ahol n a dolgoz� nev�ben lev� mag�nhangz�k sz�ma (a, e, i, o, u).*/
create or replace function maganhangzok(SZO VARCHAR2) return int is
    db int := 0;
begin
    for i in 1..length(szo) loop
        if LOWER(SUBSTR(szo,i, 1)) in ('a','e','i','o','u')then
            db:= db +1;
        end if;
    end loop;
    return db;
end maganhangzok;

create or replace procedure fiz_mod(p_oazon integer) is
    cursor curs1 is select * from dolgozo2
        where oazon = p_oazon for update;
    rec curs1%ROWTYPE;
begin
    for rec in curs1 loop
        update dolgozo2
            set fizetes = (fizetes + 10000 * maganhangzok(dnev))
            where current of curs1;
    end loop;
end fiz_mod;
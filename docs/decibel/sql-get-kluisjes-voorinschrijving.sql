-- =====================================================================
-- DD-lijst: sql-get-kluisjes-voorinschrijving
-- =====================================================================
-- Doel    : leerlingen die voor het KOMENDE schooljaar zijn geplaatst,
--           voor de kluisjes-voorinschrijving. In de app KLASLOOS
--           importeren; Klas + Email staan er alleen ter controle in.
-- Filter  : de eerstvolgende lesperiode uit sis_blpe, dus het schooljaar
--           dat nog moet beginnen. De query zoekt dat zelf op, er zit
--           GEEN datum in die jaarlijks bijgewerkt moet worden.
-- Auteur  : Vincent + Claude, 2026-06-26, herzien 2026-09-11
-- Status  : SYNTAX GEACCEPTEERD, UITVOER NOG NIET GEVERIFIEERD.
--           Bij OSG Hengelo (11 sept 2026) draait de query en kloppen de
--           kolomnamen, maar hij gaf 0 rijen omdat schooljaar 2027-2028
--           daar nog niet bestaat. Dat is correct gedrag (zie "Nul rijen"),
--           maar het betekent ook dat de joins, de locatie-COALESCE en het
--           weggelaten statusfilter nog nergens echte rijen hebben
--           opgeleverd. Eerste echte toets: draai hem bij Het Erasmus met
--           WHERE GETDATE() BETWEEN dBegin AND dEinde en vergelijk met de
--           oude lijst (686 leerlingen over 3 administratieve eenheden).
-- Aanroep : GET <url>/?library=Data&function=GetData
--                 &Layout=sql-get-kluisjes-voorinschrijving
--                 &SessionToken=<token>&Type=XML
--           (DD-lijsten gaan via library=Data, NIET ADFuncties.)
--
-- LET OP bij het bewerken van dit bestand
-- ---------------------------------------
-- Zet NOOIT een hekje in deze SQL, ook niet in een commentaarregel.
-- Decibel leest commentaar mee bij het zoeken naar placeholders en
-- struikelt erover met de melding "'p' is not a valid integer value".
-- Een eerdere versie had de tip "later parametriseren met <hekje>peildatum
-- <hekje>" in een comment staan en daardoor weigerde de hele lijst te
-- draaien. De twee ISK-lijsten die al jaren draaien bevatten geen enkel
-- hekje; gewoon commentaar met twee streepjes is wel prima.
--
-- Waarom geen parameter
-- ---------------------
-- De app stuurt een peildatum-parameter mee, maar Magister gebruikt dat
-- mechanisme in zijn eigen lijsten nergens. De ingebouwde lijsten
-- (vanr_LeerlingGegevensPeilDatum en verwanten) halen de peildatum uit
-- sis_blpe, de tabel met lesperiodes/schooljaren. Dat patroon volgen we
-- hier: het schooljaar wordt opgezocht, niet berekend en niet meegegeven.
-- Gevolg: het schooljaar-veld in de app bepaalt alleen het label waaronder
-- de leerlingen worden weggeschreven, niet welke leerlingen je krijgt.
--
-- Nul rijen
-- ---------
-- Zolang de school het volgende schooljaar nog niet heeft aangemaakt in
-- Magister, bestaat er geen lesperiode die nog moet beginnen en geeft de
-- lijst niets terug. Dat ziet eruit als een kapotte lijst maar is correct:
-- die leerlingen zijn domweg nog niet geplaatst. Scholen maken dat record
-- meestal in het voorjaar aan. Beter nul rijen dan stilzwijgend het
-- verkeerde cohort, wat gebeurde toen de peildatum hier hardcoded stond.
--
-- Controleren of de joins kloppen: vervang eenmalig
--   WHERE dBegin > GETDATE()
-- door
--   WHERE GETDATE() BETWEEN dBegin AND dEinde
-- en druk F9. Dan krijg je de huidige populatie te zien. Daarna terugzetten.
-- =====================================================================

SELECT DISTINCT
    np.omschr_k     AS Schooljaar,
    l.stamnr        AS Leerlingnummer,
    l.roepnaam      AS Voornaam,
    l.tussenvoeg    AS Tussenvoegsel,
    l.achternaam    AS Achternaam,
    l.email         AS Email,
    loc.omschr      AS Locatie,
    klas.groep      AS Klas
FROM sis_leer l
    INNER JOIN sis_aanm a ON a.stamnr = l.stamnr
    INNER JOIN (
        SELECT TOP 1 lesperiode, omschr_k
        FROM sis_blpe
        WHERE dBegin > GETDATE()
        ORDER BY dBegin
    ) np ON np.lesperiode = a.lesperiode
    INNER JOIN sis_stud s    ON s.idStud    = a.idStud
    LEFT  JOIN sis_bgrp klas ON klas.idBgrp = a.idBgrp
    INNER JOIN sis_blok loc  ON loc.idBlok  = COALESCE(klas.idBlok, s.idBlok)
ORDER BY l.stamnr;

-- Kolom Schooljaar staat er bewust in: bij een F9 zie je meteen welk jaar
-- de lijst pakt. De app negeert kolommen die hij niet kent.
--
-- Kolom Klas bevat de NIEUWE klas van volgend jaar. Die wordt bewust niet
-- geimporteerd (de leerling komt klasloos binnen); hij staat er alleen ter
-- controle in. De echte klas komt op 1 augustus via de gewone sync.
--
-- Locatie via COALESCE(klas.idBlok, s.idBlok): leerlingen die nog geen klas
-- hebben, en dat zijn er bij een voorinschrijving veel, vallen anders uit de
-- lijst of krijgen een lege locatie. De oude versie joinde via
-- sis_bgrp.c_lokatie en gaf bij Het Erasmus maar 686 leerlingen over 3
-- administratieve eenheden, met ISK en de HAVO/VWO-bovenbouw structureel
-- ontbrekend. Dit is de vermoedelijke oorzaak daarvan.
--
-- Optioneel statusfilter, overgenomen uit Magisters eigen
-- vanr_LeerlingGegevensPeilDatum maar NIET getest op voorinschrijvingen:
--   WHERE a.idHrnaanmeldingsstatus = 2
-- Bewust weggelaten. Als volgend-jaars plaatsingen een andere status
-- hebben, filtert die regel precies de leerlingen weg die je zoekt, en te
-- veel rijen is hier het veiligere probleem dan te weinig. Zodra er echt
-- rijen uit de lijst komen: draai hem een keer met en een keer zonder deze
-- regel en vergelijk de aantallen.
--
-- Optioneel, beperk tot bepaalde vestiging(en):
--   AND loc.c_lokatie IN ('...')

# Voorinschrijving volgend schooljaar - instructie voor de Magister-beheerder

Met de functie **Voorinschrijving volgend schooljaar** kun je de leerlingen die voor het
**komende** schooljaar zijn geplaatst (bijvoorbeeld de nieuwe brugklassers) nu al in
Kluisjesbeheer zetten, zodat de concierges ze alvast aan een vrij kluisje kunnen koppelen.

Ze komen er **klasloos** in, met een markering "voorinschrijving <schooljaar>". Op 1 augustus,
zodra ze actief in Magister staan, neemt de dagelijkse sync hun echte klas automatisch over en
valt de markering weg. Tot 1 augustus worden deze leerlingen beschermd: de sync markeert ze niet
per ongeluk als "vertrokken".

Er zijn **twee manieren** om de leerlingen op te halen. Kies er een:

- **Optie A - Magister-opzoeklijst (Decibel).** Eenmalig instellen; daarna werkt de knop
  "Importeer via Magister" elk jaar. Aanbevolen als je met Decibel/DD-lijsten kunt werken.
- **Optie B - Excel-export.** Geen Decibel nodig. Je exporteert de leerlingen naar een
  `.xlsx`-bestand en uploadt dat. Handig als je geen opzoeklijst kunt of wilt aanmaken.

De bestaande Magister-koppeling (dagelijkse leerling-sync) blijft ongewijzigd. Deze functie is
een aanvulling daarop.

---

## Optie A - Magister-opzoeklijst (Decibel)

De gewone leerling-sync gebruikt `ADFuncties.GetActiveStudents`, en die geeft alleen de
**huidige** leerlingen. Voor de **volgend-jaars** leerlingen is een aparte opzoeklijst (een
Decibel DD-lijst) nodig die de inschrijvingen van het eerstvolgende schooljaar ophaalt.

### Stappen

1. Open **Decibel** (de query-/DD-lijst-omgeving van Magister).
2. Maak een nieuwe DD-lijst met **exact** de naam:

   ```
   sql-get-kluisjes-voorinschrijving
   ```

   (De naam is in de app instelbaar via de instelling `voorinschrijving_lijst`; standaard is het
   bovenstaande. Houd het op de standaardnaam tenzij je een reden hebt om af te wijken.)

3. Plak de SQL uit het blok onderaan deze instructie (zie **Bijlage: SQL**). Er is niets in aan
   te passen: de query zoekt zelf het eerstvolgende schooljaar op.

   > ⚠️ Zet geen hekje in de query, ook niet in een commentaarregel. Decibel leest commentaar mee
   > bij het zoeken naar placeholders en weigert dan te draaien met de melding
   > *"'p' is not a valid integer value"*.

4. Test in Decibel (toets **F9**). Je krijgt de kolommen `Schooljaar`, `Leerlingnummer`,
   `Voornaam`, `Tussenvoegsel`, `Achternaam`, `Email`, `Locatie`, `Klas`.

   **Nul rijen is normaal** zolang de school het komende schooljaar nog niet heeft aangemaakt in
   Magister. Die leerlingen zijn dan nog niet geplaatst; de lijst gaat vanzelf werken zodra dat
   wel zo is. Wil je toch controleren of de joins kloppen, vervang dan eenmalig
   `WHERE dBegin > GETDATE()` door `WHERE GETDATE() BETWEEN dBegin AND dEinde`, druk F9 (je ziet
   dan de huidige leerlingen) en zet het daarna terug.
5. Geef het **kluisjes-webservice-account** leesrecht op deze lijst/layout. Dat is hetzelfde
   account dat in de app onder **Beheer -> Import** als Magister-account is ingevuld (per school
   verschillend, bijvoorbeeld `webuser` of `Kluisjesmodule`). Zonder dit recht geeft de
   webservice foutcode **10**: "Gebruikersaccount heeft geen recht op deze layout".

   > ⚠️ Draait je installatie op een build **ouder dan 212**, dan slikt de app die tekst in en
   > toon hij alleen "onbekende fout". Zie je dat, ga er dan van uit dat het om dit recht gaat.
6. Ga in de app naar **Beheer -> Import**, onderaan het paneel **Voorinschrijving volgend
   schooljaar**. Vul het komende schooljaar in (vorm `2027-2028`) en klik op **Importeer via
   Magister**. Dat veld bepaalt alleen het label waaronder de leerlingen worden weggeschreven.

> ℹ️ Het account heeft naast deze lijst nog steeds `Algemeen.Login` en
> `ADFuncties.GetActiveStudents` nodig voor de gewone dagelijkse sync. De opzoeklijst komt daar
> bovenop.

> ℹ️ De webservice loopt over poort 8800. Als de sync al werkt, is de IP-whitelist voor de
> kluisjes-server al geregeld en werkt deze knop ook. Zo niet, zie de IP-whitelist-stap in
> [HANDLEIDING.md, hoofdstuk 13](HANDLEIDING.md).

> ℹ️ **Geen jaarlijks onderhoud.** De query leest het eerstvolgende schooljaar uit `sis_blpe`, de
> tabel met lesperiodes. Je hoeft er dus nooit een datum in bij te werken. Dit is hetzelfde patroon
> dat Magisters eigen lijsten (`vanr_LeerlingGegevensPeilDatum` en verwanten) gebruiken.
>
> Gevolg: het schooljaar dat je in de app invult bepaalt alleen het label waaronder de leerlingen
> worden weggeschreven, niet welke leerlingen je krijgt. De app stuurt wel een `peildatum`-parameter
> mee, maar deze lijst gebruikt die niet.

---

## Optie B - Excel-export (geen Decibel nodig)

1. Maak in Magister een selectie of overzicht van de leerlingen die voor het **komende**
   schooljaar zijn geplaatst (peildatum 1 augustus van dat schooljaar).
2. Exporteer die naar **Excel (`.xlsx`)** met minimaal deze kolommen in de **kopregel** (eerste
   rij):
   - **`Leerlingnummer`** (of `Stamnummer`) - verplicht
   - **`Naam`** - verplicht (de volledige naam in een kolom)
   - `Locatie` en `Email` mogen erbij, maar zijn optioneel.

   Hoofdletters in de kolomnamen maken niet uit.
3. Ga in de app naar **Beheer -> Import**, paneel **Voorinschrijving volgend schooljaar**. Vul het
   schooljaar in, kies via **Bestand kiezen** je `.xlsx`, en klik op **Importeer uit Excel**.

---

## Wat er daarna gebeurt (beide opties)

- De leerlingen komen **klasloos** binnen, met de markering "voorinschrijving <schooljaar>"
  (zichtbaar als een klein chipje, bijvoorbeeld `'26-'27`, in de zoekresultaten en op het kluisje).
- Concierges kunnen ze meteen aan vrije kluisjes koppelen.
- **Op 1 augustus** neemt de gewone dagelijkse sync hun echte klas over en verdwijnt de markering
  automatisch, zodra ze als actieve leerling in Magister verschijnen.
- **Tot 1 augustus** worden deze leerlingen beschermd: ze worden niet als "vertrokken" gemarkeerd,
  ook al staan ze nog niet in de lijst met actieve leerlingen.
- Je kunt de import meerdere keren draaien; bestaande voorinschrijvingen worden bijgewerkt, niet
  gedupliceerd.

---

## Bijlage: SQL (voor Optie A)

De canonieke versie, met alle toelichting, staat in de repository onder
[`docs/decibel/sql-get-kluisjes-voorinschrijving.sql`](../decibel/sql-get-kluisjes-voorinschrijving.sql).
Plak hem over; er is niets in aan te passen.

```sql
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
```

> De subquery op `sis_blpe` pakt de eerstvolgende lesperiode, oftewel het schooljaar dat nog moet
> beginnen. Daarom staat er geen datum in die je jaarlijks moet bijwerken, en daarom geeft de
> lijst niets terug zolang dat schooljaar nog niet in Magister is aangemaakt.

> De kolom `Klas` bevat de **nieuwe** klas van volgend jaar. Die wordt bewust **niet**
> geimporteerd (de leerling komt klasloos binnen); hij staat er alleen ter controle in. De echte
> klas komt op 1 augustus via de gewone sync.

> De kolom `Locatie` loopt via `COALESCE(klas.idBlok, s.idBlok)` en valt dus terug op de locatie
> van de studie. Dat is nodig omdat voorinschrijvers vaak nog geen klas hebben; een join puur op
> de klas laat die leerlingen weg of geeft ze een lege locatie.

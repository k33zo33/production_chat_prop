# Naziv projekta
Radni naziv: Production Chat Prop

## 1. Vizija i cilj
**Jedna rečenica:** Production Chat Prop je alat za kreiranje i reproduciranje simuliranih chat razgovora za film, serije, reklame i druge produkcijske potrebe, bez kopiranja identiteta stvarnih messaging brandova.

**Ciljana publika:**
- produkcijske kuće
- reklamne agencije
- art odjeli i scenografi
- asistenti režije i skripteri
- video editori i motion dizajneri
- nezavisni autori, YouTube i short-form kreatori

**Problem koji rješava:**
Postojeći fake chat alati često ciljaju prank ili casual sadržaj, imaju copycat vizuale, slab export, malo kontrole za playback i nisu prilagođeni stvarnom produkcijskom workflowu. Ovaj proizvod rješava tri konkretna problema:
1. kontrolirani playback razgovora na setu
2. brzi export gotovih screenshotova i videa
3. originalan, brand-safe vizualni identitet bez pravnih sivih zona

## 2. Glavni use-caseovi

### Use-case 1: Snimanje chata na setu
**Korisnik:** asistent režije ili rekviziter

**Cilj:** pokrenuti chat razgovor na telefonu ili monitoru tijekom snimanja tako da razgovor izgleda uvjerljivo i ide u realnom vremenu.

**Scenarij korak-po-korak:**
1. Korisnik otvara projekt i odabire scenu.
2. Odabire stil chata i device prikaz.
3. Provjerava likove, poruke i vremena poruka.
4. Ulazi u playback mod.
5. Pokreće Play neposredno prije kadra.
6. Tijekom snimanja po potrebi pauzira ili restartira scenu.
7. Nakon snimanja radi manje korekcije tempa i ponavlja playback.

### Use-case 2: Generiranje gotovih chat videa za montažu
**Korisnik:** video editor, motion dizajner ili content producer

**Cilj:** izvesti video simuliranog razgovora koji se može direktno koristiti u montaži.

**Scenarij korak-po-korak:**
1. Korisnik otvara projekt i finalizira poruke.
2. Podešava ritam playbacka, typing indikator i status poruka.
3. Bira format videa: 9:16 ili 16:9.
4. Pregledava playback od početka do kraja.
5. Pokreće export videa.
6. Uvozi generirani video u montažni alat.

### Use-case 3: Generiranje statičnih screenshotova u visokoj rezoluciji
**Korisnik:** dizajner, copywriter, account ili redatelj reklame

**Cilj:** dobiti kvalitetan screenshot razgovora za prezentaciju, storyboard ili finalni vizual.

**Scenarij korak-po-korak:**
1. Korisnik odabire scenu i stil.
2. Ručno podešava koji dio razgovora želi prikazati.
3. Uključuje ili isključuje device frame.
4. Odabire rezoluciju izvoza.
5. Exporta PNG.
6. Umeće sliku u pitch deck, storyboard ili kampanju.

## 3. Scope MVP verzije

### 3.1. Što MVP SIGURNO sadrži
- Kreiranje likova (ime, avatar, boja balona)
- Jedan-na-jedan chat + grupni chat (osnovno)
- 3–5 vlastitih stilova chata
- Ručno zadavanje poruka za svakog lika
- Kontrola vremena poruke (timestamp)
- Status poruke: poslano / dostavljeno / viđeno
- Indikator tipkanja
- Playback mod: Play / Pause / Restart scene
- Screenshot export (PNG) u Full HD rezoluciji
- Video playback export u formatima 9:16 i 16:9 s osnovnom animacijom
- Lokalno spremanje projekta na uređaj ili u browser storage

### 3.2. Što MVP NE sadrži
- Login / account sustav
- Cloud sync projekata
- AI generiranje scenarija
- Kolaboracija tima u realnom vremenu
- Napredna analitika
- Brand marketplace tema
- Audio sinkronizaciju, voiceover ili lipsync
- Multi-scene timeline editor na razini cijelog projekta

## 4. Funkcionalni zahtjevi po ekranu

### 4.1. Ekran: Project list
- Prikaz liste projekata
- Kreiranje novog projekta
- Otvaranje postojećeg projekta
- Prikaz osnovnih meta podataka:
  - naziv
  - datum izmjene
  - tip projekta (reklama / serija / ostalo)
- Akcije:
  - Duplicate
  - Delete
  - Rename

### 4.2. Ekran: Chat editor
- Sidebar s likovima:
  - add
  - edit
  - delete
- Glavni editor s listom poruka po vremenskom redoslijedu
- Forma za dodavanje poruke:
  - odabir lika
  - tekst poruke
  - vrijeme (auto ili ručno)
  - status poruke
  - incoming / outgoing
- Mogućnost promjene stila chata
- Mogućnost promjene scene title-a
- Osnovna validacija:
  - prazna poruka nije dozvoljena
  - timestamp ne smije ići unatrag bez upozorenja

### 4.3. Ekran: Playback
- Play / Pause / Restart
- Slider za scrub kroz razgovor
- Trenutni timecode
- Prikaz typing indikatora prema definiranim pravilima
- Dugme za export screenshot
- Dugme za export video
- Prebacivanje prikaza:
  - telefon bez branda
  - bez framea
- Pregled razgovora kako će izgledati u exportu

## 5. Nefunkcionalni zahtjevi
- Target platforma za MVP: Flutter Web
- Kasnije platforme: Android i iOS
- Playback mora raditi glatko na modernim laptopima i desktop browserima
- Aplikacija se ne smije rušiti pri dugim razgovorima od 500+ poruka
- Osnovni flow mora biti razumljiv novom korisniku unutar 10 minuta
- Projekt mora biti strukturiran tako da kasnije podrži backend i team features
- Export mora biti dovoljno kvalitetan za stvarnu produkcijsku upotrebu

## 6. Pravne i dizajn smjernice
- Ne koristiti stvarne logotipe messaging aplikacija
- Ne koristiti službene nazive brandova kao nazive tema
- Ne kopirati točan layout, ikonografiju ili kombinaciju boja prepoznatljivih aplikacija
- Svaka tema mora imati vlastiti identitet, tipografiju i boje
- U marketinškim materijalima proizvod se opisuje kao conversation mockup / production chat tool, ne kao klon postojeće aplikacije

## 7. Mjerilo uspjeha za MVP
MVP je uspješan ako korisnik može:
1. napraviti projekt
2. definirati likove i poruke
3. reproducirati razgovor u realnom vremenu
4. izvesti upotrebljiv screenshot i video
5. to napraviti bez dodatnog objašnjenja nakon kratkog onboardinga

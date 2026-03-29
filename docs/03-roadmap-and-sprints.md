# Roadmap & Sprint plan

Pretpostavka:
- radiš sam
- sprint traje 2 tjedna
- cilj je doći do beta MVP-a s web deployom

## Faza 0 – Priprema (1 tjedan)
**Cilj:** postaviti smjer i development bazu.

Zadaci:
- Dovršiti `01-product-spec-mvp.md`
- Dovršiti `02-technical-architecture-flutter.md`
- Napraviti početni Flutter projekt
- Postaviti folder strukturu po feature-first principu
- Uvesti Riverpod, GoRouter i lint pravila
- Napraviti početni router i prazne ekrane

**Definition of done:**
- projekt se builda i pokreće lokalno
- postoji početna navigacija između glavnih ekrana
- dokumentacija je usuglašena s trenutnim scopeom

## Sprint 1 (2 tjedna) – Osnova projekta + modeli
**Cilj:** imati kostur aplikacije s dummy podacima.

Zadaci:
- Implementirati modele: Project, Scene, Character, Message
- Dodati enum-e i osnovnu serijalizaciju
- Napraviti `ProjectRepository` sučelje i lokalnu implementaciju
- Napraviti screen `Project list` s hardkodiranim ili lokalno spremljenim podacima
- Napraviti screen `Chat editor` koji prikazuje likove i listu poruka
- Implementirati kreiranje novog projekta

**Definition of done:**
- korisnik može otvoriti app i vidjeti listu projekata
- može otvoriti dummy projekt i vidjeti editor
- podaci se mogu serijalizirati i spremiti lokalno

## Sprint 2 (2 tjedna) – Chat editor funkcionalan
**Cilj:** ručno uređivanje razgovora radi od početka do kraja.

Zadaci:
- Dodavanje, uređivanje i brisanje poruka
- Dodavanje, uređivanje i brisanje likova
- Odabir lika za svaku poruku
- Uređivanje timestampa i statusa poruke
- Uređivanje incoming/outgoing smjera poruke
- Uvesti prve 2–3 vlastite teme chata

**Definition of done:**
- korisnik može složiti cijelu scenu bez ručnog mijenjanja koda
- scene se mogu spremiti i ponovno otvoriti
- osnovne teme se mogu mijenjati iz editora

## Sprint 3 (2 tjedna) – Playback mod
**Cilj:** realističan playback razgovora na ekranu.

Zadaci:
- Implementirati `PlaybackController`
- Play, Pause, Restart
- Slider / scrubber kroz vrijeme
- Typing indikator
- Prikaz statusa poruke
- Sinkronizacija s editorom

**Definition of done:**
- razgovor se reproducira po timestampovima
- korisnik može pauzirati i vratiti playback
- promjene iz editora su vidljive u playbacku bez rušenja stanja

## Sprint 4 (2 tjedna) – Export
**Cilj:** stvoriti konkretan output za produkciju.

Zadaci:
- Export screenshota u Full HD PNG
- Postavke omjera slike: 9:16 i 16:9
- Osnovni export playback videa ili definirani fallback workflow
- Device frame toggle i clean export varijanta
- Kratki QA checklist za provjeru exporta

**Definition of done:**
- korisnik može izvesti barem jedan kvalitetan screenshot
- korisnik može dobiti video ili jasno dokumentiran privremeni workaround za video izlaz
- export izgleda konzistentno s previewem

## Sprint 5 (2 tjedna) – Poliranje i testiranje
**Cilj:** MVP spreman za prve beta korisnike.

Zadaci:
- UI polishing
- dorada spacinga, tipografije i kontrasta
- bugfixing nakon internog testiranja
- osnovni unit testovi
- osnovni widget testovi
- priprema demo projekta i demo videa
- priprema kratke landing stranice ili product opisa

**Definition of done:**
- app je stabilan za internu/beta demonstraciju
- osnovne greške su pokrivene testovima
- postoji demo flow koji možeš pokazati klijentu ili partneru

## Backlog (za kasnije)
- AI generiranje scenarija iz kratkog opisa
- account sustav i cloud sync
- timovi i zajednički workspace
- više scena po projektu s višom razinom timeline upravljanja
- dodatni stilovi i templateovi
- izvoz project packagea za asset handoff
- white-label teme za agencije

## Tjedni ritam rada koji preporučujem
- Ponedjeljak: plan i izbor zadataka
- Utorak–četvrtak: implementacija
- Petak: testiranje, refaktor i dokumentiranje
- Zadnji dan sprinta: demo samome sebi + update dokumenata

## Pravilo upravljanja scopeom
Ako feature ne pomaže izravno jednom od tri glavna MVP use-casea, ide u backlog.

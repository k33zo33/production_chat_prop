# Tehnička arhitektura (Flutter)

## 1. Platforme i tech stack
- **Flutter:** stable channel
- **Target platforme:** Web za MVP, kasnije Android i iOS
- **Arhitekturni pristup:** feature-first + layered architecture
- **State management:** Riverpod
- **Routing:** GoRouter
- **Lokalno spremanje za MVP:** JSON serijalizacija + browser/local storage repository
- **Kasnije spremanje:** backend sloj iza repozitorija (Firebase, Supabase ili custom API)

### Zašto ove odluke
- Riverpod omogućuje odvajanje logike od UI-ja i dobar je za testabilan i skalabilan kod.
- GoRouter je dobar izbor za navigaciju i URL-based routing, posebno na webu.
- Layered architecture olakšava rast projekta i kasniju zamjenu storage/backend sloja bez rušenja UI-ja.

## 2. Struktura projekta (folders)

```text
lib/
  core/
    constants/
    errors/
    routing/
    theme/
    utils/
    widgets/
  features/
    projects/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        pages/
        widgets/
    chat_editor/
      data/
      domain/
      presentation/
        controllers/
        pages/
        widgets/
    playback/
      data/
      domain/
      presentation/
        controllers/
        pages/
        widgets/
  app/
    app.dart
    router.dart
  main.dart

test/
  unit/
  widget/
```

### Kratki opis feature modula
- `projects` — CRUD nad projektima, lista projekata, dupliciranje, brisanje i lokalno spremanje
- `chat_editor` — uređivanje scene, likova, poruka, statusa i stilova
- `playback` — reprodukcija razgovora kroz vrijeme, typing indikator, scrubber i export pipeline

## 3. Modeli podataka (tekstualni class dijagram)

### 3.1. Project
- `id: String`
- `name: String`
- `type: ProjectType` (`ad`, `series`, `other`)
- `createdAt: DateTime`
- `updatedAt: DateTime`
- `scenes: List<Scene>`

### 3.2. Scene
- `id: String`
- `title: String`
- `characters: List<Character>`
- `messages: List<Message>`
- `styleId: String`
- `aspectRatio: SceneAspectRatio` (`portrait9x16`, `landscape16x9`)

### 3.3. Character
- `id: String`
- `displayName: String`
- `avatarPath: String?`
- `bubbleColor: String`

### 3.4. Message
- `id: String`
- `characterId: String`
- `text: String`
- `timestampSeconds: int`
- `status: MessageStatus` (`sent`, `delivered`, `seen`)
- `isIncoming: bool`
- `showTypingBefore: bool`

## 4. Domain pravila i odgovornosti
- **Project** je root agregat za spremanje i učitavanje.
- **Scene** je glavni kontekst editora i playbacka.
- **Character** se referencira po `characterId` iz poruke.
- **Message** mora biti sortirana po `timestampSeconds` prije playbacka i exporta.
- Export sloj nikad ne mijenja source podatke; radi samo nad readonly view modelom.

## 5. State management plan

### Globalno stanje
Držati globalno:
- listu projekata
- trenutno otvoreni projekt
- trenutno otvorenu scenu
- aktivni chat stil
- playback state (`idle`, `playing`, `paused`, `finished`)

### Lokalno UI stanje po widgetu
Držati lokalno:
- otvoreni paneli
- tab selection
- forma za novu poruku
- input greške i validacijske poruke
- lokalne hover/selection UI stateove

### Sinkronizacija editora i playbacka
Predloženi pristup:
- jedan `SceneController` kao glavni source of truth za uređivanje scene
- jedan `PlaybackController` koji čita readonly snapshot iz `SceneController` stanja
- kod svake promjene scene playback se resetira ili recompute-a ovisno o UX odluci

## 6. Repository i datasource pristup

### Repozitoriji
- `ProjectRepository`
- `SceneRepository` nije nužan zasebno u MVP-u ako je `ProjectRepository` dovoljan

### Datasource za MVP
- lokalni storage adapter koji sprema JSON stringove po projektu
- opcionalni import/export JSON file za backup i prijenos

### Pravilo apstrakcije
UI ne smije direktno znati gdje se podaci spremaju. UI komunicira s kontrolerima i repozitorijima, ne sa storage API-jima.

## 7. Stilovi i teme
- Stilovi chata definiraju se kao vlastiti design tokeni
- Svaki stil ima:
  - boje balona
  - boju pozadine
  - radius balona
  - stil timestampa
  - stil status ikona
- Stilovi ne smiju biti imenovani po postojećim brandovima

## 8. Integracija s AI coding asistentom
AI koristiš za:
- generiranje modela i `toJson/fromJson` metoda
- generiranje repository skeletona
- generiranje widget layouta
- pomoć pri pisanju unit i widget testova

### Pravilo rada s AI-jem
1. prvo ručno definiraš domenu, modele i granice featurea
2. zatim tražiš AI da generira implementaciju unutar tih granica
3. svaku generiranu datoteku pregledavaš prije commita
4. AI ne određuje arhitekturu samostalno; dokumentacija je izvor istine

## 9. Kvaliteta koda
- Lint pravila: `very_good_analysis`
- Preferirati male, fokusirane widgete
- Business logika ne ide u widget build metode
- Koristiti value modele i čiste pomoćne funkcije gdje god ima smisla

### Testovi
- Unit testovi:
  - serijalizacija modela
  - sortiranje poruka
  - izračun vidljivih poruka u playback trenutku
- Widget testovi:
  - Project list render
  - Chat editor osnovni layout
  - Playback kontrole prisutne i reagiraju na state

## 10. Build & deploy

### Okruženja
- `dev`
- `prod`

### Web deploy MVP
Moguće opcije:
- GitHub Pages
- Firebase Hosting
- Netlify ili sličan static hosting

### Minimalni release proces
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build web`
5. pregled outputa lokalno ili na preview deployu
6. upload na hosting
7. smoke test nakon deploya

## 11. Početni dependencies prijedlog
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod:
  go_router:
  shared_preferences:
  uuid:

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis:
```

## 12. Što svjesno NE uvodimo u MVP
- backend servis
- auth
- real-time sync
- prekompliciran DI framework
- code generation koji nije nužan za prvu verziju

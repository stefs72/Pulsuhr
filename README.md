# Pulsuhr

Gibt den Puls der Apple Watch als **Bluetooth-Pulsgurt** frei. Gemacht fürs Indoor-Training mit
**Zwift** und **MyWhoosh**. Lesen kann ihn jeder Empfänger, der einen Brustgurt erwartet: Mac, PC,
iPad, Apple TV oder Radcomputer.

**Stand 16.11.2026: am Gerät getestet mit MyWhoosh.** Läuft im Hintergrund, auch mit gesperrtem
iPhone, und MyWhoosh verbindet sich beim nächsten Start von selbst wieder.

## Warum zwei Teile

Die Uhr allein kann es nicht. Apple sperrt den Peripheral-Betrieb auf watchOS ausdrücklich:

```
CBPeripheralManager initWithDelegate:queue:  API_AVAILABLE(ios, macos) API_UNAVAILABLE(watchos, tvos)
```

Dasselbe bei `CBMutableService` und `CBMutableCharacteristic`. Die Symbole stecken zwar in der
watchOS-Bibliothek — Apple liefert dieselbe Binärdatei für alle Systeme aus —, aber der Compiler
weist sie ab. Wer das nachprüfen will: in der Symboltabelle steht es anders als in den Headern;
**die Header entscheiden.**

Also:

```
Apple Watch                      iPhone                        Empfänger
HealthKit-Workout  ──WatchConnectivity──▶  CoreBluetooth  ──BLE 0x180D──▶  Zwift, MyWhoosh …
(misst den Puls)                  (gibt ihn frei)
```

## Die drei Dinge, die man wissen muss

**Die Workout-Session ist kein Trick, sie schaltet den Sensor ein.** Ohne sie misst die Uhr im
Ruhezustand nur alle paar Minuten — es gäbe nichts zu senden. Darum muss die Messung von Hand
gestartet werden; eine stille Dauermessung lässt watchOS nicht zu.

**Nichts landet in Health.** Die Einheit wird am Ende verworfen (`discardWorkout`), nie gesichert.
Wer `finishWorkout` einbaut, verfälscht die Ringe. Dasselbe Muster läuft in FlyMagic Hike.

**`WKBackgroundModes` steht in `PulsuhrWatch-Info.plist`, nicht in den Build-Einstellungen.** Xcode
erzeugt nur eine feste Liste von Info.plist-Einträgen aus `INFOPLIST_KEY_…`; dieser gehört nicht
dazu und fiel beim ersten Bau stillschweigend weg. Ohne ihn beendet watchOS die App, sobald der
Bildschirm ausgeht.

## Benutzen

1. Auf der Uhr öffnen — die Messung startet von selbst.
2. Auf dem iPhone öffnen und **zum Koppeln** offen lassen. Im Hintergrund versteckt iOS die
   Dienstkennung so, dass ein Empfänger sie beim Suchen kaum findet.
3. In Zwift, MyWhoosh oder einer anderen Trainings-App nach einem Pulssensor suchen. Das Gerät heisst **Pulsuhr**.
4. Danach dürfen beide in den Hintergrund: Die Uhr hält ihre Trainings-Session, das iPhone hält
   die bestehende Bluetooth-Verbindung (`bluetooth-peripheral`).

Das Koppeln ist nur beim ersten Mal nötig. Danach verbindet sich der Empfänger von selbst mit
**Pulsuhr**, sobald die Messung auf der Uhr läuft.

### Was die Verbindung stabil hält

- **iPhone-Hintergrundmodus in einer echten Info.plist** (`Pulsuhr-Info.plist`). Als
  `INFOPLIST_KEY_UIBackgroundModes` verwarf Xcode ihn stillschweigend — dieselbe Falle wie bei der
  Uhr. Ohne ihn fror iOS die App beim Sperren ein und der Pulsgurt verschwand.
- **Sofort senden** (`PulsSender`): Jeder Wert der Uhr geht ohne Umweg an den Empfänger. Im
  Hintergrund laufen keine Timer; iOS weckt die App nur kurz pro Nachricht. Ein Sekundentakt
  füllt Lücken, solange die App wach ist.
- **Uhr prüft nicht auf `isReachable`** (`Funk`): `sendMessage` weckt die iPhone-App im
  Hintergrund; die Prüfung hatte genau das verhindert.
- **Session-Delegate gesetzt** (`PulsQuelle`): Endet die Trainings-Session, merkt die App es,
  zeigt „Messung beendet" und meldet dem iPhone sofort `stop`. Kein automatischer Neustart (siehe
  `ARCHITECTURE.md` §4). Gleiches Muster wie `WatchWorkout.swift` in FlyMagic Hike.
- **Wiederanlauf** (`CBPeripheralManagerOptionRestoreIdentifierKey`): Räumt iOS die App ab, darf es
  sie im Hintergrund neu starten, wenn der Empfänger sich meldet. Die Brücke startet deshalb im
  App-Delegate, nicht in der Ansicht.

Zum Prüfen ohne MyWhoosh eignet sich ein BLE-Scanner (z. B. LightBlue): Dort sieht man
roh, ob der Dienst `180D` advertisiert wird und welche Werte rausgehen.

## Testen

**Kein Simulator** — Pulssensor und Funkmodul gibt es dort nicht. Und die **Uhr muss getragen
werden**: Liegt sie auf dem Tisch, erkennt sie kein Handgelenk und liefert keinen Puls; die App
sähe aus wie kaputt.

```bash
xcodebuild -project Pulsuhr.xcodeproj -target Pulsuhr \
  -configuration Debug -destination 'generic/platform=iOS' build
```

`-sdk iphoneos` **nicht** verwenden: Das überschreibt auch die Uhren-Abhängigkeit, die dann gegen
das falsche SDK übersetzt wird.

## Offen

- Akkuverbrauch der Uhr pro Stunde ist noch nicht gemessen.
- App Store: in Vorbereitung, siehe [APPSTORE.md](APPSTORE.md).

## Datenschutz

Keine Konten, kein Internet, keine Speicherung. Details: [PRIVACY.md](PRIVACY.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).

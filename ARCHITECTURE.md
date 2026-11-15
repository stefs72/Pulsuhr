# Pulsuhr – Konzept und Architektur

Die Hauptquelle für alle, die an diesem Repo arbeiten. Was hier steht, ist am Code geprüft.
Arbeitsregeln stehen in `CLAUDE.md`, die Nutzersicht im `README.md`.

_Stand: 15.11.2026 · Version 1.0 (Build 1) · nicht im App Store · nur lokal versioniert (kein Remote)_

---

## 1. Zweck und Grenzen

Pulsuhr gibt den Puls der Apple Watch als **Standard-Bluetooth-Pulsgurt** frei. Gebaut ist sie für
**MyWhoosh auf dem Mac**, funktioniert aber mit jeder App, die einen Brustgurt erwartet (Zwift,
LightBlue …).

**Das wichtigste Designprinzip ist Einfachheit.** Stefans Vorgabe: *„eifach nur den Puls
freigeben“*.

- Uhr: eine Zahl, ein Knopf. Die Messung startet beim Öffnen von selbst.
- iPhone: eine Zahl und eine Statuszeile. Bedienen muss man dort nichts.
- Kein Konto, kein Abo, keine Einstellungen. **Nichts wird in Health gespeichert.**

Neue Funktionen nur auf ausdrücklichen Auftrag. Im Zweifel weglassen. Dass es so wenig ist, ist
gerade der Unterschied zu den bestehenden Apps.

## 2. Datenfluss

```
Apple Watch                         iPhone                              Mac
───────────                         ──────                              ───
HKWorkoutSession                    WCSession-Empfang                   MyWhoosh
 + HKLiveWorkoutBuilder               │                                   ▲
   │  misst ~1×/s                      ▼                                   │
   ▼                                Bruecke  ── Wert setzen ──▶ PulsSender │
PulsQuelle ──▶ Funk ──sendMessage──▶ (Wache: 10 s ohne Wert → 0)   │      │
               {"bpm": Int}                                         │      │
               {"stop": true}                    eigener 1-s-Takt ──┘      │
                                                 BLE Heart Rate 0x180D ────┘
```

### Warum der Umweg übers iPhone

**watchOS darf kein BLE-Peripheral sein.** Die Header sagen es ausdrücklich:

```
CBPeripheralManager initWithDelegate:queue:   API_UNAVAILABLE(watchos, tvos)
CBMutableService / CBMutableCharacteristic    API_UNAVAILABLE(watchos, tvos)
```

Die Symbole stehen zwar in der watchOS-`.tbd`, denn Apple liefert eine gemeinsame Binärdatei aus.
Der Compiler weist sie aber ab. **Massgebend sind die Header, nicht die Symboltabelle.** Diese
Verwechslung hat am 13.11.2026 einen falschen Befund erzeugt. Also misst die Uhr, und das iPhone
tritt als Pulsgurt auf.

## 3. Komponenten

| Datei | Gerät | Aufgabe |
|---|---|---|
| `Pulsuhr Watch/PulsQuelle.swift` | Uhr | HealthKit-Trainings-Session, liefert jeden neuen Pulswert, meldet ein ungewolltes Ende (`beiEnde`) |
| `Pulsuhr Watch/Funk.swift` | Uhr | Schickt `{"bpm": Int}` und `{"stop": true}` per `WCSession.sendMessage` ans iPhone |
| `Pulsuhr Watch/WatchAnsicht.swift` | Uhr | Zahl und Knopf. Auto-Start in `.task`. Beim Stoppen auch `sendeStop()` |
| `Pulsuhr Watch/PulsuhrWatchApp.swift` | Uhr | Einstieg |
| `Pulsuhr/Bruecke.swift` | iPhone | WCSession-Empfang und Frische-Wache. Singleton `Bruecke.geteilt` |
| `Pulsuhr/PulsSender.swift` | iPhone | `CBPeripheralManager`: Dienst 0x180D, Werbung, 1-s-Takt, Wiederanlauf |
| `Pulsuhr/PulsuhrApp.swift` | iPhone | Einstieg. `Delegierter` (App-Delegate) wirft die Brücke beim Programmstart an |
| `Pulsuhr/Ansicht.swift` | iPhone | Zeigt die Zahl und den Zustand. Beobachtet nur (`@ObservedObject`) |
| `PulsuhrWatch-Info.plist` | Uhr | `WKBackgroundModes = workout-processing`, `WKSupportsAlwaysOnDisplay` |
| `Pulsuhr-Info.plist` | iPhone | `UIBackgroundModes = bluetooth-peripheral` |
| `werkzeug-symbol.swift` | – | Erzeugt das App-Symbol (siehe §9) |

## 4. Hintergrundbetrieb – beide Seiten bleiben aktiv

Das ist der Kern der Stabilität. Jede Seite braucht **ihre eigene Session** und **ihren eigenen
Hintergrundmodus**.

### Uhr: Trainings-Session

- Die `HKWorkoutSession` (Radfahren, drinnen) ist **kein Trick für Rechenzeit**. Sie schaltet
  den Sensor auf Dauermessung. Ohne sie misst die Uhr nur alle paar Minuten.
- Mit `workout-processing` läuft die App weiter, wenn der Arm sinkt, der Bildschirm ausgeht
  oder eine andere App vorne ist. Die Ansicht stoppt beim Verschwinden bewusst **nicht**.
- **`session.delegate = self` ist Pflicht.** Ohne den Delegate merkt die App nicht, dass watchOS
  die Session beendet hat: Die Zahl friert ein, und es geht nichts mehr ans iPhone. Bis
  15.11.2026 fehlte diese Zeile. Gleiches Muster wie `FlyMagic Hike/WatchWorkout.swift`.
- **Kein automatischer Neustart, mit Absicht.** Eine laufende Trainings-Session beendet watchOS
  nicht von sich aus. Wenn sie endet, hat das einen Grund: Eine andere Trainings-App wurde
  gestartet (es läuft immer nur eine), jemand hat sie im Kontrollzentrum beendet, oder der
  Sensor meldet einen Fehler. Ein Neustart würde gegen den Benutzer arbeiten und etwa der
  Trainings-App von Apple die Session wieder wegnehmen. Stattdessen zeigt `beendet()` ehrlich
  „Messung beendet“, der Knopf springt auf „Starten“, und über `beiEnde` geht sofort `stop` ans
  iPhone, damit der Mac 0 statt einer alten Zahl bekommt. Ein automatischer Neustart war am
  15.11.2026 kurz eingebaut und wurde auf Stefans Einwand wieder entfernt. Nicht wieder einbauen.
- Der von Apple vorgesehene Weg nach einem **Absturz** der App ist
  `WKApplicationDelegate.handleActiveWorkoutRecovery()` mit `HKHealthStore.recoverActiveWorkoutSession`.
  Das ist noch nicht eingebaut (§10).
- **Nichts landet in Health:** Am Ende `endCollection`, dann `discardWorkout()`, **nie**
  `finishWorkout`. Sonst verfälscht die App Ringe und Statistiken.

### iPhone: Bluetooth-Peripheral

- Mit `bluetooth-peripheral` darf die App bei gesperrtem iPhone und im Hintergrund weiter als
  Pulsgurt dienen. Bis 15.11.2026 fehlte der Modus im fertigen Paket (siehe §8, Info.plist-Falle).
  Das war der Hauptgrund für die abreissende Verbindung.
- **Eigener 1-s-Takt** (`PulsSender.schlag()`): Der Mac bekommt jede Sekunde den geltenden Wert,
  unabhängig davon, wann die Uhr liefert. Vorher ging nur etwas hinaus, wenn eine Nachricht der
  Uhr eintraf, und jedes Stocken war ein Aussetzer in MyWhoosh. `sende(_:)` setzt nur den Wert,
  gesendet wird im Takt.
- **Wiederanlauf:** `CBPeripheralManagerOptionRestoreIdentifierKey = "Moveaware.Pulsuhr.Sender"`.
  Räumt iOS die App ab, darf es sie im Hintergrund neu starten, sobald der Mac sich meldet.
  - `willRestoreState` übernimmt den bestehenden Dienst. **Dann nicht neu anlegen**, sonst reisst
    genau die Verbindung ab, die gerettet werden soll (`ausWiederanlauf`).
  - Die Zuhörer werden über `subscribedCentrals` gezählt, nicht über die Delegate-Rückrufe. Nach
    einem Wiederanlauf werden bestehende Abos nicht neu gemeldet.
  - Die Brücke startet im **App-Delegate**, nicht in `onAppear`. Bei einem Wiederanlauf im
    Hintergrund wird keine Ansicht sichtbar.
- Ist niemand verbunden und läuft keine Werbung, startet der Takt die Werbung neu.

### Koppeln braucht den Vordergrund

Im Hintergrund schiebt iOS die Dienstkennungen in einen „Overflow“-Bereich der Werbung. Ein
Mac, der nach 0x180D filtert, findet das Gerät dann kaum. **Zum ersten Koppeln muss die
iPhone-App offen sein.** Danach dürfen beide in den Hintergrund. Die Uhr-App braucht es zum Koppeln
nicht, nur für die Werte.

### Uhr → iPhone: kein `isReachable`-Check

`Funk` prüft nur `activationState == .activated`, **nicht** `isReachable`. Bei gesperrtem iPhone
steht `isReachable` auf `false`. Mit Prüfung warf die Uhr jeden Wert selbst weg. Ohne Prüfung
erfüllt `sendMessage` seinen Zweck: Es weckt die iPhone-App im Hintergrund. Fehler werden
bewusst verworfen (`errorHandler: nil`), denn eine Sekunde später kommt der nächste Wert.
Nachliefern wäre falsch: Ein alter Puls ist schlechter als keiner.

## 5. Protokolle

### WatchConnectivity (Uhr → iPhone)

| Nachricht | Bedeutung |
|---|---|
| `["bpm": Int]` | neuer Messwert |
| `["stop": true]` | Benutzer hat beendet. Das iPhone verwirft sofort, statt 10 s zu warten |

Nur `sendMessage`. `transferUserInfo` stapelt alte Werte (FIFO) und ist deshalb ungeeignet.

### Bluetooth (iPhone → Mac)

| Was | Wert |
|---|---|
| Dienst | Heart Rate Service `0x180D`, primär, **muss in der Werbung stehen** |
| Messwert | `0x2A37`, notify. Bytes: `[0x00, bpm]` (Flag-Bit 0 = 0 → uint8, bis 255) |
| Sensorort | `0x2A38`, read, fester Wert `0x02` (Handgelenk) |
| Gerätename | `Pulsuhr` (`CBAdvertisementDataLocalNameKey`) |

## 6. Zeiten und Zustände

| Konstante | Wert | Ort | Zweck |
|---|---|---|---|
| Takt | 1 s | `PulsSender` | Wert an den Mac |
| Frische | 10 s | `Bruecke.frisch` | so lange gilt ein Wert ohne Nachschub |
| Wache | 2 s | `Bruecke.wache` | prüft die Frische |

**0 bpm bedeutet „kein Kontakt“.** Das senden Brustgurte auch, wenn man sie abnimmt. Nach Ablauf
der Frische oder bei `stop` setzt die Brücke `puls = nil` und sendet 0. Eine eingefrorene Zahl
wäre schlimmer.

Statuszeile iPhone (`Bruecke.zustand`): Hinweis (Bluetooth aus …) › „warte auf die Uhr“ ›
„Empfänger verbunden“ › „freigegeben – wartet auf Empfänger“ › „startet …“. In der Anzeige steht
bewusst „Empfänger“, nicht „Mac“, denn lesen kann jedes Gerät, das einen Pulsgurt erwartet. Punkt:
grün = Empfänger abonniert, orange = Werbung läuft, grau = noch nicht bereit.

### Automatisch wieder verbinden

Ob ein Empfänger sich beim nächsten Mal von selbst verbindet, entscheidet **der Empfänger**
(MyWhoosh merkt sich Sensoren), nicht Pulsuhr. Wir können nur beeinflussen, ob er uns
**wiedererkennt**. Ein iPhone wechselt seine Bluetooth-Adresse regelmässig (Datenschutz). Ein
Empfänger ohne Bonding sieht dann womöglich jedes Mal ein „neues“ Gerät. Möglicher Hebel, noch
**nicht** eingebaut und ungetestet: das Messwert-Merkmal verschlüsselt verlangen
(`.notifyEncryptionRequired`). Dann koppeln Mac und iPhone einmal auf Systemebene, und die
Adresse bleibt auflösbar. Das Risiko: Echte Brustgurte verlangen das nicht, und manche Apps
kommen damit nicht zurecht. Nur nach einem Test am Gerät entscheiden (§10).

## 7. Build und Konfiguration

| | iPhone | Uhr |
|---|---|---|
| Target | `Pulsuhr` | `Pulsuhr Watch` (in die iPhone-App eingebettet) |
| Bundle-ID | `Moveaware.Pulsuhr` | `Moveaware.Pulsuhr.watchkitapp` |
| Minimum | iOS 18.0 | watchOS 11.0 |
| Info.plist | `Pulsuhr-Info.plist` + `INFOPLIST_KEY_…` | `PulsuhrWatch-Info.plist` + `INFOPLIST_KEY_…` |
| Entitlements | – | HealthKit |

Team `2Y6BBPH5Y4` (Moveaware). Die Bundle-IDs haben nichts mit FlyMagic zu tun. Pulsuhr ist ein
eigenes Produkt. Swift 5 Sprachmodus.

```bash
xcodebuild -project Pulsuhr.xcodeproj -scheme Pulsuhr -configuration Debug \
  -destination 'generic/platform=iOS' build
```

## 8. Fallstricke

1. **Info.plist-Falle.** Xcode erzeugt aus `INFOPLIST_KEY_…` nur eine **feste Liste** von Schlüsseln.
   `UIBackgroundModes`, `WKBackgroundModes` und `WKSupportsAlwaysOnDisplay` gehören nicht dazu und
   fallen **stillschweigend** weg. Deshalb stehen sie in echten Info.plist-Dateien
   (`INFOPLIST_FILE`). **Nach jeder Änderung am fertigen Paket prüfen:**
   ```bash
   app=$(ls -dt ~/Library/Developer/Xcode/DerivedData/Pulsuhr-*/Build/Products/Debug-iphoneos/Pulsuhr.app | head -1)
   plutil -extract UIBackgroundModes json -o - "$app/Info.plist"
   plutil -extract WKBackgroundModes json -o - "$(ls -d "$app"/Watch/*.app | head -1)/Info.plist"
   ```
2. **Die Info.plist-Dateien liegen ausserhalb der Quellordner.** `Pulsuhr/` und `Pulsuhr Watch/`
   sind synchronisierte Ordner (`PBXFileSystemSynchronizedRootGroup`). Alles darin wird
   automatisch als Ressource ins Paket gepackt.
3. **`project.pbxproj` ist von Hand geschrieben** (objectVersion 77, ohne Einträge pro Datei).
   Neue Swift-Dateien im Quellordner werden automatisch erfasst. **Nicht bearbeiten, solange
   Xcode das Projekt offen hat.**
4. **Xcodes Dialog „Update to recommended settings“ → Cancel.** Er bringt hier nichts (das sind
   ObjC-Warnungen, String-Kataloge, die es nicht gibt) und schreibt die pbxproj um.
5. **`-sdk iphoneos` nicht verwenden.** Es überschreibt auch das SDK der Uhren-Abhängigkeit, und
   `Funk` wird dann gegen iOS übersetzt (Fehler bei `WCSessionDelegate`). Immer `-destination`.
6. **SourceKit-Meldungen im Editor sind hier unzuverlässig** („No such module
   'WatchConnectivity'“, „unavailable in macOS“). Er prüft die Dateien ohne Target-Kontext.
   Massgebend ist `xcodebuild`.
7. **`discardWorkout()` ist synchron** (void, nicht async/throws). Davor `try? await endCollection`.
8. **Kein `finishWorkout`**, siehe §4.

## 9. Testen

- **Kein Simulator.** Dort gibt es weder Pulssensor noch Funkmodul. Getestet wird auf Stefans
  Apple Watch Ultra und seinem iPhone.
- **Die Uhr muss getragen werden.** Auf dem Tisch erkennt sie kein Handgelenk und liefert
  keinen Puls. Die App sieht dann kaputt aus, ist es aber nicht.
- Die Uhr-App kommt nicht immer automatisch mit. Dann über die Watch-App auf dem iPhone von Hand
  installieren. Ein neues Symbol erscheint auf der Uhr erst nach einer Neuinstallation.
- Ohne MyWhoosh prüfen: Ein BLE-Scanner auf dem Mac (z. B. LightBlue) zeigt, ob `180D`
  beworben wird und welche Bytes ankommen.
- **Stabilitätstest:** mit offener iPhone-App koppeln, dann das iPhone sperren, die Uhr-App in den
  Hintergrund schicken und eine ganze Einheit fahren.

### App-Symbol

`swift werkzeug-symbol.swift out.png` erzeugt das 1024er-PNG: ein Gesicht, die EKG-Linie ist der
lachende Mund (Krümmung 0.9). Das PNG kommt in **beide** `AppIcon.appiconset`. Es hat **keinen
Alpha-Kanal** (`noneSkipLast`), denn App Store Connect weist Symbole mit Alpha ab. Alles muss
innerhalb des einbeschriebenen Kreises liegen, weil watchOS rund beschneidet.

## 10. Offen

- Am Gerät noch nicht bestätigt (Stand 15.11.2026): Hält die Verbindung mit gesperrtem iPhone
  über eine ganze Einheit? Greift der Wiederanlauf nach einem Abräumen durch iOS wirklich?
- Akkuverbrauch der Uhr pro Stunde.
- Verbindet sich MyWhoosh beim nächsten Start von selbst wieder, oder muss man jedes Mal koppeln?
  Falls Letzteres: das Bonding-Experiment aus §6 versuchen.
- Wiederherstellung nach einem Absturz der Uhr-App (`handleActiveWorkoutRecovery`, §4). Nur auf
  Auftrag, falls sich Abstürze beim Testen tatsächlich zeigen.
- **App Store: zurückgestellt** (Stefan: *„nicht jetzt. wir warten.“*). Falls doch, braucht es
  eine Datenschutz- und eine Support-URL. Stefans Idee ist eine nicht verlinkte Seite unter
  flymagic.app. Die liegt im aerolog-Repo und dort **ausserhalb** der erlaubten Schreibbereiche,
  also nur auf ausdrücklichen Auftrag. Ausserdem braucht es Review-Notizen zu Guideline 4.2
  (minimale Funktionalität).

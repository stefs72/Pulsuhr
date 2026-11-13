# Pulsuhr

Gibt den Puls der Apple Watch als **Bluetooth-Pulsgurt** frei, damit Apps auf dem Mac ihn lesen
können — gebaut für **MyWhoosh**, funktioniert aber mit allem, was einen Brustgurt erwartet.

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
Apple Watch                      iPhone                        Mac
HealthKit-Workout  ──WatchConnectivity──▶  CoreBluetooth  ──BLE 0x180D──▶  MyWhoosh
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
2. Auf dem iPhone öffnen und offen lassen. Im Hintergrund versteckt iOS die Dienstkennung so, dass
   ein Mac sie kaum findet.
3. In MyWhoosh nach einem Pulssensor suchen. Das Gerät heisst **Pulsuhr**.

Zum Prüfen ohne MyWhoosh eignet sich ein BLE-Scanner auf dem Mac (z. B. LightBlue): Dort sieht man
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

Am Gerät noch nicht geprüft: ob die Freigabe durchhält, wenn der Arm sinkt, wie viel Akku das
kostet und ob MyWhoosh das Gerät auf Anhieb findet.

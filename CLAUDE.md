# CLAUDE.md – Arbeitsregeln für dieses Repo

Verbindlich für **jeden** Agenten, der an Pulsuhr arbeitet. Hier steht das *Wie*. Das *Was*
(Architektur, Protokolle, Fallstricke) steht in `ARCHITECTURE.md`.

## 1. Zuerst lesen

| Datei | Inhalt |
|---|---|
| `ARCHITECTURE.md` | **Die Hauptquelle.** Datenfluss, Komponenten, Hintergrundbetrieb, Fallstricke, Offenes |
| `README.md` | Kurzüberblick und Bedienung |

## 2. Was Pulsuhr ist

Die Apple Watch misst den Puls, das iPhone gibt ihn als Bluetooth-Pulsgurt (0x180D) frei, und
MyWhoosh auf dem Mac liest ihn. Ein eigenes Produkt (Moveaware), **nicht** Teil von FlyMagic.

## 3. Regeln

- **Einfachheit vor allem.** Eine Zahl, ein Knopf. Keine neuen Funktionen, Einstellungen oder
  Bildschirme ohne ausdrücklichen Auftrag. Stefan hat das mehrfach betont.
- **Volle Autonomie** in diesem Repo: ändern, bauen, committen ohne Einzelbestätigung. Gibt es
  später ein Remote: **kein Force-Push, nie.** Nur gezielt `git add <datei>`, kein `git add -A`.
- **Nichts in Health speichern.** Am Ende `discardWorkout()`, nie `finishWorkout`.
- **Kein automatischer Neustart der Trainings-Session** (Begründung in `ARCHITECTURE.md` §4).
- **Hintergrundmodi gehören in die Info.plist-Dateien**, nicht in `INFOPLIST_KEY_…`. Nach dem Bau
  im fertigen Paket prüfen (`ARCHITECTURE.md` §8).
- **`project.pbxproj` nicht bearbeiten, solange Xcode das Projekt offen hat.**
- **Kein Simulator.** Getestet wird auf Stefans Apple Watch Ultra und iPhone. Die Uhr muss
  getragen werden.
- Bauen mit `-destination 'generic/platform=iOS'`, nie mit `-sdk iphoneos`.
- Sprache: Deutsch, Schweizer Schreibweise („ss“ statt „ß“) in allem, was Nutzer sehen. Code
  und Kommentare sind deutsch; Kommentare erklären das *Warum*.
- Nach jeder Änderung, die das Konzept berührt: `ARCHITECTURE.md` nachführen (Datum im Kopf).

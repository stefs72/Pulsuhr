# Datenschutz – Pulsuhr

_Stand: 16. November 2026_

Pulsuhr erhebt, speichert und überträgt **keine Daten an uns oder an Dritte**.

## Was die App tut

- Die **Apple-Watch-App** liest während einer laufenden Messung deinen Puls über HealthKit. Dazu
  startet sie eine Trainingseinheit, denn nur so misst die Uhr fortlaufend. Die Einheit wird am
  Ende **verworfen**. Es wird nichts in Health gespeichert.
- Die Uhr schickt den aktuellen Pulswert über die Apple-eigene Verbindung (WatchConnectivity) an
  die **iPhone-App**.
- Das iPhone gibt den Wert per **Bluetooth** als Standard-Pulsgurt frei. Lesen kann ihn nur ein
  Gerät in Funkreichweite, das du selbst damit verbindest, zum Beispiel Zwift oder MyWhoosh auf
  deinem Computer, Tablet oder Apple TV.

## Was die App nicht tut

- Keine Konten, keine Anmeldung.
- Keine Verbindung ins Internet, keine Server.
- Keine Werbung, keine Analyse- oder Tracking-Dienste.
- Keine Speicherung von Pulswerten, weder auf der Uhr noch auf dem iPhone.

## Berechtigungen

| Berechtigung | Wozu |
|---|---|
| Health – Puls lesen | den aktuellen Puls anzeigen und freigeben |
| Health – Training | die Trainingseinheit starten, die die Dauermessung einschaltet. Sie wird nicht gesichert |
| Bluetooth | den Puls als Pulsgurt freigeben |

## Kontakt

Fragen und Probleme: [github.com/stefs72/Pulsuhr/issues](https://github.com/stefs72/Pulsuhr/issues)

Anbieter: Moveaware

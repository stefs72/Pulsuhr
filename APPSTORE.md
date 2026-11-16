# App Store – Einreichung Pulsuhr 1.0

Alles, was App Store Connect verlangt, zum Hineinkopieren. Was noch fehlt, steht unter
**Offen**.

## Eckdaten

| Feld | Wert |
|---|---|
| Name | Pulsuhr |
| Untertitel | Apple-Watch-Puls als Pulsgurt |
| Bundle-ID | `Moveaware.Pulsuhr` (Uhr: `Moveaware.Pulsuhr.watchkitapp`) |
| Version / Build | 1.0 / 1 |
| Kategorie | Gesundheit & Fitness |
| Geräte | iPhone + Apple Watch (kein iPad) |
| Datenschutz-URL | https://github.com/stefs72/Pulsuhr/blob/main/PRIVACY.md |
| Support-URL | https://github.com/stefs72/Pulsuhr/issues |
| Copyright | 2026 Moveaware |
| Altersfreigabe | 4+ (alle Fragen „Nein“) |
| Verschlüsselung | keine eigene (`ITSAppUsesNonExemptEncryption = false` in `Pulsuhr-Info.plist`) |

### App-Datenschutz („Nährwerttabelle“)

**„Es werden keine Daten erfasst.“** Der Puls verlässt das Gerät nur per Bluetooth zu einem
Empfänger, den die Person selbst koppelt. Er geht nie an den Anbieter oder an Dritte.

## Beschreibung (Deutsch)

> Pulsuhr macht deine Apple Watch zum Bluetooth-Pulsgurt.
>
> Starte die Messung auf der Uhr, und dein iPhone gibt den Puls als Standard-Pulsgurt frei.
> Trainings-Apps auf dem Mac, zum Beispiel MyWhoosh, finden ihn wie einen Brustgurt. Nach dem
> ersten Koppeln verbinden sie sich von selbst wieder.
>
> • Eine Zahl, ein Knopf, keine Einstellungen
> • Läuft im Hintergrund weiter, auch mit gesperrtem iPhone
> • Nichts wird in Health gespeichert, deine Ringe bleiben unberührt
> • Keine Konten, kein Internet, keine Werbung
>
> Warum das iPhone? Die Apple Watch selbst kann keinen Bluetooth-Pulsgurt anbieten. Das iPhone
> übernimmt das für sie.

**Schlüsselwörter:** Puls,Pulsgurt,Herzfrequenz,Bluetooth,MyWhoosh,Zwift,Rollentrainer,Indoor,Radfahren,Brustgurt

**Werbetext:** Dein Puls von der Uhr direkt in die Trainings-App auf dem Mac, ohne Brustgurt.

## Hinweise für die Prüfung (App Review Notes, englisch)

> Pulsuhr broadcasts the heart rate measured by Apple Watch as a standard Bluetooth Low Energy
> Heart Rate Service (0x180D), so indoor-cycling apps on a Mac (e.g. MyWhoosh) can use the watch
> instead of a chest strap.
>
> Why an iPhone app: watchOS does not allow an app to act as a Bluetooth peripheral
> (CBPeripheralManager is unavailable on watchOS). The watch measures, the iPhone relays the
> value via WatchConnectivity and advertises it over Bluetooth.
>
> How to test:
> 1. Wear the Apple Watch and open Pulsuhr on it. A measurement starts and the heart rate appears.
> 2. Open Pulsuhr on the iPhone. The status shows that the heart rate is being shared.
> 3. On a Mac or another device, open any app that reads Bluetooth heart-rate sensors (e.g.
>    MyWhoosh, or the free BLE scanner LightBlue) and connect to "Pulsuhr".
> Note: the watch must be worn. Without wrist detection it delivers no heart rate.
>
> HealthKit: the watch app starts an HKWorkoutSession only because that is the only way to get
> continuous heart-rate readings. The workout is discarded at the end (discardWorkout). Nothing
> is written to Health. Heart-rate values are not stored and never leave the user's devices
> except over Bluetooth to a receiver the user pairs themselves. No accounts, no network access,
> no analytics.
>
> Background mode "bluetooth-peripheral" keeps the heart-rate sensor available to the paired
> receiver while the iPhone is locked during a workout.

## Screenshots

- **iPhone 6,9"** (z. B. 1320 × 2868): 1–3 Bilder. Mindestens die Hauptansicht mit Puls und
  „Empfänger verbunden“.
- **Apple Watch** (Ultra: 410 × 502 bzw. 422 × 514, je nach Modell): 1–2 Bilder. Die Messung mit Pulszahl.

Am einfachsten direkt am Gerät während einer echten Messung aufnehmen.

## Offen

- Bluetooth-Text in den Build-Einstellungen: „koennen“ → „können“, und „auf dem Mac“ →
  „zum Beispiel auf dem Mac“. Steht in `project.pbxproj`, also erst bei geschlossenem Xcode.
- Preis festlegen (Vorschlag: gratis).
- Screenshots aufnehmen.
- Archivieren und hochladen (Xcode → Product → Archive), Eintrag in App Store Connect anlegen.
- Optional, aber hilfreich gegen eine Ablehnung nach Regel 4.2: ein kurzes Bildschirmvideo
  (Uhr + MyWhoosh), als Link in den Prüfhinweisen.

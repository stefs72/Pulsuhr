# App Store – Einreichung Pulsuhr 1.0

**Stand 16.11.2026: Build 1.0 (1) hochgeladen.**

Alles, was App Store Connect verlangt, zum Hineinkopieren. Was noch fehlt, steht unter
**Offen**.

## Eckdaten

| Feld | Wert |
|---|---|
| Name | Pulsuhr |
| Untertitel | Apple-Watch-Puls als Pulsgurt |
| Bundle-ID | `Moveaware.Pulsuhr` (Uhr: `Moveaware.Pulsuhr.watchkitapp`) |
| Version / Build | 1.0 / 1 |
| SKU | `pulsuhr-2` |
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
> Gemacht fürs Indoor-Training mit Zwift und MyWhoosh: Starte die Messung auf der Uhr, und dein
> iPhone gibt den Puls als Standard-Bluetooth-Pulsgurt frei. Jeder Empfänger, der einen Brustgurt
> lesen kann, findet ihn: Mac, PC, iPad, Apple TV oder Radcomputer. Nach dem ersten Koppeln
> verbindet er sich von selbst wieder.
>
> • Eine Zahl, ein Knopf, keine Einstellungen
> • Läuft im Hintergrund weiter, auch mit gesperrtem iPhone
> • Nichts wird in Health gespeichert, deine Ringe bleiben unberührt
> • Keine Konten, kein Internet, keine Werbung
>
> Warum das iPhone? Die Apple Watch selbst kann keinen Bluetooth-Pulsgurt anbieten. Das iPhone
> übernimmt das für sie.

**Schlüsselwörter:** Puls,Pulsgurt,Herzfrequenz,Bluetooth,Rollentrainer,Indoor,Radfahren,Brustgurt,Smarttrainer,Herzfrequenzsensor

**Werbetext:** Dein Puls von der Uhr direkt in Zwift, MyWhoosh und Co., ohne Brustgurt.

Zwift und MyWhoosh **nicht** in die Schlüsselwörter: Fremde App- und Markennamen dort weist Apple
ab (Regel 2.3.7). In Beschreibung und Werbetext als „funktioniert mit“ ist es üblich.

## Hinweise für die Prüfung (App Review Notes, englisch)

> Pulsuhr broadcasts the heart rate measured by Apple Watch as a standard Bluetooth Low Energy
> Heart Rate Service (0x180D). It is made for indoor cycling with apps like Zwift and MyWhoosh:
> any receiver that accepts a Bluetooth chest strap (Mac, PC, iPad, Apple TV, bike computer) can
> use the watch instead.
>
> Why an iPhone app: watchOS does not allow an app to act as a Bluetooth peripheral
> (CBPeripheralManager is unavailable on watchOS). The watch measures, the iPhone relays the
> value via WatchConnectivity and advertises it over Bluetooth.
>
> How to test:
> 1. Wear the Apple Watch and open Pulsuhr on it. A measurement starts and the heart rate appears.
> 2. Open Pulsuhr on the iPhone. The status shows that the heart rate is being shared.
> 3. On any other device, open an app that reads Bluetooth heart-rate sensors (e.g. Zwift,
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

Fertig im Ordner `appstore/`, ohne Alpha-Kanal:

| Datei | Grösse | Für |
|---|---|---|
| `iphone-1-titel.png` | 1290 × 2796 | iPhone 6,9" / 6,7" – **empfohlen**, mit Überschrift |
| `iphone-1-pur.png` | 1290 × 2796 | Alternative ohne Überschrift (leicht hochskaliert, Quelle 960 px) |
| `watch-1.png` | 410 × 502 | Apple Watch Ultra |

Neu erzeugen: `swift werkzeug-storebilder.swift <quelle.jpg> <ziel.png> titel|pur`. Swift darf
nicht vom Schreibtisch lesen, also die Quelle vorher in einen anderen Ordner kopieren.

## Offen

Hinweis für spätere Einreichungen: Den App-Eintrag **nicht** von Hand in App Store Connect anlegen,
sondern beim ersten Upload von Xcode anlegen lassen (Organizer → Distribute App). Von Hand war die
Bundle-ID der Uhr vorausgewählt; die nachträgliche Umstellung hat nicht gegriffen, der Eintrag
musste entfernt und neu angelegt werden (SKU jetzt `pulsuhr-2`).


- Zwift am Gerät testen, bevor es im Store-Text steht (bisher nur MyWhoosh geprüft).
- Preis festlegen (Vorschlag: gratis).
- Optional, aber hilfreich gegen eine Ablehnung nach Regel 4.2: ein kurzes Bildschirmvideo
  (Uhr + MyWhoosh), als Link in den Prüfhinweisen.

# App Store – Einreichung Pulsuhr 1.0

**Stand 16.11.2026: Version 1.0 (1) zur App-Prüfung eingereicht, automatische Veröffentlichung nach Freigabe.**

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
| Kategorie | Sport |
| Geräte | iPhone + Apple Watch (kein iPad). Mac (Apple Silicon) und Vision Pro **abgewählt**: ohne gekoppelte Uhr nutzlos |
| Preis | gratis, alle 175 Länder |
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

## Hinweise für die Prüfung (App Review Notes)

So in App Store Connect eingetragen (Deutsch):

> Pulsuhr gibt den Puls, den die Apple Watch misst, als Standard-Bluetooth-Pulsgurt frei
> (Bluetooth Low Energy Heart Rate Service, 0x180D). Gemacht ist die App fürs Indoor-Training mit
> Apps wie Zwift und MyWhoosh: Jeder Empfänger, der einen Bluetooth-Brustgurt liest (Mac, PC,
> iPad, Apple TV, Radcomputer), kann stattdessen die Uhr verwenden.
>
> Warum eine iPhone-App: Unter watchOS darf eine App kein Bluetooth-Peripheriegerät sein
> (CBPeripheralManager ist unter watchOS nicht verfügbar). Die Uhr misst, das iPhone erhält den
> Wert über WatchConnectivity und gibt ihn per Bluetooth frei.
>
> So testen:
> 1. Apple Watch tragen und Pulsuhr darauf öffnen. Die Messung startet, der Puls erscheint.
> 2. Pulsuhr auf dem iPhone öffnen. Die Statuszeile zeigt, dass der Puls freigegeben ist.
> 3. Auf einem anderen Gerät eine App öffnen, die Bluetooth-Pulssensoren liest (z. B. Zwift,
>    MyWhoosh oder den kostenlosen BLE-Scanner LightBlue), und mit „Pulsuhr“ verbinden.
> Hinweis: Die Uhr muss getragen werden. Ohne Handgelenkerkennung liefert sie keinen Puls.
>
> HealthKit: Die Uhr-App startet eine HKWorkoutSession nur, weil die Uhr nur so fortlaufend den
> Puls misst. Die Einheit wird am Ende verworfen (discardWorkout), in Health wird nichts
> gespeichert. Pulswerte werden nicht gespeichert und verlassen die Geräte nur per Bluetooth zu
> einem Empfänger, den die Person selbst koppelt. Keine Konten, kein Internet, keine Analyse.
> Eine Anmeldung ist nicht nötig.
>
> Der Hintergrundmodus „bluetooth-peripheral“ hält den Pulssensor für den gekoppelten Empfänger
> verfügbar, während das iPhone beim Training gesperrt ist.

## Screenshots

Fertig im Ordner `appstore/`, ohne Alpha-Kanal:

| Datei | Grösse | Für |
|---|---|---|
| `iphone-1.png` | 1206 × 2622 | iPhone mit Dynamic Island (6,1"/6,3") – mit Überschrift |
| `watch-1.png` | 410 × 502 | Apple Watch Ultra |

App Store Connect nimmt fürs iPhone nur noch 1206 × 2622 / 1179 × 2556 (Stand 16.11.2026);
1290 × 2796 passte nicht mehr.

Neu erzeugen: `swift werkzeug-storebilder.swift <quelle.jpg> <ziel.png> titel|pur [breite höhe]`. Swift darf
nicht vom Schreibtisch lesen, also die Quelle vorher in einen anderen Ordner kopieren.

## Offen

Hinweis für spätere Einreichungen: Den App-Eintrag **nicht** von Hand in App Store Connect anlegen,
sondern beim ersten Upload von Xcode anlegen lassen (Organizer → Distribute App). Von Hand war die
Bundle-ID der Uhr vorausgewählt; die nachträgliche Umstellung hat nicht gegriffen, der Eintrag
musste entfernt und neu angelegt werden (SKU jetzt `pulsuhr-2`).


- Zwift am Gerät testen, bevor es im Store-Text steht (bisher nur MyWhoosh geprüft).
- Optional, aber hilfreich gegen eine Ablehnung nach Regel 4.2: ein kurzes Bildschirmvideo
  (Uhr + MyWhoosh), als Link in den Prüfhinweisen.

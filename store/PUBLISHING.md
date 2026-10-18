# Hopstone in de Play Store zetten - stappenplan

Wat ik al voor je gedaan heb: de app, het icoon, schermafbeeldingen, de feature graphic, de teksten
(`store/listing.md`), de privacyverklaring (`docs/privacy.html`) en de bouw-workflow voor de
upload-versie. Hieronder staat wat jij nog zelf moet doen (dat kan ik niet voor je doen).

## 1. Google Play-ontwikkelaarsaccount ($25, eenmalig)
Ga naar https://play.google.com/console en maak een account. Kies "persoonlijk" als je het als
privépersoon doet. Google vraagt je identiteit te bevestigen; dat kan een paar dagen duren.
Let op: bij een nieuw persoonlijk account moet je vaak eerst een "gesloten test" draaien met
ongeveer 12 testers die het 14 dagen lang meedoen, voordat je naar productie mag. Controleer de
actuele regels in je Play Console onder "Productie".

## 2. De upload-sleutel op GitHub zetten (eenmalig)
Ik heb een upload-sleutel voor je gemaakt en stuur die los (bestand `secrets.txt` en
`UPLOAD_KEYSTORE_BASE64.txt`). Plaats ze op GitHub:
1. Open de repository -> Settings -> Secrets and variables -> Actions -> "New repository secret".
2. Maak vier secrets (naam precies zo):
   - `UPLOAD_KEYSTORE_BASE64` = de hele inhoud van `UPLOAD_KEYSTORE_BASE64.txt`
   - `UPLOAD_KEYSTORE_PASSWORD` = de waarde uit `secrets.txt`
   - `UPLOAD_KEY_ALIAS` = `upload`
   - `UPLOAD_KEY_PASSWORD` = de waarde uit `secrets.txt`
3. Bewaar `upload.jks` en de wachtwoorden ook ergens veilig (wachtwoordmanager). Verlies je ze, dan kan
   Google een nieuwe upload-sleutel voor je instellen, maar dat kost tijd.

## 3. De app aanmaken in de Play Console
- "Create app": naam "Hopstone: Peg Solitaire", taal Engels (of Nederlands), type "Game", "Free".
- App-ID: `com.hopstone.hopstone` (staat al in de app).
- Zet "Play App Signing" aan (standaard).

## 4. Het product voor de aankoop maken
Monetize -> Products -> In-app products -> Create:
- Product-ID: **`hopstone_full`** (precies zo, anders vindt de app het niet)
- Type: eenmalig product (niet-consumeerbaar), naam "Full game", prijs EUR 2,99 (of wat je wilt)
- Activeer het product.

## 5. De bundel bouwen
GitHub -> Actions -> "Release bundle" -> "Run workflow". Na een paar minuten staat onder
"Artifacts" het bestand `hopstone-release-bundle` (daarin zit `app-release.aab`). Download dat.
Elke keer dat je dit opnieuw draait, krijgt de bundel automatisch een hoger versienummer.

## 6. Uploaden en testen
Play Console -> Testing -> Internal testing (of Closed testing) -> nieuwe release -> upload het `.aab`.
Voeg jezelf (en testers) toe via hun Gmail-adres. Installeer via de testlink. Alleen op deze manier
werkt de echte aankoop (met een "licentietester" kost het niets). Zet je e-mail bij
Setup -> License testing.

## 7. Store-pagina invullen
- Teksten: `store/listing.md`
- Icoon 512: `store/icon-512.png`, feature graphic: `store/feature-graphic.png`
- Schermafbeeldingen: `store/screenshots/`
- Privacyverklaring-URL: zet GitHub Pages aan (Settings -> Pages -> Deploy from branch -> map `/docs`).
  De URL wordt dan `https://robinson-97.github.io/solitaire-app/privacy.html`. Vul eerst je e-mail in
  `docs/privacy.html` in.

## 8. Formulieren in de Play Console
- Content rating: vragenlijst invullen (geen geweld, geen gokken met echt geld). De draws gebruiken
  alleen punten uit het spel, geen echt geld. Kies dus "geen gokken". Verwachte rating: 3+/Everyone.
- Data safety: "Geen gegevens verzameld, geen gegevens gedeeld". (De aankoop loopt via Google.)
- Ads: "Nee, bevat geen advertenties".
- Doelgroep: 13+ of alle leeftijden zonder "kinderen" als hoofddoelgroep (voorkomt extra Families-regels).
- Overig: land/prijs per land naar wens.

## 9. Productie
Als de test goed ging (en je aan de testersregel voldoet): Production -> Create release -> dezelfde
bundel -> versturen ter beoordeling. Beoordeling duurt meestal enkele dagen.

## Belangrijk om te weten
- Testbuilds van GitHub (`hopstone-test.apk`) hebben alles open (testmodus) en een andere
  handtekening dan de Play-versie. Verwijder die eerst voor je de Play-versie installeert.
- Het icoon, de teksten en schermafbeeldingen mag je zelf aanpassen. Het icoon maak je opnieuw met
  `python3 tool/make_icon.py`, de schermafbeeldingen met
  `flutter test tool/shots/store_shots_test.dart --no-test-assets`.

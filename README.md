# Chiourim BA

Application iPhone pour lire la bibliothèque de Benjamin Abbou : Guemara, hassidout et halakha, en hébreu et en français, mises en page dans l'application. Les textes viennent du dépôt public `bben2/chiourimsba-donnees`. Ce qui a été ouvert reste lisible hors connexion.

Swift uniquement, iOS 17, aucune dépendance tierce. Identifiant : `com.chiourimsba.app`. Nom affiché : Chiourim BA.

## Lancer sur un iPhone

1. Installer [XcodeGen](https://github.com/yonaskolb/XcodeGen), puis à la racine du dépôt :

   ```bash
   xcodegen generate
   open ChiourimBA.xcodeproj
   ```

2. Brancher l'iPhone. Dans Xcode : cible **ChiourimBA**, onglet **Signing & Capabilities**, cocher **Automatically manage signing**, choisir son équipe **Personal Team** (un identifiant Apple gratuit suffit).
3. Choisir l'iPhone comme destination et lancer.

`DEVELOPMENT_TEAM` est vide dans `project.yml` : Xcode le remplit au moment de signer, sans le committer.

## TestFlight, puis l'App Store

1. S'inscrire au [Apple Developer Program](https://developer.apple.com/programs/) (99 $ par an).
2. Dans Xcode, remplacer l'équipe personnelle par l'équipe du programme, puis **Product → Archive**.
3. Dans l'Organizer : **Distribute App → App Store Connect → Upload**.
4. Sur App Store Connect, remplir la fiche et ajouter des testeurs dans TestFlight.
5. La lecture native, le hors-ligne, les favoris, les annotations et la reprise de lecture sont le cœur de l'app.

L'application ne collecte aucune donnée de suivi. Le fichier `ChiourimBA/PrivacyInfo.xcprivacy` le déclare. Un signalement d'erreur est un envoi volontaire vers `https://chiourimsba.vercel.app/api/signaler`, sans jeton dans l'app.

## D'où viennent les textes

Constante `SourceDonnees.base` :

`https://raw.githubusercontent.com/bben2/chiourimsba-donnees/main/`

Le catalogue est `catalogue.json`. Une page est `guemara/<Traité>/<amud>.json` ou `hassidout/<livre>/<section>.json`. Le cache est dans Application Support (`ChiourimBA/fichiers`). Au lancement, le catalogue est rafraîchi si le réseau est là. Le bouton « Télécharger ce livre pour le lire hors ligne » récupère toutes les unités d'une œuvre.

Sur le simulateur, si `~/sefaria_translate/donnees/` contient déjà les fichiers, ils sont lus à la place du réseau.

Le portail « Chiourim BA » et « Questions à l'IA » sont les deux seules pages web (plus les schémas SVG). Le reste est natif.

## Mon espace

Favoris, position de lecture, surlignages et notes sont dans SwiftData, sur l'appareil. Les signalements en attente (réseau absent, ou réponse 503 « Les signalements ouvrent bientôt ») sont dans `signalements.json` et renvoyés au lancement suivant.

`Config.connexionActive` reste faux tant que le compte développeur payant n'est pas en place : le bouton « Se connecter avec Apple » est prêt dans le code, pas affiché. `Config.urlDons` reste vide : « Nous soutenir » est caché. Les deux se lisent dans l'Info.plist (`ConnexionActive`, `URLDons`) le jour où on les remplira.

## Ajouter une collection

Le catalogue distant porte les œuvres. L'app affiche les collections `guemara`, `hassidout` et `halakha`. Une collection vide, comme la halakha aujourd'hui, montre l'écran « Bientôt dans l'appli ».

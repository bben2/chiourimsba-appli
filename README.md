# Chiourim BA

Application iPhone pour lire la bibliothèque de Benjamin Abbou : chiourim, Guemara, hassidout et halakha. Le texte est chargé depuis les dépôts GitHub publics, mis en cache sur l'appareil, et relu hors connexion. L'application ne contacte pas Vercel pour afficher les pages.

Swift uniquement, iOS 17, aucune dépendance tierce. Identifiant : `com.chiourimsba.app`. Nom affiché : Chiourim BA.

## Lancer sur un iPhone

1. Installer [XcodeGen](https://github.com/yonaskolb/XcodeGen), puis à la racine du dépôt :

   ```bash
   xcodegen generate
   open ChiourimBA.xcodeproj
   ```

2. Brancher l'iPhone. Dans Xcode : cible **ChiourimBA**, onglet **Signing & Capabilities**, cocher **Automatically manage signing**, choisir son équipe **Personal Team** (un identifiant Apple gratuit suffit). Aucun compte développeur payant n'est nécessaire pour installer sur son propre téléphone.
3. Choisir l'iPhone comme destination et lancer. La signature personnelle est valable environ sept jours ; il suffit de relancer depuis Xcode pour la renouveler.

`DEVELOPMENT_TEAM` est vide dans `project.yml` : Xcode le remplit au moment de signer, sans le committer.

## TestFlight, puis l'App Store

1. S'inscrire au [Apple Developer Program](https://developer.apple.com/programs/) (99 $ par an).
2. Dans Xcode, remplacer l'équipe personnelle par l'équipe du programme, puis **Product → Archive**.
3. Dans l'Organizer : **Distribute App → App Store Connect → Upload**.
4. Sur [App Store Connect](https://appstoreconnect.apple.com), attendre le traitement, remplir la fiche (captures, description, politique de confidentialité), ajouter des testeurs internes dans TestFlight.
5. Quand la lecture hors connexion, les favoris, la reprise, le téléchargement d'un traité et la taille du texte ont été vérifiés sur un appareil, soumettre à la revue. Ces fonctions sont le cœur de l'app : ce n'est pas une simple coquille autour d'un site.

L'application ne collecte aucune donnée. Le fichier `ChiourimBA/PrivacyInfo.xcprivacy` le déclare.

## Schéma `chiourim://`

La WebView ne charge jamais `raw.githubusercontent.com` directement : GitHub sert ces fichiers en `text/plain` et le HTML s'afficherait en code source. Un `WKURLSchemeHandler` intercepte `chiourim://`, télécharge le fichier, et le renvoie avec le type MIME de l'extension (`.html` → `text/html; charset=utf-8`, et de même pour css, js, svg, png, jpg, webp, pdf, json, woff2…).

| Hôte | Dépôt | URL publique partagée |
|---|---|---|
| `chiourim://portail/…` | `bben2/chiourimsba-portail` | `https://chiourimsba.vercel.app/…` |
| `chiourim://guemara/…` | `bben2/chiourimsba-guemara` | `https://guemara.vercel.app/…` |
| `chiourim://hassidout/…` | `bben2/chiourimsba-hassidout` | `https://hassidout.vercel.app/…` |
| `chiourim://halakha/…` | `bben2/chiourimsba-halakha` | `https://halakha.vercel.app/…` |

Un chemin qui se termine par `/` sert `index.html`. Le cache est dans `Library/Caches/Contenu/<site>/<chemin>`.

Réécriture des liens, dans la navigation et dans le HTML servi :

| Lien rencontré | Devenu |
|---|---|
| `https://chiourimsba.vercel.app/…` | `chiourim://portail/…` |
| `https://guemara.vercel.app/…` | `chiourim://guemara/…` |
| `https://hassidout.vercel.app/…` | `chiourim://hassidout/…` |
| `https://halakha.vercel.app/…` | `chiourim://halakha/…` |
| `https://otsrot.vercel.app/…` | bloqué |
| `mailto:` | application Mail |
| autre lien (Sefaria, etc.) | Safari |

Le partage envoie l'adresse Vercel, pour qu'un correspondant sans l'application puisse ouvrir la page. Le script `chat.js` est retiré : pour le rétablir plus tard, passer `DiscussionWidget.estActive` à `true`.

## Ajouter un site

Une ligne dans le tableau `Bibliotheque.sites` (`ChiourimBA/Modele/Bibliotheque.swift`) :

```swift
Site(id: "michna", depot: "chiourimsba-michna", hoteVercel: "michna.vercel.app", titreOnglet: "Michna", nom: "Michna", symbole: "book"),
```

L'onglet, l'hôte `chiourim://michna/` et la réécriture du domaine Vercel suivent cette ligne. Le dépôt GitHub doit être public, sur la branche `main`, et servir un `index.html` à la racine.

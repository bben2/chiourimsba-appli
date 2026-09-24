# Mission pour Grok : créer l'application iPhone « Chiourim BA »

Tu travailles seul, de bout en bout, et tu livres tout **dans ce dépôt GitHub** (`bben2/chiourimsba-ios`, branche `main`).
Tu ne peux pas compiler pour iOS de ton côté : c'est normal. Claude récupère ce dépôt sur le Mac de Benjamin, génère le
projet, compile avec Xcode 26 et te renvoie les erreurs éventuelles. Écris donc un code soigné, conforme au SDK iOS 17+.
Réponds et commente en français. Ne pose de question que si tu es réellement bloqué.

## 1. Ce que fait l'application

Chiourim BA est une bibliothèque de textes juifs traduits en français par Benjamin Abbou : Guemara, hassidout,
halakha, et des chiourim hebdomadaires. Aujourd'hui elle existe sous forme de sites web statiques.
L'application doit permettre de **retrouver et lire toute cette bibliothèque sur iPhone**, confortablement, y compris
hors connexion.

**Règle fondatrice : l'application charge son contenu depuis GitHub, jamais depuis Vercel.**
Les sites existent aussi sur Vercel, mais l'appli ne doit pas en dépendre.

## 2. Où est le contenu (dépôts GitHub, branche `main`)

| Onglet | Dépôt | Page d'entrée |
|---|---|---|
| Accueil / Chiourim | `bben2/chiourimsba-portail` | `index.html` |
| Guemara | `bben2/chiourimsba-guemara` | `index.html` |
| Hassidout | `bben2/chiourimsba-hassidout` | `index.html` |
| Halakha | `bben2/chiourimsba-halakha` | `index.html` |

Ce sont des sites **100 % statiques** : HTML, CSS, JS, images, PDF. Pas de base de données.
Les dépôts sont **publics** : aucune clé, aucun jeton n'est nécessaire, et **tu ne dois en mettre aucun dans l'appli**.

URL brute d'un fichier :
`https://raw.githubusercontent.com/bben2/<dépôt>/main/<chemin>`
Dernier commit d'un dépôt (pour savoir s'il y a du nouveau, sans jeton) :
`https://api.github.com/repos/bben2/<dépôt>/commits/main` → champ `sha`

## 3. Le piège technique à éviter absolument

**N'affiche PAS les URL `raw.githubusercontent.com` directement dans une WKWebView.**
GitHub sert ces fichiers en `text/plain` avec l'en-tête `X-Content-Type-Options: nosniff` : la page s'afficherait en
code source, et les scripts et feuilles de style seraient bloqués.

**Architecture imposée :**

1. Un `WKURLSchemeHandler` sur un schéma à toi, `chiourim://`.
   `chiourim://guemara/Taanit_2a.html` → le handler télécharge
   `https://raw.githubusercontent.com/bben2/chiourimsba-guemara/main/Taanit_2a.html`, puis le renvoie à la WebView
   **avec le bon type MIME** déduit de l'extension (`.html` → `text/html; charset=utf-8`, `.css`, `.js`, `.svg`,
   `.png`, `.jpg`, `.webp`, `.pdf`, `.json`, `.woff2`, etc.).
2. Correspondance hôte → dépôt : `portail`, `guemara`, `hassidout`, `halakha` → `chiourimsba-<hôte>`.
3. Un chemin qui se termine par `/` sert `index.html`.
4. Les liens absolus internes (`/orach-chayim/001.html`) doivent rester dans le même site : c'est pour ça que chaque
   site a son propre hôte dans le schéma.
5. **Les pages contiennent des liens écrits en dur vers les sites Vercel.** Intercepte-les dans
   `WKNavigationDelegate` et réécris-les :
   - `https://chiourimsba.vercel.app/…` → `chiourim://portail/…`
   - `https://guemara.vercel.app/…` → `chiourim://guemara/…`
   - `https://hassidout.vercel.app/…` → `chiourim://hassidout/…`
   - `https://halakha.vercel.app/…` → `chiourim://halakha/…`
   - `https://otsrot.vercel.app/…` → **bloqué** : ce site ne doit jamais apparaître dans l'appli.
   - `mailto:` (lien « Signaler une erreur ») → `UIApplication.shared.open`.
   - Tout autre lien externe (Sefaria, etc.) → s'ouvre dans Safari (`SFSafariViewController`).
   - Fais la même réécriture sur les requêtes de sous-ressources si besoin.
6. Les pages chargent un widget de discussion depuis `https://chiourimsba.vercel.app/chat.js`, qui appelle une API
   Vercel. Dans cette première version, **masque-le** en injectant un `WKUserScript` qui empêche ce script de
   s'exécuter, ou qui cache son bouton. Garde le mécanisme simple à réactiver plus tard.

## 4. Cache et lecture hors connexion

- Tout fichier téléchargé est enregistré dans `Library/Caches/Contenu/<site>/<chemin>`, et réutilisé ensuite.
- Stratégie : on sert le cache tout de suite s'il existe. En tâche de fond, au lancement puis toutes les 24 h, on
  compare le `sha` du dernier commit de chaque dépôt à celui qu'on a mémorisé. S'il a changé, on marque le cache de
  ce site comme « à revalider » : chaque page est alors retéléchargée à sa prochaine ouverture.
- Hors connexion, une page jamais ouverte affiche un écran clair : « Cette page n'a pas encore été téléchargée ».
- Bouton **« Télécharger pour lire hors ligne »** sur un sommaire de traité ou de livre : il récupère toutes les pages
  liées depuis ce sommaire. Barre de progression, possibilité d'annuler.
- **Les PDF des chiourim sont lourds (jusqu'à 60 Mo).** Ne les télécharge qu'à la demande, jamais en masse. Affiche-les
  avec `PDFKit`.
- Réglage « Espace utilisé » avec un bouton pour vider le cache.

## 5. Interface

- SwiftUI, **iOS 17 minimum**, iPhone d'abord ; l'iPad fonctionne sans effort particulier.
- `TabView` à 5 onglets : **Accueil, Guemara, Hassidout, Halakha, Favoris**. Chaque onglet garde son propre
  historique de navigation (retour arrière par balayage et par bouton).
- Barre d'outils de lecture : retour, partager (partage l'adresse publique Vercel équivalente, pour qu'un ami puisse
  l'ouvrir sans l'appli), ajouter aux favoris, taille du texte (A− / A+ via `pageZoom`).
- **Favoris** : titre de la page, site, date d'ajout. Stockés en local avec SwiftData.
- **Reprise de lecture** : chaque onglet rouvre la dernière page lue.
- Recherche rapide dans les titres des favoris et de l'historique.
- Mode sombre suivi automatiquement. Interface **en français**. L'hébreu est déjà en droite-à-gauche dans le HTML :
  n'y touche pas.
- Icône d'application : sobre, bleu nuit et parchemin, **aucune lettre, aucun mot, aucun texte**. Aucune figure
  humaine, aucune silhouette dans le ciel. Fournis-la en 1024×1024.

## 6. Contraintes

- Swift et frameworks Apple uniquement : **aucune dépendance tierce**, aucun SDK de statistiques, aucun suivi.
- Fournis le fichier `PrivacyInfo.xcprivacy` : aucune donnée collectée.
- Aucun jeton, aucune clé, aucun mot de passe dans le code ni dans le dépôt.
- Bundle identifier : `com.chiourimsba.app`. Nom affiché : **Chiourim BA**.
- Le projet doit compiler **sans avertissement** sous Xcode 26.

## 7. Règle Apple à anticiper

L'App Store refuse souvent les applications qui ne sont qu'un site web dans une coquille (règle 4.2 « Minimum
Functionality »). Ce qui justifie une vraie application ici : la **lecture hors connexion**, les **favoris**, la
**reprise de lecture**, le **téléchargement d'un traité entier** et le **réglage du texte**. Soigne-les : c'est ce qui
fera accepter l'appli.

## 8. Où livrer, sous quelle forme

- **Tout va dans ce dépôt** `bben2/chiourimsba-ios`, branche `main`. Structure attendue :
  ```
  project.yml              ← description du projet pour XcodeGen (OBLIGATOIRE)
  ChiourimBA/              ← sources Swift, Assets.xcassets (dont l'icône), Info.plist, PrivacyInfo.xcprivacy
  ChiourimBATests/         ← tests unitaires
  README.md
  ```
- **N'écris pas de `.xcodeproj` à la main** : un `project.pbxproj` rédigé à la main casse presque toujours.
  Fournis un `project.yml` pour **XcodeGen** (cible application iOS 17, cible de tests, bundle id `com.chiourimsba.app`,
  Swift 6, `DEVELOPMENT_TEAM` laissé vide). Claude lancera `xcodegen generate` sur le Mac.
- XcodeGen n'est qu'un outil de génération : l'application elle-même reste sans aucune dépendance tierce.
- Le `README.md` en français explique :
  1. `xcodegen generate` puis lancement sur un iPhone réel avec un simple identifiant Apple (sans compte payant) ;
  2. le passage à TestFlight puis à l'App Store (programme développeur Apple, 99 $ par an) ;
  3. le schéma `chiourim://` et la table de réécriture des liens ;
  4. comment ajouter un nouveau site plus tard (une ligne dans la table des sites).
- **Travaille par commits lisibles**, un par étape de la section 10, avec un message clair en français.

**Note sur l'accès au contenu** : les dépôts de contenu sont peut-être encore **privés** au moment où tu écris.
Les téléchargements depuis `raw.githubusercontent.com` renverront alors 404. Ne bloque pas là-dessus : écris le code
pour des dépôts publics, comme spécifié. Benjamin les rendra publics.

## 9. Tests à fournir

- Tests unitaires : réécriture de chaque type de lien (dont otsrot, bloqué), correspondance extension → type MIME,
  `/` → `index.html`, chemin du cache.
- Un test qui télécharge réellement `chiourim://guemara/index.html` et vérifie que la réponse est en `text/html`.

## 10. Ordre de travail

1. Le `WKURLSchemeHandler`, la table des sites et le cache. Vérifie que la page d'accueil de la Guemara s'affiche
   **mise en forme**, pas en code source.
2. La réécriture des liens et le blocage d'otsrot.
3. L'interface à onglets et la navigation.
4. Les favoris, la reprise de lecture, la taille du texte.
5. Le téléchargement hors ligne et les PDF.
6. Les tests, l'icône, le README, puis le dépôt GitHub.

À la fin, donne-moi en quelques lignes : ce qui marche, ce qui n'a pas pu être testé, et les points que je dois faire
moi-même (inscription développeur Apple, signature, envoi sur TestFlight).

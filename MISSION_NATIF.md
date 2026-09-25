# Mission 2 : lecteur NATIF et design premium (décision de Benjamin : « lecteur natif »)

L'appli actuelle (mission 1) affiche les sites dans un WKWebView. On passe à une vraie appli SwiftUI qui lit les
textes eux-mêmes et les met en page nativement. Lis d'abord : `MISSION.md`, `../DESIGN.md` (palette, polices, écrans,
addendum GitHub/connexion/signalements) et les maquettes `../design_claude/*.dc.html` (HTML : c'est la référence
visuelle — reproduis-les fidèlement en SwiftUI). Polices libres (OFL) : `../depot_polices/` (EB Garamond, Frank Ruhl Libre).

## Données
- Source unique : dépôt GitHub public `bben2/chiourimsba-donnees`, lu en HTTPS sur
  `https://raw.githubusercontent.com/bben2/chiourimsba-donnees/main/` (constante `SourceDonnees.base`).
- Format : voir `~/sefaria_translate/tools/MISSION_EXPORT_DONNEES.md` (section « Format »). Le dépôt n'est pas encore
  en ligne : pendant le développement, lis les fichiers générés dans `~/sefaria_translate/donnees/` s'ils existent,
  et embarque dans les TESTS (pas dans l'appli) un petit jeu d'exemple (Bekhorot 2a, une section hassidout).
- Cache disque (Application Support) : ce qui a été ouvert reste lisible hors connexion ; le catalogue est rafraîchi
  au lancement si le réseau est là ; bouton « Télécharger ce livre pour le lire hors ligne » dans le sommaire.

## Écrans (onglets : Chiourim, Guemara, Hassidout, Halakha, Mon espace — cf. maquette TabBar)
1. **Chiourim (accueil)** : hub premium — reprendre ma lecture (dernière position), les trois collections avec
   compteurs issus du catalogue, accès « Chiourim BA » (page web du portail https://chiourimsba.vercel.app en
   WKWebView, seul usage web autorisé avec le suivant), « Questions à l'IA » (WKWebView de la page de discussion du
   portail), « Nos livres » (liste statique de liens Lulu, vide pour l'instant = écran « bientôt »), « Nous soutenir »
   (caché tant que `Config.urlDons` est nil).
2. **Guemara** : traités → sommaire des amudim → **Lecture**.
3. **Hassidout** : livres → sections → Lecture.
4. **Halakha** : si la collection est vide, écran sobre « bientôt dans l'appli » + lien vers halakha.vercel.app.
5. **Lecture (native)** : par segment, l'hébreu (Frank Ruhl, RTL, justifié) puis le français (EB Garamond) — option
   dans les réglages : « côte à côte » (iPad / paysage) ou « l'un sous l'autre » (iPhone, par défaut). Sous chaque
   segment, Rachi / Tossefot / Roch repliables (Rachi : mot d'entrée en gras ; Tossefot : fond légèrement grisé),
   « Pour comprendre » (explication, HTML simple converti en AttributedString), schéma SVG (petit WKWebView non
   interactif limité au SVG, hauteur adaptée). Taille du texte A−/A+, favori, partage (lien vers la page du site),
   position de lecture mémorisée au segment près. Swipe ou boutons pour amud/section précédent/suivant.
6. **Mon espace** : maquette `Espace.dc.html`. Où j'en suis, favoris, annotations, signalements envoyés.
   Tout est stocké EN LOCAL (SwiftData). Le bouton « Se connecter avec Apple » est présent mais derrière
   `Config.connexionActive = false` (il faut le compte développeur payant ; on l'activera avec CloudKit plus tard).
7. **Annoter / Signaler** : maquette `Annoter.dc.html`, en feuille depuis un appui long sur un segment.
   Surligner et annoter = local. Signaler = POST JSON vers `https://chiourimsba.vercel.app/api/signaler` avec
   `{site: "guemara"|"hassidout", page: "<fichier .html du site>", passage, correction, source: "appli", site_web: ""}`.
   Réponse 201 → « Merci, c'est envoyé » ; 503 → message calme « Les signalements ouvrent bientôt » et le signalement
   est gardé en local pour renvoi automatique plus tard ; aucun jeton, aucun secret dans l'appli.

## Qualité « premium »
Accessibilité (Dynamic Type, VoiceOver en français et hébreu, cibles ≥ 44 pt), mode sombre soigné, animations
discrètes, chargement squelette, états vides et erreurs réseau rédigés en français simple et accentué. Aucune
lettre ni figure dans l'icône. Français avec tous les accents. Hébreu : ne jamais afficher le Tétragramme ni Elokim
sans tiret — les données sont déjà propres, n'altère pas l'hébreu reçu.

## Technique
SwiftUI iOS 17, XcodeGen (`project.yml`), pas de dépendance externe. Tests unitaires : décodage des JSON d'exemple,
cache, file d'attente des signalements. Supprime le code WebView devenu inutile (garde-le uniquement pour Chiourim BA,
Questions à l'IA et les schémas SVG).

# Mission 3 : style premium et Halakha (retour de Benjamin, 25/09 : « j'aime pas le style, pas complet, manque la Halakha »)

Ce qu'il a vu (version Mac) : fenêtre en mode sombre, onglets en haut, écran Halakha « Bientôt dans l'appli » presque vide.
Référence visuelle : `../design_claude/*.dc.html` (maquettes Claude Design) et `../DESIGN.md`. Relis-les et rapproche
l'appli de ces maquettes, sur iPhone ET sur Mac.

1. **Apparence « Papier » par défaut** : fond crème #faf8f3, cartes #fffdf8, encre #1c1917, bleu nuit #1e3a5f, or #9a6b12,
   même si le Mac ou l'iPhone est en mode sombre. Réglage « Apparence » : Papier (défaut) / Nuit (sombre soigné, pas noir
   pur) / Système.
2. **Mac et iPad** : navigation par barre latérale (NavigationSplitView : Chiourim, Guemara, Hassidout, Halakha, Mon espace)
   au lieu des onglets du haut ; colonne de lecture centrée, largeur max ~720 pt ; polices un peu plus grandes ;
   fenêtre par défaut 1200×800. iPhone : garder la barre d'onglets du bas.
3. **Halakha** : le catalogue (`catalogue.json`, collection `halakha`) contient maintenant le Kitsour Choulhan Aroukh
   (`halakha/kitsour/NNN.json`) et le Choulhan Aroukh Orah Haim (`halakha/orach-chayim/NNN.json`), même format que
   hassidout + `resume`. L'onglet Halakha affiche ces œuvres comme Hassidout (liste → simanim → lecture). Garde
   l'écran « bientôt » seulement si la collection est vide. Titres : « Siman 1 », etc.
4. **Accueil plus riche**, fidèle à `Main.dc.html` : reprendre la lecture, les trois collections avec leurs compteurs,
   Chiourim BA, Questions à l'IA, Nos livres. Typographie EB Garamond pour les titres, cartes aérées, filets fins.
5. Aucune régression : les tests unitaires et le test d'interface passent ; ajoute au test d'interface l'ouverture
   Halakha > Kitsour > 001.

Vérifications obligatoires :
- `xcodegen generate`
- `xcodebuild test -project ChiourimBA.xcodeproj -scheme ChiourimBA -destination 'id=9C158916-053A-4456-B687-E5E9D567C20C' CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -project ChiourimBA.xcodeproj -scheme ChiourimBA -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath /Volumes/DEV_SSD/Xcode/DerivedChiourimMac build`
Les deux doivent réussir. Si les données Halakha ne sont pas encore en ligne, teste avec un fichier d'exemple dans la
cible de TESTS uniquement.

## PRIORITÉ (précision de Benjamin, 25/09 10:50) : « je veux un univers équivalent aux sites en termes de graphismes »
L'appli doit avoir LE MÊME univers graphique que ses sites. La référence n'est plus les maquettes : ce sont les sites.
Ouvre et reproduis leur CSS et leur mise en page :
- `~/ChiourimsBA/_deploy_vercel/portail/index.html` (accueil), `~/ChiourimsBA/_deploy_vercel/guemara/index.html`,
  `~/ChiourimsBA/_deploy_vercel/hassidout/index.html` (sommaires), `~/ChiourimsBA/_deploy_vercel/guemara/Bekhorot_2a.html`
  (page de lecture : bandeau, titre, résumé, blocs hébreu/français, Rachi/Tossefot, schémas, pied de page),
  `~/ChiourimsBA/_deploy_vercel/hassidout/tzidkat/005.html`, `~/ChiourimsBA/_deploy_vercel/halakha/kitsour/003.html`.
- Palette exacte des sites : --bg #faf8f3, --paper #fffdf8, --ink #1c1917, --muted #78716c, --line #e7e2d8,
  --gold #b8860b (remplace l'or #9a6b12 et vérifie le bleu utilisé par les sites pour les titres/liens).
- Polices des sites : Frank Ruhl Libre (hébreu ET titres), police système (-apple-system) pour le texte français, comme
  sur les sites. Mêmes tailles relatives, mêmes filets, mêmes cartes, mêmes pastilles, mêmes emojis de navigation s'il y en a.
Un lecteur qui passe du site à l'appli doit reconnaître immédiatement le même univers.

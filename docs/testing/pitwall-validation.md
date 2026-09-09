# Validation de l’accueil Pitwall

Direction validée : accueil sombre/corail, carte du Grand Prix, horaires,
Race Center, actualités et navigation inférieure.
Branche : `codex/pitwall-home`.

## Environnement

Le SDK Flutter préinstallé (3.35.4 / Dart 3.9.2) est trop ancien pour
`better_player_plus 1.2.1`. Validation réalisée avec un SDK séparé
Flutter 3.41.5 / Dart 3.11.3 et Java 17.
Le SDK d’origine n’a pas été modifié.

Commande Android :

```sh
flutter build apk --release --target-platform android-arm64
```

## Vérifications

- `flutter pub get` : réussi avec le SDK séparé.
- `flutter test --no-pub` : 2 tests réussis (résolution de l’URL RSS et
  carte d’un week-end sprint, écran 360 px et texte agrandi à 130 %).
- `flutter analyze --no-pub` : aucune erreur ; avertissement existant
  `flutter_lints` non déclaré et 13 indications de dépréciation préexistantes.
- Flux Motorsport France : réponse HTTP 200.
- API F1 event-tracker : Grand Prix d’Espagne, 11–13 septembre 2026,
  cinq sessions et tracé fournis par la source.

## Comportement

L’accueil défile d’un seul tenant ; tirer vers le bas recharge les deux
sources. Le Race Center et les articles réutilisent les écrans existants.
Motorsport France devient le réglage par défaut uniquement si `homeFeed`
est absent. Les sources déjà enregistrées sont conservées. Les changements
ultérieurs restent possibles dans les paramètres. Pitwall et son flux RSS
sont réservés à la Formule 1 ; les autres championnats utilisent leur
fournisseur d’actualités existant. Le serveur RSS personnalisé est respecté. Les autres langues utilisent les nouvelles traductions
anglaises par défaut ; le français est traduit.

Les dates et le statut de session sont calculés depuis les données F1.
Un échec réseau affiche un message et une action de réessai.

## APK et installation

- Build release ARM64 réussi : `build/app/outputs/flutter-apk/app-release.apk`
  (32,2 Mo), version 0.10.3 (42).
- Installation ADB réussie sur Pixel 10 Pro le 9 septembre 2026.
- Package : `org.brightdv.boxbox` ; activité lancée : `.MainActivity`.
- Analyse ciblée des six fichiers Dart modifiés : aucune anomalie.
- Contrôle visuel sur le Pixel : accueil, tracé, horaires, défilement et
  actualités avec images vérifiés. Race Center affiché sur le téléphone.
- Langue propre à BoxBox réglée sur `fr-FR` via Android ; langue du téléphone inchangée.
- Captures : `pixel-accueil.png`, `pixel-actualites.png`.
- Limitation observée : le lecteur WebView existant reste blanc pour l’article
  Motorsport testé. Le navigateur externe affiche également une demande
  de désactivation du bloqueur publicitaire du site. La liste RSS fonctionne.
  Les réglages de confidentialité du téléphone n’ont pas été modifiés.

## Corrections de la revue GitHub

- Préférences conservées au démarrage et après une mise à jour.
- Séparation des flux par championnat ; rechargement au changement de championnat.
- Résolution RSS partagée avec prise en compte du serveur personnalisé,
  y compris après un changement de serveur.
- Sept tests de régression ajoutés ; neuf tests au total avec les tests
  d’accueil existants. Ces corrections n’ont pas été réinstallées sur le Pixel.

## Apparence hors Pitwall

Le thème sombre/corail ne s’applique que lorsque l’onglet Accueil affiche
Pitwall (Formule 1 avec un flux RSS). Le flux classique, les autres
championnats et les autres onglets héritent du thème actif de l’application,
y compris l’en-tête et la navigation. Les couleurs forcées de l’en-tête
sont retirées hors Pitwall.

Cinq tests de widgets supplémentaires vérifient les modes clair, système
et sombre sur le flux classique, un autre championnat en mode clair et
un aller-retour entre Pitwall et le calendrier. Cette correction n’est
pas encore installée sur le Pixel.

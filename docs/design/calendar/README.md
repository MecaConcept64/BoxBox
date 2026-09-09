# Calendrier — direction validée le 9 septembre 2026

Référence : `calendrier-valide.png`. Maquette approuvée par l’utilisateur,
avec ajout des drapeaux à gauche. Les anciennes variantes à grosses cartes
et blocs de date sont rejetées.

## Mise en œuvre

- Conserver les onglets précédents / à venir, les données, le cache,
  les notifications et les routes existantes.
- Sélecteur arrondi corail, photo du prochain événement depuis la source
  existante, lignes simples avec séparateurs discrets.
- Drapeau à gauche ; pays et circuit au centre ; date et heure à droite.
- Dates localisées et heures locales, préférence de format horaire conservée.
- Drapeaux issus des libellés de pays et alias des événements ; icône neutre
  si un pays n’est pas reconnu, sans inventer de correspondance.
- Palette Pitwall partagée entre calendrier et accueil, avec variantes
  claire et sombre. Respect du réglage système et des préférences explicites.

La photo de Madrid générée dans la maquette est illustrative. Elle n’est pas
intégrée dans l’application ; celle-ci utilise les images de son fournisseur.

## Validation

- 23 tests de l’application réussis, puis les 6 tests de navigation réussis
  après ajout du test de changement de luminosité système (24 cas au total).
- Analyse ciblée de tous les fichiers modifiés : aucune anomalie.
- Analyse globale : avertissement préexistant `flutter_lints` absent et
  13 dépréciations préexistantes ; aucune erreur.
- APK release ARM64 compilé avec Flutter 3.41.5 et Java 17, installé sur
  Pixel 10 Pro avec conservation des données.
- Contrôle visuel du calendrier clair et sombre, et de l’accueil clair.
- Réglage d’apparence remis sur « Suivre le système » après vérification.
- Captures réelles : `pixel-calendrier-clair.png`,
  `pixel-calendrier-sombre.png`, `pixel-accueil-clair.png`.

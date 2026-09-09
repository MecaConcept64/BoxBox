# Essai du lecteur natif — 9 septembre 2026

Le clic sur un article Motorsport France ouvre un lecteur Flutter sombre/corail :
titre, auteur, date locale, photo, introduction, paragraphes, intertitres et photos
intégrées. Les autres sources conservent leur écran web existant.

L'essai a été validé sur le Pixel 10 Pro connecté avec l'article réel :
https://fr.motorsport.com/f1/news/leclerc-eviter-penalite-moteur-crash-monza/10853867/
Les deux PNG de ce dossier sont des captures directes du téléphone.

La récupération HTTP directe est refusée (403) par le site dans cet environnement.
Un chargement avec le moteur web de la plateforme, en arrière-plan, permet de lire
la page publique puis d'afficher son contenu dans les widgets natifs. Le moteur est
libéré après extraction. Aucune ouverture du navigateur externe n'est nécessaire.
En cas d'échec, le lecteur propose de réessayer ou de consulter la page intégrée.

Validation : compilation Android debug lors de l’essai, 17 tests Flutter réussis sur main à jour, analyse ciblée
sans erreur, ouverture depuis l'accueil, défilement et bouton vers la page originale
vérifiés sur le Pixel. SDK utilisé : Flutter 3.41.5.
Java 17 installé via Homebrew doit être indiqué à Gradle. Le SDK Flutter par défaut
est trop ancien pour les dépendances actuelles. L'avertissement préexistant du
formateur sur flutter_lints (non déclaré) reste présent.

Limites du prototype : validé sur un article public et un appareil Android ; les
vidéos, tableaux et liens enrichis ne sont pas reproduits. Le lecteur dépend de la
structure HTML de Motorsport ; les articles marqués comme réservés aux abonnés
sont refusés. Pas de cache hors ligne, de republication ni de déploiement effectué.

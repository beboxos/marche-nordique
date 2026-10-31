# Guide Marche Nordique : version web (iPhone + Android) avec admin

Date : 2026-10-31. Validé en conversation par l'utilisateur.

## Pourquoi
L'appli est déjà du HTML/JS (Leaflet, PWA), mais seule l'enveloppe APK est Android. Les marcheurs sur iPhone ne peuvent pas l'installer. Les circuits sont figés dans `circuits-data.js` : 19 circuits sur 23 n'ont qu'un tracé approximatif (11 à 25 points) et des cadres de calage de scan approximatifs. Le décalage vient de là. 1 à 2 personnes connaissent le terrain et doivent pouvoir corriger sans passer par moi.

## Objectifs
- Site public sur GitHub Pages, installable sur l'écran d'accueil (iOS et Android).
- Les circuits sont lus dans Supabase ; repli automatique sur `circuits-data.js` et cache hors-ligne (forêt sans réseau).
- Page `admin.html` protégée par une vraie connexion (Supabase Auth) : créer une marche en déposant un `.gpx`, corriger tracé / repères / textes, recaler le scan du PDF sur la carte, publier/dépublier.
- Une modification enregistrée est visible tout de suite par tous.

## Hors périmètre
- GPS écran éteint sur iPhone (impossible dans Safari). Contournement : WakeLock + mode poche.
- Réécriture de l'appli ou du guidage vocal. On modifie uniquement la source des données.
- Gestion multi-rôles ou inscription publique.

## Conception
- Table `circuits` : `id` (texte, clé), `position`, `published`, `data` (jsonb, même forme que les objets de `DEFAULT_CIRCUITS` pour ne pas toucher au rendu), `updated_at`.
- Table `admins(user_id)`. Lecture publique des circuits publiés ; écriture réservée aux comptes listés dans `admins` (RLS). Inscription publique désactivée ; comptes créés par invitation.
- Storage : buckets publics `scans` et `gpx` ; écriture réservée aux admins. Les scans existants restent servis par Pages (`scanImage` relatif) ; les nouveaux sont des URL Supabase.
- Appli : récupère `circuits` (clé publishable, simple `fetch`), met en cache dans localStorage, retombe sur `DEFAULT_CIRCUITS`. L'éditeur local (localStorage) est neutralisé quand des données distantes existent, pour éviter deux sources de vérité.
- Admin : Leaflet, `supabase-js` (version figée via CDN), import GPX (DOMParser, distance et départ calculés), points du tracé déplaçables/supprimables, poignées de coin pour le scan + curseur d'opacité, enregistrement.

## Choix faits par moi (à valider)
- Supabase plutôt qu'un hébergement maison.
- Calage du scan par deux coins (comme aujourd'hui). Si les scans sont tournés par rapport au nord, on passera à 4 coins dans un second temps.
- Les 23 circuits existants sont importés tels quels comme base de départ.

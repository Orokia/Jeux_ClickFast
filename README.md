# ClickFast — Jeu de rapidité web conteneurisé

## 1. Présentation du projet

ClickFast est un jeu web de rapidité avec classement des scores. Le joueur doit cliquer le plus rapidement possible pendant une partie chronométrée de 5 secondes.

Le projet met en œuvre une architecture composée d'un frontend web, de deux API et d'une base de données PostgreSQL. L'ensemble est conteneurisé avec Docker et Docker Compose, avec un pipeline CI/CD permettant de tester, construire, publier et déployer les images.

### Fonctionnalités

- Jeu web accessible depuis un navigateur.
- Compteur de clics et chronomètre de 5 secondes.
- Enregistrement des scores et consultation du top 10.
- API de statistiques : meilleur score, nombre de parties et nombre de joueurs distincts.
- Base PostgreSQL avec stockage persistant.
- Environnement conteneurisé avec Docker Compose.
- Réseau Docker dédié et configuration par variables d'environnement.
- Publication des images sur Docker Hub.
- Pipeline CI/CD GitHub Actions.
- Déploiement sur une VM via un runner auto-hébergé et SSH.
- Sauvegarde PostgreSQL avec vérification par restauration.

## 2. Technologies utilisées

| Composant | Technologies |
|---|---|
| Frontend | HTML, CSS, JavaScript, Nginx |
| API de scores | Node.js, Express |
| API de statistiques | Python, FastAPI, Uvicorn |
| Base de données | PostgreSQL |
| Conteneurisation | Docker, Docker Compose |
| CI/CD | GitHub Actions |
| Registre d'images | Docker Hub |
| Déploiement | VM, runner auto-hébergé, SSH |
| Sauvegarde | `pg_dump`, `pg_restore`, PowerShell |
| Contrôle des accès | Utilisateurs non privilégiés dans les images concernées |

## 3. Architecture

```text
Navigateur
    |
    v
Frontend ClickFast — Nginx
    |
    +------> API de scores — Node.js / Express
    |                    |
    |                    v
    |                PostgreSQL
    |                    ^
    |                    |
    +------> API statistiques — Python / FastAPI

Administration de la base : Adminer
```

Les services communiquent via le réseau Docker. En production, PostgreSQL n'est pas publié directement sur le port de l'hôte.

## 4. Prérequis

Installer les éléments suivants :

- Docker Desktop ou Docker Engine.
- Docker Compose v2.
- Git.
- Un navigateur web.

Vérifier les installations :

```powershell
docker --version
docker compose version
git --version
```

## 5. Démarrage local

### 5.1. Cloner le dépôt

```powershell
git clone https://github.com/Orokia/Jeux_ClickFast.git
cd Jeux_ClickFast
```

### 5.2. Configurer les variables d'environnement

Créer un fichier `.env` à la racine du projet :

```dotenv
DB_PASSWORD=choisir_un_mot_de_passe
```

Utiliser le nom exact des variables attendu par `docker-compose.yml` et par les services. Ne jamais publier le véritable mot de passe.

### 5.3. Construire et démarrer les services

```powershell
docker compose up -d --build
```

Vérifier leur état :

```powershell
docker compose ps
```

Consulter les journaux :

```powershell
docker compose logs --tail=100
```

Pour un service spécifique :

```powershell
docker compose logs -f clickfast
docker compose logs -f clickfast-api
docker compose logs -f clickfast-stats-api
docker compose logs -f clickfast-db
```

Les noms exacts des services doivent correspondre à ceux définis dans le fichier Compose.

### 5.4. Adresses locales

| Service | Adresse |
|---|---|
| Jeu ClickFast | http://localhost:8080 |
| API de scores | http://localhost:3000 |
| API statistiques | http://localhost:8000 |
| Adminer | http://localhost:8081 |

Ces adresses supposent que les ports correspondants sont publiés par la configuration locale.

### 5.5. Arrêter les services

```powershell
docker compose down
```

Les données PostgreSQL sont conservées dans le volume Docker `clickfast_pgdata_v2`, sous réserve que ce volume soit bien celui référencé par la configuration.

**Attention :** ne pas ajouter `-v` à la commande d'arrêt si les données doivent être conservées.

## 6. API de scores

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/` | Vérifier que l'API répond |
| POST | `/scores` | Enregistrer un score |
| GET | `/scores` | Récupérer les 10 meilleurs scores |

Les données sont validées avant insertion. Les requêtes SQL utilisent des paramètres afin de limiter les risques d'injection SQL.

### Tests rapides

Vérifier que l'API répond :

```powershell
curl.exe -i http://localhost:3000/
```

Récupérer le classement :

```powershell
curl.exe -i http://localhost:3000/scores
```

Tester l'enregistrement d'un score avec un exemple adapté aux champs réellement attendus par l'API :

```powershell
curl.exe -i -X POST http://localhost:3000/scores `
  -H "Content-Type: application/json" `
  -d '{"player":"Test","score":10}'
```

Adapter le JSON si l'API attend d'autres noms de champs. Vérifier que les scores sont persistés dans PostgreSQL.

## 7. API de statistiques

L'API de statistiques est développée en Python avec FastAPI.

Elle permet notamment de consulter :

- Le meilleur score.
- Le nombre total de parties.
- Le nombre de joueurs distincts.

L'URL de chaque endpoint doit être vérifiée dans le code de `stats-api/` avant utilisation.

Tester la disponibilité du service :

```powershell
curl.exe -i http://localhost:8000/
```

Si cette route n'existe pas, utiliser l'endpoint de santé ou de statistiques effectivement défini dans l'application.

## 8. Sécurité et bonnes pratiques Docker

Le projet applique ou vise les bonnes pratiques suivantes :

- Utiliser des images de base versionnées.
- Exécuter les processus applicatifs avec un utilisateur non privilégié lorsque cela est pris en charge.
- Limiter le contenu copié dans les images.
- Utiliser un fichier `.dockerignore`.
- Séparer les services sur un réseau Docker dédié.
- Ne pas publier le port PostgreSQL en production.
- Conserver les données dans un volume nommé.
- Externaliser les secrets et la configuration.
- Utiliser des requêtes SQL paramétrées.
- Vérifier les erreurs de connexion à la base.
- Utiliser des contrôles de santé pour ordonner le démarrage des services lorsque la configuration le permet.

### Vérifier les images

```powershell
docker images
```

Afficher les couches d'une image :

```powershell
docker history clickfast:1.3
docker history clickfast-api:1.0
docker history clickfast-stats-api:1.0
```

Afficher le nombre de couches :

```powershell
docker image inspect clickfast:1.3 --format "{{len .RootFS.Layers}}"
docker image inspect clickfast-api:1.0 --format "{{len .RootFS.Layers}}"
docker image inspect clickfast-stats-api:1.0 --format "{{len .RootFS.Layers}}"
```

## 9. Métriques Docker — État initial mesuré

Les mesures ci-dessous correspondent aux résultats obtenus pendant l'analyse du projet. Elles constituent un état initial et non un bilan après optimisation.

### 9.1. Taille des images et nombre de couches

| Image | Taille disque Docker | Taille du contenu | Couches |
|---|---:|---:|---:|
| `clickfast:1.3` | 81,5 MB | 23 MB | 11 |
| `clickfast-api:1.0` | 253 MB | 63,9 MB | 8 |
| `clickfast-stats-api:1.0` | 243 MB | 58,7 MB | 8 |

La taille disque Docker et la taille du contenu sont deux mesures distinctes. Les tailles peuvent également varier selon la version de Docker et les images présentes localement.

### 9.2. Couches principales identifiées

| Image | Couche identifiée | Taille annoncée par Docker |
|---|---|---:|
| `clickfast:1.3` | Installation Nginx et dépendances | 43,6 MB |
| `clickfast-api:1.0` | Installation de Node.js | 167 MB |
| `clickfast-stats-api:1.0` | Installation de Python | 41,4 MB |
| `clickfast-stats-api:1.0` | Installation des dépendances Python | 50,5 MB |

Ces valeurs proviennent de `docker history`. Elles permettent d'identifier les couches à examiner, mais ne représentent pas nécessairement une taille additionnelle unique sur le disque, car les couches peuvent être partagées.

### 9.3. Temps de construction et réponse HTTP

| Mesure | Résultat | Périmètre |
|---|---:|---|
| Construction frontend sans cache | 3,61 s | `docker build --no-cache` |
| Construction frontend avec cache | 1,1 s | Durée affichée par Docker |
| Construction frontend avec cache, premier essai | 2,91 s | Durée totale mesurée par PowerShell |
| Première réponse HTTP mesurée | 95,11 ms | Frontend via tunnel SSH local |
| Dernière réponse HTTP mesurée | 30,17 ms | Frontend via tunnel SSH local |

Les temps de construction mesurés par PowerShell incluent le temps de lancement et d'exécution de la commande. La durée affichée par Docker mesure le processus de construction selon ses propres indications. Ces valeurs ne sont donc pas strictement équivalentes.

Le dernier test HTTP a renvoyé `200 OK`. Les deux mesures HTTP sont ponctuelles ; plusieurs essais seraient nécessaires pour calculer une moyenne fiable.

### 9.4. Commandes de mesure

Construction avec cache :

```powershell
Measure-Command {
    docker build -t clickfast:metrics-test .
}
```

Construction sans cache :

```powershell
Measure-Command {
    docker build --no-cache -t clickfast:metrics-test .
}
```

Mesure du temps de réponse HTTP :

```powershell
curl.exe -s -o NUL -w "HTTP %{http_code} - %{time_total} secondes`n" http://localhost:8080
```

La construction sans cache permet de mesurer un scénario où les étapes de construction ne réutilisent pas le cache. Elle ne constitue pas nécessairement une mesure de reconstruction sur une machine entièrement vierge.

### 9.5. Optimisations à évaluer

- Examiner les images de base Node.js et Python et envisager des variantes plus légères compatibles.
- Vérifier que seules les dépendances de production sont installées.
- Maintenir un ordre de `COPY` qui préserve le cache des dépendances.
- Vérifier que `.dockerignore` exclut les fichiers inutiles.
- Éviter de copier les sources, outils ou fichiers temporaires non nécessaires.
- Comparer les tailles et les temps de construction après chaque modification.
- Tester les services et les fonctionnalités après chaque optimisation.

**État :** les mesures initiales sont disponibles. Les mesures des deux API avec et sans cache ainsi que les résultats après optimisation restent à compléter.

## 10. CI/CD et déploiement

Le workflow GitHub Actions se trouve dans :

```text
.github/workflows/ci.yml
```

Selon la configuration du projet, le pipeline exécute les étapes suivantes :

1. Lint et tests.
2. Construction des images Docker.
3. Publication des images sur Docker Hub.
4. Déploiement sur la VM lors d'un push vers `main`, via un runner auto-hébergé et SSH.

Les secrets et mots de passe doivent être configurés dans les secrets GitHub ou dans les fichiers d'environnement locaux non versionnés.

Ne jamais committer :

- Un fichier `.env` contenant des secrets.
- Une clé privée SSH.
- Des mots de passe de production.
- Des jetons d'accès.

### Vérifier le déploiement

Vérifier les conteneurs de production :

```powershell
docker ps
```

Vérifier le site via le tunnel SSH local :

```powershell
curl.exe -I http://localhost:8080
```

Le tunnel doit être actif pour accéder à cette adresse si le site n'est pas directement exposé sur le réseau.

Le déploiement doit utiliser les images publiées et le fichier `docker-compose.prod.yml`, avec les variables nécessaires dans `.env.prod`. Les tags d'images doivent être explicitement définis et cohérents avec ceux publiés sur Docker Hub.

## 11. Sauvegarde et restauration PostgreSQL

Le script `backup-clickfast-db.ps1` réalise une sauvegarde de la base de production avec `pg_dump`, au format custom.

La procédure prévoit :

1. Création du dump.
2. Restauration du dump dans un conteneur PostgreSQL jetable.
3. Comparaison du nombre de lignes de chaque table avec la production.
4. Conservation du dump uniquement si les contrôles réussissent.
5. Génération d'un manifeste JSON contenant le SHA-256 et le nombre de lignes.
6. Suppression des sauvegardes de plus de 14 jours, en conservant toujours les trois plus récentes.

Le journal est écrit dans :

```text
%LOCALAPPDATA%\ClickFast\backup.log
```

### Créer une sauvegarde vérifiée

```powershell
.\backup-clickfast-db.ps1
```

### Vérifier à nouveau une sauvegarde

```powershell
.\backup-clickfast-db.ps1 -Verify <fichier>
```

Remplacer `<fichier>` par le chemin attendu par le script.

### Restaurer en production

**Attention : cette opération écrase les données actuelles.** Vérifier le fichier, le nom de la base et les identifiants avant de l'exécuter.

```powershell
docker cp backups\db\<fichier>.dump vm-prod:/var/tmp/restore.dump
docker exec vm-prod docker cp /var/tmp/restore.dump clickfast-db:/var/tmp/restore.dump
docker exec vm-prod docker exec clickfast-db pg_restore -U clickfast -d clickfast --clean --if-exists --exit-on-error /var/tmp/restore.dump
```

Remplacer `<fichier>` par le nom réel du dump à restaurer.

## 12. Structure principale du dépôt

```text
Jeux_ClickFast/
├── index.html
├── style.css
├── script.js
├── api/
├── stats-api/
├── Dockerfile
├── Dockerfile.vm
├── docker-compose.yml
├── docker-compose.prod.yml
├── .dockerignore
├── .env.example
├── .github/
│   └── workflows/
│       └── ci.yml
├── backup-clickfast-db.ps1
├── backups/
│   └── db/
└── README.md
```

Cette arborescence est indicative : vérifier les noms et les chemins réels dans le dépôt avant de la considérer comme exhaustive. Le dossier des sauvegardes de production doit rester non versionné.

## 13. Journal de bord — étapes du projet

Le journal de bord retrace les réalisations, les difficultés, les mesures et les validations. Les éléments marqués « à vérifier » ne doivent être déclarés terminés qu'après exécution des tests correspondants.

| Étape | Travail attendu | État documenté |
|---|---|---|
| 1. Jeu fonctionnel | Compteur, chronomètre de 5 secondes, arrêt du compteur en fin de partie | À valider par un test fonctionnel complet |
| 2. Image frontend | Nginx, utilisateur non privilégié, fichiers nécessaires uniquement | Image mesurée : 81,5 MB, 11 couches |
| 3. API de scores | Enregistrement et consultation des scores, persistance PostgreSQL | Fonctionnalités documentées ; tests de persistance à confirmer |
| 4. Réseau Docker | Réseau dédié, accès à la base par nom de service, port DB non publié en production | Configuration à vérifier et tests d'isolation à consigner |
| 5. Secrets et configuration | Variables d'environnement, `.env.example`, absence de secrets dans Git | Configuration décrite ; contrôle de l'historique Git à confirmer |
| 6. Docker Compose | Démarrage coordonné, volume persistant, gestion des erreurs et journalisation | Stack exécutée ; tests de panne et de récupération à compléter |
| 7. API statistiques | Meilleur score, parties, joueurs distincts, gestion des erreurs DB | API présente ; comparaison avec les résultats SQL à compléter |
| 8. Publication et déploiement | Images publiées, configuration de production autonome, démarrage sans sources | Déploiement documenté ; test dans un répertoire vierge à confirmer |
| 9. Métriques et optimisation | Mesures des images, couches, builds, réponses HTTP et comparaison après optimisation | Mesures initiales disponibles ; optimisation et mesures finales à effectuer |
| 10. Tests de bout en bout | Partie complète, score invalide, isolation DB, statistiques SQL, panne DB | À valider par les tests finaux |

### Entrée de journal — mesures initiales

- **Travail effectué :** inspection des trois images Docker, du nombre de couches et des principales couches lourdes.
- **Résultats :** frontend 81,5 MB ; API de scores 253 MB ; API statistiques 243 MB.
- **Construction frontend :** 3,61 secondes sans cache ; 1,1 seconde affichée par Docker lors d'une construction avec cache.
- **Réponse HTTP :** `200 OK`, mesurée à 30,17 ms lors du dernier essai.
- **Difficulté rencontrée :** les durées affichées par PowerShell et Docker ne mesurent pas exactement le même périmètre.
- **Suite prévue :** mesurer les deux API, optimiser les images si nécessaire, puis documenter les résultats avant/après.

### Validation finale

Avant de déclarer le projet terminé, vérifier :

- [ ] Le jeu fonctionne jusqu'à la fin du chronomètre.
- [ ] Les scores restent présents après recréation des conteneurs avec le même volume.
- [ ] Le top 10 et les statistiques correspondent aux données SQL.
- [ ] PostgreSQL n'est pas directement accessible depuis l'hôte en production.
- [ ] Les données invalides sont rejetées correctement.
- [ ] Les services gèrent proprement une indisponibilité de la base.
- [ ] Les images sont publiées et le déploiement fonctionne sans code source local.
- [ ] Les mesures avant/après optimisation sont consignées.
- [ ] Les sauvegardes sont restaurables et vérifiées.
- [ ] Le dépôt ne contient aucun secret ni fichier de sauvegarde sensible

## 14. Objectif du projet

ClickFast permet de mettre en pratique le développement web, la conception d'API, la persistance PostgreSQL, la conteneurisation, la sécurité des services, les mesures de performance, l'intégration continue, le déploiement et les stratégies de sauvegarde.

Le README doit être maintenu au fil des étapes, avec des commandes reproductibles, des mesures vérifiables et un journal de bord fidèle aux tests réellement effectués.

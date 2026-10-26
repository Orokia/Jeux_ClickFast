# Journal de bord — Projet ClickFast

# Jour 1


## 1. Objectif de la séance

L’objectif de cette séance est de préparer le projet ClickFast à être exécuté dans un conteneur Docker, en utilisant une image de production légère, en limitant les fichiers intégrés à l’image et en évitant l’exécution du service avec les privilèges `root`.

## 2. Création et préparation du projet

Le projet a été créé sur le Bureau Windows dans le répertoire suivant :

`C:\Users\COULIBALI ROKIA\Desktop\Jeux_ClickFast`

Les fichiers principaux du jeu sont :
- `index.html` : structure de la page web ;
- `style.css` : mise en forme et présentation ;
- `script.js` : logique du jeu ;
- `README.md` : documentation du projet.

Un fichier `Dockerfile` a été ajouté pour définir la construction de l’image Docker. Le fichier `.dockerignore` a également été créé afin d’exclure du contexte de construction les fichiers inutiles, notamment `.git`, les fichiers d’environnement et les dépendances Node.js.

## 3. Construction de l’image Docker

Une première image a été construite à partir de Nginx Alpine. Les vérifications ont ensuite révélé deux points à améliorer : l’image initiale exécutait le service avec l’utilisateur `root` et contenait un fichier Nginx par défaut, `50x.html`.

Le Dockerfile a donc été adapté pour utiliser l’image `nginxinc/nginx-unprivileged:1.28-alpine`, qui permet d’exécuter Nginx sans privilèges administrateur.

Pour supprimer le fichier `50x.html`, l’utilisateur a été temporairement défini sur `root` pendant la construction. Il a ensuite été rétabli sur `nginx`.

La construction finale a été réalisée avec la commande :

`docker build --no-cache -t clickfast:1.2 .`

**Résultat :** la construction de l’image `clickfast:1.2` s’est terminée avec succès.

## 4. Vérifications réalisées

### Vérification du contenu de l’image

Commande exécutée :

`docker run --rm clickfast:1.2 ls -la /usr/share/nginx/html`

Résultat : le répertoire du site contient uniquement les trois fichiers nécessaires :
- `index.html`
- `script.js`
- `style.css`

Le fichier Nginx par défaut `50x.html` a bien été supprimé.

### Vérification de l’utilisateur

Commande exécutée :

`docker run --rm clickfast:1.2 whoami`

Résultat obtenu :

`nginx`

Cette vérification confirme que le conteneur utilise par défaut l’utilisateur non privilégié `nginx`, conformément à l’objectif de sécurité.

## 5. Difficultés rencontrées et solutions

**Difficulté 1 :** le fichier `50x.html` était toujours présent dans l’image malgré la copie limitée aux fichiers du projet.

**Solution :** suppression explicite du fichier dans le Dockerfile avant la copie des fichiers du jeu.

**Difficulté 2 :** la suppression du fichier a échoué avec une erreur de permission, car l’image non privilégiée utilise l’utilisateur `nginx` par défaut.

**Solution :** passage temporaire à `USER root` pendant la construction, puis retour à `USER nginx` pour l’exécution du conteneur.

Ces corrections ont permis d’obtenir une image fonctionnelle au niveau de sa construction et conforme aux vérifications de contenu et d’utilisateur réalisées.

## 6. Bilan de la séance

Les objectifs suivants sont atteints :
- [x] Création du projet ClickFast sur le Bureau.
- [x] Préparation du Dockerfile de production.
- [x] Création du fichier `.dockerignore`.
- [x] Construction réussie de l’image `clickfast:1.2`.
- [x] Suppression des fichiers Nginx inutiles du répertoire du site.
- [x] Vérification de l’exécution avec l’utilisateur non privilégié `nginx`.

Les étapes suivantes restent à effectuer :
- [ ] Démarrer le conteneur et vérifier l’accès au jeu via `http://localhost:8080`.
- [ ] Vérifier le fonctionnement du jeu dans le navigateur.
- [ ] Mesurer la taille de l’image Docker.
- [ ] Mesurer le temps de construction à froid et à chaud.
- [ ] Consigner les mesures et les résultats dans le journal de bord.
- [ ] Enregistrer les modifications dans Git avec des commits explicites.

## 7. Conclusion

Cette séance a permis de construire une image Docker de production pour ClickFast, de limiter les fichiers intégrés à l’image et de configurer l’exécution avec un utilisateur non privilégié. La prochaine étape consiste à valider le fonctionnement du jeu via HTTP et à mesurer les performances de construction et la taille de l’image.

### 8. Test de fonctionnement HTTP

Le conteneur Docker `clickfast` a été démarré avec la commande :

`docker run -d --name clickfast -p 8080:8080 clickfast:1.2`

Un test HTTP a ensuite été effectué avec :

`curl.exe -I http://localhost:8080`

**Résultat obtenu :**
- Code HTTP : `200 OK`
- Serveur : Nginx 1.28.2
- Type de contenu : `text/html`
- Taille de la réponse HTML : 961 octets
- Port publié : `8080`

**Conclusion :** le serveur Nginx répond correctement et la page HTML de ClickFast est accessible via HTTP. Le fonctionnement interactif du jeu dans le navigateur reste à vérifier séparément.


### 9. Mesure de la taille et des temps de construction

Les mesures ont été réalisées avec Docker Desktop le 26 octobre 2026.

**Taille de l’image**

Commande utilisée :

`docker images clickfast:1.2`

Résultats :
- Taille disque : 81,5 MB.
- Taille du contenu : 23 MB.

**Construction à froid**

Commande utilisée :

`Measure-Command { docker build --no-cache -t clickfast:1.2 . }`

Temps mesuré : **7,147 secondes**.

Le paramètre `--no-cache` force Docker à reconstruire les étapes sans réutiliser le cache de construction.

**Construction à chaud**

Commande utilisée :

`Measure-Command { docker build -t clickfast:1.2 . }`

Temps mesuré : **2,826 secondes**.

Cette construction bénéficie du cache Docker lorsque les étapes et leurs entrées n'ont pas changé.

**Analyse des résultats**

La construction à chaud a été réalisée en environ 2,83 secondes, contre 7,15 secondes pour la construction à froid. Le gain de temps mesuré est d'environ 60,5 %.

Ces mesures constituent un premier point de référence pour le projet. Elles peuvent varier selon la machine, le cache disponible et les conditions d'exécution.


# Pollpear

Superprojet Pollpear : orchestre les sous-modules (`frontend`, `backend`, `gateway`,
`ai`, `cyber`, `infra`, `docs`) et l'infra de déploiement.

## Démarrage sur une machine vierge

Prérequis : `git`, `make`, Docker Engine avec Compose v2, environ 18 Go de disque libre
(images, cache de build et dépôts), et une clé SSH autorisée sur l'organisation
`transummer2026`.

```sh
git clone --recursive git@github.com:transummer2026/Pollpear.git
cd Pollpear
```

Les sous-modules sont épinglés : `--recursive` est obligatoire, et après chaque `git pull`
il faut relancer `git submodule update --init --recursive`.

Une fois les deux `.env` en place (voir plus bas), lever la stack puis semer la base.
`make seed_prod` est **obligatoire** et ne fonctionne que sur une base vide : c'est lui qui
crée les comptes.

```sh
make up_prod      # build, migrations, certificats, up --wait
make seed_prod    # une seule fois, sur une base vide
```

L'application répond ensuite sur l'URL formée par `DOMAIN` et `NGINX_HTTPS_PORT` du `.env`
racine — sur les machines de test, <https://localhost:8443/>. Le certificat est auto-signé :
le navigateur demande une confirmation.

### Les deux fichiers `.env`

Ils ne sont pas versionnés, donc absents du clone. Les demander à l'équipe et les déposer
exactement ici :

| Fichier | Contenu |
| :------ | :------ |
| `.env` (racine du superrepo) | `DOMAIN`, ports publiés, `SKIP_LETSENCRYPT`, `VAULT_ROOT_TOKEN` |
| `Pollpear_cyber/.env` | secrets applicatifs, identifiants OAuth, mots de passe des services |

Le second est monté en lecture seule dans le conteneur Vault, qui tourne en `uid 100` : en
`600` il ne peut pas le lire, et la stack ne démarre pas. Le `.env` racine, lui, n'est monté
dans aucun conteneur — il doit rester lisible par vous seul.

```sh
chmod 600 .env && chmod 644 Pollpear_cyber/.env
```

Sans le `.env` racine, l'erreur tombe beaucoup plus loin, sous la forme
`required variable DOMAIN is missing a value`.

## Déploiement

[![Deploy dev.pollpear.com](https://img.shields.io/badge/Deploy-dev.pollpear.com-2ea44f?style=for-the-badge&logo=github)](https://github.com/transummer2026/Pollpear/compare/staging...dev?quick_pull=1)

Le bouton ci-dessus ouvre une PR pré-remplie `dev` → `staging`. Au **merge sur
`staging`**, le deploy part automatiquement sur **dev.pollpear.com** (runner
self-hosted).

### Flux

1. Clic sur le bouton → PR `dev` → `staging`
2. La CI « PR deploy description » remplit le corps de la PR (bumps de sous-modules +
   commits)
3. Review + merge
4. Le workflow « Deploy staging » (`push: staging`) build les services, applique les
   migrations Prisma, régénère les certs puis relance la stack en `--wait` (valide les
   healthchecks)
5. Rollback : revert du merge sur `staging` → push → le deploy rejoue l'état précédent

### Commandes locales

| Commande           | Effet                                                        |
| ------------------ | ----------------------------------------------------------- |
| `make up`          | Stack dev (services Pollpear seuls)                         |
| `make up_dev_full` | Stack dev + monitoring                                       |
| `make up_prod`     | Stack prod/staging locale (certs + `--wait`)                |
| `make deploy`      | Séquence CD complète (migrations + up prod + prune d'images) |

### Prérequis serveur (premier deploy)

- [ ] DNS `dev.pollpear.com` → IP du serveur
- [ ] `.env` déposé au chemin `DEPLOY_ENV_FILE` (défaut `~/pollpear/.env`)
- [ ] htpasswd : creds `HTPASSWD_*` + `SMOKE_*` présents dans le `.env`
- [ ] Runner self-hosted `pollpear-staging` en ligne (labels `self-hosted`, `staging`)
- [ ] Repo autorisé en lecture sur les packages GHCR de l'infra
      (settings du package → *Manage Actions access*)

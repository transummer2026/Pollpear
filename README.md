# Pollpear

Superprojet Pollpear : orchestre les sous-modules (`frontend`, `backend`, `gateway`,
`ai`, `cyber`, `infra`, `docs`) et l'infra de déploiement.

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

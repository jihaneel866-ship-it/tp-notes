# Compte rendu — TP Pipeline DevSecOps (Master TRC)
Étapes validées : 10/10

## Étape 1 — Préparer son poste
- [x] node -v affiche v22.x
- [x] docker run hello-world fonctionne sans sudo
- [x] Les 7 images sont téléchargées (docker images)
- [x] La base Trivy est téléchargée

## Étape 2 — Mise en place
- [x] npm test affiche 3 tests réussis
- [x] package-lock.json est commité
- [x] Le dépôt tp-notes est visible sur github.com

**Q.** Pourquoi faut-il commiter package-lock.json, et pourquoi utilisera-t-on npm ci plutôt que npm install dans le pipeline ?
package-lock.json doit être commité pour garantir les mêmes versions des dépendances dans tous les environnements.

On utilise npm ci dans le pipeline CI/CD car il installe exactement les versions définies dans package-lock.json, sans le modifier. Cela garantit une installation rapide, stable et reproductible.

## Étape 3 — CI de base
- Durée du job build-test (secondes) : build-test (pull_request) : 7 secondes    build-test (push) : 9 secondes
- [x] Le pipeline passe au vert sur main
- [x] La pull request test-rouge est bloquée (pipeline rouge)
- [x] La pull request est fermée sans merge, branche supprimée

**Q.** Quelle est la différence entre ce que vous venez de faire (Continuous Integration) et le Continuous Delivery ? Que manque-t-il au pipeline pour en faire du Continuous Delivery ?
La CI vérifie automatiquement la qualité du code grâce aux tests, tandis que la Continuous Delivery automatise également la préparation et la livraison de l'application pour son déploiement.

## Étape 4 — Conteneur
- Taille de l'image naïve (Mo) : 1140
- Trivy : HIGH + CRITICAL (naïve) : 706 (670 HIGH + 36 CRITICAL)
- Checkov : contrôles échoués (naïve) : 2
- Utilisateur affiché par whoami (naïve) : root

**Q.** Repérez trois défauts de la version naïve. Pour chacun, dites quel risque il crée.
1. Utilisateur root : risque de privilèges élevés en cas de compromission du conteneur.
2. Absence de .dockerignore : risque d'inclure des fichiers sensibles ou inutiles dans l'image.
3. Image node:22 volumineuse : augmente la surface d'attaque et rend les builds moins reproductibles.
- Taille de l'image durcie (Mo) : 170MB
- Trivy : HIGH + CRITICAL (durcie) : 10 (HIGH: 10, CRITICAL: 0)
- Checkov : contrôles échoués (durcie) : 0
- Utilisateur affiché par whoami (durcie) : node
- [x] L'image durcie démarre et /health répond
- [x] L'état de santé Docker passe à healthy
- [x] Dockerfile et .dockerignore durcis sont commités

**Q.** Une image avec 0 vulnérabilité HIGH/CRITICAL aujourd'hui le sera-t-elle encore dans un mois ? Que faut-il prévoir ?
Non, pas forcément. De nouvelles vulnérabilités peuvent être découvertes. Il faut donc refaire régulièrement les scans Trivy, mettre à jour les dépendances et automatiser les contrôles dans le CI/CD.

## Étape 5 — Dépendances & SBOM
- Dépendances directes : express@4.22.3
- Paquets dans l'arbre complet : 128
- npm audit : vulnérabilités trouvées : 0
- Composants dans sbom-src : 69
- Composants dans sbom-image : 285
- [x] Les deux SBOM sont générés (et ignorés par Git)
- [x] dependabot.yml est commité et les alertes sont activées

**Q.** Vous n'avez déclaré qu'une dépendance. Pourquoi l'arbre en contient-il autant ? Et pourquoi le SBOM de l'image est-il plus gros que celui du code source ?
Même si nous avons déclaré une seule dépendance directe (Express), celle-ci possède plusieurs dépendances transitives, ce qui explique la taille de l'arbre.

Le SBOM de l'image Docker est plus grand parce qu'il contient aussi les composants de Node.js et les paquets système d'Alpine Linux, comme musl et busybox.

Donc, nous avons 69 composants dans le code source et 285 dans l'image Docker.

## Étape 6 — Secrets
- Gitleaks : fuites trouvées sur le dépôt : no leaks found
- Gitleaks : fuites trouvées avec demo.env : leaks found: 1
- Nom de la règle déclenchée : generic-api-key
- [x] Le commit contenant demo.env a été refusé par le hook
- [x] demo.env est supprimé, rien n'a été poussé

**Q.** Le hook pre-commit est sur votre poste. Pourquoi faut-il quand même un scan de secrets dans le pipeline CI ? Et si un vrai secret avait été poussé, quelle serait la première action ?
Le hook pre-commit peut être contourné ou désactivé. Le scan CI ajoute une deuxième protection pour détecter les secrets.Révoquer immédiatement le secret compromis, puis le remplacer par un nouveau.

## Étape 7 — SAST
- Nombre de règles exécutées : 75
- Alertes (findings) : 0
- Alertes avec le Dockerfile naïf :  • Findings: 1 (1 blocking)  • Rules run: 7  • Targets scanned: 3

**Q.** Semgrep ne trouve rien (ou presque) sur votre code. Cela prouve-t-il que l'application est sûre ? Citez deux limites du SAST.
Non. L’absence de findings ne garantit pas que l’application est totalement sécurisée.
Faux négatifs
Faux positifs

## Étape 8 — Pipeline & portes
- Durée totale du pipeline (minutes) : —
- Job le plus long : —
- Porte 1 : jobs en échec : image
- Porte 2 : jobs en échec : SAST , IaC
- [x] Le pipeline complet est vert sur main
- [x] Les deux pull requests de test sont bloquées
- [x] Les branches de test sont fermées sans merge
- [x] Le SBOM est téléchargeable dans les artefacts

**Q.** Le pipeline utilise des images aquasec/trivy:latest, semgrep/semgrep, etc. sans version fixée. Quel risque cela crée-t-il pour la chaîne d'approvisionnement, et comment le réduire ?
L'utilisation d'images sans version précise peut entraîner des changements imprévus dans les outils utilisés et rendre les builds non reproductibles. Cela peut également introduire des vulnérabilités dans la chaîne d'approvisionnement. Pour réduire ce risque, il faut fixer les versions des images et utiliser leurs empreintes numériques (SHA256) afin de garantir leur intégrité.

**Q.** Le job Trivy utilise --ignore-unfixed et ne bloque que HIGH et CRITICAL. Justifiez ces deux choix, et dites ce qu'ils laissent passer.
L'option `--ignore-unfixed` permet d'ignorer les vulnérabilités qui ne disposent pas encore de correctif. Le blocage des niveaux HIGH et CRITICAL permet de donner la priorité aux risques les plus importants sans bloquer systématiquement le pipeline pour les vulnérabilités moins graves. Cependant, cette configuration peut laisser passer des vulnérabilités MEDIUM et LOW ainsi que des vulnérabilités sans correctif disponible.

## Étape 9 — Tri d'alertes
- Alerte 1 : Vrai positif · Bloquer la livraison maintenant (juste)
- Alerte 2 : Faux positif · Accepter et documenter l'exception (juste)
- Alerte 3 : Vrai positif · Backlog / surveiller (juste)
- Alerte 4 : Faux positif · Accepter et documenter l'exception (juste)
- Alerte 5 : Vrai positif · Bloquer la livraison maintenant (juste)
- Alerte 6 : Vrai positif · Corriger sous quelques jours (juste)
- Alerte 7 : Vrai positif · Backlog / surveiller (juste)
Score : 7/7

**Q.** Pour l'alerte que vous avez trouvée la plus difficile à classer, expliquez votre raisonnement.
L'alerte 5 est la plus difficile à classer. Le jeton GitHub a été supprimé du code, mais il reste présent dans l'historique Git. Il s'agit donc d'un vrai problème de sécurité, car une personne malveillante pourrait encore l'utiliser s'il est toujours valide. Il faut révoquer immédiatement le jeton, le remplacer si nécessaire et nettoyer l'historique Git. La suppression du code ne suffit pas à éliminer le risque.

## Bilan

**Q.** Placez chaque contrôle que vous avez mis en place sur la boucle Plan › Code › Build › Test › Release › Deploy › Operate › Monitor. Quelles étapes de la boucle restent sans contrôle dans votre pipeline ?
Les contrôles de sécurité sont répartis sur plusieurs étapes du cycle DevSecOps. Au niveau **Code**, le hook pre-commit permet de détecter les secrets, tandis que Semgrep réalise l'analyse statique du code (SAST). Pendant la phase **Build**, npm audit vérifie les dépendances, le SBOM recense les composants utilisés et Checkov contrôle la configuration du Dockerfile. Enfin, à l'étape **Release**, Trivy analyse l'image Docker et une porte de sécurité permet de bloquer la livraison en cas de vulnérabilités importantes.

Cependant, certaines étapes restent à améliorer. La phase **Plan** ne comprend pas encore de modélisation des menaces. La phase **Test** ne dispose pas de test dynamique (DAST). Pour **Deploy**, il manque la signature des images et des politiques de sécurité automatisées. Enfin, les phases **Operate et Monitor** nécessitent une surveillance continue, une centralisation des logs et des analyses régulières des images en production.

**Q.** Si vous deviez ajouter un seul contrôle de plus à ce pipeline, lequel choisiriez-vous et pourquoi ?
Si je devais ajouter un seul contrôle, je choisirais un test dynamique de sécurité des applications (DAST).

Ce contrôle permettrait de tester l'API en fonctionnement afin de détecter des vulnérabilités qui ne sont pas toujours visibles avec l'analyse statique du code ou l'analyse des dépendances. Il compléterait ainsi les contrôles existants et renforcerait la sécurité avant le déploiement.

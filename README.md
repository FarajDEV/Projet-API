# 📚 Collection de Scripts Bash

Ce repository contient deux scripts bash utilitaires pour Ubuntu 22.04+.

---

## 📋 Table des matières

- [Exercice 1 : DEV.TO API Manager](#exercice-1--devto-api-manager)
- [Exercice 2 : Server Monitoring](#exercice-2--server-monitoring)
- [Prérequis système](#prérequis-système)
- [Installation](#installation)

---

## 🚀 Exercice 1 : DEV.TO API Manager

### Description

Gestionnaire interactif complet pour l'API Dev.to permettant de lire, publier et gérer des articles directement depuis le terminal.

### Fonctionnalités

#### 📖 Lecture (sans authentification)
- Lire les derniers articles
- Chercher des articles par tag
- Voir les détails d'un article
- Consulter les tags populaires
- Voir les commentaires d'un article

#### ✍️ Écriture (avec API key)
- Publier un nouvel article
- Voir vos articles
- Modifier un article existant
- Statistiques personnelles

#### 🔧 Utilitaires
- Test de connexion à l'API
- Installation automatique des dépendances

### Configuration

Le script est pré-configuré avec :
- **API Key** : `fxt7nz7zeC3mvsHHnjQycd7N`
- **Username par défaut** : `faraj_cheniki_deea553679e`

### Utilisation

```bash
# Rendre le script exécutable
chmod +x Exercice_1.sh

# Lancer le script
./Exercice_1.sh
```

### Navigation dans le menu

```
1. Lire les derniers articles
2. Chercher des articles par tag
3. Voir les détails d'un article
4. Publier un nouvel article
5. Voir mes articles
6. Modifier un article
7. Voir les tags populaires
8. Voir les commentaires d'un article
9. Mes statistiques
T. Tester la connexion
0. Quitter
```

### Exemple : Publier un article

1. Choisir l'option `4` dans le menu
2. Entrer le titre de l'article
3. Saisir le contenu en Markdown (terminer avec `END`)
4. Ajouter des tags (optionnel)
5. Choisir de publier ou créer un brouillon

---

## 📊 Exercice 2 : Server Monitoring

### Description

Dashboard de monitoring serveur complet en temps réel, directement dans le terminal. Surveille CPU, mémoire, disque, uptime et processus avec système d'alertes.

### Fonctionnalités

- **Monitoring CPU** : Utilisation en temps réel avec nombre de cœurs
- **Monitoring Mémoire** : Usage, total, libre avec indicateurs visuels
- **Monitoring Disque** : Espace utilisé/disponible sur la partition racine
- **Uptime** : Temps d'activité du serveur
- **Top Processus** : Les 5 processus les plus gourmands en CPU
- **Système d'alertes** : Notifications automatiques selon les seuils

### Seuils d'alerte par défaut

- **CPU** : 90%
- **Mémoire** : 85%
- **Disque** : 90%

### Utilisation

```bash
# Rendre le script exécutable
chmod +x Exercice_2.sh

# Mode interactif (actualisation auto toutes les 5s)
./Exercice_2.sh

# Afficher une seule fois
./Exercice_2.sh --once

# Afficher uniquement le CPU
./Exercice_2.sh --cpu

# Afficher uniquement la mémoire
./Exercice_2.sh --memory

# Afficher uniquement le disque
./Exercice_2.sh --disk

# Afficher uniquement l'uptime
./Exercice_2.sh --uptime

# Afficher uniquement les alertes
./Exercice_2.sh --alerts

# Afficher uniquement les processus
./Exercice_2.sh --processes

# Afficher l'aide
./Exercice_2.sh --help
```

### Contrôles

- **Ctrl+C** : Arrêter le monitoring
- L'actualisation automatique se fait toutes les **5 secondes** en mode interactif

### Indicateurs visuels

Le script utilise des barres de progression colorées :
- 🟢 **Vert** : Utilisation normale (0-75%)
- 🟡 **Jaune** : Utilisation élevée (75-90%)
- 🔴 **Rouge** : Utilisation critique (>90%)

---

## 🔧 Prérequis système

### Pour les deux scripts

- **OS** : Ubuntu 22.04+ (ou distribution Debian-based)
- **Permissions** : Accès sudo pour l'installation des dépendances
- **Connexion internet** : Requise pour Exercice_1

### Dépendances

Les scripts installent automatiquement les dépendances nécessaires :

#### Exercice_1.sh
- `curl` : Requêtes HTTP vers l'API
- `jq` : Traitement des données JSON

#### Exercice_2.sh
- `bc` : Calculs mathématiques

---

## 📥 Installation

### Installation rapide

```bash
# Cloner ou télécharger les scripts
wget https://votre-repo/Exercice_1.sh
wget https://votre-repo/Exercice_2.sh

# Rendre les scripts exécutables
chmod +x Exercice_1.sh Exercice_2.sh

# Lancer le script souhaité
./Exercice_1.sh
# ou
./Exercice_2.sh
```

### Installation des dépendances manuellement (optionnel)

```bash
# Pour Exercice_1
sudo apt-get update
sudo apt-get install -y curl jq

# Pour Exercice_2
sudo apt-get install -y bc
```

---

## 🎨 Aperçu des interfaces

### Exercice_1 : DEV.TO API Manager
```
╔════════════════════════════════════════════════════════════════╗
║  ★ DEV.TO API MANAGER ★                                       ║
║  Gestionnaire Interactif pour l'API Dev.to                    ║
╚════════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════════╗
║ MENU PRINCIPAL                                                 ║
╠════════════════════════════════════════════════════════════════╣
║ LECTURE (pas besoin d'authentification)                       ║
║   1. Lire les derniers articles                               ║
║   2. Chercher des articles par tag                            ║
...
```

### Exercice_2 : Server Monitoring
```
╔════════════════════════════════════════════════════════════════════╗
║              🖥️  SERVER MONITORING DASHBOARD                      ║
╚════════════════════════════════════════════════════════════════════╝

Serveur: ubuntu-server
Mise à jour: 2026-01-09 14:30:45

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💻 CPU
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Utilisation: 45.3% [████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░]
Cœurs: 4
```

---

## ⚠️ Notes importantes

### Exercice_1
- L'API key fournie est à usage de démonstration
- Pour utiliser votre propre compte, modifiez les variables `API_KEY` et `DEFAULT_USERNAME` dans le script
- Les articles publiés sont réels et visibles sur dev.to

### Exercice_2
- Le script nécessite les permissions de lecture système
- Les seuils d'alerte peuvent être modifiés en éditant les variables en début de script
- Le monitoring peut consommer des ressources CPU si lancé en continu

---

## 🐛 Dépannage

### Exercice_1 : Erreur de connexion à l'API
```bash
# Tester la connexion
./Exercice_1.sh
# Choisir option T (Test de connexion)

# Vérifier manuellement
curl -s https://dev.to/api/articles?per_page=1
```

### Exercice_2 : Commande bc non trouvée
```bash
# Installer bc manuellement
sudo apt-get update
sudo apt-get install -y bc
```

### Permissions refusées
```bash
# Vérifier les permissions
ls -l Exercice_*.sh

# Ajouter les permissions d'exécution
chmod +x Exercice_1.sh Exercice_2.sh
```

---

## 📝 Licence

Ces scripts sont fournis "tels quels" à des fins éducatives.

---

## 👨‍💻 Auteur

Scripts créés pour des exercices pratiques de scripting Bash sur Ubuntu 22.04.

---

## 🤝 Contribution

Pour toute amélioration ou rapport de bug :
1. Testez sur Ubuntu 22.04
2. Documentez les changements
3. Vérifiez la compatibilité avec les deux scripts

---

**Dernière mise à jour** : Janvier 2026

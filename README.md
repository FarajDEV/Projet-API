# DEV.TO API Manager 🚀

Un gestionnaire d'API interactif en ligne de commande pour Dev.to avec authentification sécurisée et chiffrement AES-256.

## 📋 Fonctionnalités

### Lecture publique (sans authentification)
- 📖 Lire les derniers articles
- 🔍 Chercher des articles par tag
- 📊 Voir les détails d'un article
- 🏷️ Voir les tags populaires
- 💬 Voir les commentaires

### Fonctions authentifiées (API Key requise)
- ✍️ Publier un nouvel article
- 📝 Voir vos articles
- ✏️ Modifier un article
- 📈 Voir vos statistiques

### Sécurité
- 🔐 Chiffrement AES-256-CBC de l'API Key
- 🔑 Mot de passe maître pour déchiffrement
- 🛡️ Validation automatique de l'API Key
- 🔒 Authentification à la demande (smart auth)

## 🔧 Prérequis

- Système Linux/Unix ou macOS
- Bash 4.0+
- Connexion Internet

### Dépendances (installées automatiquement)
- `curl` - Pour les requêtes HTTP
- `jq` - Pour le parsing JSON
- `openssl` - Pour le chiffrement

## 📥 Installation

1. Téléchargez le script:
```bash
wget https://votre-url/devto-manager.sh
# ou
curl -O https://votre-url/devto-manager.sh
```

2. Rendez-le exécutable:
```bash
chmod +x devto-manager.sh
```

3. Lancez le script:
```bash
./devto-manager.sh
```

Les dépendances seront installées automatiquement au premier lancement.

## 🔑 Configuration de l'API Key

### Obtenir votre API Key

1. Connectez-vous sur [Dev.to](https://dev.to)
2. Allez sur [Settings > Extensions](https://dev.to/settings/extensions)
3. Générez une nouvelle API Key
4. Copiez la clé

### Première utilisation

Au premier lancement d'une fonction nécessitant l'authentification:

1. Le script vous demandera votre API Key
2. Entrez votre clé (la saisie est masquée pour la sécurité)
3. La clé sera validée automatiquement
4. Vous pourrez choisir de la sauvegarder de manière chiffrée
5. Si vous acceptez, créez un mot de passe maître (minimum 8 caractères)

### Utilisations suivantes

- Entrez simplement votre mot de passe maître
- L'API Key sera déchiffrée automatiquement
- En cas d'oubli du mot de passe, vous pourrez configurer une nouvelle clé

## 🎯 Utilisation

### Menu principal

```
======================================================
  MENU PRINCIPAL
======================================================

LECTURE PUBLIQUE (pas d'authentification)
  1. Lire les derniers articles
  2. Chercher des articles par tag
  3. Voir les détails d'un article
  7. Voir les tags populaires
  8. Voir les commentaires d'un article

FONCTIONS AUTHENTIFIÉES (API key requise)
  4. Publier un nouvel article
  5. Voir mes articles
  6. Modifier un article
  9. Mes statistiques

GESTION API KEY
  K. Changer/Configurer l'API Key
  I. Voir info API Key

  0. Quitter
```

### Exemples d'utilisation

#### Lire les derniers articles
```bash
# Sélectionnez l'option 1
# Choisissez le nombre d'articles (5, 10 ou 20)
```

#### Chercher par tag
```bash
# Sélectionnez l'option 2
# Choisissez un tag prédéfini ou entrez le vôtre
```

#### Publier un article
```bash
# Sélectionnez l'option 4
# Entrez le titre
# Entrez le contenu en Markdown (tapez END pour terminer)
# Ajoutez des tags (optionnel)
# Choisissez de publier ou créer un brouillon
```

#### Voir vos articles
```bash
# Sélectionnez l'option 5
# Utilisez votre username par défaut ou entrez-en un autre
```

## 🔒 Sécurité

### Chiffrement
- **Algorithme**: AES-256-CBC
- **Dérivation de clé**: PBKDF2 avec 100,000 itérations
- **Salt unique**: Généré automatiquement
- **Permissions**: Fichiers protégés (chmod 600)

### Fichiers créés
- `~/.devto_api_key.enc` - API Key chiffrée
- `~/.devto_salt` - Salt pour le chiffrement
- `/tmp/devto_installed` - Flag d'installation

### Bonnes pratiques
- ✅ Utilisez un mot de passe maître fort et unique
- ✅ Ne partagez jamais votre API Key
- ✅ Révoquez les clés non utilisées sur Dev.to
- ✅ Utilisez des permissions restrictives sur les fichiers

## 🛠️ Résolution de problèmes

### L'API Key ne fonctionne pas
- Vérifiez que la clé est toujours valide sur Dev.to
- Assurez-vous de copier la clé complète
- Utilisez l'option K pour reconfigurer

### Mot de passe maître oublié
- Utilisez l'option K pour configurer une nouvelle clé
- L'ancienne clé chiffrée sera supprimée

### Erreur de connexion
- Vérifiez votre connexion Internet
- Le timeout est fixé à 30 secondes par défaut
- Dev.to peut être temporairement indisponible

### Erreurs de parsing JSON
- Assurez-vous que `jq` est correctement installé
- Relancez le script pour une réinstallation

## 📚 API Dev.to

Ce script utilise l'[API officielle Dev.to](https://developers.forem.com/api).

### Endpoints utilisés
- `GET /api/articles` - Liste des articles
- `GET /api/articles?tag={tag}` - Articles par tag
- `GET /api/users/me` - Informations utilisateur
- `POST /api/articles` - Publier un article

### Rate Limiting
- Respecte les limites de l'API Dev.to
- Timeout de 30 secondes par requête

## 🤝 Contribution

Les contributions sont les bienvenues! Pour contribuer:

1. Fork le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Committez vos changements (`git commit -m 'Ajout fonctionnalité'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

## 📝 Changelog

### Version 1.0
- ✨ Authentification sécurisée avec chiffrement AES-256
- ✨ Smart auth (API Key demandée uniquement si nécessaire)
- ✨ Lecture d'articles sans authentification
- ✨ Publication et gestion d'articles
- ✨ Recherche par tags
- ✨ Interface interactive en français

## 📄 Licence

Ce projet est sous licence MIT. Vous êtes libre de l'utiliser, le modifier et le distribuer.

## 👤 Auteur

Créé pour faciliter l'utilisation de l'API Dev.to en ligne de commande.

## ⚠️ Avertissement

Ce script n'est pas affilié officiellement à Dev.to. Utilisez-le de manière responsable et respectez les conditions d'utilisation de Dev.to.

---

**Note**: Assurez-vous de garder votre API Key et votre mot de passe maître en sécurité. Ne les partagez jamais et ne les commitez pas dans un dépôt public.

Pour toute question ou problème, ouvrez une issue sur GitHub.

Happy coding! 🚀

# Server Monitoring Dashboard 📊

Un tableau de bord de surveillance système en temps réel pour Linux, léger et interactif, directement dans votre terminal.

## 🌟 Fonctionnalités

### Métriques surveillées
- 🖥️ **CPU** - Utilisation en temps réel avec nombre de cœurs
- 💾 **Mémoire** - RAM utilisée/disponible/libre
- 💿 **Disque** - Espace utilisé sur la partition racine
- ⏱️ **Uptime** - Temps d'activité du serveur
- 🔄 **Processus** - Top 5 des processus consommant le plus de CPU

### Système d'alertes
- 🔴 Alertes CPU (seuil par défaut: 90%)
- 🟡 Alertes Mémoire (seuil par défaut: 85%)
- 🟠 Alertes Disque (seuil par défaut: 90%)
- ⚠️ Niveaux d'alerte: WARNING et CRITIQUE

### Visualisation
- 📊 Barres de progression colorées
- 🎨 Indicateurs visuels avec codes couleurs (vert/jaune/rouge)
- 🔄 Actualisation automatique toutes les 5 secondes
- 📱 Interface claire et organisée

## 🔧 Prérequis

- Système Linux (Ubuntu, Debian, CentOS, etc.)
- Bash 4.0+
- Droits sudo (pour l'installation de dépendances si nécessaire)

### Dépendances
- `bc` - Calculatrice pour les comparaisons (installée automatiquement si absente)
- `top` - Informations processus (préinstallé)
- `free` - Informations mémoire (préinstallé)
- `df` - Informations disque (préinstallé)

## 📥 Installation

1. Téléchargez le script:
```bash
wget https://votre-url/server-monitor.sh
# ou
curl -O https://votre-url/server-monitor.sh
```

2. Rendez-le exécutable:
```bash
chmod +x server-monitor.sh
```

3. Lancez le script:
```bash
./server-monitor.sh
```

La dépendance `bc` sera installée automatiquement si elle est manquante.

## 🎯 Utilisation

### Mode interactif (par défaut)
Affiche le tableau de bord complet avec actualisation automatique toutes les 5 secondes:

```bash
./server-monitor.sh
```

### Affichage unique
Affiche le tableau de bord une seule fois sans actualisation:

```bash
./server-monitor.sh --once
```

### Affichage par métrique

Afficher uniquement une métrique spécifique:

```bash
# CPU uniquement
./server-monitor.sh --cpu

# Mémoire uniquement
./server-monitor.sh --memory
# ou
./server-monitor.sh --mem

# Disque uniquement
./server-monitor.sh --disk

# Uptime uniquement
./server-monitor.sh --uptime

# Résumé des alertes uniquement
./server-monitor.sh --alerts

# Top processus uniquement
./server-monitor.sh --processes
# ou
./server-monitor.sh --proc
```

### Aide
Afficher l'aide et les options disponibles:

```bash
./server-monitor.sh --help
```

## 📊 Exemple de sortie

```
========================================================
         SERVER MONITORING DASHBOARD
========================================================

Serveur: web-server-01
Mise à jour: 2026-01-09 14:35:22

========================================================
RÉSUMÉ DES ALERTES
========================================================
✅ Aucune alerte - Tous les systèmes fonctionnent normalement

========================================================
CPU
========================================================
Utilisation: 45.3% [█████████████████████████░░░░░░░░░░░░░░░░░░░░░░░]
Cœurs: 8

========================================================
MÉMOIRE
========================================================
Utilisation: 67.8% [█████████████████████████████████░░░░░░░░░░░░░░░]
Utilisée: 10.8 Go / Total: 16.0 Go / Libre: 5.2 Go

========================================================
DISQUE
========================================================
Utilisation: 42% [█████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░]
Utilisé: 84 Go / Total: 200 Go / Libre: 116 Go

========================================================
UPTIME
========================================================
Temps d'activité: 15 days, 7 hours, 23 minutes

========================================================
TOP 5 PROCESSUS (CPU)
========================================================
PID       CPU%    MEM%    COMMANDE
1234      12.5%   3.2%    /usr/bin/node
5678      8.3%    2.1%    /usr/sbin/mysqld
9012      5.7%    1.8%    python3
3456      3.2%    0.9%    nginx
7890      2.1%    0.5%    sshd

========================================================
Appuyez sur Ctrl+C pour quitter | Auto-refresh toutes les 5 secondes
========================================================
```

## ⚙️ Configuration

### Modifier les seuils d'alerte

Éditez les variables en haut du script:

```bash
# Seuils d'alerte (en %)
CPU_THRESHOLD=90        # Alerte si CPU > 90%
MEMORY_THRESHOLD=85     # Alerte si Mémoire > 85%
DISK_THRESHOLD=90       # Alerte si Disque > 90%
```

### Personnaliser l'intervalle de rafraîchissement

Modifiez la ligne dans la fonction `interactive_mode()`:

```bash
sleep 5  # Changez 5 en nombre de secondes souhaité
```

## 🎨 Codes couleurs

Le script utilise un système de couleurs pour faciliter la lecture:

- 🟢 **Vert** - Utilisation normale (0-75%)
- 🟡 **Jaune** - Utilisation élevée (75-90%)
- 🔴 **Rouge** - Utilisation critique (>90%)

## 🚀 Cas d'usage

### Surveillance continue d'un serveur de production
```bash
./server-monitor.sh
```
Laissez tourner dans un terminal ou une session `tmux`/`screen`

### Vérification rapide avant déploiement
```bash
./server-monitor.sh --once
```

### Surveillance CPU lors d'un test de charge
```bash
watch -n 2 './server-monitor.sh --cpu'
```

### Monitoring avec tmux
```bash
tmux new-session -d -s monitor './server-monitor.sh'
tmux attach -t monitor
```

### Cron pour alertes par email
Créez un script wrapper qui envoie un email si des alertes sont détectées:

```bash
#!/bin/bash
OUTPUT=$(./server-monitor.sh --alerts)
if echo "$OUTPUT" | grep -q "🔴\|🟡"; then
    echo "$OUTPUT" | mail -s "Alerte Serveur" admin@example.com
fi
```

Ajoutez à crontab pour vérification toutes les 15 minutes:
```bash
*/15 * * * * /path/to/alert-wrapper.sh
```

## 🛠️ Résolution de problèmes

### Le script ne s'exécute pas
```bash
# Vérifiez les permissions
ls -l server-monitor.sh

# Rendez-le exécutable
chmod +x server-monitor.sh
```

### Erreur "bc: command not found"
Le script devrait installer `bc` automatiquement. Si ça échoue:
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y bc

# CentOS/RHEL
sudo yum install -y bc

# Fedora
sudo dnf install -y bc
```

### Les barres de progression ne s'affichent pas correctement
Assurez-vous que votre terminal supporte les caractères UTF-8:
```bash
echo $LANG
# Devrait afficher quelque chose comme: en_US.UTF-8
```

### Les pourcentages semblent incorrects
Certaines distributions calculent l'utilisation mémoire différemment. Le script utilise la commande standard `free -m`.

### Le script s'arrête immédiatement
Si vous êtes en mode interactif, utilisez `Ctrl+C` pour quitter proprement.

## 📈 Fonctionnalités avancées

### Surveillance de partitions spécifiques

Modifiez la fonction `get_disk_info()` pour surveiller une autre partition:

```bash
get_disk_info() {
    df -BG /home | awk 'NR==2{gsub(/G/,"",$3); gsub(/G/,"",$2); gsub(/G/,"",$4); gsub(/%/,"",$5); print $3, $2, $4, $5}'
}
```

### Ajouter d'autres métriques

Le script est facilement extensible. Exemple pour ajouter la température CPU:

```bash
get_cpu_temp() {
    sensors | grep 'Core 0' | awk '{print $3}' | sed 's/+//' | sed 's/°C//'
}
```

### Export en JSON

Pour intégration avec d'autres outils:

```bash
# Ajoutez une fonction d'export
export_json() {
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_info | awk '{print $4}')
    
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "cpu_usage": $cpu,
  "memory_usage": $mem,
  "hostname": "$(hostname)"
}
EOF
}
```

## 🔒 Sécurité

- Le script nécessite uniquement des droits de lecture sur `/proc` et `/sys`
- Aucune modification système n'est effectuée (sauf installation de `bc`)
- Pas de collecte de données externe
- Fonctionne entièrement en local

## 🤝 Contribution

Les contributions sont les bienvenues! Pour contribuer:

1. Fork le projet
2. Créez une branche (`git checkout -b feature/nouvelle-metrique`)
3. Committez vos changements (`git commit -m 'Ajout métrique réseau'`)
4. Push vers la branche (`git push origin feature/nouvelle-metrique`)
5. Ouvrez une Pull Request

### Idées de contributions
- 📡 Ajout de métriques réseau (bande passante, connexions)
- 🌡️ Surveillance température CPU/GPU
- 📊 Export des métriques (CSV, JSON, InfluxDB)
- 🔔 Notifications (email, Slack, Discord)
- 📱 Interface web complémentaire
- 🐳 Support Docker/conteneurs

## 📝 Changelog

### Version 1.0
- ✨ Surveillance CPU, Mémoire, Disque
- ✨ Système d'alertes à trois niveaux
- ✨ Barres de progression colorées
- ✨ Mode interactif avec auto-refresh
- ✨ Affichage par métrique
- ✨ Top 5 processus CPU
- ✨ Support multi-cœurs CPU

## 📄 Licence

Ce projet est sous licence MIT. Vous êtes libre de l'utiliser, le modifier et le distribuer.

## 👤 Auteur

Créé pour simplifier la surveillance système en ligne de commande.

## 💡 Alternatives

Si vous cherchez des solutions plus complètes:

- **htop** - Moniteur système interactif
- **glances** - Surveillance système avancée en Python
- **netdata** - Monitoring en temps réel avec interface web
- **prometheus + grafana** - Stack complète pour production

Ce script est idéal pour une surveillance légère, rapide et sans dépendances lourdes!

---

**Astuce**: Utilisez ce script avec `tmux` ou `screen` pour le laisser tourner en arrière-plan sur vos serveurs!

Pour toute question ou suggestion, ouvrez une issue sur GitHub.

Happy monitoring! 📊🚀

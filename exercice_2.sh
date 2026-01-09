#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Seuils d'alerte
CPU_THRESHOLD=90
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90

# Effacer l'écran
clear_screen() {
    clear
}

# Obtenir l'utilisation CPU
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

# Obtenir le nombre de cœurs
get_cpu_cores() {
    nproc
}

# Obtenir l'utilisation mémoire
get_memory_info() {
    free -m | awk 'NR==2{printf "%.1f %.1f %.1f %.1f", $3/1024, $2/1024, $4/1024, $3*100/$2 }'
}

# Obtenir l'utilisation disque
get_disk_info() {
    df -BG / | awk 'NR==2{gsub(/G/,"",$3); gsub(/G/,"",$2); gsub(/G/,"",$4); gsub(/%/,"",$5); print $3, $2, $4, $5}'
}

# Obtenir l'uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Obtenir le hostname
get_hostname() {
    hostname
}

# Obtenir la date/heure
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Créer une barre de progression
create_progress_bar() {
    local percent=$1
    local width=50
    
    local percent_int=$(printf "%.0f" "$percent")
    local filled=$((percent_int * width / 100))
    local empty=$((width - filled))
    
    local color=$GREEN
    local is_high=$(echo "$percent > 90" | bc -l)
    local is_medium=$(echo "$percent > 75" | bc -l)
    
    if [ "$is_high" -eq 1 ]; then
        color=$RED
    elif [ "$is_medium" -eq 1 ]; then
        color=$YELLOW
    fi
    
    echo -ne "${color}["
    printf '%*s' "$filled" | tr ' ' '█'
    printf '%*s' "$empty" | tr ' ' '░'
    echo -ne "]${NC}"
}

# Afficher le header
display_header() {
    echo ""
    echo "========================================================"
    echo "         SERVER MONITORING DASHBOARD"
    echo "========================================================"
    echo ""
    echo "Serveur: $(get_hostname)"
    echo "Mise à jour: $(get_timestamp)"
    echo ""
}

# Afficher les métriques CPU
display_cpu() {
    local cpu_usage=$(get_cpu_usage)
    local cpu_cores=$(get_cpu_cores)
    
    echo "========================================================"
    echo "CPU"
    echo "========================================================"
    
    printf "Utilisation: %.1f%% " "$cpu_usage"
    create_progress_bar "$cpu_usage"
    echo ""
    echo "Cœurs: ${cpu_cores}"
    
    local is_alert=$(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l)
    if [ "$is_alert" -eq 1 ]; then
        echo "⚠️  ALERTE: CPU à ${cpu_usage}% (seuil: ${CPU_THRESHOLD}%)"
    fi
    echo ""
}

# Afficher les métriques mémoire
display_memory() {
    read used total free percent <<< $(get_memory_info)
    
    echo "========================================================"
    echo "MÉMOIRE"
    echo "========================================================"
    
    printf "Utilisation: %.1f%% " "$percent"
    create_progress_bar "$percent"
    echo ""
    echo "Utilisée: ${used} Go / Total: ${total} Go / Libre: ${free} Go"
    
    local is_alert=$(echo "$percent > $MEMORY_THRESHOLD" | bc -l)
    if [ "$is_alert" -eq 1 ]; then
        local level="WARNING"
        local color=$YELLOW
        local is_critical=$(echo "$percent > 90" | bc -l)
        if [ "$is_critical" -eq 1 ]; then
            level="CRITIQUE"
            color=$RED
        fi
        printf "⚠️  ALERTE ${level}: Mémoire à %.1f%% (seuil: ${MEMORY_THRESHOLD}%%)\n" "$percent"
    fi
    echo ""
}

# Afficher les métriques disque
display_disk() {
    read used total free percent <<< $(get_disk_info)
    
    echo "========================================================"
    echo "DISQUE"
    echo "========================================================"
    
    printf "Utilisation: %s%% " "$percent"
    create_progress_bar "$percent"
    echo ""
    echo "Utilisé: ${used} Go / Total: ${total} Go / Libre: ${free} Go"
    
    if [ "$percent" -gt "$DISK_THRESHOLD" ]; then
        local level="WARNING"
        local color=$YELLOW
        if [ "$percent" -gt 95 ]; then
            level="CRITIQUE"
            color=$RED
        fi
        echo "⚠️  ALERTE ${level}: Disque à ${percent}% (seuil: ${DISK_THRESHOLD}%)"
    fi
    echo ""
}

# Afficher l'uptime
display_uptime() {
    local uptime=$(get_uptime)
    
    echo "========================================================"
    echo "UPTIME"
    echo "========================================================"
    echo "Temps d'activité: ${uptime}"
    echo ""
}

# Afficher les processus principaux
display_top_processes() {
    echo "========================================================"
    echo "TOP 5 PROCESSUS (CPU)"
    echo "========================================================"
    echo "PID       CPU%    MEM%    COMMANDE"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-10s %-7s %-7s %s\n", $2, $3"%", $4"%", $11}'
    echo ""
}

# Afficher le résumé des alertes
display_alerts_summary() {
    local cpu_usage=$(get_cpu_usage)
    read used total free mem_percent <<< $(get_memory_info)
    read used_disk total_disk free_disk disk_percent <<< $(get_disk_info)
    
    local alert_count=0
    
    echo "========================================================"
    echo "RÉSUMÉ DES ALERTES"
    echo "========================================================"
    
    local is_cpu_alert=$(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l)
    if [ "$is_cpu_alert" -eq 1 ]; then
        printf "🔴 CPU: %.1f%% (seuil: ${CPU_THRESHOLD}%%)\n" "$cpu_usage"
        ((alert_count++))
    fi
    
    local is_mem_alert=$(echo "$mem_percent > $MEMORY_THRESHOLD" | bc -l)
    if [ "$is_mem_alert" -eq 1 ]; then
        printf "🟡 MÉMOIRE: %.1f%% (seuil: ${MEMORY_THRESHOLD}%%)\n" "$mem_percent"
        ((alert_count++))
    fi
    
    if [ "$disk_percent" -gt "$DISK_THRESHOLD" ]; then
        echo "🟡 DISQUE: ${disk_percent}% (seuil: ${DISK_THRESHOLD}%)"
        ((alert_count++))
    fi
    
    if [ $alert_count -eq 0 ]; then
        echo "✅ Aucune alerte - Tous les systèmes fonctionnent normalement"
    else
        echo "Total: ${alert_count} alerte(s) active(s)"
    fi
    echo ""
}

# Afficher le footer
display_footer() {
    echo "========================================================"
    echo "Appuyez sur Ctrl+C pour quitter | Auto-refresh toutes les 5 secondes"
    echo "========================================================"
}

# Afficher tout
display_all() {
    clear_screen
    display_header
    display_alerts_summary
    display_cpu
    display_memory
    display_disk
    display_uptime
    display_top_processes
    display_footer
}

# Mode interactif
interactive_mode() {
    echo "Mode interactif activé!"
    echo ""
    
    while true; do
        display_all
        sleep 5
    done
}

# Afficher une seule métrique
show_metric() {
    case $1 in
        cpu)
            clear_screen
            display_header
            display_cpu
            ;;
        memory|mem)
            clear_screen
            display_header
            display_memory
            ;;
        disk)
            clear_screen
            display_header
            display_disk
            ;;
        uptime)
            clear_screen
            display_header
            display_uptime
            ;;
        alerts)
            clear_screen
            display_header
            display_alerts_summary
            ;;
        processes|proc)
            clear_screen
            display_header
            display_top_processes
            ;;
        *)
            echo "Métrique inconnue: $1"
            echo "Disponibles: cpu, memory, disk, uptime, alerts, processes"
            exit 1
            ;;
    esac
}

# Afficher l'aide
show_help() {
    echo "Server Monitoring - Aide"
    echo ""
    echo "Usage:"
    echo "  $0              # Mode interactif (actualisation auto toutes les 5s)"
    echo "  $0 --once       # Afficher une seule fois"
    echo "  $0 --cpu        # Afficher uniquement CPU"
    echo "  $0 --memory     # Afficher uniquement mémoire"
    echo "  $0 --disk       # Afficher uniquement disque"
    echo "  $0 --uptime     # Afficher uniquement uptime"
    echo "  $0 --alerts     # Afficher uniquement alertes"
    echo "  $0 --processes  # Afficher uniquement top processus"
    echo "  $0 --help       # Afficher cette aide"
    echo ""
    echo "Configuration des seuils d'alerte:"
    echo "  CPU: ${CPU_THRESHOLD}%"
    echo "  Mémoire: ${MEMORY_THRESHOLD}%"
    echo "  Disque: ${DISK_THRESHOLD}%"
    echo ""
}

# Gestion du signal d'interruption
trap 'echo "Monitoring arrêté."; exit 0' INT TERM

# Point d'entrée principal
main() {
    # Vérifier que bc est installé
    if ! command -v bc &> /dev/null; then
        echo "Installation de bc (calculatrice)..."
        sudo apt-get update -qq && sudo apt-get install -y bc -qq
    fi
    
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --once)
            display_all
            ;;
        --cpu)
            show_metric cpu
            ;;
        --memory|--mem)
            show_metric memory
            ;;
        --disk)
            show_metric disk
            ;;
        --uptime)
            show_metric uptime
            ;;
        --alerts)
            show_metric alerts
            ;;
        --processes|--proc)
            show_metric processes
            ;;
        "")
            interactive_mode
            ;;
        *)
            echo "Option inconnue: $1"
            echo "Utilisez --help pour voir les options disponibles"
            exit 1
            ;;
    esac
}

# Lancer le script
main "$@"

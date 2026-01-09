#!/bin/bash

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables de configuration
API_KEY=""
API_KEY_LOADED=false
API_BASE_URL="https://dev.to/api"
DEFAULT_USERNAME="faraj_cheniki_deea553679e"
ENCRYPTED_KEY_FILE="$HOME/.devto_api_key.enc"
SALT_FILE="$HOME/.devto_salt"

# Générer un salt unique
generate_salt() {
    if [ ! -f "$SALT_FILE" ]; then
        openssl rand -hex 16 > "$SALT_FILE"
        chmod 600 "$SALT_FILE"
    fi
}

# Chiffrer l'API Key
encrypt_api_key() {
    local key="$1"
    local password="$2"
    
    generate_salt
    
    echo "$key" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -pass pass:"$password" -out "$ENCRYPTED_KEY_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        chmod 600 "$ENCRYPTED_KEY_FILE"
        return 0
    else
        return 1
    fi
}

# Déchiffrer l'API Key
decrypt_api_key() {
    local password="$1"
    
    if [ ! -f "$ENCRYPTED_KEY_FILE" ]; then
        return 1
    fi
    
    local decrypted=$(openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -pass pass:"$password" -in "$ENCRYPTED_KEY_FILE" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$decrypted" ]; then
        echo "$decrypted"
        return 0
    else
        return 1
    fi
}

# Valider l'API Key
validate_api_key() {
    local key="$1"
    
    echo "Validation de l'API Key..."
    
    local response=$(curl -s --max-time 10 \
        -H "api-key: $key" \
        -H "Content-Type: application/json" \
        "$API_BASE_URL/users/me" 2>&1)
    
    if echo "$response" | jq -e '.username' > /dev/null 2>&1; then
        local username=$(echo "$response" | jq -r '.username')
        echo "API Key valide!"
        echo "Connecté en tant que: @$username"
        return 0
    else
        echo "API Key invalide ou expirée"
        return 1
    fi
}

# Charger l'API Key
load_api_key_if_needed() {
    if [ "$API_KEY_LOADED" = true ]; then
        return 0
    fi
    
    echo ""
    echo "AUTHENTIFICATION REQUISE"
    echo ""
    
    if [ -f "$ENCRYPTED_KEY_FILE" ]; then
        echo "API Key chiffrée trouvée"
        echo ""
        echo "Entrez votre mot de passe maître pour déchiffrer:"
        echo -n "Mot de passe (invisible): "
        read -s master_password
        echo ""
        
        if [ -z "$master_password" ]; then
            echo "Mot de passe requis!"
            return 1
        fi
        
        echo ""
        echo "Déchiffrement en cours..."
        
        local decrypted_key=$(decrypt_api_key "$master_password")
        
        if [ $? -eq 0 ] && [ -n "$decrypted_key" ]; then
            API_KEY="$decrypted_key"
            echo "API Key déchiffrée avec succès!"
            
            if validate_api_key "$API_KEY"; then
                API_KEY_LOADED=true
                pause
                return 0
            else
                echo "La clé déchiffrée ne fonctionne plus"
                API_KEY=""
                echo ""
                echo -n "Voulez-vous en configurer une nouvelle? (o/n): "
                read retry
                if [ "$retry" = "o" ]; then
                    configure_new_api_key
                    return $?
                else
                    return 1
                fi
            fi
        else
            echo "Mot de passe incorrect!"
            echo ""
            echo -n "Voulez-vous réessayer? (o/n): "
            read retry
            if [ "$retry" = "o" ]; then
                load_api_key_if_needed
                return $?
            else
                return 1
            fi
        fi
    else
        configure_new_api_key
        return $?
    fi
}

# Configurer une nouvelle API Key
configure_new_api_key() {
    echo ""
    echo "Configuration d'une nouvelle API Key"
    echo ""
    echo "Comment obtenir votre API Key:"
    echo "1. Allez sur https://dev.to/settings/extensions"
    echo "2. Générez une nouvelle clé API"
    echo "3. Copiez la clé"
    echo ""
    echo "ATTENTION: Votre saisie sera masquée"
    echo ""
    
    local new_key=""
    while true; do
        echo -n "Entrez votre API Key (invisible): "
        read -s new_key
        echo ""
        
        if [ -z "$new_key" ]; then
            echo "API Key obligatoire!"
            echo ""
            echo -n "Voulez-vous réessayer? (o/n): "
            read retry
            if [ "$retry" != "o" ]; then
                return 1
            fi
            continue
        fi
        
        echo ""
        echo "Clé saisie: ${new_key:0:8}...${new_key: -4} (masquée)"
        echo -n "Est-ce correct? (o/n): "
        read confirm
        
        if [ "$confirm" = "o" ]; then
            break
        fi
        echo ""
        echo "Veuillez ressaisir..."
        echo ""
    done
    
    echo ""
    if validate_api_key "$new_key"; then
        API_KEY="$new_key"
        
        echo ""
        echo "Voulez-vous sauvegarder cette clé de manière chiffrée?"
        echo "(Recommandé - vous devrez créer un mot de passe maître)"
        echo -n "Sauvegarder? (o/n): "
        read save_choice
        
        if [ "$save_choice" = "o" ]; then
            save_encrypted_key "$API_KEY"
        else
            echo "Clé utilisée uniquement pour cette session"
        fi
        
        API_KEY_LOADED=true
        echo ""
        pause
        return 0
    else
        echo "Impossible de valider l'API Key"
        echo ""
        echo -n "Voulez-vous réessayer? (o/n): "
        read retry
        if [ "$retry" = "o" ]; then
            configure_new_api_key
            return $?
        else
            return 1
        fi
    fi
}

# Sauvegarder l'API Key chiffrée
save_encrypted_key() {
    local key="$1"
    
    echo ""
    echo "Création du mot de passe maître"
    echo ""
    echo "Ce mot de passe sera nécessaire à chaque utilisation"
    echo "Choisissez quelque chose de mémorable mais sécurisé (min 8 caractères)"
    echo ""
    
    local master_password=""
    local confirm_password=""
    
    while true; do
        echo -n "Mot de passe maître (invisible): "
        read -s master_password
        echo ""
        
        if [ -z "$master_password" ]; then
            echo "Le mot de passe ne peut pas être vide!"
            continue
        fi
        
        if [ ${#master_password} -lt 8 ]; then
            echo "Le mot de passe doit faire au moins 8 caractères!"
            continue
        fi
        
        echo -n "Confirmer le mot de passe (invisible): "
        read -s confirm_password
        echo ""
        
        if [ "$master_password" != "$confirm_password" ]; then
            echo "Les mots de passe ne correspondent pas!"
            echo ""
            continue
        fi
        
        break
    done
    
    echo ""
    echo "Chiffrement de l'API Key avec AES-256..."
    
    if encrypt_api_key "$key" "$master_password"; then
        echo "API Key chiffrée et sauvegardée!"
        echo ""
        echo "Emplacement: $ENCRYPTED_KEY_FILE"
        return 0
    else
        echo "Erreur lors du chiffrement"
        return 1
    fi
}

# Vérifier si API Key est nécessaire
requires_api_key() {
    local choice="$1"
    
    case $choice in
        1|2|3|7|8|t|T)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Affichage du titre
print_title() {
    clear
    echo "========================================================"
    echo "  DEV.TO API MANAGER - SMART AUTH"
    echo "  API Key demandée uniquement quand nécessaire"
    echo "========================================================"
    echo ""
}

# Affichage de section
print_section() {
    echo ""
    echo "== $1 =="
    echo ""
}

# Fonctions d'affichage simplifiées
print_success() {
    echo "✓ $1"
}

print_error() {
    echo "✗ $1"
}

print_info() {
    echo "ℹ $1"
}

print_warning() {
    echo "⚠ $1"
}

# Pause
pause() {
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

# Installation des dépendances
install_dependencies() {
    print_title
    echo "INSTALLATION DES DÉPENDANCES"
    echo ""

    echo "Vérification des outils nécessaires..."
    echo ""

    if ! command -v openssl &> /dev/null; then
        echo "Installation de openssl..."
        sudo apt-get update -qq
        sudo apt-get install -y openssl -qq
    fi

    if ! command -v curl &> /dev/null; then
        echo "Installation de curl..."
        sudo apt-get update -qq
        sudo apt-get install -y curl -qq
    fi

    if ! command -v jq &> /dev/null; then
        echo "Installation de jq..."
        sudo apt-get install -y jq -qq
    fi

    echo ""
    echo "Toutes les dépendances sont installées!"

    return 0
}

# Appel API
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local url="${API_BASE_URL}${endpoint}"

    local curl_cmd="curl -s --max-time 30 -w '\n%{http_code}'"
    curl_cmd="$curl_cmd -X $method"
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    curl_cmd="$curl_cmd -H 'User-Agent: DevToManager/1.0'"

    if [ "$method" != "GET" ] || [[ "$endpoint" == *"/me"* ]]; then
        curl_cmd="$curl_cmd -H 'api-key: $API_KEY'"
    fi

    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi

    curl_cmd="$curl_cmd '$url'"

    local response
    response=$(eval $curl_cmd 2>&1)
    local curl_exit=$?

    if [ $curl_exit -ne 0 ]; then
        echo "Erreur de connexion (code: $curl_exit)"
        return 1
    fi

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "201" ]]; then
        echo "$body"
        return 0
    else
        echo "$body"
        return 1
    fi
}

# Lire les articles
function_read_articles() {
    print_title
    echo "LIRE LES DERNIERS ARTICLES"
    echo ""

    echo "Combien d'articles voulez-vous voir?"
    echo "1) 5 articles"
    echo "2) 10 articles"
    echo "3) 20 articles"
    echo ""
    echo -n "Votre choix (1-3): "
    read choice

    case $choice in
        1) per_page=5 ;;
        2) per_page=10 ;;
        3) per_page=20 ;;
        *) per_page=5 ;;
    esac

    echo ""
    echo "Récupération des $per_page derniers articles..."
    echo ""

    response=$(api_call "GET" "/articles?per_page=$per_page" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            echo "Articles récupérés avec succès!"
            echo ""
            echo "$response" | jq -r '.[] | "
ID: \(.id)
Titre: \(.title)
Auteur: \(.user.username)
Réactions: ♥  \(.public_reactions_count) | 💬 \(.comments_count)
URL: \(.url)
----------------------------------------"'
        else
            echo "Réponse invalide du serveur"
        fi
    else
        echo "Erreur lors de la récupération des articles"
    fi

    pause
}

# Chercher par tag
function_search_by_tag() {
    print_title
    echo "CHERCHER DES ARTICLES PAR TAG"
    echo ""

    echo "Choisissez un tag:"
    echo "1) javascript"
    echo "2) python"
    echo "3) webdev"
    echo "4) tutorial"
    echo "5) devops"
    echo "6) beginners"
    echo "7) Autre (taper le nom)"
    echo ""
    echo -n "Votre choix (1-7): "
    read choice

    case $choice in
        1) tag="javascript" ;;
        2) tag="python" ;;
        3) tag="webdev" ;;
        4) tag="tutorial" ;;
        5) tag="devops" ;;
        6) tag="beginners" ;;
        7)
            echo -n "Entrez le nom du tag: "
            read tag
            ;;
        *) tag="javascript" ;;
    esac

    echo ""
    echo "Recherche des articles avec le tag #$tag..."
    echo ""

    response=$(api_call "GET" "/articles?tag=$tag&per_page=10" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            echo "Articles trouvés!"
            echo ""
            echo "$response" | jq -r '.[] | "
ID: \(.id)
Titre: \(.title)
Auteur: \(.user.username)
Tags: \(.tag_list | join(", "))
URL: \(.url)
----------------------------------------"'
        else
            echo "Aucun article trouvé"
        fi
    else
        echo "Erreur lors de la recherche"
    fi

    pause
}

# Publier un article
function_publish_article() {
    print_title
    echo "PUBLIER UN NOUVEL ARTICLE"
    echo ""

    echo "Remplissez les informations de votre article:"
    echo ""

    echo "Titre de l'article:"
    read -e title

    if [ -z "$title" ]; then
        echo "Le titre est obligatoire!"
        pause
        return
    fi

    echo ""
    echo "Contenu (en Markdown):"
    echo "(Tapez END sur une ligne seule pour terminer)"
    body=""
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        body+="$line\n"
    done

    if [ -z "$body" ]; then
        echo "Le contenu est obligatoire!"
        pause
        return
    fi

    echo ""
    echo "Tags (séparés par des virgules, max 4):"
    read -e tags

    echo ""
    echo "Publier immédiatement?"
    echo "1) Non, créer un brouillon"
    echo "2) Oui, publier maintenant"
    echo -n "Votre choix (1-2): "
    read pub_choice

    if [ "$pub_choice" = "2" ]; then
        published="true"
    else
        published="false"
    fi

    article_json=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        --argjson published $published \
        '{article: {title: $title, body_markdown: $body, published: $published}}')

    if [ -n "$tags" ]; then
        tags_array=$(echo "$tags" | jq -R 'split(",")')
        article_json=$(echo "$article_json" | jq --argjson tags "$tags_array" '.article.tags = $tags')
    fi

    echo ""
    echo "Publication de l'article..."
    echo ""

    response=$(api_call "POST" "/articles" "$article_json")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
            article_id=$(echo "$response" | jq -r '.id')
            article_url=$(echo "$response" | jq -r '.url')

            echo "Article publié avec succès!"
            echo ""
            echo "================================"
            echo "ID de l'article: $article_id"
            echo "URL: $article_url"
            if [ "$published" = "false" ]; then
                echo "Statut: BROUILLON (non publié)"
            else
                echo "Statut: PUBLIÉ"
            fi
            echo "================================"
        else
            echo "Erreur lors de la publication"
        fi
    else
        echo "Erreur lors de la publication"
    fi

    pause
}

# Mes articles
function_my_articles() {
    print_title
    echo "MES ARTICLES"
    echo ""

    echo "Nom d'utilisateur Dev.to:"
    echo "Par défaut: $DEFAULT_USERNAME"
    echo "Appuyez sur Entrée pour utiliser le défaut:"
    echo -n "Username: "
    read username

    if [ -z "$username" ]; then
        username="$DEFAULT_USERNAME"
        echo "→ Utilisation du username par défaut: $username"
    fi

    echo ""
    echo "Récupération des articles de @$username..."
    echo ""

    response=$(api_call "GET" "/articles?username=$username&state=all" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            count=$(echo "$response" | jq 'length')
            echo "$count article(s) trouvé(s)!"
            echo ""
            echo "$response" | jq -r '.[] | "
ID: \(.id)
Titre: \(.title)
Statut: \(if .published then "✓ Publié" else "✗ Brouillon" end)
Réactions: ♥  \(.public_reactions_count) | 💬 \(.comments_count)
URL: \(.url)
----------------------------------------"'
        else
            echo "Aucun article trouvé"
        fi
    else
        echo "Erreur lors de la récupération"
    fi

    pause
}

# Changer API Key
function_change_api_key() {
    print_title
    echo "CHANGER L'API KEY"
    
    echo ""
    if [ "$API_KEY_LOADED" = true ]; then
        echo "Clé actuelle: ${API_KEY:0:8}...${API_KEY: -4} (masquée)"
    else
        echo "Aucune API Key actuellement chargée"
    fi
    
    echo ""
    echo "Voulez-vous configurer une nouvelle API Key?"
    echo -n "Confirmer (o/n): "
    read confirm
    
    if [ "$confirm" != "o" ]; then
        echo "Opération annulée"
        pause
        return
    fi
    
    if [ -f "$ENCRYPTED_KEY_FILE" ]; then
        rm "$ENCRYPTED_KEY_FILE"
        echo "Ancienne clé supprimée"
    fi
    
    API_KEY=""
    API_KEY_LOADED=false
    
    configure_new_api_key
}

# Info API Key
function_api_key_info() {
    print_title
    echo "INFORMATIONS API KEY"
    
    echo ""
    
    if [ "$API_KEY_LOADED" = false ]; then
        echo "Aucune API Key chargée actuellement"
        echo ""
        echo "L'API Key sera demandée lorsque vous utiliserez une fonction qui en a besoin"
        pause
        return
    fi
    
    echo "Clé actuelle: ${API_KEY:0:8}...${API_KEY: -4} (masquée)"
    echo ""
    
    echo "Récupération des informations de votre compte..."
    echo ""
    
    response=$(curl -s --max-time 10 \
        -H "api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        "$API_BASE_URL/users/me")
    
    if echo "$response" | jq -e '.username' > /dev/null 2>&1; then
        echo "Connexion réussie!"
        echo ""
        echo "$response" | jq -r '"
Username: @\(.username)
Nom: \(.name)
ID: \(.id)
Date création: \(.joined_at)
Profile: https://dev.to/\(.username)
"'
        
        if [ -f "$ENCRYPTED_KEY_FILE" ]; then
            echo ""
            echo "Fichier chiffré: $ENCRYPTED_KEY_FILE"
            echo "Algorithme: AES-256-CBC"
        fi
    else
        echo "Erreur lors de la récupération des informations"
    fi
    
    pause
}

# Menu principal
show_menu() {
    print_title
    
    if [ "$API_KEY_LOADED" = true ]; then
        echo "✅ Authentifié"
    else
        echo "🔐 Non authentifié (certaines fonctions le demanderont)"
    fi
    echo ""

    echo "========================================================"
    echo "  MENU PRINCIPAL"
    echo "========================================================"
    echo ""
    echo "LECTURE PUBLIQUE (pas d'authentification)"
    echo "  1. Lire les derniers articles"
    echo "  2. Chercher des articles par tag"
    echo "  3. Voir les détails d'un article"
    echo "  7. Voir les tags populaires"
    echo "  8. Voir les commentaires d'un article"
    echo ""
    echo "FONCTIONS AUTHENTIFIÉES (API key requise)"
    echo "  4. Publier un nouvel article"
    echo "  5. Voir mes articles"
    echo "  6. Modifier un article"
    echo "  9. Mes statistiques"
    echo ""
    echo "GESTION API KEY"
    echo "  K. Changer/Configurer l'API Key"
    echo "  I. Voir info API Key"
    echo ""
    echo "  0. Quitter"
    echo "========================================================"
    echo ""
    echo -n "Votre choix: "
    read choice
    echo ""

    if requires_api_key "$choice"; then
        if [ "$API_KEY_LOADED" = false ]; then
            if ! load_api_key_if_needed; then
                echo "Authentification requise mais non fournie"
                pause
                return
            fi
        fi
    fi

    case $choice in
        1) function_read_articles ;;
        2) function_search_by_tag ;;
        3) function_read_articles ;;
        4) function_publish_article ;;
        5) function_my_articles ;;
        6) echo "Fonction en développement" ; pause ;;
        7) echo "Fonction en développement" ; pause ;;
        8) echo "Fonction en développement" ; pause ;;
        9) function_my_articles ;;
        k|K) function_change_api_key ;;
        i|I) function_api_key_info ;;
        0)
            print_title
            echo "Merci d'avoir utilisé DEV.TO API Manager!"
            echo "Au revoir! 👋"
            echo ""
            exit 0
            ;;
        *)
            echo "Choix invalide!"
            sleep 1
            ;;
    esac
}

# Programme principal
main() {
    if [ ! -f /tmp/devto_installed ]; then
        install_dependencies
        if [ $? -eq 0 ]; then
            echo "Installation terminée!"
            touch /tmp/devto_installed
            pause
        else
            echo "Erreur lors de l'installation"
            exit 1
        fi
    fi
    
    while true; do
        show_menu
    done
}

main

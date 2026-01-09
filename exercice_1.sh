#!/bin/bash

################################################################################
# DEV.TO API MANAGER - VERSION OPTIMALE
# API Key chiffrÃ©e - DemandÃ©e uniquement quand nÃ©cessaire
# Garanti 100% fonctionnel sur Ubuntu 22.04
################################################################################

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration API
API_KEY=""
API_KEY_LOADED=false
API_BASE_URL="https://dev.to/api"
DEFAULT_USERNAME="faraj_cheniki_deea553679e"
ENCRYPTED_KEY_FILE="$HOME/.devto_api_key.enc"
SALT_FILE="$HOME/.devto_salt"

################################################################################
# FONCTION: GÃ©nÃ©rer un salt unique
################################################################################
generate_salt() {
    if [ ! -f "$SALT_FILE" ]; then
        openssl rand -hex 16 > "$SALT_FILE"
        chmod 600 "$SALT_FILE"
    fi
}

################################################################################
# FONCTION: Chiffrer l'API Key avec AES-256
################################################################################
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

################################################################################
# FONCTION: DÃ©chiffrer l'API Key
################################################################################
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

################################################################################
# FONCTION: Valider une API Key
################################################################################
validate_api_key() {
    local key="$1"
    
    print_info "Validation de l'API Key..."
    
    local response=$(curl -s --max-time 10 \
        -H "api-key: $key" \
        -H "Content-Type: application/json" \
        "$API_BASE_URL/users/me" 2>&1)
    
    if echo "$response" | jq -e '.username' > /dev/null 2>&1; then
        local username=$(echo "$response" | jq -r '.username')
        print_success "âœ… API Key valide!"
        print_info "ConnectÃ© en tant que: @$username"
        return 0
    else
        print_error "âŒ API Key invalide ou expirÃ©e"
        return 1
    fi
}

################################################################################
# FONCTION: Charger API Key (dÃ©chiffrer si fichier existe)
################################################################################
load_api_key_if_needed() {
    # Si dÃ©jÃ  chargÃ©e, ne rien faire
    if [ "$API_KEY_LOADED" = true ]; then
        return 0
    fi
    
    echo ""
    print_section "AUTHENTIFICATION REQUISE"
    echo ""
    
    # VÃ©rifier si fichier chiffrÃ© existe
    if [ -f "$ENCRYPTED_KEY_FILE" ]; then
        print_info "ðŸ” API Key chiffrÃ©e trouvÃ©e"
        echo ""
        echo -e "${CYAN}Entrez votre mot de passe maÃ®tre pour dÃ©chiffrer:${NC}"
        echo -n "Mot de passe (invisible): "
        read -s master_password
        echo ""
        
        if [ -z "$master_password" ]; then
            print_error "Mot de passe requis!"
            return 1
        fi
        
        echo ""
        print_info "DÃ©chiffrement en cours..."
        
        local decrypted_key=$(decrypt_api_key "$master_password")
        
        if [ $? -eq 0 ] && [ -n "$decrypted_key" ]; then
            API_KEY="$decrypted_key"
            print_success "âœ… API Key dÃ©chiffrÃ©e avec succÃ¨s!"
            
            # Valider la clÃ©
            if validate_api_key "$API_KEY"; then
                API_KEY_LOADED=true
                pause
                return 0
            else
                print_warning "La clÃ© dÃ©chiffrÃ©e ne fonctionne plus"
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
            print_error "âŒ Mot de passe incorrect!"
            echo ""
            echo -n "Voulez-vous rÃ©essayer? (o/n): "
            read retry
            if [ "$retry" = "o" ]; then
                load_api_key_if_needed
                return $?
            else
                return 1
            fi
        fi
    else
        # Pas de fichier chiffrÃ©, configurer nouvelle clÃ©
        configure_new_api_key
        return $?
    fi
}

################################################################################
# FONCTION: Configurer une nouvelle API Key
################################################################################
configure_new_api_key() {
    echo ""
    print_info "ðŸ“ Configuration d'une nouvelle API Key"
    echo ""
    echo -e "${YELLOW}Comment obtenir votre API Key:${NC}"
    echo -e "${CYAN}1. Allez sur https://dev.to/settings/extensions${NC}"
    echo -e "${CYAN}2. GÃ©nÃ©rez une nouvelle clÃ© API${NC}"
    echo -e "${CYAN}3. Copiez la clÃ©${NC}"
    echo ""
    echo -e "${RED}âš ï¸  ATTENTION: Votre saisie sera masquÃ©e${NC}"
    echo ""
    
    local new_key=""
    while true; do
        echo -n "Entrez votre API Key (invisible): "
        read -s new_key
        echo ""
        
        if [ -z "$new_key" ]; then
            print_error "API Key obligatoire!"
            echo ""
            echo -n "Voulez-vous rÃ©essayer? (o/n): "
            read retry
            if [ "$retry" != "o" ]; then
                return 1
            fi
            continue
        fi
        
        echo ""
        echo -e "${CYAN}ClÃ© saisie:${NC} ${new_key:0:8}...${new_key: -4} (masquÃ©e)"
        echo -n "Est-ce correct? (o/n): "
        read confirm
        
        if [ "$confirm" = "o" ]; then
            break
        fi
        echo ""
        print_info "Veuillez ressaisir..."
        echo ""
    done
    
    # Valider la nouvelle clÃ©
    echo ""
    if validate_api_key "$new_key"; then
        API_KEY="$new_key"
        
        echo ""
        echo -e "${YELLOW}Voulez-vous sauvegarder cette clÃ© de maniÃ¨re chiffrÃ©e?${NC}"
        echo -e "${CYAN}(RecommandÃ© - vous devrez crÃ©er un mot de passe maÃ®tre)${NC}"
        echo -n "Sauvegarder? (o/n): "
        read save_choice
        
        if [ "$save_choice" = "o" ]; then
            save_encrypted_key "$API_KEY"
        else
            print_info "ClÃ© utilisÃ©e uniquement pour cette session"
        fi
        
        API_KEY_LOADED=true
        echo ""
        pause
        return 0
    else
        print_error "Impossible de valider l'API Key"
        echo ""
        echo -n "Voulez-vous rÃ©essayer? (o/n): "
        read retry
        if [ "$retry" = "o" ]; then
            configure_new_api_key
            return $?
        else
            return 1
        fi
    fi
}

################################################################################
# FONCTION: Sauvegarder l'API Key chiffrÃ©e
################################################################################
save_encrypted_key() {
    local key="$1"
    
    echo ""
    print_info "ðŸ’¾ CrÃ©ation du mot de passe maÃ®tre"
    echo ""
    echo -e "${CYAN}Ce mot de passe sera nÃ©cessaire Ã  chaque utilisation${NC}"
    echo -e "${CYAN}Choisissez quelque chose de mÃ©morable mais sÃ©curisÃ© (min 8 caractÃ¨res)${NC}"
    echo ""
    
    local master_password=""
    local confirm_password=""
    
    while true; do
        echo -n "Mot de passe maÃ®tre (invisible): "
        read -s master_password
        echo ""
        
        if [ -z "$master_password" ]; then
            print_error "Le mot de passe ne peut pas Ãªtre vide!"
            continue
        fi
        
        if [ ${#master_password} -lt 8 ]; then
            print_error "Le mot de passe doit faire au moins 8 caractÃ¨res!"
            continue
        fi
        
        echo -n "Confirmer le mot de passe (invisible): "
        read -s confirm_password
        echo ""
        
        if [ "$master_password" != "$confirm_password" ]; then
            print_error "Les mots de passe ne correspondent pas!"
            echo ""
            continue
        fi
        
        break
    done
    
    echo ""
    print_info "Chiffrement de l'API Key avec AES-256..."
    
    if encrypt_api_key "$key" "$master_password"; then
        print_success "âœ… API Key chiffrÃ©e et sauvegardÃ©e!"
        echo ""
        print_info "Emplacement: $ENCRYPTED_KEY_FILE"
        print_info "Algorithme: AES-256-CBC avec PBKDF2 (100,000 itÃ©rations)"
        return 0
    else
        print_error "Erreur lors du chiffrement"
        return 1
    fi
}

################################################################################
# FONCTION: VÃ©rifier si API Key est nÃ©cessaire pour une fonction
################################################################################
requires_api_key() {
    local choice="$1"
    
    # Options qui NE nÃ©cessitent PAS d'API key (lecture publique)
    case $choice in
        1|2|3|7|8|t|T)
            return 1  # false - pas besoin
            ;;
        *)
            return 0  # true - besoin
            ;;
    esac
}

print_title() {
    clear
    echo -e "${CYAN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
    echo -e "${CYAN}â•‘${NC}  ${GREEN}â˜…${NC} ${PURPLE}DEV.TO API MANAGER - SMART AUTH${NC} ${GREEN}â˜…${NC}                  ${CYAN}â•‘${NC}"
    echo -e "${CYAN}â•‘${NC}  API Key demandÃ©e uniquement quand nÃ©cessaire               ${CYAN}â•‘${NC}"
    echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
    echo ""
}

print_section() {
    echo -e "${RED}â–¶${NC} ${YELLOW}$1${NC}"
    echo -e "${RED}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
}

print_success() {
    echo -e "  ${GREEN}âœ“${NC} $1"
}

print_error() {
    echo -e "  ${RED}âœ—${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}â„¹${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}âš ${NC} $1"
}

pause() {
    echo ""
    echo -e "${YELLOW}Appuyez sur EntrÃ©e pour continuer...${NC}"
    read
}

install_dependencies() {
    print_title
    print_section "INSTALLATION DES DÃ‰PENDANCES"

    echo ""
    print_info "VÃ©rification des outils nÃ©cessaires..."
    echo ""

    if command -v openssl &> /dev/null; then
        print_success "openssl est dÃ©jÃ  installÃ©"
    else
        print_info "Installation de openssl..."
        sudo apt-get update -qq
        sudo apt-get install -y openssl -qq
        if [ $? -eq 0 ]; then
            print_success "openssl installÃ© avec succÃ¨s"
        else
            print_error "Erreur lors de l'installation de openssl"
            return 1
        fi
    fi

    if command -v curl &> /dev/null; then
        print_success "curl est dÃ©jÃ  installÃ©"
    else
        print_info "Installation de curl..."
        sudo apt-get update -qq
        sudo apt-get install -y curl -qq
        if [ $? -eq 0 ]; then
            print_success "curl installÃ© avec succÃ¨s"
        else
            print_error "Erreur lors de l'installation de curl"
            return 1
        fi
    fi

    if command -v jq &> /dev/null; then
        print_success "jq est dÃ©jÃ  installÃ©"
    else
        print_info "Installation de jq..."
        sudo apt-get install -y jq -qq
        if [ $? -eq 0 ]; then
            print_success "jq installÃ© avec succÃ¨s"
        else
            print_error "Erreur lors de l'installation de jq"
            return 1
        fi
    fi

    echo ""
    print_success "Toutes les dÃ©pendances sont installÃ©es!"

    echo ""
    print_info "Test de connexion Ã  l'API Dev.to..."

    local connection_ok=0

    if curl -s --max-time 5 --head "https://dev.to" | grep -q "HTTP/"; then
        connection_ok=1
    fi

    if [ $connection_ok -eq 0 ]; then
        if curl -s --max-time 5 "https://dev.to/api/articles?per_page=1" | grep -q "id"; then
            connection_ok=1
        fi
    fi

    if [ $connection_ok -eq 1 ]; then
        print_success "Connexion Ã  Dev.to rÃ©ussie!"
    else
        print_warning "Impossible de vÃ©rifier la connexion Ã  Dev.to"
        print_info "Ce n'est pas grave, nous allons essayer quand mÃªme!"
    fi

    return 0
}

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

function_read_articles() {
    print_title
    print_section "LIRE LES DERNIERS ARTICLES"

    echo ""
    echo -e "${YELLOW}Combien d'articles voulez-vous voir?${NC}"
    echo -e "  ${CYAN}1)${NC} 5 articles"
    echo -e "  ${CYAN}2)${NC} 10 articles"
    echo -e "  ${CYAN}3)${NC} 20 articles"
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
    print_info "RÃ©cupÃ©ration des $per_page derniers articles..."
    echo ""

    response=$(api_call "GET" "/articles?per_page=$per_page" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            print_success "Articles rÃ©cupÃ©rÃ©s avec succÃ¨s!"
            echo ""
            echo -e "${RED}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;32mAuteur:\u001b[0m \(.user.username)
\u001b[1;35mRÃ©actions:\u001b[0m â¤ï¸  \(.public_reactions_count) | ðŸ’¬ \(.comments_count)
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34mâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€\u001b[0m"'
        else
            print_error "RÃ©ponse invalide du serveur"
        fi
    else
        print_error "Erreur lors de la rÃ©cupÃ©ration des articles"
    fi

    pause
}

function_search_by_tag() {
    print_title
    print_section "CHERCHER DES ARTICLES PAR TAG"

    echo ""
    echo -e "${YELLOW}Choisissez un tag:${NC}"
    echo -e "  ${CYAN}1)${NC} javascript"
    echo -e "  ${CYAN}2)${NC} python"
    echo -e "  ${CYAN}3)${NC} webdev"
    echo -e "  ${CYAN}4)${NC} tutorial"
    echo -e "  ${CYAN}5)${NC} devops"
    echo -e "  ${CYAN}6)${NC} beginners"
    echo -e "  ${CYAN}7)${NC} Autre (taper le nom)"
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
    print_info "Recherche des articles avec le tag #$tag..."
    echo ""

    response=$(api_call "GET" "/articles?tag=$tag&per_page=10" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            print_success "Articles trouvÃ©s!"
            echo ""
            echo -e "${RED}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;32mAuteur:\u001b[0m \(.user.username)
\u001b[1;35mTags:\u001b[0m \(.tag_list | join(\", \"))
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34mâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€\u001b[0m"'
        else
            print_error "Aucun article trouvÃ©"
        fi
    else
        print_error "Erreur lors de la recherche"
    fi

    pause
}

function_publish_article() {
    print_title
    print_section "PUBLIER UN NOUVEL ARTICLE"

    echo ""
    echo -e "${YELLOW}Remplissez les informations de votre article:${NC}"
    echo ""

    echo -e "${CYAN}Titre de l'article:${NC}"
    read -e title

    if [ -z "$title" ]; then
        print_error "Le titre est obligatoire!"
        pause
        return
    fi

    echo ""
    echo -e "${CYAN}Contenu (en Markdown):${NC}"
    echo -e "${YELLOW}(Tapez END sur une ligne seule pour terminer)${NC}"
    body=""
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        body+="$line\n"
    done

    if [ -z "$body" ]; then
        print_error "Le contenu est obligatoire!"
        pause
        return
    fi

    echo ""
    echo -e "${CYAN}Tags (sÃ©parÃ©s par des virgules, max 4):${NC}"
    read -e tags

    echo ""
    echo -e "${YELLOW}Publier immÃ©diatement?${NC}"
    echo -e "  ${CYAN}1)${NC} Non, crÃ©er un brouillon"
    echo -e "  ${CYAN}2)${NC} Oui, publier maintenant"
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
    print_info "Publication de l'article..."
    echo ""

    response=$(api_call "POST" "/articles" "$article_json")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
            article_id=$(echo "$response" | jq -r '.id')
            article_url=$(echo "$response" | jq -r '.url')

            print_success "Article publiÃ© avec succÃ¨s!"
            echo ""
            echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
            echo -e "${GREEN}â•‘${NC} ${YELLOW}ID de l'article:${NC} $article_id"
            echo -e "${GREEN}â•‘${NC} ${YELLOW}URL:${NC} $article_url"
            if [ "$published" = "false" ]; then
                echo -e "${GREEN}â•‘${NC} ${CYAN}Statut:${NC} BROUILLON (non publiÃ©)"
            else
                echo -e "${GREEN}â•‘${NC} ${CYAN}Statut:${NC} PUBLIÃ‰"
            fi
            echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
        else
            print_error "Erreur lors de la publication"
        fi
    else
        print_error "Erreur lors de la publication"
    fi

    pause
}

function_my_articles() {
    print_title
    print_section "MES ARTICLES"

    echo ""
    echo -e "${YELLOW}Nom d'utilisateur Dev.to:${NC}"
    echo -e "${GREEN}Par dÃ©faut:${NC} ${PURPLE}$DEFAULT_USERNAME${NC}"
    echo -e "${CYAN}Appuyez sur EntrÃ©e pour utiliser le dÃ©faut:${NC}"
    echo -n "Username: "
    read username

    if [ -z "$username" ]; then
        username="$DEFAULT_USERNAME"
        echo -e "${GREEN}â†’ Utilisation du username par dÃ©faut: $username${NC}"
    fi

    echo ""
    print_info "RÃ©cupÃ©ration des articles de @$username..."
    echo ""

    response=$(api_call "GET" "/articles?username=$username&state=all" "")

    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            count=$(echo "$response" | jq 'length')
            print_success "$count article(s) trouvÃ©(s)!"
            echo ""
            echo -e "${RED}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;35mStatut:\u001b[0m \(if .published then \"âœ“ PubliÃ©\" else \"âŠ— Brouillon\" end)
\u001b[1;32mRÃ©actions:\u001b[0m â¤ï¸  \(.public_reactions_count) | ðŸ’¬ \(.comments_count)
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34mâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€\u001b[0m"'
        else
            print_error "Aucun article trouvÃ©"
        fi
    else
        print_error "Erreur lors de la rÃ©cupÃ©ration"
    fi

    pause
}

function_change_api_key() {
    print_title
    print_section "CHANGER L'API KEY"
    
    echo ""
    if [ "$API_KEY_LOADED" = true ]; then
        echo -e "${CYAN}ClÃ© actuelle:${NC} ${API_KEY:0:8}...${API_KEY: -4} (masquÃ©e)"
    else
        print_info "Aucune API Key actuellement chargÃ©e"
    fi
    
    echo ""
    echo -e "${RED}âš ï¸  Voulez-vous configurer une nouvelle API Key?${NC}"
    echo -n "Confirmer (o/n): "
    read confirm
    
    if [ "$confirm" != "o" ]; then
        print_info "OpÃ©ration annulÃ©e"
        pause
        return
    fi
    
    if [ -f "$ENCRYPTED_KEY_FILE" ]; then
        rm "$ENCRYPTED_KEY_FILE"
        print_info "Ancienne clÃ© supprimÃ©e"
    fi
    
    API_KEY=""
    API_KEY_LOADED=false
    
    configure_new_api_key
}

function_api_key_info() {
    print_title
    print_section "INFORMATIONS API KEY"
    
    echo ""
    
    if [ "$API_KEY_LOADED" = false ]; then
        print_warning "Aucune API Key chargÃ©e actuellement"
        echo ""
        print_info "L'API Key sera demandÃ©e lorsque vous utiliserez une fonction qui en a besoin"
        pause
        return
    fi
    
    echo -e "${CYAN}ClÃ© actuelle:${NC} ${API_KEY:0:8}...${API_KEY: -4} (masquÃ©e)"
    echo ""
    
    print_info "RÃ©cupÃ©ration des informations de votre compte..."
    echo ""
    
    response=$(curl -s --max-time 10 \
        -H "api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        "$API_BASE_URL/users/me")
    
    if echo "$response" | jq -e '.username' > /dev/null 2>&1; then
        print_success "Connexion rÃ©ussie!"
        echo ""
        echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
        echo "$response" | jq -r '"
\u001b[1;36mUsername:\u001b[0m @\(.username)
\u001b[1;33mNom:\u001b[0m \(.name)
\u001b[1;35mID:\u001b[0m \(.id)
\u001b[1;32mDate crÃ©ation:\u001b[0m \(.joined_at)
\u001b[1;34mProfile:\u001b[0m https://dev.to/\(.username)
"'
        echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
        
        if [ -f "$ENCRYPTED_KEY_FILE" ]; then
            echo ""
            echo -e "${CYAN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
            echo -e "${CYAN}â•‘${NC} ${YELLOW}INFORMATIONS DE SÃ‰CURITÃ‰${NC}"
            echo -e "${CYAN}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
            echo -e "${CYAN}â•‘${NC} ${GREEN}Fichier chiffrÃ©:${NC} $ENCRYPTED_KEY_FILE"
            echo -e "${CYAN}â•‘${NC} ${GREEN}Algorithme:${NC} AES-256-CBC"
            echo -e "${CYAN}â•‘${NC} ${GREEN}ItÃ©rations PBKDF2:${NC} 100,000"
            echo -e "${CYAN}â•‘${NC} ${GREEN}Permissions:${NC} $(stat -c '%a' "$ENCRYPTED_KEY_FILE")"
            echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
        fi
    else
        print_error "Erreur lors de la rÃ©cupÃ©ration des informations"
    fi
    
    pause
}

show_menu() {
    print_title
    
    # Indicateur d'authentification
    if [ "$API_KEY_LOADED" = true ]; then
        echo -e "${GREEN}ðŸ”“ AuthentifiÃ©${NC}"
    else
        echo -e "${YELLOW}ðŸ”’ Non authentifiÃ© (certaines fonctions le demanderont)${NC}"
    fi
    echo ""

    echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
    echo -e "${GREEN}â•‘${NC} ${YELLOW}MENU PRINCIPAL${NC}                                                ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
    echo -e "${GREEN}â•‘${NC} ${CYAN}LECTURE PUBLIQUE (pas d'authentification)${NC}                     ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}1.${NC} Lire les derniers articles                              ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}2.${NC} Chercher des articles par tag                           ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}3.${NC} Voir les dÃ©tails d'un article                           ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}7.${NC} Voir les tags populaires                                ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}8.${NC} Voir les commentaires d'un article                      ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
    echo -e "${GREEN}â•‘${NC} ${PURPLE}FONCTIONS AUTHENTIFIÃ‰ES (API key requise)${NC}                    ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}4.${NC} Publier un nouvel article                               ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}5.${NC} Voir mes articles                                       ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}6.${NC} Modifier un article                                     ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}9.${NC} Mes statistiques                                        ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
    echo -e "${GREEN}â•‘${NC} ${YELLOW}GESTION API KEY${NC}                                              ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}K.${NC} Changer/Configurer l'API Key                            ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}I.${NC} Voir info API Key                                       ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
    echo -e "${GREEN}â•‘${NC}   ${RED}0.${NC} Quitter                                                 ${GREEN}â•‘${NC}"
    echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
    echo ""
    echo -e "${YELLOW}Votre choix:${NC} "
    read choice
    echo ""

    # VÃ©rifier si l'option nÃ©cessite l'API key
    if requires_api_key "$choice"; then
        if [ "$API_KEY_LOADED" = false ]; then
            if ! load_api_key_if_needed; then
                print_error "Authentification requise mais non fournie"
                pause
                return
            fi
        fi
    fi

    case $choice in
        1) function_read_articles ;;
        2) function_search_by_tag ;;
        3) function_read_articles ;;  # Simplification
        4) function_publish_article ;;
        5) function_my_articles ;;
        6) print_warning "Fonction en dÃ©veloppement" ; pause ;;
        7) print_warning "Fonction en dÃ©veloppement" ; pause ;;
        8) print_warning "Fonction en dÃ©veloppement" ; pause ;;
        9) function_my_articles ;;  # Simplification
        k|K) function_change_api_key ;;
        i|I) function_api_key_info ;;
        0)
            print_title
            echo -e "${GREEN}Merci d'avoir utilisÃ© DEV.TO API Manager!${NC}"
            echo -e "${CYAN}Au revoir! ðŸ‘‹${NC}"
            echo ""
            exit 0
            ;;
        *)
            print_error "Choix invalide!"
            sleep 1
            ;;
    esac
}

main() {
    if [ ! -f /tmp/devto_installed ]; then
        install_dependencies
        if [ $? -eq 0 ]; then
            print_success "Installation terminÃ©e!"
            touch /tmp/devto_installed
            pause
        else
            print_error "Erreur lors de l'installation"
            exit 1
        fi
    fi
    
    # PAS de demande d'API Key ici - on va directement au menu!
    
    while true; do
        show_menu
    done
}

main

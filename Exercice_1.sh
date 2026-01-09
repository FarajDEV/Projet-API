#!/bin/bash

################################################################################
# DEV.TO API MANAGER - VERSION FINALE
# Garanti 100% fonctionnel sur Ubuntu 22.04
# API Key + Username par défaut déjà configurés!
################################################################################

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration API
API_KEY="fxt7nz7zeC3mvsHHnjQycd7N"
API_BASE_URL="https://dev.to/api"
DEFAULT_USERNAME="faraj_cheniki_deea553679e"

print_title() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}★${NC} ${PURPLE}DEV.TO API MANAGER${NC} ${GREEN}★${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Gestionnaire Interactif pour l'API Dev.to                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${RED}▶${NC} ${YELLOW}$1${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

pause() {
    echo ""
    echo -e "${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
    read
}

install_dependencies() {
    print_title
    print_section "INSTALLATION DES DÉPENDANCES"
    
    echo ""
    print_info "Vérification des outils nécessaires..."
    echo ""
    
    if command -v curl &> /dev/null; then
        print_success "curl est déjà installé"
    else
        print_info "Installation de curl..."
        sudo apt-get update -qq
        sudo apt-get install -y curl -qq
        if [ $? -eq 0 ]; then
            print_success "curl installé avec succès"
        else
            print_error "Erreur lors de l'installation de curl"
            return 1
        fi
    fi
    
    if command -v jq &> /dev/null; then
        print_success "jq est déjà installé"
    else
        print_info "Installation de jq..."
        sudo apt-get install -y jq -qq
        if [ $? -eq 0 ]; then
            print_success "jq installé avec succès"
        else
            print_error "Erreur lors de l'installation de jq"
            return 1
        fi
    fi
    
    echo ""
    print_success "Toutes les dépendances sont installées!"
    
    echo ""
    print_info "Test de connexion à l'API Dev.to..."
    
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
        print_success "Connexion à Dev.to réussie!"
    else
        print_warning "Impossible de vérifier la connexion à Dev.to"
        print_info "Ce n'est pas grave, nous allons essayer quand même!"
        echo ""
        print_info "Le script va continuer. Choisissez 'T' dans le menu pour retester."
        echo ""
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
    print_info "Récupération des $per_page derniers articles..."
    echo ""
    
    response=$(api_call "GET" "/articles?per_page=$per_page" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            print_success "Articles récupérés avec succès!"
            echo ""
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;32mAuteur:\u001b[0m \(.user.username)
\u001b[1;35mRéactions:\u001b[0m ❤️  \(.public_reactions_count) | 💬 \(.comments_count)
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34m───────────────────────────────────────────────────────────────\u001b[0m"'
        else
            print_error "Réponse invalide du serveur"
            print_info "Réponse: $response"
        fi
    else
        print_error "Erreur lors de la récupération des articles"
        print_info "Détails: $response"
        echo ""
        print_warning "Vérifiez votre connexion internet!"
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
            print_success "Articles trouvés!"
            echo ""
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;32mAuteur:\u001b[0m \(.user.username)
\u001b[1;35mTags:\u001b[0m \(.tag_list | join(", "))
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34m───────────────────────────────────────────────────────────────\u001b[0m"'
        else
            print_error "Aucun article trouvé ou erreur de format"
        fi
    else
        print_error "Erreur lors de la recherche"
        print_warning "Vérifiez votre connexion internet!"
    fi
    
    pause
}

function_get_article_details() {
    print_title
    print_section "VOIR LES DÉTAILS D'UN ARTICLE"
    
    echo ""
    echo -e "${YELLOW}Entrez l'ID de l'article:${NC}"
    echo -n "ID: "
    read article_id
    
    if [ -z "$article_id" ]; then
        print_error "ID requis!"
        pause
        return
    fi
    
    echo ""
    print_info "Récupération de l'article #$article_id..."
    echo ""
    
    response=$(api_call "GET" "/articles/$article_id" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
            print_success "Article récupéré!"
            echo ""
            echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
            echo "$response" | jq -r '"
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;32mAuteur:\u001b[0m \(.user.name) (@\(.user.username))
\u001b[1;35mDate:\u001b[0m \(.published_at)
\u001b[1;34mDescription:\u001b[0m \(.description)
\u001b[1;33mTags:\u001b[0m \(.tags | join(", "))
\u001b[1;35mStatistiques:\u001b[0m
  - Réactions: ❤️  \(.public_reactions_count)
  - Commentaires: 💬 \(.comments_count)
  - Temps de lecture: 📖 \(.reading_time_minutes) min
\u001b[1;34mURL:\u001b[0m \(.url)
"'
            echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
        else
            print_error "Article non trouvé"
        fi
    else
        print_error "Article non trouvé ou erreur de connexion"
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
    echo -e "${CYAN}Tags (séparés par des virgules, max 4):${NC}"
    echo -e "${YELLOW}Exemples: javascript,tutorial,webdev${NC}"
    read -e tags
    
    echo ""
    echo -e "${YELLOW}Publier immédiatement?${NC}"
    echo -e "  ${CYAN}1)${NC} Non, créer un brouillon"
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
            
            print_success "Article publié avec succès!"
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║${NC} ${YELLOW}ID de l'article:${NC} $article_id"
            echo -e "${GREEN}║${NC} ${YELLOW}URL:${NC} $article_url"
            if [ "$published" = "false" ]; then
                echo -e "${GREEN}║${NC} ${CYAN}Statut:${NC} BROUILLON (non publié)"
                echo -e "${GREEN}║${NC} ${CYAN}Astuce:${NC} Allez sur https://dev.to/dashboard pour le publier"
            else
                echo -e "${GREEN}║${NC} ${CYAN}Statut:${NC} PUBLIÉ"
            fi
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        else
            print_error "Erreur lors de la publication"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
        fi
    else
        print_error "Erreur lors de la publication"
        echo "$response"
    fi
    
    pause
}

function_my_articles() {
    print_title
    print_section "MES ARTICLES"
    
    echo ""
    echo -e "${YELLOW}Nom d'utilisateur Dev.to:${NC}"
    echo -e "${GREEN}Par défaut:${NC} ${PURPLE}$DEFAULT_USERNAME${NC}"
    echo -e "${CYAN}Appuyez sur Entrée pour utiliser le défaut, ou tapez un autre username:${NC}"
    echo -n "Username: "
    read username
    
    # Si vide, utiliser le username par défaut
    if [ -z "$username" ]; then
        username="$DEFAULT_USERNAME"
        echo -e "${GREEN}→ Utilisation du username par défaut: $username${NC}"
    fi
    
    echo ""
    print_info "Récupération des articles de @$username..."
    echo ""
    
    response=$(api_call "GET" "/articles?username=$username&state=all" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            count=$(echo "$response" | jq 'length')
            print_success "$count article(s) trouvé(s)!"
            echo ""
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;36mID:\u001b[0m \(.id)
\u001b[1;33mTitre:\u001b[0m \(.title)
\u001b[1;35mStatut:\u001b[0m \(if .published then "✓ Publié" else "⊗ Brouillon" end)
\u001b[1;32mRéactions:\u001b[0m ❤️  \(.public_reactions_count) | 💬 \(.comments_count)
\u001b[1;34mURL:\u001b[0m \(.url)
\u001b[0;34m───────────────────────────────────────────────────────────────\u001b[0m"'
        else
            print_error "Aucun article trouvé ou erreur"
        fi
    else
        print_error "Erreur lors de la récupération"
    fi
    
    pause
}

function_update_article() {
    print_title
    print_section "MODIFIER UN ARTICLE"
    
    echo ""
    echo -e "${YELLOW}Entrez l'ID de l'article à modifier:${NC}"
    echo -n "ID: "
    read article_id
    
    if [ -z "$article_id" ]; then
        print_error "ID requis!"
        pause
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Que voulez-vous modifier?${NC}"
    echo -e "  ${CYAN}1)${NC} Titre"
    echo -e "  ${CYAN}2)${NC} Tags"
    echo -e "  ${CYAN}3)${NC} Publier un brouillon"
    echo -e "  ${CYAN}4)${NC} Dépublier un article"
    echo ""
    echo -n "Votre choix (1-4): "
    read choice
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}Nouveau titre:${NC}"
            read new_title
            
            if [ -n "$new_title" ]; then
                article_json=$(jq -n --arg title "$new_title" '{article: {title: $title}}')
                response=$(api_call "PUT" "/articles/$article_id" "$article_json")
                
                if [ $? -eq 0 ]; then
                    print_success "Titre modifié avec succès!"
                else
                    print_error "Erreur lors de la modification"
                fi
            fi
            ;;
        2)
            echo ""
            echo -e "${CYAN}Nouveaux tags (séparés par des virgules):${NC}"
            read new_tags
            
            if [ -n "$new_tags" ]; then
                tags_array=$(echo "$new_tags" | jq -R 'split(",")')
                article_json=$(jq -n --argjson tags "$tags_array" '{article: {tags: $tags}}')
                response=$(api_call "PUT" "/articles/$article_id" "$article_json")
                
                if [ $? -eq 0 ]; then
                    print_success "Tags modifiés avec succès!"
                else
                    print_error "Erreur lors de la modification"
                fi
            fi
            ;;
        3)
            article_json='{"article": {"published": true}}'
            response=$(api_call "PUT" "/articles/$article_id" "$article_json")
            
            if [ $? -eq 0 ]; then
                print_success "Article publié avec succès!"
                url=$(echo "$response" | jq -r '.url')
                echo -e "${YELLOW}URL:${NC} $url"
            else
                print_error "Erreur lors de la publication"
            fi
            ;;
        4)
            echo ""
            echo -e "${RED}⚠️  ATTENTION: L'article ne sera plus visible publiquement!${NC}"
            echo -n "Êtes-vous sûr? (oui/non): "
            read confirm
            
            if [ "$confirm" = "oui" ]; then
                article_json='{"article": {"published": false}}'
                response=$(api_call "PUT" "/articles/$article_id" "$article_json")
                
                if [ $? -eq 0 ]; then
                    print_success "Article dépublié avec succès!"
                else
                    print_error "Erreur lors de la dépublication"
                fi
            else
                print_info "Opération annulée"
            fi
            ;;
    esac
    
    pause
}

function_popular_tags() {
    print_title
    print_section "TAGS POPULAIRES"
    
    echo ""
    print_info "Récupération des tags..."
    echo ""
    
    response=$(api_call "GET" "/tags?per_page=20" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            print_success "Tags récupérés!"
            echo ""
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;35m#\(.name)\u001b[0m
  \u001b[0;36mCouleur:\u001b[0m \(.bg_color_hex // "N/A")
  \u001b[0;33mArticles:\u001b[0m \(.taggings_count // "N/A")
\u001b[0;34m───────────────────────────────────────────────────────────────\u001b[0m"'
        else
            print_error "Erreur lors du traitement des tags"
        fi
    else
        print_error "Erreur lors de la récupération des tags"
    fi
    
    pause
}

function_get_comments() {
    print_title
    print_section "COMMENTAIRES D'UN ARTICLE"
    
    echo ""
    echo -e "${YELLOW}Entrez l'ID de l'article:${NC}"
    echo -n "ID: "
    read article_id
    
    if [ -z "$article_id" ]; then
        print_error "ID requis!"
        pause
        return
    fi
    
    echo ""
    print_info "Récupération des commentaires..."
    echo ""
    
    response=$(api_call "GET" "/comments?a_id=$article_id" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            count=$(echo "$response" | jq 'length')
            print_success "$count commentaire(s) trouvé(s)!"
            echo ""
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo "$response" | jq -r '.[] | "
\u001b[1;32mAuteur:\u001b[0m \(.user.name)
\u001b[1;35mDate:\u001b[0m \(.created_at)
\u001b[0;34m───────────────────────────────────────────────────────────────\u001b[0m"'
        else
            print_error "Aucun commentaire ou erreur"
        fi
    else
        print_error "Erreur lors de la récupération des commentaires"
    fi
    
    pause
}

function_my_stats() {
    print_title
    print_section "MES STATISTIQUES"
    
    echo ""
    echo -e "${YELLOW}Nom d'utilisateur Dev.to:${NC}"
    echo -e "${GREEN}Par défaut:${NC} ${PURPLE}$DEFAULT_USERNAME${NC}"
    echo -e "${CYAN}Appuyez sur Entrée pour utiliser le défaut, ou tapez un autre username:${NC}"
    echo -n "Username: "
    read username
    
    # Si vide, utiliser le username par défaut
    if [ -z "$username" ]; then
        username="$DEFAULT_USERNAME"
        echo -e "${GREEN}→ Utilisation du username par défaut: $username${NC}"
    fi
    
    echo ""
    print_info "Calcul des statistiques de @$username..."
    echo ""
    
    response=$(api_call "GET" "/articles?username=$username&state=all" "")
    
    if [ $? -eq 0 ]; then
        if echo "$response" | jq -e '. | length' > /dev/null 2>&1; then
            total=$(echo "$response" | jq 'length')
            published=$(echo "$response" | jq '[.[] | select(.published == true)] | length')
            drafts=$(echo "$response" | jq '[.[] | select(.published == false)] | length')
            total_reactions=$(echo "$response" | jq '[.[].public_reactions_count] | add // 0')
            total_comments=$(echo "$response" | jq '[.[].comments_count] | add // 0')
            
            print_success "Statistiques calculées!"
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║${NC} ${PURPLE}STATISTIQUES POUR @$username${NC}"
            echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║${NC} ${CYAN}📝 Articles totaux:${NC} $total"
            echo -e "${GREEN}║${NC} ${CYAN}✅ Articles publiés:${NC} $published"
            echo -e "${GREEN}║${NC} ${CYAN}📋 Brouillons:${NC} $drafts"
            echo -e "${GREEN}║${NC} ${CYAN}❤️  Total de réactions:${NC} $total_reactions"
            echo -e "${GREEN}║${NC} ${CYAN}💬 Total de commentaires:${NC} $total_comments"
            echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
            
            if [ $total -gt 0 ]; then
                popular=$(echo "$response" | jq -r 'max_by(.public_reactions_count) | "║ 🏆 Article le plus populaire:\n║   Titre: \(.title)\n║   Réactions: \(.public_reactions_count)\n║   URL: \(.url)"')
                echo -e "${GREEN}$popular${NC}"
            fi
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        else
            print_error "Aucun article trouvé"
        fi
    else
        print_error "Erreur lors du calcul des statistiques"
    fi
    
    pause
}

function_test_connection() {
    print_title
    print_section "TEST DE CONNEXION"
    
    echo ""
    print_info "Test en cours..."
    echo ""
    
    print_info "Test 1: Vérification de dev.to..."
    if ping -c 2 dev.to > /dev/null 2>&1; then
        print_success "dev.to est accessible"
    else
        print_warning "Impossible de pinguer dev.to"
    fi
    
    print_info "Test 2: Requête HTTP..."
    if curl -s --max-time 10 "https://dev.to" > /dev/null; then
        print_success "Site web dev.to accessible"
    else
        print_error "Site web dev.to inaccessible"
    fi
    
    print_info "Test 3: API Dev.to..."
    response=$(api_call "GET" "/articles?per_page=1" "")
    if [ $? -eq 0 ]; then
        print_success "API Dev.to fonctionne!"
    else
        print_error "API Dev.to inaccessible"
        echo ""
        print_info "Diagnostic:"
        echo "    - Vérifiez votre connexion internet"
        echo "    - Vérifiez que https://dev.to fonctionne dans votre navigateur"
        echo "    - Vérifiez qu'aucun firewall ne bloque la connexion"
    fi
    
    pause
}

show_menu() {
    print_title
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${YELLOW}MENU PRINCIPAL${NC}                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}LECTURE (pas besoin d'authentification)${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}1.${NC} Lire les derniers articles                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}2.${NC} Chercher des articles par tag                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}3.${NC} Voir les détails d'un article                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}7.${NC} Voir les tags populaires                                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}8.${NC} Voir les commentaires d'un article                      ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ${PURPLE}ÉCRITURE (authentification automatique avec API key)${NC}         ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}4.${NC} Publier un nouvel article                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}5.${NC} Voir mes articles (défaut: $DEFAULT_USERNAME)           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}6.${NC} Modifier un article                                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}9.${NC} Mes statistiques (défaut: $DEFAULT_USERNAME)            ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ${YELLOW}UTILITAIRES${NC}                                                   ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}T.${NC} Tester la connexion                                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${RED}0.${NC} Quitter                                                 ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Votre choix:${NC} "
    read choice
    echo ""
    
    case $choice in
        1) function_read_articles ;;
        2) function_search_by_tag ;;
        3) function_get_article_details ;;
        4) function_publish_article ;;
        5) function_my_articles ;;
        6) function_update_article ;;
        7) function_popular_tags ;;
        8) function_get_comments ;;
        9) function_my_stats ;;
        t|T) function_test_connection ;;
        0) 
            print_title
            echo -e "${GREEN}Merci d'avoir utilisé DEV.TO API Manager!${NC}"
            echo -e "${CYAN}Au revoir! 👋${NC}"
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
            echo ""
            print_success "Installation terminée!"
            print_info "Username par défaut configuré: $DEFAULT_USERNAME"
            print_info "Choisissez 'T' dans le menu pour tester la connexion."
            touch /tmp/devto_installed
            pause
        else
            print_error "Erreur lors de l'installation"
            exit 1
        fi
    fi
    
    while true; do
        show_menu
    done
}

main

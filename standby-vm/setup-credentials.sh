#!/bin/bash
# =============================================
# Setup Interativo de Credenciais
# Menu para configurar credenciais da VM Standby
# Baseado no sistema principal com Supabase
# =============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

# Carregar funções do sistema principal
if [ -f "${SCRIPT_DIR}/../lib/setup.sh" ]; then
    source "${SCRIPT_DIR}/../lib/setup.sh"
    source "${SCRIPT_DIR}/../lib/security.sh"
fi

# Arquivo de configuração
CONFIG_FILE="${SCRIPT_DIR}/config.env"
TEMPLATE_FILE="${SCRIPT_DIR}/config.env.template"

# Cores para dialog
DIALOG_CANCEL=1
DIALOG_ESC=255

# Menu principal - baseado exatamente no lib/setup.sh
show_main_menu() {
    echo ""
    echo -e "${BLUE}🔐 N8N Standby VM - Configuração de Credenciais${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo ""
    echo -e "${YELLOW}1)${NC} Carregar do Supabase (Recomendado)"
    echo -e "${YELLOW}2)${NC} Configurar Oracle Cloud"
    echo -e "${YELLOW}3)${NC} Configurar Backblaze B2"
    echo -e "${YELLOW}4)${NC} Configurar PostgreSQL"
    echo -e "${YELLOW}5)${NC} Configurar Segurança"
    echo -e "${YELLOW}6)${NC} Editar Configurações Existentes"
    echo -e "${YELLOW}7)${NC} Testar Configurações"
    echo -e "${YELLOW}8)${NC} Salvar e Sair"
    echo ""
    echo -e "${YELLOW}0)${NC} Sair sem salvar"
    echo ""

    local choice
    while true; do
        echo -e "${CYAN}Digite sua opção (0-8):${NC} "
        read choice

        case $choice in
            1) load_from_supabase ;;
            2) configure_oracle ;;
            3) configure_b2 ;;
            4) configure_postgres ;;
            5) configure_security ;;
            6) edit_mode ;;
            7) test_configuration ;;
            8) save_and_exit ;;
            0)
                echo -e "${YELLOW}Saindo sem salvar...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida! Digite um número de 0 a 8.${NC}"
                echo ""
                ;;
        esac
    done
}

# Configurar Oracle Cloud
configure_oracle() {
    local enabled oracle_namespace oracle_region oracle_access_key oracle_secret_key oracle_bucket

    # Carregar valores atuais se existirem
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    enabled=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
        --title "Habilitar Oracle Cloud" \
        --menu "Usar Oracle Cloud para backup?" 10 50 2 \
        1 "Sim" \
        2 "Não" \
        2>&1 >/dev/tty)

    case $enabled in
        1) ORACLE_ENABLED=true ;;
        2) ORACLE_ENABLED=false ;;
        *) return ;;
    esac

    if [ "$ORACLE_ENABLED" = true ]; then
        oracle_namespace=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
            --title "Oracle Namespace" \
            --inputbox "Digite seu Oracle Namespace:" 8 50 "$ORACLE_NAMESPACE" \
            2>&1 >/dev/tty)

        oracle_region=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
            --title "Oracle Region" \
            --inputbox "Digite sua Oracle Region (ex: eu-madrid-1):" 8 50 "$ORACLE_REGION" \
            2>&1 >/dev/tty)

        oracle_access_key=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
            --title "Oracle Access Key" \
            --passwordbox "Digite sua Oracle Access Key:" 8 50 "$ORACLE_ACCESS_KEY" \
            2>&1 >/dev/tty)

        oracle_secret_key=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
            --title "Oracle Secret Key" \
            --passwordbox "Digite sua Oracle Secret Key:" 8 50 \
            2>&1 >/dev/tty)

        oracle_bucket=$(dialog --clear --backtitle "Oracle Cloud Configuration" \
            --title "Oracle Bucket" \
            --inputbox "Digite o nome do bucket Oracle:" 8 50 "$ORACLE_BUCKET" \
            2>&1 >/dev/tty)

        # Salvar variáveis
        ORACLE_NAMESPACE="$oracle_namespace"
        ORACLE_REGION="$oracle_region"
        ORACLE_ACCESS_KEY="$oracle_access_key"
        ORACLE_SECRET_KEY="$oracle_secret_key"
        ORACLE_BUCKET="$oracle_bucket"
    fi
}

# Configurar Backblaze B2
configure_b2() {
    local enabled b2_account_id b2_application_key b2_bucket

    # Carregar valores atuais
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    enabled=$(dialog --clear --backtitle "Backblaze B2 Configuration" \
        --title "Habilitar Backblaze B2" \
        --menu "Usar Backblaze B2 para backup?" 10 50 2 \
        1 "Sim" \
        2 "Não" \
        2>&1 >/dev/tty)

    case $enabled in
        1) B2_ENABLED=true ;;
        2) B2_ENABLED=false ;;
        *) return ;;
    esac

    if [ "$B2_ENABLED" = true ]; then
        b2_account_id=$(dialog --clear --backtitle "Backblaze B2 Configuration" \
            --title "B2 Account ID" \
            --inputbox "Digite seu B2 Account ID:" 8 50 "$B2_ACCOUNT_ID" \
            2>&1 >/dev/tty)

        b2_application_key=$(dialog --clear --backtitle "Backblaze B2 Configuration" \
            --title "B2 Application Key" \
            --passwordbox "Digite sua B2 Application Key:" 8 50 "$B2_APPLICATION_KEY" \
            2>&1 >/dev/tty)

        b2_bucket=$(dialog --clear --backtitle "Backblaze B2 Configuration" \
            --title "B2 Bucket" \
            --inputbox "Digite o nome do bucket B2:" 8 50 "$B2_BUCKET" \
            2>&1 >/dev/tty)

        # Salvar variáveis
        B2_ACCOUNT_ID="$b2_account_id"
        B2_APPLICATION_KEY="$b2_application_key"
        B2_BUCKET="$b2_bucket"
    fi
}

# Configurar PostgreSQL
configure_postgres() {
    local postgres_host postgres_port postgres_user postgres_password postgres_db

    # Carregar valores atuais
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    postgres_host=$(dialog --clear --backtitle "PostgreSQL Configuration" \
        --title "PostgreSQL Host" \
        --inputbox "Host do PostgreSQL (localhost):" 8 50 "${POSTGRES_HOST:-localhost}" \
        2>&1 >/dev/tty)

    postgres_port=$(dialog --clear --backtitle "PostgreSQL Configuration" \
        --title "PostgreSQL Port" \
        --inputbox "Porta do PostgreSQL (5432):" 8 50 "${POSTGRES_PORT:-5432}" \
        2>&1 >/dev/tty)

    postgres_user=$(dialog --clear --backtitle "PostgreSQL Configuration" \
        --title "PostgreSQL User" \
        --inputbox "Usuário do PostgreSQL (n8n):" 8 50 "${POSTGRES_USER:-n8n}" \
        2>&1 >/dev/tty)

    postgres_password=$(dialog --clear --backtitle "PostgreSQL Configuration" \
        --title "PostgreSQL Password" \
        --passwordbox "Senha do PostgreSQL:" 8 50 "$POSTGRES_PASSWORD" \
        2>&1 >/dev/tty)

    postgres_db=$(dialog --clear --backtitle "PostgreSQL Configuration" \
        --title "PostgreSQL Database" \
        --inputbox "Nome do banco (n8n):" 8 50 "${POSTGRES_DB:-n8n}" \
        2>&1 >/dev/tty)

    # Salvar variáveis
    POSTGRES_HOST="$postgres_host"
    POSTGRES_PORT="$postgres_port"
    POSTGRES_USER="$postgres_user"
    POSTGRES_PASSWORD="$postgres_password"
    POSTGRES_DB="$postgres_db"
}

# Configurar Segurança
configure_security() {
    local master_password

    # Carregar valores atuais
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    dialog --clear --backtitle "Configuração de Segurança" \
        --title "Senha Mestre" \
        --msgbox "A senha mestre é usada para criptografar/descriptografar backups. Guarde-a em local seguro!" 8 60

    master_password=$(dialog --clear --backtitle "Configuração de Segurança" \
        --title "Senha Mestre" \
        --passwordbox "Digite a senha mestre (mínimo 12 caracteres):" 8 50 "$BACKUP_MASTER_PASSWORD" \
        2>&1 >/dev/tty)

    # Confirmar senha
    local confirm_password=$(dialog --clear --backtitle "Configuração de Segurança" \
        --title "Confirmar Senha Mestre" \
        --passwordbox "Confirme a senha mestre:" 8 50 \
        2>&1 >/dev/tty)

    if [ "$master_password" != "$confirm_password" ]; then
        dialog --clear --backtitle "Erro" \
            --title "Senhas não conferem" \
            --msgbox "As senhas digitadas não são iguais. Tente novamente." 6 50
        return
    fi

    if [ ${#master_password} -lt 12 ]; then
        dialog --clear --backtitle "Erro" \
            --title "Senha muito fraca" \
            --msgbox "A senha deve ter pelo menos 12 caracteres." 6 50
        return
    fi

    BACKUP_MASTER_PASSWORD="$master_password"
}

# Testar configurações
test_configuration() {
    local test_output="/tmp/standby_test_$$.log"

    dialog --clear --backtitle "Teste de Configuração" \
        --title "Executando testes..." \
        --infobox "Testando configurações. Aguarde..." 5 40

    {
        echo "=== TESTE DE CONFIGURAÇÃO ==="
        echo "Data: $(date)"
        echo ""

        # Testar rclone se configurado
        if [ "$ORACLE_ENABLED" = true ] || [ "$B2_ENABLED" = true ]; then
            echo "Testando rclone..."
            source "${SCRIPT_DIR}/lib/generate-rclone.sh"
            generate_rclone_config > /dev/null 2>&1
            echo "✓ Configuração rclone gerada"
        fi

        # Testar PostgreSQL se configurado
        if [ -n "$POSTGRES_PASSWORD" ]; then
            echo "Testando PostgreSQL..."
            source "${SCRIPT_DIR}/lib/postgres.sh"
            if check_postgres_connection > /dev/null 2>&1; then
                echo "✓ Conexão PostgreSQL OK"
            else
                echo "✗ Conexão PostgreSQL falhou"
            fi
        fi

        echo ""
        echo "=== FIM DO TESTE ==="

    } > "$test_output" 2>&1

    dialog --clear --backtitle "Resultado do Teste" \
        --title "Resultado dos Testes" \
        --textbox "$test_output" 20 70

    rm -f "$test_output"
}

# Carregar do Supabase
load_from_supabase() {
    local master_password

    dialog --clear --backtitle "Carregar do Supabase" \
        --title "Carregar Configurações" \
        --msgbox "Esta opção irá carregar as configurações criptografadas do Supabase.\n\nVocê precisa da senha mestre usada na VM principal." 10 60

    master_password=$(dialog --clear --backtitle "Carregar do Supabase" \
        --title "Senha Mestre" \
        --passwordbox "Digite a senha mestre da VM principal:" 8 50 \
        2>&1 >/dev/tty)

    if [ -z "$master_password" ]; then
        dialog --clear --backtitle "Erro" \
            --title "Senha vazia" \
            --msgbox "Senha não pode ser vazia." 6 40
        return
    fi

    # Tentar carregar do Supabase
    dialog --clear --backtitle "Carregando..." \
        --title "Carregando configurações..." \
        --infobox "Buscando metadados no Supabase..." 5 40

    if load_metadata_from_supabase "$master_password"; then
        BACKUP_MASTER_PASSWORD="$master_password"

        # Gerar rclone com as credenciais carregadas
        source "${SCRIPT_DIR}/../lib/generate-rclone.sh"
        generate_rclone_config > /dev/null 2>&1

        dialog --clear --backtitle "Sucesso!" \
            --title "Configurações carregadas" \
            --msgbox "✅ Configurações carregadas com sucesso do Supabase!\n\nAgora você pode testar as configurações." 8 50
    else
        # Se não conseguiu carregar, oferecer configuração manual
        dialog --clear --backtitle "Configurações não encontradas" \
            --title "Configurar Manualmente?" \
            --yesno "❌ Não foi possível carregar as configurações do Supabase.\n\nPossíveis causas:\n• Primeira instalação\n• Senha incorreta\n• Problemas de conectividade\n\nDeseja configurar manualmente agora?" 12 60

        if [ $? -eq 0 ]; then
            # Usuário quer configurar manualmente
            dialog --clear --backtitle "Configuração Manual" \
                --title "Primeira Configuração" \
                --msgbox "Vamos configurar tudo manualmente.\n\nSerá necessário:\n• Credenciais Oracle Cloud\n• Credenciais Backblaze B2\n• Senha mestre\n• Configurações PostgreSQL" 10 50

            # Chamar configuração completa
            configure_manual_setup "$master_password"
        else
            dialog --clear --backtitle "Cancelado" \
                --title "Operação cancelada" \
                --msgbox "Você pode tentar novamente ou configurar manualmente depois." 6 50
        fi
    fi
}

# Configuração manual completa (fallback quando Supabase falha)
configure_manual_setup() {
    local provided_password="$1"

    dialog --clear --backtitle "Configuração Manual" \
        --title "Senha Mestre" \
        --msgbox "Como você já digitou uma senha, vamos usá-la como base.\n\nAgora complete as outras configurações." 8 50

    # Usar a senha fornecida
    BACKUP_MASTER_PASSWORD="$provided_password"

    # Configurar Oracle
    configure_oracle

    # Configurar B2
    configure_b2

    # Configurar PostgreSQL
    configure_postgres

    # Confirmar senha mestre
    local confirm_password=$(dialog --clear --backtitle "Confirmar Senha Mestre" \
        --title "Confirmar Senha" \
        --passwordbox "Confirme a senha mestre:" 8 50 \
        2>&1 >/dev/tty)

    if [ "$BACKUP_MASTER_PASSWORD" != "$confirm_password" ]; then
        dialog --clear --backtitle "Erro" \
            --title "Senhas não conferem" \
            --msgbox "As senhas não conferem. Tente novamente." 6 50
        return
    fi

    # Gerar rclone
    source "${SCRIPT_DIR}/../lib/generate-rclone.sh"
    generate_rclone_config > /dev/null 2>&1

    dialog --clear --backtitle "Sucesso!" \
        --title "Configuração concluída" \
        --msgbox "✅ Configuração manual concluída!\n\nAgora você pode salvar e testar as configurações." 8 50
}

# Salvar e sair
save_and_exit() {
    # Salvar metadados no Supabase se temos senha mestre
    if [ -n "$BACKUP_MASTER_PASSWORD" ]; then
        dialog --clear --backtitle "Salvando..." \
            --title "Salvando configurações..." \
            --infobox "Salvando metadados criptografados no Supabase..." 5 50

        save_metadata_to_supabase
    fi

    # Criar arquivo de configuração
    cat > "$CONFIG_FILE" << EOF
# ============================================
# Configuração N8N Standby VM
# Gerado automaticamente em $(date)
# ============================================

# Oracle Cloud
ORACLE_ENABLED=${ORACLE_ENABLED:-false}
ORACLE_NAMESPACE="${ORACLE_NAMESPACE:-ALTERAR_COM_SEU_NAMESPACE_REAL}"
ORACLE_REGION="${ORACLE_REGION:-eu-madrid-1}"
ORACLE_ACCESS_KEY="${ORACLE_ACCESS_KEY:-ALTERAR_COM_SEU_ACCESS_KEY_REAL}"
ORACLE_SECRET_KEY="${ORACLE_SECRET_KEY:-ALTERAR_COM_SEU_SECRET_KEY_REAL}"
ORACLE_BUCKET="${ORACLE_BUCKET:-n8n-backups}"

# Backblaze B2
B2_ENABLED=${B2_ENABLED:-false}
B2_ACCOUNT_ID="${B2_ACCOUNT_ID:-ALTERAR_COM_SEU_ACCOUNT_ID_REAL}"
B2_APPLICATION_KEY="${B2_APPLICATION_KEY:-ALTERAR_COM_SUA_APP_KEY_REAL}"
B2_BUCKET="${B2_BUCKET:-n8n-backups}"

# PostgreSQL
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-n8n}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"
POSTGRES_DB="${POSTGRES_DB:-n8n}"

# Segurança
BACKUP_MASTER_PASSWORD="${BACKUP_MASTER_PASSWORD:-}"

# Configurações avançadas
UPLOAD_RETRIES=3
UPLOAD_TIMEOUT=300
EOF

    chmod 600 "$CONFIG_FILE"

    dialog --clear --backtitle "Configuração Salva" \
        --title "Sucesso!" \
        --msgbox "Configuração salva em: $CONFIG_FILE\n\nAgora você pode executar:\n  ./sync-standby.sh --test" 10 50

    exit 0
}

# Verificar dependências
check_dependencies() {
    if ! command -v dialog &> /dev/null; then
        log_error "Dialog não encontrado. Instale com: sudo apt install dialog"
        exit 1
    fi
}

# Modo de edição - permite alterar configurações específicas
edit_mode() {
    echo ""
    echo -e "${BLUE='\033[0;34m'}🔧 Modo de Edição${NC='\033[0m'}"
    echo -e "${BLUE}=================${NC}"

    # Tentar carregar configuração atual
    if ! load_encrypted_config; then
        echo -e "${RED='\033[0;31m'}❌ Não foi possível carregar configuração${NC}"
        echo "Execute primeiro: ./setup-credentials.sh"
        return 1
    fi

    echo ""
    echo -e "${GREEN='\033[0;32m'}✓ Configuração carregada${NC}"
    echo ""
    echo -e "${CYAN='\033[0;36m'}Valores atuais:${NC}"
    echo "1)  N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:0:10}...${N8N_ENCRYPTION_KEY: -10}"
    echo "2)  N8N_POSTGRES_PASSWORD: ${N8N_POSTGRES_PASSWORD:0:4}***"
    echo "3)  ORACLE_NAMESPACE: $ORACLE_NAMESPACE"
    echo "4)  ORACLE_REGION: $ORACLE_REGION"
    echo "5)  ORACLE_ACCESS_KEY: ${ORACLE_ACCESS_KEY:0:8}..."
    echo "6)  ORACLE_SECRET_KEY: ${ORACLE_SECRET_KEY:0:4}***${ORACLE_SECRET_KEY: -4}"
    echo "7)  ORACLE_BUCKET: $ORACLE_BUCKET"
    echo "8)  ORACLE_CONFIG_BUCKET: $ORACLE_CONFIG_BUCKET"
    echo "9)  B2_ACCOUNT_ID: $B2_ACCOUNT_ID"
    echo "10) B2_APPLICATION_KEY: ${B2_APPLICATION_KEY:0:4}***"
    echo "11) B2_USE_SEPARATE_KEYS: $B2_USE_SEPARATE_KEYS"
    echo "12) B2_BUCKET: $B2_BUCKET"
    echo "13) B2_CONFIG_BUCKET: $B2_CONFIG_BUCKET"
    echo "14) NOTIFY_WEBHOOK: ${NOTIFY_WEBHOOK:-<vazio>}"
    echo "15) CONFIG_STORAGE_TYPE: $CONFIG_STORAGE_TYPE"
    echo ""
    echo "0)  Salvar alterações e sair"
    echo ""

    while true; do
        echo -e "${YELLOW='\033[1;33m'}Qual campo deseja editar? (0 para sair)${NC}"
        echo -n "> "
        read choice

        case $choice in
            0)
                echo ""
                echo -e "${YELLOW}Salvando alterações...${NC}"
                apply_config_to_env

                log_info "Regenerando rclone..."
                source "${SCRIPT_DIR}/../lib/generate-rclone.sh"
                generate_rclone_config > /dev/null 2>&1

                save_encrypted_config
                save_metadata_to_supabase

                echo -e "${GREEN}✓ Configuração atualizada!${NC}"
                break
                ;;
            1)
                echo -e "${YELLOW}Novo N8N_ENCRYPTION_KEY:${NC}"
                echo -n "> "
                read N8N_ENCRYPTION_KEY
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            2)
                echo -e "${YELLOW}Novo N8N_POSTGRES_PASSWORD:${NC}"
                echo -n "> "
                read -s N8N_POSTGRES_PASSWORD
                echo ""
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            3)
                echo -e "${YELLOW}Novo ORACLE_NAMESPACE:${NC}"
                echo -n "> "
                read ORACLE_NAMESPACE
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            4)
                echo -e "${YELLOW}Novo ORACLE_REGION:${NC}"
                echo -n "> "
                read ORACLE_REGION
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            5)
                echo -e "${YELLOW}Novo ORACLE_ACCESS_KEY:${NC}"
                echo -n "> "
                read ORACLE_ACCESS_KEY
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            6)
                echo -e "${YELLOW}Novo ORACLE_SECRET_KEY:${NC}"
                echo -n "> "
                read -s ORACLE_SECRET_KEY
                echo ""
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            7)
                echo -e "${YELLOW}Novo ORACLE_BUCKET:${NC}"
                echo -n "> "
                read ORACLE_BUCKET
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            8)
                echo -e "${YELLOW}Novo ORACLE_CONFIG_BUCKET:${NC}"
                echo -n "> "
                read ORACLE_CONFIG_BUCKET
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            9)
                echo -e "${YELLOW}Novo B2_ACCOUNT_ID:${NC}"
                echo -n "> "
                read B2_ACCOUNT_ID
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            10)
                echo -e "${YELLOW}Novo B2_APPLICATION_KEY:${NC}"
                echo -n "> "
                read -s B2_APPLICATION_KEY
                echo ""
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            11)
                echo -e "${YELLOW}B2_USE_SEPARATE_KEYS (true/false):${NC}"
                echo -n "> "
                read B2_USE_SEPARATE_KEYS
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            12)
                echo -e "${YELLOW}Novo B2_BUCKET:${NC}"
                echo -n "> "
                read B2_BUCKET
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            13)
                echo -e "${YELLOW}Novo B2_CONFIG_BUCKET:${NC}"
                echo -n "> "
                read B2_CONFIG_BUCKET
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            14)
                echo -e "${YELLOW}Novo NOTIFY_WEBHOOK:${NC}"
                echo -n "> "
                read NOTIFY_WEBHOOK
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            15)
                echo -e "${YELLOW}Novo CONFIG_STORAGE_TYPE (oracle/b2):${NC}"
                echo -n "> "
                read CONFIG_STORAGE_TYPE
                if [ "$CONFIG_STORAGE_TYPE" = "oracle" ]; then
                    CONFIG_BUCKET="$ORACLE_CONFIG_BUCKET"
                else
                    CONFIG_BUCKET="$B2_CONFIG_BUCKET"
                fi
                echo -e "${GREEN}✓ Atualizado${NC}"
                ;;
            *)
                echo -e "${RED}❌ Opção inválida${NC}"
                ;;
        esac

        echo ""
    done
}

# Função principal
main() {
    check_dependencies

    # Tentar carregar configuração existente primeiro
    if load_encrypted_config 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✓ Configuração existente encontrada!${NC}"
        echo -e "${CYAN}Carregando configurações salvas...${NC}"
        apply_config_to_env 2>/dev/null || true
    else
        echo ""
        echo -e "${YELLOW}⚠ Nenhuma configuração encontrada${NC}"
        echo -e "${CYAN}Iniciando configuração interativa...${NC}"
    fi

    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "Arquivo template não encontrado: $TEMPLATE_FILE"
        exit 1
    fi

    log_info "Arquivo será salvo em: $CONFIG_FILE"

    if show_main_menu; then
        log_info "Configuração cancelada pelo usuário"
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi

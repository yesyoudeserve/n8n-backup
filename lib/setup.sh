#!/bin/bash
# ============================================
# Configuração Automática e Interativa
# Arquivo: /opt/n8n-backup/lib/setup.sh
# Versão: 2.0 Final
# ============================================

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Carregar funções do logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

# Arquivo de configuração criptografada
ENCRYPTED_CONFIG_FILE="${SCRIPT_DIR}/config.enc"

# Função para detectar credenciais automaticamente
detect_credentials() {
    log_info "🔍 Detectando credenciais automaticamente..."

    # Carregar config.env para ver se já temos credenciais
    if [ -f "${SCRIPT_DIR}/config.env" ]; then
        source "${SCRIPT_DIR}/config.env"
    fi

    # Detectar N8N Encryption Key
    if [ -z "$N8N_ENCRYPTION_KEY" ] || [ "$N8N_ENCRYPTION_KEY" = "ALTERAR_COM_SUA_CHAVE_ENCRYPTION_REAL" ]; then
        N8N_CONTAINER=$(sudo docker ps --filter "name=n8n" --format "{{.Names}}" | grep -E "^n8n" | head -1 || echo "")
        if [ -n "$N8N_CONTAINER" ]; then
            DETECTED_N8N_KEY=$(sudo docker exec "$N8N_CONTAINER" env 2>/dev/null | grep N8N_ENCRYPTION_KEY | cut -d'=' -f2 | tr -d '\r' || echo "")
            if [ -n "$DETECTED_N8N_KEY" ]; then
                N8N_ENCRYPTION_KEY="$DETECTED_N8N_KEY"
                echo -e "${GREEN}✓ N8N_ENCRYPTION_KEY detectada do container: ${N8N_CONTAINER}${NC}"
            fi
        fi
    fi

    # Detectar PostgreSQL Password
    if [ -z "$N8N_POSTGRES_PASSWORD" ] || [ "$N8N_POSTGRES_PASSWORD" = "ALTERAR_COM_SUA_SENHA_POSTGRES_REAL" ]; then
        POSTGRES_CONTAINER=$(sudo docker ps --filter "name=postgres" --format "{{.Names}}" | grep -E "postgres" | head -1 || echo "")
        if [ -n "$POSTGRES_CONTAINER" ]; then
            DETECTED_POSTGRES_PASS=$(sudo docker exec "$POSTGRES_CONTAINER" env 2>/dev/null | grep POSTGRES_PASSWORD | cut -d'=' -f2 | tr -d '\r' || echo "")
            if [ -n "$DETECTED_POSTGRES_PASS" ]; then
                N8N_POSTGRES_PASSWORD="$DETECTED_POSTGRES_PASS"
                echo -e "${GREEN}✓ N8N_POSTGRES_PASSWORD detectada do container: ${POSTGRES_CONTAINER}${NC}"
            fi
        fi
    fi
}

# Função para perguntar credenciais interativamente
ask_credentials() {
    echo ""
    echo -e "${BLUE}🔐 Configuração de Credenciais${NC}"
    echo -e "${BLUE}================================${NC}"

    # Senha mestra (sempre pedir)
    while true; do
        echo ""
        echo -e "${YELLOW}Digite uma senha mestra forte (mínimo 12 caracteres):${NC}"
        echo -e "${YELLOW}Esta senha protege todas as suas credenciais!${NC}"
        echo -n "> "
        read -s BACKUP_MASTER_PASSWORD
        echo ""

        # Validar se não está vazia
        if [ -z "$BACKUP_MASTER_PASSWORD" ]; then
            echo -e "${RED}❌ Senha não pode ser vazia!${NC}"
            continue
        fi

        # Validar tamanho
        if [ ${#BACKUP_MASTER_PASSWORD} -lt 12 ]; then
            echo -e "${RED}❌ Senha muito curta! Mínimo 12 caracteres.${NC}"
            continue
        fi

        # Confirmar senha
        echo ""
        echo -e "${YELLOW}Confirme a senha mestra:${NC}"
        echo -n "> "
        read -s CONFIRM_PASSWORD
        echo ""

        if [ "$BACKUP_MASTER_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
            echo -e "${RED}❌ As senhas não coincidem!${NC}"
            BACKUP_MASTER_PASSWORD=""
            continue
        fi

        echo -e "${GREEN}✓ Senha mestra aceita (${#BACKUP_MASTER_PASSWORD} caracteres)${NC}"
        break
    done

    # N8N Encryption Key
    if [ -z "$N8N_ENCRYPTION_KEY" ] || [ "$N8N_ENCRYPTION_KEY" = "ALTERAR_COM_SUA_CHAVE_ENCRYPTION_REAL" ]; then
        echo ""
        echo -e "${YELLOW}N8N_ENCRYPTION_KEY (encontre no EasyPanel > Settings > Encryption):${NC}"
        echo -n "> "
        read N8N_ENCRYPTION_KEY
        
        if [ -z "$N8N_ENCRYPTION_KEY" ]; then
            echo -e "${RED}❌ Encryption key não pode ser vazia!${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ Encryption key configurada${NC}"
    else
        echo -e "${GREEN}✓ N8N_ENCRYPTION_KEY já detectada${NC}"
    fi

    # PostgreSQL Password
    if [ -z "$N8N_POSTGRES_PASSWORD" ] || [ "$N8N_POSTGRES_PASSWORD" = "ALTERAR_COM_SUA_SENHA_POSTGRES_REAL" ]; then
        echo ""
        echo -e "${YELLOW}N8N_POSTGRES_PASSWORD (senha do banco PostgreSQL):${NC}"
        echo -n "> "
        read N8N_POSTGRES_PASSWORD
        
        if [ -z "$N8N_POSTGRES_PASSWORD" ]; then
            echo -e "${RED}❌ Senha PostgreSQL não pode ser vazia!${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ PostgreSQL password configurada${NC}"
    else
        echo -e "${GREEN}✓ N8N_POSTGRES_PASSWORD já detectada${NC}"
    fi

    # Oracle Credentials (S3-compatible API)
    echo ""
    echo -e "${BLUE}Oracle Object Storage (S3-compatible):${NC}"
    
    # Namespace
    while [ -z "$ORACLE_NAMESPACE" ] || [ "$ORACLE_NAMESPACE" = "ALTERAR_COM_SEU_NAMESPACE_REAL" ]; do
        echo -e "${YELLOW}ORACLE_NAMESPACE (ex: axqwerty12345):${NC}"
        echo -n "> "
        read ORACLE_NAMESPACE
        if [ -z "$ORACLE_NAMESPACE" ]; then
            echo -e "${RED}❌ Namespace não pode ser vazio!${NC}"
        fi
    done

    # Region
    while [ -z "$ORACLE_REGION" ]; do
        echo -e "${YELLOW}ORACLE_REGION (ex: eu-madrid-1):${NC}"
        echo -n "> "
        read ORACLE_REGION
        if [ -z "$ORACLE_REGION" ]; then
            echo -e "${RED}❌ Region não pode ser vazia!${NC}"
        fi
    done

    # Access Key
    while [ -z "$ORACLE_ACCESS_KEY" ]; do
        echo -e "${YELLOW}ORACLE_ACCESS_KEY (Customer Secret Key - Access Key):${NC}"
        echo -n "> "
        read ORACLE_ACCESS_KEY
        if [ -z "$ORACLE_ACCESS_KEY" ]; then
            echo -e "${RED}❌ Access Key não pode ser vazia!${NC}"
        fi
    done

    # Secret Key
    while [ -z "$ORACLE_SECRET_KEY" ]; do
        echo -e "${YELLOW}ORACLE_SECRET_KEY (Customer Secret Key - Secret):${NC}"
        echo -n "> "
        read -s ORACLE_SECRET_KEY
        echo ""
        if [ -z "$ORACLE_SECRET_KEY" ]; then
            echo -e "${RED}❌ Secret Key não pode ser vazia!${NC}"
        fi
    done

    echo ""
    echo -e "${BLUE}Oracle Buckets:${NC}"
    
    # Bucket de dados Oracle
    while [ -z "$ORACLE_BUCKET" ]; do
        echo -e "${YELLOW}ORACLE_BUCKET (bucket para backups de DADOS - ex: n8n-backups):${NC}"
        echo -n "> "
        read ORACLE_BUCKET
        if [ -z "$ORACLE_BUCKET" ]; then
            echo -e "${RED}❌ Bucket de dados não pode ser vazio!${NC}"
        fi
    done

    # Bucket de configuração Oracle
    while [ -z "$ORACLE_CONFIG_BUCKET" ]; do
        echo -e "${YELLOW}ORACLE_CONFIG_BUCKET (bucket para CONFIGURAÇÕES - ex: n8n-config):${NC}"
        echo -n "> "
        read ORACLE_CONFIG_BUCKET
        if [ -z "$ORACLE_CONFIG_BUCKET" ]; then
            echo -e "${RED}❌ Bucket de config não pode ser vazio!${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ Oracle credentials configuradas${NC}"

    # B2 Credentials
    echo ""
    echo -e "${BLUE}Backblaze B2:${NC}"
    echo -e "${YELLOW}⚠️  Importante: Se seus buckets B2 usam Application Keys separadas,${NC}"
    echo -e "${YELLOW}   você precisará configurar manualmente o rclone depois.${NC}"
    echo ""
    
    # Account ID
    while [ -z "$B2_ACCOUNT_ID" ] || [ "$B2_ACCOUNT_ID" = "ALTERAR_COM_SEU_ACCOUNT_ID_REAL" ]; do
        echo -e "${YELLOW}B2_ACCOUNT_ID:${NC}"
        echo -n "> "
        read B2_ACCOUNT_ID
        if [ -z "$B2_ACCOUNT_ID" ]; then
            echo -e "${RED}❌ Account ID não pode ser vazio!${NC}"
        fi
    done

    # Perguntar se tem chaves separadas
    echo ""
    echo -e "${YELLOW}Suas Application Keys B2 são específicas por bucket?${NC}"
    echo "1) Não - Tenho uma Master Application Key (acessa todos os buckets)"
    echo "2) Sim - Tenho Application Keys diferentes para cada bucket"
    echo -n "> Opção (1 ou 2): "
    read B2_KEY_TYPE

    case $B2_KEY_TYPE in
        1)
            # Uma chave para tudo
            while [ -z "$B2_APPLICATION_KEY" ] || [ "$B2_APPLICATION_KEY" = "ALTERAR_COM_SUA_APP_KEY_REAL" ]; do
                echo -e "${YELLOW}B2_APPLICATION_KEY (Master Key):${NC}"
                echo -n "> "
                read -s B2_APPLICATION_KEY
                echo ""
                if [ -z "$B2_APPLICATION_KEY" ]; then
                    echo -e "${RED}❌ Application Key não pode ser vazia!${NC}"
                fi
            done
            B2_USE_SEPARATE_KEYS=false
            ;;
        2)
            # Chaves separadas
            echo ""
            echo -e "${BLUE}Application Key para bucket de DADOS:${NC}"
            while [ -z "$B2_DATA_KEY" ]; do
                echo -e "${YELLOW}B2_DATA_KEY (para backups):${NC}"
                echo -n "> "
                read -s B2_DATA_KEY
                echo ""
                if [ -z "$B2_DATA_KEY" ]; then
                    echo -e "${RED}❌ Data Key não pode ser vazia!${NC}"
                fi
            done

            echo ""
            echo -e "${BLUE}Application Key para bucket de CONFIGURAÇÕES:${NC}"
            while [ -z "$B2_CONFIG_KEY" ]; do
                echo -e "${YELLOW}B2_CONFIG_KEY (para configurações):${NC}"
                echo -n "> "
                read -s B2_CONFIG_KEY
                echo ""
                if [ -z "$B2_CONFIG_KEY" ]; then
                    echo -e "${RED}❌ Config Key não pode ser vazia!${NC}"
                fi
            done
            
            B2_USE_SEPARATE_KEYS=true
            ;;
        *)
            echo -e "${YELLOW}⚠ Opção inválida. Assumindo Master Key.${NC}"
            while [ -z "$B2_APPLICATION_KEY" ]; do
                echo -e "${YELLOW}B2_APPLICATION_KEY:${NC}"
                echo -n "> "
                read -s B2_APPLICATION_KEY
                echo ""
            done
            B2_USE_SEPARATE_KEYS=false
            ;;
    esac

    echo ""
    echo -e "${BLUE}B2 Buckets:${NC}"

    # Bucket de dados B2
    while [ -z "$B2_BUCKET" ]; do
        echo -e "${YELLOW}B2_BUCKET (bucket para backups de DADOS - ex: n8n-backups-offsite):${NC}"
        echo -n "> "
        read B2_BUCKET
        if [ -z "$B2_BUCKET" ]; then
            echo -e "${RED}❌ Bucket de dados não pode ser vazio!${NC}"
        fi
    done

    # Bucket de configuração B2
    while [ -z "$B2_CONFIG_BUCKET" ]; do
        echo -e "${YELLOW}B2_CONFIG_BUCKET (bucket para CONFIGURAÇÕES - ex: n8n-config-offsite):${NC}"
        echo -n "> "
        read B2_CONFIG_BUCKET
        if [ -z "$B2_CONFIG_BUCKET" ]; then
            echo -e "${RED}❌ Bucket de config não pode ser vazio!${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ B2 credentials configuradas${NC}"

    # Escolher storage para configurações
    echo ""
    echo -e "${BLUE}Escolha o storage para salvar as configurações:${NC}"
    echo "1) Oracle Object Storage"
    echo "2) Backblaze B2"
    echo -n "> Opção (1 ou 2): "
    read STORAGE_CHOICE

    case $STORAGE_CHOICE in
        1)
            CONFIG_STORAGE_TYPE="oracle"
            CONFIG_BUCKET="$ORACLE_CONFIG_BUCKET"
            ;;
        2)
            CONFIG_STORAGE_TYPE="b2"
            CONFIG_BUCKET="$B2_CONFIG_BUCKET"
            ;;
        *)
            echo -e "${YELLOW}⚠ Opção inválida. Usando Oracle por padrão.${NC}"
            CONFIG_STORAGE_TYPE="oracle"
            CONFIG_BUCKET="$ORACLE_CONFIG_BUCKET"
            ;;
    esac

    # Discord Webhook (opcional)
    echo ""
    echo -e "${BLUE}Discord Webhook (opcional - pressione ENTER para pular):${NC}"
    if [ -z "$NOTIFY_WEBHOOK" ]; then
        echo -n "> "
        read NOTIFY_WEBHOOK
        if [ -n "$NOTIFY_WEBHOOK" ]; then
            echo -e "${GREEN}✓ Discord webhook configurado${NC}"
        fi
    fi
}

# Função para consultar Supabase
query_supabase() {
    local action="$1"
    local backup_key_hash="$2"
    local storage_type="${3:-}"
    local storage_config="${4:-}"

    local supabase_url="https://jpxctcxpxmevwiyaxkqu.supabase.co/functions/v1/backup-metadata"
    local backup_secret="xt6F2!iRMul*y9"

    local payload=""
    if [ "$action" = "get" ]; then
        payload="{\"action\":\"get\",\"backupKeyHash\":\"$backup_key_hash\"}"
    elif [ "$action" = "set" ]; then
        payload="{\"action\":\"set\",\"backupKeyHash\":\"$backup_key_hash\",\"storageType\":\"$storage_type\",\"storageConfig\":$storage_config}"
    fi

    curl -s -X POST "$supabase_url" \
         -H "Authorization: Bearer $backup_secret" \
         -H "Content-Type: application/json" \
         -d "$payload"
}

# Função para gerar hash da senha mestra
generate_backup_key_hash() {
    local master_password="$1"
    echo -n "$master_password" | sha256sum | awk '{print $1}'
}

# Função para salvar metadados no Supabase
save_metadata_to_supabase() {
    local master_password="$1"
    local storage_type="$2"
    local config_bucket="$3"

    local backup_key_hash=$(generate_backup_key_hash "$master_password")

    # Configuração do storage em formato JSON
    local storage_config=""
    if [ "$storage_type" = "oracle" ]; then
        storage_config="{\"bucket\":\"$config_bucket\",\"namespace\":\"$ORACLE_NAMESPACE\"}"
    elif [ "$storage_type" = "b2" ]; then
        storage_config="{\"bucket\":\"$config_bucket\"}"
    fi

    log_info "Salvando metadados no Supabase..."
    local response=$(query_supabase "set" "$backup_key_hash" "$storage_type" "$storage_config")

    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        log_success "Metadados salvos no Supabase"
        return 0
    else
        log_error "Falha ao salvar metadados: $response"
        return 1
    fi
}

# Função para buscar metadados do Supabase
load_metadata_from_supabase() {
    local master_password="$1"

    local backup_key_hash=$(generate_backup_key_hash "$master_password")

    log_info "Buscando metadados no Supabase..."
    local response=$(query_supabase "get" "$backup_key_hash")

    if echo "$response" | jq -e '.storageType' > /dev/null 2>&1; then
        CONFIG_STORAGE_TYPE=$(echo "$response" | jq -r '.storageType')
        CONFIG_BUCKET=$(echo "$response" | jq -r '.storageConfig.bucket')
        log_success "Metadados carregados do Supabase"
        return 0
    else
        log_info "Metadados não encontrados (primeira instalação)"
        return 1
    fi
}

# Salvar configuração criptografada
save_encrypted_config() {
    log_info "💾 Salvando configuração criptografada..."

    # Criar arquivo temporário com todas as configurações
    local temp_config="${SCRIPT_DIR}/temp_config.env"

    cat > "$temp_config" << EOF
# Configuração criptografada - $(date)
N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY"
N8N_POSTGRES_PASSWORD="$N8N_POSTGRES_PASSWORD"
ORACLE_NAMESPACE="$ORACLE_NAMESPACE"
ORACLE_REGION="$ORACLE_REGION"
ORACLE_ACCESS_KEY="$ORACLE_ACCESS_KEY"
ORACLE_SECRET_KEY="$ORACLE_SECRET_KEY"
ORACLE_CONFIG_BUCKET="$ORACLE_CONFIG_BUCKET"
ORACLE_BUCKET="$ORACLE_BUCKET"
B2_ACCOUNT_ID="$B2_ACCOUNT_ID"
B2_APPLICATION_KEY="${B2_APPLICATION_KEY:-}"
B2_USE_SEPARATE_KEYS="${B2_USE_SEPARATE_KEYS:-false}"
B2_DATA_KEY="${B2_DATA_KEY:-}"
B2_CONFIG_KEY="${B2_CONFIG_KEY:-}"
B2_CONFIG_BUCKET="$B2_CONFIG_BUCKET"
B2_BUCKET="$B2_BUCKET"
NOTIFY_WEBHOOK="$NOTIFY_WEBHOOK"
BACKUP_MASTER_PASSWORD="$BACKUP_MASTER_PASSWORD"
CONFIG_STORAGE_TYPE="$CONFIG_STORAGE_TYPE"
CONFIG_BUCKET="$CONFIG_BUCKET"
EOF

    # Criptografar arquivo com OpenSSL usando senha mestra
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -pass pass:"$BACKUP_MASTER_PASSWORD" \
        -in "$temp_config" \
        -out "$ENCRYPTED_CONFIG_FILE"

    if [ $? -ne 0 ]; then
        log_error "Falha ao criptografar configuração"
        rm "$temp_config"
        return 1
    fi

    # Limpar arquivo temporário
    rm "$temp_config"

    # Upload para storages
    upload_encrypted_config

    echo -e "${GREEN}✓ Configuração salva e criptografada${NC}"
}

# Upload da configuração criptografada
upload_encrypted_config() {
    log_info "Enviando configuração para ${CONFIG_STORAGE_TYPE}..."

    # Validar se rclone está configurado
    if ! command -v rclone &> /dev/null; then
        log_error "rclone não instalado!"
        return 1
    fi

    # Upload baseado no storage escolhido
    if [ "$CONFIG_STORAGE_TYPE" = "oracle" ]; then
        if rclone ls "oracle:" > /dev/null 2>&1; then
            rclone copy "$ENCRYPTED_CONFIG_FILE" "oracle:${CONFIG_BUCKET}/" --quiet
            if [ $? -eq 0 ]; then
                log_success "Configuração enviada para Oracle"
            else
                log_error "Falha ao enviar para Oracle"
            fi
        else
            log_error "Oracle rclone não configurado!"
        fi
    elif [ "$CONFIG_STORAGE_TYPE" = "b2" ]; then
        # Verificar se usa chaves separadas
        local b2_remote="b2"
        if [ "$B2_USE_SEPARATE_KEYS" = true ]; then
            b2_remote="b2-config"
            log_info "Usando remote 'b2-config' para bucket de configurações"
        fi
        
        if rclone ls "${b2_remote}:" > /dev/null 2>&1; then
            rclone copy "$ENCRYPTED_CONFIG_FILE" "${b2_remote}:${CONFIG_BUCKET}/" --quiet
            if [ $? -eq 0 ]; then
                log_success "Configuração enviada para B2"
            else
                log_error "Falha ao enviar para B2"
            fi
        else
            log_error "B2 rclone não configurado!"
        fi
    fi
}

# Carregar configuração criptografada
load_encrypted_config() {
    log_info "📥 Carregando configuração do cloud..."

    # Pedir senha mestra
    echo ""
    echo -e "${BLUE}🔑 Digite sua senha mestra para carregar as configurações:${NC}"
    echo -n "> "
    read -s MASTER_PASSWORD
    echo ""

    if [ -z "$MASTER_PASSWORD" ]; then
        log_error "Senha mestra não pode ser vazia"
        return 1
    fi

    # Tentar carregar metadados do Supabase
    if load_metadata_from_supabase "$MASTER_PASSWORD"; then
        # Baixar configuração do storage identificado
        if [ "$CONFIG_STORAGE_TYPE" = "oracle" ]; then
            if rclone ls "oracle:${CONFIG_BUCKET}/config.enc" > /dev/null 2>&1; then
                rclone copy "oracle:${CONFIG_BUCKET}/config.enc" "${SCRIPT_DIR}/" --quiet
            fi
        elif [ "$CONFIG_STORAGE_TYPE" = "b2" ]; then
            if rclone ls "b2:${CONFIG_BUCKET}/config.enc" > /dev/null 2>&1; then
                rclone copy "b2:${CONFIG_BUCKET}/config.enc" "${SCRIPT_DIR}/" --quiet
            fi
        fi

        if [ -f "$ENCRYPTED_CONFIG_FILE" ]; then
            # Descriptografar
            local temp_decrypted="${SCRIPT_DIR}/temp_decrypted.env"
            openssl enc -d -aes-256-cbc -salt -pbkdf2 \
                -pass pass:"$MASTER_PASSWORD" \
                -in "$ENCRYPTED_CONFIG_FILE" \
                -out "$temp_decrypted" 2>/dev/null

            if [ $? -eq 0 ]; then
                # Carregar variáveis
                source "$temp_decrypted"
                BACKUP_MASTER_PASSWORD="$MASTER_PASSWORD"
                rm "$temp_decrypted"

                echo -e "${GREEN}✓ Configuração carregada com sucesso!${NC}"
                return 0
            else
                echo -e "${RED}❌ Senha mestra incorreta!${NC}"
                rm "$temp_decrypted" 2>/dev/null || true
                return 1
            fi
        else
            echo -e "${YELLOW}⚠ Arquivo de configuração não encontrado${NC}"
            return 1
        fi
    else
        return 1
    fi
}

# Aplicar configuração no config.env
apply_config_to_env() {
    log_info "📝 Aplicando configuração no config.env..."

    # Atualizar config.env com valores reais (usando | como delimitador)
    sed -i "s|N8N_ENCRYPTION_KEY=\".*\"|N8N_ENCRYPTION_KEY=\"$N8N_ENCRYPTION_KEY\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|N8N_POSTGRES_PASSWORD=\".*\"|N8N_POSTGRES_PASSWORD=\"$N8N_POSTGRES_PASSWORD\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_NAMESPACE=\".*\"|ORACLE_NAMESPACE=\"$ORACLE_NAMESPACE\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_REGION=\".*\"|ORACLE_REGION=\"$ORACLE_REGION\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_ACCESS_KEY=\".*\"|ORACLE_ACCESS_KEY=\"$ORACLE_ACCESS_KEY\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_SECRET_KEY=\".*\"|ORACLE_SECRET_KEY=\"$ORACLE_SECRET_KEY\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_CONFIG_BUCKET=\".*\"|ORACLE_CONFIG_BUCKET=\"$ORACLE_CONFIG_BUCKET\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|ORACLE_BUCKET=\".*\"|ORACLE_BUCKET=\"$ORACLE_BUCKET\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_ACCOUNT_ID=\".*\"|B2_ACCOUNT_ID=\"$B2_ACCOUNT_ID\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_APPLICATION_KEY=\".*\"|B2_APPLICATION_KEY=\"${B2_APPLICATION_KEY:-}\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_USE_SEPARATE_KEYS=.*|B2_USE_SEPARATE_KEYS=${B2_USE_SEPARATE_KEYS:-false}|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_DATA_KEY=\".*\"|B2_DATA_KEY=\"${B2_DATA_KEY:-}\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_CONFIG_KEY=\".*\"|B2_CONFIG_KEY=\"${B2_CONFIG_KEY:-}\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_CONFIG_BUCKET=\".*\"|B2_CONFIG_BUCKET=\"$B2_CONFIG_BUCKET\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|B2_BUCKET=\".*\"|B2_BUCKET=\"$B2_BUCKET\"|g" "${SCRIPT_DIR}/config.env"
    sed -i "s|BACKUP_MASTER_PASSWORD=\".*\"|BACKUP_MASTER_PASSWORD=\"$BACKUP_MASTER_PASSWORD\"|g" "${SCRIPT_DIR}/config.env"

    if [ -n "$NOTIFY_WEBHOOK" ]; then
        sed -i "s|NOTIFY_WEBHOOK=\"\"|NOTIFY_WEBHOOK=\"$NOTIFY_WEBHOOK\"|g" "${SCRIPT_DIR}/config.env"
    fi

    echo -e "${GREEN}✓ Configuração aplicada com sucesso!${NC}"
}

# Setup interativo completo
interactive_setup() {
    echo ""
    echo -e "${BLUE}🚀 N8N Backup System - Configuração Interativa${NC}"
    echo -e "${BLUE}================================================${NC}"

    # Detectar credenciais automaticamente primeiro
    detect_credentials

    # Tentar carregar configuração existente do cloud
    if load_encrypted_config; then
        echo -e "${GREEN}✓ Configuração carregada do cloud!${NC}"
        apply_config_to_env
        
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║    SISTEMA JÁ CONFIGURADO! 🎉         ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "🎯 Sistema pronto para uso:"
        echo "   sudo ./n8n-backup.sh backup    # Fazer backup"
        echo "   sudo ./n8n-backup.sh status    # Ver status"
        echo ""
        return 0
    else
        # Se não conseguiu carregar, pedir credenciais
        echo -e "${YELLOW}⚠ Configuração não encontrada. Vamos configurar...${NC}"
        ask_credentials
    fi

    # Aplicar configuração
    apply_config_to_env

    # Gerar configuração rclone automaticamente
    log_info "Gerando configuração rclone..."
    source "${SCRIPT_DIR}/lib/generate-rclone.sh"
    generate_rclone_config

    # Salvar criptografado no cloud
    save_encrypted_config

    # Salvar metadados no Supabase
    save_metadata_to_supabase "$BACKUP_MASTER_PASSWORD" "$CONFIG_STORAGE_TYPE" "$CONFIG_BUCKET"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    CONFIGURAÇÃO CONCLUÍDA! 🎉         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "🎯 Próximos passos:"
    echo "   1. Primeiro backup: sudo ./n8n-backup.sh backup"
    echo "   2. Ver status: sudo ./n8n-backup.sh status"
    echo ""
}

# Função principal
main() {
    case "${1:-interactive}" in
        interactive)
            interactive_setup
            ;;
        detect)
            detect_credentials
            ;;
        save)
            save_encrypted_config
            ;;
        load)
            load_encrypted_config
            ;;
        *)
            echo "Uso: $0 {interactive|detect|save|load}"
            exit 1
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
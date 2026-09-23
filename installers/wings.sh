#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Instalador Pterodactyl Wings - BlackHosting                                        #
# Versão em Português Brasileiro                                                     #
#                                                                                    #
######################################################################################

# Verifica se o script está carregado
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERRO: Não foi possível carregar o script lib" && exit 1
fi

# ------------------ Variáveis ----------------- #

INSTALL_MARIADB="${INSTALL_MARIADB:-false}"
CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-false}"
CONFIGURE_LETSENCRYPT="${CONFIGURE_LETSENCRYPT:-false}"
FQDN="${FQDN:-}"
EMAIL="${EMAIL:-}"
CONFIGURE_DBHOST="${CONFIGURE_DBHOST:-false}"
CONFIGURE_DB_FIREWALL="${CONFIGURE_DB_FIREWALL:-false}"
MYSQL_DBHOST_HOST="${MYSQL_DBHOST_HOST:-127.0.0.1}"
MYSQL_DBHOST_USER="${MYSQL_DBHOST_USER:-pterodactyluser}"
MYSQL_DBHOST_PASSWORD="${MYSQL_DBHOST_PASSWORD:-}"

# --------- Funções principais de instalação -------- #

install_docker() {
  output "Instalando Docker..."
  
  case "$OS" in
    ubuntu | debian)
      # Remover versões antigas
      apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
      
      # Instalar dependências
      install_packages "ca-certificates curl gnupg lsb-release"
      
      # Adicionar chave GPG oficial do Docker
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      
      # Configurar repositório
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      
      # Instalar Docker Engine
      update_repos
      install_packages "docker-ce docker-ce-cli containerd.io docker-compose-plugin"
      ;;
      
    rocky | almalinux)
      # Instalar yum-utils
      install_packages "yum-utils"
      
      # Adicionar repositório Docker
      yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      
      # Instalar Docker Engine
      install_packages "docker-ce docker-ce-cli containerd.io docker-compose-plugin"
      ;;
  esac
  
  # Habilitar e iniciar Docker
  systemctl enable --now docker
  
  success "Docker instalado com sucesso!"
}

install_wings() {
  output "Instalando Pterodactyl Wings..."
  
  # Baixar wings
  mkdir -p /etc/pterodactyl
  curl -L -o /usr/local/bin/wings "$WINGS_DL_BASE_URL$ARCH"
  
  # Tornar executável
  chmod +x /usr/local/bin/wings
  
  success "Wings instalado!"
}

configure_wings_service() {
  output "Configurando serviço systemd do Wings..."
  
  # Criar arquivo de serviço
  cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
  
  # Recarregar systemd
  systemctl daemon-reload
  systemctl enable wings.service
  
  success "Serviço Wings configurado!"
}

install_mariadb_server() {
  if [ "$INSTALL_MARIADB" == true ]; then
    output "Instalando MariaDB Server..."
    
    case "$OS" in
      ubuntu | debian)
        install_packages "mariadb-server"
        ;;
      rocky | almalinux)
        install_packages "mariadb-server"
        ;;
    esac
    
    # Iniciar MariaDB
    systemctl enable --now mariadb
    
    success "MariaDB instalado!"
  fi
}

configure_database_host() {
  if [ "$CONFIGURE_DBHOST" == true ]; then
    output "Configurando host de banco de dados..."
    
    # Criar usuário de banco de dados
    create_db_user "$MYSQL_DBHOST_USER" "$MYSQL_DBHOST_PASSWORD" "$MYSQL_DBHOST_HOST"
    
    # Conceder privilégios
    mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DBHOST_USER'@'$MYSQL_DBHOST_HOST' WITH GRANT OPTION;"
    mariadb -u root -e "FLUSH PRIVILEGES;"
    
    # Configurar para aceitar conexões externas se necessário
    if [ "$MYSQL_DBHOST_HOST" != "127.0.0.1" ]; then
      output "Configurando MySQL para aceitar conexões externas..."
      sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
      sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || true
      systemctl restart mariadb
    fi
    
    success "Host de banco de dados configurado!"
  fi
}

setup_letsencrypt_wings() {
  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    output "Configurando Let's Encrypt para Wings..."
    
    # Instalar certbot
    case "$OS" in
      ubuntu | debian)
        install_packages "certbot"
        ;;
      rocky | almalinux)
        install_packages "certbot"
        ;;
    esac
    
    # Obter certificado standalone
    certbot certonly --standalone --preferred-challenges http --no-eff-email --email "$EMAIL" --agree-tos -d "$FQDN"
    
    # Criar link simbólico para o Wings
    mkdir -p /etc/letsencrypt/live/
    ln -sf /etc/letsencrypt/live/"$FQDN"/fullchain.pem /etc/pterodactyl/fullchain.pem
    ln -sf /etc/letsencrypt/live/"$FQDN"/privkey.pem /etc/pterodactyl/privkey.pem
    
    success "Let's Encrypt configurado para Wings!"
  fi
}

main() {
  output "Iniciando instalação do Pterodactyl Wings..."
  print_brake 70
  
  # Instalar Docker
  install_docker
  
  # Instalar MariaDB se necessário
  install_mariadb_server
  
  # Configurar host de banco de dados se necessário
  configure_database_host
  
  # Instalar Wings
  install_wings
  
  # Configurar serviço Wings
  configure_wings_service
  
  # Setup Let's Encrypt se necessário
  setup_letsencrypt_wings
  
  # Configurar firewall se necessário
  if [ "$CONFIGURE_FIREWALL" == true ]; then
    output "Configurando firewall..."
    install_firewall
    
    # Portas padrão do Wings
    firewall_allow_ports "8080 2022"
    
    # Porta do Let's Encrypt se necessário
    [ "$CONFIGURE_LETSENCRYPT" == true ] && firewall_allow_ports "80"
    
    # Porta MySQL se necessário
    [ "$CONFIGURE_DB_FIREWALL" == true ] && firewall_allow_ports "3306"
  fi
  
  print_brake 70
  success "Instalação do Pterodactyl Wings concluída!"
  output ""
  output "IMPORTANTE: O Wings foi instalado mas NÃO foi iniciado automaticamente."
  output ""
  output "Próximos passos:"
  output "1. Crie um node no painel Pterodactyl"
  output "2. Copie o arquivo de configuração para /etc/pterodactyl/config.yml"
  output "3. Inicie o Wings: systemctl start wings"
  output ""
  output "Para verificar o status: systemctl status wings"
  output ""
  output "BlackHosting - Obrigado por usar nosso instalador!"
}

# Executar instalação
main

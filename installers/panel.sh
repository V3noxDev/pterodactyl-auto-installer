#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Instalador Pterodactyl Panel - BlackHosting                                        #
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

# Nome de domínio / IP
FQDN="${FQDN:-localhost}"

# Credenciais padrão do MySQL
MYSQL_DB="${MYSQL_DB:-panel}"
MYSQL_USER="${MYSQL_USER:-pterodactyl}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-$(gen_passwd 64)}"

# Ambiente
timezone="${timezone:-America/Sao_Paulo}"
telemetry="${telemetry:-true}"

# Assume SSL
ASSUME_SSL="${ASSUME_SSL:-false}"
CONFIGURE_LETSENCRYPT="${CONFIGURE_LETSENCRYPT:-false}"

# Firewall
CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-false}"

# Devem ser atribuídos para funcionar
email="${email:-}"
user_email="${user_email:-}"
user_username="${user_username:-}"
user_firstname="${user_firstname:-}"
user_lastname="${user_lastname:-}"
user_password="${user_password:-}"

missing=()

for var in email user_email user_username user_firstname user_lastname user_password; do
  if [[ -z "${!var}" ]]; then
    missing+=("$var")
  fi
done

if (( ${#missing[@]} > 0 )); then
  for m in "${missing[@]}"; do
    error "${m} é obrigatório"
  done
  exit 1
fi

# --------- Funções principais de instalação -------- #

install_composer() {
  output "Instalando composer..."
  
  case "$OS" in
    ubuntu | debian)
      install_packages "composer"
      ;;
    rocky | almalinux)
      # Para RHEL/Rocky/Alma usar o método oficial
      curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
      ;;
  esac
  
  success "Composer instalado!"
}

ptdl_dl() {
  output "Baixando arquivos do painel pterodactyl..."
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl || exit

  curl -Lo panel.tar.gz "$PANEL_DL_URL"
  tar -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  success "Arquivos do Pterodactyl baixados!"
}

install_dependencies() {
  output "Instalando dependências do sistema..."
  
  case "$OS" in
    ubuntu | debian)
      install_packages "software-properties-common curl apt-transport-https ca-certificates gnupg"
      update_repos
      install_packages "php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server"
      ;;
    rocky | almalinux)
      install_packages "curl tar unzip git"
      output "Instalando PHP 8.3 e dependências..."
      # Comandos específicos para RHEL/Rocky/Alma
      ;;
  esac
  
  success "Dependências instaladas!"
}

configure_mysql() {
  output "Configurando MySQL..."
  
  # Criar banco de dados e usuário
  create_db "$MYSQL_DB" "$MYSQL_USER"
  create_db_user "$MYSQL_USER" "$MYSQL_PASSWORD"
  
  success "MySQL configurado!"
}

configure_panel() {
  output "Configurando painel Pterodactyl..."
  
  cd /var/www/pterodactyl || exit
  
  # Instalar dependências do composer
  output "Instalando dependências do Composer..."
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction
  
  # Gerar chave da aplicação
  php artisan key:generate --force
  
  # Configurar ambiente
  php artisan p:environment:setup \
    --author="$email" \
    --url="http://$FQDN" \
    --timezone="$timezone" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="localhost" \
    --redis-pass="" \
    --redis-port="6379" \
    --settings-ui=true
  
  # Configurar banco de dados
  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$MYSQL_DB" \
    --username="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD"
  
  # Migrar banco de dados
  php artisan migrate --seed --force
  
  # Criar usuário administrador
  php artisan p:user:make \
    --email="$user_email" \
    --username="$user_username" \
    --name-first="$user_firstname" \
    --name-last="$user_lastname" \
    --password="$user_password" \
    --admin=1
  
  # Definir permissões
  chown -R www-data:www-data /var/www/pterodactyl/*
  
  success "Painel Pterodactyl configurado!"
}

configure_webserver() {
  output "Configurando servidor web nginx..."
  
  # Baixar configuração apropriada do nginx
  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    curl -o /etc/nginx/sites-available/pterodactyl.conf "$GITHUB_URL"/configs/pterodactyl-nginx-ssl.conf
  elif [ "$ASSUME_SSL" == true ]; then
    curl -o /etc/nginx/sites-available/pterodactyl.conf "$GITHUB_URL"/configs/pterodactyl-nginx-ssl.conf
  else
    curl -o /etc/nginx/sites-available/pterodactyl.conf "$GITHUB_URL"/configs/pterodactyl-nginx.conf
  fi
  
  # Substituir <domain> pelo FQDN
  sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/pterodactyl.conf
  
  # Habilitar site
  ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  
  # Remover configuração padrão
  rm -f /etc/nginx/sites-enabled/default
  
  # Reiniciar nginx
  systemctl restart nginx
  
  success "Servidor web configurado!"
}

setup_letsencrypt() {
  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    output "Configurando Let's Encrypt..."
    
    # Instalar certbot
    install_packages "certbot python3-certbot-nginx"
    
    # Obter certificado
    certbot --nginx --redirect --no-eff-email --email "$email" --agree-tos -d "$FQDN"
    
    success "Let's Encrypt configurado!"
  fi
}

configure_cron() {
  output "Configurando cron job..."
  
  (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
  
  success "Cron job configurado!"
}

configure_queue_worker() {
  output "Configurando queue worker..."
  
  curl -o /etc/systemd/system/pteroq.service "$GITHUB_URL"/configs/pteroq.service
  
  systemctl enable --now pteroq.service
  
  success "Queue worker configurado!"
}

main() {
  output "Iniciando instalação do Pterodactyl Panel..."
  print_brake 70
  
  # Instalar dependências
  install_dependencies
  
  # Instalar composer
  install_composer
  
  # Configurar MySQL
  configure_mysql
  
  # Baixar arquivos do pterodactyl
  ptdl_dl
  
  # Configurar painel
  configure_panel
  
  # Configurar webserver
  configure_webserver
  
  # Setup Let's Encrypt se necessário
  setup_letsencrypt
  
  # Configurar firewall se necessário
  if [ "$CONFIGURE_FIREWALL" == true ]; then
    output "Configurando firewall..."
    install_firewall
    firewall_allow_ports "80 443"
  fi
  
  # Configurar cron
  configure_cron
  
  # Configurar queue worker
  configure_queue_worker
  
  print_brake 70
  success "Instalação do Pterodactyl Panel concluída!"
  output ""
  output "Painel instalado com sucesso em: http://$FQDN"
  output "Use as credenciais que você configurou para fazer login."
  output ""
  output "BlackHosting - Obrigado por usar nosso instalador!"
}

# Executar instalação
main

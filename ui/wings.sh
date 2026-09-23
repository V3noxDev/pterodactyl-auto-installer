#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Instalador Pterodactyl - BlackHosting                                              #
# UI Wings - Versão em Português Brasileiro                                          #
#                                                                                    #
######################################################################################

# Verifica se o script está carregado
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERRO: Não foi possível carregar o script lib" && exit 1
fi

# ------------------ Variáveis ----------------- #

# Instalar mariadb
export INSTALL_MARIADB=false

# Firewall
export CONFIGURE_FIREWALL=false

# SSL (Let's Encrypt)
export CONFIGURE_LETSENCRYPT=false
export FQDN=""
export EMAIL=""

# Host do banco de dados
export CONFIGURE_DBHOST=false
export CONFIGURE_DB_FIREWALL=false
export MYSQL_DBHOST_HOST="127.0.0.1"
export MYSQL_DBHOST_USER="pterodactyluser"
export MYSQL_DBHOST_PASSWORD=""

# ------------ Funções de entrada do usuário ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt requer que as portas 80/443 estejam abertas! Você optou por não configurar o firewall automaticamente; use por sua conta e risco (se a porta 80/443 estiver fechada, o script falhará)!"
  fi

  warning "Você não pode usar Let's Encrypt com seu hostname como endereço IP! Deve ser um FQDN (ex: node.exemplo.com.br)."

  echo -e -n "* Deseja configurar HTTPS automaticamente usando Let's Encrypt? (s/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Ss] ]]; then
    CONFIGURE_LETSENCRYPT=true
  fi
}

ask_database_user() {
  echo -n "* Deseja configurar automaticamente um usuário para hosts de banco de dados? (s/N): "
  read -r CONFIRM_DBHOST

  if [[ "$CONFIRM_DBHOST" =~ [Ss] ]]; then
    ask_database_external
    CONFIGURE_DBHOST=true
  fi
}

ask_database_external() {
  echo -n "* Deseja configurar o MySQL para ser acessado externamente? (s/N): "
  read -r CONFIRM_DBEXTERNAL

  if [[ "$CONFIRM_DBEXTERNAL" =~ [Ss] ]]; then
    echo -n "* Digite o endereço do painel (deixe em branco para qualquer endereço): "
    read -r CONFIRM_DBEXTERNAL_HOST
    if [ "$CONFIRM_DBEXTERNAL_HOST" == "" ]; then
      MYSQL_DBHOST_HOST="%"
    else
      MYSQL_DBHOST_HOST="$CONFIRM_DBEXTERNAL_HOST"
    fi
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
    return 0
  fi
}

ask_database_firewall() {
  warning "Permitir tráfego de entrada na porta 3306 (MySQL) pode ser um risco de segurança, a menos que você saiba o que está fazendo!"
  echo -n "* Gostaria de permitir tráfego de entrada na porta 3306? (s/N): "
  read -r CONFIRM_DB_FIREWALL
  if [[ "$CONFIRM_DB_FIREWALL" =~ [Ss] ]]; then
    CONFIGURE_DB_FIREWALL=true
  fi
}

####################
## FUNÇÕES PRINCIPAIS ##
####################

main() {
  # verifica se já existe uma instalação
  if [ -d "/etc/pterodactyl" ]; then
    warning "O script detectou que você já tem o Pterodactyl wings em seu sistema! Você não pode executar o script várias vezes, ele falhará!"
    echo -e -n "* Tem certeza que deseja prosseguir? (s/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Ss] ]]; then
      error "Instalação abortada!"
      exit 1
    fi
  fi

  welcome "wings"

  check_virt

  echo "* "
  echo "* O instalador instalará Docker, dependências necessárias para o Wings"
  echo "* assim como o próprio Wings. Mas ainda é necessário criar o node"
  echo "* no painel e então colocar o arquivo de configuração no node manualmente após"
  echo "* a instalação ter terminado. Leia mais sobre este processo na"
  echo "* documentação oficial: $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo -e "* ${COLOR_RED}Nota${COLOR_NC}: este script não iniciará o Wings automaticamente (instalará o serviço systemd, mas não o iniciará)."
  echo -e "* ${COLOR_RED}Nota${COLOR_NC}: este script não habilitará swap (para docker)."
  print_brake 42

  ask_firewall CONFIGURE_FIREWALL

  ask_database_user

  if [ "$CONFIGURE_DBHOST" == true ]; then
    type mysql >/dev/null 2>&1 && HAS_MYSQL=true || HAS_MYSQL=false

    if [ "$HAS_MYSQL" == false ]; then
      INSTALL_MARIADB=true
    fi

    MYSQL_DBHOST_USER="-"
    while [[ "$MYSQL_DBHOST_USER" == *"-"* ]]; do
      required_input MYSQL_DBHOST_USER "Nome de usuário do host do banco de dados (pterodactyluser): " "" "pterodactyluser"
      [[ "$MYSQL_DBHOST_USER" == *"-"* ]] && error "Usuário do banco de dados não pode conter hífens"
    done

    password_input MYSQL_DBHOST_PASSWORD "Senha do host do banco de dados: " "Senha não pode estar vazia"
  fi

  ask_letsencrypt

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ -z "$FQDN" ]; do
      echo -n "* Defina o FQDN para usar com Let's Encrypt (node.exemplo.com.br): "
      read -r FQDN

      ASK=false

      [ -z "$FQDN" ] && error "FQDN não pode estar vazio"
      bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN" || ASK=true
      [ -d "/etc/letsencrypt/live/$FQDN/" ] && error "Um certificado com este FQDN já existe!" && ASK=true

      [ "$ASK" == true ] && FQDN=""
      [ "$ASK" == true ] && echo -e -n "* Ainda deseja configurar HTTPS automaticamente usando Let's Encrypt? (s/N): "
      [ "$ASK" == true ] && read -r CONFIRM_SSL

      if [[ ! "$CONFIRM_SSL" =~ [Ss] ]] && [ "$ASK" == true ]; then
        CONFIGURE_LETSENCRYPT=false
        FQDN=""
      fi
    done
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while ! valid_email "$EMAIL"; do
      echo -n "* Digite o endereço de e-mail para Let's Encrypt: "
      read -r EMAIL

      valid_email "$EMAIL" || error "E-mail não pode estar vazio ou ser inválido"
    done
  fi

  echo -n "* Prosseguir com a instalação? (s/N): "

  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Ss] ]]; then
    run_installer "wings"
  else
    error "Instalação abortada."
    exit 1
  fi
}

function goodbye {
  echo ""
  print_brake 70
  echo "* Instalação do Wings concluída"
  echo "*"
  echo "* Para continuar, você precisa configurar o Wings para funcionar com seu painel"
  echo "* Por favor, consulte o guia oficial, $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo "* Você pode copiar o arquivo de configuração do painel manualmente para /etc/pterodactyl/config.yml"
  echo "* ou pode usar o botão \"auto deploy\" do painel e simplesmente colar o comando neste terminal"
  echo "* "
  echo "* Você pode então iniciar o Wings manualmente para verificar se está funcionando"
  echo "*"
  echo "* sudo wings"
  echo "*"
  echo "* Depois de verificar que está funcionando, use CTRL+C e então inicie o Wings como serviço (roda em segundo plano)"
  echo "*"
  echo "* systemctl start wings"
  echo "*"
  echo -e "* ${COLOR_RED}Nota${COLOR_NC}: É recomendado habilitar swap (para Docker, leia mais sobre isso na documentação oficial)."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Nota${COLOR_NC}: Se você não configurou seu firewall, as portas 8080 e 2022 precisam estar abertas."
  print_brake 70
  echo ""
  output "Obrigado por usar este script - BlackHosting"
}

# executar script
main
goodbye

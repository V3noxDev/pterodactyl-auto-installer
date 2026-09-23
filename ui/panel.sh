#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Instalador Pterodactyl - BlackHosting                                              #
# UI Panel - Versão em Português Brasileiro                                          #
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
export FQDN=""

# Credenciais padrão do MySQL
export MYSQL_DB=""
export MYSQL_USER=""
export MYSQL_PASSWORD=""

# Ambiente
export timezone=""
export email=""
export telemetry=""

# Conta de administrador inicial
export user_email=""
export user_username=""
export user_firstname=""
export user_lastname=""
export user_password=""

# Assume SSL, buscará configuração diferente se verdadeiro
export ASSUME_SSL=false
export CONFIGURE_LETSENCRYPT=false

# Firewall
export CONFIGURE_FIREWALL=false

# ------------ Funções de entrada do usuário ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt requer que as portas 80/443 estejam abertas! Você optou por não configurar o firewall automaticamente; use por sua conta e risco (se a porta 80/443 estiver fechada, o script falhará)!"
  fi

  echo -e -n "* Deseja configurar HTTPS automaticamente usando Let's Encrypt? (s/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Ss] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

ask_assume_ssl() {
  output "Let's Encrypt não será configurado automaticamente por este script (usuário optou por não usar)."
  output "Você pode 'assumir' Let's Encrypt, o que significa que o script baixará uma configuração nginx configurada para usar um certificado Let's Encrypt, mas o script não obterá o certificado para você."
  output "Se você assumir SSL e não obtiver o certificado, sua instalação não funcionará."
  echo -n "* Assumir SSL ou não? (s/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Ss] ]] && ASSUME_SSL=true
  true
}

ask_telemetry() {
  output "O Pterodactyl Panel coleta dados de telemetria anônimos para ajudar a orientar o desenvolvimento."
  output "Mais informações: https://pterodactyl.io/panel/1.0/additional_configuration.html#telemetry"
  echo -n "* Habilitar envio de dados de telemetria anônimos? (sim/nao) [sim]: "
  read -r telemetry_input

  if [[ -z "$telemetry_input" ]] || [[ "$telemetry_input" =~ ^([Ss]|[Ss]im)$ ]]; then
    telemetry="true"
  else
    telemetry="false"
  fi
}

check_FQDN_SSL() {
  if [[ $(invalid_ip "$FQDN") == 1 && $FQDN != 'localhost' ]]; then
    SSL_AVAILABLE=true
  else
    warning "* Let's Encrypt não estará disponível para endereços IP."
    output "Para usar Let's Encrypt, você deve usar um nome de domínio válido."
  fi
}

main() {
  # verifica se já existe uma instalação
  if [ -d "/var/www/pterodactyl" ]; then
    warning "O script detectou que você já tem o Pterodactyl panel em seu sistema! Você não pode executar o script várias vezes, ele falhará!"
    echo -e -n "* Tem certeza que deseja prosseguir? (s/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Ss] ]]; then
      error "Instalação abortada!"
      exit 1
    fi
  fi

  welcome "panel"

  check_os_x86_64

  # configurar credenciais do banco de dados
  output "Configuração do banco de dados."
  output ""
  output "Estas serão as credenciais usadas para comunicação entre o banco de dados"
  output "MySQL e o painel. Você não precisa criar o banco de dados antes de"
  output "executar este script, o script fará isso para você."
  output ""

  MYSQL_DB="-"
  while [[ "$MYSQL_DB" == *"-"* ]]; do
    required_input MYSQL_DB "Nome do banco de dados (panel): " "" "panel"
    [[ "$MYSQL_DB" == *"-"* ]] && error "Nome do banco de dados não pode conter hífens"
  done

  MYSQL_USER="-"
  while [[ "$MYSQL_USER" == *"-"* ]]; do
    required_input MYSQL_USER "Nome de usuário do banco de dados (pterodactyl): " "" "pterodactyl"
    [[ "$MYSQL_USER" == *"-"* ]] && error "Usuário do banco de dados não pode conter hífens"
  done

  # Entrada de senha do MySQL
  rand_pw=$(gen_passwd 64)
  password_input MYSQL_PASSWORD "Senha (pressione enter para usar senha gerada aleatoriamente): " "Senha do MySQL não pode estar vazia" "$rand_pw"

  readarray -t valid_timezones <<<"$(curl -s "$GITHUB_URL"/configs/valid_timezones.txt)"
  output "Lista de fusos horários válidos aqui $(hyperlink "https://www.php.net/manual/pt_BR/timezones.php")"

  while [ -z "$timezone" ]; do
    echo -n "* Selecione o fuso horário [America/Sao_Paulo]: "
    read -r timezone_input

    array_contains_element "$timezone_input" "${valid_timezones[@]}" && timezone="$timezone_input"
    [ -z "$timezone_input" ] && timezone="America/Sao_Paulo"
  done

  email_input email "Forneça o endereço de e-mail que será usado para configurar Let's Encrypt e Pterodactyl: " "E-mail não pode estar vazio ou ser inválido"

  # Conta de administrador inicial
  email_input user_email "Endereço de e-mail para a conta de administrador inicial: " "E-mail não pode estar vazio ou ser inválido"
  required_input user_username "Nome de usuário para a conta de administrador inicial: " "Nome de usuário não pode estar vazio"
  required_input user_firstname "Primeiro nome para a conta de administrador inicial: " "Nome não pode estar vazio"
  required_input user_lastname "Sobrenome para a conta de administrador inicial: " "Nome não pode estar vazio"
  password_input user_password "Senha para a conta de administrador inicial: " "Senha não pode estar vazia"

  print_brake 72

  # definir FQDN
  while [ -z "$FQDN" ]; do
    echo -n "* Defina o FQDN deste painel (panel.exemplo.com.br): "
    read -r FQDN
    [ -z "$FQDN" ] && error "FQDN não pode estar vazio"
  done

  # Verificar se SSL está disponível
  check_FQDN_SSL

  # Perguntar se o firewall é necessário
  ask_firewall CONFIGURE_FIREWALL

  # Só perguntar sobre SSL se estiver disponível
  if [ "$SSL_AVAILABLE" == true ]; then
    # Perguntar se letsencrypt é necessário
    ask_letsencrypt
    # Se já for verdadeiro, isso deve ser óbvio
    [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
  fi

  # verificar FQDN se o usuário selecionou assumir SSL ou configurar Let's Encrypt
  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN"

  # perguntar preferência de telemetria
  ask_telemetry

  # resumo
  summary

  # confirmar instalação
  echo -e -n "\n* Configuração inicial concluída. Continuar com a instalação? (s/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Ss] ]]; then
    run_installer "panel"
  else
    error "Instalação abortada."
    exit 1
  fi
}

summary() {
  print_brake 62
  output "Pterodactyl panel $PTERODACTYL_PANEL_VERSION com nginx no $OS"
  output "Nome do banco de dados: $MYSQL_DB"
  output "Usuário do banco de dados: $MYSQL_USER"
  output "Senha do banco de dados: (censurada)"
  output "Fuso horário: $timezone"
  output "E-mail: $email"
  output "E-mail do usuário: $user_email"
  output "Nome de usuário: $user_username"
  output "Primeiro nome: $user_firstname"
  output "Sobrenome: $user_lastname"
  output "Senha do usuário: (censurada)"
  output "Hostname/FQDN: $FQDN"
  output "Configurar Firewall? $CONFIGURE_FIREWALL"
  output "Configurar Let's Encrypt? $CONFIGURE_LETSENCRYPT"
  output "Assumir SSL? $ASSUME_SSL"
  output "Telemetria: $telemetry"
  print_brake 62
}

goodbye() {
  print_brake 62
  output "Instalação do Panel concluída"
  output ""

  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Seu painel deve estar acessível em $(hyperlink "$FQDN")"
  [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Você optou por usar SSL, mas não via Let's Encrypt automaticamente. Seu painel não funcionará até que o SSL seja configurado."
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Seu painel deve estar acessível em $(hyperlink "$FQDN")"

  output ""
  output "A instalação está usando nginx no $OS"
  output "Obrigado por usar este script - BlackHosting"
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Nota${COLOR_NC}: Se você não configurou o firewall: 80/443 (HTTP/HTTPS) precisa estar aberto!"
  print_brake 62
}

# executar script
main
goodbye

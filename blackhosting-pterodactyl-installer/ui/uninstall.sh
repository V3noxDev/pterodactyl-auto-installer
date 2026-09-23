#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Desinstalador Pterodactyl - BlackHosting                                           #
# Versão em Português Brasileiro                                                     #
#                                                                                    #
######################################################################################

# Verifica se o script está carregado
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERRO: Não foi possível carregar o script lib" && exit 1
fi

uninstall_panel() {
  warning "AVISO: Esta ação removerá completamente o Pterodactyl Panel do seu sistema!"
  warning "Todos os dados serão perdidos permanentemente!"
  echo -n "* Tem CERTEZA ABSOLUTA que deseja continuar? Digite 'SIM' em maiúsculas: "
  read -r CONFIRM
  
  if [ "$CONFIRM" != "SIM" ]; then
    output "Desinstalação cancelada."
    exit 0
  fi
  
  output "Desinstalando Pterodactyl Panel..."
  
  # Parar serviços
  systemctl stop pteroq 2>/dev/null || true
  systemctl disable pteroq 2>/dev/null || true
  
  # Remover arquivos
  rm -rf /var/www/pterodactyl
  rm -f /etc/systemd/system/pteroq.service
  rm -f /etc/nginx/sites-enabled/pterodactyl.conf
  rm -f /etc/nginx/sites-available/pterodactyl.conf
  
  # Remover cron
  crontab -l | grep -v 'pterodactyl' | crontab - 2>/dev/null || true
  
  # Reiniciar nginx
  systemctl restart nginx 2>/dev/null || true
  
  success "Pterodactyl Panel desinstalado!"
}

uninstall_wings() {
  warning "AVISO: Esta ação removerá completamente o Pterodactyl Wings do seu sistema!"
  warning "Todos os contêineres e dados serão perdidos permanentemente!"
  echo -n "* Tem CERTEZA ABSOLUTA que deseja continuar? Digite 'SIM' em maiúsculas: "
  read -r CONFIRM
  
  if [ "$CONFIRM" != "SIM" ]; then
    output "Desinstalação cancelada."
    exit 0
  fi
  
  output "Desinstalando Pterodactyl Wings..."
  
  # Parar serviço
  systemctl stop wings 2>/dev/null || true
  systemctl disable wings 2>/dev/null || true
  
  # Remover arquivos
  rm -rf /etc/pterodactyl
  rm -f /usr/local/bin/wings
  rm -f /etc/systemd/system/wings.service
  
  # Recarregar systemd
  systemctl daemon-reload
  
  output "Wings desinstalado!"
  output "Nota: Docker não foi removido. Se desejar removê-lo, faça manualmente."
  success "Desinstalação concluída!"
}

main() {
  welcome ""
  
  output "O que você deseja desinstalar?"
  output "[0] Panel"
  output "[1] Wings"
  output "[2] Cancelar"
  
  echo -n "* Escolha uma opção: "
  read -r choice
  
  case $choice in
    0)
      uninstall_panel
      ;;
    1)
      uninstall_wings
      ;;
    2)
      output "Operação cancelada."
      exit 0
      ;;
    *)
      error "Opção inválida"
      exit 1
      ;;
  esac
}

main

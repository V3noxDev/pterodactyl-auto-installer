#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Instalador Pterodactyl - BlackHosting                                              #
# Versão em Português Brasileiro                                                     #
#                                                                                    #
# Baseado no projeto 'pterodactyl-installer' original                                #
# Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>                   #
#                                                                                    #
# Adaptado e traduzido por BlackHosting                                              #
#                                                                                    #
#   Este programa é software livre: você pode redistribuí-lo e/ou modificá-lo       #
#   sob os termos da GNU General Public License conforme publicada pela              #
#   Free Software Foundation, na versão 3 da Licença, ou                             #
#   (a seu critério) qualquer versão posterior.                                      #
#                                                                                    #
#   Este programa é distribuído na esperança de ser útil,                            #
#   mas SEM QUALQUER GARANTIA; sem mesmo a garantia implícita de                     #
#   COMERCIALIZAÇÃO ou ADEQUAÇÃO A UM PROPÓSITO ESPECÍFICO. Veja a                  #
#   GNU General Public License para mais detalhes.                                   #
#                                                                                    #
#   Você deve ter recebido uma cópia da GNU General Public License                   #
#   junto com este programa. Se não, veja <https://www.gnu.org/licenses/>.          #
#                                                                                    #
# Este script não é associado ao Projeto Oficial Pterodactyl.                       #
#                                                                                    #
######################################################################################

export GITHUB_SOURCE="main"
export SCRIPT_RELEASE="v1.0.0-blackhosting"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/V3noxDev/pterodactyl-auto-installer"

LOG_PATH="/var/log/pterodactyl-installer-blackhosting.log"

# Verifica se curl está instalado
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl é necessário para este script funcionar."
  echo "* instale usando apt (Debian e derivados) ou yum/dnf (CentOS)"
  exit 1
fi

# Sempre remove lib.sh antes de baixar
[ -f /tmp/lib.sh ] && rm -rf /tmp/lib.sh
LIB_URL="$GITHUB_BASE_URL/main/lib/lib.sh"
echo "* Baixando lib.sh de: $LIB_URL"
if ! curl -sSLf -o /tmp/lib.sh "$LIB_URL?$(date +%s)"; then
  echo "* ERRO: Não foi possível baixar $LIB_URL"
  echo "* Verifique sua conexão com a internet e tente novamente."
  exit 1
fi
# shellcheck source=lib/lib.sh
source /tmp/lib.sh

execute() {
  echo -e "\n\n* instalador-pterodactyl-blackhosting $(date) \n\n" >>$LOG_PATH

  [[ "$1" == *"canary"* ]] && export GITHUB_SOURCE="main" && export SCRIPT_RELEASE="canary"
  update_lib_source
  run_ui "${1//_canary/}" |& tee -a $LOG_PATH

  if [[ -n $2 ]]; then
    echo -e -n "* Instalação de $1 concluída. Deseja prosseguir com a instalação de $2? (s/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Ss] ]]; then
      execute "$2"
    else
      error "Instalação de $2 abortada."
      exit 1
    fi
  fi
}

welcome ""

done=false
while [ "$done" == false ]; do
  options=(
    "Instalar o Painel (Panel)"
    "Instalar Wings"
    "Instalar ambos [0] e [1] na mesma máquina (Wings após Panel)"

    "Instalar Panel com versão canary do script (versão em desenvolvimento, pode estar quebrada!)"
    "Instalar Wings com versão canary do script (versão em desenvolvimento, pode estar quebrada!)"
    "Instalar ambos [3] e [4] na mesma máquina (Wings após Panel)"
    "Desinstalar panel ou wings com versão canary"
  )

  actions=(
    "panel"
    "wings"
    "panel;wings"

    "panel_canary"
    "wings_canary"
    "panel_canary;wings_canary"
    "uninstall_canary"
  )

  output "O que você gostaria de fazer?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Digite 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "É necessário informar uma opção" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Opção inválida"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done

# Remove lib.sh para que na próxima execução seja baixada a versão mais recente
rm -rf /tmp/lib.sh

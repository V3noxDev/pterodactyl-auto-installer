#!/bin/bash

######################################################################################
#                                                                                    #
# Verificação de FQDN - BlackHosting                                                 #
#                                                                                    #
######################################################################################

FQDN="$1"

# Verifica se FQDN foi fornecido
if [ -z "$FQDN" ]; then
  echo "* ERRO: FQDN não fornecido"
  exit 1
fi

# Verifica se é um IP
if [[ $FQDN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "* ERRO: FQDN não pode ser um endereço IP"
  exit 1
fi

# Verifica se o FQDN resolve
if ! host "$FQDN" >/dev/null 2>&1; then
  echo "* AVISO: FQDN '$FQDN' não resolve para um endereço IP"
  echo "* Isso pode causar problemas com Let's Encrypt"
  echo -n "* Deseja continuar mesmo assim? (s/N): "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ [Ss] ]]; then
    exit 1
  fi
fi

echo "* FQDN '$FQDN' verificado com sucesso"
exit 0

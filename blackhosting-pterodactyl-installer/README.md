# 🦖 Instalador Pterodactyl - BlackHosting

[![License: GPL v3](https://img.shields.io/github/license/pterodactyl-installer/pterodactyl-installer)](LICENSE)
[![made-with-bash](https://img.shields.io/badge/-Feito%20com%20Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

**Versão em Português Brasileiro**

Scripts não oficiais para instalação do Pterodactyl Panel & Wings. Funciona com a versão mais recente do Pterodactyl!

Este é um fork traduzido e personalizado do projeto original [pterodactyl-installer](https://github.com/pterodactyl-installer/pterodactyl-installer), adaptado e mantido por **BlackHosting** para a comunidade brasileira.

Leia mais sobre o [Pterodactyl](https://pterodactyl.io/) aqui. Este script não é associado ao Projeto Oficial Pterodactyl.

## 🚀 Recursos

- Instalação automática do Pterodactyl Panel (dependências, banco de dados, cronjob, nginx).
- Instalação automática do Pterodactyl Wings (Docker, systemd).
- Panel: (opcional) configuração automática de Let's Encrypt.
- Panel: (opcional) configuração automática de firewall.
- Suporte para desinstalação de panel e wings.
- **Interface 100% em Português Brasileiro**
- **Otimizado para uso no Brasil (fuso horário America/Sao_Paulo como padrão)**

## 📋 Instalações Suportadas

Lista de sistemas operacionais suportados para panel e Wings (instalações suportadas por este script de instalação).

### Sistemas operacionais suportados

| Sistema Operacional | Versão | Suportado          | Versão PHP |
| ------------------- | ------ | ------------------ | ---------- |
| Ubuntu              | 22.04  | :white_check_mark: | 8.3        |
|                     | 24.04  | :white_check_mark: | 8.3        |
|                     | 26.04  | :white_check_mark: | 8.3        |
| Debian              | 10     | :white_check_mark: | 8.3        |
|                     | 11     | :white_check_mark: | 8.3        |
|                     | 12     | :white_check_mark: | 8.3        |
|                     | 13     | :white_check_mark: | 8.3        |
| Rocky Linux         | 8      | :white_check_mark: | 8.3        |
|                     | 9      | :white_check_mark: | 8.3        |
| AlmaLinux           | 8      | :white_check_mark: | 8.3        |
|                     | 9      | :white_check_mark: | 8.3        |

## 💻 Usando os scripts de instalação

Para usar os scripts de instalação, simplesmente execute este comando como root. O script perguntará se você gostaria de instalar apenas o panel, apenas o Wings ou ambos.

```bash
bash <(curl -s https://SUA-URL-AQUI/install.sh)
```

_Nota: Em alguns sistemas, é necessário já estar logado como root antes de executar o comando de uma linha (onde `sudo` está na frente do comando não funciona)._

## 🔥 Configuração de Firewall

Os scripts de instalação podem instalar e configurar um firewall para você. O script perguntará se você deseja isso ou não. É altamente recomendado optar pela configuração automática do firewall.

## 🇧🇷 Diferenças desta versão

Esta versão foi adaptada para o público brasileiro com as seguintes modificações:

- ✅ Interface 100% traduzida para Português Brasileiro
- ✅ Fuso horário padrão: `America/Sao_Paulo`
- ✅ Mensagens de erro e sucesso em português
- ✅ Documentação em português
- ✅ Exemplos de domínio usando `.com.br`
- ✅ Branding BlackHosting

## 📝 Ajuda e Suporte

Para ajuda e suporte relacionados ao script em si e **não ao projeto oficial Pterodactyl**, entre em contato com a BlackHosting.

## ⚖️ Licença

Este projeto é licenciado sob a GNU General Public License v3.0.

Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>  
Adaptado e traduzido por BlackHosting

Este programa é software livre: você pode redistribuí-lo e/ou modificá-lo sob os termos da GNU General Public License conforme publicada pela Free Software Foundation, na versão 3 da Licença, ou (a seu critério) qualquer versão posterior.

## 🙏 Créditos

- Projeto original criado por [Vilhelm Prytz](https://github.com/vilhelmprytz)
- Mantido por [Linux123123](https://github.com/Linux123123)
- Traduzido e adaptado por **BlackHosting**

Este script não é associado ao Projeto Oficial Pterodactyl.

## ⚠️ Aviso Legal

Este software é fornecido "como está", sem garantia de qualquer tipo, expressa ou implícita. Em nenhum caso os autores ou detentores de direitos autorais serão responsáveis por qualquer reclamação, danos ou outra responsabilidade.

---

**BlackHosting** - Hospedagem de qualidade para brasileiros 🇧🇷

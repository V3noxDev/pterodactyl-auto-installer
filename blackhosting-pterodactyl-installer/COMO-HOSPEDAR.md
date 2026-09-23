# Como Hospedar Este Instalador

Este guia explica como você pode hospedar o instalador BlackHosting Pterodactyl em seu próprio servidor ou GitHub Pages.

## Opção 1: Hospedagem via GitHub (Recomendado)

### Passo 1: Fazer Fork do Repositório

1. Faça upload deste código para um repositório GitHub
2. O repositório pode ser público ou privado

### Passo 2: Configurar GitHub Pages (para repositório público)

1. Vá em Settings → Pages
2. Selecione a branch `main` (ou `master`)
3. Selecione a pasta `/ (root)`
4. Salve

### Passo 3: Usar o Raw URL

Para repositórios GitHub, você pode usar o raw URL:

```bash
bash <(curl -s https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO/main/install.sh)
```

**Importante:** Você precisa atualizar todas as URLs dentro dos scripts:

1. Abra `install.sh`
2. Encontre: `export GITHUB_BASE_URL="https://raw.githubusercontent.com/SEUGITHUB/blackhosting-pterodactyl-installer"`
3. Substitua `SEUGITHUB` pelo seu usuário do GitHub
4. Faça o mesmo em `lib/lib.sh`

## Opção 2: Hospedagem em Servidor Web Próprio

### Requisitos

- Servidor web (Apache, Nginx, etc.)
- Domínio ou subdomínio
- Certificado SSL (recomendado)

### Passo 1: Upload dos Arquivos

Faça upload de todos os arquivos para seu servidor web:

```bash
/var/www/html/pterodactyl-installer/
├── install.sh
├── lib/
│   ├── lib.sh
│   └── verify-fqdn.sh
├── ui/
│   ├── panel.sh
│   ├── wings.sh
│   └── uninstall.sh
├── installers/
│   ├── panel.sh
│   └── wings.sh
└── configs/
    └── valid_timezones.txt
```

### Passo 2: Configurar Permissões

```bash
chmod -R 755 /var/www/html/pterodactyl-installer/
```

### Passo 3: Atualizar URLs nos Scripts

Em `install.sh` e `lib/lib.sh`, atualize:

```bash
export GITHUB_BASE_URL="https://seudominio.com.br/pterodactyl-installer"
```

### Passo 4: Usar o Instalador

```bash
bash <(curl -s https://seudominio.com.br/pterodactyl-installer/install.sh)
```

## Opção 3: Usar Localmente

Para testar localmente ou usar sem internet:

```bash
# Clone ou baixe os arquivos
cd /root/pterodactyl-installer

# Execute diretamente
bash install.sh
```

## URLs que Precisam ser Atualizadas

Certifique-se de atualizar estas URLs em todos os arquivos:

### install.sh
```bash
export GITHUB_BASE_URL="https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO"
```

### lib/lib.sh
```bash
export GITHUB_BASE_URL=${GITHUB_BASE_URL:-"https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO"}
```

## Testando a Instalação

Antes de disponibilizar para outros, teste:

1. Em uma VM ou container limpo
2. Execute o comando de instalação
3. Verifique se todos os arquivos são baixados corretamente
4. Verifique se a instalação completa com sucesso

## Segurança

- Use HTTPS sempre que possível
- Mantenha o repositório atualizado
- Não armazene credenciais nos scripts
- Considere usar assinatura de código

## Personalização Adicional

Você pode personalizar ainda mais:

- Adicionar seu logo/branding
- Modificar mensagens padrão
- Adicionar pré-configurações específicas
- Criar versões customizadas para diferentes casos de uso

---

**BlackHosting** - Para mais informações, entre em contato conosco.

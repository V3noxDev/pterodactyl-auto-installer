# 📚 Guia de Instalação - BlackHosting Pterodactyl Installer

## 🚀 Instalação Rápida

### Requisitos

- Sistema operacional suportado (Ubuntu 22.04+, Debian 10+, Rocky/AlmaLinux 8+)
- Acesso root ao servidor
- Conexão com a internet
- (Opcional) Domínio apontado para o servidor para usar Let's Encrypt

### Instalação com um comando

Para começar a instalação, execute como root:

```bash
bash <(curl -s https://SEU-DOMINIO.com.br/install.sh)
```

**Nota:** Você precisará hospedar este script em um servidor web acessível pela internet.

### Opções de Instalação

Ao executar o script, você verá as seguintes opções:

1. **[0] Instalar o Painel (Panel)** - Instala apenas o painel de controle Pterodactyl
2. **[1] Instalar Wings** - Instala apenas o Wings (daemon que executa os servidores)
3. **[2] Instalar ambos** - Instala Panel e Wings na mesma máquina
4. **[3-6] Versões Canary** - Versões de desenvolvimento (não recomendado para produção)

## 📖 Instalação Detalhada

### Instalando o Panel

1. Execute o script de instalação
2. Selecione a opção `[0]`
3. Forneça as informações solicitadas:
   - Nome do banco de dados (padrão: panel)
   - Usuário do banco de dados (padrão: pterodactyl)
   - Senha do banco de dados (será gerada automaticamente se deixar em branco)
   - Fuso horário (padrão: America/Sao_Paulo)
   - E-mail do administrador
   - Dados da conta de administrador (nome de usuário, nome, sobrenome, senha)
   - FQDN/domínio do painel (ex: panel.seudominio.com.br)
   - Se deseja configurar firewall automaticamente (recomendado: sim)
   - Se deseja configurar Let's Encrypt (recomendado se tiver domínio: sim)

4. Confirme as informações e aguarde a instalação

### Instalando o Wings

1. Execute o script de instalação
2. Selecione a opção `[1]`
3. Forneça as informações solicitadas:
   - Se deseja configurar firewall automaticamente (recomendado: sim)
   - Se deseja configurar usuário para host de banco de dados
   - Se deseja configurar Let's Encrypt para o Wings

4. Após a instalação:
   - Acesse o painel Pterodactyl
   - Crie um novo Node
   - Copie o arquivo de configuração fornecido
   - Cole em `/etc/pterodactyl/config.yml`
   - Inicie o Wings: `systemctl start wings`

### Instalando Ambos

1. Execute o script de instalação
2. Selecione a opção `[2]`
3. Siga as instruções para o Panel primeiro
4. Depois siga as instruções para o Wings

## 🔧 Configuração Pós-Instalação

### Panel

Após a instalação do Panel, você pode acessá-lo através do domínio configurado:

```
http://seu-dominio.com.br
```

ou

```
https://seu-dominio.com.br (se configurou Let's Encrypt)
```

Faça login com as credenciais de administrador que você criou.

### Wings

Após instalar o Wings:

1. **Criar Node no Panel**
   - Faça login no painel
   - Vá em "Admin" → "Nodes" → "Create New"
   - Preencha as informações do node
   - Copie o comando de configuração ou o conteúdo do arquivo config.yml

2. **Configurar o Wings**
   ```bash
   nano /etc/pterodactyl/config.yml
   # Cole o conteúdo copiado do painel
   ```

3. **Iniciar o Wings**
   ```bash
   systemctl start wings
   systemctl status wings
   ```

4. **Verificar logs (se houver problemas)**
   ```bash
   journalctl -u wings -f
   ```

## 🔒 Configurações de Segurança

### Firewall

Se você optou pela configuração automática do firewall, as seguintes portas foram abertas:

**Panel:**
- 80/tcp (HTTP)
- 443/tcp (HTTPS)

**Wings:**
- 8080/tcp (Daemon)
- 2022/tcp (SFTP)
- 3306/tcp (MySQL - apenas se configurado para acesso externo)

### SSL/TLS

É altamente recomendado usar Let's Encrypt para SSL. O script pode configurar isso automaticamente se você:
- Tiver um domínio válido
- O domínio estiver apontado para o IP do servidor
- As portas 80 e 443 estiverem abertas

## 🐛 Resolução de Problemas

### Panel não carrega

1. Verifique se o nginx está rodando:
   ```bash
   systemctl status nginx
   ```

2. Verifique os logs:
   ```bash
   tail -f /var/log/nginx/error.log
   ```

### Wings não conecta ao Panel

1. Verifique se o Wings está rodando:
   ```bash
   systemctl status wings
   ```

2. Verifique a configuração:
   ```bash
   cat /etc/pterodactyl/config.yml
   ```

3. Verifique os logs:
   ```bash
   journalctl -u wings -f
   ```

### Problemas com Let's Encrypt

1. Verifique se o domínio está apontado corretamente:
   ```bash
   nslookup seu-dominio.com.br
   ```

2. Verifique se as portas 80 e 443 estão abertas:
   ```bash
   netstat -tulpn | grep -E ':(80|443)'
   ```

## 📞 Suporte

Para suporte relacionado ao script de instalação, entre em contato com a BlackHosting.

Para suporte relacionado ao Pterodactyl em si, consulte a [documentação oficial](https://pterodactyl.io/project/introduction.html).

## ⚠️ Observações Importantes

- Este script deve ser executado como root
- Não execute o script múltiplas vezes na mesma máquina
- Faça backup de dados importantes antes de instalar
- Para ambientes de produção, use versões estáveis (não canary)
- Certifique-se de que seu servidor atende aos requisitos mínimos do Pterodactyl

## 🔄 Atualizações

Para atualizar o Pterodactyl Panel ou Wings, consulte a documentação oficial do Pterodactyl:
- [Atualizar Panel](https://pterodactyl.io/panel/1.0/updating.html)
- [Atualizar Wings](https://pterodactyl.io/wings/1.0/upgrading.html)

---

**BlackHosting** - Hospedagem de qualidade para brasileiros 🇧🇷

#!/bin/bash

system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instância...${GRAY_LIGHT}\n\n"

  sleep 2

  # Verifica se a senha do MySQL foi fornecida
  if [ -z "$mysql_root_password" ]; then
    printf "${RED} ❌ A senha para o usuário deploy não foi fornecida! Abortando operação.${GRAY_LIGHT}\n"
    exit 1
  fi

  # Criando o usuário 'deploy'
  printf "${WHITE} 🔧 Criando o usuário deploy...${GRAY_LIGHT}\n"
  sudo su - root <<EOF
    useradd -m -p \$(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
    usermod -aG sudo deploy
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Usuário 'deploy' criado com sucesso e adicionado ao grupo sudo.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao criar o usuário 'deploy'. Abortando operação.${GRAY_LIGHT}\n"
    exit 1
  fi

  # Adicionando configurações do NVM no .bashrc do deploy
  printf "${WHITE} 🔧 Configurando o NVM para o usuário deploy...${GRAY_LIGHT}\n"
  sudo su - root <<EOF
    echo 'export NVM_DIR="\$HOME/.nvm"' >> /home/deploy/.bashrc
    echo '[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"' >> /home/deploy/.bashrc
    echo '[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"' >> /home/deploy/.bashrc
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Configuração do NVM concluída para o usuário deploy.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao configurar o NVM para o usuário deploy.${GRAY_LIGHT}\n"
    exit 1
  fi

  sleep 2
}

system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código AutoAtende...${GRAY_LIGHT}\n\n"

  sleep 2

  printf "${WHITE} 🔧 Verificando se o git está instalado...${GRAY_LIGHT}\n"
  git --version &>/dev/null
  if [ $? -ne 0 ]; then
    printf "${RED} ❌ Git não encontrado! Instalando o git...${GRAY_LIGHT}\n"
    sudo apt install -y git
    if [ $? -ne 0 ]; then
      printf "${RED} ❌ Falha ao instalar o git. Abortando operação.${GRAY_LIGHT}\n"
      exit 1
    fi
  else
    printf "${GREEN} ✅ Git está instalado.${GRAY_LIGHT}\n"
  fi

  if [ -d "/home/deploy/${instancia_add}" ]; then
    printf "${RED} ❌ A pasta /home/deploy/${instancia_add} já existe. Abortando operação para evitar sobrescrita.${GRAY_LIGHT}\n"
    exit 1
  fi

  printf "${WHITE} 🔧 Clonando o repositório do AutoAtende...${GRAY_LIGHT}\n"
  sudo su - deploy <<EOF
    git clone https://lucassaud:${token_code}@github.com/AutoAtende/AA-APP.git /home/deploy/${instancia_add}
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Repositório clonado com sucesso em /home/deploy/${instancia_add}.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao clonar o repositório. Abortando operação.${GRAY_LIGHT}\n"
    exit 1
  fi

  sleep 2
}

system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos preparar o sistema para o AutoAtende...${GRAY_LIGHT}\n\n"

  sleep 2

  # Início do processo de atualização do sistema
  printf "${WHITE} 🔧 Atualizando o sistema...${GRAY_LIGHT}\n"
  sudo su - root <<EOF
  sudo apt -y update
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Sistema atualizado com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha na atualização do sistema.${GRAY_LIGHT}\n"
    exit 1
  fi

  printf "${WHITE} 🔧 Instalando pacotes necessários...${GRAY_LIGHT}\n"
  sudo apt-get install -y build-essential libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Pacotes instalados com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao instalar pacotes.${GRAY_LIGHT}\n"
    exit 1
  fi

  printf "${WHITE} 🔧 Removendo pacotes desnecessários...${GRAY_LIGHT}\n"
  sudo apt-get autoremove -y
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Pacotes desnecessários removidos com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao remover pacotes desnecessários.${GRAY_LIGHT}\n"
    exit 1
  fi
EOF

  sleep 2

  printf "${WHITE} ✔️ Sistema preparado com sucesso para o AutoAtende!${GRAY_LIGHT}\n\n"
  sleep 2
}

deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o AutoAtende da empresa ${empresa_delete}...${GRAY_LIGHT}\n\n"

  sleep 2

  printf "${WHITE} 🔧 Removendo o Redis do servidor...${GRAY_LIGHT}\n"
  sudo systemctl stop redis
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Redis parado com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao parar o Redis.${GRAY_LIGHT}\n"
    exit 1
  fi
  sudo apt-get purge --auto-remove redis-server -y
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Redis removido com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao remover o Redis.${GRAY_LIGHT}\n"
    exit 1
  fi

  printf "${WHITE} 🔧 Removendo arquivos de configuração do Nginx...${GRAY_LIGHT}\n"
  rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend
  rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Arquivos de configuração do Nginx removidos com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao remover arquivos de configuração do Nginx.${GRAY_LIGHT}\n"
    exit 1
  fi

  sleep 2

  sudo su - postgres <<EOF
  printf "${WHITE} 🔧 Deletando banco de dados e usuário PostgreSQL...${GRAY_LIGHT}\n"
  dropuser ${empresa_delete}
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Usuário PostgreSQL ${empresa_delete} deletado com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao deletar o usuário PostgreSQL ${empresa_delete}.${GRAY_LIGHT}\n"
    exit 1
  fi
  dropdb ${empresa_delete}
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Banco de dados ${empresa_delete} deletado com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao deletar o banco de dados ${empresa_delete}.${GRAY_LIGHT}\n"
    exit 1
  fi
  exit
EOF

  sleep 2

  sudo su - deploy <<EOF
  printf "${WHITE} 🔧 Deletando arquivos e serviços PM2...${GRAY_LIGHT}\n"
  rm -rf /home/deploy/${empresa_delete}
  pm2 delete ${empresa_delete}-backend
  pm2 save
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Arquivos e serviços PM2 deletados com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao deletar arquivos e serviços PM2.${GRAY_LIGHT}\n"
    exit 1
  fi
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instância/Empresa ${empresa_delete} realizada com sucesso!${GRAY_LIGHT}\n\n"

  sleep 2
}

system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Node.js e outras dependências...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🚀 Configurando o Node.js...${GRAY_LIGHT}\n"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
printf "${GREEN} ✅ Node.js configurado com sucesso.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🔄 Atualizando o sistema...${GRAY_LIGHT}\n"
apt-get update -y
printf "${GREEN} ✅ Sistema atualizado.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🛠️ Instalando o Node.js versão 20.17.0...${GRAY_LIGHT}\n"
apt-get install -y nodejs=20.17.0-1nodesource1
printf "${GREEN} ✅ Node.js instalado com sucesso.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🔧 Atualizando o NPM para a versão 10.8.0...${GRAY_LIGHT}\n"
npm install -g npm@10.8.0
printf "${GREEN} ✅ NPM atualizado.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 📦 Instalando o NVM...${GRAY_LIGHT}\n"
wget --quiet -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="\$([ -z "\${XDG_CONFIG_HOME-}" ] && printf %s "\${HOME}/.nvm" || printf %s "\${XDG_CONFIG_HOME}/nvm")"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
printf "${GREEN} ✅ NVM instalado com sucesso.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🗃️ Configurando o repositório PostgreSQL...${GRAY_LIGHT}\n"
echo "deb http://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
printf "${GREEN} ✅ Repositório PostgreSQL configurado.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🛠️ Instalando PostgreSQL versão 16...${GRAY_LIGHT}\n"
apt-get -y install postgresql-16
printf "${GREEN} ✅ PostgreSQL instalado com sucesso.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🌍 Configurando o fuso horário para América/São Paulo...${GRAY_LIGHT}\n"
timedatectl set-timezone America/Sao_Paulo
printf "${GREEN} ✅ Fuso horário configurado.${GRAY_LIGHT}\n\n"
sleep 2
EOF

  sleep 2
}

system_fail2ban_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Fail2Ban e configurando...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔄 Atualizando o sistema...${GRAY_LIGHT}\n"
apt-get update -y
printf "${GREEN} ✅ Sistema atualizado.${GRAY_LIGHT}\n\n"
sleep 2

printf "${WHITE} 🛡️ Instalando Fail2Ban...${GRAY_LIGHT}\n"
apt-get install fail2ban -y
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Fail2Ban instalado com sucesso.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao instalar o Fail2Ban.${GRAY_LIGHT}\n\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🛠️ Configurando o Fail2Ban...${GRAY_LIGHT}\n"
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Configuração de Fail2Ban concluída.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao configurar o Fail2Ban.${GRAY_LIGHT}\n\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🚀 Instalação e configuração do Fail2Ban finalizadas!${GRAY_LIGHT}\n\n"
}

system_fail2ban_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o Fail2Ban...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🛠️ Habilitando o serviço Fail2Ban no boot...${GRAY_LIGHT}\n"
systemctl enable fail2ban
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Fail2Ban habilitado para iniciar automaticamente.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao habilitar o Fail2Ban.${GRAY_LIGHT}\n\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🚀 Iniciando o serviço Fail2Ban...${GRAY_LIGHT}\n"
systemctl start fail2ban
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Fail2Ban iniciado com sucesso.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao iniciar o Fail2Ban.${GRAY_LIGHT}\n\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Configuração do Fail2Ban concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_firewall_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o Firewall com UFW...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Configurando regras padrão do firewall...${GRAY_LIGHT}\n"
ufw default allow outgoing
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Regras padrão de saída configuradas para permitir conexões.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao configurar as regras padrão de saída.${GRAY_LIGHT}\n"
  exit 1
fi

ufw default deny incoming
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Regras padrão de entrada configuradas para bloquear conexões.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao configurar as regras padrão de entrada.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🚪 Permitindo conexões essenciais (SSH, HTTP, HTTPS)...${GRAY_LIGHT}\n"
ufw allow ssh
ufw allow 22
ufw allow 80
ufw allow 443
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Conexões SSH, HTTP e HTTPS permitidas.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao configurar as regras de conexões essenciais.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔐 Habilitando o firewall...${GRAY_LIGHT}\n"
echo "y" | ufw enable
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Firewall ativado com sucesso.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao ativar o firewall.${GRAY_LIGHT}\n\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Configuração do firewall concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o PM2...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Instalando PM2 globalmente...${GRAY_LIGHT}\n"
npm install -g pm2@latest
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ PM2 instalado com sucesso.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao instalar o PM2.${GRAY_LIGHT}\n\n"
  exit 1
fi
EOF

  sleep 2

  printf "${WHITE} 🎉 Instalação do PM2 concluída!${GRAY_LIGHT}\n\n"
}

system_set_timezone() {
  print_banner
  printf "${WHITE} 💻 Definindo a Timezone...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🌍 Configurando o timezone para 'America/Sao_Paulo'...${GRAY_LIGHT}\n"
timedatectl set-timezone America/Sao_Paulo
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Timezone configurado para 'America/Sao_Paulo'.${GRAY_LIGHT}\n\n"
else
  printf "${RED} ❌ Falha ao configurar o timezone.${GRAY_LIGHT}\n\n"
  exit 1
fi
EOF

  sleep 2

  printf "${WHITE} 🎉 Configuração de timezone concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o Snapd...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Instalando o pacote snapd...${GRAY_LIGHT}\n"
apt install -y snapd
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Snapd instalado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao instalar o snapd.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔧 Instalando o núcleo do Snap (core)...${GRAY_LIGHT}\n"
snap install core
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Core do Snap instalado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao instalar o core do Snap.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔄 Atualizando o núcleo do Snap (core)...${GRAY_LIGHT}\n"
snap refresh core
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Core do Snap atualizado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao atualizar o core do Snap.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Instalação do Snapd concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o Certbot...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Removendo versões antigas do Certbot...${GRAY_LIGHT}\n"
apt-get remove -y certbot
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Versões antigas do Certbot removidas com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao remover versões antigas do Certbot.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔧 Instalando Certbot via Snap...${GRAY_LIGHT}\n"
snap install --classic certbot
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Certbot instalado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao instalar o Certbot.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔧 Criando link simbólico para '/usr/bin/certbot'...${GRAY_LIGHT}\n"
ln -sf /snap/bin/certbot /usr/bin/certbot
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Link simbólico criado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao criar o link simbólico.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Instalação do Certbot concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o Nginx...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Instalando o Nginx...${GRAY_LIGHT}\n"
apt install -y nginx
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Nginx instalado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao instalar o Nginx.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2

printf "${WHITE} 🔧 Removendo o arquivo de configuração padrão do Nginx...${GRAY_LIGHT}\n"
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Arquivos de configuração padrão removidos com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao remover arquivos de configuração padrão.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Instalação do Nginx concluída com sucesso!${GRAY_LIGHT}\n\n"
}

system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando o Nginx...${GRAY_LIGHT}\n\n"

  sleep 2

  sudo su - root <<EOF
printf "${WHITE} 🔧 Reiniciando o Nginx...${GRAY_LIGHT}\n"
service nginx restart
if [ \$? -eq 0 ]; then
  printf "${GREEN} ✅ Nginx reiniciado com sucesso.${GRAY_LIGHT}\n"
else
  printf "${RED} ❌ Falha ao reiniciar o Nginx.${GRAY_LIGHT}\n"
  exit 1
fi
sleep 2
EOF

  printf "${WHITE} 🎉 Nginx reiniciado com sucesso!${GRAY_LIGHT}\n\n"
}

system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o Nginx...${GRAY_LIGHT}\n\n"

  sleep 2

  # Verifica se o diretório de configuração do Nginx existe
  if [ ! -d "/etc/nginx/conf.d" ]; then
    printf "${RED} ❌ Diretório /etc/nginx/conf.d não encontrado! Abortando operação.${GRAY_LIGHT}\n"
    exit 1
  fi

  # Configurando o arquivo de configuração do Nginx
  printf "${WHITE} 🔧 Criando configuração para aumentar o tamanho do corpo da requisição...${GRAY_LIGHT}\n"
  sudo su - root <<EOF
cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END
EOF

  # Verificando se o arquivo de configuração foi criado com sucesso
  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Arquivo de configuração do Nginx criado com sucesso em /etc/nginx/conf.d/deploy.conf.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao criar o arquivo de configuração do Nginx.${GRAY_LIGHT}\n"
    exit 1
  fi

  # Reiniciando o Nginx para aplicar as mudanças
  printf "${WHITE} 🔄 Reiniciando o Nginx para aplicar a nova configuração...${GRAY_LIGHT}\n"
  sudo su - root <<EOF
service nginx restart
EOF

  # Verificando se o Nginx foi reiniciado com sucesso
  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Nginx reiniciado com sucesso.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao reiniciar o Nginx.${GRAY_LIGHT}\n"
    exit 1
  fi

  sleep 2
}

system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando o Certbot, já estamos perto do fim...${GRAY_LIGHT}\n\n"

  sleep 2

  # Substituindo https:// para o domínio base (sem protocolo)
  backend_domain=$(echo "${backend_url}" | sed 's/https:\/\///')
  frontend_domain=$(echo "${frontend_url}" | sed 's/https:\/\///')

  sudo su - root <<EOF
  printf "${WHITE} 🔧 Configurando Certbot para os domínios ${backend_domain} e ${frontend_domain}...${GRAY_LIGHT}\n"
  
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
  
  if [ \$? -eq 0 ]; then
    printf "${GREEN} ✅ Certbot configurado com sucesso para os domínios ${backend_domain} e ${frontend_domain}.${GRAY_LIGHT}\n"
  else
    printf "${RED} ❌ Falha ao configurar o Certbot.${GRAY_LIGHT}\n"
    exit 1
  fi
EOF

  sleep 2
  printf "${WHITE} 🎉 Certbot configurado com sucesso!${GRAY_LIGHT}\n\n"
}

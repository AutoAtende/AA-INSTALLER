#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  useradd -m -p $(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
  usermod -aG sudo deploy
  echo 'export NVM_DIR="\$HOME/.nvm"' >> /home/deploy/.bashrc
  echo '[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"' >> /home/deploy/.bashrc
  echo '[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"' >> /home/deploy/.bashrc
EOF

  sleep 2
}

#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
  git clone https://lucassaud:${token_code}@github.com/AutoAtende/AA-APP.git /home/deploy/${instancia_add}
EOF

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos preparar o sistema para o AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  sudo apt -y update
  sudo apt-get install -y build-essential libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
  sudo apt-get autoremove -y
EOF

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container stop redis-${empresa_delete}
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Node.js e PostgreSQL...${GRAY_LIGHT}\n\n"

  # Instalação do NVM e Node.js
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Carregar NVM no ambiente atual

  nvm install 20.17.0
  nvm alias default 20.17.0
  npm install -g npm@10.8.0

  # Instalação do PostgreSQL
  echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /usr/share/keyrings/postgresql.gpg >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y postgresql-16

  # Configuração do fuso horário
  sudo timedatectl set-timezone America/Sao_Paulo
}

#######################################
# installs fail2ban
# Arguments:
#   None
#######################################
system_fail2ban_install() {
  print_banner
  printf "${WHITE} 💻 Instalando fail2ban...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
sudo apt install fail2ban -y && sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
EOF

  sleep 2
}
#######################################
# configure fail2ban
# Arguments:
#   None
#######################################
system_fail2ban_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o fail2ban...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
EOF

  sleep 2
}
#######################################
# configure firewall
# Arguments:
#   None
#######################################
system_firewall_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o firewall...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
EOF

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y apt-transport-https \
                 ca-certificates curl \
                 software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  apt install -y docker-ce
EOF

  sleep 2
}

##################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o pm2...${GRAY_LIGHT}\n\n"

  sudo su - root <<EOF
  npm install -g pm2@latest
EOF

  sleep 2

  printf "${WHITE} ✔️ pm2 instalado com sucesso!${GRAY_LIGHT}\n"

  sleep 2

}


#######################################
# set timezone
# Arguments:
#   None
#######################################
system_set_timezone() {
  print_banner
  printf "${WHITE} 💻 Definindo a timezone...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  timedatectl set-timezone America/Sao_Paulo
EOF

  sleep 2
}


#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y nginx
  rm /etc/nginx/sites-enabled/default
  rm /etc/nginx/sites-available/default
EOF

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF
cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot, Já estamos perto do fim...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2
}

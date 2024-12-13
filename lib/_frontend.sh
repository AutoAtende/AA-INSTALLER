#!/bin/bash
# 
# functions for setting up app frontend

#######################################
# installed node packages
# Arguments:
#   None
#######################################
frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm install --legacy-peer-deps
EOF

  sleep 2
}

#######################################
# compiles frontend code
# Arguments:
#   None
#######################################
frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm run build
  rm -rf src
EOF

  sleep 2

}

#######################################
# sets frontend environment variables
# Arguments:
#   None
#######################################
frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - deploy << EOF1
  cat <<-EOF2 > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_BACKEND_PROTOCOL=https
REACT_APP_BACKEND_HOST=${backend_hostname}
REACT_APP_BACKEND_PORT=443
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_FACEBOOK_APP_ID=
EOF2
EOF1

  sleep 2

}

#######################################
# sets up nginx for frontend
# Arguments:
#   None
#######################################
frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  frontend_hostname=$(echo "$frontend_url" | sed 's/https:\/\///')
  date_gmt=$(date -u +"%a, %d %b %Y %T GMT")

  sudo bash << EOF
cat > /etc/nginx/sites-available/${instancia_add}-frontend << EOF2
server {
  server_name $frontend_hostname;
  
  root /home/deploy/${instancia_add}/frontend/build;
  index index.html;

  location / {
      try_files \$uri \$uri/ /index.html;
  }

  # BLoquear solicitacoes de arquivos do GitHub
  location ~ /\.git {
    deny all;
  }

  # X-Frame-Options is to prevent from clickJacking attack
  add_header X-Frame-Options SAMEORIGIN;

  # disable content-type sniffing on some browsers.
  add_header X-Content-Type-Options nosniff;

  # This header enables the Cross-site scripting (XSS) filter
  add_header X-XSS-Protection "1; mode=block";

  # This will enforce HTTP browsing into HTTPS and avoid ssl stripping attack
  add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";

  add_header Referrer-Policy "no-referrer-when-downgrade";

  # Enables response header of "Vary: Accept-Encoding"
  gzip_vary on;
}
EOF2
EOF

sudo ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled


  sleep 2
}

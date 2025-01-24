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

  frontend_hostname=$(echo "${frontend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/${instancia_add}-frontend << 'END'
server {
  server_name $frontend_hostname;
  
  root /home/deploy/${instancia_add}/frontend/build;
  index index.html;

  # Bloquear solicitacoes de arquivos do GitHub
  location ~ /\.git {
    deny all;
  }

 # Configuração específica para index.html - sempre buscar nova versão
    location = /index.html {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate" always;
        add_header Pragma "no-cache" always;
    }

    # Configuração para arquivos com hash no nome (gerados pelo Webpack)
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable, max-age=31536000" always;
        access_log off;
    }

    # Configuração para chunks do Webpack
    location ~* \.([a-f0-9]{8,32})\.(js|css)$ {
        expires 1y;
        add_header Cache-Control "public, immutable, max-age=31536000" always;
        access_log off;
        tcp_nodelay on;
    }

    # Manifest e outros arquivos de configuração
    location = /manifest.json {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate" always;
        add_header Pragma "no-cache" always;
    }

    # Assets sem hash no nome
    location ~* \.(ico|pdf|flv|jpg|jpeg|png|gif|svg|js|css|swf)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000" always;
        tcp_nodelay on;
    }

    # Regra principal para roteamento do React
    location / {
        try_files \$uri /index.html;
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate" always;
        add_header Pragma "no-cache" always;
    }

    # Configurações de compressão otimizadas
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types
        application/javascript
        application/json
        application/x-javascript
        application/xml
        text/css
        text/javascript
        text/plain
        text/xml;

    # Buffer sizes
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;

    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;

    # SSL optimization
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_prefer_server_ciphers on;

}
END

ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
EOF

  sleep 2
}

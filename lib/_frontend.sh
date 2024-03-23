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
  npm install
  npm install express helmet express-rate-limit
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
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-frontend
  git pull
  cd /home/deploy/${empresa_atualizar}/frontend
  npm install
  npm install express helmet express-rate-limit
  rm -rf build
  npm run build
  pm2 start ${empresa_atualizar}-frontend
  pm2 save
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

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_PAGE_TITLE=AutoAtende
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_TRIALEXPIRATION=7
REACT_APP_PLANIDDEFAULT= 
REACT_APP_LOGO= 
REACT_APP_COLOR_TOOLBAR= 
REACT_APP_COPYRIGHT= 
REACT_APP_COPYRIGHT_YEAR= 
REACT_APP_COPYRIGHT_URL= 
REACT_APP_MANUAL_URL= 
REACT_APP_FACEBOOK_APP_ID=
PORT={$frontend_port} 
[-]EOF
EOF

  sleep 2

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/server.js
const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const path = require("path");

const app = express();

// Aplicar o Helmet para segurança básica
app.use(helmet());

// Limitador de taxa de requisições para prevenir ataques de força bruta e DDoS
const limiter = rateLimit({
	windowMs: 15 * 60 * 1000, // 15 minutos
	max: 100, // limite cada IP a 100 requisições por janela (aqui definida em 15 minutos)
	standardHeaders: true, // Retorna informações de limite de taxa nos cabeçalhos `RateLimit-*`
	legacyHeaders: false, // Desabilita os cabeçalhos `X-RateLimit-*`
});

// Aplicar o limitador de taxa a todas as requisições
app.use(limiter);

// Servir arquivos estáticos de forma segura
app.use(express.static(path.join(__dirname, "build"), {
	dotfiles: 'deny', // Não permitir acesso a arquivos dotfiles
	index: false, // Desabilitar listagem de diretório
}));

// Rota para servir o frontend
app.get("/*", function (req, res) {
	res.sendFile(path.join(__dirname, "build", "index.html"), {
		dotfiles: 'deny', // Mesma regra para arquivos dotfiles aqui
	});
});

// Iniciar o servidor
const PORT = process.env.PORT || ${frontend_port};
app.listen(PORT, () => console.log(`Servidor rodando na porta ${frontend_port}`));

[-]EOF
EOF

  sleep 2
}

#######################################
# starts pm2 for frontend
# Arguments:
#   None
#######################################
frontend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  pm2 start server.js --name ${instancia_add}-frontend
  pm2 save
EOF

 sleep 2
  
  sudo su - root <<EOF
   pm2 startup
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF
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

  location / {
    proxy_pass http://127.0.0.1:${frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END

ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
EOF

  sleep 2
}

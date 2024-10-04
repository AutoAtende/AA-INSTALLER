#!/bin/bash

# Lista de possíveis nomes de diretórios antigos
PASTAS_ANTIGAS=("autoatende" "atende" "automax" "autotende")

# Caminho do diretório base (você pode ajustar esse caminho conforme necessário)
CAMINHO_BASE="/home/deploy"

# Encontrar a pasta antiga
PASTA_ANTIGA=""
for PASTA in "${PASTAS_ANTIGAS[@]}"; do
  if [ -d "$CAMINHO_BASE/$PASTA" ]; then
    PASTA_ANTIGA="$PASTA"
    echo "Pasta antiga encontrada: $PASTA_ANTIGA"
    break
  fi
done

# Se a pasta antiga não foi encontrada, solicitar ao usuário
if [ -z "$PASTA_ANTIGA" ]; then
  echo "Nenhuma pasta pré-definida encontrada."
  read -p "Por favor, digite o nome da pasta antiga: " PASTA_ANTIGA
  # Verificar se a pasta inserida pelo usuário existe
  if [ ! -d "$CAMINHO_BASE/$PASTA_ANTIGA" ]; then
    echo "A pasta $PASTA_ANTIGA não foi encontrada. Verifique o nome e tente novamente."
    exit 1
  fi
fi

# Instalar build-essential
echo "Instalando build-essential..."
sudo apt update
sudo apt install -y build-essential

# Alternando para usuário deploy
sudo su deploy
cd

# Pausar o PM2
echo "Parando o PM2..."
pm2 stop all

# Clonar o novo repositório
echo "Clonando o repositório novo..."
git clone https://github.com/AutoAtende/AA-APP.git /tmp/AA-APP

# Copiar arquivos .env e pasta public
echo "Copiando arquivos .env e pasta public..."
cp "$CAMINHO_BASE/$PASTA_ANTIGA/backend/.env" "/tmp/AA-APP/backend/.env"
cp "$CAMINHO_BASE/$PASTA_ANTIGA/frontend/.env" "/tmp/AA-APP/frontend/.env"
cp -r "$CAMINHO_BASE/$PASTA_ANTIGA/backend/public" "/tmp/AA-APP/backend/public"

mv $PASTA_ANTIGA bkp20241004

# Renomear o novo clone para o nome do sistema antigo
echo "Renomeando o novo clone para o nome do sistema antigo..."
mv /tmp/AA-APP "$CAMINHO_BASE/$PASTA_ANTIGA"

# Reiniciar o PM2
echo "Reiniciando o PM2..."
pm2 restart all

echo "Atualização concluída com sucesso!"

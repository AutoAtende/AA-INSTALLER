#!/bin/bash
# Desenvolvido por: Eduardo Maronas Monks
# Script para criacao de dumps do Postgres
# Postgres:
# Dever ser permitido o localhost como trust
# no arquivo pg_hba.conf
# Armazenamento remoto:
# Devera ser permitido ao usuario root local acessar por
# SSH, com certificado no host remoto, com o usuario onde
# sera o armazenamento dos dumps 

# -- Variaveis de Ambiente ---

DATA=$(date +%Y-%m-%d_%H-%M)

# Diretorio local de backup
PBACKUP="/backup"

# Diretorio remoto de backup
RBACKUP="/backup/dumps"

# Usuario e host de destino
SDESTINO="dumper@IP_remoto"

HOST=$(hostname)

# Envio de e-mail com a confirmacao do backup
EMAIL="gerencia@minhaempresa.com.br"

# -- LIMPEZA ---
# Os arquivos dos ultimos 5 dias serao mantidos
NDIAS="5"

executar_backup() {
print_banner
printf "${WHITE} 💻 Vamos realizar o backup do banco de dados..${GRAY_LIGHT}"
printf "\n\n"

if [ ! -d ${PBACKUP} ]; then
	
	printf ""
	printf " A pasta de backup nao foi encontrada!"
	mkdir -p ${PBACKUP}
	printf " Iniciando Tarefa de backup..."
	printf ""

else

	printf ""
	printf " Rotacionando backups mais antigos que $NDIAS"
	printf ""

	find ${PBACKUP} -type d -mtime +$NDIAS -exec rm -rf {} \;

fi

printf "${WHITE} 💻 Iniciando o backup..${GRAY_LIGHT}"
printf "\n\n"
printf "Iniciando o backup" |mutt -s "Backup $HOST Iniciado" $EMAIL

sleep 2

if [ ! -d $PBACKUP/$DATA/postgres ]; then

        mkdir -p $PBACKUP/$DATA/postgres

fi

chown -R postgres:postgres $PBACKUP/$DATA/postgres/

su - postgres -c "vacuumdb -a -f -z"

for basepostgres in $(su - postgres -c "psql -l" | grep -v template0|grep -v template1|grep "|" |grep -v Owner |awk '{if ($1 != "|" && $1 != "Nome") print $1}'); do

        su - postgres -c "pg_dump $basepostgres > $PBACKUP/$DATA/postgres/$basepostgres.txt"

        cd $PBACKUP/$DATA/postgres/

        tar -czvf $basepostgres.tar.gz $basepostgres.txt
		
	sha1sum $basepostgres.tar.gz > $basepostgres.sha1

        rm -rf $basepostgres.txt

	cd /

done

sleep 2

# Backup de usuarios do Postgresql
su - postgres -c "pg_dumpall --globals-only -S postgres > $PBACKUP/$DATA/postgres/usuarios.sql"

DAYOFWEEK=$(date +"%u")
if [ "${DAYOFWEEK}" -eq 7  ];  then

  # Otimizacao das tabelas
  su - postgres -c "vacuumdb -a -f -z"
  
  # Backup de todo o banco
  su - postgres -c "pg_dumpall > $PBACKUP/$DATA/postgres/postgres_tudo.txt"
  
  cd ${PBACKUP}/${DATA}/postgres/

  tar -czvf postgres_tudo.tar.gz postgres_tudo.txt
   
  sha1sum postgres_tudo.tar.gz > postgres_tudo.sha1

  rm -f postgres_tudo.txt  

fi

sleep 2

# Verifica se existe um diretorio com o nome do host no host remoto
if [ $(ssh  $SDESTINO "ls ${RBACKUP}" |grep -i $HOST |wc -l) = 0 ]; then

        ssh  $SDESTINO "mkdir -p ${RBACKUP}/$HOST"

fi

# Copiar para o host de destino os dumps gerados localmente
scp -o StrictHostKeyChecking=no -r $PBACKUP/$DATA $SDESTINO:${RBACKUP}/$HOST/

printf "${WHITE} 💻 Backup realizado com sucesso...${GRAY_LIGHT}"
printf "\n\n"
printf "Backup finalizado" |mutt -s "Backup $HOST Finalizado!" $EMAIL

sleep 2
}

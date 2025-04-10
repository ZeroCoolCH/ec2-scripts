#!/bin/bash

# Script: setup_zerohash_service.sh
# Descrição: Configura um serviço systemd para rodar o zerohash_finder continuamente em uma instância EC2 (Ubuntu).
# Autor: [Seu Nome]
# Data: 10 de Abril de 2025
# Licença: MIT (ou a que preferir)

# --- Configurações Personalizáveis ---
PROGRAM_PATH="/zerohash/target/release/zerohash_finder"  # Caminho do binário
PROGRAM_ARGS="--address 19vkiEajfhuZ8bs8Zu2jgmC6oqZbWqhxhG --range-start 1000000000000 --range-end 1ffffffffffff --random"  # Argumentos do programa
WORKING_DIR="/zerohash/target/release"  # Diretório de trabalho
SERVICE_NAME="zerohash"  # Nome do serviço
USER="ubuntu"  # Usuário padrão do Ubuntu na EC2, ajuste se necessário
LOG_OUTPUT="/var/log/zerohash.log"  # Arquivo de log de saída
LOG_ERROR="/var/log/zerohash_err.log"  # Arquivo de log de erro

# --- Verificações Iniciais ---
if [ ! -f "$PROGRAM_PATH" ]; then
    echo "Erro: O arquivo $PROGRAM_PATH não foi encontrado. Verifique o caminho e tente novamente."
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado como root (use sudo)."
    exit 1
fi

# --- Passo 1: Criar o Script de Execução ---
echo "Criando script de execução em /zerohash/run_zerohash.sh..."
cat <<EOT > /zerohash/run_zerohash.sh
#!/bin/bash
$PROGRAM_PATH $PROGRAM_ARGS
EOT

chmod +x /zerohash/run_zerohash.sh
echo "Script de execução criado com sucesso."

# --- Passo 2: Criar o Arquivo de Serviço systemd ---
echo "Criando arquivo de serviço systemd em /etc/systemd/system/${SERVICE_NAME}.service..."
cat <<EOT > /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=ZeroHash Finder Service
After=network.target

[Service]
ExecStart=/zerohash/run_zerohash.sh
WorkingDirectory=$WORKING_DIR
Restart=always
User=$USER
StandardOutput=file:$LOG_OUTPUT
StandardError=file:$LOG_ERROR

[Install]
WantedBy=multi-user.target
EOT
echo "Arquivo de serviço criado com sucesso."

# --- Passo 3: Configurar Arquivos de Log ---
echo "Configurando arquivos de log..."
touch "$LOG_OUTPUT" "$LOG_ERROR"
chown "$USER":"$USER" "$LOG_OUTPUT" "$LOG_ERROR"
echo "Arquivos de log criados em $LOG_OUTPUT e $LOG_ERROR."

# --- Passo 4: Ativar e Iniciar o Serviço ---
echo "Recarregando configurações do systemd..."
systemctl daemon-reload

echo "Ativando o serviço para iniciar no boot..."
systemctl enable "${SERVICE_NAME}.service"

echo "Iniciando o serviço..."
systemctl start "${SERVICE_NAME}.service"

# --- Passo 5: Verificar o Status ---
echo "Verificando o status do serviço..."
systemctl status "${SERVICE_NAME}.service"

# --- Instruções Finais ---
echo ""
echo "Configuração concluída!"
echo " - Para verificar os logs em tempo real:"
echo "   tail -f $LOG_OUTPUT"
echo " - Para erros:"
echo "   tail -f $LOG_ERROR"
echo " - Para parar o serviço:"
echo "   sudo systemctl stop ${SERVICE_NAME}.service"
echo " - Para reiniciar o serviço:"
echo "   sudo systemctl restart ${SERVICE_NAME}.service"
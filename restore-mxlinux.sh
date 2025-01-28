#!/bin/bash

# Verifica permissões de root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root."
  exit
fi

# Define o diretório de backup no diretório do usuário original
USER_HOME=$(eval echo "~$SUDO_USER") # Diretório do usuário original
BACKUP_DIR="$USER_HOME/backup"

echo "Iniciando restauração a partir do diretório $BACKUP_DIR..."

# 1. Restaurar lista de pacotes
if [ -f "$BACKUP_DIR/packages.list" ]; then
  sudo dpkg --set-selections < "$BACKUP_DIR/packages.list"
  sudo apt-get dselect-upgrade -y
  echo "Pacotes restaurados com sucesso."
else
  echo "Arquivo $BACKUP_DIR/packages.list não encontrado. Pulei essa etapa."
fi

# 2. Restaurar configurações do sistema
if [ -f "$BACKUP_DIR/etc-backup.tar.gz" ]; then
  tar -xzvf "$BACKUP_DIR/etc-backup.tar.gz" -C /
  echo "Configurações do sistema restauradas."
else
  echo "Arquivo $BACKUP_DIR/etc-backup.tar.gz não encontrado. Pulei essa etapa."
fi

# 3. Restaurar configurações do XFCE e diretório home
if [ -f "$BACKUP_DIR/xfce-configs.tar.gz" ]; then
  tar -xzvf "$BACKUP_DIR/xfce-configs.tar.gz" -C "$USER_HOME"
  echo "Configurações do XFCE restauradas."
else
  echo "Arquivo $BACKUP_DIR/xfce-configs.tar.gz não encontrado. Pulei essa etapa."
fi

if [ -f "$BACKUP_DIR/home-configs.tar.gz" ]; then
  tar -xzvf "$BACKUP_DIR/home-configs.tar.gz" -C "$USER_HOME"
  echo "Configurações pessoais restauradas."
else
  echo "Arquivo $BACKUP_DIR/home-configs.tar.gz não encontrado. Pulei essa etapa."
fi

# 4. Restaurar configurações do painel do XFCE
if [ -f "$BACKUP_DIR/xfce4-panel-config.xml" ]; then
  xfconf-query -c xfce4-panel -p / -R -F -f < "$BACKUP_DIR/xfce4-panel-config.xml"
  echo "Configurações do painel do XFCE restauradas."
else
  echo "Arquivo $BACKUP_DIR/xfce4-panel-config.xml não encontrado. Pulei essa etapa."
fi

# 5. Restaurar configurações do GRUB
if [ -f "$BACKUP_DIR/grub.cfg" ] && [ -f "$BACKUP_DIR/grub-default" ]; then
  cp "$BACKUP_DIR/grub.cfg" /boot/grub/grub.cfg
  cp "$BACKUP_DIR/grub-default" /etc/default/grub
  sudo update-grub
  echo "Configurações do GRUB restauradas."
else
  echo "Arquivos do GRUB não encontrados. Pulei essa etapa."
fi

echo "Restauração concluída."

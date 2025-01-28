#!/bin/bash

# Verifica permissões de root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root."
  exit
fi

# Define o diretório de backup no diretório do usuário original
USER_HOME=$(eval echo "~$SUDO_USER") # Diretório do usuário original
BACKUP_DIR="$USER_HOME/backup"

# Cria o diretório de backup, se não existir
mkdir -p "$BACKUP_DIR"

echo "Iniciando backup no diretório $BACKUP_DIR..."

# 1. Backup dos pacotes instalados
dpkg --get-selections > "$BACKUP_DIR/packages.list"
echo "Lista de pacotes salva em $BACKUP_DIR/packages.list"

# 2. Backup das configurações do sistema (/etc)
tar -czvf "$BACKUP_DIR/etc-backup.tar.gz" /etc
echo "Configurações do sistema salvas em $BACKUP_DIR/etc-backup.tar.gz"

# 3. Backup das configurações do XFCE e diretório home
tar -czvf "$BACKUP_DIR/xfce-configs.tar.gz" "$USER_HOME/.config/xfce4" "$USER_HOME/.config/Thunar" "$USER_HOME/.config/xfce4-panel"
tar -czvf "$BACKUP_DIR/home-configs.tar.gz" "$USER_HOME"/.* --exclude="$BACKUP_DIR"
echo "Configurações pessoais salvas em $BACKUP_DIR/xfce-configs.tar.gz e $BACKUP_DIR/home-configs.tar.gz"

# 4. Exporta configurações específicas do painel
xfconf-query -c xfce4-panel -p / -R -X > "$BACKUP_DIR/xfce4-panel-config.xml"
echo "Configurações do painel XFCE salvas em $BACKUP_DIR/xfce4-panel-config.xml"

# 5. Backup do GRUB
cp /boot/grub/grub.cfg "$BACKUP_DIR/grub.cfg"
cp /etc/default/grub "$BACKUP_DIR/grub-default"
echo "Configurações do GRUB salvas em $BACKUP_DIR"

echo "Backup completo salvo no diretório $BACKUP_DIR"

#!/bin/bash

echo "Iniciando otimização do XFCE4 para hardware antigo..."

# Atualizar sistema
echo "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

# Remover serviços desnecessários
echo "Removendo serviços que consomem recursos..."
sudo systemctl disable cups-browsed.service
sudo systemctl disable bluetooth.service
sudo systemctl disable ModemManager.service
sudo systemctl disable avahi-daemon.service

# Ajustar compositor XFCE
echo "Desabilitando efeitos visuais no compositor do XFCE..."
xfconf-query -c xfwm4 -p /general/use_compositing -s false

# Ajustar o Thunar
echo "Desabilitando monitoramento automático de pastas no Thunar..."
xfconf-query -c thunar -p /misc-monitor-remote-devices -s false
xfconf-query -c thunar -p /misc-volume-management -s false

# Remover serviços não essenciais do XFCE
echo "Removendo plugins desnecessários da barra de tarefas..."
xfce4-panel --quit
rm -f ~/.config/xfce4/panel/*.desktop
xfce4-panel &

# Otimizar inicialização
echo "Reduzindo processos na inicialização..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p $AUTOSTART_DIR

for SERVICE in "xfce4-notifyd" "polkit-gnome-authentication-agent-1" "update-notifier"; do
  if [ -f "/etc/xdg/autostart/$SERVICE.desktop" ]; then
    cp /etc/xdg/autostart/$SERVICE.desktop $AUTOSTART_DIR
    echo "Hidden=true" >> $AUTOSTART_DIR/$SERVICE.desktop
  fi
done

# Ajustar swap para desempenho em baixa memória
echo "Ajustando swap para evitar travamentos..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configurar o gerenciador de energia
echo "Ajustando configurações de energia..."
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inhibit-sleep-mode -s true

# Instalar pacotes leves e remover os pesados
echo "Instalando pacotes mais leves e removendo os pesados..."
sudo apt install --no-install-recommends -y lightdm-gtk-greeter gvfs-backends
sudo apt remove -y orage pulseaudio parole

# Limpeza do sistema
echo "Limpando pacotes desnecessários..."
sudo apt autoremove -y
sudo apt autoclean

echo "Otimização concluída! Reinicie o sistema para aplicar todas as mudanças."

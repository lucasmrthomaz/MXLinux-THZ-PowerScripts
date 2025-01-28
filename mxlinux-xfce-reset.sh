#!/bin/bash

# Verificar se o script está sendo executado como root ou com sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root ou com sudo!"
    exit 1
fi

# Função para exibir mensagens
show_message() {
    echo -e "\n=== $1 ===\n"
}

# Função para confirmar ações
confirm_action() {
    read -p "$1 (s/n): " resposta
    [[ "$resposta" =~ ^[Ss]$ ]] && return 0 || return 1
}

# Início do script
show_message "Este script irá resetar o ambiente do MX Linux para XFCE e remover outros ambientes gráficos como GNOME e KDE."

# Confirmação do usuário
if ! confirm_action "Você deseja continuar? Isso removerá pacotes de KDE, GNOME e outros ambientes."; then
    show_message "Operação cancelada pelo usuário."
    exit 1
fi

# Backup das configurações
show_message "Fazendo backup das configurações do XFCE..."
mkdir -p ~/xfce_backup
cp -r ~/.config/xfce4 ~/xfce_backup/
cp -r ~/.cache/sessions ~/xfce_backup/
show_message "Backup das configurações salvo em ~/xfce_backup/"

# Atualiza o sistema e reinstala o XFCE
show_message "Reinstalando o ambiente XFCE..."
sudo apt update && sudo apt install --reinstall -y mx-system mx-goodies xfce4 xfce4-goodies || {
    echo "Erro: Falha ao reinstalar o XFCE."
    exit 1
}

# Verifica e remove KDE se instalado
show_message "Verificando pacotes do KDE..."
if dpkg -l | grep -q 'kde'; then
    show_message "KDE encontrado. Removendo..."
    sudo apt purge -y '*kde*' '*plasma*'
else
    show_message "KDE não encontrado."
fi

# Verifica e remove GNOME se instalado
show_message "Verificando pacotes do GNOME..."
if dpkg -l | grep -q 'gnome'; then
    show_message "GNOME encontrado. Removendo..."
    sudo apt purge -y '*gnome*'
else
    show_message "GNOME não encontrado."
fi

# Remove pacotes órfãos
show_message "Removendo pacotes órfãos..."
sudo apt autoremove --purge -y || echo "Aviso: Falha ao remover pacotes órfãos."

# Verificação e remoção de pacotes órfãos com deborphan
show_message "Verificando pacotes órfãos com deborphan..."
orphaned_packages=$(deborphan)
if [ -n "$orphaned_packages" ]; then
    show_message "Pacotes órfãos encontrados: $orphaned_packages"
    sudo apt-get remove --purge -y $orphaned_packages
else
    show_message "Nenhum pacote órfão encontrado."
fi

# Limpeza de cache do APT
show_message "Limpando cache do APT..."
sudo apt clean

# Limpa as configurações antigas do XFCE
show_message "Limpando configurações antigas do XFCE..."
rm -rf ~/.config/xfce4 ~/.cache/sessions || echo "Aviso: Não foi possível limpar todas as configurações do usuário."

# Reconfigura o ambiente gráfico
show_message "Reconfigurando o XFCE..."
xfce4-panel --restart || echo "Aviso: Falha ao reiniciar o painel do XFCE."

# Configuração do LightDM
if dpkg -l | grep -q 'lightdm'; then
    if confirm_action "Deseja configurar o LightDM para iniciar apenas o XFCE?"; then
        sudo sed -i 's/^user-session=.*/user-session=xfce/' /etc/lightdm/lightdm.conf || echo "Aviso: Falha ao configurar o LightDM."
    fi
else
    show_message "LightDM não encontrado. Pulando a configuração do LightDM."
fi

# Finalização
show_message "Processo concluído com sucesso!"
show_message "Reinicie o sistema para garantir que todas as alterações sejam aplicadas corretamente."

# Reinício opcional
if confirm_action "Deseja reiniciar o sistema agora?"; then
    sudo reboot
fi

exit 0

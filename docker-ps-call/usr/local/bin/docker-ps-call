#!/bin/bash

# Lista os containers e gera o menu principal
menu_principal() {
  sudo docker ps --format '{{.ID}} {{.Names}}' | awk '{print $2, $1}' > /tmp/container_list.txt

  if [ ! -s /tmp/container_list.txt ]; then
    dialog --msgbox "Nenhum container em execução." 10 40
    clear
    exit 1
  fi

  local selection=$(dialog --menu "Selecione o container:" 20 60 10 $(cat /tmp/container_list.txt) 2>&1 >/dev/tty)
  clear

  if [ -n "$selection" ]; then
    menu_secundario "$selection"
  else
    echo "Saindo..."
    exit 0
  fi
}

# Menu secundário: ações no container selecionado
menu_secundario() {
  local container_id="$1"

  while true; do
    local action=$(dialog --menu "Ações para o container: $container_id" 20 60 10 \
      1 "Executar (bash)" \
      2 "Listar (logs)" \
      3 "Reiniciar (confirmar)" 2>&1 >/dev/tty)

    clear

    case "$action" in
      1) executar_bash "$container_id" ;;
      2) listar_logs "$container_id" ;;
      3) confirmar_reinicio "$container_id" ;;
      *) break ;;  # Esc volta ao menu principal
    esac
  done
}

# Função: Executar bash no container
executar_bash() {
  echo "Abrindo bash no container $1..."
  sudo docker exec -it "$1" bash
}

# Função: Listar logs em tempo real
listar_logs() {
  echo "Exibindo logs em tempo real do container $1 (Ctrl+C para sair)..."
  sleep 1
  sudo docker logs -f --tail=20 "$1"
}

# Função: Confirmar reinício do container
confirmar_reinicio() {
  dialog --yesno "Tem certeza que deseja reiniciar o container $1?" 10 40
  if [ $? -eq 0 ]; then
    echo "Reiniciando o container $1..."
    sudo docker restart "$1"
    echo "Container $1 reiniciado com sucesso."
    sleep 2
  else
    echo "Reinício cancelado."
    sleep 1
  fi
}

# Inicia o menu principal
while true; do
  menu_principal
done

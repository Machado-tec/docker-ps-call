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
# Função: Inspecionar container
inspecionar_container() {
  local container_id="$1"
  local container_inspect=$(sudo docker inspect "$container_id")

  local container_name=$(echo "$container_inspect" | jq -r '.[0].Name' | sed 's|/||')
  local image=$(echo "$container_inspect" | jq -r '.[0].Config.Image')
  local network_name=$(echo "$container_inspect" | jq -r '.[0].NetworkSettings.Networks | keys[]')
  local ip_address=$(echo "$container_inspect" | jq -r ".[0].NetworkSettings.Networks[\"$network_name\"].IPAddress")
  local hostname=$(echo "$container_inspect" | jq -r '.[0].Config.Hostname')
  local compose_file=$(echo "$container_inspect" | jq -r '.[0].Config.Labels["com.docker.compose.project.config_files"]')
  local started_at=$(echo "$container_inspect" | jq -r '.[0].State.StartedAt')

  # Calcula o uptime
  local uptime=$(date -u -d "@$(($(date +%s) - $(date -d "$started_at" +%s)))" +"%H:%M:%S")

  # Exibe as informações
  dialog --msgbox "Container: $container_name
Imagem: $image
Rede: $network_name
IP: $ip_address
Hostname: $hostname
Compose File: $compose_file
Uptime: $uptime" 15 70
  clear
}

# Função: Submenu para commit e save
submenu_commit_save() {
  local container_id="$1"

  while true; do
    local action=$(dialog --menu "Submenu - Commit e Save da imagem" 20 60 10 \
      1 "Commit da imagem" \
      2 "Save da imagem" 2>&1 >/dev/tty)

    clear

    case "$action" in
      1) commit_imagem "$container_id" ;;
      2) save_imagem "$container_id" ;;
      *) break ;;  # Esc volta ao menu principal
    esac
  done
}

# Função: Realizar commit da imagem (com nome sugerido do container)
commit_imagem() {
  local container_id="$1"
  local container_name=$(sudo docker inspect --format='{{.Name}}' "$container_id" | sed 's|/||')
  local timestamp=$(date +%Y-%m-%d-%H%M)

  # Nome padrão baseado no container, permite edição
  local image_name=$(dialog --inputbox "Digite o nome da nova imagem:" 10 40 "${container_name}" 2>&1 >/dev/tty)

  if [ -n "$image_name" ]; then
    echo "Realizando commit da imagem..."
    sudo docker commit "$container_id" "${image_name}:${timestamp}"
    dialog --msgbox "Imagem '${image_name}:${timestamp}' criada com sucesso." 10 40
  else
    dialog --msgbox "Nome da imagem não pode ser vazio. Operação cancelada." 10 40
  fi

  clear
}

# Função: Realizar save da imagem
save_imagem() {
  # Lista as imagens disponíveis, filtrando pelo container_id
  local images_list=$(sudo docker images --format '{{.Repository}}:{{.Tag}}' | grep "${container_id}")

  if [ -z "$images_list" ]; then
    dialog --msgbox "Nenhuma imagem disponível para save." 10 40
    return
  fi

  # Exibe as opções para selecionar apenas uma coluna (imagem)
  local options=""
  while IFS= read -r image; do
    options+="$image $image "
  done <<< "$images_list"

  local selected_image=$(dialog --menu "Selecione a imagem para salvar:" 20 60 10 $options 2>&1 >/dev/tty)
  clear

  if [ -n "$selected_image" ]; then
    # Nome do arquivo de saída
    local sanitized_image_name=$(echo "$selected_image" | tr ':' '_')
    local output_file="./${sanitized_image_name}.tgz"

    echo "Salvando a imagem '${selected_image}' em '${output_file}'..."
    sudo docker save "$selected_image" > "$output_file"

    if [ $? -eq 0 ]; then
      echo "Gerando checksum MD5 para '${output_file}'..."
      sudo md5sum "$output_file" > "${output_file}.md5sum"

      if [ $? -eq 0 ]; then
        dialog --msgbox "Imagem '${selected_image}' salva com sucesso como '${output_file}'.
Checksum MD5 gerado em '${output_file}.md5sum'." 10 50
      else
        dialog --msgbox "Imagem salva, mas houve um erro ao gerar o checksum MD5." 10 40
      fi
    else
      dialog --msgbox "Erro ao salvar a imagem '${selected_image}'." 10 40
    fi
  else
    dialog --msgbox "Nenhuma imagem selecionada. Operação cancelada." 10 40
  fi

  clear
}
# Menu secundário: ações no container selecionado
menu_secundario() {
  local container_id="$1"

  while true; do
    local action=$(dialog --menu "Ações para o container: $container_id" 20 60 10 \
      1 "Executar (bash)" \
      2 "Listar (logs)" \
      3 "Reiniciar (confirmar)" \
      4 "Inspecionar (informações filtradas)" \
      5 "Commit e Save da imagem" 2>&1 >/dev/tty)

    clear

    case "$action" in
      1) executar_bash "$container_id" ;;
      2) listar_logs "$container_id" ;;
      3) confirmar_reinicio "$container_id" ;;
      4) inspecionar_container "$container_id" ;;
      5) submenu_commit_save "$container_id" ;;
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

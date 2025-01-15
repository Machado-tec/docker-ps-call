#!/bin/bash

# Lista os containers e gera o menu principal
FILE=/tmp/container_list.txt.$$

# Função para obter o cabeçalho dinâmico
get_header() {
  local version="DPS:0.1 - By Xadrak"
  local hostname=$(hostname)
  echo "$version $separator Host: '$hostname'"
}

# Função: Exibir status dos containers
exibir_status_containers() {
  echo "Exibindo status de todos os containers em execução (CTRL+C para sair)..."
  sleep 1
  sudo docker stats
  echo "Pressione ENTER para retornar ao DPS"
  read
}
menu_principal() {
  sudo docker ps --format '{{.ID}} {{.Names}}' | awk '{print $2, $1}' | sort > $FILE 

  if [ ! -s $FILE  ]; then
    dialog --msgbox "Nenhum container em execução." 10 40
    clear
    exit 1
  fi



  local selection=$(dialog  --title "$(get_header)" --menu "Selecione o container:" 20 60 10 $(cat $FILE ) 2>&1 >/dev/tty)
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

submenu_dps_json() {
  local container_id="$1"

  # Verifica se o arquivo dps.json existe no container
  if sudo docker exec "$container_id" test -f /root/dps.json; then
    # Lê o conteúdo do dps.json diretamente no container
    local json_content=$(sudo docker exec "$container_id" cat /root/dps.json)

    # Valida se o JSON está bem formatado
    if ! echo "$json_content" | jq empty; then
      dialog --msgbox "O arquivo '/root/dps.json' está mal formatado. Verifique o conteúdo." 10 40
      return
    fi

    # Gera as opções do menu a partir do JSON
    local menu_items=()
    while IFS= read -r key; do
      # Adiciona pares (chave e Nome) ao array, garantindo que a chave seja tratada como string
      local name=$(echo "$json_content" | jq -r ".\"$key\".Name")
      menu_items+=("$key" "$name")
    done < <(echo "$json_content" | jq -r 'keys[]')

    # Cria o menu com os comandos personalizados
    local action=$(dialog --menu "Comandos Customizados" 20 60 10 "${menu_items[@]}" 2>&1 >/dev/tty)
    clear

    if [ -n "$action" ]; then
      # Obtém o comando correspondente à seleção
      local command=$(echo "$json_content" | jq -r --arg key "$action" '.[$key | tostring].Command')

      if [ -n "$command" ] && [ "$command" != "null" ]; then
        # Executa o comando no container
        dialog --msgbox "Executando: $command" 10 40
        clear 
        sudo docker exec -it "$container_id" bash -c "$command"
        echo "Pressione ENTER para retornar ao dps"
        read 
      else
        dialog --msgbox "Comando não encontrado para a opção selecionada." 10 40
      fi
    else
      dialog --msgbox "Nenhuma opção selecionada." 10 40
    fi
  else
    dialog --msgbox "Arquivo '/root/dps.json' não encontrado no container $container_id." 10 40
  fi

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
    local action=$(dialog --title "$(get_header)" \
      --menu "Ações para o container: $container_id" 20 70 10 \
    0 "Executar (bash)" \
    1 "Customizados /root/dps.json" 2>&1 >/dev/tty \
    2 "Listar    (logs)" \
    3 "Reiniciar (confirmar)" \
    4 "Pause     (confirmar)" \
    5 "UnPause   (confirmar)" \
    6 "Stop      (confirmar)" \
    7 "Start     (confirmar)" \
    8 "Inspecionar (informações filtradas)" \
    9 "Commit e Save da imagem" \
   10 "Exibir status (docker stats)")

    clear

    case "$action" in
      0) executar_bash "$container_id" ;;
      1) submenu_dps_json "$container_id" ;;
      2) listar_logs "$container_id" ;;
      3) confirmar_reinicio "$container_id" ;;
      4) confirmar_pause    "$container_id" ;;
      5) confirmar_unpause    "$container_id" ;;
      6) confirmar_stop     "$container_id" ;;
      7) confirmar_start    "$container_id" ;;
      8) inspecionar_container "$container_id" ;;
      9) submenu_commit_save "$container_id" ;;
      10) exibir_status_containers ;;
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
confirmar_start()
{
  confirmar_restart_stop_start_pause_unpause_unpause "start" "$1"
}

confirmar_pause() {
  confirmar_restart_stop_start_pause_unpause_unpause "pause" "$1"
}

confirmar_unpause() {
  confirmar_restart_stop_start_pause_unpause_unpause "unpause" "$1"
}
confirmar_restart_stop_start_pause_unpause_unpause(){
  dialog --yesno "Tem certeza que deseja $1 o container $2?" 10 40
  if [ $? -eq 0 ]; then
    echo "$1 o container $2..."
    sudo docker $1 "$2"
    echo "Container $2 $1 com sucesso."
  else
    echo "$1 cancelado."
    sleep 1
  fi 
}
confirmar_stop() {
  confirmar_restart_stop_start_pause_unpause_unpause "stop" "$1"
}
confirmar_reinicio() {
  confirmar_restart_stop_start_pause_unpause_unpause "restart" "$1"
}

# Inicia o menu principal
while true; do
  menu_principal
done

#!/bin/bash

# 错误处理
set -euo pipefail

# 日志记录函数
log() {
    local msg="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $msg"
}

# 停止容器、修改权限、重启容器函数
restart_container_with_permissions() {
    local container_name="$1"
    local mount_path="$2"

    log "正在停止容器 $container_name..."
    docker stop "$container_name" >/dev/null 2>&1
    log "已停止容器 $container_name。"

    log "正在给目录 $mount_path 赋予权限 chmod -R 755..."
    sudo chmod -R 755 "$mount_path"

    log "正在重新启动容器 $container_name..."
    docker start "$container_name" >/dev/null 2>&1
    log "容器 $container_name 已重新启动。"
}

# 输入镜像版本
select_image_version() {
    local service_name="$1"
    shift
    local image_list=("$@")
    log "请选择 ${service_name} 的镜像版本："
    for i in "${!image_list[@]}"; do
        echo "$((i+1)). ${image_list[i]}"
    done
    echo "$(( ${#image_list[@]} + 1 )). 自定义输入镜像版本"
    while true; do
        read -p "请输入你的选择 [1-$(( ${#image_list[@]} + 1 ))]，或输入 'b' 返回上一步： " choice
        if [[ $choice == 'b' ]]; then
            return 1
        elif [[ $choice -ge 1 && $choice -le ${#image_list[@]} ]]; then
            selected_image="${image_list[choice-1]}"
            log "已选择镜像版本：$selected_image"
            break
        elif [[ $choice -eq $(( ${#image_list[@]} + 1 )) ]]; then
            read -p "请输入自定义镜像版本： " selected_image
            if [[ -n "$selected_image" ]]; then
                log "已选择自定义镜像版本：$selected_image"
                break
            fi
        else
            log "无效输入，请重新选择。"
        fi
    done
}

# 输入挂载路径
input_path() {
    local prompt_message="$1"
    local default_path="$2"
    while true; do
        read -p "$prompt_message (默认: $default_path) 或输入 'b' 返回上一步： " user_input
        if [[ $user_input == 'b' ]]; then
            return 1
        elif [[ -z "$user_input" ]]; then
            echo "$default_path"
            break
        else
            echo "$user_input"
            break
        fi
    done
}

# 生成并执行 Docker Run 命令
generate_and_run_container() {
    local service_name="$1"
    local container_name="$2"
    local image_versions=("${!3}")
    local volume_mapping=("${!4}")

    # 选择镜像版本
    select_image_version "$service_name" "${image_versions[@]}"
    if [[ $? -ne 0 ]]; then return 1; fi

    # 输入挂载路径
    declare -A paths
    for mapping in "${volume_mapping[@]}"; do
        local host_path=$(echo "$mapping" | awk -F':' '{print $1}')
        local container_path=$(echo "$mapping" | awk -F':' '{print $2}')
        user_path=$(input_path "请输入挂载路径 $container_path" "$host_path")
        if [[ $? -ne 0 ]]; then return 1; fi
        paths[$container_path]="$user_path"
    done

    # 拼接挂载路径
    local volumes=""
    for container_path in "${!paths[@]}"; do
        volumes+=" -v ${paths[$container_path]}:$container_path"
    done

    # 拼接 Docker 命令
    docker_command="docker run -d \
        --name=$container_name \
        --restart=always \
        --net=host \
        $volumes \
        $selected_image"

    log "即将执行以下 Docker 命令："
    log "$docker_command"

    # 执行 Docker 命令
    eval "$docker_command"
    if [[ $? -eq 0 ]]; then
        log "${service_name} 容器已成功安装！"
        for volume in "${default_volumes[@]}"; do
            local mount_path=$(echo "$volume" | awk -F':' '{print $1}')
            restart_container_with_permissions "$container_name" "$mount_path"
        done
    else
        log "安装 ${service_name} 容器失败，请检查错误信息。"
    fi
}

# 各服务的安装函数
install_service() {
    local service_name="$1"
    local image_versions=("${!2}")
    local volume_mapping=("${!3}")
    generate_and_run_container "$service_name" "$service_name" image_versions[@] volume_mapping[@]
}

# 主菜单
show_menu() {
    log "============================"
    log "请选择要安装的服务："
    log "1. 安装 Portainer"
    log "2. 安装 Alist"
    log "3. 安装 Rclone"
    log "4. 安装 QBittorrent"
    log "5. 安装 Emby Server"
    log "6. 安装 MoviePilot"
    log "7. 退出"
    log "============================"
}

# 主程序
while true; do
    show_menu
    read -p "请输入你的选择 [1-7]： " choice
    case $choice in
        1) install_service "Portainer" "6053537/portainer-ce:latest" "/var/run/docker.sock:/var/run/docker.sock" ;;
        2) install_service "Alist" "xhofe/alist:latest" "/root/alist/data:/opt/alist/data" ;;
        3) install_rclone ;;
        4) install_service "qBittorrent" "lscr.io/linuxserver/qbittorrent:latest" "/root/qbittorrent/config:/config" "/root/qbittorrent/downloads:/downloads" ;;
        5) install_service "Emby Server" "amilys/embyserver:latest" "/root/emby/config:/config" "/root/media:/mnt/media" ;;
        6) install_service "MoviePilot" "jxxghp/moviepilot:latest" "/root/media:/media" "/root/mp/config:/config" "/root/.config/rclone/rclone.conf:/moviepilot/.config/rclone/rclone.conf" "/root/qbittorrent/downloads:/downloads" "/root/mp/plugins:/app/plugins" "/root/mp/core:/moviepilot" "/var/run/docker.sock:/var/run/docker.sock" ;;
        7) log "退出脚本。"; exit 0 ;;
        *) log "无效输入，请重新输入。" ;;
    esac
    log "按回车键返回主菜单..."
    read
done

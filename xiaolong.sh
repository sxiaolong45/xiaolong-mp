#!/bin/bash

# 停止容器、修改权限、重启容器函数
restart_container_with_permissions() {
    local container_name="$1"
    local mount_path="$2"

    echo "正在停止容器 $container_name..."
    docker stop "$container_name" >/dev/null 2>&1
    echo "已停止容器 $container_name。"

    echo "正在给目录 $mount_path 赋予权限 chmod -R 777..."
    chmod -R 777 "$mount_path"

    echo "正在重新启动容器 $container_name..."
    docker start "$container_name" >/dev/null 2>&1
    echo "容器 $container_name 已重新启动。"
}

# 选择镜像版本函数
select_image_version() {
    local service_name="$1"
    shift
    local image_list=("$@")
    echo "请选择 ${service_name} 的镜像："
    for i in "${!image_list[@]}"; do
        echo "$((i+1)). ${image_list[i]}"
    done
    read -p "请输入你的选择 [1-${#image_list[@]}]： " image_choice
    if [[ $image_choice -ge 1 && $image_choice -le ${#image_list[@]} ]]; then
        selected_image="${image_list[image_choice-1]}"
        echo "已选择镜像：$selected_image"
    else
        echo "无效输入，默认选择第一个镜像。"
        selected_image="${image_list[0]}"
    fi
}

# 输入目录函数
input_path() {
    local prompt_message="$1"
    local user_path=""
    while true; do
        read -p "$prompt_message: " user_path
        if [ -n "$user_path" ]; then
            echo "$user_path"
            return
        else
            echo "路径不能为空，请重新输入。"
        fi
    done
}

# 安装容器的通用函数
install_container() {
    local service_name="$1"
    local container_name="$2"
    local image_versions=("${!3}")
    local volume_mapping=("${!4}")

    # 镜像选择
    select_image_version "$service_name" "${image_versions[@]}"

    # 输入挂载路径
    declare -A paths
    for volume in "${volume_mapping[@]}"; do
        path_name=$(echo "$volume" | awk -F':' '{print $1}')
        mount_point=$(echo "$volume" | awk -F':' '{print $2}')
        paths[$path_name]=$(input_path "请输入挂载路径 $mount_point")
    done

    # 拼接挂载选项
    local docker_volumes=""
    for volume in "${volume_mapping[@]}"; do
        path_name=$(echo "$volume" | awk -F':' '{print $1}')
        mount_point=$(echo "$volume" | awk -F':' '{print $2}')
        docker_volumes="$docker_volumes -v ${paths[$path_name]}:$mount_point"
    done

    # 安装容器
    echo "正在安装 ${service_name} 容器..."
    docker run -d --name="$container_name" --restart=unless-stopped --network=host \
        $docker_volumes "$selected_image"
    if [ $? -eq 0 ]; then
        echo "${service_name} 容器已成功安装！"
        restart_container_with_permissions "$container_name" "${paths[@]}"
    else
        echo "安装 ${service_name} 容器失败，请检查错误信息。"
    fi
}

# 安装服务函数
install_portainer() {
    image_versions=("portainer/portainer-ce:latest" "6053537/portainer-ce:latest")
    volume_mapping=("data:/data" "docker_socket:/var/run/docker.sock")
    install_container "Portainer" "portainer" image_versions[@] volume_mapping[@]
}

install_alist() {
    image_versions=("xhofe/alist:latest")
    volume_mapping=("alist_data:/opt/alist/data")
    install_container "Alist" "alist" image_versions[@] volume_mapping[@]
}

install_qbittorrent() {
    image_versions=("lscr.io/linuxserver/qbittorrent:latest" "lscr.io/linuxserver/qbittorrent:4.6.7")
    volume_mapping=("qb_config:/config" "qb_downloads:/downloads")
    install_container "qBittorrent" "qbittorrent" image_versions[@] volume_mapping[@]
}

install_emby() {
    image_versions=("emby/embyserver:latest" "amilys/embyserver:latest")
    volume_mapping=("emby_config:/config" "emby_media:/mnt/media")
    install_container "Emby Server" "embyserver" image_versions[@] volume_mapping[@]
}

install_moviepilot() {
    image_versions=("jxxghp/moviepilot:latest" "jxxghp/moviepilot_v2:latest")
    volume_mapping=(
        "movie_media:/media"
        "movie_config:/config"
        "rclone_conf:/moviepilot/.config/rclone/rclone.conf"
        "movie_downloads:/downloads"
        "movie_cache:/moviepilot/.cache/ms-playwright"
    )
    install_container "MoviePilot" "moviepilot" image_versions[@] volume_mapping[@]
}

# 显示主菜单函数
show_menu() {
    echo "============================"
    echo "请选择要安装的服务："
    echo "1. 安装 Portainer"
    echo "2. 安装 Alist"
    echo "3. 安装 qBittorrent"
    echo "4. 安装 Emby Server"
    echo "5. 安装 MoviePilot"
    echo "6. 退出"
    echo "============================"
}

# 主程序逻辑
while true; do
    show_menu
    read -p "请输入你的选择 [1-6]： " choice
    case $choice in
        1) install_portainer ;;
        2) install_alist ;;
        3) install_qbittorrent ;;
        4) install_emby ;;
        5) install_moviepilot ;;
        6) echo "退出脚本。"; exit 0 ;;
        *) echo "无效的输入，请重新输入。" ;;
    esac
    echo "按回车键返回主菜单..."
    read
done

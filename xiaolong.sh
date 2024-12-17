#!/bin/bash

# 输入镜像版本
select_image_version() {
    local service_name="$1"
    shift
    local image_list=("$@")
    echo "请选择 ${service_name} 的镜像版本："
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
            echo "已选择镜像版本：$selected_image"
            break
        elif [[ $choice -eq $(( ${#image_list[@]} + 1 )) ]]; then
            read -p "请输入自定义镜像版本： " selected_image
            if [[ -n "$selected_image" ]]; then
                echo "已选择自定义镜像版本：$selected_image"
                break
            fi
        else
            echo "无效输入，请重新选择。"
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

    echo "即将执行以下 Docker 命令："
    echo "$docker_command"

    # 执行 Docker 命令
    eval "$docker_command"
    if [[ $? -eq 0 ]]; then
        echo "${service_name} 容器已成功安装！"
    else
        echo "安装 ${service_name} 容器失败，请检查错误信息。"
    fi
}

# 各服务的安装函数
install_portainer() {
    image_versions=("6053537/portainer-ce:latest" "portainer/portainer-ce:latest")
    volume_mapping=("/var/run/docker.sock:/var/run/docker.sock")
    generate_and_run_container "Portainer" "portainer" image_versions[@] volume_mapping[@]
}

install_alist() {
    image_versions=("xhofe/alist:latest")
    volume_mapping=("/root/alist/data:/opt/alist/data")
    generate_and_run_container "Alist" "alist" image_versions[@] volume_mapping[@]
}

install_rclone(){

}

install_qbittorrent() {
    image_versions=("lscr.io/linuxserver/qbittorrent:latest" "lscr.io/linuxserver/qbittorrent:4.6.7")
    volume_mapping=("/root/qbittorrent/config:/config" "/root/qbittorrent/downloads:/downloads")
    generate_and_run_container "qBittorrent" "qbittorrent" image_versions[@] volume_mapping[@]
}

install_emby() {
    image_versions=("amilys/embyserver:latest" "emby/embyserver:latest")
    volume_mapping=("/root/emby/config:/config" "/root/media:/mnt/media")
    generate_and_run_container "Emby Server" "embyserver" image_versions[@] volume_mapping[@]
}

install_moviepilot() {
    image_versions=("jxxghp/moviepilot:latest")
    volume_mapping=(
        "/root/media:/media"
        "/root/mp/config:/config"
        "/root/.config/rclone/rclone.conf:/moviepilot/.config/rclone/rclone.conf"
        "/root/qbittorrent/downloads:/downloads"
        "/root/mp/plugins:/app/plugins"
        "/root/mp/core:/moviepilot"
        "/var/run/docker.sock:/var/run/docker.sock"
    )
    generate_and_run_container "MoviePilot" "moviepilot" image_versions[@] volume_mapping[@]
}

# 主菜单
show_menu() {
    echo "============================"
    echo "请选择要安装的服务："
    echo "1. 安装 Portainer"
    echo "2. 安装 Alist"
    echo "3. 安装 rclone"
    echo "4. 安装 qBittorrent"
    echo "5. 安装 Emby Server"
    echo "6. 安装 MoviePilot"
    echo "7. 退出"
    echo "============================"
}

# 主程序
while true; do
    show_menu
    read -p "请输入你的选择 [1-7]： " choice
    case $choice in
        1) install_portainer ;;
        2) install_alist ;;
        3) install_rclone ;;
        4) install_qbittorrent ;;
        5) install_emby ;;
        6) install_moviepilot ;;
        7) echo "退出脚本。"; exit 0 ;;
        *) echo "无效输入，请重新输入。" ;;
    esac
    echo "按回车键返回主菜单..."
    read
done

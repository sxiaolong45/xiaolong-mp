# xiaolong-mp
简单的脚本安装mp及相关软件
执行命令
```bash
curl -O https://raw.githubusercontent.com/shixiaolong777/xiaolong-mp/main/xiaolong.sh && chmod +x xiaolong.sh && ./xiaolong.sh
```
1.安装portainer 可以选择安装的镜像 
  ```bash
  portainer/portainer-ce:latest
  ```
  ```bash
  6053537/portainer-ce:latest
  ```
  默认使用第二个中文版
  
2.安装alist 
  ```bash
  xhofe/alist:latest
  ```
  默认使用官方版
  
3.安装rclone 
  ```bash 
  sudo -v ; curl https://rclone.org/install.sh | sudo bash
  ```
  
4.安装qbittorrent 可以选择安装的镜像 
  ```bash
  lscr.io/linuxserver/qbittorrent:latest
  ```
  ```bash
  lscr.io/linuxserver/qbittorrent:4.6.7
  ```
  默认第二个，qbittorrent版本太高的话有些PT站不支持
  
5.安装emby 可以选择安装的镜像 
  ```bash
  emby/embyserver:latest 
  ```
  ```bash
  amilys/embyserver:latest
  ```
  默认使用官方版

6.安装moviepilot 可以选择安装的镜像 
  ```bash
  jxxghp/moviepilot:latest
  ```
  ```bash
  jxxghp/moviepilot_v2:latest 
  ```
  默认使用第一个V1版本，第二个是V2版目前不太稳定 


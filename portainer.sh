#!/bin/bash
#sh -c '[ "$1" = "run_portainer" ] && (curl -fsSL https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh || wget -qO - https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh) | sh' _ "%N"

docker run -d -p 10000:10000 --name portainer1 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts



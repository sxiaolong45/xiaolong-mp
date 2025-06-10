#!/bin/bash
#sh -c '[ "$1" = "run_portainer" ] && (curl -fsSL https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh || wget -qO - https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh) | sh' _ "%N"

docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts



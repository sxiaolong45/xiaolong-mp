#!/bin/bash
#sh -c '[ "$1" = "run_portainer" ] && (curl -fsSL https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh || wget -qO - https://raw.githubusercontent.com/sxiaolong45/xiaolong-mp/refs/heads/main/portainer.sh) | sh' _ "%N"

docker run -d \
  -p 9003:9003 \
  --name portainer_agent3 \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:latest



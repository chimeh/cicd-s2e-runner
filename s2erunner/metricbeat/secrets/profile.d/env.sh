export K8S_AUTOCD=0
grep -qxF '10.99.16.41 rancher.ops' /etc/hosts || echo '10.99.16.41 rancher.ops' >> /etc/hosts
grep -qxF '10.128.2.12 harbor.nx-engine.com' /etc/hosts || echo '10.128.2.12 harbor.nx-engine.com' >> /etc/hosts
grep -qxF "$(/sbin/ip route|awk '/default/ { print $3 }') metricd" /etc/hosts || echo "$(/sbin/ip route|awk '/default/ { print $3 }') metricd" >> /etc/hosts
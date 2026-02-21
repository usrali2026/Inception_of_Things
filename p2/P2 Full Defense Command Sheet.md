## P2 Full Defense Command Sheet

```bash
# ── Pre-flight: host machine (BEFORE vagrant up) ──────────────────────
virsh net-list --all
# Must show:
# iot56   active   yes

# If inactive:
virsh net-start iot56

# ── Start up ──────────────────────────────────────────────────────────
cd p2/
vagrant up

# ── Connect ───────────────────────────────────────────────────────────
vagrant ssh alrahmouS

# ── Evalsheet checks (run inside VM) ──────────────────────────────────

# IP verification
ip a | grep 192.168.56.110

# Hostname
hostname
# → alrahmouS

# K3s server mode — must show BOTH active AND enabled
sudo systemctl is-active k3s && sudo systemctl is-enabled k3s
# → active
# → enabled

# Nodes
kubectl get nodes -o wide
# → alrahmouS   Ready   ...   192.168.56.110

# All webapps resources (3 deploys, 3 services, 5 pods)
kubectl get all -n webapps
# → app1-deployment   1/1   Running
# → app2-deployment   3/3   Running  ← 3 replicas
# → app3-deployment   1/1   Running
# → app1-service, app2-service, app3-service

# Traefik running
kubectl -n kube-system get deploy,svc traefik
# → traefik   1/1   Available

# Ingress (evaluators WILL ask — subject warns this is hidden on purpose)
kubectl -n webapps get ingress
# → webapps-ingress   traefik   app1.com,app2.com

kubectl -n webapps describe ingress webapps-ingress
# → Rules:
# →   app1.com → app1-service:80
# →   app2.com → app2-service:80
# →   *        → app3-service:80 (default)

# ── Ingress routing demo ───────────────────────────────────────────────
# Run from iot-host-ubuntu (exit VM first)
exit

curl -H 'Host: app1.com' http://192.168.56.110
# → Hello from app1. | namespace: webapps | pod: app1-xxx ✅

curl -H 'Host: app2.com' http://192.168.56.110
# → Hello from app2. | namespace: webapps | pod: app2-xxx ✅
# Run 3x → different pod name each time = proves 3 replicas live

curl http://192.168.56.110
# → Hello from app3. | namespace: webapps ✅ (default — no Host header)

# ── Browser demo (42 workstation — no sudo needed) ────────────────────
# Terminal 1: start SOCKS proxy
ssh -D 1080 -N -f -p 2222 alrahmou@127.0.0.1

# Firefox → about:preferences → Network Settings:
#   ● Manual proxy config
#   SOCKS Host: 127.0.0.1   Port: 1080
#   ● SOCKS v5
#   ☑ Proxy DNS when using SOCKS v5

# Browser URLs:
#   http://app1.com         → Hello from app1. ✅
#   http://app2.com         → Hello from app2. ✅ (refresh = new pod)
#   http://192.168.56.110   → Hello from app3. ✅

# ── After defense: kill SOCKS proxy ───────────────────────────────────
pkill -f "ssh -D 1080"
# Firefox → Network Settings → No Proxy
```

> **Key talking points during defense:**
> - app2 has **3 replicas** — refresh the browser to show different pod names live
> - Ingress uses **Traefik** (K3s default) with Host-based routing
> - Default rule (no Host header) falls through to **app3**
> - The `KUBERNETES_NAMESPACE`, `KUBERNETES_POD_NAME`, `KUBERNETES_NODE_NAME` env vars come from the **downward API** — pod injects its own metadata at runtime

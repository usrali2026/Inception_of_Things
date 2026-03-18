# ══════════════════════════════════════════════════════════════════════
# P2 Full Defense Command Sheet
# K3s single VM · 3 apps · Traefik ingress · Host-based routing
# Evalsheet v4.0 aligned
# ══════════════════════════════════════════════════════════════════════

# ── Pre-flight: host machine (BEFORE vagrant up) ──────────────────────
virsh net-list --all
# Must show:
#  Name    State    Autostart
#  iot56   active   yes

# If inactive:
virsh net-start iot56

# ── Shut down p1 VMs first (recommended by evalsheet) ─────────────────
cd p1/
vagrant halt
cd ../p2/

# ── Start up ──────────────────────────────────────────────────────────
vagrant up

# ── Connect ───────────────────────────────────────────────────────────
vagrant ssh alrahmouS

# ── Deploy webapps manifests ───────────────────────────────────────────
kubectl apply -f /vagrant/confs/apps-ingress.yaml

# Verify namespace was created
kubectl get ns webapps

# Watch pods come up live
kubectl get pods -n webapps -w
# Wait until all show Running, then Ctrl+C

# ── Evalsheet checks (run inside VM) ──────────────────────────────────

# IP verification — evaluator may ask either form
ip a | grep 192.168.56.110
# or (interface name may be eth1, enp0s8, enp0s9, etc.)
ip a show eth1

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

# Wait for all deployments to be fully ready
kubectl rollout status deployment -n webapps

# All webapps resources (3 deploys, 3 services, 5 pods)
kubectl get all -n webapps
# → app1-deployment   1/1   Running
# → app2-deployment   3/3   Running  ← 3 replicas
# → app3-deployment   1/1   Running
# → app1-service, app2-service, app3-service

# Ingress (evaluators WILL ask — subject warns this is hidden on purpose)
kubectl get ingress -n webapps
# → webapps-ingress   traefik   app1.com,app2.com
# NOTE: app3 catch-all has no host field — correctly absent from HOSTS column

kubectl describe ingress webapps-ingress -n webapps
# → Rules:
# →   app1.com  → app1-service:80
# →   app2.com  → app2-service:80
# →   *         → app3-service:80 (catch-all, no host field)

# Traefik running
kubectl -n kube-system get deploy,svc traefik
# → traefik   1/1   Available

# ── Ingress routing demo (run from host machine — exit VM first) ───────
exit

curl -H 'Host: app1.com' http://192.168.56.110
# → Hello from app1. | namespace: webapps | pod: app1-xxx ✅

curl -H 'Host: app2.com' http://192.168.56.110
# → Hello from app2. | namespace: webapps | pod: app2-xxx ✅
# Run 3x → different pod name each time = proves 3 replicas live

curl http://192.168.56.110
# → Hello from app3. | namespace: webapps ✅ (catch-all — no Host header)

# ── Browser demo (42 workstation — no sudo needed) ────────────────────
# Get the exact key path first:
vagrant ssh-config alrahmouS | grep IdentityFile

# Terminal 1: start SOCKS proxy via direct VM IP (libvirt has no 2222 forwarding)
ssh -D 1080 -N -f -i ~/.vagrant.d/insecure_private_key vagrant@192.168.56.110

# Firefox → about:preferences → Network Settings:
#   ● Manual proxy config
#   SOCKS Host: 127.0.0.1   Port: 1080
#   ● SOCKS v5
#   ☑ Proxy DNS when using SOCKS v5

# Browser URLs:
#   http://app1.com          → Hello from app1. ✅
#   http://app2.com          → Hello from app2. ✅ (refresh = new pod each time)
#   http://192.168.56.110    → Hello from app3. ✅ (catch-all, no Host header)

# ── After defense: cleanup ────────────────────────────────────────────
pkill -f "ssh -D 1080" && echo "SOCKS proxy killed"
# Firefox → Network Settings → No Proxy

# ══════════════════════════════════════════════════════════════════════
# Key talking points during defense
# ══════════════════════════════════════════════════════════════════════
# - app2 has 3 replicas — refresh browser to show different pod names live
# - Ingress uses Traefik (K3s default) with Host-based routing
# - Catch-all rule (no host: field in spec) falls through to app3
# - app1/app2 require exact Host header match; app3 catches everything else
# - KUBERNETES_NAMESPACE, KUBERNETES_POD_NAME, KUBERNETES_NODE_NAME
#   come from the downward API — pod injects its own metadata at runtime
# - Interface name may vary: eth1, enp0s8, enp0s9 — all are valid (evalsheet v4.0)
# ══════════════════════════════════════════════════════════════════════

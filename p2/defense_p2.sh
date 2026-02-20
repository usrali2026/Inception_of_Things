#!/usr/bin/env bash
set -euo pipefail

vagrant status
vagrant ssh alrahmouS -c "sudo kubectl get nodes -o wide"
vagrant ssh alrahmouS -c "sudo kubectl -n kube-system get deploy,svc traefik -o wide"
vagrant ssh alrahmouS -c "sudo kubectl -n webapps get deploy,pods -o wide"
vagrant ssh alrahmouS -c "sudo kubectl -n webapps get ingress -o wide"

echo '--- curl tests ---'
curl -s -H "Host: app1.com" http://192.168.56.110 ; echo
curl -s -H "Host: app2.com" http://192.168.56.110 ; echo
curl -s http://192.168.56.110 ; echo

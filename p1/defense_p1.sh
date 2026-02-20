#!/usr/bin/env bash
set -euo pipefail

vagrant status
vagrant ssh alrahmouS  -c "hostname"
vagrant ssh alrahmouSW -c "hostname"
vagrant ssh alrahmouS  -c "ip -4 a show eth1 || ip -4 a"
vagrant ssh alrahmouSW -c "ip -4 a show eth1 || ip -4 a"
vagrant ssh alrahmouS  -c "sudo systemctl is-active k3s && sudo systemctl is-enabled k3s"
vagrant ssh alrahmouSW -c "sudo systemctl is-active k3s-agent && sudo systemctl is-enabled k3s-agent"
vagrant ssh alrahmouS  -c "sudo kubectl get nodes -o wide"

#!/usr/bin/env bash
#===============================================================================
# k8s_run_command.sh — Run commands across debug DaemonSet pods
#
# Requires: debug DaemonSet created via oci_cli_ops.sh --manage k 3 → 12
# Uses app.kubernetes.io/name=node-debug label to find pods
#
# Author: Tim Cowen
# Version: 1.0.0 (2026-04-10)
#===============================================================================
set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_VERSION_DATE="2026-04-10"

# Defaults
NAMESPACE="monitoring"
LABEL="app.kubernetes.io/name=node-debug"
PARALLELISM=8
DEBUG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace) NAMESPACE="$2"; shift 2 ;;
        -l|--label)     LABEL="$2"; shift 2 ;;
        -P|--parallel)  PARALLELISM="$2"; shift 2 ;;
        --debug)        DEBUG=true; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Run GPU diagnostics across all debug DaemonSet pods."
            echo ""
            echo "Options:"
            echo "  -n, --namespace NS   Namespace (default: monitoring)"
            echo "  -l, --label LABEL    Pod label selector (default: app.kubernetes.io/name=node-debug)"
            echo "  -P, --parallel N     Max parallel executions (default: 8)"
            echo "      --debug          Enable debug mode"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Prerequisite: Create debug DaemonSet via:"
            echo "  ./oci_cli_ops.sh --manage k 3 → 12"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

$DEBUG && set -x

# Verify debug pods exist
POD_COUNT=$(kubectl get pods -l "$LABEL" -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [[ "$POD_COUNT" -eq 0 ]]; then
    echo "ERROR: No debug pods found with label '$LABEL' in namespace '$NAMESPACE'"
    echo ""
    echo "Create the debug DaemonSet first:"
    echo "  ./oci_cli_ops.sh --manage k 3 → 12"
    exit 1
fi

echo "Running GPU diagnostics across $POD_COUNT node(s) (parallelism: $PARALLELISM)..."
echo ""

kubectl get pods -l "$LABEL" -n "$NAMESPACE" \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.nodeName}{"\n"}{end}' |
    xargs -r -n 2 -P "$PARALLELISM" sh -c '
        pod="$1"; node="$2"
        output=$(kubectl exec -n "'"$NAMESPACE"'" "$pod" -- chroot /host /bin/bash -c "
            echo \"=== nvidia-smi ===\"
            nvidia-smi --query-gpu=index,pci.bus_id,power.draw,power.limit,clocks_throttle_reasons.hw_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown,temperature.gpu --format=csv 2>/dev/null || echo \"nvidia-smi: not available\"
            echo \"\"
            echo \"=== Serial Number ===\"
            dmidecode -s system-serial-number 2>/dev/null || echo \"dmidecode: not available\"
            echo \"\"
            echo \"=== NVLink 53.125 GBps links ===\"
            nvidia-smi nvlink --status 2>/dev/null | grep -c 53.125 || echo \"0\"
        " 2>&1)
        echo "$output" | sed "s/^/$node: /"
    ' sh | sort -t: -k1,1 -s

**OCI CLI Operations** — Interactive management tool for Oracle Cloud Infrastructure, Kubernetes, and GPU infrastructure.

**Version:** 3.34.1 | **Date:** 2026-04-14

## Overview

`oci_cli_ops.sh` — bash script that turns your terminal into a full OCI management console. OCI CLI + kubectl, menu-driven, zero web UI required.

🔥 *Compute* (12 sub-sections)
Instance lifecycle with K8s cordon/drain/taint/terminate workflows, GPU Memory Fabrics & Clusters with firmware tracking, Capacity Topology with RDMA tree visualization, Custom Images, Instance Pools, Cluster Networks, Compute Hosts with impacted component details and recycle status, Host Groups with attach/detach BM hosts, and Notifications (ONS topics, subscriptions, event rules for host monitoring)

⚡ *Kubernetes* (11 diagnostic tools)
OKE cluster environment + comparison, NVIDIA GPU Stack Health (Operator + DRA), node-level GPU health, XID error scanning, RDMA/NCCL diagnostics, NVMe SMART logs, NVIDIA bug reports, SOS bundles, GPU tolerations, and SSH key distribution via DaemonSet

🌐 *Networking*
Full VCN resource views, all gateway types, DRG/LPG/RPC/IPSec, NSG + security list management — plus DRG connectivity maps and cross-region DRG topology visualization

💾 *Storage*
FSS with guided setup, Lustre with Object Storage links, Object Storage with private endpoint + rule wizards

🔐 *Identity*
Compartment tree, Identity Domains (users/groups/dynamic groups/IdPs), full policy search + validation, Vaults (KMS)

🛠️ *Operations*
Resource Manager Stacks (Terraform state!), Work Requests, Maintenance Events with reschedule, Announcements, Service Limits + GPU capacity reports, and Audit Logs with toggleable columns

⚙️ *Built for daily ops:* metadata auto-discovery, response caching, action logging, `--debug` mode, multi-select targeting, global nav shortcuts, and auto-detected auth (instance principal, API key, Cloud Shell, Resource Principal)


## Prerequisites

| Tool | Required | Notes |
|------|----------|-------|
| `oci` | Yes | OCI CLI (instance principal, API key, or cloud shell auth) |
| `kubectl` | Yes | Configured kubeconfig with cluster access |
| `jq` | Yes | JSON processor |
| `helm` | Optional | For GPU Operator / DRA stack inspection |
| `curl` | Optional | For IMDS metadata queries during setup |
| `base64` / `gunzip` | Optional | For user-data decoding |

**macOS Note:** Requires Bash 4+ (macOS ships with Bash 3.2). Install via `brew install bash`, then run with `/opt/homebrew/bin/bash ./oci_cli_ops.sh`. Setup auto-detects `~/.oci/config` when IMDS is unavailable (laptop/desktop use).

## Quick Start

```bash
# Initial setup — creates variables.sh from instance metadata
./oci_cli_ops.sh --setup

# Launch interactive management console
./oci_cli_ops.sh --manage

# Jump directly to a section
./oci_cli_ops.sh --manage c1    # Compute Instances
./oci_cli_ops.sh --manage k3    # Kubernetes Management
./oci_cli_ops.sh --manage o3    # Maintenance Events

# Single instance lookup
./oci_cli_ops.sh <instance-ocid> --all
```

## Configuration

### variables.sh

`variables.sh` is the environment configuration file that tells the script where to operate. It's sourced at startup and sets the default region, tenancy, compartment, availability domain, and OKE cluster for all queries.

**Auto-setup:** Run `./oci_cli_ops.sh --setup` (or just launch the script without a `variables.sh`). The setup wizard detects your environment automatically:

| Environment | Detection Method |
|-------------|-----------------|
| **OCI Instance** | IMDS metadata at `169.254.169.254` (tenancy, compartment, region, AD) |
| **Cloud Shell** | `OCI_TENANCY` / `OCI_REGION` environment variables |
| **Mac / Laptop** | `~/.oci/config` API key config (DEFAULT profile, or `OCI_CLI_PROFILE` env var) |

After detection, the setup walks through interactive selection of region, availability domain, compartment (if defaulting to root), and OKE cluster. The result is saved to `variables.sh`:

```bash
#!/bin/bash
# OCI Environment Configuration
REGION="us-ashburn-1"
TENANCY_ID="ocid1.tenancy.oc1..aaaa..."
COMPARTMENT_ID="ocid1.compartment.oc1..aaaa..."
AD="jLaG:US-ASHBURN-AD-1"

# OKE Cluster
OKE_CLUSTER_ID="ocid1.cluster.oc1..aaaa..."
CLUSTER_NAME="oke-gpu-quickstart"

# Instance filter for listing: "gpu", "non-gpu", or "all"
INSTANCE_FILTER="all"
```

| Variable | Purpose |
|----------|---------|
| `REGION` | Default OCI region for all API calls |
| `TENANCY_ID` | Tenancy OCID — used for compute hosts, capacity topology, service limits |
| `COMPARTMENT_ID` | Default compartment for resource queries |
| `AD` | Availability domain — used for host group creation, compute cluster placement |
| `OKE_CLUSTER_ID` | Default OKE cluster for Kubernetes operations |
| `CLUSTER_NAME` | Display name for the OKE cluster |
| `INSTANCE_FILTER` | Filter instance list: `gpu` (GPU shapes only), `non-gpu`, or `all` |

All values can be overridden at runtime using the `env` menu (change region, compartment, OKE cluster, VCN) without editing the file. Use `env` → `s` to save runtime changes back to `variables.sh`.

### Global CLI Options

```
--compartment-id <ocid>   Override compartment
--region <region>         Override region
--debug                   Enable debug mode (verbose OCI CLI output)
```

---

## Menu Structure

### Top Level (`--manage`)

```
  c)  Compute         k)  Kubernetes      n)  Network
  s)  Storage         i)  Identity        o)  Operations

  r)     Overview        env)   Change Focus     cache) Cache Stats
  /)     Search          setup) Env Setup         q)    Quit
```

Shortcuts: `c1`, `k2`, `s3`, etc. jump directly to a sub-resource.
Global nav: type `:c`, `:k1`, `:n2`, etc. from any prompt to jump.

---

### c) Compute

| Option | Function | Description |
|--------|----------|-------------|
| `c1` | Compute Instances | Instance list with K8s status, cordon/drain/taint, BVR, bulk run-command. Node Pool/OKE Cluster columns (`col` to enable). BVR blocked for nodepool-managed instances. OKE Node Pool detail in `i#` view |
| `c2` | Instance Configurations | Create, view, compare, delete. `cci` creates cloud-init YAML (auto-detects API server + CA from kubeconfig) |
| `c3` | Compute Clusters | Create, view, and delete compute clusters |
| `c4` | GPU Memory Fabrics & Clusters | Manage GPU fabrics, clusters, firmware bundles (region-aware cache) |
| `c5` | Capacity Topology | Host lifecycle states, RDMA topology tree (AD-aware filtering) |
| `c6` | Custom Images | Import, create from instance, export, shape compatibility |
| `c7` | GPU Instance Tagging | ComputeInstanceHostActions namespace and tags |
| `c8` | Instance Pools | Create, view, and manage instance pools |
| `c9` | Cluster Networks | View cluster networks and instance details |
| `c10` | Compute Hosts | Bare-metal host health, state, topology, SN column, impacted component details (`h#` drill-down), recycle status, `f` fault code filter, `notify` for event rules |
| `c11` | Host Groups | Create, view, delete host groups; attach/detach BM hosts; capacity topology pre-flight; host count per group |
| `c12` | Notifications | ONS topics, subscriptions (email/Slack/PagerDuty/webhook), event rules list/detail/delete |

**Instance Actions** (`c1` prompt): `i#` (detail), `/` (search), `taint`, `untaint`, `cordon`, `uncordon`, `drain`, `reboot`, `cdt` (Cordon-Drain-Tag-Terminate), `terminate`, `bvr` (Boot Volume Replacement), `brc` (Bulk Run-Command), `p` (properties view), `col` (column picker, includes `np` and `oke_cluster`)

**Host Group Actions** (`c11` detail): `a` (attach BM host), `dt #` (detach), `notify` (create event rule), `j` (JSON)

**Notification Actions** (`c12`): `c` (create topic), `s` (subscribe), `d #` (delete topic), `e#` (view event rule), `ed #` (delete event rule)

---

### k) Kubernetes

| Option | Function | Description |
|--------|----------|-------------|
| `k1` | OKE Cluster Environment | Cluster details, VCN, node pools, add-ons |
| `k2` | NVIDIA GPU Stack Health | GPU Operator and DRA component status per node |
| `k3` | Kubernetes Management | Node diagnostics, RDMA, SSH keys, debug DaemonSet (12 sub-options) |

**K8s Management** (`k3`) sub-options:

| # | Tool | Description |
|---|------|-------------|
| 1 | Kubelet Deregister | Drain, delete K8s node, recovery steps |
| 2 | Node Storage | Disk layout, NVMe health, SMART logs via kubectl debug |
| 3 | Node Network | Host NIC hardware and IP config via kubectl debug |
| 4 | Node GPU Health | nvidia-smi temps, ECC, NVLink, topology |
| 5 | Dmesg XID Scanner | NVIDIA XID errors per GPU node |
| 6 | RDMA / NCCL Diagnostics | InfiniBand port states, GID tables, error counters |
| 7 | NVIDIA Bug Report | Generate nvidia-bug-report.sh on a node |
| 8 | SOS Report | Oracle Linux / Ubuntu diagnostic bundle |
| 9 | GPU Tolerations | View/add/remove tolerations on GPU operator daemonsets |
| 10 | Storage Provisioning | Validate BV, FSS, Lustre prerequisites for K8s |
| 11 | Authorized SSH Keys | Distribute SSH public keys via DaemonSet |
| 12 | Debug DaemonSet | Deploy privileged busybox pod to selected nodes for troubleshooting |

Additional shortcuts: `oke` (select cluster), `cc` (compare clusters), `cn` (compare node pools)

---

### n) Network

Auto-enters the VCN resource view if a VCN is focused. Shows:

- Subnets (with NSG assignments)
- NSG rules (ingress/egress counts)
- Route Tables
- Internet / Service / NAT Gateways
- DRG attachments, LPGs, RPCs
- Security Lists
- Object Storage Private Endpoints

Actions: `#` (resource detail), `/` (search port in NSG/SL rules), `drg` (DRG connectivity map), `xr` (cross-region DRG map)

---

### s) Storage

| Option | Function | Description |
|--------|----------|-------------|
| `s1` | File Storage (FSS) | File systems, mount targets, exports, guided setup |
| `s2` | Lustre File Systems | Lustre management, Object Storage links, import/export |
| `s3` | Object Storage | Buckets, private endpoints, NSG/SL rule wizards |

---

### i) Identity

| Option | Function | Description |
|--------|----------|-------------|
| `i1` | Compartments | Hierarchy tree, create sub-compartments |
| `i2` | Identity Domains | Users, groups, dynamic groups, identity providers, search |
| `i3` | Policies | Full policy tree, search by keyword/service/compartment, validation |
| `i4` | Vaults (KMS) | Manage vaults, keys, encryption |

---

### o) Operations

| Option | Function | Description |
|--------|----------|-------------|
| `o1` | Resource Manager Stacks | Stacks, jobs, logs, outputs, state files |
| `o2` | Work Requests | Status, errors, and logs for async operations |
| `o3` | Maintenance | Instance maintenance events, reschedule windows, filter by reason/lifecycle, parallel data fetch |
| `o4` | Announcements | Announcements with affected resource details |
| `o5` | Service Limits & Quotas | Limits, usage, availability, GPU capacity reports |
| `o6` | Audit Logs | OCI audit events (API calls, changes, access) |

---

## CLI Reference

### Instance Operations

```bash
# Instance info
./oci_cli_ops.sh <instance-ocid> --labels          # K8s labels
./oci_cli_ops.sh <instance-ocid> --clique           # GPU clique, tags, fabric
./oci_cli_ops.sh <instance-ocid> --count-clique     # Nodes in same clique
./oci_cli_ops.sh <instance-ocid> --all              # Everything
./oci_cli_ops.sh <instance-ocid> --details          # Network, boot/block volumes
./oci_cli_ops.sh <instance-ocid> --console-history  # Serial console output
./oci_cli_ops.sh <instance-ocid> --get-user-data    # Decoded cloud-init

# Instance actions
./oci_cli_ops.sh <instance-ocid> --terminate        # Interactive terminate

# GPU cluster
./oci_cli_ops.sh <gpu-cluster-ocid> --list-cluster  # List cluster instances

# Instance configuration
./oci_cli_ops.sh <ic-ocid> --get-user-data-config   # Extract cloud-init from config
```

### Bulk Operations

```bash
./oci_cli_ops.sh --list-cliques         # GPU cliques with fabric info
./oci_cli_ops.sh --cliques-summary      # Summary table of all cliques
./oci_cli_ops.sh --maintenance          # Instances needing maintenance
./oci_cli_ops.sh --maintenance-events   # Maintenance events (view/reschedule)
./oci_cli_ops.sh --announcements        # All announcements
./oci_cli_ops.sh --search <text>        # Search resources by OCID/name
./oci_cli_ops.sh --refresh              # Clear all caches
```

---

## Standalone Scripts

| Script | Description |
|--------|-------------|
| `k8s_run_command.sh` | Run GPU diagnostics (nvidia-smi, serial number, NVLink) across all debug DaemonSet pods in parallel. Requires debug DaemonSet from `--manage k 3 → 12`. Supports `-n namespace`, `-P parallelism`, `--debug` |

---

## Architecture

### Data Pipeline

```
  CACHE              FOCUS              DISPLAY
  ─────              ─────              ───────
  OCI API  ──►  Cache Files  ──►  Focus Filter  ──►  Formatted Output
  kubectl       (JSON/text)       (compartment,      (tables, colors,
  helm          TTL-based          region, OKE)       spinners)
```

- **Cache layer**: OCI API responses cached as JSON/text files in `./cache/` with configurable TTL (default 5 minutes). Atomic writes via temp file + `mv -f`.
- **Focus layer**: Region, compartment, OKE cluster, and VCN can be changed at runtime via `env` menu. All queries respect the current focus.
- **Display layer**: Color-coded tables with column picker, breadcrumb navigation, spinners with elapsed timers.

### Key Patterns

| Pattern | Description |
|---------|-------------|
| `_col_*` functions | Generic column visibility system — toggleable columns with persistent width/alignment |
| `_parse_targets()` | Multi-select targeting — `i1`, `i1,i3`, `i1-i5`, `all` |
| `_step_*` functions | Multi-phase spinner with elapsed timer |
| `_safe_exec()` | Command validation and array-based execution |
| `log_action()` | Audit logging — exact command + result for all create/update/delete |
| `_cache_write()` | Atomic cache writes (temp file + mv) |
| `_nav_try_jump()` | Global navigation — `:c1`, `:k3`, etc. from any prompt |

### Cache Files

All caches stored in `./cache/` relative to the script. Key caches:

| Cache | File | TTL |
|-------|------|-----|
| Instances | `instance_list.json` | 5m |
| GPU Fabrics | `gpu_fabrics.json` | 5m |
| GPU Clusters | `gpu_clusters.json` | 5m |
| Maintenance Events | `maintenance_events.json` | 5m |
| Compute Hosts | `compute_hosts.json` | 5m |
| Compute Host Details | `compute_host_detail/*.json` | 5m |
| Host Groups | `compute_host_groups.json` | 5m |
| Capacity Topology | `capacity_topology_hosts.json` | 5m |
| OKE Environment | `oke_environment.txt` | 5m |
| Network Resources | `network_resources.txt` | 5m |
| Policies | `policies_all.json` | 5m |
| Service Limits Index | `limits_search_index.tsv` | 24h |
| Cross-Region DRG | `xr_map/` | 3m |
| Audit Events | `audit_events.json` | 2m |

### Logging

All create, update, and delete operations:
1. Display the exact command on screen before execution
2. Log to `${LOGS_DIR}/<action>_actions.log` with timestamp, command, and exit code
3. Mask OCIDs to last 6 characters in log output

---

## Script Layout (by line range)

| Lines | Section | Description |
|-------|---------|-------------|
| 1–368 | Header & Coding Standards | Shebang, description, machine-readable coding spec |
| 384–638 | Configuration | Colors, constants, cache paths, TTL registry, global arrays |
| 639–1759 | Utility Functions | Logging, OCID validation, cache helpers, spinners, progress |
| 1760–3311 | Cache Fetch Functions | GPU fabrics/clusters, OKE, instances, compute hosts, topology |
| 3312–4835 | Network Gateway Functions | IGW, SGW, NAT, DRG, LPG, RPC, route tables, NSGs, security lists |
| 4836–5108 | Lookup & Color Functions | State lookups, announcement mapping, color helpers |
| 5109–6492 | UI Helpers | Banners, menus, breadcrumbs, prompts, JSON viewer, shape helpers |
| 6493–7271 | Environment Focus System | Region/compartment/OKE/VCN selection and persistence |
| 7272–7625 | Category Menus | Top-level menu routing (c, k, n, s, i, o) |
| 7626–8053 | OKE Environment Display | Cluster header, console history |
| 8054–12692 | Main List Functions | Instance lists, maintenance events, announcements, clique analysis |
| 12693–13164 | GPU Management & Search | GPU menu entry, OCI resource search |
| 13165–14448 | Main Menu & Compartments | Interactive management menu, compartment hierarchy |
| 14449–17713 | Identity Management | Identity domains, users, groups, dynamic groups, policies |
| 17714–18815 | Vault & Cache Stats | KMS vault management, cache statistics display |
| 18816–19957 | Utilities & OKE Selection | Env setup, tmux config, OKE cluster selection/comparison |
| 19958–22597 | OKE Cluster Management | Node pool operations, BVR, cycle, add-on management |
| 22598–30715 | Network Management | VCN resources, DRG connectivity, cross-region DRG map |
| 30716–31956 | Shared Helpers | Target parsing, AD discovery, column visibility system |
| 31957–37586 | Compute Instance Core | Instance list, detail, K8s node operations, search |
| 37587–40802 | Instance Tools | Tagging, console history, cloud-init comparison, instance configs |
| 40803–43668 | GPU & Cluster Management | GPU fabrics/clusters, firmware, compute clusters |
| 43669–45305 | Instance Pools & Cluster Networks | Pool and cluster network lifecycle management |
| 45306–49011 | Operations | Resource Manager, work requests, service limits & quotas |
| 49012–52929 | Storage | File Storage (FSS), Lustre file systems with Object Storage links |
| 52930–55654 | Topology & Hosts | Capacity topology, compute hosts (impacted detail fetch, h# drill-down), GPU instance tagging |
| 55355–58829 | K8s Diagnostics | Storage/network/GPU/RDMA verification, bulk run-command, audit |
| 58830–62847 | K8s Tools | Bug reports, SOS, GPU tolerations, SSH keys, GPU stack health |
| 62848–65795 | Instance Config Operations | Create/delete instance configurations |
| 65796–68251 | Object Storage | Buckets, private endpoints, NSG/SL rule wizards |
| 68252–70067 | Custom Images | Import, create, export, shape compatibility, delete |
| 70068–70977 | Help, Setup & Main | Help text, IMDS helpers, initial setup, argument routing |

---

## OCI Auth Modes

Auto-detected at startup:

| Mode | How |
|------|-----|
| Instance Principal | Running on OCI instance with dynamic group policy |
| API Key | `~/.oci/config` with key file |
| Cloud Shell | Security token / delegation token |
| Resource Principal | OCI Functions or Container Instances |

---

## Environment Focus

The script maintains a runtime "focus" that scopes all queries:

```
env c       — Change compartment (hierarchical tree selector with root tenancy)
env r       — Change region (all subscribed regions listed)
env oke     — Change OKE cluster
env vcn     — Change VCN
env profile — Switch OCI CLI profile (for multi-profile ~/.oci/config)
```

Focus can be saved to `variables.sh` via `env` → `s` (save). The current focus is shown in the header of every menu.

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 3.34.1 | 2026-04-14 | c1: Node Pool/OKE Cluster columns, BVR guard for nodepool instances, OKE Node Pool section in instance detail. c2: `cci` cloud-init YAML creator. c10: SN column, fault code filter (`f`), optimized impacted detail fetch. c11: host count per group. c12: event rule list/detail/delete. o3: parallel data fetch, filter by maintenance reason (`re`), wider instance name column. k3: option 12 debug DaemonSet. `env profile` for multi-profile OCI configs. macOS `grep -oP` → portable `grep -oE`/`sed`. Spinner wrap fix. Dynamic group matching rule fix. Policy hints for firmware bundles, compute clusters, GPU clusters. `k8s_run_command.sh` standalone script |
| 3.33.1 | 2026-04-10 | c11 Host Groups (CRUD, attach/detach BM hosts, capacity pre-flight, BM.GPU shape picker). c12 Notifications (ONS topics, subscriptions, event rule list/detail/delete). c10 `notify` for event rules. macOS support (Bash 4 guard, `~/.oci/config` setup, IMDS skip on Darwin). OKE focus fix, BVR `--region`, env r persistence in menus, capacity topology AD filtering |
| 3.27.2 | 2026-03-11 | o3 summary: monthly fault code/fabric tables with lifecycle columns, fault code reference with component/description/impact. c10 summary: per-fabric GPU memory table, per-row impacted inline, skip k8s without context |
| 3.26.0 | 2026-03-10 | Dedicated pool GB200 fix, capacity report error diagnostics, `h#` compute host navigation from o3, RDMA alignment, c10 impacted component aggregation |
| 3.25.73 | 2026-03-04 | Compute host impacted component details via `compute-host get`, recycle-details, `h#` detail drill-down, parallel detail fetch with progress |
| 3.25.66 | 2026-03-02 | Compute host RDMA tree: topology counts, fabric tags, aligned OCIDs |
| 3.25.56 | 2026-03-02 | Audit logs: column visibility system, request action column, search drill-down |
| 3.25.50 | 2026-03-02 | Renamed to `oci_cli_ops.sh`, compute host GPU fabric tags |
| 3.25.49 | 2026-03-01 | Code review: 6 critical, 13 high, 15+ medium, 7 low fixes |
| 3.25.47 | 2026-03-01 | Maintenance events cache refresh, column width tuning |
| 3.25.46 | 2026-03-01 | Column widths for maintenance events display |
| 3.25.45 | 2026-03-01 | Root tenancy selectable in compartment picker |
| 3.25.44 | 2026-03-01 | Disable category/announce columns by default |

---

## Feature Previews

Sample terminal output for key management screens.

---

### Initial Setup (`./oci_cli_ops.sh`)

When `variables.sh` is not found, the setup wizard runs automatically:

```
  variables.sh not found.

  Would you like to run initial setup? (Y/n): Y

  ═══════════════════════════════════════════════════════════════════════════════
                            INITIAL SETUP - CREATING VARIABLES.SH
  ═══════════════════════════════════════════════════════════════════════════════
  Discovering:
  ✓ IMDS, 0.2s  ✓ metadata, 0.3s  ✓ OCI CLI, 1.8s  ✓ names, 4.2s

  Base environment detected:
    Tenancy:     naciegpu [ocid1.tenancy.oc1..aaaa...]
    Compartment: tim [ocid1.compartment.oc1..aaaa...]
    Region:      us-ashburn-1
    AD:          US-ASHBURN-AD-1

  ◆ Region Selection
   1) ap-chuncheon-1        7) ap-singapore-1      13) eu-frankfurt-1      19) me-abudhabi-1
   ...
  27) us-ashburn-1           (home) ← detected
  28) us-chicago-1
  Select region [Enter to keep us-ashburn-1]:
  ✓ Region: us-ashburn-1 (kept)

  ◆ Availability Domain
   1) jLaG:US-ASHBURN-AD-1   ← detected
   2) jLaG:US-ASHBURN-AD-2
   3) jLaG:US-ASHBURN-AD-3
  Select AD [Enter to keep US-ASHBURN-AD-1]:
  ✓ AD: US-ASHBURN-AD-1 (kept)

  ◆ OKE Clusters
  Auto-selected (only cluster):
    Name:    oke-gpu-quickstart-npejxs
    Version: v1.34.1

  Save configuration to variables.sh? (Y/n): Y
  Configuration saved to: ./variables.sh
```

On macOS / laptop (no IMDS), setup falls back to `~/.oci/config`:

```
  Discovering:
  ✓ IMDS(unavailable), 1.2s  ✓ OCI config, 2.1s  ✓ names, 1.8s

  Base environment detected (local OCI config):
    Tenancy:     mytenancy [ocid1.tenancy.oc1..aaaa...]
    Compartment: mytenancy [ocid1.tenancy.oc1..aaaa...]
    Region:      us-ashburn-1

  ◆ Compartment Selection
  Currently set to root (tenancy). Select a sub-compartment or keep root.
   1) gpu-workloads
   2) networking
   0) Keep root compartment (tenancy)
  Select compartment [Enter to keep root]: 1
  ✓ Compartment: gpu-workloads
```

---

### Main Menu (`--manage`)

```
  ═══════════════════════════════════════════════════════════════════════════════
                                OCI RESOURCE MANAGEMENT
  ═══════════════════════════════════════════════════════════════════════════════
  Focus: (variables.sh configured │ manually selected │ derived)
    Tenancy: naciegpu [ocid1.tenancy.oc1..aaaa...]
    Region: us-ashburn-1  │  AD: US-ASHBURN-AD-1  │  Compartment: naciegpu > krupa > thiago > tim  │  OKE: oke-gpu-quickstart
    OCI CLI: 3.74.0 (instance_principal)  │  kubectl: v1.34.1  │  helm: v3.20.0

  ─── Actions ────────────────────────────────────────────────
  » Categories
  c)  Compute         - Instances, configs, clusters, GPU fabrics, images, topology
  k)  Kubernetes      - OKE cluster environment, GPU stack health, node management
  n)  Network         - VCN subnets, NSGs, route tables, DRGs, security lists
  s)  Storage         - File Storage (FSS), Lustre, Object Storage
  i)  Identity        - Compartments, identity domains, policies
  o)  Operations      - Resource Manager, work requests, maintenance, announcements

  » Utilities
  r)     Overview      - Full environment view
  env)   Change Focus  - Change region, compartment, OKE cluster, VCN
  cache) Cache Stats   - View cache status, age, and refresh options
  /)     Search        - Search resources by OCID, name, or free text

  » Env Setup
  setup) Env Setup    - Configure local dev tools (tmux, etc.)

  q)     Quit

  Shortcuts: c1, k2, s3, etc. jump directly to a resource
  Global nav: type :c, :k1, :n2, etc. from any prompt to jump
  Quick env: env c (compartment), env r (region), env oke, env vcn

  [OCI Management] Selection (c, k, n, s, i, o, r, env [c|r|oke|vcn], /, setup, q):
```

---

### Compute Menu (`--manage c`)

```
  ═══════════════════════════════════════════════════════════════════════════════
                                      COMPUTE
  ═══════════════════════════════════════════════════════════════════════════════
  Main > Compute

   1) Compute Instances             - View instance details, IPs, and volumes
   2) Instance Configurations       - Create, view, compare, and delete instance configs
   3) Compute Clusters              - Create, view, and delete compute clusters
   4) GPU Memory Fabrics & Clusters - Manage GPU memory fabrics and clusters
   5) Capacity Topology             - View host lifecycle states and details summary
   6) Custom Images                 - List, import, create, and export custom images
   7) GPU Instance Tagging          - Manage ComputeInstanceHostActions namespace and tags
   8) Instance Pools                - Create, view, and manage instance pools
   9) Cluster Networks              - View cluster networks and instance details
  10) Compute Hosts                 - View bare-metal host health, state, and topology
  11) Host Groups                   - Create, view, attach/detach BM hosts to host groups
  12) Notifications                 - ONS topics, subscriptions for compute host events

  [Compute] Selection (1-12, env [c|r|oke|vcn], b):
```

---

### Compute Instances (`--manage c,1`)

```
  Region: us-phoenix-1   Compartment: gpu-workloads   OKE: oke-gpu-prod

  [Compute Instances (32)]
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  ID    I  Display Name                                   State     K8s    Cordon  Taint   Pods  Shape               AD   FD   Created
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  i1       gpu-worker-node-01                             RUNNING   Ready  -       -         14  BM.GPU.H100.8       AD1  FD1  2026-01-15 08:32
  i2       gpu-worker-node-02                             RUNNING   Ready  -       -         12  BM.GPU.H100.8       AD1  FD2  2026-01-15 08:34
  i3    I  gpu-worker-node-03                             RUNNING   Ready  true    maint      0  BM.GPU.H100.8       AD1  FD3  2026-01-15 08:36
  i4       gpu-worker-node-04                             RUNNING   NotRdy true    newNode    0  BM.GPU.H100.8       AD2  FD1  2026-01-16 09:12
  i5       gpu-worker-node-05                             STOPPED   -      -       -          0  BM.GPU.H100.8       AD2  FD2  2026-01-16 09:14
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  Showing 5 of 32  (excluding TERMINATED)   Hidden: host_id rack_id serial_num ocid — use 'col' to toggle

  i# detail  /search  taint  untaint  cordon  uncordon  drain  reboot  cdt  terminate  bvr  brc  p  col
  [Compute Instances] i#, /, taint, cordon, drain, reboot, cdt, terminate, bvr, brc, p, col, q >
```

---

### Compute Hosts + RDMA Topology (`--manage c,10`)

```
  [Compute Hosts — RDMA Topology Overview]

  ├── HPC Island          [2 nb, 6 lb, 48 hosts       ]  [ocid1.hpcisland.oc1.phx...a1b2c3]
  │   ├── Network Block   [3 lb, 24 hosts              ]  [ocid1.computenetworkblock...d4e5f6]
  │   │   ├── Local Block [8 hosts                     ]  [ocid1.computelocalblock...g7h8i9]
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [OCCUPIED ] [HEALTHY  ]  [ocid1.computehost...j0k1l2]  ✓ instance
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [OCCUPIED ] [HEALTHY  ]  [ocid1.computehost...m3n4o5]  ✓ instance
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [OCCUPIED ] [DEGRADED ]  [ocid1.computehost...p6q7r8]  ✓ instance  [Impacted: HPCRDMA-0002-02 ×8 NIC/DOWNTIME maint:DOWNTIME]
  │   │   │   └── BM.GPU.H100.8 [fabric-ab12c]  [OCCUPIED ] [HEALTHY  ]  [ocid1.computehost...s9t0u1]  ✓ instance
  │   │   ├── Local Block [8 hosts                     ]  [ocid1.computelocalblock...v2w3x4]
  │   │   │   └── ...
  │   │   └── Local Block [8 hosts                     ]  [ocid1.computelocalblock...y5z6a7]
  │   │       └── ...
  │   └── Network Block   [3 lb, 24 hosts              ]  [ocid1.computenetworkblock...b8c9d0]
  │       └── ...
  └── HPC Island          [1 nb, 3 lb, 24 hosts       ]  [ocid1.hpcisland.oc1.phx...e1f2g3]
      └── ...

  ◆ Summary
  By State:   OCCUPIED(46) AVAILABLE(2)     By Health:  HEALTHY(44) DEGRADED(3) UNHEALTHY(1)
  By Shape:   BM.GPU.H100.8(48)

  ◆ GPU Memory Fabrics (6)

  Fabric         Shape                   AD  Hosts  InUse  Avail    Imp  Impact Details
  -------------- ---------------------- ---- ------ ------ ------ ------  -----------------------------
  fabric-ab12c   BM.GPU.H100.8          AD-1      8      8      0      1  HPCRDMA-0002-02 x8 NIC/DOWNTIME (DOWNTIME)
  fabric-cd34e   BM.GPU.H100.8          AD-1      8      8      0      0  -
  fabric-ef56g   BM.GPU.H100.8          AD-1      8      8      0      0  -
  fabric-gh78i   BM.GPU.H100.8          AD-2      8      8      0      0  -
  fabric-ij90k   BM.GPU.H100.8          AD-2      8      6      2      0  -
  fabric-kl12m   BM.GPU.H100.8          AD-2      8      8      0      0  -
  -------------- ---------------------- ---- ------ ------ ------ ------
                 Total                            48     46      2      1  1 of 6 fabrics impacted

  Total Hosts: 48
```

### Compute Host Detail (`--manage c,10` → `h#`)

```
  [Compute Host - computebaremetalhost-p6q7r8]
  ──────────────────────────────────────────────────────────────────────────────────
    Display Name:         computebaremetalhost-p6q7r8
    State:                OCCUPIED
    Health:               UNHEALTHY
    Shape:                BM.GPU.H100.8
    Platform:             GPU_H100-NVL8_S.02
    Fault Domain:         FAULT-DOMAIN-3
    Instance:             ocid1.instance.oc1.phx...a1b2c3
    Has Impacted:         true

  ── Impacted Components ─────────────────────────────────────────────────────────
    Maintenance Type:     DOWNTIME
    State:                ACTIVE
    Customer Impacting:   true
    ── Components ──
    1)  NIC       DOWNTIME  HPCRDMA-0002-03  MEDIUM  [impacting]
    2)  GPU       DOWNTIME  GPUFAIL-0010-01  HIGH    [impacting]

  ── Recycle Details ─────────────────────────────────────────────────────────────
    Recycle Level:        FULL_RECYCLE

  ── Topology ────────────────────────────────────────────────────────────────────
    HPC Island:           ocid1.hpcisland.oc1.phx...a1b2c3
    Network Block:        ocid1.computenetworkblock...d4e5f6
    Local Block:          ocid1.computelocalblock...g7h8i9
    GPU Fabric:           ocid1.computegpumemoryfabric...j0k1l2
  ──────────────────────────────────────────────────────────────────────────────────

  [Compute Host - computebaremetalhost-p6q7r8] q >
```

---

### Host Groups (`--manage c,11`)

```
  ◆ Existing Host Groups

  #    Display Name                                       Availability Domain       State        Targeted   Created
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1)   skip_recycle_ad_X                                  AP-OSAKA-1-AD-1           ACTIVE       No         2026-04-09
  2)   skip_recycle_BM.GPU4.8_ap-osaka-1_AD_1_HG          AP-OSAKA-1-AD-1           ACTIVE       No         2026-04-10

  Total: 2 host group(s)

  #) View    - View host group details (enter number)
  c) Create  - Create a new host group
  d) Delete  - Delete host group(s) (d 1, d 1,2, d 1-2, d all)
  j) JSON    - View raw JSON (j <keyword> to search)
  r) Refresh - Refresh host group list
  b) Back    - Return to compute menu

  [Host Groups] Selection (#, c, d [#|#,#|#-#|all], j, r, b, show):
```

### Host Group Detail (`--manage c,11` → `1`)

```
  ◆ Properties
  Display Name:        skip_recycle_ad_X
  OCID:                ocid1.computehostgroup.oc1.ap-osaka-1.anvwsljr2bemolaawsyjzqsvylhutnghlauxdbkumfbgo4bwe45c3476yfka
  Availability Domain: AP-OSAKA-1-AD-1
  Lifecycle State:     ACTIVE
  Targeted Placement:  No
  Time Created:        2026-04-09T22:58:22.626000+00:00
  Time Updated:        2026-04-09T22:58:22.626000+00:00

  ◆ Configurations (1)
  #    Target Shape       Recycle Level        Firmware Bundle                State
  ───────────────────────────────────────────────────────────────────────────────────────────────
  1    BM.GPU4.8          SKIP_RECYCLE         -                              -

  ◆ Attached Bare Metal Hosts (1)
  #    Display Name                             Shape           State        Health     Bare Metal Host OCID
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1    computebaremetalhost-pefjq               BM.GPU4.8       AVAILABLE    HEALTHY    ocid1.computebaremetalhost.oc1.ap-osaka-1.anvwsljr2bemolaczibwi7u37sddwdlznszwfk3jih72oz3wz5ommhopefjq

  a)      Attach  - Attach a bare metal host to this group
  dt #)   Detach  - Detach a bare metal host (dt 1)
  notify) Notify  - Set up event notifications for host changes
  j)      JSON    - View raw JSON
  r)      Refresh - Refresh details
  Enter)  Back    - Return to host group list

  [Host Group - skip_recycle_ad_X] Selection (a, dt #, notify, j, r, Enter):
```

### Host Group Create (`--manage c,11` → `c`)

```
  ◆ Pre-flight Check — Capacity Topology (c5)

  Checking capacity topology in ap-osaka-1 / AP-OSAKA-1-AD-1...
  ✓ capacity topology (AP-OSAKA-1-AD-1), 2.1s
  ✓ Found 8 capacity topology host(s) in ap-osaka-1 / AP-OSAKA-1-AD-1

  ◆ Target Shape

  Fetching BM.GPU shapes...
    1) BM.GPU.A10.4
    2) BM.GPU3.8
    3) BM.GPU4.8

  Select shape: 3
  ✓ Target: BM.GPU4.8

  ◆ Recycle Level
  1) SKIP_RECYCLE  - Skip host recycling (default)
  2) RECYCLE       - Standard recycling
  Select recycle level [1]: 1
  ✓ Recycle Level: SKIP_RECYCLE

  ◆ Display Name
  Suggested: skip_recycle_BM.GPU4.8_ap-osaka-1_AD_1_HG
  Enter display name [skip_recycle_BM.GPU4.8_ap-osaka-1_AD_1_HG]:
  ✓ Display Name: skip_recycle_BM.GPU4.8_ap-osaka-1_AD_1_HG

  ◆ Targeted Placement
  Targeted placement required? (y/N): n
  ✓ Targeted Placement: false

  Command:
  oci compute compute-host-group create \
    --availability-domain "jLaG:AP-OSAKA-1-AD-1" \
    --compartment-id "ocid1.compartment..." \
    --region "ap-osaka-1" \
    --display-name "skip_recycle_BM.GPU4.8_ap-osaka-1_AD_1_HG" \
    --configurations '[{"target":"BM.GPU4.8","recycleLevel":"SKIP_RECYCLE"}]' \
    --is-targeted-placement-required false

  Type 'CREATE' to confirm:
```

---

### Notifications (`--manage c,12`)

```
  ◆ ONS Topics (2)

  #    Name                                     State        Topic OCID
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1)   compute-host-events                      ACTIVE       ocid1.onstopic.oc1.ap-osaka-1...
  2)   gpu-alerts                                ACTIVE       ocid1.onstopic.oc1.ap-osaka-1...

  ◆ Event Rules (1)

  #    Display Name                             State      Enabled  Event Types
  ────────────────────────────────────────────────────────────────────────────────────────────────────────
  e1)  host-events-skip_recycle_ad_X            ACTIVE     Yes      compute.computehost.upda...

  #)     View        - View topic subscriptions
  c)     Create      - Create a new ONS topic
  s)     Subscribe   - Add subscription to a topic (email, webhook, PagerDuty)
  d #)   Delete      - Delete topic
  e#)    View Rule   - View event rule details (e1, e2...)
  ed #)  Delete Rule - Delete event rule (ed 1, ed 2...)
  r)     Refresh
  b)     Back

  [Notifications] Selection (#, c, s, d #, e#, ed #, r, b):
```

### Event Rule Detail (`--manage c,12` → `e1`)

```
  ◆ Event Rule: host-events-skip_recycle_ad_X

  Name:        host-events-skip_recycle_ad_X
  OCID:        ocid1.eventrule.oc1.ap-osaka-1...
  State:       ACTIVE
  Enabled:     Yes
  Created:     2026-04-10T06:10:12Z

  Event Types:
    • com.oraclecloud.compute.computehost.update
    • com.oraclecloud.compute.computehost.healthchange
    • com.oraclecloud.compute.computehostgroup.update
    • com.oraclecloud.compute.computehost.attach
    • com.oraclecloud.compute.computehost.detach

  Actions:
    ONS → ocid1.onstopic.oc1.ap-osaka-1...
```

---

### GPU Memory Fabrics & Clusters (`--manage c,4`)

```
  [GPU Memory Fabrics & Clusters]
    f# = GPU Memory Fabric    g# = GPU Memory Cluster
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
  ID    Display Name                                  State         Healthy  Avail  Total  OCID
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
  f1    gpu-fabric-prod-phx-01                        ACTIVE             48     48     48  ocid1.gpumemfabric...a1b2c3
       │  Fw  Firmware: HEALTHY                       cur:25.02.10     tgt:25.02.10  [up-to-date]
       ├── g1  gpu-cluster-prod-01                    ACTIVE                          8  ocid1.gpucluster...d4e5f6
       │         Compute Cluster: cc-gpu-prod-01
       │         Instance Config:  ic-bm-gpu-h100
       ├── g2  gpu-cluster-prod-02                    ACTIVE                          8  ocid1.gpucluster...g7h8i9
       │         Compute Cluster: cc-gpu-prod-02
       │         Instance Config:  ic-bm-gpu-h100
       └── g3  gpu-cluster-dev-01                     PROVISIONING                    8  ocid1.gpucluster...j0k1l2
                 Compute Cluster: cc-gpu-dev-01
                 Instance Config:  ic-bm-gpu-h100-dev
  f2    gpu-fabric-prod-phx-02                        ACTIVE             32     32     32  ocid1.gpumemfabric...m3n4o5
       │  Fw  Firmware: UPDATING                      cur:25.01.08     tgt:25.02.10
       └── g4  gpu-cluster-prod-03                    ACTIVE                          8  ocid1.gpucluster...p6q7r8
                 Compute Cluster: cc-gpu-prod-03
                 Instance Config:  ic-bm-gpu-h100
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
         Summary (2 fabrics)                                80     80     80
         GPU Memory Clusters: 4   Cluster Nodes Provisioned: 32

  f# fabric detail  g# cluster detail  r refresh  q back
  [GPU Memory Fabrics] f#, g#, r, q >
```

---

### Custom Images (`--manage c,6`)

```
  [Custom Images (4)]
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
  #   Image Name                                                             OS                Status        Size    Created
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1   gpu-ubuntu-22-04-cuda-12-oci-2026-01-15                               Oracle Linux 8.9  AVAILABLE     52.5 GB 2026-01-15
  2   oke-worker-custom-ubuntu-22-base                                       Ubuntu 22.04      AVAILABLE     46.8 GB 2026-01-18
  3   gpu-worker-rdma-image-v2                                               Oracle Linux 8.9  AVAILABLE     58.2 GB 2026-02-01
  4   test-image-scratch                                                     Oracle Linux 8.9  IMPORTING      0.0 GB 2026-02-28
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────

  # detail  import  create  export  shapes  delete
  [Custom Images] #, import, create, export, shapes, delete, q >
```

---

### OKE Cluster Environment (`--manage k,1`)

```
  ╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║                                   OKE CLUSTER ENVIRONMENT                                      ║
  ╠══════════════════════════════════════════════════════════════════════════════════════════════════╣
  ║  Tenancy:          ocid1.tenancy.oc1..aaaaaa...xxxxxxxxxx                                      ║
  ║  Region:           us-phoenix-1                                                                ║
  ║  Compartment:      gpu-workloads  (ocid1.compartment.oc1..aaaaaa...yyyyyy)                     ║
  ║  Avail. Domains:   PHX-AD-1, PHX-AD-2, PHX-AD-3                                               ║
  ║  OKE Cluster:      oke-gpu-prod [ACTIVE]  (ocid1.cluster.oc1.phx.aaaaaa...zzzzzz)             ║
  ║  OKE Version:      v1.30.1                                                                    ║
  ║  Pod Network:      OCI_VCN_IP_NATIVE (10.244.0.0/16)                                          ║
  ║  Cluster Addons:   3 installed                                                                 ║
  ║  VCN:              vcn-gpu-prod  (ocid1.vcn.oc1.phx.aaaaaa...vvvvvv)                           ║
  ╠══════════════════════════════════════════════════════════════════════════════════════════════════╣
  ║  GPU Operator:     gpu-operator v24.9.0  (deployed)                                            ║
  ║  DRA Driver:       nvidia-dra-driver v0.7.0  (deployed)                                        ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

  [Node Pools (2)]
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  #   Pool Name                  Shape              Size  Version   Status
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  1   np-gpu-h100-workers        BM.GPU.H100.8        32  v1.30.1   ACTIVE
  2   np-standard-utilities      VM.Standard.E5.Flex   3  v1.30.1   ACTIVE
  ──────────────────────────────────────────────────────────────────────────────────────────────────

  np# detail  addons  oke select  cc compare clusters  cn compare node pools
  [OKE Cluster] np#, addons, oke, cc, cn, q >
```

---

### Network Resources (`--manage n`)

```
  [Network Resources — vcn-gpu-prod]

  [Virtual Cloud Network]
   1) VCN: vcn-gpu-prod                           10.0.0.0/16   ocid1.vcn.oc1.phx...a1b2c3

  [Subnets]
   2) Subnet: subnet-oke-workers        [10.0.1.0/24  ] [Private] RT: rt-private-workers          ocid1.subnet...d4e5f6
         ├─ SL:  sl-private-standard   [In:5  Out:3]
         ├─ NSG: nsg-gpu-workers       In:3  Out:2
         └─ NSG: nsg-oke-cluster       In:2  Out:2
   3) Subnet: subnet-oke-endpoint       [10.0.0.0/29  ] [Private] RT: rt-private-endpoint         ocid1.subnet...g7h8i9
         └─ SL:  sl-endpoint           [In:3  Out:2]
   4) Subnet: subnet-oke-lb             [10.0.2.0/24  ] [Public ] RT: rt-public-lb                ocid1.subnet...j0k1l2

  [Route Tables]
   5) RT: rt-private-workers            [Rules:4]  ocid1.routetable...m3n4o5
   6) RT: rt-public-lb                  [Rules:3]  ocid1.routetable...p6q7r8

  [Gateways]
   7) Internet GW:  igw-gpu-prod        [AVAILABLE]  ocid1.internetgateway...s9t0u1
   8) NAT GW:       nat-gpu-prod        [AVAILABLE]  ocid1.natgateway...v2w3x4
   9) Service GW:   sgw-gpu-prod        [AVAILABLE]  ocid1.servicegateway...y5z6a7
  10) DRG:          drg-gpu-prod        [AVAILABLE]  ocid1.drg...b8c9d0

  # detail  / search port  drg connectivity map  xr cross-region DRG
  [Network Resources] #, /, drg, xr, q >
```

---

### Compartments (`--manage i,1`)

```
  [Compartment Hierarchy (6 compartments)]
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  1) MyTenancy                            (root tenancy, 3 sub)    ocid1.tenancy.oc1..aaaaaa...t1
     ├── 2) gpu-workloads                 (ACTIVE, 2 sub)          ocid1.compartment.oc1..aaaaaa...c1
  ►  │   ├── 3) gpu-prod                 (ACTIVE)                 ocid1.compartment.oc1..aaaaaa...c2
     │   └── 4) gpu-dev                  (ACTIVE)                 ocid1.compartment.oc1..aaaaaa...c3
     ├── 5) networking                   (ACTIVE)                 ocid1.compartment.oc1..aaaaaa...c4
     └── 6) storage                      (ACTIVE)                 ocid1.compartment.oc1..aaaaaa...c5
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  ► = current focus

  # select compartment  r refresh
  [Compartments] #, r, q >
```

---

### Policies (`--manage i,3`)

```
  [Policy Management]
  Tenancy: MyTenancy   Policies: 14 in 4 compartments

  1) View All Policies        2) Search by Keyword     3) Filter by OCI Service
  4) Filter by Compartment    5) Filter by Policy Name 6) Export JSON
  7) Policy Validation Check

  ─── Policy Tree (option 1) ───

  MyTenancy (root)
  ├── [policy: tenancy-admin-policy]
  │     Allow group Administrators to manage all-resources in tenancy
  │     Allow group NetworkAdmins to manage virtual-network-family in tenancy
  │
  ├── gpu-workloads
  │   ├── [policy: gpu-workload-policy]
  │   │     Allow group GpuUsers to manage instance-family in compartment gpu-workloads
  │   │     Allow group GpuUsers to manage cluster-family in compartment gpu-workloads
  │   │
  │   └── gpu-prod
  │       └── [policy: gpu-prod-limits]
  │             Allow group GpuOps to manage compute-capacity-reservations in compartment gpu-prod
  │
  └── networking
      └── [policy: network-admin-policy]
            Allow group NetworkAdmins to manage virtual-network-family in compartment networking

  [Policies] 1-7, q >
```

---

### Maintenance Events (`--manage o,3`)

```
  #   Instance Name             K8s Node            Serial        State     K8s    Crdn  Taints  Pods  Maint Reason          Lifecycle   Event Name                 Window Start
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1   gpu-worker-node-03        gpu-worker-03       SN-A1B2C3D4   RUNNING   Ready  false none      0   HARDWARE_FAILURE      SCHEDULED   LIVE_MIGRATION             2026-03-10T08:00:00
  2   gpu-worker-node-07        gpu-worker-07       SN-X7Y8Z9A0   RUNNING   Ready  true  maint     7   PLANNED_MAINTENANCE   SUCCEEDED   REBOOT_MIGRATION           2026-02-15T12:00:00
  3   gpu-worker-node-12        gpu-worker-12       SN-D5E6F7G8   RUNNING   Ready  false none     14   HARDWARE_FAILURE      SCHEDULED   LIVE_MIGRATION             2026-03-12T06:00:00
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

  ◆ Summary

  Total: 62 maintenance event(s)

  By Fault Code:
  Month     Fault Code               Nodes   SCHED    PASS  CANCEL    FAIL
  --------- ---------------------- ------ ------- ------- ------- -------
  Feb 2026  HPCRDMA-0002-02            38      20      12       5       1
            SMARTNIC-8000-17            3       -       -       3       -
            SPNVDA-XID149-0400          1       -       -       1       -
  Mar 2026  HPCRDMA-0002-02            14      12       -       2       -
            HPCRDMA-0002-03             4       3       -       1       -
            HPCRDMA-0002-04             1       1       -       -       -
            SMARTNIC-8000-17            1       1       -       -       -
  --------- ---------------------- ------ ------- ------- ------- -------
  Totals by Fault Code:
            HPCRDMA-0002-02            52      32      12       7       1
            HPCRDMA-0002-03             4       3       -       1       -
            HPCRDMA-0002-04             1       1       -       -       -
            SMARTNIC-8000-17            4       1       -       3       -
            SPNVDA-XID149-0400          1       -       -       1       -
  --------- ---------------------- ------ ------- ------- ------- -------
            Total                      62      37      12      12       1

  Fault Code Reference:
  ──────────────────────────────────────────────────────────────────────────────────
  HPCRDMA-0002-02 [HPC_NIC]
    Description:  A network component requires maintenance to prevent degraded performance
    Impact:       Host may experience brief network interruption during maintenance window
  ──────────────────────────────────────────────────────────────────────────────────
  SMARTNIC-8000-17 [SMART_NIC]
    Description:  SmartNIC firmware update required for security patch
    Impact:       Network throughput may be reduced during update
  ──────────────────────────────────────────────────────────────────────────────────

  By GPU Fabric:
  Month     Fabric           Fault Code            Nodes   SCHED    PASS  CANCEL    FAIL
  --------- ---------------- -------------------- ------ ------- ------- ------- -------
  Feb 2026  fabric-x1y2z     HPCRDMA-0002-02           8       4       4       -       -
  Mar 2026  fabric-a3b4c     HPCRDMA-0002-03           1       1       -       -       -
            fabric-x1y2z     HPCRDMA-0002-02           4       5       -       -       -
                             SMARTNIC-8000-17          1       -       -       -       -
            fabric-d5e6f     HPCRDMA-0002-02          14      14       -       -       -
            fabric-g7h8i     HPCRDMA-0002-02           1       1       -       -       -
  --------- ---------------- -------------------- ------ ------- ------- ------- -------
  Totals by Fabric/Fault Code:
            fabric-a3b4c     HPCRDMA-0002-03           1       1       -       -       -
            fabric-x1y2z     HPCRDMA-0002-02          12       9       4       -       -
                             SMARTNIC-8000-17          1       -       -       -       -
            fabric-d5e6f     HPCRDMA-0002-02          14      14       -       -       -
            fabric-g7h8i     HPCRDMA-0002-02           1       1       -       -       -
  --------- ---------------- -------------------- ------ ------- ------- ------- -------
                             Total                    29      25       4       0       0  4 fabric(s)

  m# event detail  h# host detail  m#,r reschedule  view toggle  col columns  r refresh
  [Maintenance Events] m#, h#, view, col, r, q >
```

---

### Service Limits — GPU Capacity (`--manage o,5,4`)

```
  ━━━ Compute Standard Capacity ━━━

  BM GPU
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  Shape / Limit                              PHX-AD-1                PHX-AD-2                PHX-AD-3
                                                  Cap   Used  Limit      Cap   Used  Limit      Cap   Used  Limit
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  BM.GPU.H100.8 (gpu-h100-count)                   ✓     24     32       ✓     16     32       ✗      0      0
  BM.GPU.A100-v2.8 (gpu-a100-v2-count)             ✓      8     16       ✓      0     16       ✓      0     16
  BM.GPU.B200.8 (gpu-b200-count)                   ✓      0      8       ✓      0      8       ✗      0      0

  VM GPU
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  VM.GPU.A10.1 (gpu-a10-count)                     ✓      0     10       ✓      2     10       ✓      1     10
  VM.GPU.A10.2 (gpu-a10-count)                     ✓      0      5       ✓      0      5       ✗      0      0

  Flex Compute
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  VM.Standard.E5.Flex (standard-e5-core-count)     ✓      0   1000       ✓      0   1000       ✓      0   1000

  ✓ = capacity available    ✗ = no capacity / no limit
  [Service Limits] q >
```

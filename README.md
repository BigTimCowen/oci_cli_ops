**OCI CLI Operations** — Interactive management tool for Oracle Cloud Infrastructure, Kubernetes, and GPU infrastructure.

**Version:** 3.25.73 | **Date:** 2026-03-04

## Overview

`oci_cli_ops.sh` — 71K lines of bash that turns your terminal into a full OCI management console. OCI CLI + kubectl, menu-driven, zero web UI required.

🔥 *Compute* (10 sub-sections)
Instance lifecycle with K8s cordon/drain/taint/terminate workflows, GPU Memory Fabrics & Clusters with firmware tracking, Capacity Topology with RDMA tree visualization, Custom Images, Instance Pools, Cluster Networks, Compute Hosts with impacted component details and recycle status, and more

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

The script reads from `variables.sh` in the same directory. Run `--setup` to auto-populate from instance metadata, or configure manually:

```bash
REGION="us-ashburn-1"
TENANCY_ID="ocid1.tenancy.oc1..aaaa..."
COMPARTMENT_ID="ocid1.compartment.oc1..aaaa..."
```

Global options available on any invocation:

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
| `c1` | Compute Instances | Instance list with K8s status, cordon/drain/taint, BVR, bulk run-command |
| `c2` | Instance Configurations | Create, view, compare, and delete instance configs |
| `c3` | Compute Clusters | Create, view, and delete compute clusters |
| `c4` | GPU Memory Fabrics & Clusters | Manage GPU fabrics, clusters, firmware bundles |
| `c5` | Capacity Topology | Host lifecycle states, RDMA topology tree |
| `c6` | Custom Images | Import, create from instance, export, shape compatibility |
| `c7` | GPU Instance Tagging | ComputeInstanceHostActions namespace and tags |
| `c8` | Instance Pools | Create, view, and manage instance pools |
| `c9` | Cluster Networks | View cluster networks and instance details |
| `c10` | Compute Hosts | Bare-metal host health, state, topology, impacted component details (`h#` drill-down), recycle status |

**Instance Actions** (`c1` prompt): `i#` (detail), `/` (search), `taint`, `untaint`, `cordon`, `uncordon`, `drain`, `reboot`, `cdt` (Cordon-Drain-Tag-Terminate), `terminate`, `bvr` (Boot Volume Replacement), `brc` (Bulk Run-Command), `p` (properties view), `col` (column picker)

---

### k) Kubernetes

| Option | Function | Description |
|--------|----------|-------------|
| `k1` | OKE Cluster Environment | Cluster details, VCN, node pools, add-ons |
| `k2` | NVIDIA GPU Stack Health | GPU Operator and DRA component status per node |
| `k3` | Kubernetes Management | Node diagnostics, RDMA, SSH keys (11 sub-options) |

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
| `o3` | Maintenance | Instance maintenance events, reschedule windows |
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
env c   — Change compartment (hierarchical tree selector with root tenancy)
env r   — Change region (all subscribed regions listed)
env oke — Change OKE cluster
env vcn — Change VCN
```

Focus can be saved to `variables.sh` via `env` → `s` (save). The current focus is shown in the header of every menu.

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
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

Sample terminal output for key management screens. All data is sanitized — no real OCIDs, tenancy names, or infrastructure details.

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
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [ACTIVE  ] [OK       ]  [ocid1.computehost...j0k1l2]  ✓ worker-01
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [ACTIVE  ] [OK       ]  [ocid1.computehost...m3n4o5]  ✓ worker-02
  │   │   │   ├── BM.GPU.H100.8 [fabric-ab12c]  [ACTIVE  ] [DEGRADED ]  [ocid1.computehost...p6q7r8]  ✓ worker-03  [Impacted: NIC/DOWNTIME HPCRDMA-0002 | FULL_RECYCLE]
  │   │   │   └── BM.GPU.H100.8 [fabric-ab12c]  [ACTIVE  ] [OK       ]  [ocid1.computehost...s9t0u1]  ✓ worker-04
  │   │   ├── Local Block [8 hosts                     ]  [ocid1.computelocalblock...v2w3x4]
  │   │   │   └── ...
  │   │   └── Local Block [8 hosts                     ]  [ocid1.computelocalblock...y5z6a7]
  │   │       └── ...
  │   └── Network Block   [3 lb, 24 hosts              ]  [ocid1.computenetworkblock...b8c9d0]
  │       └── ...
  └── HPC Island          [1 nb, 3 lb, 24 hosts       ]  [ocid1.hpcisland.oc1.phx...e1f2g3]
      └── ...

  By State:   ACTIVE(46) INACTIVE(2)     By Health:  OK(44) DEGRADED(3) UNHEALTHY(1)
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
  ══════════════════════════════════════════════════════════════════════════════════════════════════
  INSTANCES REQUIRING MAINTENANCE ATTENTION
  Showing instances with: unhealthy compute host health state
  ══════════════════════════════════════════════════════════════════════════════════════════════════
  ID  Display Name              OCI State  K8s Node            Ready  Cordon Pods  CompHost  Serial        Shape              Instance OCID
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1   gpu-worker-node-03        RUNNING    gpu-worker-03       False  false    0   ch-ab12   SN-A1B2C3D4   BM.GPU.H100.8      ocid1.instance...x1y2z3
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                                                                                                 Current UTC: 2026-03-02T14:33:01Z
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  #   Instance Name             K8s Node            Serial        State     K8s    Crdn  Taints  Pods  Maint Reason          Lifecycle   Event Name                 Window Start
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1   gpu-worker-node-03        gpu-worker-03       SN-A1B2C3D4   RUNNING   Ready  false none      0   HARDWARE_FAILURE      SCHEDULED   LIVE_MIGRATION             2026-03-10T08:00:00
  2   gpu-worker-node-07        gpu-worker-07       SN-X7Y8Z9A0   RUNNING   Ready  true  maint     7   PLANNED_MAINTENANCE   ONGOING     REBOOT_MIGRATION           2026-03-02T12:00:00
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  Hidden: category announce fault_code comp_host — use 'col' to toggle

  m# event detail  m#,r reschedule  view toggle  col columns  r refresh
  [Maintenance Events] m#, view, col, r, q >
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

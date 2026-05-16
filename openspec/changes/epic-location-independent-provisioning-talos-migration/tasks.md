## 1. Talos Machine Config Setup

- [x] 1.1 Create `talos/` directory structure in git repo (`talos/rammus/`, `talos/karma/`, `talos/patches/`)
- [x] 1.2 Create Talos machine config template for rammus (standard k8s, NOT k3s)
- [x] 1.3 Create Talos machine config template for karma (standard k8s, NOT k3s)
- [x] 1.4 Create shared network patch (DNS, NTP)
- [ ] 1.5 Create Tailscale extension patch (template exists but needs auth key integration)
- [ ] 1.6 Create SOPS/Age key patch (template exists but needs key integration)
- [x] 1.7 Validate machine configs with `talosctl validate`

## 2. Test Migration (Staging)

> **Requires physical access to a spare T440p.** These tasks are manual and cannot be automated from the devcontainer.

- [ ] 2.1 Flash Talos ISO to USB drive
- [ ] 2.2 Install Talos on a spare T440p using the rammus machine config
- [ ] 2.3 Bootstrap Kubernetes on the test node
- [ ] 2.4 Bootstrap FluxCD against the test node
- [ ] 2.5 Verify all workloads reconcile correctly (Soft Serve, Audiobookshelf, Linkding, cert-manager, monitoring)
- [ ] 2.6 Verify SOPS secret decryption works
- [ ] 2.7 Verify Tailscale extension connects and provides OS-level access
- [ ] 2.8 Test `talosctl` access remotely via Tailscale IP
- [ ] 2.9 Document any workarounds needed for standard k8s on Talos

## 3. Production Migration (rammus)

> **Requires physical access to the rammus T440p.** These tasks are manual and cannot be automated from the devcontainer.

- [ ] 3.1 Backup all Persistent Volume data (Soft Serve repos, Audiobookshelf data, Linkding data)
- [ ] 3.2 Backup SOPS Age private key to password manager
- [ ] 3.3 Export FluxCD reconciliation state
- [ ] 3.4 Flash Talos ISO to USB and install on rammus T440p
- [ ] 3.5 Apply rammus machine config via `talosctl apply-config`
- [ ] 3.6 Bootstrap Kubernetes and FluxCD on rammus
- [ ] 3.7 Verify all workloads are running and healthy
- [ ] 3.8 Verify Tailscale OS-level connectivity
- [ ] 3.9 Restore Persistent Volume data from backup

## 4. Production Migration (karma)

> Note: karma is a fresh install, no backup/restore needed.
> **Provisioning script created:** `scripts/provision-karma.sh`

- [x] 4.1 Install Talos on karma T440p (via `provision-karma.sh`)
- [x] 4.2 Apply karma machine config (via `provision-karma.sh`)
- [x] 4.3 Bootstrap Kubernetes and FluxCD on karma (via `provision-karma.sh`)
- [x] 4.4 Verify RustFS is running and accessible (220Gi PVC bound)
- [x] 4.5 Verify Flux reconciles all karma manifests (apps, infra-controllers, infra-configs all True)

## 5. Cleanup and Documentation

- [ ] 5.1 Remove Debian/Ubuntu-specific configurations from git (if any)
- [x] 5.2 Update README with Talos provisioning instructions (via `provision-karma.sh`)
- [ ] 5.3 Document `talosctl` common commands for remote management
- [ ] 5.4 Verify automated backup strategy still works on Talos

## 1. Talos Machine Config Setup

- [ ] 1.1 Create `talos/` directory structure in git repo (`talos/rammus/`, `talos/karma/`, `talos/patches/`)
- [ ] 1.2 Generate initial Talos machine config for rammus (controlplane mode with k3s)
- [ ] 1.3 Generate initial Talos machine config for karma (controlplane mode with k3s)
- [ ] 1.4 Create shared network patch (DNS, NTP, interfaces)
- [ ] 1.5 Create Tailscale extension patch (auth key reference, extension install)
- [ ] 1.6 Create SOPS/Age key patch (Age key for Flux secret decryption)
- [ ] 1.7 Validate machine configs with `talosctl validate`

## 2. Test Migration (Staging)

- [ ] 2.1 Flash Talos ISO to USB drive
- [ ] 2.2 Install Talos on a spare T440p using the rammus machine config
- [ ] 2.3 Bootstrap k3s on the test node
- [ ] 2.4 Bootstrap FluxCD against the test node
- [ ] 2.5 Verify all workloads reconcile correctly (Soft Serve, Audiobookshelf, Linkding, cert-manager, monitoring)
- [ ] 2.6 Verify SOPS secret decryption works
- [ ] 2.7 Verify Tailscale extension connects and provides OS-level access
- [ ] 2.8 Test `talosctl` access remotely via Tailscale IP
- [ ] 2.9 Document any workarounds needed for k3s on Talos

## 3. Production Migration (rammus)

- [ ] 3.1 Backup all Persistent Volume data (Soft Serve repos, Audiobookshelf data, Linkding data)
- [ ] 3.2 Backup SOPS Age private key to password manager
- [ ] 3.3 Export FluxCD reconciliation state
- [ ] 3.4 Flash Talos ISO to USB and install on rammus T440p
- [ ] 3.5 Apply rammus machine config via `talosctl apply-config`
- [ ] 3.6 Bootstrap k3s and FluxCD on rammus
- [ ] 3.7 Verify all workloads are running and healthy
- [ ] 3.8 Verify Tailscale OS-level connectivity
- [ ] 3.9 Restore Persistent Volume data from backup

## 4. Production Migration (karma)

- [ ] 4.1 Backup RustFS data
- [ ] 4.2 Install Talos on karma T440p
- [ ] 4.3 Apply karma machine config via `talosctl apply-config`
- [ ] 4.4 Bootstrap k3s and FluxCD on karma
- [ ] 4.5 Verify RustFS is running and accessible
- [ ] 4.6 Restore RustFS data from backup

## 5. Cleanup and Documentation

- [ ] 5.1 Remove Debian/Ubuntu-specific configurations from git (if any)
- [ ] 5.2 Update README with Talos provisioning instructions
- [ ] 5.3 Document `talosctl` common commands for remote management
- [ ] 5.4 Verify automated backup strategy still works on Talos

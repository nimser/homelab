## 1. Hetzner Cloud Setup

- [ ] 1.1 Create Hetzner Cloud account and project
- [ ] 1.2 Pre-credit Hetzner account (€50 recommended)
- [ ] 1.3 Generate hcloud API token and store in SOPS
- [ ] 1.4 Upload SSH public key to Hetzner Cloud
- [ ] 1.5 Test hcloud CLI: create and destroy a test CX22 VM

## 2. Talos Cloud Machine Configs

- [ ] 2.1 Create `talos/rammus-cloud/` directory with cloud-specific machine config
- [ ] 2.2 Create `talos/karma-cloud/` directory with cloud-specific machine config
- [ ] 2.3 Adapt machine configs for Hetzner network (different CIDR, different DNS)
- [ ] 2.4 Validate cloud machine configs with `talosctl validate`
- [ ] 2.5 Test: create Hetzner VM with Talos image and cloud machine config

## 3. Failover Scripts

- [ ] 3.1 Create `scripts/failover-to-cloud.sh` for cluster failover (create VM, apply config, bootstrap FluxCD, restore data, switch DNS)
- [ ] 3.2 Create `scripts/failover-back-home.sh` for cluster failback (sync data, switch DNS, destroy VM)
- [ ] 3.3 Implement RustFS data restore from iDrive e2 in failover script
- [ ] 3.4 Implement RustFS data sync from cloud to home in failback script

## 4. Cloudflare Tunnel Configuration

- [ ] 4.1 Create a Cloudflare tunnel for failover (separate from home tunnel)
- [ ] 4.2 Store failover tunnel token in SOPS
- [ ] 4.3 Create Cloudflare API token for DNS updates and store in SOPS
- [ ] 4.4 Deploy cloudflared with failover tunnel token as FluxCD manifest in cloud configs
- [ ] 4.5 Implement DNS CNAME switching in failover/failback scripts

## 5. Testing

- [ ] 5.1 Test full failover: create Hetzner VM → apply config → bootstrap Flux → restore data → switch DNS
- [ ] 5.2 Test full failback: sync data → switch DNS → destroy VM
- [ ] 5.3 Test: access apps via Cloudflare tunnel during cloud failover
- [ ] 5.4 Test: verify RustFS data integrity after restore
- [ ] 5.5 Document cost per hour of failover (VM + storage + bandwidth)

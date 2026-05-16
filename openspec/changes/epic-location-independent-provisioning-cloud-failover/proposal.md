## Why

When the homelab at the user's parents' home becomes unavailable (fiber outage, hardware failure), the user needs to continue running their apps from a cloud provider. The homelab clusters (rammus and karma) should be location-independent identities that can run on ThinkPads at home or on VMs in the cloud. This change enables spinning up Hetzner cloud VMs on-demand with the same Talos configs and FluxCD workloads.

## What Changes

- Create Hetzner cloud provisioning scripts (failover-to-cloud.sh, failover-back-home.sh)
- Create Talos machine configs for cloud VMs (rammus-cloud, karma-cloud)
- Configure Cloudflare tunnel failover (redirect traffic from home to Hetzner)
- Implement RustFS data restore from iDrive e2 on cloud VMs
- Pre-credit Hetzner account for automated provisioning
- Document the failover and failback procedures

## Capabilities

### New Capabilities
- `cloud-failover`: On-demand provisioning of Hetzner cloud VMs running Talos with identical workloads to home clusters
- `cloudflare-tunnel-failover`: Dynamic redirection of Cloudflare tunnels from home to cloud and back

### Modified Capabilities
_(none)_

## Impact

- Requires Hetzner Cloud account with pre-credited balance (~€7/month per VM during failover only)
- Requires Cloudflare API token for tunnel configuration updates (stored in SOPS)
- Cloud VMs will have different IPs and network configuration than home nodes
- RustFS data will need to be restored from iDrive e2 backup during failover

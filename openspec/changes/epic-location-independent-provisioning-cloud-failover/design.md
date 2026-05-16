## Context

The user's homelab runs on physical ThinkPads at their parents' home. When the home becomes unreachable (fiber outage, hardware death), the user needs to run their entire stack from the cloud. Talos machine configs make this possible - the same declarative config can provision a ThinkPad or a Hetzner VM. The failover process creates Hetzner VMs, applies Talos configs, bootstraps FluxCD, restores data from iDrive e2, and switches Cloudflare tunnels to the cloud.

## Goals / Non-Goals

**Goals:**
- On-demand provisioning of Hetzner cloud VMs running rammus and karma workloads
- Cloudflare tunnel failover to redirect traffic to cloud
- RustFS data restore from iDrive e2 during failover
- Failback procedure to return to home when fiber/hardware recovers
- Keep cloud costs under $5-10/month during active failover

**Non-Goals:**
- Always-on cloud cluster (provisioned only during failover)
- Automated failback (requires manual confirmation)
- Active-active multi-site (home and cloud running simultaneously)

## Decisions

**1. Hetzner Cloud as failover provider**
- CX22 VM (~€3.50/month) is sufficient for single-node k3s workloads
- hcloud CLI for provisioning
- Talos has native Hetzner cloud support (user-data injection)
- Pre-credited account eliminates payment automation concerns
- Alternative (AWS/GCP/Azure) is more expensive and complex for this use case

**2. Talos native Hetzner support for provisioning**
- Use hcloud CLI to create VMs with Talos image
- Inject Talos machine config via user-data
- Same git-tracked configs, different network settings
- Alternative (custom ISO + manual install) is slower and not automatable

**3. Cloudflare tunnel for traffic failover**
- Deploy a second cloudflared instance on the Hetzner VM with a failover tunnel token
- During failover, update Cloudflare DNS CNAME to point to cloud tunnel
- Single API call to switch traffic
- Alternative (DNS TTL-based failover) has 1-5 minute propagation delay

**4. RustFS data restore from iDrive e2**
- During cloud failover, restore RustFS data from iDrive e2 using rustic
- Data frequency: Soft Serve backup every 6 hours, other apps less frequent
- Acceptable data loss window: up to 6 hours (based on backup schedule)
- Alternative (continuous sync) would cost more and add complexity

**5. Failback requires manual confirmation**
- When home comes back online, the user is notified via ntfy.sh
- Failback is triggered manually to avoid thrashing (home fiber could be unstable)
- Sync RustFS data from cloud back to home before switching

## Risks / Trade-offs

- **Data loss window**: up to 6 hours of data could be lost if failover happens just before a backup → Mitigation: increase backup frequency for critical data
- **Hetzner VM availability**: rare, but VMs could be unavailable during peak demand → Mitigation: Hetzner has good availability; CX22 tier rarely sold out
- **Cloudflare DNS propagation**: CNAME update takes ~1 minute → Mitigation: acceptable for 30-minute failover SLA
- **Cost during extended outages**: ~€7/month for 2 VMs during failover → Mitigation: Hetzner bills by the hour, destroy VMs when not needed

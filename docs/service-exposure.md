# Service Exposure

Services are exposed via two methods, each handling TLS and DNS differently.

## Tailscale Ingress

Services exposed through the Tailscale operator use `ingressClassName: tailscale`. Tailscale automatically provisions and manages TLS certificates via Let's Encrypt for the MagicDNS domain (`*.example.ts.net`). No cert-manager configuration is needed.

Custom hostnames (e.g., `abs.tn.example.com`) are set via CNAME DNS records pointing to the Tailscale MagicDNS name. Tailscale's built-in proxy handles TLS termination for these domains as well.

To set a stable MagicDNS hostname, annotate the Ingress:

```yaml
metadata:
  annotations:
    tailscale.com/hostname: rammus-abs
```

The resulting MagicDNS address follows the pattern `<hostname>.<tailnet>.ts.net` (e.g., `rammus-abs.example.ts.net`).

## Cloudflare Tunnel

Services exposed via Cloudflare Tunnel (`cloudflared`) use Cloudflare's edge TLS. The tunnel terminates TLS at Cloudflare's edge and forwards traffic over an encrypted connection to the service. No cert-manager configuration is needed.

## cert-manager

cert-manager is available in the cluster for provisioning certificates when a service needs to be exposed outside of Tailscale or Cloudflare Tunnel — for example, for direct LAN access, internal service-to-service mTLS, or custom ingress controllers. It integrates with Let's Encrypt and other issuers to automatically manage certificate lifecycles.

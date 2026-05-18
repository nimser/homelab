# Service Exposure

Services are exposed via two methods, each handling TLS and DNS differently.

## Tailscale Ingress

Services exposed through the Tailscale operator use `ingressClassName: tailscale`.

**MagicDNS Domains:** Tailscale automatically provisions and manages TLS certificates via Let's Encrypt for its own MagicDNS domains (e.g., `*.example.ts.net`). No cert-manager configuration is needed for these.

**Custom Domains (`*.example.com`):** To use custom hostnames (e.g., `abs.tn.example.com`), set a CNAME DNS record pointing to the Tailscale MagicDNS name. However, Tailscale's built-in cert manager cannot provision certificates for external custom domains. You must use **cert-manager** to fetch a valid Let's Encrypt certificate for your custom domain and provide it to the Tailscale Ingress via the `tls` block. Without this, the Tailscale proxy will serve the MagicDNS certificate, causing a browser certificate mismatch warning.

To set a stable MagicDNS hostname, annotate the Ingress:

```yaml
metadata:
  annotations:
    tailscale.com/hostname: rammus-audiobookshelf
```

The resulting MagicDNS address follows the pattern `<hostname>.<tailnet>.ts.net` (e.g., `rammus-audiobookshelf.example.ts.net`).

## Cloudflare Tunnel

Services exposed via Cloudflare Tunnel (`cloudflared`) use Cloudflare's edge TLS. The tunnel terminates TLS at Cloudflare's edge and forwards traffic over an encrypted connection to the service. No cert-manager configuration is needed.

## cert-manager

cert-manager is used in the cluster primarily to provision certificates for **custom domains exposed over Tailscale** (e.g., `*.tn.example.com`). By integrating with Let's Encrypt via DNS-01 challenges, it automatically manages certificates that the Tailscale proxies serve, ensuring no browser warnings.

It is also available for provisioning certificates when a service needs to be exposed outside of Tailscale or Cloudflare Tunnel — for example, for direct LAN access, internal service-to-service mTLS, or custom ingress controllers.

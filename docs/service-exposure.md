# Service Exposure

Services are exposed via two methods, each handling TLS and DNS differently.

## Tailscale & Traefik (Custom Domains)

Services on the tailnet that require custom domains (e.g., `*.tn.example.com`) use **Traefik** as the Ingress Controller, which is exposed to the tailnet via the Tailscale Operator (`loadBalancerClass: tailscale` on the Traefik `Service`).

**Why Traefik?**
Tailscale's native Ingress (`ingressClassName: tailscale`) automatically provisions TLS certificates for its own MagicDNS domains (e.g., `*.example.ts.net`). However, the Tailscale proxy cannot currently load external Kubernetes `Secret` resources to serve custom domain certificates. If you point a custom domain CNAME at a native Tailscale proxy, it serves the MagicDNS certificate, resulting in a browser certificate mismatch warning.

To bypass this limitation, we use Traefik to handle HTTP routing and TLS termination using `cert-manager` certificates. Tailscale simply provides the secure L4 transport tunnel to the Traefik service.

*Note: We are tracking [tailscale/tailscale#12709](https://github.com/tailscale/tailscale/issues/12709) for native Tailscale Operator support for custom domain certificates. Once implemented, Traefik can be deprecated in favor of native Tailscale Ingress.*

## Cloudflare Tunnel

Services exposed via Cloudflare Tunnel (`cloudflared`) use Cloudflare's edge TLS. The tunnel terminates TLS at Cloudflare's edge and forwards traffic over an encrypted connection to the service. No cert-manager configuration is needed.

## cert-manager

cert-manager is used in the cluster primarily to provision certificates for **custom domains exposed via Traefik over Tailscale** (e.g., `*.tn.example.com`). By integrating with Let's Encrypt via DNS-01 challenges, it automatically manages the certificates that Traefik serves, ensuring no browser warnings.

It is also available for provisioning certificates for internal service-to-service mTLS or other custom ingress configurations.

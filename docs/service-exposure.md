# Service Exposure

Services are exposed via two methods, each handling TLS and DNS differently.

## Tailscale & Traefik (Custom Domains)

Services on the tailnet that require custom domains (e.g., `*.tn.example.com`) use **Traefik** as the Ingress Controller, which is exposed to the tailnet via the Tailscale Operator (`loadBalancerClass: tailscale` on the Traefik `Service`).

**Why Traefik?**
Tailscale's native Ingress (`ingressClassName: tailscale`) automatically provisions TLS certificates for its own MagicDNS domains (e.g., `*.example.ts.net`). However, the Tailscale proxy cannot currently load external Kubernetes `Secret` resources to serve custom domain certificates. If you point a custom domain CNAME at a native Tailscale proxy, it serves the MagicDNS certificate, resulting in a browser certificate mismatch warning.

To bypass this limitation, we use Traefik to handle HTTP routing and TLS termination using `cert-manager` certificates. Tailscale simply provides the secure L4 transport tunnel to the Traefik service.

*Note: We are tracking [tailscale/tailscale#12709](https://github.com/tailscale/tailscale/issues/12709) for native Tailscale Operator support for custom domain certificates. Once implemented, Traefik can be deprecated in favor of native Tailscale Ingress.*

### DNS records for `*.tn.example.com`

These records live in Cloudflare and are maintained by hand. They are always **DNS only** (grey cloud): they point into the `100.64.0.0/10` tailnet range, which Cloudflare's edge cannot reach, so proxying them yields 521/522.

Two record shapes are possible, and they do not resolve for the same clients:

| Shape | Example value | Resolves for |
|---|---|---|
| `CNAME` to the proxy's MagicDNS name | `rammus-traefik.example.ts.net` | only clients whose stub resolver re-queries the CNAME target through Tailscale split DNS |
| `A` to the proxy's Tailscale address | `100.91.247.71` | every resolver |

The MagicDNS target is not published in public DNS — `1.1.1.1` returns NXDOMAIN for it, and only Tailscale's resolver answers it. A CNAME record therefore needs *two* resolvers to answer one name, and only some clients stitch that chain:

- **`systemd-resolved`** re-queries the CNAME target and routes `*.ts.net` to `100.100.100.100` via the per-domain rules `tailscaled` installs. It works.
- **Tailscale's resolver alone (`100.100.100.100`)** does not chase the chain: it answers with a bare CNAME and NXDOMAIN.
- **The Windows DNS client** accepts that NXDOMAIN, so the name is unreachable there even with Tailscale connected and MagicDNS enabled.
- **Cluster pods** have no MagicDNS route at all, so the name is NXDOMAIN in-cluster.

**Rule:** a CNAME is enough for a host only reached from Linux tailnet clients. Use an A record to the proxy's Tailscale address as soon as the host must resolve from Windows, from a client using Tailscale's resolver directly, or from inside the cluster. The A record pins an address that changes when the proxy's Tailscale identity is recreated, so re-check it after reprovisioning (see `talos.md`).

An A record does not help an endpoint that must resolve **both** publicly and from inside the cluster — a tailnet address is unroutable from the public internet. Expose those through the Cloudflare Tunnel instead: `s3.example.com` carries Teable's attachment storage for exactly this reason, because the backend signs URLs the browser then fetches directly.

Verify a record end to end without a browser:

```bash
curl -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=<host>&type=A'
```

An answer carrying only a `ts.net` CNAME and `"Status": 3` means the host is CNAME-shaped and will fail on every client that does not stitch the chain.

## Cloudflare Tunnel

Services exposed via Cloudflare Tunnel (`cloudflared`) use Cloudflare's edge TLS. The tunnel terminates TLS at Cloudflare's edge and forwards traffic over an encrypted connection to the service. No cert-manager configuration is needed.

## cert-manager

cert-manager is used in the cluster primarily to provision certificates for **custom domains exposed via Traefik over Tailscale** (e.g., `*.tn.example.com`). By integrating with Let's Encrypt via DNS-01 challenges, it automatically manages the certificates that Traefik serves, ensuring no browser warnings.

It is also available for provisioning certificates for internal service-to-service mTLS or other custom ingress configurations.

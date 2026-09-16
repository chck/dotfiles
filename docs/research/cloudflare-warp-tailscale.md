# Cloudflare WARP and Tailscale on macOS

## Conclusion

Cloudflare WARP and Tailscale can coexist only with deliberate split-tunnel and
DNS configuration; installing both does not establish a supported guarantee
that inbound Tailscale access to this Mac will remain available. For the stated
goal (remote inbound access), retain Tailscale as the path to the Mac and test
the exact WARP version/configuration after every update.

Tailscale explicitly lists Cloudflare Warp among software that may conflict
with Tailscale. It explains that VPNs can install aggressive firewall rules or
otherwise prevent the other VPN from routing traffic, and that kernel-mode
Tailscale can conflict with another VPN's address space. Sources:

- [Tailscale: Can I use Tailscale alongside other VPNs?](https://tailscale.com/docs/reference/faq/other-vpns)
- [Tailscale: Interoperability with other software](https://tailscale.com/docs/reference/interoperability)

## Routing and inbound reachability

- Tailscale assigns a tailnet address and accepts incoming connections by
  default. `Allow incoming connections` / `tailscale set --shields-up=false`
  must remain enabled, and the tailnet policy plus a listening service must
  allow the connection. [Tailscale client preferences](https://tailscale.com/docs/features/client/manage-preferences)
  and [connecting to devices](https://tailscale.com/kb/1452/connect-to-devices)
  document these prerequisites.
- Tailscale subnet routes are accepted by macOS by default. The OS routing
  table uses longest-prefix matching, so a more-specific route wins over a
  broader route. [Tailscale route injection](https://tailscale.com/docs/reference/route-injection)
- Tailscale's documented coexistence workaround is to exclude Tailscale's
  IPv4 `100.64.0.0/10` and IPv6 `fd7a:115c:a1e0::/48` addresses from the other
  VPN, and to exclude any advertised subnet-route CIDRs as well. This applies
  to traffic *to* those addresses; it is not a guarantee that a competing
  macOS Network Extension will pass inbound packets to Tailscale.
  [Tailscale VPN coexistence](https://tailscale.com/docs/reference/faq/other-vpns)
- Therefore, inbound access remains reachable when Tailscale's interface and
  firewall path are left functional, but official docs do not promise that a
  consumer WARP install will preserve it. Verify from an external tailnet node
  using `tailscale ping` and the actual service port.

## WARP split tunnels and DNS

Cloudflare's split-tunnel feature is a **Cloudflare One Client / Zero Trust**
device-profile feature, not a local consumer-WARP cookbook setting. In Exclude
mode, traffic goes through Gateway except listed IPs/domains; in Include mode,
only listed destinations go through Gateway. Cloudflare explicitly recommends
this feature for running the client alongside a VPN. Split Tunnels affect IP
traffic only: DNS still goes to Gateway unless Local Domain Fallback is
configured. Sources:

- [Cloudflare One: Split Tunnels](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/configure/route-traffic/split-tunnels/)
- [Cloudflare One: Cloudflare One Client with legacy VPNs](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/vpn/)

Cloudflare's VPN guidance requires the VPN to split-tunnel WARP traffic and
WARP to exclude the VPN's private ranges and endpoint. In Traffic and DNS mode,
one product must own DNS; Cloudflare says to use Local Domain Fallback or use
Traffic only mode if the VPN must retain DNS control. It also recommends
testing compatibility after each VPN update.

In a default Zero Trust Exclude-mode device profile, Cloudflare currently
excludes `100.64.0.0/10`, which covers Tailscale's IPv4 addresses. This reduces
the most obvious route collision, but it does not cover Tailscale's IPv6 range,
advertised subnet routes, DNS ownership, firewall behavior, or macOS Network
Extension interaction. [Cloudflare reserved IP addresses](https://developers.cloudflare.com/cloudflare-one/networks/routes/reserved-ips/)

The consumer WARP macOS documentation describes downloading and enabling the
app, its WARP/1.1.1.1 modes, and the app bundle path, but does not document
user-configurable Zero Trust split-tunnel exclusions. Do not assume that
consumer WARP exposes the exclusions needed for Tailscale coexistence.
[Consumer WARP macOS docs](https://developers.cloudflare.com/warp-client/get-started/macos/)

## Practical decision

For this repository's consumer cask install, Tailscale inbound access should
be treated as **not proven compatible** while WARP is enabled. If Zero Trust
split tunnels are available, exclude `100.64.0.0/10`,
`fd7a:115c:a1e0::/48`, every Tailscale subnet-route CIDR, and any required
Tailscale control/DERP endpoints according to the deployed profile; then
choose one DNS owner and test inbound access externally. If those controls are
not available, disable WARP when inbound access is required or use a separate
Cloudflare/Tailscale design rather than relying on route precedence alone.

The lowest-risk consumer configuration is DNS-only mode because it does not
tunnel device IP traffic. That avoids the routing collision, but MagicDNS names
must still be tested because both clients can affect DNS. If full WARP mode is
required, enable it only while another recovery path is available, keep
Tailscale's incoming connections enabled, and verify from a second tailnet
device before relying on unattended remote access.

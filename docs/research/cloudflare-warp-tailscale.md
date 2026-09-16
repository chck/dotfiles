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

## Japanese IPoE / IPv4-over-IPv6 connections

IPoE and IPv4-over-IPv6 describe the ISP access path; WARP cannot increase the
physical last-mile capacity or replace the router/ISP access method. WARP can
change DNS handling and the encrypted egress path after the Mac reaches
Cloudflare. Cloudflare says that WARP may
choose a shorter path to a destination (especially Cloudflare-served sites),
but also explicitly says that encryption can reduce throughput on high-speed
desktop broadband. Treat any speed or latency gain as a measurement result,
not as a property of IPoE itself.

Enable the ISP-supported IPoE and IPv4-over-IPv6 function on the home router
first. That is the layer designed to bypass the traditional PPPoE congestion
point; WARP is an optional overlay after that foundation is working.

- [Cloudflare WARP modes](https://developers.cloudflare.com/warp-client/warp-modes/)
- [Cloudflare WARP FAQ: throughput](https://developers.cloudflare.com/warp-client/known-issues-and-faq/)
- [IIJ: why IPv4-over-IPv6 uses IPoE](https://techlog.iij.ad.jp/archives/2524)

For a home connection, start with consumer **DNS-only** mode if the goal is
DNS privacy without changing the default IP routes. DNS-only can improve lookup
latency, but it cannot improve the throughput of an established transfer. For
selected browser or application traffic, desktop WARP's **Local proxy** mode is
the safer performance experiment: it sends only proxy-configured applications
through WARP and leaves the rest of the Mac on its normal routes. The current
default tunnel protocol is **MASQUE**; keep that default unless measurements
show a connection-specific problem.

Full **WARP / Traffic and DNS** mode tunnels all device traffic and is the mode
most likely to interfere with Tailscale. Consumer WARP's documented macOS UI
lets the user change the connection protocol and DNS protocol, but it does not
provide the Zero Trust device-profile split-tunnel controls described above. If
full WARP is needed, preserve Tailscale inbound access only as an experimentally
verified result.

- [Cloudflare WARP Local proxy mode](https://developers.cloudflare.com/warp-client/warp-modes/)
- [Cloudflare tunnel protocol parameters](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/parameters/)

Cloudflare's current requirements page recommends an MTU of 1381 bytes for
macOS. Its Cloudflare One PMTUD documentation reports protocol-specific
minimums of 1361 bytes (MASQUE/IPv4), 1381 bytes (MASQUE/IPv6), 1340 bytes
(WireGuard/IPv4), and 1360 bytes (WireGuard/IPv6); below 1361 bytes, the
Cloudflare One Client automatically disables IPv6 on the tunnel interface when
PMTUD is enabled. These exact PMTUD controls are documented for the Zero Trust
client, so do not assume the consumer cask exposes them. On an IPv6-capable
IPoE path, check that IPv6 remains usable after enabling WARP rather than
forcing a manual MTU change first.

- [Cloudflare WARP requirements](https://developers.cloudflare.com/warp-client/get-started/)
- [Cloudflare One PMTUD and MTU](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/path-mtu-discovery/)

### Benchmark before choosing a setting

Run each case for several repeated samples at the same time of day, from the
same Mac and connection: (1) WARP off, (2) DNS-only, and (3) full WARP. Record
IPv4 and IPv6 reachability separately, DNS lookup latency, unloaded and loaded
latency, download/upload throughput, packet loss, and the selected WARP
protocol/edge. Also run a sustained transfer and the real remote-access test
from an outside Tailscale node (`tailscale ping` plus the service port) in every
case. Compare medians and failure rates; a single speed-test peak is not
evidence of acceleration. If full WARP improves a Cloudflare-hosted workload
but reduces general throughput or breaks inbound Tailscale, keep DNS-only (or
disable WARP when remote access is needed).

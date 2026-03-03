# CLI/TUI Power Tools Reference for Ubuntu Linux

Comprehensive reference for networking, security, text processing, and miscellaneous
power-user tools. Organized by category with install commands, usage examples, and config tips.

---

# PART 1: NETWORKING

---

## curl (Advanced Tips)

**What it does:** The Swiss-army knife for transferring data over HTTP, HTTPS, FTP, and dozens of other protocols. Already installed on virtually every Linux system.

**Why it's useful:** Indispensable for API testing, file downloads, debugging HTTP issues, and scripting web interactions. Supports cookies, auth, certificates, proxies, and streaming.

**Install:** Pre-installed. Update with `sudo apt install curl`.

**Key commands:**

```bash
# 1. GET with custom headers and verbose output
curl -v -H "Authorization: Bearer TOKEN" -H "Accept: application/json" https://api.example.com/data

# 2. POST JSON data
curl -X POST https://api.example.com/items \
  -H "Content-Type: application/json" \
  -d '{"name":"widget","price":9.99}'

# 3. Multipart file upload
curl -F "file=@/path/to/image.png" -F "description=My photo" https://api.example.com/upload

# 4. Save and reuse cookies across requests
curl -c cookies.txt -b cookies.txt -L https://example.com/login -d "user=admin&pass=secret"
curl -b cookies.txt https://example.com/dashboard

# 5. Follow redirects, show only response headers
curl -LIs https://example.com | head -20

# 6. Download with progress bar and resume support
curl -L -o bigfile.iso -C - https://releases.ubuntu.com/25.10/ubuntu-25.10-desktop-amd64.iso

# 7. Time the entire request lifecycle
curl -o /dev/null -s -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n" https://example.com

# 8. Use a .netrc file for auth (avoid passwords in CLI history)
curl -n https://api.example.com/private

# 9. Rate-limit download speed
curl --limit-rate 500K -O https://example.com/largefile.tar.gz

# 10. POST from stdin (pipe data in)
echo '{"query":"test"}' | curl -X POST -H "Content-Type: application/json" -d @- https://api.example.com/search
```

**Config tips:**
- Create `~/.curlrc` with defaults: `--location`, `--silent`, `--show-error`, `--connect-timeout 10`.
- Use `curl -w @format.txt` with a format file for reusable timing templates.
- The `-K` flag reads options from a config file for complex requests.
- Use `--compressed` to automatically request and decompress gzip/brotli responses.

---

## wget2

**What it does:** The successor to GNU Wget, rewritten from scratch with HTTP/2, parallel downloads, compression, and multi-threaded operation.

**Why it's useful:** Dramatically faster than wget1.x for recursive site downloads and large file retrieval thanks to parallelism and modern protocol support.

**Install:** `sudo apt install wget2` (or build from source via https://gitlab.com/gnuwget/wget2).

**Key commands:**

```bash
# 1. Basic download (drop-in wget replacement)
wget2 https://example.com/file.tar.gz

# 2. Parallel recursive site mirror
wget2 --mirror --page-requisites --adjust-extension --convert-links --no-parent https://example.com/docs/

# 3. Multi-threaded download (8 connections)
wget2 --max-threads=8 https://releases.ubuntu.com/25.10/ubuntu-25.10-desktop-amd64.iso

# 4. Download with HTTP/2
wget2 --http2 https://example.com/largefile.bin

# 5. Resume interrupted download
wget2 -c https://example.com/bigfile.iso

# 6. Download list of URLs from a file
wget2 -i urls.txt --max-threads=4

# 7. Recursive download with depth limit
wget2 -r -l 2 https://example.com/
```

**Config tips:**
- wget2 reads `~/.wget2rc` for persistent configuration.
- Not all wget1.x flags are supported yet; check `wget2 --help` for differences.
- HTTP/2 and compression are enabled by default.

---

## aria2

**What it does:** Lightweight multi-protocol, multi-source download utility supporting HTTP/HTTPS, FTP, BitTorrent, and Metalink with segmented (multi-connection) downloading.

**Why it's useful:** Can split a single download into multiple connections for dramatically faster speeds, download from multiple mirrors simultaneously, and handle torrents natively.

**Install:** `sudo apt install aria2`

**Key commands:**

```bash
# 1. Download with 16 connections per server
aria2c -x 16 https://example.com/largefile.iso

# 2. Download from multiple mirrors simultaneously
aria2c https://mirror1.com/file.iso https://mirror2.com/file.iso https://mirror3.com/file.iso

# 3. Download a list of URLs
aria2c -i urls.txt -j 5  # 5 concurrent downloads

# 4. BitTorrent download
aria2c /path/to/file.torrent
aria2c "magnet:?xt=urn:btih:HASH..."

# 5. Download with speed limit
aria2c --max-overall-download-limit=2M --max-download-limit=500K https://example.com/file.iso

# 6. Metalink download (auto-selects fastest mirrors)
aria2c https://example.com/file.metalink

# 7. Resume interrupted download
aria2c -c https://example.com/bigfile.iso

# 8. Run as JSON-RPC daemon for remote control
aria2c --enable-rpc --rpc-listen-all=true --daemon=true
```

**Config tips:**
- Create `~/.aria2/aria2.conf` with: `max-connection-per-server=16`, `split=16`, `min-split-size=1M`, `continue=true`.
- Use `--file-allocation=falloc` on ext4 for faster pre-allocation.
- Pair with a web UI like AriaNg for a graphical download manager.

---

## xh

**What it does:** A fast, user-friendly HTTP client written in Rust that reimplements HTTPie's intuitive syntax with much faster startup times and a single static binary.

**Why it's useful:** Makes API testing pleasant with automatic JSON formatting, expressive request syntax, and colorized output -- all without the Python dependency overhead of HTTPie.

**Install:** `cargo install xh` or download binary from https://github.com/ducaale/xh/releases

**Key commands:**

```bash
# 1. Simple GET (auto-formatted JSON response)
xh https://api.github.com/repos/ducaale/xh

# 2. POST with JSON body (= for strings, := for raw JSON)
xh POST https://api.example.com/items name=widget price:=9.99 active:=true

# 3. Custom headers
xh GET https://api.example.com/data Authorization:"Bearer TOKEN" Accept:application/json

# 4. Query string parameters (use ==)
xh https://api.example.com/search q==ubuntu page==1 limit==10

# 5. Form submission
xh --form POST https://example.com/login user=admin password=secret

# 6. File upload
xh --form POST https://api.example.com/upload file@/path/to/document.pdf

# 7. Print only headers (-h) or only body (-b)
xh -h https://example.com
xh -b https://api.example.com/data

# 8. Download a file
xh -d https://example.com/archive.tar.gz

# 9. Use HTTPS by default (xhs alias)
xhs api.example.com/data  # equivalent to xh https://api.example.com/data
```

**Config tips:**
- If installed via package manager, both `xh` and `xhs` (HTTPS default) should be available.
- Otherwise create a symlink: `ln -s ./xh ./xhs`.
- Supports `--session` for persistent headers/cookies across requests.

---

## trippy

**What it does:** A modern network diagnostic TUI tool written in Rust that combines traceroute and ping with an interactive terminal interface, charts, and even a world map visualization.

**Why it's useful:** Far superior to mtr for visual network path analysis with ASN lookups, jitter calculations, protocol flexibility (ICMP/UDP/TCP), and multiple output formats.

**Install:** `sudo add-apt-repository ppa:fujiapple/trippy && sudo apt update && sudo apt install trippy`
Or: `cargo install trippy`

**Key commands:**

```bash
# 1. Basic interactive TUI traceroute
trip google.com

# 2. Use TCP on port 443 (bypass ICMP-blocking firewalls)
trip --protocol tcp --target-port 443 google.com

# 3. Use UDP protocol
trip --protocol udp google.com

# 4. Generate a static report (like mtr --report)
trip google.com --mode pretty

# 5. JSON output for scripting
trip google.com --mode json

# 6. CSV output for analysis
trip google.com --mode csv

# 7. Show ASN (Autonomous System Number) info
trip --tui-as-mode prefix google.com

# 8. Trace multiple targets simultaneously
trip google.com cloudflare.com github.com

# 9. Force IPv4 or IPv6
trip -4 google.com
trip -6 google.com
```

**Config tips:**
- Config file at `~/.config/trippy/trippy.toml` for persistent settings.
- Requires root/sudo for raw socket access (ICMP), or use TCP/UDP modes.
- Supports themes and custom color schemes in the config file.

---

## gping

**What it does:** A visual ping tool that plots latency to one or more hosts as a real-time graph directly in your terminal.

**Why it's useful:** Instantly see latency patterns, spikes, and packet loss visually. Compare multiple hosts side-by-side on the same graph with distinct colors.

**Install:** `sudo apt install gping` (Ubuntu 23.10+) or `cargo install gping`

**Key commands:**

```bash
# 1. Ping a single host with graph
gping google.com

# 2. Compare multiple hosts simultaneously
gping google.com cloudflare.com 8.8.8.8

# 3. Graph command execution time instead of ping
gping --cmd "curl -so /dev/null https://example.com" "curl -so /dev/null https://other.com"

# 4. Adjust the time window (seconds displayed)
gping -b 120 google.com  # show last 2 minutes

# 5. Change ping interval
gping -n 0.2 google.com  # ping every 200ms

# 6. Use simple ASCII graphics (no braille)
gping -s google.com

# 7. Custom colors
gping --color 1,2,3 google.com cloudflare.com 8.8.8.8
```

**Config tips:**
- No config file; all settings via CLI flags.
- Great for monitoring during deployments: `gping your-server.com` in a tmux pane.

---

## dog / doggo

**What it does:** Modern DNS lookup clients. `dog` (Rust) and `doggo` (Go) are colorful, user-friendly replacements for `dig` with support for DNS-over-HTTPS (DoH), DNS-over-TLS (DoT), and JSON output.

**Why it's useful:** Much more readable output than dig, with modern DNS protocol support and easy scripting via JSON output.

**Install:**
- doggo: `go install github.com/mr-karan/doggo/cmd/doggo@latest` or download from GitHub releases
- dog: `cargo install dog` (note: dog is less actively maintained; prefer doggo)

**Key commands:**

```bash
# 1. Simple DNS lookup
doggo example.com

# 2. Query specific record types
doggo MX github.com
doggo AAAA example.com
doggo NS example.com

# 3. Use a specific nameserver
doggo example.com @9.9.9.9

# 4. DNS over HTTPS (Cloudflare)
doggo example.com @https://cloudflare-dns.com/dns-query

# 5. DNS over TLS
doggo example.com @tls://9.9.9.9

# 6. JSON output for scripting
doggo example.com --json | jq '.responses[0].answers[].address'

# 7. Reverse DNS lookup
doggo --reverse 8.8.8.8 --short

# 8. Short output (just the answer)
doggo example.com --short

# 9. Query multiple domains
doggo example.com github.com google.com
```

**Config tips:**
- doggo has no config file; all options are CLI flags.
- Alias it: `alias dig='doggo'` for muscle memory.

---

## RustScan

**What it does:** An ultra-fast port scanner written in Rust that scans all 65,535 ports in as little as 3 seconds, then automatically pipes discovered open ports into nmap for detailed analysis.

**Why it's useful:** Combines the speed of a dedicated port scanner with nmap's deep analysis -- scan fast, then analyze precisely. Uses async I/O for massive parallelism.

**Install:** `cargo install rustscan` or download .deb from https://github.com/bee-san/RustScan/releases

**Key commands:**

```bash
# 1. Basic scan (all 65535 ports)
rustscan -a 192.168.1.1

# 2. Scan with batch size and timeout
rustscan -a 192.168.1.1 -b 500 -T 1500

# 3. Pipe results into nmap for service detection
rustscan -a 192.168.1.1 -- -sV -sC

# 4. Pipe into nmap aggressive scan
rustscan -a 192.168.1.1 -- -A

# 5. Scan specific port range
rustscan -a 192.168.1.1 -r 1-1000

# 6. Scan multiple hosts
rustscan -a 192.168.1.1,192.168.1.2,192.168.1.3

# 7. Scan a subnet (via file)
rustscan -a "$(cat hosts.txt)"

# 8. Greppable output
rustscan -a 192.168.1.1 -g
```

**Config tips:**
- Docker is recommended for high open-file-descriptor limits: `docker run -it --rm rustscan/rustscan:latest -a target`
- Increase ulimit: `ulimit -n 65535` before scanning.
- Only scan networks you own or have explicit permission to test.

---

## nmap (Tips)

**What it does:** The gold standard network mapper for port scanning, service detection, OS fingerprinting, and vulnerability assessment with the NSE scripting engine.

**Why it's useful:** The most comprehensive network scanning tool available, with hundreds of scripts for vulnerability detection, service enumeration, and network mapping.

**Install:** `sudo apt install nmap`

**Key commands:**

```bash
# 1. Quick scan of top 100 ports
nmap --top-ports 100 192.168.1.0/24

# 2. Service version detection + default scripts
sudo nmap -sV -sC 192.168.1.1

# 3. OS detection + version + scripts + traceroute
sudo nmap -A 192.168.1.1

# 4. Stealth SYN scan (most common)
sudo nmap -sS 192.168.1.1

# 5. UDP scan (finds DNS, SNMP, DHCP, etc.)
sudo nmap -sU --top-ports 50 192.168.1.1

# 6. Vulnerability scan with NSE
nmap --script vuln 192.168.1.1

# 7. Save output in all formats simultaneously
sudo nmap -sV -oA scan-results 192.168.1.0/24

# 8. Scan through firewall with fragmentation
sudo nmap -f --mtu 24 192.168.1.1

# 9. Timing template (T0=slowest/stealthy, T5=fastest/noisy)
sudo nmap -T4 -sV 192.168.1.0/24

# 10. Scan specific ports
nmap -p 22,80,443,8080 192.168.1.1
nmap -p- 192.168.1.1  # all 65535 ports
```

**Config tips:**
- Use `-oA` to save in all output formats (normal, XML, greppable) simultaneously.
- Chain with RustScan: fast discovery, then targeted nmap.
- NSE scripts live in `/usr/share/nmap/scripts/` -- browse them for specialized checks.
- Only scan networks you own or have explicit permission to test.

---

## mtr

**What it does:** Combines traceroute and ping into a single continuously-updating network diagnostic tool that shows every hop's packet loss and latency stats in real time.

**Why it's useful:** The standard tool for diagnosing where in the network path problems occur. Shows loss and latency at each hop, updated live.

**Install:** `sudo apt install mtr`

**Key commands:**

```bash
# 1. Interactive mode (default)
mtr google.com

# 2. Generate a report (non-interactive, 10 cycles)
mtr --report google.com

# 3. Report with specific cycle count
mtr -c 20 --report google.com

# 4. Show both hostnames and IPs
mtr -b google.com

# 5. Use TCP instead of ICMP (port 443)
mtr -T -P 443 example.com

# 6. Show AS numbers for each hop
mtr --aslookup google.com

# 7. JSON output
mtr --json google.com

# 8. Wide report (no hostname truncation)
mtr -rw google.com
```

**Config tips:**
- Use `-c 100` for more statistically significant results.
- TCP mode (`-T`) bypasses ICMP-blocking firewalls.
- Consider `trippy` as a modern alternative with a richer TUI.

---

## ss (Socket Statistics Tips)

**What it does:** The modern replacement for netstat that displays socket statistics by communicating directly with the kernel via netlink sockets -- much faster and more detailed.

**Why it's useful:** Essential for diagnosing network issues: see which processes are listening, which connections are established, connection states, and internal TCP info.

**Install:** Pre-installed (part of `iproute2`).

**Key commands:**

```bash
# 1. Show all listening TCP sockets with process info
ss -tlnp

# 2. Show all established connections
ss -t state established

# 3. Show socket summary statistics
ss -s

# 4. Filter by destination port
ss dst :443
ss dst :22

# 5. Filter by source port
ss sport = :8080

# 6. Show connections to a specific IP
ss dst 192.168.1.100

# 7. Show internal TCP info (congestion, RTT, etc.)
ss -ti

# 8. Show all UDP sockets
ss -ulnp

# 9. Show UNIX domain sockets
ss -x

# 10. Combine filters (established connections on port 443)
ss -t state established dst :443
```

**Config tips:**
- Always use `-p` to see which process owns each socket (requires sudo for other users' processes).
- `-i` shows detailed TCP internal state (window sizes, congestion algorithm, RTT).
- Replace `netstat` entirely: `alias netstat='ss'`.

---

## tshark (Wireshark CLI)

**What it does:** The terminal-based version of Wireshark for capturing and analyzing network packets. Supports all Wireshark display filters and dissectors.

**Why it's useful:** Full packet capture and analysis from the command line, scriptable, and usable on headless servers where GUI Wireshark cannot run.

**Install:** `sudo apt install tshark`

**Key commands:**

```bash
# 1. Capture on an interface
sudo tshark -i eth0

# 2. Capture with a count limit
sudo tshark -i eth0 -c 100

# 3. Capture with duration limit (60 seconds)
sudo tshark -i eth0 -a duration:60

# 4. Capture with display filter
sudo tshark -i eth0 -Y "http.request.method == GET"

# 5. Capture only specific traffic with capture filter
sudo tshark -i eth0 -f "port 443"

# 6. Save capture to file
sudo tshark -i eth0 -w capture.pcap

# 7. Read and analyze a pcap file
tshark -r capture.pcap -Y "dns"

# 8. Extract specific fields
tshark -r capture.pcap -T fields -e ip.src -e ip.dst -e tcp.port

# 9. Show HTTP requests
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# 10. Follow a TCP stream
tshark -r capture.pcap -z "follow,tcp,ascii,0"
```

**Config tips:**
- Add your user to the `wireshark` group to capture without sudo: `sudo usermod -aG wireshark $USER`.
- Use ring buffers for long captures: `-b filesize:100000 -b files:10`.
- Capture filters (BPF, `-f`) are applied at capture time and are more efficient than display filters (`-Y`).

---

## termshark

**What it does:** A TUI frontend for tshark that brings Wireshark's interactive experience to the terminal, with packet list, detail, and hex views.

**Why it's useful:** Get the Wireshark experience over SSH or on headless servers. Supports live capture, pcap reading, display filters, and TCP stream reassembly.

**Install:** `sudo apt install termshark` or `go install github.com/gcla/termshark/v2/cmd/termshark@latest`

**Key commands:**

```bash
# 1. Capture on an interface
sudo termshark -i eth0

# 2. Read a pcap file
termshark -r capture.pcap

# 3. Open with a display filter
termshark -r capture.pcap -Y "http"

# 4. Capture with a filter
sudo termshark -i eth0 -f "port 80"

# 5. Navigate: Tab between panes, arrow keys to browse, Enter to expand
# 6. Apply filter: type in the filter bar at top, press Enter
# 7. Reassemble TCP stream: select a TCP packet, go to Analysis > Reassemble stream
# 8. Capture file properties: Analysis > Capture file properties
```

**Config tips:**
- Requires `tshark` in PATH (installed with the wireshark/tshark package).
- Config at `~/.config/termshark/termshark.toml`.
- Use the same display filters you know from Wireshark.

---

## bore

**What it does:** A minimal, fast TCP tunnel written in Rust (~400 lines) that exposes local ports to the public internet through a relay server.

**Why it's useful:** The simplest possible ngrok alternative. Single binary, no account needed (public relay at bore.pub), and trivial to self-host.

**Install:** `cargo install bore-cli`

**Key commands:**

```bash
# 1. Expose local port 8000 to the internet
bore local 8000 --to bore.pub

# 2. Expose with a specific remote port
bore local 8000 --to bore.pub --port 31415

# 3. Expose on a specific local host
bore local 3000 --local-host 127.0.0.1 --to bore.pub

# 4. Use authentication secret
bore local 8000 --to bore.pub --secret mysecretkey

# 5. Self-host the relay server
bore server --min-port 1024 --max-port 65535

# 6. Connect to your self-hosted relay
bore local 8000 --to your-server.com --secret yoursecret
```

**Config tips:**
- Public relay `bore.pub` is free but ports are random. Self-host for predictable ports.
- For the server, open TCP ports 7835 (control) and your chosen port range.
- No HTTP tunneling (TCP only) -- use cloudflared or frp if you need HTTP-specific features.

---

## croc

**What it does:** A CLI tool for securely transferring files and folders between any two computers using code phrases with end-to-end encryption (PAKE).

**Why it's useful:** The easiest secure file transfer tool. No accounts, no setup, works across platforms and networks. Just share a code phrase.

**Install:** `curl https://getcroc.schollz.com | bash` or download .deb from GitHub releases.

**Key commands:**

```bash
# 1. Send a file (generates a code phrase)
croc send document.pdf

# 2. Receive a file
croc 8344-think-unit-pulse

# 3. Send with a custom code phrase
croc send --code mypassphrase123 document.pdf

# 4. Send multiple files
croc send file1.txt file2.txt file3.jpg

# 5. Send a directory
croc send /path/to/directory/

# 6. Send text
croc send --text "Here is a secret message"

# 7. Use Tor for extra privacy
croc --socks5 "127.0.0.1:9050" send document.pdf

# 8. Self-host a relay
croc relay --ports 9009-9013
croc --relay yourserver.com:9009 send document.pdf
```

**Config tips:**
- Default relay uses TCP ports 9009-9013.
- Code phrases use PAKE (password-authenticated key exchange) for end-to-end encryption.
- Self-host the relay for sensitive transfers on your own network.
- Files are encrypted until they reach the recipient.

---

## magic-wormhole

**What it does:** Securely transfers files, directories, or text between computers using human-pronounceable code phrases and end-to-end encryption.

**Why it's useful:** Extremely simple UX with strong security guarantees. The code phrases are short and easy to read aloud (e.g., "7-crossover-clockwork").

**Install:** `sudo apt install magic-wormhole` or `pip install magic-wormhole`

**Key commands:**

```bash
# 1. Send a file
wormhole send document.pdf
# Outputs: wormhole receive 7-crossover-clockwork

# 2. Receive a file
wormhole receive 7-crossover-clockwork

# 3. Send a directory (auto-zipped)
wormhole send /path/to/directory/

# 4. Send text
wormhole send --text "Here is the password: hunter2"

# 5. Receive text
wormhole receive 4-purple-sausage

# 6. Specify a custom code length (more words = more security)
wormhole send --code-length 4 document.pdf

# 7. Use a specific relay server
wormhole --relay-url ws://myrelay.example.com:4000/v1 send file.txt
```

**Config tips:**
- Tab completion works on the receiving end for code words.
- Transfer uses a rendezvous server (mailbox) for initial connection, then direct transfer.
- Rust implementation (`magic-wormhole.rs`) is available for better performance.

---

## rclone

**What it does:** A command-line tool for managing files on cloud storage. Supports 70+ cloud providers (S3, Google Drive, Dropbox, OneDrive, etc.) with sync, copy, mount, and encryption.

**Why it's useful:** The "rsync for cloud storage." Unified interface for every cloud provider, with server-side operations, encryption, caching, and FUSE mounting.

**Install:** `sudo apt install rclone` or `curl https://rclone.org/install.sh | sudo bash`

**Key commands:**

```bash
# 1. Configure a new remote (interactive)
rclone config

# 2. List remotes
rclone listremotes

# 3. Sync local to remote (make remote match local)
rclone sync /local/path remote:bucket/path --progress

# 4. Copy (without deleting extra files on dest)
rclone copy /local/path remote:bucket/path -P --transfers 16

# 5. Mount cloud storage as filesystem
rclone mount remote:bucket /mnt/cloud --daemon --vfs-cache-mode full

# 6. Bidirectional sync
rclone bisync /local/path remote:path --resync  # first run
rclone bisync /local/path remote:path           # subsequent runs

# 7. Encrypted backup
rclone sync /important/data encrypted-remote:backups -P

# 8. Check for differences without syncing
rclone check /local/path remote:path

# 9. Serve files over HTTP/WebDAV
rclone serve http remote:path --addr :8080
rclone serve webdav remote:path --addr :8081

# 10. Filter files during sync
rclone sync /local remote:dest --include "*.doc" --include "*.pdf" --exclude "*"
```

**Config tips:**
- Config at `~/.config/rclone/rclone.conf`.
- Use `--fast-list` for remotes that support it (S3, GCS) for faster listing.
- `--checksum` verifies files by hash instead of size/time.
- `--max-delete 10` as a safety net to prevent accidental mass deletion.
- Use `--transfers 32 --checkers 16` for high-bandwidth connections.

---

## rsync (Tips)

**What it does:** The classic file synchronization tool using delta encoding to transfer only changed parts of files, minimizing data transfer.

**Why it's useful:** The gold standard for efficient backups, deployments, and file mirroring. Delta transfer means only changes are sent, even for huge files.

**Install:** `sudo apt install rsync` (usually pre-installed).

**Key commands:**

```bash
# 1. Basic sync with archive mode, verbose, progress
rsync -avP /source/ user@remote:/destination/

# 2. Sync with deletion (make dest match source exactly)
rsync -av --delete /source/ /destination/

# 3. Dry run (preview what would change)
rsync -avP --dry-run /source/ /destination/

# 4. Exclude patterns
rsync -av --exclude='*.log' --exclude='.git' /source/ /dest/

# 5. Use SSH with custom port
rsync -avP -e "ssh -p 2222" /source/ user@host:/dest/

# 6. Bandwidth limit (in KB/s)
rsync -av --bwlimit=5000 /source/ remote:/dest/

# 7. Compress during transfer
rsync -avz /source/ remote:/dest/

# 8. Delete source files after successful transfer
rsync -av --remove-source-files /source/ /dest/

# 9. Show itemized changes
rsync -avi /source/ /dest/

# 10. Backup with hardlinks (incremental, space-efficient)
rsync -av --link-dest=/backups/latest /source/ /backups/$(date +%Y-%m-%d)/
```

**Config tips:**
- Trailing slash on source matters: `/source/` copies contents, `/source` copies the directory itself.
- Use `--link-dest` for Time Machine-style incremental backups.
- `--partial --progress` (or `-P`) keeps partially transferred files for resumption.
- For large file trees, `--info=progress2` shows overall progress instead of per-file.

---

## syncthing (CLI)

**What it does:** A continuous, decentralized file synchronization tool that syncs files between devices in real time with no cloud server required.

**Why it's useful:** Peer-to-peer sync with no central server, strong encryption, version history, and conflict resolution. Runs as a daemon with web UI and CLI control.

**Install:** `sudo apt install syncthing`

**Key commands:**

```bash
# 1. Start syncthing
syncthing

# 2. Start as a service
sudo systemctl enable --now syncthing@$USER

# 3. Access web UI
# Open http://127.0.0.1:8384 in browser

# 4. CLI: Show device ID
syncthing -device-id

# 5. CLI: Generate config
syncthing generate --config=/path/to/config

# 6. REST API queries (via curl)
curl -s -H "X-API-Key: YOUR_KEY" http://localhost:8384/rest/system/status | jq .

# 7. Show sync status
curl -s -H "X-API-Key: YOUR_KEY" http://localhost:8384/rest/db/status?folder=default | jq .

# 8. Force rescan
curl -X POST -H "X-API-Key: YOUR_KEY" http://localhost:8384/rest/db/scan?folder=default
```

**Config tips:**
- Config at `~/.local/state/syncthing/` or `~/.config/syncthing/`.
- API key is in `config.xml` under `<gui><apikey>`.
- Use `.stignore` files (like .gitignore) to exclude files from sync.
- Set `relaysEnabled` to false if all devices are on the same LAN.

---

# PART 2: SECURITY & ENCRYPTION

---

## age

**What it does:** A simple, modern file encryption tool with small explicit keys, no config options, and UNIX-style composability. Created by Filippo Valsorda (Go team security lead).

**Why it's useful:** The modern replacement for GPG for file encryption. No key servers, no "web of trust," no config -- just simple, auditable encryption with short keys.

**Install:** `sudo apt install age`

**Key commands:**

```bash
# 1. Generate a key pair
age-keygen -o key.txt
# Outputs public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

# 2. Encrypt a file with a public key
age -r age1ql3z7hjy54pw... -o secret.txt.age secret.txt

# 3. Decrypt with private key
age -d -i key.txt -o secret.txt secret.txt.age

# 4. Encrypt with a passphrase (no keys needed)
age -p -o secret.txt.age secret.txt

# 5. Decrypt passphrase-encrypted file
age -d -o secret.txt secret.txt.age

# 6. Encrypt for multiple recipients
age -r age1abc... -r age1def... -o secret.age secret.txt

# 7. Encrypt using SSH public keys
age -R ~/.ssh/id_ed25519.pub -o secret.age secret.txt

# 8. Decrypt with SSH private key
age -d -i ~/.ssh/id_ed25519 -o secret.txt secret.age

# 9. Pipe-friendly encryption
tar czf - ~/important/ | age -r age1abc... > backup.tar.gz.age

# 10. Decrypt from pipe
age -d -i key.txt backup.tar.gz.age | tar xzf -
```

**Config tips:**
- Store recipients in a file, one per line: `age -R recipients.txt -o out.age in.txt`.
- Works beautifully with SOPS for encrypting config files.
- Prefer age over GPG for new projects -- simpler, more auditable, faster.

---

## GPG (Tips)

**What it does:** GNU Privacy Guard -- the classic open-source implementation of the OpenPGP standard for encryption, signing, and key management.

**Why it's useful:** Still required for signing git commits, Debian packages, email encryption, and tools like `pass`. Deep ecosystem integration.

**Install:** `sudo apt install gnupg` (usually pre-installed).

**Key commands:**

```bash
# 1. Generate a new key pair
gpg --full-gen-key

# 2. List keys
gpg --list-keys
gpg --list-secret-keys --keyid-format LONG

# 3. Encrypt a file for a recipient
gpg -e -r recipient@email.com secret.txt

# 4. Decrypt a file
gpg -d secret.txt.gpg > secret.txt

# 5. Symmetric encryption (passphrase only)
gpg -c secret.txt

# 6. Sign a file (detached signature)
gpg --detach-sign -a file.tar.gz

# 7. Verify a signature
gpg --verify file.tar.gz.asc file.tar.gz

# 8. Export public key
gpg --armor --export your@email.com > publickey.asc

# 9. Import someone's public key
gpg --import theirkey.asc

# 10. Sign git commits
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

**Config tips:**
- Config at `~/.gnupg/gpg.conf`. Add: `keyid-format long`, `with-fingerprint`, `use-agent`.
- Agent config at `~/.gnupg/gpg-agent.conf`: `default-cache-ttl 3600`, `max-cache-ttl 86400`.
- For new encryption-only use cases, prefer `age` over GPG.
- Back up `~/.gnupg/` securely -- losing your private key means losing access.

---

## pass / gopass

**What it does:** `pass` is the standard UNIX password manager -- a shell script that stores passwords as GPG-encrypted files in a git-versioned directory tree. `gopass` is a feature-enhanced Go rewrite with team support.

**Why it's useful:** Simple, transparent, UNIX-philosophy password management. Passwords are just GPG files in directories, version-controlled with git, and accessible from CLI, dmenu, or browser extensions.

**Install:** `sudo apt install pass` or `sudo apt install gopass`

**Key commands:**

```bash
# 1. Initialize the password store
pass init YOUR_GPG_KEY_ID

# 2. Initialize git tracking
pass git init

# 3. Add a password
pass insert email/gmail

# 4. Add a multi-line entry (username, URL, notes)
pass insert -m email/gmail

# 5. Generate a random password (25 chars)
pass generate web/github.com 25

# 6. Generate with no symbols, copy to clipboard
pass generate -n -c web/github.com 25

# 7. Retrieve a password (copies to clipboard for 45s)
pass -c email/gmail

# 8. Show a password
pass email/gmail

# 9. List all entries
pass

# 10. Sync with git remote
pass git push
pass git pull

# gopass extras:
# Team sharing with multiple GPG keys
gopass recipients add colleague@email.com
# Fuzzy search
gopass show -f
```

**Config tips:**
- Password store lives at `~/.password-store/`.
- Use `passmenu` (dmenu wrapper) or `rofi-pass` for GUI access.
- Browser extension: `browserpass` connects Firefox/Chrome to pass.
- gopass supports age as an alternative to GPG: `gopass setup --crypto age`.

---

## Bitwarden CLI (bw)

**What it does:** Full-featured command-line client for the Bitwarden password manager, allowing vault access, password generation, and TOTP codes from the terminal.

**Why it's useful:** Access your Bitwarden vault from scripts, CI/CD pipelines, or headless servers. Generate passwords, retrieve credentials, and manage vault items programmatically.

**Install:** `sudo snap install bw` or `npm install -g @bitwarden/cli`

**Key commands:**

```bash
# 1. Log in
bw login

# 2. Unlock vault (returns session key)
export BW_SESSION=$(bw unlock --raw)

# 3. List all items
bw list items

# 4. Search for an item
bw list items --search github

# 5. Get a specific password
bw get password "github.com"

# 6. Get TOTP code
bw get totp "github.com"

# 7. Generate a secure password
bw generate -ulns --length 32

# 8. Create a new login item
bw get template item | jq '.name="New Login" | .login.username="user" | .login.password="pass"' | bw encode | bw create item

# 9. Check password against HIBP (Have I Been Pwned)
bw get password "example" | bw check --password

# 10. Lock the vault when done
bw lock
```

**Config tips:**
- Always `bw lock` when finished to clear the session.
- Set `BW_SESSION` in your shell for the duration of scripting.
- Use `bw sync` to pull latest changes from the server.
- `bw serve` starts a local REST API for integration with other tools.

---

## SOPS

**What it does:** Secrets OPerationS -- an editor for encrypted files that supports YAML, JSON, ENV, INI, and binary formats. Encrypts only the values (not keys) so diffs remain readable.

**Why it's useful:** Store encrypted secrets directly in git. Keys/structure remain visible in diffs; only values are encrypted. Supports age, GPG, AWS KMS, GCP KMS, and Azure Key Vault.

**Install:** Download from https://github.com/getsops/sops/releases or `go install github.com/getsops/sops/v3/cmd/sops@latest`

**Key commands:**

```bash
# 1. Create .sops.yaml config (use age)
cat > .sops.yaml << 'EOF'
creation_rules:
  - path_regex: \.enc\.yaml$
    age: "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
EOF

# 2. Encrypt a file in place
sops encrypt -i secrets.enc.yaml

# 3. Decrypt a file in place
sops decrypt -i secrets.enc.yaml

# 4. Edit encrypted file (decrypts, opens editor, re-encrypts)
sops edit secrets.enc.yaml

# 5. Decrypt to stdout
sops decrypt secrets.enc.yaml

# 6. Encrypt with age explicitly
sops encrypt --age age1abc... secrets.yaml > secrets.enc.yaml

# 7. Extract a specific key
sops decrypt --extract '["database"]["password"]' secrets.enc.yaml

# 8. Rotate encryption keys
sops updatekeys secrets.enc.yaml

# 9. Encrypt with multiple key groups (Shamir sharing)
sops encrypt --shamir-secret-sharing-threshold 2 --age age1abc...,age1def... secrets.yaml
```

**Config tips:**
- Use `.sops.yaml` at repo root to auto-apply encryption rules by path.
- Set `SOPS_AGE_KEY_FILE` environment variable to your age key file path.
- SOPS encrypts values but leaves keys/structure visible -- great for code review.
- Use `creation_rules` with `path_regex` to apply different keys to different files.

---

## SSH (Tips & Tricks)

**What it does:** Secure Shell for encrypted remote access, tunneling, file transfer, and more.

**Why it's useful:** The backbone of remote Linux administration. Advanced config unlocks multiplexing, jump hosts, tunnels, and more.

**Install:** `sudo apt install openssh-client openssh-server`

**Key commands and config:**

```bash
# 1. Generate modern key
ssh-keygen -t ed25519 -C "user@hostname"

# 2. Copy key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# 3. Jump through a bastion host
ssh -J bastion.example.com target.internal.com

# 4. Chain multiple jumps
ssh -J bastion1,bastion2 target.internal.com

# 5. Local port forward (access remote:5432 at localhost:5432)
ssh -L 5432:localhost:5432 user@dbserver

# 6. Remote port forward (expose local:3000 on remote:8080)
ssh -R 8080:localhost:3000 user@server

# 7. SOCKS proxy
ssh -D 1080 user@server  # then configure browser to use localhost:1080

# 8. Copy files via SSH
scp -r /local/dir user@server:/remote/dir
# Or better, use rsync:
rsync -avP /local/dir/ user@server:/remote/dir/

# 9. Run a command remotely
ssh user@server 'df -h && free -m'

# 10. Mount remote filesystem
sshfs user@server:/remote/path /local/mount
```

**~/.ssh/config tips:**

```
# Multiplexing (reuse connections -- much faster)
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Jump host config
Host internal-server
    HostName 10.0.0.50
    User admin
    ProxyJump bastion.example.com

# Alias with custom port
Host myserver
    HostName server.example.com
    User deploy
    Port 2222
    IdentityFile ~/.ssh/deploy_key
```

**Config tips:**
- Create `~/.ssh/sockets/` directory for multiplexing.
- Prefer `ProxyJump` over agent forwarding -- keeps private keys local.
- Use `AddKeysToAgent yes` in config to auto-add keys to agent on first use.
- Harden sshd: disable password auth, set `PermitRootLogin no`, use `AllowUsers`.

---

## fail2ban

**What it does:** Monitors log files for brute-force attempts and automatically bans offending IPs using firewall rules (iptables/ufw/nftables).

**Why it's useful:** Essential server hardening. Automatically blocks SSH brute-force attacks, web login attempts, and other abuse patterns.

**Install:** `sudo apt install fail2ban`

**Key commands:**

```bash
# 1. Start and enable
sudo systemctl enable --now fail2ban

# 2. Check jail status
sudo fail2ban-client status

# 3. Check SSH jail specifically
sudo fail2ban-client status sshd

# 4. Manually ban an IP
sudo fail2ban-client set sshd banip 1.2.3.4

# 5. Unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# 6. Check fail2ban log
sudo tail -f /var/log/fail2ban.log

# 7. Reload after config changes
sudo fail2ban-client reload

# 8. Test a filter regex against a log
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

**Config tips:**
- Never edit `jail.conf` directly. Copy to `jail.local`: `sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local`.
- Key settings in `jail.local`:
  ```
  [sshd]
  enabled = true
  banaction = ufw          # use ufw instead of iptables
  maxretry = 3
  findtime = 600
  bantime = 86400          # 24 hours
  ```
- Create custom jails in `/etc/fail2ban/jail.d/` for nginx, Apache, etc.
- Emergency lockout recovery: `sudo ufw disable` or access via console.

---

## ufw (Tips)

**What it does:** Uncomplicated Firewall -- a user-friendly frontend for iptables/nftables that makes firewall management simple.

**Why it's useful:** Makes Linux firewall configuration accessible without memorizing iptables syntax. Perfect for servers and workstations alike.

**Install:** `sudo apt install ufw` (usually pre-installed).

**Key commands:**

```bash
# 1. Enable firewall with defaults (deny incoming, allow outgoing)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# 2. Allow SSH (do this BEFORE enabling!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# 3. Allow specific port
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 4. Allow from specific IP
sudo ufw allow from 192.168.1.100

# 5. Allow from subnet to specific port
sudo ufw allow from 192.168.1.0/24 to any port 22

# 6. Delete a rule
sudo ufw delete allow 80/tcp
# Or by number:
sudo ufw status numbered
sudo ufw delete 3

# 7. Rate limiting (anti-brute-force)
sudo ufw limit ssh

# 8. Show detailed status
sudo ufw status verbose

# 9. Allow application profiles
sudo ufw app list
sudo ufw allow "Nginx Full"

# 10. Reset to defaults
sudo ufw reset
```

**Config tips:**
- Always allow SSH before enabling: getting locked out of a remote server is painful.
- `ufw limit ssh` auto-rate-limits to 6 connections per 30 seconds.
- App profiles live in `/etc/ufw/applications.d/`.
- Logs at `/var/log/ufw.log`; enable with `sudo ufw logging on`.

---

## lynis

**What it does:** A comprehensive security auditing tool for Linux/UNIX that performs hundreds of tests covering system hardening, compliance (HIPAA, ISO27001, PCI-DSS), and vulnerability detection.

**Why it's useful:** Get an instant security score and actionable hardening suggestions for any Linux system. Agentless, no installation required (runs from tarball).

**Install:** `sudo apt install lynis` or clone from https://github.com/CISOfy/lynis

**Key commands:**

```bash
# 1. Full system audit
sudo lynis audit system

# 2. Quick scan (fewer tests)
sudo lynis audit system --quick

# 3. Check specific compliance
sudo lynis audit system --compliance pci-dss
sudo lynis audit system --compliance cis

# 4. Pentest mode (more aggressive)
sudo lynis audit system --pentest

# 5. Scan a Dockerfile
lynis audit dockerfile /path/to/Dockerfile

# 6. View the report
cat /var/log/lynis-report.dat

# 7. Show only warnings
grep Warning /var/log/lynis-report.dat

# 8. Automated cron job
# Add to crontab: 0 0 * * * /usr/sbin/lynis audit system --cronjob --quiet > /var/log/lynis-cron.log

# 9. Check specific test group
sudo lynis audit system --tests-from-group "firewalls"

# 10. Show Lynis version and update status
lynis update info
```

**Config tips:**
- Results in `/var/log/lynis.log` (detailed) and `/var/log/lynis-report.dat` (findings).
- Custom profiles at `/etc/lynis/custom.prf` for site-specific settings.
- Run after every major system change to catch regressions.
- Focus on "Suggestions" output -- each has a test ID you can research.

---

# PART 3: TEXT PROCESSING

---

## awk (Tips)

**What it does:** A powerful pattern-scanning and text-processing language that operates on fields (columns) within lines.

**Why it's useful:** The go-to tool for column extraction, calculation, and reporting from structured text data. Far more capable than most people realize.

**Install:** Pre-installed (`gawk` on Ubuntu).

**Key commands:**

```bash
# 1. Print specific columns
awk '{print $1, $3}' file.txt

# 2. Custom field separator
awk -F',' '{print $2}' data.csv
awk -F':' '{print $1, $7}' /etc/passwd

# 3. Filter rows by pattern
awk '$3 > 100 {print $0}' data.txt

# 4. Sum a column
awk '{sum += $3} END {print "Total:", sum}' data.txt

# 5. Count lines matching a pattern
awk '/ERROR/ {count++} END {print count}' logfile.log

# 6. Print unique values in a column
awk '!seen[$1]++ {print $1}' file.txt

# 7. Calculate average
awk '{sum += $2; n++} END {print "Average:", sum/n}' data.txt

# 8. Reformat output (printf)
awk '{printf "%-20s %10.2f\n", $1, $3}' data.txt

# 9. Multiple field separators
awk -F'[,;:]' '{print $1, $2}' mixed.txt

# 10. Process multi-file with FILENAME
awk '{print FILENAME, $0}' file1.txt file2.txt
```

**Config tips:**
- `BEGIN {}` runs before input, `END {}` runs after all input.
- Built-in variables: `NR` (line number), `NF` (number of fields), `FS` (field separator), `OFS` (output field separator).
- Use `-v var=value` to pass shell variables into awk.
- For complex scripts, put awk code in a file: `awk -f script.awk data.txt`.

---

## sed (Tips)

**What it does:** Stream editor that performs text transformations on input streams -- search/replace, delete, insert, and transform text line by line.

**Why it's useful:** The fastest way to do search-and-replace across files, transform text in pipelines, and make bulk edits from scripts.

**Install:** Pre-installed.

**Key commands:**

```bash
# 1. Basic find and replace (first occurrence per line)
sed 's/old/new/' file.txt

# 2. Replace ALL occurrences (global)
sed 's/old/new/g' file.txt

# 3. In-place edit (modify file directly)
sed -i 's/old/new/g' file.txt

# 4. In-place with backup
sed -i.bak 's/old/new/g' file.txt

# 5. Delete lines matching a pattern
sed '/^#/d' config.txt          # delete comments
sed '/^$/d' file.txt            # delete blank lines

# 6. Print only matching lines (like grep)
sed -n '/pattern/p' file.txt

# 7. Replace on specific line numbers
sed '5s/old/new/' file.txt      # line 5 only
sed '10,20s/old/new/g' file.txt # lines 10-20

# 8. Insert text before/after a match
sed '/pattern/i\New line before' file.txt
sed '/pattern/a\New line after' file.txt

# 9. Multiple operations
sed -e 's/foo/bar/g' -e 's/baz/qux/g' file.txt

# 10. Extract text between patterns
sed -n '/START/,/END/p' file.txt
```

**Config tips:**
- Use different delimiters for paths: `sed 's|/old/path|/new/path|g'`.
- Extended regex with `-E`: `sed -E 's/(foo|bar)/baz/g'`.
- `-i` without backup is dangerous; prefer `-i.bak` and delete backups after verifying.
- Combine with `find` for bulk edits: `find . -name "*.conf" -exec sed -i 's/old/new/g' {} +`.

---

## Miller (mlr)

**What it does:** Like awk, sed, cut, join, and sort combined, but for name-indexed data (CSV, TSV, JSON, DKVP, XTAB, and more). Handles headers automatically.

**Why it's useful:** The single most powerful tool for structured data manipulation on the command line. Understands data formats natively, so no more fragile field-number references.

**Install:** `sudo apt install miller`

**Key commands:**

```bash
# 1. Pretty-print a CSV
mlr --icsv --opprint cat data.csv

# 2. Filter rows
mlr --csv filter '$age > 30' data.csv

# 3. Select columns
mlr --csv cut -f name,email,age data.csv

# 4. Sort by column
mlr --csv sort-by -nf age data.csv  # numeric sort by age

# 5. Group-by statistics
mlr --csv stats1 -a mean,count -f salary -g department data.csv

# 6. Convert CSV to JSON
mlr --icsv --ojson cat data.csv

# 7. Convert JSON to CSV
mlr --ijson --ocsv cat data.json

# 8. Add computed columns
mlr --csv put '$full_name = $first . " " . $last' data.csv

# 9. Top N per group
mlr --csv top -n 5 -f salary -g department data.csv

# 10. Chain operations
mlr --csv filter '$status == "active"' then sort-by -nf score then head -n 10 data.csv
```

**Config tips:**
- Miller is format-aware: `--csv`, `--json`, `--tsv`, `--dkvp`, `--xtab`.
- Mix input/output formats freely: `--icsv --ojson` converts CSV to JSON.
- Use `then` to chain verbs in a single command.
- Full documentation at https://miller.readthedocs.io/.

---

## csvkit

**What it does:** A suite of Python command-line tools for converting to and working with CSV, including tools for converting Excel/JSON to CSV, querying with SQL, and generating statistics.

**Why it's useful:** The most complete CSV toolkit with SQL query support, format conversion, and statistical analysis. Great for quick data exploration.

**Install:** `pip install csvkit` or `sudo apt install csvkit`

**Key commands:**

```bash
# 1. Convert Excel to CSV
in2csv data.xlsx > data.csv

# 2. Convert JSON to CSV
in2csv data.json > data.csv

# 3. Show column names and types
csvstat data.csv

# 4. Select columns
csvcut -c 1,3,5 data.csv
csvcut -c name,email data.csv

# 5. Filter rows with grep-like syntax
csvgrep -c state -m "California" data.csv

# 6. Query with SQL
csvsql --query "SELECT name, COUNT(*) FROM data GROUP BY name ORDER BY COUNT(*) DESC LIMIT 10" data.csv

# 7. Sort by column
csvsort -c age data.csv

# 8. Pretty-print
csvlook data.csv

# 9. Join two CSVs
csvjoin -c id data1.csv data2.csv

# 10. Import CSV into SQLite
csvsql --db sqlite:///mydb.db --insert data.csv
```

**Config tips:**
- csvkit auto-detects delimiters, encoding, and quoting.
- Use `csvformat` to change delimiters: `csvformat -D '\t' data.csv > data.tsv`.
- `csvsql` supports SQLite, PostgreSQL, MySQL.

---

## xsv

**What it does:** A fast CSV command-line toolkit written in Rust for indexing, slicing, analyzing, splitting, and joining CSV files.

**Why it's useful:** Orders of magnitude faster than csvkit for large files. Single binary, no dependencies. Ideal for quick exploration of big datasets.

**Install:** `cargo install xsv` or download from https://github.com/BurntSushi/xsv/releases

**Key commands:**

```bash
# 1. Show headers
xsv headers data.csv

# 2. Row count
xsv count data.csv

# 3. Quick statistics
xsv stats data.csv | xsv table

# 4. Select columns
xsv select name,age data.csv

# 5. Search/filter rows
xsv search -s state "California" data.csv

# 6. Sort by column
xsv sort -s age -N data.csv  # -N for numeric

# 7. Sample random rows
xsv sample 100 data.csv

# 8. Slice rows
xsv slice -s 0 -l 10 data.csv  # first 10 rows

# 9. Create an index (speeds up subsequent operations)
xsv index data.csv

# 10. Join two CSVs
xsv join id data1.csv id data2.csv

# 11. Frequency table
xsv frequency -s state data.csv | xsv table
```

**Config tips:**
- Create an index (`xsv index`) for repeated operations on the same file.
- `xsv table` formats output as a readable table.
- Note: `qsv` is an actively maintained fork with more features.

---

## jless

**What it does:** A command-line JSON viewer designed for reading, exploring, and searching through JSON data with vim-style navigation.

**Why it's useful:** Navigate massive JSON files interactively -- expand/collapse objects, search, copy paths. Like `less` but built specifically for JSON/YAML.

**Install:** `cargo install jless` (needs X11 libs: `sudo apt install libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev`)

**Key commands:**

```bash
# 1. View a JSON file
jless data.json

# 2. Pipe from curl
curl -s https://api.github.com/repos/torvalds/linux | jless

# 3. View YAML
jless config.yaml

# Navigation inside jless:
# j/k        - move up/down
# h/l        - collapse/expand
# Space      - toggle expand/collapse
# /          - search
# n/N        - next/previous search result
# yy         - copy node to clipboard
# yp         - copy path to node
# q          - quit
```

**Config tips:**
- No config file needed.
- Works with JSON Lines (one JSON object per line).
- Great for API response exploration: `curl ... | jless`.

---

## fx

**What it does:** A terminal JSON viewer and processor that works in both interactive (TUI) and CLI (piped JavaScript processing) modes.

**Why it's useful:** Explore JSON interactively or transform it with familiar JavaScript syntax. No DSL to learn -- just use JavaScript expressions.

**Install:** `snap install fx` or `npm install -g fx` or download binary from https://fx.wtf/install

**Key commands:**

```bash
# 1. Interactive mode (pipe JSON in)
cat data.json | fx

# 2. Extract a field using JavaScript
cat data.json | fx '.name'

# 3. Map over arrays
cat data.json | fx '.items.map(x => x.name)'

# 4. Filter arrays
cat data.json | fx '.users.filter(u => u.age > 30)'

# 5. Chain transformations
cat data.json | fx '.items' '.map(x => x.price)' '.reduce((a,b) => a+b)'

# 6. Access nested fields
cat data.json | fx '.data.results[0].name'

# 7. Raw JSON values (for piping)
cat data.json | fx '.count' # outputs raw value, not quoted

# 8. Slurp mode (treat JSON stream as array)
cat items.jsonl | fx --slurp '.length'
```

**Config tips:**
- Arguments are JavaScript functions applied in sequence.
- Start expressions with `.` to avoid writing `x => x.`.
- Interactive mode: arrow keys to navigate, `e` to expand all, `q` to quit.

---

## gron

**What it does:** Transforms JSON into discrete line-by-line assignments, making it possible to grep JSON data and see the full path to each value.

**Why it's useful:** Makes JSON greppable. Find a value with grep, see its exact path, modify it, and convert back to JSON with `gron --ungron`.

**Install:** Download from https://github.com/tomnomnom/gron/releases or `go install github.com/tomnomnom/gron@latest`

**Key commands:**

```bash
# 1. Flatten JSON to greppable assignments
gron data.json

# 2. Pipe from curl and grep
curl -s https://api.github.com/users/torvalds | gron | grep "name"

# 3. Filter and convert back to JSON
curl -s https://api.github.com/users/torvalds | gron | grep "company" | gron --ungron

# 4. Print just the values
gron -v data.json

# 5. Colorized output
gron -c data.json

# 6. Stream mode (one JSON per line)
gron -s data.jsonl

# 7. Fetch and flatten from URL
gron https://api.github.com/users/torvalds

# 8. Full workflow: gron -> grep -> ungron
gron data.json | grep "email" | gron --ungron | jq .
```

**Config tips:**
- Alias `ungron` for convenience: `alias ungron='gron --ungron'`.
- Workflow: `gron | grep | ungron` is the killer pattern.
- No runtime dependencies -- single static binary.

---

## pup

**What it does:** A command-line HTML parser that reads from stdin and filters HTML using CSS selectors, inspired by jq.

**Why it's useful:** Extract data from HTML pages using CSS selectors you already know from web development. Perfect for scraping and parsing.

**Install:** `go install github.com/ericchiang/pup@latest`

**Key commands:**

```bash
# 1. Extract page title
curl -s https://example.com | pup 'title text{}'

# 2. Extract all links
curl -s https://example.com | pup 'a attr{href}'

# 3. Extract specific class
curl -s https://example.com | pup '.article-title text{}'

# 4. Extract by ID
curl -s https://example.com | pup '#main-content text{}'

# 5. Multiple selectors
curl -s https://example.com | pup 'h1, h2, h3'

# 6. Content filtering
curl -s https://example.com | pup ':contains("Contact")'

# 7. Output as JSON
curl -s https://example.com | pup 'a json{}'

# 8. Nested selectors
curl -s https://example.com | pup 'div.content > p text{}'
```

**Config tips:**
- `text{}` extracts text content, `attr{href}` extracts attributes.
- `json{}` outputs structured JSON for further processing with jq.
- Supports standard CSS selectors including pseudo-classes.

---

## htmlq

**What it does:** Like jq but for HTML. Uses CSS selectors to extract content from HTML files, written in Rust.

**Why it's useful:** Fast, single-binary HTML extraction. Complements curl perfectly for web scraping pipelines.

**Install:** `cargo install htmlq`

**Key commands:**

```bash
# 1. Extract text from body
curl -s https://example.com | htmlq 'body'

# 2. Get all link URLs
curl -s https://example.com | htmlq 'a' --attribute href

# 3. Get meta tags
curl -s https://example.com | htmlq 'meta[name="description"]' --attribute content

# 4. Remove unwanted elements
curl -s https://example.com | htmlq 'body' --remove-nodes 'script,style,nav'

# 5. Extract text content only
curl -s https://example.com | htmlq --text 'article'

# 6. Pretty-print HTML
curl -s https://example.com | htmlq --pretty 'main'
```

**Config tips:**
- `--attribute` extracts a specific attribute value.
- `--remove-nodes` strips elements before extraction.
- `--text` strips all HTML tags and returns plain text.

---

## pandoc

**What it does:** A universal document converter that reads and writes dozens of formats including Markdown, HTML, LaTeX, DOCX, PDF, EPUB, reStructuredText, and many more.

**Why it's useful:** The Swiss army knife of document conversion. Convert between virtually any document format while preserving structure, tables, citations, and formatting.

**Install:** `sudo apt install pandoc`

**Key commands:**

```bash
# 1. Markdown to HTML
pandoc -f markdown -t html -o output.html input.md

# 2. Markdown to PDF (requires LaTeX)
pandoc input.md -o output.pdf

# 3. Markdown to DOCX
pandoc input.md -o output.docx

# 4. HTML to Markdown
pandoc -f html -t markdown -o output.md input.html

# 5. Standalone HTML (with head/body)
pandoc -s -o output.html input.md

# 6. With table of contents
pandoc -s --toc -o output.html input.md

# 7. With custom CSS
pandoc -s -c style.css -o output.html input.md

# 8. DOCX to Markdown
pandoc -f docx -t markdown -o output.md input.docx

# 9. Multiple input files
pandoc ch1.md ch2.md ch3.md -o book.html

# 10. Convert from URL
pandoc -f html -t markdown https://example.com
```

**Config tips:**
- For PDF output, install `texlive-latex-base` and `texlive-fonts-recommended`.
- Use `--template` for custom output templates.
- `--metadata title="My Document"` sets document metadata.
- Pandoc Markdown supports extensions beyond standard Markdown (tables, footnotes, citations).

---

# PART 4: MISC POWER TOOLS

---

## tmux (Advanced)

**What it does:** Terminal multiplexer that lets you create multiple terminal sessions, split panes, and detach/reattach sessions that persist even when you disconnect.

**Why it's useful:** Essential for remote work -- sessions survive disconnects. Split your terminal into panes, manage multiple projects in sessions, and script complex layouts.

**Install:** `sudo apt install tmux`

**Key commands:**

```bash
# 1. New named session
tmux new -s project

# 2. Detach (inside tmux)
# Ctrl-b d

# 3. List sessions
tmux ls

# 4. Reattach to session
tmux attach -t project

# 5. Split pane horizontally / vertically
# Ctrl-b "    (horizontal split)
# Ctrl-b %    (vertical split)

# 6. Synchronize panes (type in all panes at once)
# Ctrl-b :setw synchronize-panes on

# 7. Navigate panes
# Ctrl-b arrow-key

# 8. Create new window
# Ctrl-b c

# 9. Switch windows
# Ctrl-b 0-9  (by number)
# Ctrl-b n/p  (next/previous)

# 10. Resize pane
# Ctrl-b Ctrl-arrow-key

# Scripted layout
tmux new-session -d -s dev -n editor
tmux send-keys -t dev:editor 'vim .' Enter
tmux split-window -t dev:editor -h
tmux send-keys -t dev:editor.1 'npm run dev' Enter
tmux split-window -t dev:editor -v
tmux send-keys -t dev:editor.2 'git log --oneline -20' Enter
tmux attach -t dev
```

**~/.tmux.conf tips:**

```
# Start windows at 1 instead of 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Mouse support
set -g mouse on

# Vi mode for copy
setw -g mode-keys vi

# Increase scrollback
set -g history-limit 50000

# Faster escape
set -sg escape-time 0

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
```

---

## GNU Parallel

**What it does:** A shell tool for executing jobs in parallel using one or more computers, replacing xargs and for-loops with a parallel execution engine.

**Why it's useful:** Turn any serial task into a parallel one. Process files, run commands, or transform data across all your CPU cores with simple syntax.

**Install:** `sudo apt install parallel`

**Key commands:**

```bash
# 1. Run command on multiple inputs
parallel echo ::: A B C D

# 2. Process files in parallel (4 jobs)
ls *.jpg | parallel -j4 convert {} {.}.png

# 3. Replace xargs (parallel execution)
find . -name "*.log" | parallel gzip

# 4. Multiple arguments
parallel echo {1} {2} ::: A B ::: 1 2
# Output: A 1, A 2, B 1, B 2

# 5. Progress bar
ls *.csv | parallel --bar -j4 'mlr --csv sort-by -f name {} > sorted/{/}'

# 6. Pipe data chunks to commands
cat bigfile.txt | parallel --pipe -L 1000 wc -l

# 7. Run on multiple remote hosts
parallel -S server1,server2 echo ::: A B C D

# 8. Keep output order matching input order
ls *.txt | parallel -k 'wc -l {}' | sort -n

# 9. Retry failed jobs
parallel --retries 3 curl -sO ::: url1 url2 url3

# 10. Dry run (show what would run)
parallel --dry-run echo ::: A B C
```

**Config tips:**
- First run asks you to cite GNU Parallel. Run `parallel --citation` once to acknowledge.
- `{.}` = input without extension, `{/}` = basename, `{//}` = directory.
- Use `-j+0` to use all CPU cores, `-j 75%` for 75% of cores.
- `--eta` shows estimated time of arrival.

---

## pv (Pipe Viewer)

**What it does:** Monitors the progress of data through a pipeline, showing transfer rate, elapsed time, percentage complete, and ETA.

**Why it's useful:** See progress bars for any pipe operation. Know how long that `dd`, compression, or database dump will actually take.

**Install:** `sudo apt install pv`

**Key commands:**

```bash
# 1. Monitor file copy/write
pv bigfile.iso > /dev/sdb

# 2. Monitor compression
pv bigfile.tar | gzip > bigfile.tar.gz

# 3. Monitor with known size (shows percentage)
pv -s $(stat -c%s bigfile.tar) bigfile.tar | gzip > bigfile.tar.gz

# 4. Database dump progress
mysqldump -u root mydb | pv | gzip > mydb.sql.gz

# 5. Rate-limit a pipe
pv -L 10m bigfile.iso > /dev/sdb  # limit to 10 MB/s

# 6. Between two commands
cat /dev/urandom | pv -s 1G -S | dd of=randomfile bs=1M count=1024

# 7. Monitor network transfer
pv file.tar.gz | ssh user@server 'cat > /remote/file.tar.gz'

# 8. Multiple pv instances in a pipeline
pv -cN source bigfile.tar | gzip | pv -cN gzip > bigfile.tar.gz
```

**Config tips:**
- Use `-s SIZE` whenever you know the total size for percentage/ETA display.
- `-c` and `-N name` label multiple pv instances in the same pipeline.
- Works anywhere in a pipeline -- insert between any two commands.

---

## moreutils (sponge, ts, vidir, etc.)

**What it does:** A collection of additional UNIX utilities that should have been in coreutils: `sponge` (write to same file you read), `ts` (timestamp lines), `vidir` (edit directory in vim), and more.

**Why it's useful:** Fills critical gaps in standard UNIX tools. `sponge` alone saves you from temp-file gymnastics constantly.

**Install:** `sudo apt install moreutils`

**Key commands:**

```bash
# sponge: read all input before writing (allows same-file read/write)
sort file.txt | sponge file.txt          # sort file in place
grep -v "bad" data.txt | sponge data.txt # filter file in place

# ts: add timestamps to output
ping google.com | ts '[%Y-%m-%d %H:%M:%S]'
long-running-command | ts

# vidir: edit filenames in your editor
vidir                      # edit current directory
vidir /path/to/photos/     # bulk rename files in vim

# ifdata: get network interface info
ifdata -pa eth0            # print IP address
ifdata -pn eth0            # print netmask

# chronic: run command, only show output on failure
chronic backup-script.sh   # silent if success, shows output if failure

# combine: boolean operations on files (line-level)
combine file1.txt and file2.txt   # lines in both files
combine file1.txt not file2.txt   # lines in file1 but not file2
combine file1.txt or file2.txt    # lines in either file

# errno: look up errno names and descriptions
errno ENOENT
errno -l     # list all

# pee: tee to multiple commands
echo "hello" | pee 'wc -c' 'wc -w'
```

**Config tips:**
- `sponge` is the most commonly used tool -- it soaks up all input before writing output, solving the "can't redirect to the same file" problem.
- `chronic` is perfect for cron jobs: silent on success, noisy on failure.
- `vidir` uses `$EDITOR` -- great for bulk file renames.

---

## trash-cli

**What it does:** A command-line interface to the FreeDesktop.org trash specification -- moves files to trash instead of permanently deleting them.

**Why it's useful:** Safety net for `rm`. Files go to the system trash (same as the desktop trash can) and can be restored.

**Install:** `sudo apt install trash-cli`

**Key commands:**

```bash
# 1. Move files to trash (instead of rm)
trash-put file.txt
trash-put *.log

# 2. List trashed files
trash-list

# 3. Restore a trashed file
trash-restore

# 4. Empty trash for files older than 30 days
trash-empty 30

# 5. Empty all trash
trash-empty

# 6. Remove specific file from trash
trash-rm file.txt
```

**Config tips:**
- Alias rm for safety: `alias rm='trash-put'` (controversial but useful on workstations).
- Or use a safer alias: `alias rm='rm -I'` (prompts before deleting more than 3 files).
- Trash location: `~/.local/share/Trash/`.

---

## thefuck

**What it does:** Corrects your previous console command by analyzing the error output and suggesting the right command.

**Why it's useful:** Automatically fixes typos, missing sudo, wrong git commands, and dozens of other common mistakes. Just type `fuck` after an error.

**Install:** `sudo apt install thefuck` or `pip install thefuck`

**Key commands:**

```bash
# 1. Setup: add to .bashrc
eval "$(thefuck --alias)"

# 2. After a failed command, just type:
fuck
# It suggests the corrected command and runs it

# 3. Custom alias
eval "$(thefuck --alias oops)"
# Now use: oops

# Examples of what it fixes:
apt install vim        # -> sudo apt install vim
git push              # -> git push --set-upstream origin branch
cd /ect               # -> cd /etc
python script.py      # -> python3 script.py
pacman -S pkg         # -> sudo pacman -S pkg
```

**Config tips:**
- Config at `~/.config/thefuck/settings.py`.
- Set `require_confirmation = True` to always confirm before running.
- Disable specific rules: `exclude_rules = ['rm_dir']`.

---

## pet

**What it does:** A simple command-line snippet manager that stores, searches, and executes frequently used commands with parameter support.

**Why it's useful:** Never forget a complex command again. Store commands with descriptions, search with fuzzy finder, and execute with parameter substitution.

**Install:** Download from https://github.com/knqyf263/pet/releases

**Key commands:**

```bash
# 1. Add a new snippet
pet new

# 2. Search and run a snippet
pet exec

# 3. List all snippets
pet list

# 4. Search snippets
pet search

# 5. Edit snippets file directly
pet edit

# 6. Sync to GitHub Gist
pet sync

# 7. Add with parameters (prompted at execution)
# When adding, use <param> placeholders:
# Command: ssh <user>@<host> -p <port=22>

# 8. Configure fzf integration
pet configure
```

**Config tips:**
- Config at `~/.config/pet/config.toml`.
- Snippets stored at `~/.config/pet/snippet.toml`.
- Integrates with fzf for fuzzy searching.
- Use `<param=default>` for parameters with defaults.
- Sync snippets across machines via GitHub Gist.

---

## Clipboard Tools (xclip / xsel / wl-copy)

**What it does:** Command-line access to the system clipboard. `xclip`/`xsel` for X11, `wl-copy`/`wl-paste` for Wayland.

**Why it's useful:** Pipe anything to/from the clipboard. Copy command output, paste into terminals, integrate clipboard into scripts.

**Install:** `sudo apt install xclip xsel wl-clipboard`

**Key commands:**

```bash
# X11 (xclip):
# 1. Copy to clipboard
echo "hello" | xclip -selection clipboard
cat file.txt | xclip -selection clipboard

# 2. Paste from clipboard
xclip -selection clipboard -o

# 3. Copy file contents
xclip -selection clipboard < file.txt

# X11 (xsel):
# 4. Copy to clipboard
echo "hello" | xsel --clipboard --input

# 5. Paste from clipboard
xsel --clipboard --output

# Wayland (wl-clipboard):
# 6. Copy to clipboard
echo "hello" | wl-copy
cat file.txt | wl-copy

# 7. Paste from clipboard
wl-paste

# 8. Copy an image
wl-copy < screenshot.png

# 9. Clear clipboard
wl-copy --clear
```

**Config tips:**
- Create universal aliases in .bashrc:
  ```bash
  if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      alias clip='wl-copy'
      alias paste='wl-paste'
  else
      alias clip='xclip -selection clipboard'
      alias paste='xclip -selection clipboard -o'
  fi
  ```
- `xclip` has three selections: `primary` (middle-click), `secondary`, `clipboard` (Ctrl+C/V).

---

## strace

**What it does:** Traces all system calls made by a process, showing every interaction between a program and the Linux kernel (file access, network, memory, etc.).

**Why it's useful:** The ultimate debugging tool. See exactly what a program is doing: which files it opens, which syscalls fail, where it's spending time.

**Install:** `sudo apt install strace`

**Key commands:**

```bash
# 1. Trace a command
strace ls -la

# 2. Trace a running process
sudo strace -p 12345

# 3. Trace with child processes
strace -f ./my-program

# 4. Filter specific syscalls
strace -e openat,read,write ./my-program

# 5. Show timing information
strace -T ./my-program

# 6. Summary statistics
strace -c ./my-program

# 7. Trace network-related calls
strace -e trace=network ./my-program

# 8. Trace file-related calls
strace -e trace=file ./my-program

# 9. Save output to file
strace -o trace.log ./my-program

# 10. Increase string length shown
strace -s 1024 ./my-program
```

**Config tips:**
- Always use `-f` to follow child processes (forks).
- `-e trace=file` is a shortcut for all file-related syscalls.
- `-T` shows time spent in each call -- great for finding slow operations.
- `-c` gives a statistical summary instead of full trace.

---

## ltrace

**What it does:** Traces library calls made by a program, showing every call to shared libraries (libc, libssl, etc.) with arguments and return values.

**Why it's useful:** Complements strace by showing higher-level library calls (malloc, free, printf, strlen, SSL calls) instead of raw syscalls.

**Install:** `sudo apt install ltrace`

**Key commands:**

```bash
# 1. Trace library calls
ltrace ./my-program

# 2. Trace a running process
sudo ltrace -p 12345

# 3. Show system calls too (combined view)
ltrace -S ./my-program

# 4. Filter specific library calls
ltrace -e malloc+free ./my-program

# 5. Follow child processes
ltrace -f ./my-program

# 6. Summary statistics
ltrace -c ./my-program

# 7. Show timestamps
ltrace -t ./my-program

# 8. Increase string length
ltrace -s 200 ./my-program
```

**Config tips:**
- Combine with strace for full picture: strace for kernel, ltrace for libraries.
- `-e malloc+free-@libc.so*` traces memory allocation from libc specifically.
- `-c` summary helps identify which library functions are called most.

---

## lsof (Tips)

**What it does:** Lists open files -- and since "everything is a file" in Linux, this includes network connections, devices, pipes, and sockets.

**Why it's useful:** Essential for debugging "file in use" errors, finding which process is using a port, identifying open network connections, and tracking file descriptor leaks.

**Install:** `sudo apt install lsof` (usually pre-installed).

**Key commands:**

```bash
# 1. Find what's using a port
sudo lsof -i :8080

# 2. Show all network connections for a process
sudo lsof -i -a -p 12345

# 3. Find who has a file open
lsof /path/to/file

# 4. All files opened by a user
lsof -u username

# 5. All files opened by a process
lsof -p 12345

# 6. All listening TCP ports
sudo lsof -iTCP -sTCP:LISTEN -nP

# 7. Find deleted but still-open files (disk space issues)
sudo lsof +L1

# 8. Files open in a directory
lsof +D /var/log/

# 9. Show all IPv4 connections
sudo lsof -i4

# 10. Repeat every 2 seconds (watch mode)
lsof -i :8080 -r 2
```

**Config tips:**
- `-n` skips DNS resolution, `-P` skips port-to-service name mapping -- both make it faster.
- `+L1` finds deleted files still held open by processes (common cause of phantom disk usage).
- `-r` repeat mode is like `watch` built into lsof.

---

## GNU Screen

**What it does:** The original terminal multiplexer -- creates persistent terminal sessions that survive disconnects with window management and split screens.

**Why it's useful:** Pre-dates tmux and is available on virtually every UNIX system, including minimal server installs. Useful when tmux is not available.

**Install:** `sudo apt install screen`

**Key commands:**

```bash
# 1. Start a named session
screen -S mysession

# 2. Detach
# Ctrl-a d

# 3. List sessions
screen -ls

# 4. Reattach
screen -r mysession

# 5. Create new window
# Ctrl-a c

# 6. Switch windows
# Ctrl-a n  (next)
# Ctrl-a p  (previous)
# Ctrl-a 0-9 (by number)

# 7. Split horizontal / vertical
# Ctrl-a S  (horizontal)
# Ctrl-a |  (vertical)

# 8. Navigate between splits
# Ctrl-a Tab

# 9. Kill a window
# Ctrl-a k

# 10. Scrollback mode
# Ctrl-a [  (then use arrow keys / Page Up/Down)
```

**Config tips:**
- Config at `~/.screenrc`.
- Add `defscrollback 10000` for more scrollback history.
- Add `startup_message off` to skip the splash screen.
- Prefer tmux for new setups; use screen on systems where tmux is unavailable.

---

## tee (Tricks)

**What it does:** Reads from stdin and writes to both stdout and one or more files simultaneously, like a T-junction in a pipe.

**Why it's useful:** Log output while still displaying it, write to multiple files at once, or capture intermediate pipeline results.

**Install:** Pre-installed (part of coreutils).

**Key commands:**

```bash
# 1. Log output while displaying it
make 2>&1 | tee build.log

# 2. Append to file (instead of overwrite)
echo "new entry" | tee -a logfile.txt

# 3. Write to multiple files
echo "data" | tee file1.txt file2.txt file3.txt

# 4. Sudo write trick (write to protected file)
echo "config line" | sudo tee /etc/myconfig.conf > /dev/null

# 5. Append to protected file
echo "new line" | sudo tee -a /etc/hosts > /dev/null

# 6. Capture intermediate pipeline results
cat data.csv | tee raw.csv | sort | tee sorted.csv | head -20

# 7. Process substitution (tee to commands)
cat data.txt | tee >(wc -l) >(grep error > errors.txt) > /dev/null
```

**Config tips:**
- `> /dev/null` after tee suppresses stdout when you only want the file.
- Process substitution `>(command)` lets tee feed multiple commands.
- `tee` + `sudo` is the proper way to write to root-owned files from a pipe.

---

## figlet / toilet / lolcat / cmatrix / pipes.sh

**What it does:** Fun terminal tools: `figlet` creates ASCII art text, `toilet` adds color filters to ASCII art, `lolcat` adds rainbow coloring to any output, `cmatrix` displays The Matrix rain effect, `pipes.sh` shows animated pipe screensaver.

**Why it's useful:** Terminal customization, MOTD banners, making presentations fun, and impressing colleagues. Also great for shell script splash screens.

**Install:**

```bash
sudo apt install figlet toilet lolcat cmatrix
# pipes.sh:
sudo apt install pipes.sh  # or install from https://github.com/pipeseroni/pipes.sh
```

**Key commands:**

```bash
# 1. ASCII art text
figlet "Hello World"

# 2. figlet with specific font
figlet -f slant "Deploy"
figlet -f banner "SERVER01"
showfigfonts  # preview all installed fonts

# 3. toilet with color filter
toilet -f mono12 --filter border "Status: OK"
toilet --metal "Metal Text"
toilet --gay "Rainbow"  # built-in rainbow

# 4. Rainbow coloring on any output
echo "Hello World" | lolcat
figlet "Deploy" | lolcat
ls -la | lolcat

# 5. Animated rainbow
lolcat -a -d 5 <<< "$(figlet 'DEPLOYING')"

# 6. Matrix rain effect
cmatrix
cmatrix -b   # bold
cmatrix -C red  # color

# 7. Pipe screensaver
pipes.sh
pipes.sh -t 0  # different pipe type

# 8. Combine them all
figlet "PROD READY" | toilet --filter border | lolcat
```

**Config tips:**
- `figlet -I 2` shows the font directory; download more fonts from figlet.org.
- Add `figlet` + `lolcat` banners to your `.bashrc` or MOTD.
- `toilet` is figlet-compatible but adds color filters natively.

---

## asciinema

**What it does:** Records terminal sessions as lightweight asciicast files that can be replayed in a terminal or embedded on web pages with perfect fidelity.

**Why it's useful:** Create terminal recordings for documentation, tutorials, and bug reports. Files are tiny (text-based), and playback is pixel-perfect because it records text, not video.

**Install:** `sudo apt install asciinema`

**Key commands:**

```bash
# 1. Record a session
asciinema rec demo.cast

# 2. Record with title
asciinema rec -t "My Demo" demo.cast

# 3. Record with idle time limit (speed up pauses)
asciinema rec --idle-time-limit 2 demo.cast

# 4. Play back a recording
asciinema play demo.cast

# 5. Play at double speed
asciinema play -s 2 demo.cast

# 6. Upload to asciinema.org
asciinema upload demo.cast

# 7. Record and upload in one step
asciinema rec

# 8. Concatenate recordings
asciinema cat first.cast second.cast > combined.cast
```

**Config tips:**
- Config at `~/.config/asciinema/config`.
- Set `idle_time_limit = 2` to auto-trim pauses.
- Recordings are JSON text files -- you can edit them.
- Embed in HTML with the asciinema-player JavaScript library.

---

## VHS (Charmbracelet)

**What it does:** Write terminal GIFs as code using a simple `.tape` script format. Creates reproducible, pixel-perfect terminal recordings as GIF, MP4, or WebM.

**Why it's useful:** Declarative terminal recordings for documentation, CI/CD, and demos. Scripts are version-controllable and reproducible -- no manual recording needed.

**Install:** `sudo apt install vhs ffmpeg` (via Charm apt repo) or `go install github.com/charmbracelet/vhs@latest`

**Key commands:**

```bash
# 1. Create a tape file
cat > demo.tape << 'EOF'
Output demo.gif
Set FontSize 14
Set Width 1200
Set Height 600
Type "echo Hello, World!"
Enter
Sleep 1s
Type "ls -la"
Enter
Sleep 2s
EOF

# 2. Run the tape to generate GIF
vhs demo.tape

# 3. Output as MP4
# Change first line to: Output demo.mp4

# 4. Available tape commands:
# Type "text"       - types text
# Enter             - presses Enter
# Sleep 500ms       - waits
# Ctrl+C            - sends ctrl+c
# Set FontSize 16   - configure font
# Set Theme "Dracula"  - set theme
# Hide/Show         - hide/show output
# Wait              - wait for specific conditions

# 5. Validate a tape file
vhs validate demo.tape

# 6. Run via Docker
docker run --rm -v $PWD:/vhs ghcr.io/charmbracelet/vhs demo.tape
```

**Config tips:**
- Tape files support `Set` for Shell, FontSize, FontFamily, Width, Height, Theme, Padding, Framerate.
- Use `Hide` before setup commands and `Show` before the demo portion.
- Integrates with CI via `charmbracelet/vhs-action` GitHub Action.

---

## gum (Charmbracelet)

**What it does:** A toolkit for making glamorous, interactive shell scripts with styled prompts, selection menus, confirmation dialogs, spinners, and more.

**Why it's useful:** Turn ugly bash scripts into beautiful interactive experiences. No need to learn a TUI framework -- just call gum commands from your shell scripts.

**Install:** `sudo apt install gum` (via Charm repo) or `go install github.com/charmbracelet/gum@latest`

**Key commands:**

```bash
# 1. Text input prompt
NAME=$(gum input --placeholder "Enter your name")

# 2. Multi-line text input
DESCRIPTION=$(gum write --placeholder "Describe the changes...")

# 3. Selection menu (choose one)
COLOR=$(gum choose "red" "green" "blue" "yellow")

# 4. Multi-select (choose many)
TOPPINGS=$(gum choose --no-limit "cheese" "pepperoni" "mushrooms" "olives")

# 5. Confirmation dialog
gum confirm "Deploy to production?" && echo "Deploying..." || echo "Cancelled"

# 6. Fuzzy filter from a list
BRANCH=$(git branch --format='%(refname:short)' | gum filter)

# 7. Spinner for long-running tasks
gum spin --spinner dot --title "Installing..." -- sleep 5

# 8. Styled text output
gum style --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    "Deploy Complete" "Version 1.2.3"

# 9. Git commit with gum
TYPE=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore")
SCOPE=$(gum input --placeholder "scope")
SUMMARY=$(gum input --value "$TYPE($SCOPE): " --placeholder "Summary")
DETAIL=$(gum write --placeholder "Details (optional)")
gum confirm "Commit?" && git commit -m "$SUMMARY" -m "$DETAIL"

# 10. Join/format output
gum join --align center --vertical "$(gum style --bold 'Title')" "$(gum style 'Subtitle')"
```

**Config tips:**
- All styling via flags: `--foreground`, `--background`, `--border`, `--bold`, etc.
- Spinner types: line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger.
- Combine with other Charm tools (mods, freeze) for powerful workflows.

---

## mods (Charmbracelet)

**What it does:** AI on the command line -- pipes stdin through an LLM (OpenAI, Anthropic, local models) and returns the result, making your pipelines AI-powered.

**Why it's useful:** Add AI to any shell pipeline: summarize logs, explain errors, generate code, translate text, and more -- all from the terminal.

**Install:** `go install github.com/charmbracelet/mods@latest` or `brew install charmbracelet/tap/mods`

**Key commands:**

```bash
# 1. Simple prompt
mods "what is the capital of France?"

# 2. Pipe data for analysis
cat error.log | mods "summarize these errors"

# 3. Code explanation
cat script.py | mods "explain this code"

# 4. Generate a commit message
git diff --cached | mods "write a conventional commit message for these changes"

# 5. Convert formats
cat data.csv | mods "convert this CSV to a markdown table"

# 6. Use a specific model
cat log.txt | mods --model gpt-4 "find security issues"

# 7. Continued conversation
mods --continue "elaborate on that last point"

# 8. List available models
mods --list-models
```

**Config tips:**
- Config at `~/.config/mods/mods.yml`.
- Supports OpenAI, Anthropic, Ollama (local), and other LLM providers.
- Set default model and API keys in the config file.

---

## freeze (Charmbracelet)

**What it does:** Generates beautiful images (SVG, PNG, WebP) of code and terminal output with syntax highlighting, themes, and customization.

**Why it's useful:** Create shareable, beautiful code screenshots from the terminal. Perfect for documentation, social media, and presentations.

**Install:** `go install github.com/charmbracelet/freeze@latest` or `brew install charmbracelet/tap/freeze`

**Key commands:**

```bash
# 1. Screenshot a code file
freeze main.go --output code.png

# 2. Screenshot with specific language
freeze --language python script.py --output code.svg

# 3. Pipe terminal output
ls -la | freeze --output listing.png

# 4. Screenshot with theme
freeze --theme dracula main.go --output code.png

# 5. Interactive mode (customize in TUI)
freeze main.go

# 6. WebP output
freeze main.go --output code.webp

# 7. Custom window chrome
freeze --window --border.radius 8 --shadow main.go --output styled.png
```

**Config tips:**
- Settings saved to `$XDG_CONFIG/freeze/user.json` from interactive mode.
- Auto-detects language from filename; override with `--language`.
- Supports all output formats: SVG, PNG, WebP.

---

This reference covers the major CLI/TUI power tools for Ubuntu Linux across networking,
security, text processing, and miscellaneous categories. Tools are current as of early 2026.

For installation of Charmbracelet tools via their apt repository:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update
sudo apt install gum vhs freeze mods
```

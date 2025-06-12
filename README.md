# mongo db recon : automated 
not perfect but useful scripts i wrote for automating recon on target host
![screen](https://github.com/user-attachments/assets/187c4231-884b-4eeb-9ffd-bf362c12a5f8)

First you run shodan_ips.py > collect target range > copy output to mongo script

Configurable Targets: Edit the IPS and COMMON_PORTS arrays to specify which hosts and ports to scan.

Fast Port Discovery: Uses nc -z with a 2-second timeout to skip closed ports and stops on the first open port per host.

Dual-Mode Connection: Attempts a plaintext MongoDB shell first; on network failures, automatically retries over TLS with --tls --tlsAllowInvalidCertificates.

Reliable JSON Parsing: Extracts only the {…} JSON payload from mixed shell output and uses jq to list database names.

Ransomware Detection: Flags any database named READ_ME_TO_RECOVER_YOUR_DATA (or variants) as encrypted, rather than listing it.

Authentication Awareness: Checks for “Unauthorized” errors and reports when a server requires credentials instead of a false failure (especially with force listing dbs)

Minimal Dependencies: Written in Bash; only requires nc, docker, and jq.

#!/usr/bin/env bash
# ex16x41
# mongo-scan.sh
# Fast scan of IPs on common MongoDB ports, only testing known ports,
# then for each open port, docker-run mongo shell to list databases.
# for educational use only, don't use if not allowed

set -euo pipefail

### ── CONFIG ───────────────────────────────────────────────────────────────────

# Target IPs
IPS=(
TARGET IP 
TARGET IP
TARGET IP
TARGET IP
TARGET IP
TARGET IP
TARGET IP
TARGET IP
TARGET IP
)

# Only the truly common MongoDB ports as per Shodan
COMMON_PORTS=(
  27017 7000 28017 20000 30002 30017 6666 30003 30001
  10001 30000 5000 11000 8017 8001 31017 3000 7001
  6000 6002 8888 9000 10002 8080 8090 9999
)

# Where to save results
OUTFILE="mongo-scan-results.txt"

### ── SCRIPT ────────────────────────────────────────────────────────────────────

# Start fresh
: > "$OUTFILE"

for ip in "${IPS[@]}"; do
  echo "================================================================================"
  echo "Host: $ip"
  echo "--------------------------------------------------------------------------------"
  echo "$ip" >> "$OUTFILE"

  for port in "${COMMON_PORTS[@]}"; do
    printf "  → Port %-5s : " "$port"

    # Quick TCP check (nc -z = scan, -w2 = 2s timeout)
    if nc -z -w2 "$ip" "$port" 2>/dev/null; then
      # Port is open → check MongoDB
      result=$(
        docker run --rm -i mongo:4.4 \
          mongo --host "$ip" --port "$port" --quiet \
          --eval '
            try {
              var names = db.adminCommand({ listDatabases:1 })
                           .databases.map(function(d){ return d.name });
              print(names.length ? names.join(", ") : "<no databases>");
            } catch(e) {
              print("<unauthorized or error>");
            }
          ' 2>/dev/null
      ) || result="<mongo shell error>"

      echo "$result"
      echo "  $port: $result" >> "$OUTFILE"
    else
      # Port closed or filtered
      echo "<closed>"
      echo "  $port: <closed>" >> "$OUTFILE"
    fi
  done

  echo
done

echo "Done. Results saved in $OUTFILE"

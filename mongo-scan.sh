#!/usr/bin/env bash
# by ex16x41
set -euo pipefail

# ANSI color codes
RED="\033[1;31m"        # bright red
YELLOW="\033[1;93m"     # bright yellow
ORANGE="\033[0;33m"     # brown/orange
DARKGREEN="\033[0;32m"  # dark green
RESET="\033[0m"         # reset to default

IPS=(
IP ADDRESS
IP ADDRESS
IP ADDRESS
)

COMMON_PORTS=(27017 7000 28017 20000 30002 30017 6666 30003 30001 10001)

# Extracts pure JSON block
extract_json() {
  printf "%s\n" "$1" | awk '/^{/{flag=1} flag'
}

for ip in "${IPS[@]}"; do
  echo "=============================="
  echo "Host: $ip"
  echo "------------------------------"

  port_found=0
  for port in "${COMMON_PORTS[@]}"; do
    if ! nc -z -w2 "$ip" "$port" 2>/dev/null; then
      continue
    fi

    port_found=1
    echo "→ Identified MongoDB Open Port: $port"

    # Plaintext test
    echo "   • Testing MongoDB access…"
    set +e
    plain_raw=$(docker run --rm -i mongo:4.4 \
      mongo --quiet --host "$ip" --port "$port" \
           --eval 'printjson(db.getMongo().getDBs())' 2>/dev/null)
    plain_code=$?
    set -e

    if [ $plain_code -eq 0 ]; then
      plain_json=$(extract_json "$plain_raw" || true)
      if jq -e 'has("databases")' <<<"$plain_json" &>/dev/null; then
        # Ransomware check
        if jq -e '.databases[].name | select(test("^READ_+ME_TO_RECOVER_YOUR_DATA$"))' \
             <<<"$plain_json" &>/dev/null; then
          echo -e "   ${RED}! This MongoDB is encrypted for ransomware${RESET}"
          break
        fi
        # List DBs
        names=$(jq -r '(.databases | map(.name)) | join(",")' <<<"$plain_json")
        echo -e "   ✓ Databases: ${YELLOW}$names${RESET}"
        break
      fi
    fi

    # Auth‐only?
    if grep -qi "Unauthorized" <<<"$plain_raw" \
       || grep -qi "requires authentication" <<<"$plain_raw"; then
      echo -e "   ${ORANGE}⚠ Access works, but requires authentication to list databases${RESET}"
      break
    fi

    # Retry via TLS
    echo "   ✗ Access failed, retrying via TLS…"
    echo "   • Testing access via TLS"
    set +e
    tls_raw=$(docker run --rm -i mongo:4.4 \
      mongo --quiet --host "$ip" --port "$port" \
           --tls --tlsAllowInvalidCertificates \
           --eval 'printjson(db.getMongo().getDBs())' 2>/dev/null)
    tls_code=$?
    set -e

    if [ $tls_code -eq 0 ]; then
      tls_json=$(extract_json "$tls_raw" || true)
      if jq -e 'has("databases")' <<<"$tls_json" &>/dev/null; then
        # Ransomware check under TLS
        if jq -e '.databases[].name | select(test("^READ_+ME_TO_RECOVER_YOUR_DATA$"))' \
             <<<"$tls_json" &>/dev/null; then
          echo -e "   ${RED}! This MongoDB is encrypted for ransomware${RESET}"
        else
          tls_names=$(jq -r '(.databases | map(.name)) | join(",")' <<<"$tls_json")
          echo -e "   ✓ Databases (TLS): ${YELLOW}$tls_names${RESET}"
        fi
      else
        echo "   ✓ Connected via TLS (no DBs visible)"
      fi
    else
      if grep -qi "Unauthorized" <<<"$tls_raw" \
         || grep -qi "requires authentication" <<<"$tls_raw"; then
        echo -e "   ${ORANGE}⚠ Access works, but requires authentication to list databases${RESET}"
      else
        first_tls=$(head -n1 <<<"$tls_raw")
        echo -e "   ${DARKGREEN}✗ Access via TLS failed: ${first_tls}${RESET}"
      fi
    fi

    break
  done

  if [ $port_found -eq 0 ]; then
    echo "→ No common MongoDB ports open"
  fi
  echo
done

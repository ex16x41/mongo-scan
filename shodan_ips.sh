#!/usr/bin/env python3
"""
shodan_ips.py

Queries Shodan for a specified filter using the shodan-python library
and writes the total number of results and all matching IPs across all pages
into a file `results.txt` in the current working directory.

Usage:
  export SHODAN_API_KEY=<your key>
  python3 shodan_ips.py "MongoDB Server Information -authentication country:CN"

Requires:
  pip install shodan
"""
import os
import sys
import shodan

def main():
    api_key = os.getenv('SHODAN_API_KEY')
    if not api_key:
        print('Error: SHODAN_API_KEY environment variable not set.', file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <filter>', file=sys.stderr)
        sys.exit(1)

    query = sys.argv[1]
    client = shodan.Shodan(api_key)

    try:
        # Initial search to get total and first page
        results = client.search(query, page=1)
    except shodan.APIError as e:
        print(f'Shodan API error: {e}', file=sys.stderr)
        sys.exit(1)

    total = results.get('total', 0)
    output_file = 'results.txt'

    # Open file and write results
    with open(output_file, 'w') as outfile:
        outfile.write(f'Total Results: {total}\n')
        page = 1
        while True:
            for match in results.get('matches', []):
                ip = match.get('ip_str')
                if ip:
                    outfile.write(ip + '\n')
            # Check if we have fetched all pages
            if page * 100 >= total:
                break
            page += 1
            try:
                results = client.search(query, page=page)
            except shodan.APIError as e:
                print(f'API error on page {page}: {e}', file=sys.stderr)
                break

    # Notify user
    cwd = os.getcwd()
    print(f"Total results {total}, exported into new document {output_file} in {cwd}")

if __name__ == '__main__':
    main()

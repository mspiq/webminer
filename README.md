# 🕸️ WebMiner

> Fast Wayback Machine URL Extractor

## 🚀 Quick Install
```bash 
curl -s -L "https://raw.githubusercontent.com/mspiq/webminer/v1.0.1/installer.sh" | bash
```

## Basic Usage
```bash 
webminer -u example.com
# Domain list + save to file
webminer -l domains.txt -o urls.txt
# Check updates
webminer --check-update

```

## webminer -h
```bash
🕸  webminer v1.0.1
Wayback Machine Archive URL Extractor

Usage:
  ./webminer.sh -u example.com                 # Scan single domain
  ./webminer.sh -l domains.txt                # Scan domain list
  ./webminer.sh -l domains.txt -o results.txt # Save results to file
  ./webminer.sh -u example.com -o urls.txt    # Scan domain and save results
  ./webminer.sh --update                      # Update tool
  ./webminer.sh --version                     # Show version
  ./webminer.sh --check-update                # Check for updates

Options:
  -u URL     Target domain (e.g., example.com)
  -l FILE    File containing domain list
  -o FILE    Save results to file (optional)
  -h         Show this help

Examples:
  ./webminer.sh -u google.com
  ./webminer.sh -l domains.txt -o wayback_urls.txt
  ./webminer.sh -l my_domains.txt
  ./webminer.sh --check-update
```

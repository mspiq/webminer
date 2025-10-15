#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Tool information
TOOL_NAME="webminer"
VERSION="1.0.1"
GITHUB_REPO="mspiq/webminer"  # Change to your repo

# File paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Check for updates
check_update() {
    echo -e "${CYAN}🔍 Checking for updates...${NC}"
    
    # Get latest version from GitHub
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_VERSION" ]]; then
        echo -e "${YELLOW}⚠️  Cannot check for updates${NC}"
        return 1
    fi
    
    if [[ "$LATEST_VERSION" != "$VERSION" ]]; then
        echo -e "${YELLOW}🔄 New update available: $LATEST_VERSION${NC}"
        echo -e "${BLUE}Current version: $VERSION${NC}"
        
        read -p "Do you want to update now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_tool
        fi
    else
        echo -e "${GREEN}✅ You are using the latest version ($VERSION)${NC}"
    fi
}

# Update the tool
update_tool() {
    echo -e "${CYAN}🔄 Updating...${NC}"
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download updated tool
    if curl -s -L "https://github.com/$GITHUB_REPO/raw/main/webminer.sh" -o "webminer_new.sh"; then
        # Verify file is not empty
        if [[ -s "webminer_new.sh" ]]; then
            # Copy updated tool
            sudo cp "webminer_new.sh" "$INSTALL_DIR/webminer"
            sudo chmod +x "$INSTALL_DIR/webminer"
            
            # Update version file
            echo "$LATEST_VERSION" | sudo tee "/usr/local/etc/webminer_version" > /dev/null
            
            echo -e "${GREEN}✅ Successfully updated to version $LATEST_VERSION${NC}"
            echo -e "${GREEN}🔄 Please restart the tool${NC}"
        else
            echo -e "${RED}❌ Failed to download update${NC}"
        fi
    else
        echo -e "${RED}❌ Connection error${NC}"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    exit 0
}

# Show version
show_version() {
    echo -e "${GREEN}$TOOL_NAME v$VERSION${NC}"
    echo -e "${CYAN}Wayback Machine URL Extractor Tool${NC}"
    exit 0
}

# Show help
show_help() {
    echo -e "${GREEN}🕸️  $TOOL_NAME v$VERSION${NC}"
    echo -e "${CYAN}Wayback Machine Archive URL Extractor${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  $0 -u example.com                 # Scan single domain"
    echo -e "  $0 -l domains.txt                # Scan domain list"
    echo -e "  $0 -l domains.txt -o results.txt # Save results to file"
    echo -e "  $0 -u example.com -o urls.txt    # Scan domain and save results"
    echo -e "  $0 --update                      # Update tool"
    echo -e "  $0 --version                     # Show version"
    echo -e "  $0 --check-update                # Check for updates"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -u URL     Target domain (e.g., example.com)"
    echo -e "  -l FILE    File containing domain list"
    echo -e "  -o FILE    Save results to file (optional)"
    echo -e "  -h         Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  $0 -u google.com"
    echo -e "  $0 -l domains.txt -o wayback_urls.txt"
    echo -e "  $0 -l my_domains.txt"
    echo -e "  $0 --check-update"
}

# Extract URLs from Wayback Machine
get_wayback_urls() {
    local domain="$1"
    local temp_file="/tmp/wayback_$$.txt"
    
    echo -e "${BLUE}🔍 Extracting URLs: $domain${NC}" >&2
    
    # Call Wayback Machine API
    curl -s -G "https://web.archive.org/cdx/search/cdx" \
        --data-urlencode "url=$domain/*" \
        --data-urlencode "collapse=urlkey" \
        --data-urlencode "output=text" \
        --data-urlencode "fl=original" > "$temp_file"
    
    # Check if results exist
    if [[ ! -s "$temp_file" ]]; then
        echo -e "${RED}❌ No URLs found for: $domain${NC}" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    # Show results or temporary save
    cat "$temp_file"
    rm -f "$temp_file"
    
    return 0
}

# Show progress
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    echo -e "${YELLOW}📊 Progress: $current/$total ($percent%)${NC}" >&2
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "sort")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}❌ $dep is not installed${NC}"
            exit 1
        fi
    done
}

# Main function
main() {
    # Check dependencies
    check_dependencies
    
    # Handle special options first
    case "$1" in
        "--update")
            check_update
            ;;
        "--version")
            show_version
            ;;
        "--check-update")
            check_update
            exit 0
            ;;
        "-h"|"--help")
            show_help
            exit 0
            ;;
    esac
    
    # Auto-check for updates (once per day)
    if [[ -f "/usr/local/etc/webminer_last_update" ]]; then
        LAST_CHECK=$(cat "/usr/local/etc/webminer_last_update")
        NOW=$(date +%s)
        if (( NOW - LAST_CHECK > 86400 )); then # 24 hours
            check_update
            date +%s | sudo tee "/usr/local/etc/webminer_last_update" > /dev/null
        fi
    else
        date +%s | sudo tee "/usr/local/etc/webminer_last_update" > /dev/null
    fi
    
    # Main variables
    local DOMAIN=""
    local INPUT_FILE=""
    local OUTPUT_FILE=""
    
    # Parse parameters
    while getopts "u:l:o:h" opt; do
        case $opt in
            u)
                DOMAIN="$OPTARG"
                ;;
            l)
                INPUT_FILE="$OPTARG"
                ;;
            o)
                OUTPUT_FILE="$OPTARG"
                ;;
            h)
                show_help
                exit 0
                ;;
            \?)
                echo -e "${RED}❌ Invalid option: -$OPTARG${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$DOMAIN" && -z "$INPUT_FILE" ]]; then
        echo -e "${RED}❌ Must specify domain (-u) or file (-l)${NC}"
        show_help
        exit 1
    fi
    
    if [[ -n "$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
        echo -e "${RED}❌ File not found: $INPUT_FILE${NC}"
        exit 1
    fi
    
    # Start
    echo -e "${GREEN}🚀 Starting $TOOL_NAME v$VERSION${NC}"
    echo -e "${BLUE}⏰ Time: $(date)${NC}"
    echo ""
    
    # Create temporary results file
    local RESULTS_FILE="/tmp/wayback_results_$$.txt"
    > "$RESULTS_FILE"
    
    # Process domains
    if [[ -n "$DOMAIN" ]]; then
        # Single domain
        local DOMAINS=("$DOMAIN")
        local TOTAL_DOMAINS=1
    else
        # Read domains from file
        mapfile -t DOMAINS < "$INPUT_FILE"
        local TOTAL_DOMAINS=${#DOMAINS[@]}
    fi
    
    echo -e "${YELLOW}📊 Domains to scan: $TOTAL_DOMAINS${NC}"
    echo ""
    
    # Process counter
    local PROCESSED=0
    local TOTAL_URLS=0
    
    # Process each domain
    for domain in "${DOMAINS[@]}"; do
        ((PROCESSED++))
        
        # Show progress if output file specified
        if [[ -n "$OUTPUT_FILE" ]]; then
            show_progress $PROCESSED $TOTAL_DOMAINS
        fi
        
        # Extract URLs for this domain
        local domain_urls=$(get_wayback_urls "$domain")
        
        if [[ $? -eq 0 && -n "$domain_urls" ]]; then
            local url_count=$(echo "$domain_urls" | wc -l)
            ((TOTAL_URLS += url_count))
            
            echo -e "${GREEN}✅ Found $url_count URLs for: $domain${NC}" >&2
            
            # Save or display results
            if [[ -n "$OUTPUT_FILE" ]]; then
                echo "$domain_urls" >> "$RESULTS_FILE"
            else
                echo "$domain_urls"
            fi
        fi
        
        
    done
    
    # Save results to final file if requested
    if [[ -n "$OUTPUT_FILE" ]]; then
        # Remove duplicates
        sort -u "$RESULTS_FILE" > "$OUTPUT_FILE"
        rm -f "$RESULTS_FILE"
        
        local FINAL_COUNT=$(wc -l < "$OUTPUT_FILE")
        echo ""
        echo -e "${GREEN}✅ Completed!${NC}"
        echo -e "${GREEN}📈 Total URLs extracted: $FINAL_COUNT${NC}"
        echo -e "${GREEN}💾 Results saved to: $OUTPUT_FILE${NC}"
    else
        # If no output file, results were already displayed
        echo ""
        echo -e "${GREEN}✅ Completed!${NC}"
        echo -e "${GREEN}📈 Total URLs extracted: $TOTAL_URLS${NC}"
    fi
    
    # Cleanup temporary files
    rm -f "/tmp/wayback_*.txt" 2>/dev/null
}

# Run main function
main "$@"

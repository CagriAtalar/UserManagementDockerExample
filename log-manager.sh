#!/bin/bash

# Log Manager Script for User Management System
# This script helps manage logs on the host system

LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/usermanagement.txt"
BACKUP_DIR="/var/log/backups"
MAX_LOG_SIZE="100M"
MAX_BACKUP_FILES=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to create log directory if it doesn't exist
create_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        print_status "Creating log directory: $LOG_DIR"
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_status "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        chmod 755 "$BACKUP_DIR"
    fi
}

# Function to check log file size and rotate if necessary
rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        local log_size_bytes=$(du -b "$LOG_FILE" | cut -f1)
        local max_size_bytes=$(numfmt --from=iec $MAX_LOG_SIZE)
        
        if [[ $log_size_bytes -gt $max_size_bytes ]]; then
            print_warning "Log file size ($log_size) exceeds maximum ($MAX_LOG_SIZE). Rotating logs..."
            
            local timestamp=$(date +"%Y%m%d_%H%M%S")
            local backup_file="$BACKUP_DIR/usermanagement_$timestamp.txt"
            
            mv "$LOG_FILE" "$backup_file"
            touch "$LOG_FILE"
            chmod 644 "$LOG_FILE"
            
            print_status "Log rotated to: $backup_file"
            
            # Clean up old backup files
            cleanup_old_backups
        else
            print_status "Log file size ($log_size) is within limits"
        fi
    else
        print_status "Log file does not exist yet. It will be created when the application starts."
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi
}

# Function to clean up old backup files
cleanup_old_backups() {
    local backup_count=$(ls -1 "$BACKUP_DIR"/usermanagement_*.txt 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt $MAX_BACKUP_FILES ]]; then
        print_warning "Found $backup_count backup files. Keeping only $MAX_BACKUP_FILES most recent ones..."
        
        ls -1t "$BACKUP_DIR"/usermanagement_*.txt | tail -n +$((MAX_BACKUP_FILES + 1)) | xargs rm -f
        
        print_status "Old backup files cleaned up"
    fi
}

# Function to show log statistics
show_log_stats() {
    print_header "Log Statistics"
    
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        local line_count=$(wc -l < "$LOG_FILE")
        local last_modified=$(stat -c %y "$LOG_FILE")
        
        echo "Current log file: $LOG_FILE"
        echo "Size: $log_size"
        echo "Lines: $line_count"
        echo "Last modified: $last_modified"
        
        # Show recent log entries
        echo ""
        echo "Recent log entries (last 10 lines):"
        echo "----------------------------------------"
        tail -n 10 "$LOG_FILE" 2>/dev/null || echo "No log entries found"
        
    else
        print_warning "Log file does not exist"
    fi
    
    # Show backup files
    local backup_count=$(ls -1 "$BACKUP_DIR"/usermanagement_*.txt 2>/dev/null | wc -l)
    echo ""
    echo "Backup files: $backup_count"
    if [[ $backup_count -gt 0 ]]; then
        echo "----------------------------------------"
        ls -lh "$BACKUP_DIR"/usermanagement_*.txt 2>/dev/null
    fi
}

# Function to tail logs in real-time
tail_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        print_status "Tailing logs in real-time (Ctrl+C to stop)..."
        tail -f "$LOG_FILE"
    else
        print_error "Log file does not exist"
        exit 1
    fi
}

# Function to search logs
search_logs() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        print_error "Please provide a search term"
        echo "Usage: $0 search <search_term>"
        exit 1
    fi
    
    if [[ -f "$LOG_FILE" ]]; then
        print_status "Searching logs for: '$search_term'"
        echo "----------------------------------------"
        grep -i "$search_term" "$LOG_FILE" || echo "No matches found"
    else
        print_error "Log file does not exist"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status     - Show log statistics and recent entries"
    echo "  rotate     - Check and rotate logs if necessary"
    echo "  tail       - Tail logs in real-time"
    echo "  search     - Search logs for a specific term"
    echo "  cleanup    - Clean up old backup files"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 rotate"
    echo "  $0 tail"
    echo "  $0 search 'error'"
    echo "  $0 cleanup"
}

# Main script logic
main() {
    case "${1:-status}" in
        "status")
            check_root
            create_log_dir
            show_log_stats
            ;;
        "rotate")
            check_root
            create_log_dir
            rotate_logs
            ;;
        "tail")
            tail_logs
            ;;
        "search")
            search_logs "$2"
            ;;
        "cleanup")
            check_root
            create_log_dir
            cleanup_old_backups
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

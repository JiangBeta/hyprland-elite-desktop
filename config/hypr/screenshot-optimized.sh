#!/bin/bash

# Optimized Screenshot script for Hyprland
# Fast, responsive, with progress indication

# Check if screenshot tools are already running
if pgrep -x "swappy\|slurp\|grim" > /dev/null 2>&1; then
    exit 0
fi

# Get display info for optimization
DISPLAY_INFO=$(hyprctl monitors -j | jq -r '.[0] | "\(.width)x\(.height)"')
SCALE_FACTOR=$(hyprctl monitors -j | jq -r '.[0].scale // 1')

# Create temp directory if not exists
TEMP_DIR="/tmp/screenshots"
mkdir -p "$TEMP_DIR"

# Generate filename with milliseconds for uniqueness
TEMP_FILE="$TEMP_DIR/screenshot_$(date +%Y%m%d_%H%M%S_%3N).png"

# Function to show progress notification
show_progress() {
    notify-send "📸 Screenshot" "Taking screenshot..." -t 1000 -u low --replace-id=12345 &
}

# Function to optimize image for large screenshots
optimize_if_needed() {
    local file="$1"
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    # If file is larger than 2MB, optimize it
    if [ "$size" -gt 2097152 ]; then
        local optimized="${file%.*}_opt.png"
        # Use pngquant for compression if available, otherwise use imagemagick
        if command -v pngquant >/dev/null 2>&1; then
            pngquant --quality=65-80 --output "$optimized" "$file" 2>/dev/null
            if [ -f "$optimized" ]; then
                mv "$optimized" "$file"
            fi
        elif command -v convert >/dev/null 2>&1; then
            convert "$file" -quality 80 -strip "$optimized" 2>/dev/null
            if [ -f "$optimized" ]; then
                mv "$optimized" "$file"
            fi
        fi
    fi
}

# Function to take screenshot
take_screenshot() {
    case "$1" in
        "area")
            # Show progress
            show_progress
            
            # Use slurp with timeout to prevent hanging
            if GEOMETRY=$(timeout 30 slurp 2>/dev/null); then
                # Take screenshot with grim
                grim -g "$GEOMETRY" "$TEMP_FILE"
            else
                notify-send "Screenshot" "Area selection cancelled or timed out" -u normal
                exit 1
            fi
            ;;
        "full")
            show_progress
            grim "$TEMP_FILE"
            ;;
        *)
            echo "Usage: $0 {area|full}"
            exit 1
            ;;
    esac
}

# Function to process screenshot asynchronously
process_screenshot() {
    local file="$1"
    
    # Check if screenshot was taken successfully
    if [ ! -f "$file" ]; then
        notify-send "Screenshot" "Failed to take screenshot" -u critical
        exit 1
    fi
    
    # Optimize large images in background
    optimize_if_needed "$file" &
    
    # Copy to clipboard immediately (without waiting for swappy)
    wl-copy < "$file" &
    
    # Open swappy for editing (non-blocking)
    if command -v swappy >/dev/null 2>&1; then
        # Run swappy in background, don't wait for it
        (
            swappy -f "$file" -o "$file" 2>/dev/null
            # Clean up after swappy closes
            sleep 2
            rm -f "$file"
        ) &
    else
        # If no swappy, just copy and notify
        notify-send "📸 Screenshot" "Screenshot copied to clipboard" -i "$file" -t 3000
        # Clean up after 30 seconds
        (sleep 30 && rm -f "$file") &
    fi
    
    # Immediate feedback
    notify-send "✅ Screenshot Ready" "Copied to clipboard • Opening editor..." -t 2000 -u low
}

# Main execution
take_screenshot "$1"
process_screenshot "$TEMP_FILE"

# Exit immediately, don't wait for background processes
exit 0
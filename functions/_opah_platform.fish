#
# Platform-agnostic utility functions
#
# Provides cross-platform helpers for common operations that differ between
# macOS and Linux. This centralizes platform detection and ensures consistent
# behavior across different operating systems.
#

#
# Get modification time of a file in a human-readable format
#
# Returns the last modification time of a file in a consistent format
# across macOS (BSD stat) and Linux (GNU stat).
#
# @param file_path The path to the file
# @return The modification time string (stdout)
#
function _opah_mtime -d "Get file modification time (cross-platform)"
    set -l file_path $argv[1]
    
    if not test -f "$file_path"
        return 1
    end
    
    switch (uname)
        case Darwin
            stat -f '%Sm' "$file_path"
        case Linux
            # Strip time and timezone; timezone may be +0000 or +00:00 format
            stat -c '%y' "$file_path" | string replace -r ' \d+:\d+:\d+(\.\d+)? [+-]\d+(:\d+)?' ''
        case '*'
            # Fallback: use date command
            date -r "$file_path" 2>/dev/null; or echo "unknown"
    end
end

#
# Get file permissions in octal format
#
# Returns the file permissions in octal format (e.g., "600", "755")
# consistently across macOS and Linux.
#
# @param file_path The path to the file
# @return The permissions in octal format (stdout)
#
function _opah_perms -d "Get file permissions in octal (cross-platform)"
    set -l file_path $argv[1]
    
    if not test -e "$file_path"
        return 1
    end
    
    switch (uname)
        case Darwin
            stat -f '%A' "$file_path"
        case Linux
            stat -c '%a' "$file_path"
        case '*'
            # Fallback: try to parse ls -l output
            echo "unknown"
    end
end

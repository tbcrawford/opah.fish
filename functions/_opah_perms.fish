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
            echo unknown
    end
end

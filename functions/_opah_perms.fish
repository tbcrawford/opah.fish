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
            return 1
    end
end

#
# Return whether a path has no group/other permission bits
#
# @param file_path Path to inspect
# @return 0 if owner-only (e.g. 600, 400, 700), 1 otherwise
#
function _opah_perms_owner_only -d "Return 0 when path permissions are owner-only"
    set -l file_path $argv[1]
    set -l perms (_opah_perms "$file_path")
    if test $status -ne 0
        return 1
    end

    if not string match -qr '^[0-7]+$' -- "$perms"
        return 1
    end

    test (math $perms % 100) -eq 0
end

#
# Return whether a directory has secure cache permissions (700)
#
# @param dir_path Directory path to inspect
# @return 0 if permissions are 700, 1 otherwise
#
function _opah_perms_secure_cache_dir -d "Return 0 when directory permissions are 700"
    set -l dir_path $argv[1]
    set -l perms (_opah_perms "$dir_path")
    if test $status -ne 0
        return 1
    end

    if not string match -qr '^[0-7]+$' -- "$perms"
        return 1
    end

    test "$perms" = 700
end

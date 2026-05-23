#
# Return the numeric owner UID for a path (cross-platform)
#
# @param file_path Path to inspect
# @return Owner UID on stdout, exit 1 if unavailable
#
function _opah_file_owner_uid -d "Get file owner UID"
    set -l file_path $argv[1]

    if not test -e "$file_path"
        return 1
    end

    switch (uname)
        case Darwin
            stat -f '%u' "$file_path"
        case Linux
            stat -c '%u' "$file_path"
        case '*'
            return 1
    end
end

#
# Return whether the current user owns a path
#
# @param file_path Path to inspect
# @return 0 if owned by current user, 1 otherwise
#
function _opah_file_owned_by_user -d "Return 0 if path is owned by the current user"
    set -l file_path $argv[1]
    set -l owner_uid (_opah_file_owner_uid "$file_path" 2>/dev/null)
    if test $status -ne 0
        return 1
    end

    test "$owner_uid" = (id -u)
end

#
# Validate cache directory before writing secrets
#
# @param cache_dir Cache directory path
# @return 0 if safe to write, 1 otherwise
#
function _opah_cache_validate_dir_for_write -d "Validate cache directory is safe for writes"
    set -l cache_dir $argv[1]

    if test -L "$cache_dir"
        echo "Cache directory is a symlink: $cache_dir" >&2
        return 1
    end

    if test -e "$cache_dir"
        if not test -d "$cache_dir"
            echo "Cache path is not a directory: $cache_dir" >&2
            return 1
        end

        if not _opah_file_owned_by_user "$cache_dir"
            echo "Cache directory is not owned by the current user: $cache_dir" >&2
            return 1
        end

        if not _opah_perms_secure_cache_dir "$cache_dir"
            set -l perms (_opah_perms "$cache_dir")
            echo "Cache directory permissions $perms are not secure (expected 700)" >&2
            return 1
        end
    end

    return 0
end

#
# Validate an existing cache file before overwriting it
#
# @param cache_file Cache file path
# @return 0 if safe to overwrite, 1 otherwise
#
function _opah_cache_validate_file_for_write -d "Validate cache file is safe to overwrite"
    set -l cache_file $argv[1]

    if test -L "$cache_file"
        echo "Cache file is a symlink: $cache_file" >&2
        return 1
    end

    if not test -e "$cache_file"
        return 0
    end

    if not test -f "$cache_file"
        echo "Cache path is not a regular file: $cache_file" >&2
        return 1
    end

    if not _opah_file_owned_by_user "$cache_file"
        echo "Cache file is not owned by the current user: $cache_file" >&2
        return 1
    end

    return 0
end

#
# Validate cache file before reading secrets into the environment
#
# @param cache_file Cache file path
# @return 0 if safe to read, 1 otherwise
#
function _opah_cache_validate_file_for_read -d "Validate cache file is safe to read"
    set -l cache_file $argv[1]

    if test -L "$cache_file"
        echo "Cache file is a symlink: $cache_file" >&2
        return 1
    end

    if not test -f "$cache_file"
        echo "Cache file not found: $cache_file" >&2
        return 1
    end

    if not _opah_file_owned_by_user "$cache_file"
        echo "Cache file is not owned by the current user: $cache_file" >&2
        return 1
    end

    set -l perms (_opah_perms "$cache_file")
    if test "$perms" != 600
        echo "Cache file permissions $perms are not secure (expected 600)" >&2
        return 1
    end

    return 0
end

#
# Create the cache directory with secure permissions
#
# @param cache_dir Cache directory path
# @return 0 on success, 1 on error
#
function _opah_cache_prepare_dir -d "Create cache directory with mode 700"
    set -l cache_dir $argv[1]

    if not _opah_cache_validate_dir_for_write "$cache_dir"
        return 1
    end

    if not test -d "$cache_dir"
        mkdir -m 700 -p "$cache_dir"
        if test $status -ne 0
            return 1
        end
    end

    return 0
end

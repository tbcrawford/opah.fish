#
# Return whether a value is a 1Password secret reference
#
# @param value Secret reference string
# @return 0 if value starts with op://, 1 otherwise
#
function _opah_is_op_ref -d "Return 0 if value is a 1Password op:// reference"
    string match -qr '^op://' -- "$argv[1]"
end

#
# Validate configuration file permissions and ownership
#
# @param config_file Path to secrets configuration file
# @return 0 if safe to use, 1 otherwise
#
function _opah_config_validate -d "Validate configuration file security"
    set -l config_file $argv[1]

    if test -z "$config_file"; or not test -f "$config_file"
        echo "Configuration file not found" >&2
        return 1
    end

    if test -L "$config_file"
        echo "Configuration file is a symlink: $config_file" >&2
        return 1
    end

    if not _opah_file_owned_by_user "$config_file"
        echo "Configuration file is not owned by the current user: $config_file" >&2
        return 1
    end

    set -l perms (_opah_perms "$config_file")
    if test "$perms" != 600
        echo "Configuration file permissions $perms are not secure (expected 600)" >&2
        return 1
    end

    return 0
end

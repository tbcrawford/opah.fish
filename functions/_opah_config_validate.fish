source (status dirname)/_opah_perms.fish

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
# Validate configuration file permissions
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

    if not _opah_perms_owner_only "$config_file"
        echo "Configuration file permissions are not secure (expected owner-only, e.g. 600)" >&2
        return 1
    end

    return 0
end

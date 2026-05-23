#
# Check whether an environment variable name is blocked from opah export
#
# Prevents cache poisoning or misconfiguration from overwriting
# security-sensitive variables such as PATH or LD_PRELOAD.
#
# @param key Environment variable name
# @return 0 if blocked, 1 if allowed
#
function _opah_is_blocked_env_key -d "Return 0 if key must not be exported by opah"
    set -l key (string upper -- $argv[1])

    if test -z "$key"
        return 0
    end

    switch $key
        case PATH LD_PRELOAD LD_LIBRARY_PATH DYLD_INSERT_LIBRARIES DYLD_LIBRARY_PATH \
            NODE_OPTIONS NODE_PATH PYTHONPATH FISH_FUNCTION_PATH SHELL BASH_ENV ENV \
            CDPATH IFS GLOBIGNORE PS4
            return 0
    end

    if string match -qr '^(LD_|DYLD_)' -- "$key"
        return 0
    end

    return 1
end

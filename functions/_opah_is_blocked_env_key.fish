#
# Block export of PATH to prevent accidental misconfiguration.
#
# @param key Environment variable name
# @return 0 if blocked, 1 if allowed
#
function _opah_is_blocked_env_key -d "Return 0 if key must not be exported by opah"
    test (string upper -- "$argv[1]") = PATH
end

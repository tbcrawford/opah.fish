#
# Return whether automatic secret loading is enabled
#
# OPAH_AUTOLOAD defaults to 1 (enabled). Set OPAH_AUTOLOAD=0 to disable
# automatic loading in non-interactive Fish shells.
#
# @return 0 if autoload is enabled, 1 if disabled
#
function _opah_autoload_enabled -d "Return 0 when automatic secret loading is enabled"
    if not set -q OPAH_AUTOLOAD
        return 0
    end

    switch "$OPAH_AUTOLOAD"
        case 0 false no off
            return 1
        case '*'
            return 0
    end
end

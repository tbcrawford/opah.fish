#
# UI initialization helper for opah functions
#
# Provides a centralized function to ensure UI utilities are available
# across all opah functions. This standardizes the UI loading pattern
# and eliminates duplication of the initialization code.
#
# @return 0 always succeeds
#

#
# Initialize UI functions for opah commands
#
# Ensures that UI utility functions are loaded and available for use.
# This function should be called at the beginning of any opah function
# that needs to use UI formatting functions.
#
# @return 0 always succeeds
#
function _opah_init_ui -d "Initialize UI functions for opah commands"
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
end
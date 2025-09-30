function _opah_ui -d "UI utilities for consistent formatting and colors"
    # Color and style constants
    set -g __OPAH_COLOR_SUCCESS (set_color green)
    set -g __OPAH_COLOR_ERROR (set_color red) 
    set -g __OPAH_COLOR_WARNING (set_color yellow)
    set -g __OPAH_COLOR_INFO (set_color cyan)
    set -g __OPAH_COLOR_DIM (set_color --dim)
    set -g __OPAH_COLOR_BOLD (set_color --bold)
    set -g __OPAH_COLOR_RESET (set_color normal)
end

# Standard formatting functions
function _opah_success -d "Print success message with green checkmark"
    printf "%s✓%s %s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET "$argv"
end

function _opah_error -d "Print error message with red X"
    printf "%s✗%s %s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET "$argv"
end

function _opah_warning -d "Print warning message with yellow triangle"
    printf "%s⚠%s %s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET "$argv"
end

function _opah_info -d "Print info message with cyan info icon"
    printf "%sℹ%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

function _opah_security -d "Print security message with lock icon"
    printf "%s🔐%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

function _opah_process -d "Print process message with loading icon"
    printf "%s🔄%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

function _opah_file -d "Print file message with folder icon"
    printf "%s📁%s %s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET "$argv"
end

function _opah_diagnostic -d "Print diagnostic message with magnifying glass"
    printf "%s🔍%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

function _opah_hint -d "Print next action hint in dim color"
    printf "\n%sRun '%s' %s%s\n" $__OPAH_COLOR_DIM "$argv[1]" "$argv[2..]" $__OPAH_COLOR_RESET
end

function _opah_section -d "Print section header with separator"
    printf "\n%s📋 %s%s\n" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
end

function _opah_step -d "Print numbered step header"
    printf "\n%s📍 Step %s: %s%s\n" $__OPAH_COLOR_BOLD "$argv[1]" "$argv[2..]" $__OPAH_COLOR_RESET
end

function _opah_dim -d "Print text in dim color"
    printf "%s%s%s" $__OPAH_COLOR_DIM "$argv" $__OPAH_COLOR_RESET
end

function _opah_bold -d "Print text in bold"
    printf "%s%s%s" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
end

# Initialize colors when the function is loaded
_opah_ui
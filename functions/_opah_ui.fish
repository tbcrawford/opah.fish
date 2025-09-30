#
# UI utilities for consistent formatting and colors
#
# Initializes global color constants and provides helper functions for consistent
# terminal output formatting across all opah commands. Defines standard color
# variables and provides utility functions for success, error, warning, info,
# and other specialized message types.
#
# @return 0 always succeeds
#
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
#
# Print success message with green checkmark
#
# Formats and prints a success message with a green checkmark prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_success -d "Print success message with green checkmark"
    printf "%s✓%s %s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET "$argv"
end

#
# Print error message with red X
#
# Formats and prints an error message with a red X prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_error -d "Print error message with red X"
    printf "%s✗%s %s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET "$argv"
end

#
# Print warning message with yellow triangle
#
# Formats and prints a warning message with a yellow warning triangle prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_warning -d "Print warning message with yellow triangle"
    printf "%s⚠%s %s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET "$argv"
end

#
# Print info message with cyan info icon
#
# Formats and prints an informational message with a cyan info icon prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_info -d "Print info message with cyan info icon"
    printf "%sℹ%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

#
# Print security message with lock icon
#
# Formats and prints a security-related message with a lock icon prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_security -d "Print security message with lock icon"
    printf "%s🔐%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

#
# Print process message with loading icon
#
# Formats and prints a process/loading message with a loading icon prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_process -d "Print process message with loading icon"
    printf "%s🔄%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

#
# Print file message with folder icon
#
# Formats and prints a file/folder-related message with a folder icon prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_file -d "Print file message with folder icon"
    printf "%s📁%s %s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET "$argv"
end

#
# Print diagnostic message with magnifying glass
#
# Formats and prints a diagnostic message with a magnifying glass icon prefix.
#
# @param argv The message to print
# @return 0 always succeeds
#
function _opah_diagnostic -d "Print diagnostic message with magnifying glass"
    printf "%s🔍%s %s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv"
end

#
# Print next action hint in dim color
#
# Formats and prints a hint about the next action to take, with the command
# name and description in dim color for subtle guidance.
#
# @param argv[1] The command to suggest running
# @param argv[2..] The description of what the command does
# @return 0 always succeeds
#
function _opah_hint -d "Print next action hint in dim color"
    printf "\n%sRun '%s' %s%s\n" $__OPAH_COLOR_DIM "$argv[1]" "$argv[2..]" $__OPAH_COLOR_RESET
end

#
# Print section header with separator
#
# Formats and prints a section header with a clipboard icon and decorative
# separator line underneath.
#
# @param argv The section title
# @return 0 always succeeds
#
function _opah_section -d "Print section header with separator"
    printf "\n%s📋 %s%s\n" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
end

#
# Print numbered step header
#
# Formats and prints a numbered step header with a location pin icon, useful
# for multi-step processes.
#
# @param argv[1] The step number
# @param argv[2..] The step description
# @return 0 always succeeds
#
function _opah_step -d "Print numbered step header"
    printf "\n%s📍 Step %s: %s%s\n" $__OPAH_COLOR_BOLD "$argv[1]" "$argv[2..]" $__OPAH_COLOR_RESET
end

#
# Print text in dim color
#
# Wraps the provided text in dim color formatting without adding a newline.
#
# @param argv The text to dim
# @return The dimmed text (stdout)
#
function _opah_dim -d "Print text in dim color"
    printf "%s%s%s" $__OPAH_COLOR_DIM "$argv" $__OPAH_COLOR_RESET
end

#
# Print text in bold
#
# Wraps the provided text in bold formatting without adding a newline.
#
# @param argv The text to bold
# @return The bolded text (stdout)
#
function _opah_bold -d "Print text in bold"
    printf "%s%s%s" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
end

# Initialize colors when the function is loaded
_opah_ui
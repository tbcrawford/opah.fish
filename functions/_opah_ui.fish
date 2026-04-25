#
# UI primitives for consistent output formatting.
#
# Defines the Ocean design system: four geometric sigils (● ✕ ▲ ◆),
# section headers, hint lines, and the brand header used only by
# the help screen. All emoji and legacy message types are removed.
#
# Color palette (set_color arguments):
#   brcyan --bold  brand accent, section headers
#   green          success sigil ●
#   red            error sigil ✕
#   yellow         warning sigil ▲
#   brcyan         info sigil ◆
#   normal --dim   detail text, hints, descriptions
#   brcyan --dim   help screen separator rule
#
function _opah_ui -d "Initialize UI color constants"
    set -g __OPAH_COLOR_SUCCESS (set_color green)
    set -g __OPAH_COLOR_ERROR (set_color red)
    set -g __OPAH_COLOR_WARNING (set_color yellow)
    set -g __OPAH_COLOR_INFO (set_color brcyan)
    set -g __OPAH_COLOR_DIM (set_color normal --dim)
    set -g __OPAH_COLOR_BOLD (set_color brcyan --bold)
    set -g __OPAH_COLOR_RESET (set_color normal)
    set -g __OPAH_COLOR_SEP (set_color brcyan --dim)
end

# Print success message with ● sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line (printed indented and dim)
#
function _opah_success -d "Print success: ● msg [detail]"
    printf "%s ● %s%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print error message with ✕ sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_error -d "Print error: ✕ msg [detail]"
    printf "%s ✕ %s%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print warning message with ▲ sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_warning -d "Print warning: ▲ msg [detail]"
    printf "%s ▲ %s%s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print info message with ◆ sigil.
# Also used for: security, process, file, and diagnostic messages (legacy types
# collapsed into this single info primitive).
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_info -d "Print info: ◆ msg [detail]"
    printf "%s ◆ %s%s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print a section header.
#
# Prints a blank line then the title in bold brcyan (title case expected from
# caller). One blank line between sections; none before the first section is
# acceptable as it adds visual breathing room after the shell prompt.
#
# @param argv Section title string (caller provides title case)
#
function _opah_section -d "Print section header: bold cyan title"
    printf "\n%s%s%s\n" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
end

# Print a hint line (actionable suggestion).
#
# Indented 5 spaces (aligns under sigil message text). No sigil. Dim.
#
# @param argv Full hint string, e.g. "run: opah refresh to reload secrets"
#
function _opah_hint -d "Print hint: dim indented suggestion"
    printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv" $__OPAH_COLOR_RESET
end

# Print the brand header and separator rule.
#
# Called ONLY from _opah_show_help. All other subcommands start output
# directly without a title or rule.
#
function _opah_header -d "Print brand header and separator (help screen only)"
    printf "%sopah%s  %s1password secrets manager%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s────────────────────────────%s\n" \
        $__OPAH_COLOR_SEP $__OPAH_COLOR_RESET
end

_opah_ui

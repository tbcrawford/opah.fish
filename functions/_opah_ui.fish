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

    # set_color returns no argv when stdout is not a TTY; keep one empty
    # string per slot so printf format args stay aligned in tests and CI.
    for c in __OPAH_COLOR_SUCCESS __OPAH_COLOR_ERROR __OPAH_COLOR_WARNING \
        __OPAH_COLOR_INFO __OPAH_COLOR_DIM __OPAH_COLOR_BOLD \
        __OPAH_COLOR_RESET __OPAH_COLOR_SEP
        if test (count $$c) -eq 0
            set -g $c ""
        end
    end
end

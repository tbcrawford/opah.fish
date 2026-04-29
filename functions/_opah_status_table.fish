#
# Render secrets status as a Unicode box-drawing table.
#
# Usage: _opah_status_table N key1 ... keyN flag1 ... flagN
#
#   N     – count of secrets
#   keyI  – secret name
#   flagI – 1 if loaded into env, 0 if not
#
# All listed keys are implicitly cached (they came from the cache file).
#
function _opah_status_table -d "Render secrets status as a Unicode box table"
    if not set -q argv[1]
        return 1
    end
    set -l n $argv[1]
    if test $n -eq 0
        return 0
    end

    set -l keys $argv[2..(math $n + 1)]
    set -l flags $argv[(math $n + 2)..-1]

    # ── Secret column width ───────────────────────────────────────────────────
    # Minimum = length of "Secret" (6) so the header always fits.
    set -l max_key_len 6
    for key in $keys
        set -l klen (string length -- $key)
        if test $klen -gt $max_key_len
            set max_key_len $klen
        end
    end

    # Cap total table width to min($COLUMNS, 80).
    # Total table width = secret_col + 24  (borders + two 10-wide status cols)
    set -l term_width 80
    if set -q COLUMNS; and string match -qr '^\d+$' -- "$COLUMNS"
        if test "$COLUMNS" -lt 80
            set term_width $COLUMNS
        end
    end
    set -l max_secret_col (math $term_width - 24)
    if test $max_secret_col -lt 6
        set max_secret_col 6
    end
    if test (math $max_key_len + 2) -gt $max_secret_col
        set max_key_len (math $max_secret_col - 2)
    end

    set -l secret_col (math $max_key_len + 2)
    set -l status_col 10

    # ── Horizontal rule strings ───────────────────────────────────────────────
    set -l h_s (string repeat -n $secret_col ─)
    set -l h_c (string repeat -n $status_col ─)

    # ── Center "Secret" in secret_col ────────────────────────────────────────
    set -l s_pad_total (math $secret_col - 6)
    set -l s_pad_l (math "floor($s_pad_total / 2)")
    set -l s_pad_r (math $s_pad_total - $s_pad_l)
    set -l hdr_secret (printf "%*s%s%*s" $s_pad_l "" Secret $s_pad_r "")

    # ── Sigil padding: 1 char centered in status_col-wide cell ───────────────
    set -l sig_pad (math "floor(($status_col - 1) / 2)")
    set -l sig_l (string repeat -n $sig_pad " ")
    set -l sig_r (string repeat -n (math $status_col - 1 - $sig_pad) " ")

    # ── Top border ────────────────────────────────────────────────────────────
    printf "%s┌%s┬%s┬%s┐%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET

    # ── Header row ────────────────────────────────────────────────────────────
    printf "%s│%s%s%s│%s  Cached  %s│%s  Loaded  %s│%s\n" \
        $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $hdr_secret $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET

    # ── Header separator ──────────────────────────────────────────────────────
    printf "%s├%s┼%s┼%s┤%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET

    # ── Data rows ─────────────────────────────────────────────────────────────
    for i in (seq 1 $n)
        set -l key $keys[$i]
        set -l is_loaded $flags[$i]

        # Truncate key if it exceeds max_key_len
        if test (string length -- $key) -gt $max_key_len
            set key (string sub -l (math $max_key_len - 1) -- $key)…
        end

        # Left-align key padded to max_key_len with one space on each side
        set -l padded (printf " %-*s " $max_key_len "$key")

        # Cached is always ✓ — keys listed here came from the cache file
        set -l cached_sig "$__OPAH_COLOR_SUCCESS✓$__OPAH_COLOR_RESET"
        set -l loaded_sig
        if test "$is_loaded" = 1
            set loaded_sig "$__OPAH_COLOR_SUCCESS✓$__OPAH_COLOR_RESET"
        else
            set loaded_sig "$__OPAH_COLOR_ERROR✕$__OPAH_COLOR_RESET"
        end

        printf "%s│%s%s%s│%s%s%s%s%s│%s%s%s%s%s│%s\n" \
            $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $padded $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $sig_l $cached_sig $sig_r $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $sig_l $loaded_sig $sig_r $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET
    end

    # ── Bottom border ─────────────────────────────────────────────────────────
    printf "%s└%s┴%s┴%s┘%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET
end

" This is a replacement for syntax/syncolor.vim that removes all default
" coloring.

if !exists("g:cscheck_syncolor_log")
    let g:cscheck_syncolor_log = []
endif

if exists("syntax_cmd")
    call add(g:cscheck_syncolor_log, [syntax_cmd, &background])

    if syntax_cmd == "skip"
        finish
    endif
else
    call add(g:cscheck_syncolor_log, ["hl_init", &background])
endif

call cscheck#ClearHighlights()

let syntax_cmd = "skip"

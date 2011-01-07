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

" Stuff from syntax.c that can't be otherwise ovirridden
highlight clear ColorColumn
highlight clear Conceal
highlight clear Cursor
highlight clear CursorColumn
highlight clear CursorLine
highlight clear DiffAdd
highlight clear DiffChange
highlight clear DiffDelete
highlight clear DiffText
highlight clear Directory
highlight clear ErrorMsg
highlight clear FoldColumn
highlight clear Folded
highlight clear IncSearch
highlight clear LineNr
highlight clear MatchParen
highlight clear ModeMsg
highlight clear MoreMsg
highlight clear NonText
highlight clear Normal
highlight clear Pmenu
highlight clear PmenuSbar
highlight clear PmenuSel
highlight clear PmenuThumb
highlight clear Question
highlight clear Search
highlight clear SignColumn
highlight clear SpecialKey
highlight clear SpellBad
highlight clear SpellCap
highlight clear SpellLocal
highlight clear SpellRare
highlight clear StatusLine
highlight clear StatusLineNC
highlight clear TabLine
highlight clear TabLineFill
highlight clear TabLineSel
highlight clear Title
highlight clear VertSplit
highlight clear Visual
highlight clear VisualNOS
highlight clear WarningMsg
highlight clear WildMenu
highlight clear lCursor

let syntax_cmd = "skip"

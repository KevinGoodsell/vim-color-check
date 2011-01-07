" Possible checks:
" * Groups with a link and colors
" * Group name typos
"   - Maybe create a list of all highlight groups that are set, report any
"     "unknown" groups.
" * Missing
"   - highlight clear
"   - syntax reset
" * 'background' doesn't match real background color (ekvoli)

" NOTES:
" * What's the "best" preamble for colorschemes? Something like:
"   set background=...
"   highlight clear
"   if exists("syntax_on")
"       syntax reset
"   endif

let s:runtime_dir = expand("<sfile>:h:h:p")

function! g:CheckColorScheme(name) abort
    call s:ColorSchemeFileChecks(a:name)
    call s:ColorSchemeResultChecks(a:name)
endfunction

function! s:Log(level, msg) abort
    echomsg printf("%s: %s", a:level, a:msg)
endfunction

function! s:ColorSchemeFileChecks(name) abort
    let path = globpath(&runtimepath, printf("colors/%s.vim", a:name), 1)
    let path = substitute(path, '\v\n.*$', "", "")
    if empty(path)
        call s:Log("ERROR", "can't find colorscheme file")
        return
    else
        call s:Log("INFO", printf("using file %s", path))
    endif

    let linenr = 0
    for line in readfile(path)
        let linenr += 1

        if line =~ '\v^\s*"'
            continue
        endif

        if line =~ '\v<au%[tocmd]>'
            call s:Log("WARNING",
                \ printf("possible autocmd at line %d", linenr))
        endif

        " If changing a setting, but not background
        if line =~ '\v<(se%[t]\s+|let\s+\&)((background|bg)>)@!'
            call s:Log("WARNING",
                \ printf("possible setting change at line %d", linenr))
        endif

        if line =~ '\v<[nvxsoilc]?(nore)?map>'
            call s:Log("WARNING",
                \ printf("possible mapping at line %d", linenr))
        endif
    endfor
endfunction

function! s:ColorSchemeResultChecks(name) abort
    let saved_background = &background
    let saved_colors_name = g:colors_name

    " Initial tests

    exec "colorscheme " . a:name

    if !exists("g:colors_name")
        call s:Log("ERROR", "colors_name doesn't exist!")
    elseif g:colors_name != a:name
        call s:Log("ERROR", printf("colors_name (%s) doesn't match " .
                                 \ "colorscheme file name", g:colors_name))
    endif

    call s:SpellCheckGroups()

    let normal_links = s:GetLinks()

    " Light background and link tests

    set background=light

    " Re-load colorscheme without default colors and check for new links. A
    " common mistake is to attempt to link groups that have default colors,
    " which silently fails.
    let light_log = s:LoadWithoutDefaults(a:name)
    let bg_after_light = &background

    " Check links
    let new_links = s:GetLinks()

    for link in new_links
        if index(normal_links, link) < 0
            call s:Log("WARNING", printf("link might need !: %s", link[0]))
        endif
    endfor

    " Dark background tests

    set background=dark
    let dark_log = s:LoadWithoutDefaults(a:name)
    let bg_after_dark = &background

    if bg_after_dark == "dark" && bg_after_light == "light"
        call s:Log("WARNING", "colorscheme didn't set 'background'")
    elseif bg_after_dark == bg_after_light
        call s:Log("INFO", printf("colorscheme uses %s background",
            \ bg_after_dark))

        " But was background set before the first "hi clear" and/or "syntax
        " reset"?
        if empty(dark_log) || empty(light_log)
            call s:Log("WARNING", "didn't reset colors")
        elseif dark_log[0][1] != light_log[0][1]
            call s:Log("WARNING", "colorscheme changed 'background' after " .
                                \ "setting color defaults")
        endif
    else
        call s:Log("WARNING", "colorscheme inverts 'background' (weird)")
    endif

    let &background = saved_background
    exec "colorscheme " . saved_colors_name
endfunction

" Returns the log of calls to syncolor.vim
function! s:LoadWithoutDefaults(colorscheme) abort
    call s:ClearHighlights()

    let saved_runtimepath = &runtimepath
    let &runtimepath = s:runtime_dir . "/cscheck_runtime," . &runtimepath

    let g:cscheck_syncolor_log = []
    exec "colorscheme " . a:colorscheme

    let &runtimepath = saved_runtimepath

    return copy(g:cscheck_syncolor_log)
endfunction

function! s:ClearHighlights() abort
    for group in s:GetGroups(0)
        exec printf("highlight clear %s|highlight link %s NONE",
                  \ group, group)
    endfor
endfunction

function! s:GetHighlights(with_cleared) abort
    redir => hltext
    silent highlight
    redir END

    let hltext = substitute(hltext, '\v\n\s+', " ", "g")
    if !a:with_cleared
        let hltext = substitute(hltext, '\v\w+\s+xxx cleared($|\n)',
                              \ "", "g")
    endif
    return split(hltext, "\n")
endfunction

function! s:GetLinks() abort
    let lines = s:GetHighlights(0)

    let link_pattern = '\v^(\w+)\s.*<links to\s*(\w+)'
    call filter(lines, "v:val =~ link_pattern")

    return map(lines, "matchlist(v:val, link_pattern)[1:2]")
endfunction

function! s:GetGroups(with_cleared) abort
    let lines = s:GetHighlights(a:with_cleared)

    let group_pattern = '\v^\w+\ze'
    return map(lines, "matchstr(v:val, group_pattern)")
endfunction

function! s:SpellCheckGroups() abort
    if !exists("s:lower_group_names")
        let s:lower_group_names = {}
        for group in s:group_names
            let s:lower_group_names[tolower(group)] = 1
        endfor
    endif

    let unknown_groups = []

    for group in s:GetGroups(0)
        if has_key(s:lower_group_names, tolower(group))
            continue
        endif

        let suggestion = s:SpellCheckGroup(group)
        if !empty(suggestion)
            call s:Log("WARNING", printf("possible typo: %s (did you mean %s?)",
                \ group, suggestion))
        endif

        call add(unknown_groups, group)
    endfor

    if !empty(unknown_groups)
        call s:Log("INFO", printf("unknown highlight groups: %s",
            \ string(unknown_groups)))
    endif
endfunction

function! s:SpellCheckGroup(name) abort
    if !exists("s:group_typos")
        let s:group_typos = {}
        for group in s:group_names
            call extend(s:group_typos, s:GetSpellingVariants(group))
        endfor
    endif

    let variants = s:GetSpellingVariants(a:name)

    for variant in keys(variants)
        if has_key(s:group_typos, variant)
            return s:group_typos[variant]
        endif
    endfor

    return ""
endfunction

function! s:GetSpellingVariants(word) abort
    let variants = s:GetVariantsHelper(tolower(a:word), a:word)

    for variant in keys(variants)
        call extend(variants, s:GetVariantsHelper(variant, a:word))
    endfor

    return variants
endfunction

function! s:GetVariantsHelper(word, value) abort
    let result = {}

    for i in range(strlen(a:word))
        let front = strpart(a:word, 0, i)
        let back = a:word[i :]
        let deleted = front . back[1:]
        let replaced = front . "*" . back[1:]
        let inserted = front . "*" . back

        if !empty(deleted)
            let result[deleted] = a:value
        endif
        let result[replaced] = a:value
        let result[inserted] = a:value
    endfor

    " One insertion missed.
    let result[a:word . "*"] = a:value

    return result
endfunction

let s:group_names = [
    \ "Comment",
    \ "Constant",
    \ "Special",
    \ "Identifier",
    \ "Statement",
    \ "PreProc",
    \ "Type",
    \ "Underlined",
    \ "Ignore",
    \ "Error",
    \ "Todo",
    \ "String",
    \ "Character",
    \ "Number",
    \ "Boolean",
    \ "Float",
    \ "Function",
    \ "Conditional",
    \ "Repeat",
    \ "Label",
    \ "Operator",
    \ "Keyword",
    \ "Exception",
    \ "Include",
    \ "Define",
    \ "Macro",
    \ "PreCondit",
    \ "StorageClass",
    \ "Structure",
    \ "Typedef",
    \ "Tag",
    \ "SpecialChar",
    \ "Delimiter",
    \ "SpecialComment",
    \ "Debug",
    \ "ColorColumn",
    \ "Conceal",
    \ "Cursor",
    \ "CursorIM",
    \ "CursorColumn",
    \ "CursorLine",
    \ "DiffAdd",
    \ "DiffChange",
    \ "DiffDelete",
    \ "DiffText",
    \ "Directory",
    \ "ErrorMsg",
    \ "FoldColumn",
    \ "Folded",
    \ "IncSearch",
    \ "LineNr",
    \ "MatchParen",
    \ "ModeMsg",
    \ "MoreMsg",
    \ "NonText",
    \ "Normal",
    \ "Pmenu",
    \ "PmenuSbar",
    \ "PmenuSel",
    \ "PmenuThumb",
    \ "Question",
    \ "Search",
    \ "SignColumn",
    \ "SpecialKey",
    \ "SpellBad",
    \ "SpellCap",
    \ "SpellLocal",
    \ "SpellRare",
    \ "StatusLine",
    \ "StatusLineNC",
    \ "TabLine",
    \ "TabLineFill",
    \ "TabLineSel",
    \ "Title",
    \ "VertSplit",
    \ "Visual",
    \ "VisualNOS",
    \ "WarningMsg",
    \ "WildMenu",
    \ "lCursor",
    \ "User1",
    \ "User2",
    \ "User3",
    \ "User4",
    \ "User5",
    \ "User6",
    \ "User7",
    \ "User8",
    \ "User9",
    \ "Menu",
    \ "Scrollbar",
    \ "Tooltip",
\ ]

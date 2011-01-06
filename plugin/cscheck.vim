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

function! s:Log(level, msg)
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
    let saved_runtimepath = &runtimepath

    exec "colorscheme " . a:name

    if !exists("g:colors_name")
        call s:Log("ERROR", "colors_name doesn't exist!")
    elseif g:colors_name != a:name
        call s:Log("ERROR", "colors_name doesn't match colorscheme file name")
    endif

    let normal_links = s:GetLinks()

    " Light background and link tests

    set background=light
    let g:cscheck_syncolor_log = []

    " Re-load colorscheme without default colors and check for new links. A
    " common mistake is to attempt to link groups that have default colors,
    " which silently fails.
    let &runtimepath = s:runtime_dir . "/cscheck_runtime," . &runtimepath
    exec "colorscheme " . a:name

    let light_log = g:cscheck_syncolor_log
    let bg_after_light = &background
    let g:cscheck_syncolor_log = []

    " Check links
    let new_links = s:GetLinks()

    for link in new_links
        if index(normal_links, link) < 0
            call s:Log("WARNING", printf("link might need !: %s", link[0]))
        endif
    endfor

    " Dark background tests

    set background=dark

    let &runtimepath = s:runtime_dir . "/cscheck_runtime," . &runtimepath
    exec "colorscheme " . a:name
    let &runtimepath = saved_runtimepath

    let dark_log = copy(g:cscheck_syncolor_log)
    let g:cscheck_syncolor_log = []
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

function! s:GetHighlights()
    redir => hltext
    silent highlight
    redir END

    let hltext = substitute(hltext, '\v\n\s+', " ", "g")
    return split(hltext, "\n")
endfunction

function! s:GetLinks()
    let lines = s:GetHighlights()

    let link_pattern = '\v^(\w+)\s.*<links to\s*(\w+)'
    call filter(lines, "v:val =~ link_pattern")

    return map(lines, "matchlist(v:val, link_pattern)[1:2]")
endfunction

" {{{ COPYRIGHT & LICENSE
"
" Copyright 2011 Kevin Goodsell
"
" This file is part of Vim Color Check.
"
" Vim Color Check is free software: you can redistribute it and/or modify it
" under the terms of the GNU General Public License as published by the Free
" Software Foundation, either version 3 of the License, or (at your option)
" any later version.
"
" Vim Color Check is distributed in the hope that it will be useful, but
" WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
" or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
" more details.
"
" You should have received a copy of the GNU General Public License along with
" Vim Color Check.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" This is a replacement for syntax/syncolor.vim that removes all default
" coloring.

if !exists("g:colorcheck_syncolor_log")
    let g:colorcheck_syncolor_log = []
endif

if exists("syntax_cmd")
    call add(g:colorcheck_syncolor_log, [syntax_cmd, &background])

    if syntax_cmd == "skip"
        finish
    endif
else
    call add(g:colorcheck_syncolor_log, ["hl_init", &background])
endif

call colorcheck#ClearHighlights()

let syntax_cmd = "skip"

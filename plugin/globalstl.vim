if get(g:, 'global_stl_loaded', 0) == 1
    finish
endif

let g:global_stl_loaded = 1

let g:stl_nonbtbg = 'folded'
let g:stl_bg = 'FoldColumn'

let g:saved_fillchars = &fillchars
if g:saved_fillchars[-1:-1] != ','
    let g:saved_fillchars .= ','
endif

set laststatus=2
call stl#init()

function! s:modestr()
    let m = mode()
    if m == 'n'
        call stl#setVirtualStl(0, ' NORMAL ', 'StatusLineTerm', 'mode')
    elseif m == 'i'
        call stl#setVirtualStl(0, ' INSERT ', 'SpellRare', 'mode')
    elseif m == 'v'
        call stl#setVirtualStl(0, ' VISUAL ', 'SpellCap', 'mode')
    elseif m == 'V'
        call stl#setVirtualStl(0, ' V-LINE ', 'Visual', 'mode')
    elseif m == '^V'
        call stl#setVirtualStl(0, ' V-BLOCK ', 'CurSearch', 'mode')
    endif
    call stl#setStl()
endfunction

function! s:fnstr()
    let fn = bufname()
    call stl#setVirtualStl(10, 'filename: '.fn, '', 'filename')
    call stl#setStl()
endfunction

function! s:bufstr()
    let bufstr = bufferline#get_echo_string()
    call stl#setVirtualStl(10, bufstr, '', 'bufstr')
    call stl#setStl()
endfunction

function! s:lncol()
    let col = virtcol(".")
    let ln = line('.')
    call stl#setVirtualStl(float2nr(&co * 0.9), ln.':'.col, '', 'linenr')
    call stl#setStl()
endfunction

augroup GlobalStl
    autocmd!
    autocmd ModeChanged * call s:modestr()
    autocmd BufEnter,BufDelete,BufWrite  * call s:bufstr()
    autocmd CursorMoved * call s:lncol()
augroup END


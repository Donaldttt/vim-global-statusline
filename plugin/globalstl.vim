
let g:global_stl = 1
if get(g:, 'global_stl', 0) == 0
    finish
endif

let g:global_stl = 1




set laststatus=2
call stl#init()


function! s:modestr()
    let m = mode()
    if m == 'n'
        call stl#setVirtualStl(0, '[NORMAL]', 'StatusLineTerm', 'mode')
    elseif m == 'i'
        call stl#setVirtualStl(0, '[INSERT]', 'SpellRare', 'mode')
    elseif m == 'v'
        call stl#setVirtualStl(0, '[VISUAL]', 'SpellCap', 'mode')
    elseif m == 'V'
        call stl#setVirtualStl(0, '[V-LINE]', 'Visual', 'mode')
    elseif m == '^V'
        call stl#setVirtualStl(0, '[V-BLOCK]', 'CurSearch', 'mode')
    endif
    call stl#setStl()
endfunction

function! s:fnstr()
    let fn = bufname()
    call stl#setVirtualStl(30, 'filename: '.fn, 'IncSearch', 'filename')
    call stl#setStl()
endfunction

        " call stl#setVirtualStl(20, '[V-BLOCK][V-BLOCK][V-BLOCK][V-BLOCK][V-BLOCK][V-BLOCK]', 'CurSearch', 'mode')

augroup GlobalStl
    autocmd!
    autocmd ModeChanged * call s:modestr()
    autocmd BufEnter * call s:fnstr()
augroup END

" call stl#setVirtualStl(0, 1, '[]', 'SpellBad')
" call stl#setVirtualStl(60, 61, 'mode 2', 'IncSearch')



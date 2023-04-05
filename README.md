# vim-global-statusline

A plugin implements a global statusline(like the one in neovim) in vim.

(needs vim9 with patch 9.0.0036 to work perfectly, check using `:echo has('patch36')`. For other vim version the characters at win split positions on statusline will be blocked)

## Options

```vim
" highlight of horizontal window split
let g:stl_nonbtbg = 'folded'

" default global statusline backgroud
let g:stl_bg = 'FoldColumn'

```

## Usage

To add extensions to status line, you need to call `StlSetPart(start_column, content, highlight, extension_name)`,
`extension_name` are used to identify the extensions internaly. And then call `StlRefresh()` to update statusline.

Currently this function only accept raw string as content.

you can use autocmd to update the content of statusline in real time.

```vim
" a simple extension display the buffer name of current buffer
function! s:fnstr()
    call StlSetPart(10, 'filename: '.bufname(), '', 'filename')
    call StlRefresh()
endfunction


" extension that adds mode information"
function! s:modestr()
    let m = mode()
    if m == 'n'
        call StlSetPart(0, ' NORMAL ', 'StatusLineTerm', 'mode')
    elseif m == 'i'
        call StlSetPart(0, ' INSERT ', 'SpellRare', 'mode')
    elseif m == 'v'
        call StlSetPart(0, ' VISUAL ', 'SpellCap', 'mode')
    elseif m == 'V'
        call StlSetPart(0, ' V-LINE ', 'Visual', 'mode')
    elseif m == '^V'
        call StlSetPart(0, ' V-BLOCK ', 'CurSearch', 'mode')
    endif
    call StlRefresh()
endfunction

" extension adds line column information
function! s:lncol()
    let col = virtcol(".")
    let ln = line('.')
    call StlSetPart(float2nr(&co * 0.9), ln.':'.col, '', 'linenr')
    call StlRefresh()
endfunction

augroup GlobalStl
    autocmd!
    autocmd VimEnter,ModeChanged * call s:modestr()
    autocmd BufEnter * call s:fnstr()
    autocmd CursorHold * call s:lncol()
augroup END
```

## Demo

[demo](resources/gloablstl_demo.gif)

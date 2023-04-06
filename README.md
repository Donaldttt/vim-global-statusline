# vim-global-statusline

A plugin implements a global statusline(like the one in neovim) in vim.

(needs vim9 with patch 9.0.0036 to work perfectly, check using `:echo has('patch36')`. For other vim version the characters at win split positions on statusline will be blocked)
## Install

Using any plugin manager 

```vim
" for vim-plug
Plug 'Donaldttt/vim-global-statusline'
```

or put it in vim's run time path.

## Options

```vim
" highlight of horizontal window split
let g:stl_nonbtbg = 'folded'

" default global statusline backgroud
let g:stl_bg = 'FoldColumn'

```

## Usage

To add extensions to status line, you need to call `g:StlSetPart(start_column, content, highlight, extension_name)`,
`extension_name` are used to identify the extensions internaly. And then call `g:StlRefresh()` to update statusline.

Currently this function only accept raw string as content.

you can use autocmd to update the content of statusline in real time.

```vim
" a simple extension display the buffer name of current buffer
function! s:fnstr()
    call g:StlSetPart(10, 'filename: '.bufname(), '', 'filename')
    call g:StlRefresh()
endfunction


" extension that adds mode information"
function! s:modestr()
    let m = mode()
    if m == 'n'
        call g:StlSetPart(0, ' NORMAL ', 'StatusLineTerm', 'mode')
    elseif m == 'i'
        call g:StlSetPart(0, ' INSERT ', 'SpellRare', 'mode')
    elseif m == 'v'
        call g:StlSetPart(0, ' VISUAL ', 'SpellCap', 'mode')
    elseif m == 'V'
        call g:StlSetPart(0, ' V-LINE ', 'Visual', 'mode')
    elseif m == '^V'
        call g:StlSetPart(0, ' V-BLOCK ', 'CurSearch', 'mode')
    endif
    call g:StlRefresh()
endfunction

" extension adds line column information
function! s:lncol()
    let col = virtcol(".")
    let ln = line('.')
    call g:StlSetPart(float2nr(&co * 0.9), ln.':'.col, '', 'linenr')
    call g:StlRefresh()
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

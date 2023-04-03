# vim-globalstl

A plugin implements a global statusline(like the one in neovim) in vim.

## Options

```vim
" highlight of horizontal window split
let g:stl_nonbtbg = 'folded'

" default global statusline backgroud
let g:stl_bg = 'FoldColumn'

```

## Usage

To add extensions to status line, you need to call `stl#setVirtualStl(start_column, content, highlight, extension_name)`,
`extension_name` are used to identify the extensions internaly. And then call `stl#setStl()` to update statusline.

Currently this function only accept raw string as content.

you can use autocmd to update the content of statusline in real time.

```vim
" a simple extension display the buffer name of current buffer
function! s:fnstr()
    call stl#setVirtualStl(10, 'filename: '.bufname(), '', 'filename')
    call stl#setStl()
endfunction

augroup GlobalStl
    autocmd!
    autocmd BufEnter * call s:fnstr()
augroup END
```

## Demo

[demo](resources/gloablstl_demo.gif)

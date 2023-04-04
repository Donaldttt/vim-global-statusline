vim9script

if get(g:, 'global_stl_loaded', 0) == 1
    finish
endif

set laststatus=2

g:global_stl_loaded = 1
g:stl_nonbtbg = get(g:, 'stl_nonbtbg', 'folded')
g:stl_bg = get(g:, 'stl_bg', 'folded')

g:saved_fillchars = &fillchars
if g:saved_fillchars[-1 : -1] != ','
    g:saved_fillchars .= ','
endif

import autoload 'stl9.vim'

g:StlSetPart = stl9.SetVirtualStl
g:StlRefresh = stl9.SetStl

augroup globalstl
    autocmd!
    autocmd WinEnter,WinNew * call stl9.SetStl()
    if exists('##winresized')
        autocmd WinResized * call stl9.SetStl()
    endif
augroup END




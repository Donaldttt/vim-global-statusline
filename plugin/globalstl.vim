if get(g:, 'global_stl_loaded', 0) == 1
    finish
endif

let g:global_stl_loaded = 1

let g:stl_nonbtbg = get(g:, 'stl_nonbtbg', 'folded')
let g:stl_bg = get(g:, 'stl_bg', 'folded')

let g:saved_fillchars = &fillchars
if g:saved_fillchars[-1:-1] != ','
    let g:saved_fillchars .= ','
endif

set laststatus=2

call stl#init()

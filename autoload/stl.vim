
function! stl#setStl()
    " call SetStl()
    call g:stl_funcs['SetStl']()
endfunction


function! stl#setVirtualStl(start, content, highlight, id)
    call g:stl_funcs['SetVirtualStl'](a:start, a:content, a:highlight, a:id)
endfunction


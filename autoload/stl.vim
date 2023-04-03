
let s:virtualstl = {}
let s:virtualstl_list = []
let s:curwins = []
let s:winstls = {}
let s:activewin = 0
let s:bg = g:stl_bg
let s:nonbottom = []
let s:nonbtbg = g:stl_nonbtbg

" get winid of windows at the bottom of the screen
function! stl#getStlInfo()
    let layout = winlayout()

    let s:nonbombom = []
    function! s:nonbomhelper(li)
        if a:li[0] == 'leaf'
            call add(s:nonbombom, a:li[1])
        elseif a:li[0] == 'col'
            for w in a:li[1]
                call s:nonbomhelper(w)
            endfor
        elseif a:li[0] == 'row'
            for w in a:li[1]
                call s:nonbomhelper(w)
            endfor
        end
    endfunction

    function! s:healper(li)
        let ret = []
        if a:li[0] == 'leaf'
            return [a:li[1]]
        elseif a:li[0] == 'col'
            for w in a:li[1][0:-2]
                call s:nonbomhelper(w)
            endfor
            let last = a:li[1][-1]
            let ret = s:healper(last)
        elseif a:li[0] == 'row'
            for w in a:li[1]
                let ret += s:healper(w)
            endfor
        end
        return ret
    endfunction
    let left2right = s:healper(layout)

    let retobjs = []
    let start = 0

    let idx = 0
    for w in left2right
        let obj = {}
        let obj['winid'] = w
        let obj['width'] = winwidth(w)
        " let obj['start'] = idx > 0 ? start - 1 : start
        let obj['start'] = start
        let start += obj['width'] + 1
        let retobjs += [obj]
        let idx += 1
    endfor
    return [retobjs, s:nonbombom]
endfunction
function! stl#clearVirtualStl()
    let s:virtualstl = []
endfunction

function! s:sorter(a, b)
    if a:a['start'] < a:b['start']
        return -1
    elseif a:a['start'] > a:b['start']
        return 1
    else
        return 0
    endif
endfunction

function! stl#setVirtualStl(start, content, highlight, id)
    let obj = {}
    let obj['start'] = a:start
    let obj['content'] = a:content
    let obj['hi'] = a:highlight
    let s:virtualstl[a:id] = obj

    let s:virtualstl_list = []
    for [k, v] in items(s:virtualstl)
        let s:virtualstl_list += [v]
    endfor
    call sort(s:virtualstl_list, 's:sorter')
endfunction

function! s:addToWinStl(start, content, hi)
    let hi = a:hi != '' ? '%#'.a:hi.'#' : ''
    let bg = '%#'.s:bg.'#'
    for w in s:curwins

        let winend = w['start'] + w['width']
        if w['start'] <= a:start && a:start <= winend

            let used = s:winstls[w['winid']]['used']

            let width = strcharlen(a:content)
            if a:start + width <= winend

                let padstr = [hi, a:content]
                let pad = a:start - (w['start'] + used) > 0 ? a:start - (w['start'] + used) : 0
                if pad > 0
                    let padstr = [bg, repeat(' ', pad)] + padstr
                endif

                let overlap = (w['start'] + used) - a:start
                while overlap > 0
                " overlapping

                    let last = remove(s:winstls[w['winid']]['content'], -1)

                    let l = strcharlen(last)
                    if l > 2 && last[0:1] != '%#' && l >= overlap
                        let last = strcharpart(last, 0, l - overlap)
                        call add(s:winstls[w['winid']]['content'], last)
                        let s:winstls[w['winid']]['used'] -= overlap
                        break
                    else
                        if l > 2 && last[0:1] == '%#'
                            continue
                        else
                            let overlap -= l 
                        endif
                    endif
                endwhile

                let s:winstls[w['winid']]['content'] += padstr

                let s:winstls[w['winid']]['used'] += strcharlen(a:content) + pad

            else

                " need to split
                " let first = a:content[0:winend - a:start - 1]
                " let special = a:content[winend - a:start]
                " let second = a:content[winend - a:start + 1:]
                let first = strcharpart(a:content, 0, winend - a:start)
                let special = strcharpart(a:content, winend - a:start, 1)
                let second = strcharpart(a:content, winend - a:start + 1)

                let s:winstls[w['winid']]['special'] = special
                let s:winstls[w['winid']]['specialhi'] = a:hi != '' ? a:hi : ''

                call s:addToWinStl(a:start, first, a:hi)

                call s:addToWinStl(winend + 1, second, a:hi)
            endif
            break
        endif
    endfor

endfunction

function! s:getHiTerm(group)
  let output = execute('hi ' . a:group)
  let list = split(output, '\s\+')
  let dict = {}
  for item in list
    if match(item, '=') > 0
      let splited = split(item, '=')
      let dict[splited[0]] = splited[1]
    endif
  endfor
  return dict
endfunction

function! s:applyStls()
    let hi = s:getHiTerm(s:bg)

    let cterm = has_key(hi, 'cterm') != '' ? hi['cterm'] : 'NONE'

    if hi['guibg'] != '' && has('termguicolors')
        " ctermbg of these two are set differently to avoid fillchars, same
        " for bleow
        let guifg = has_key(hi, 'guifg') != '' ? hi['guifg'] : 'NONE'
        exe 'hi! Statusline guibg='.hi['guibg'].' ctermbg=33 guifg='.guifg.' cterm='.cterm
        exe 'hi! StatuslineNC guibg='.hi['guibg'].' ctermbg=44 guifg='.guifg.' cterm='.cterm
    elseif hi['ctermbg'] != ''
        let ctermfg = has_key(hi, 'ctermfg') != '' ? hi['ctermfg'] : 'NONE'
        exe 'hi! Statusline guibg=#ffffff ctermbg='.hi['ctermbg'].' ctermfg='.ctermfg.' cterm='.cterm
        exe 'hi! StatuslineNC guibg=#111111 ctermbg='.hi['ctermbg'].' ctermfg='.ctermfg.' cterm='.cterm
    endif

    for [wid, v] in items(s:winstls)
        let content = v['content']
        let used = v['used']
        let width = v['width']
        let special = v['special']
        let specialhi = v['specialhi']
        let bgstr = '%#'.s:bg.'#'
        let stl = bgstr.join(content, '').bgstr

        if special != ''
            if wid == s:activewin
                call setwinvar(wid, '&fillchars', g:saved_fillchars.'stl:' . special)
                if specialhi != ''
                    exe 'hi! link Statusline '.specialhi
                endif
            else
                call setwinvar(wid, '&fillchars', g:saved_fillchars.'stlnc:' . special)
                if specialhi != ''
                    exe 'hi! link StatuslineNC '.specialhi
                endif
            endif
        else
            call setwinvar(wid, '&fillchars', g:saved_fillchars.'stlnc: ,stl: ,')
        endif

        if used < width
            " let stl .= s:bg.repeat(' ', width - used)
        endif
        call setwinvar(wid, '&stl', stl)
    endfor
endfunction

function! stl#getVirtualStl()
    return s:virtualstl
endfunction

function! stl#getVirtualStlLi()
    return s:virtualstl_list
endfunction

function! stl#getWinStl()
    return s:winstls
endfunction

function! stl#init()
    augroup globalstl
        autocmd!
        autocmd WinEnter,WinResized,WinNew * call stl#setStl()
    augroup END
endfunction

" clear stl of other windows
function! s:clearNonBottom()
    let bg2 = '%#'.s:nonbtbg.'#'
    for wid in s:nonbottom
        " to avoid fillchars
        call setwinvar(wid, '&stl', bg2.repeat(' ', winwidth(wid)))
    endfor
endfunction

function! stl#getNonbot()
    return s:nonbottom
endfunction
function! stl#setStl()

    let s:activewin = win_getid()
    let pos = 0
    let li = stl#getStlInfo()
    let s:curwins = li[0]
    let s:nonbottom = li[1]
    let s:winstls = {}
    for w in s:curwins
        let s:winstls[w['winid']] = {
            \ 'content': [],
            \ 'used': 0,
            \ 'width': w['width'],
            \ 'special': '',
            \ 'specialhi': '',
        \ }
    endfor
    for obj in s:virtualstl_list
        call s:addToWinStl(obj['start'], obj['content'], obj['hi'])
    endfor
    call s:applyStls()
    call s:clearNonBottom()
endfunction


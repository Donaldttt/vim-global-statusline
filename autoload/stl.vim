
let s:virtualstl = {}
let s:virtualstl_list = []
let s:curwins = []
let s:winstls = {}
let s:activewin = 0
let s:bg = 'IncSearch'
let s:nonbottom = []

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
    for w in left2right
        let obj = {}
        let obj['winid'] = w
        let obj['width'] = winwidth(w)
        let obj['start'] = start
        let start += obj['width'] + 1
        let retobjs += [obj]
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
    let width = len(a:content)
    let hi = a:hi != '' ? '%#'.a:hi.'#' : ''
    let bg = '%#'.s:bg.'#'
    for w in s:curwins

        let winend = w['start'] + w['width']
        if w['start'] <= a:start && a:start <=  winend

            let used = s:winstls[w['winid']]['used']

            if a:start + width <= winend

                " let used = len(s:winstls[w['winid']]['content'])
                let padstr = hi. a:content
                let pad = a:start - (w['start'] + used) - 1
                if pad > 0
                    let padstr = bg.repeat(' ', pad) . padstr
                endif
                let s:winstls[w['winid']]['content'] .= padstr

                let s:winstls[w['winid']]['used'] += len(a:content)
            else

                " need to split
                let first = a:content[0:winend - a:start]
                let special = a:content[winend - a:start + 1]
                let second = a:content[winend - a:start + 2:]
                let s:winstls[w['winid']]['special'] = special

                let s:winstls[w['winid']]['specialhi'] = a:hi != '' ? a:hi : ''

                let padstr = hi . first
                let pad = a:start - (w['start'] + used) - 1
                if pad > 0
                    let padstr = bg.repeat(' ', pad) . padstr
                endif

                let s:winstls[w['winid']]['content'] .= padstr

                let s:winstls[w['winid']]['used'] += len(first)

                call s:addToWinStl(winend + 1, second, a:hi)
            endif
            break
        endif
    endfor
endfunction

function! s:getHiTerm(group, term)
   let output = execute('hi ' . a:group)
   return matchstr(output, a:term.'=\zs\S*')
endfunction

function! s:applyStls()
    let guibg = s:getHiTerm(s:bg, 'guibg')
    let ctermbg = s:getHiTerm(s:bg, 'ctermbg')

    if guibg != ''
        exe 'hi! Statusline guibg='.guibg
        exe 'hi! StatuslineNC guibg='.guibg
    else
        exe 'hi! Statusline ctermbg='.ctermbg
        exe 'hi! StatuslineNC ctermbg='.ctermbg
    endif
    for [wid, v] in items(s:winstls)
        let content = v['content']
        let used = v['used']
        let width = v['width']
        let special = v['special']
        let specialhi = v['specialhi']
        let bgstr = '%#'.s:bg.'#'
        let stl = bgstr.content.bgstr

        if special != ''
            if wid == s:activewin
                call setwinvar(wid, '&fillchars', 'stl:' . special)
                if specialhi != ''
                    exe 'hi! link Statusline '.specialhi
                else
                    " exe 'hi! link Statusline '.s:bg
                    if guibg != ''
                        exe 'hi! Statusline guibg='.guibg
                    else
                        exe 'hi! Statusline ctermbg='.ctermbg
                    endif
                endif
            else
                call setwinvar(wid, '&fillchars', 'stlnc:' . special)
                if specialhi != ''
                    exe 'hi! link StatuslineNC '.specialhi
                else
                    " exe 'hi! link StatuslineNC '.s:bg
                    if guibg != ''
                        exe 'hi! StatuslineNC guibg='.guibg
                    else
                        exe 'hi! StatuslineNC ctermbg='.ctermbg
                    endif
                endif
            endif
        else
            call setwinvar(wid, '&fillchars', 'stlnc: ,stl: ,')
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
    let bg2 = '%#Folded#'
    for w in s:nonbottom
        call setwinvar(w, '&stl', bg2.repeat(' ', 9))
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

        " call setwinvar(w['winid'], '&stl', '')
        let s:winstls[w['winid']] = {
            \ 'content': '',
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


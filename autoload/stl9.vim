vim9script

var virtualstl: dict<any>       = {}
var virtualstl_list: list<any>  = []
var stlbg: string               = g:stl_bg
var nonbtbg: string             = g:stl_nonbtbg
const savedfillchars            = g:saved_fillchars
const bgstr: string             = '%#' .. stlbg .. '#'
const nonbtbgstr: string        = '%#' .. nonbtbg .. '#'

var stlFixList = ['guibg', '#ffffff', '#111111']
if has('termguicolors')
    stlFixList = ['ctermbg', '33', '43']
endif

# get winid of windows at the bottom of the screen
def GetStlInfo(): list<any>
    var layout: list<any>     = winlayout()
    var nonbom: list<number>  = gettabinfo(tabpagenr())[0]['windows']
    var start: number         = 0
    var left2right: list<any> = []

    def Healper(li: list<any>): void
        if li[0] == 'leaf'
            nonbom->remove(index(nonbom, li[1]))
            var obj = {
                'winid': li[1],
                'width': winwidth(li[1]),
                'start': start }
            start += obj['width'] + 1
            left2right->add(obj)
        elseif li[0] == 'col'
            Healper(li[1][-1])
        elseif li[0] == 'row'
            for w in li[1]
                Healper(w)
            endfor
        endif
    enddef

    Healper(layout)
    return [left2right, nonbom]
enddef


export def SetVirtualStl(start: number, content: string, highlight: string, id: string): void
    def Sorter(a: dict<any>, b: dict<any>): number
        if a['start'] < b['start']
            return -1
        elseif a['start'] > b['start']
            return 1
        endif
        return 0
    enddef

    virtualstl[id] = {
            'start': start,
            'content': content,
            'hi': highlight
        }
    virtualstl_list = virtualstl->values()
    virtualstl_list->sort(function(Sorter))
enddef

def AddToWinStl(start: number, content: string, chi: string, botwins: list<any>, winstls: dict<any> ): void
    const width: number = strdisplaywidth(content)

    var padstr: list<string> = [bgstr]
    if chi != ''
        padstr = ['%#' .. chi .. '#']
    endif
    for w in botwins
        var winend: number = w['start'] + w['width']
        var wid: number = w['winid']
        if w['start'] <= start && start <= winend
            var used = winstls[wid]['used']
            if start + width <= winend

                padstr += [content, bgstr]
                var pad = start - (w['start'] + used) > 0 ? start - (w['start'] + used) : 0
                if pad > 0
                    padstr = [repeat(' ', pad)] + padstr
                endif

                var overlap: number = (w['start'] + used) - start
                while overlap > 0 # overlapping
                    var last: string = remove(winstls[wid]['content'], -1)

                    var l: number = strdisplaywidth(last)
                    if l > 2 && last[0 : 1] != '%#' && l >= overlap
                        last = strcharpart(last, 0, l - overlap)
                        winstls[wid]['content']->add(last)
                        winstls[wid]['used'] -= overlap
                        break
                    else
                        if l <= 2 || last[0 : 1] != '%#'
                            overlap -= l
                        endif
                    endif
                endwhile

                winstls[wid]['content'] += padstr
                winstls[wid]['used'] += strdisplaywidth(content) + pad
            else

                var first: string   = strcharpart(content, 0, winend - start)
                var special: string = strcharpart(content, winend - start, 1)
                var second: string  = strcharpart(content, winend - start + 1)

                winstls[wid]['special'] = special
                if chi != ''
                    winstls[wid]['specialhi'] = chi
                endif
                AddToWinStl(start, first, chi, botwins, winstls)
                AddToWinStl(winend + 1, second, chi, botwins, winstls)

            endif
            break
        endif
    endfor
enddef

def GetHiTerm(group: string): dict<any>
    var output: string = execute('hi ' .. group)
    if stridx(output, 'links to') > 0
        var higroup = matchstr(output, 'links.to.\?\zs\S\+\ze')
        return GetHiTerm(higroup)
    endif
    var list: list<string> = split(output, '')
    var dict: dict<any> = {}

    for item in list
        if stridx(item, '=') > 0
              var splited = split(item, '=')
              dict[splited[0]] = splited[1]
        endif
    endfor

    for item in ['guibg', 'ctermbg', 'term', 'cterm', 'guifg', 'ctermfg']
        if ! has_key(dict, item)
            dict[item] = 'NONE'
        endif
    endfor
    return dict
enddef

def CopyHi(hiname: string, terms: dict<any>): void
    var str = 'hi! ' .. hiname
    for [k, v] in items(terms)
        str ..= ' ' .. k .. '=' .. v
    endfor
    try
    execute(str)
    catch
    echom str
    endtry
enddef

def ApplyStls(winstls: dict<any>): void
    const fillcharsstr = savedfillchars .. 'stlnc: ,stl: ,'
    var activewin = win_getid()
    var flag1 = 1
    var flag2 = 1

    for [_wid, v] in items(winstls)
        var wid: number = str2nr(_wid)
        if has_key(v, 'special')
            if wid == activewin
                setwinvar(wid, '&fillchars', savedfillchars .. 'stl:' .. v['special'])
                if has_key(v, 'specialhi')
                    var shi: dict<any> = GetHiTerm(v['specialhi'])
                    shi[stlFixList[0]] = stlFixList[2]
                    CopyHi('Statusline', shi)
                    CopyHi('StatuslineTerm', shi)
                    flag1 = 0
                endif
            else
                setwinvar(wid, '&fillchars', savedfillchars .. 'stlnc:' .. v['special'])
                if has_key(v, 'specialhi')
                    var shi: dict<any> = GetHiTerm(v['specialhi'])
                    shi[stlFixList[0]] = stlFixList[1]
                    CopyHi('StatuslineNC', shi)
                    CopyHi('StatuslineTermNC', shi)
                    flag2 = 0
                endif
            endif
        else
            setwinvar(wid, '&fillchars', fillcharsstr)
        endif
        setwinvar(wid, '&stl', join(v['content'], ''))
    endfor
    if flag1 || flag2
        var defaultHi: dict<any> = GetHiTerm(stlbg)
        if flag1
            defaultHi[stlFixList[0]] = stlFixList[1]
            CopyHi('Statusline', defaultHi)
            CopyHi('StatuslineTerm', defaultHi)
        endif
        if flag2
            defaultHi[stlFixList[0]] = stlFixList[2]
            CopyHi('StatuslineNC', defaultHi)
            CopyHi('StatuslineTermNC', defaultHi)
        endif
    endif

enddef

var ww: dict<any> = {}
def g:ReturnWinstl(): dict<any>
    return ww
enddef

# clear stl of other windows
def ClearNonBottom(nonbottom: list<any>): void
    const fillcharsstr = savedfillchars .. 'stlnc: ,stl: ,'
    for wid in nonbottom  # to avoid fillchars
        setwinvar(wid, '&stl', nonbtbgstr)
        setwinvar(wid, '&fillchars', fillcharsstr)
    endfor
enddef

export def SetStl(): void
    var [botwins, nonbottom] = GetStlInfo()
    var winstls: dict<any> = {}
    for w in botwins
        winstls[w['winid']] = {
                 'content': [bgstr],
                 'used': 0,
                 'width': w['width'] 
             }
    endfor
    for obj in virtualstl_list
        AddToWinStl(obj['start'], obj['content'], obj['hi'], botwins, winstls)
    endfor
    ww = winstls
    ApplyStls(winstls)
    ClearNonBottom(nonbottom)
enddef


vim9script

var virtualstl = {}
var virtualstl_list = []
var curwins = []
var winstls = {}
var activewin = 0
var defaultbg = g:stl_bg
var nonbottom = []
var nonbtbg = g:stl_nonbtbg

# get winid of windows at the bottom of the screen
def GetStlInfo(): list<any>
    var layout = winlayout()
    var nonbom = []

    def Nonbomhelper(li: list<any>): void
        if li[0] == 'leaf'
            nonbom->add(li[1])
        elseif li[0] == 'col'
            for w in li[1]
                Nonbomhelper(w)
            endfor
        elseif li[0] == 'row'
            for w in li[1]
                Nonbomhelper(w)
            endfor
        endif
    enddef

    def Healper(li: list<any>): list<any>
        var ret = []
        if li[0] == 'leaf'
            return [li[1]]
        elseif li[0] == 'col'
            for w in li[1][0 : -2]
                Nonbomhelper(w)
            endfor
            var last = li[1][-1]
            ret = Healper(last)
        elseif li[0] == 'row'
            for w in li[1]
                ret += Healper(w)
            endfor
        endif
        return ret
    enddef

    var left2right = Healper(layout)

    var retobjs = []
    var start = 0

    for w in left2right
        var obj = {}
        obj['winid'] = w
        obj['width'] = winwidth(w)
        obj['start'] = start
        start += obj['width'] + 1
        retobjs += [obj]
    endfor
    return [retobjs, nonbom]
enddef


export def SetVirtualStl(start: number, content: string, highlight: string, id: string): void
    def Sorter(a: dict<any>, b: dict<any>): number
        if a['start'] < b['start']
            return -1
        elseif a['start'] > b['start']
            return 1
        else
            return 0
        endif
    enddef
    var obj = {}
    obj['start'] = start
    obj['content'] = content
    obj['hi'] = highlight

    virtualstl[id] = obj

    virtualstl_list = []
    for [k, v] in items(virtualstl)
        virtualstl_list += [v]
    endfor
    sort(virtualstl_list, function(Sorter))
enddef

def AddToWinStl(_start: number, _content: string, _chi: string): void
    var Wrapper: func(number, string, string)
    Wrapper = (start: number, content: string, chi: string) => {
    var hi = chi != '' ? '%#' .. chi .. '#' : ''
    var bgstr = '%#' .. defaultbg .. '#'
    for w in curwins

        var winend = w['start'] + w['width']
        if w['start'] <= start && start <= winend

            var used = winstls[w['winid']]['used']
            var width = strcharlen(content)

            if start + width <= winend

                var padstr = [hi, content]
                var pad = start - (w['start'] + used) > 0 ? start - (w['start'] + used) : 0
                if pad > 0
                    padstr = [bgstr, repeat(' ', pad)] + padstr
                endif

                var overlap = (w['start'] + used) - start
                while overlap > 0
                # overlapping
                    var last = remove(winstls[w['winid']]['content'], -1)

                    var l = strcharlen(last)
                    if l > 2 && last[0 : 1] != '%#' && l >= overlap
                        last = strcharpart(last, 0, l - overlap)
                        winstls[w['winid']]['content']->add(last)
                        winstls[w['winid']]['used'] -= overlap
                        break
                    else
                        if l > 2 && last[0 : 1] == '%#'
                            continue
                        else
                            overlap -= l
                        endif
                    endif
                endwhile

                winstls[w['winid']]['content'] += padstr

                winstls[w['winid']]['used'] += strcharlen(content) + pad

            else

                 var first = strcharpart(content, 0, winend - start)
                 var special = strcharpart(content, winend - start, 1)
                 var second = strcharpart(content, winend - start + 1)

                 winstls[w['winid']]['special'] = special
                 winstls[w['winid']]['specialhi'] = chi != '' ? chi : ''

                Wrapper(start, first, chi)
                Wrapper(winend + 1, second, chi)

            endif
            break
        endif
    endfor
    }
    Wrapper(_start, _content, _chi)
enddef


def ApplyStls(): void
    def GetHiTerm(group: string): dict<any>
      var output = execute('hi ' .. group)
      var list = split(output, '\s\+')
      var dict = {}

      for item in list
        if match(item, '=') > 0
          var splited = split(item, '=')
          dict[splited[0]] = splited[1]
        endif
      endfor
      return dict
    enddef
    var hi = GetHiTerm(defaultbg)
    var cterm = has_key(hi, 'cterm') ? hi['cterm'] : 'NONE'

    if has_key(hi, 'guibg') && hi['guibg'] != '' && has('termguicolors')
        # ctermbg of these two are set differently to avoid fillchars, same
        # for bleow
        var guifg = has_key(hi, 'guifg') ? hi['guifg'] : 'NONE'
        exe 'hi! Statusline guibg=' .. hi['guibg'] .. ' ctermbg=33 guifg=' .. guifg .. ' cterm=' .. cterm
        exe 'hi! StatuslineNC guibg=' .. hi['guibg'] .. ' ctermbg=44 guifg=' .. guifg .. ' cterm=' .. cterm

        exe 'hi! StatuslineTerm guibg=' .. hi['guibg'] .. ' ctermbg=33 guifg=' .. guifg .. ' cterm=' .. cterm
        exe 'hi! StatuslineTermNC guibg=' .. hi['guibg'] .. ' ctermbg=44 guifg=' .. guifg .. ' cterm=' .. cterm

    elseif has_key(hi, 'ctermbg') && hi['ctermbg'] != ''
        var ctermfg = has_key(hi, 'ctermfg') ? hi['ctermfg'] : 'NONE'
        exe 'hi! Statusline guibg=#ffffff ctermbg=' .. hi['ctermbg'] .. ' ctermfg=' .. ctermfg .. ' cterm=' .. cterm
        exe 'hi! StatuslineNC guibg=#111111 ctermbg=' .. hi['ctermbg'] .. ' ctermfg=' .. ctermfg .. ' cterm=' .. cterm

        exe 'hi! StatuslineTerm guibg=#ffffff ctermbg=' .. hi['ctermbg'] .. ' ctermfg=' .. ctermfg .. ' cterm=' .. cterm
        exe 'hi! StatuslineTermNC guibg=#111111 ctermbg=' .. hi['ctermbg'] .. ' ctermfg=' .. ctermfg .. ' cterm=' .. cterm
    endif

    for [_wid, v] in items(winstls)
        var content = v['content']
        var used = v['used']
        var width = v['width']
        var special = v['special']
        var specialhi = v['specialhi']
        var bgstr = '%#' .. defaultbg .. '#'
        var stl = bgstr .. join(content, '') .. bgstr
        var wid = str2nr(_wid)

        if special != ''
            if wid == activewin
                setwinvar(wid, '&fillchars', g:saved_fillchars .. 'stl:' .. special)
                if specialhi != ''
                    exe 'hi! link Statusline ' .. specialhi
                    exe 'hi! link StatuslineTerm ' .. specialhi
                endif
            else
                setwinvar(wid, '&fillchars', g:saved_fillchars .. 'stlnc:' .. special)
                if specialhi != ''
                    exe 'hi! link StatuslineNC ' .. specialhi
                    exe 'hi! link StatuslineTermNC ' .. specialhi
                endif
            endif
        else
            setwinvar(wid, '&fillchars', g:saved_fillchars .. 'stlnc: ,stl: ,')
        endif

        setwinvar(wid, '&stl', stl)
    endfor
enddef

# clear stl of other windows
def ClearNonBottom(): void
    var bg2 = '%#' .. nonbtbg .. '#'
    for wid in nonbottom
        # to avoid fillchars
        call setwinvar(wid, '&stl', bg2 .. repeat(' ', winwidth(wid)))
    endfor
enddef

export def SetStl(): void
    var li = GetStlInfo()

    curwins = li[0]
    nonbottom = li[1]

    activewin = win_getid()
    winstls = {}
    for w in curwins
        winstls[w['winid']] = {
             'content': [],
             'used': 0,
             'width': w['width'],
             'special': '',
             'specialhi': '',
         }
    endfor
    for obj in virtualstl_list
        AddToWinStl(obj['start'], obj['content'], obj['hi'])
    endfor
    ApplyStls()
    ClearNonBottom()
enddef

defcompile

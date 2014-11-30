scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

if !has('lua')
  let &cpo = s:save_cpo
  unlet! s:save_cpo
  finish
endif

let s:ns = expand('<sfile>:t:r')
function! s:luadict() "{{{
let d = {}
lua << EOF
  local function trace(parent, ret, depth)
  for k,v in pairs(parent) do
    if type(v) == 'table' then
      if depth < 1 then
        if k ~= '_G' then
          ret[k] = vim.dict()
          trace(v, ret[k], depth + 1)
        end
      elseif _G[k] ~= v then
        ret[k] = vim.dict()
        trace(v, ret[k], depth + 1)
      end
    else
      ret[k] = type(v)
    end
  end
  return ret
  end
  trace(_ENV, vim.eval('d'), 0);
EOF
let d['_G'] = d
return extend({'_ENV': d}, d)
endfunction "}}}
function! s:getluadict() "{{{
  if !exists('s:_dict')
    let dict = s:luadict()
    let s:_dict = {'vim': dict, 'lua': deepcopy(dict)}
    unlet! s:_dict.lua.vim
  endif
  return get(s:_dict, &ft, {})
endfunction "}}}
function! s:getpos(...) "{{{
  let line = getline('.')
  let col = col('.') - 1
  let regexp = a:0 ?
  \ '\v\C[a-zA-Z0-9_.]' : '\v\C[a-zA-Z0-9_]'
  while col > 0 && line[col - 1] =~# regexp
    let col -= 1
  endwhile
  return col
endfunction "}}}
function! {s:ns}#complete(findstart, base) "{{{
  if a:findstart | return s:getpos() | endif
  let ret = []
  let lns = s:getluadict()
  let base = strpart(getline('.'), s:getpos(1), col('.') - 1)
  if stridx(base, '..')
    let base = split(base, '\v\.\.')[1]
  endif
  for ns in split(base, '\v\.')
    if has_key(lns, ns)
      if type(lns[ns]) != type({})
        return -1
      endif
      let lns = lns[ns]
    endif
  endfor
  for k in sort(keys(lns))
    if stridx(k, a:base) != 0
      continue
    endif
    let kind = 'v'
    if type(lns[k]) == type({})
      call add(ret, {'word': k, 'kind': kind, 'menu': 'class'})
    else
      let t = lns[k]
      if t == 'function'
        let kind = 'f'
        let k .= '('
      endif
      call add(ret, {'word': k, 'kind': kind, 'menu': t})
    endif
  endfor
  return ret
endfunction "}}}

" debug
if expand('<sfile>:p') == expand('%:p')
  unlet! s:_dict
endif

let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set ts=2 sts=2 sw=2 fdm=marker foldmarker={{{,}}}:

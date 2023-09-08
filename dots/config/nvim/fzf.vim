" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
" - see:  https://github.com/junegunn/fzf/blob/master/README-VIM.md#explanation-of-gfzf_colors
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'Comment', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Keyword', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Comment'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'],
  \ 'gutter':  ['fg', 'Comment'] }

" customize the preview window size
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }

" shamlessly stolen from: https://github.com/unphased/vim-config/blob/master/.vimrc#L3661
" An action can be a reference to a function that processes selected lines
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

" add ctrlq to default maps
  " \ 'enter': function('s:open_with_fzf'),
let g:fzf_action = {
  \ 'ctrl-i': function('s:build_quickfix_list'),
  \ 'ctrl-o': 'tab split',
  \ 'ctrl-k': 'split',
  \ 'ctrl-l': 'vsplit' }

" fzf lua
map <silent> <Space>f :FzfLua<CR>

" search
" search buffers
map <silent> <Space>sbb :Buffers<CR>
map <silent> <Space>sbf :FzfLua buffers<CR>
map <silent> <Space>sbd :BD<CR>
"FZF Buffer Delete
function! s:list_buffers()
  redir => list
  silent ls
  redir END
  return split(list, "\n")
endfunction
function! s:delete_buffers(lines)
  execute 'bwipeout' join(map(a:lines, {_, line -> split(line)[0]}))
endfunction
command! BD call fzf#run(fzf#wrap({
  \ 'source': s:list_buffers(),
  \ 'sink*': { lines -> s:delete_buffers(lines) },
  \ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
\ }))
" search current buffer lines
map <silent> <Space>sbl :BLines<CR>
map <silent> <Space>sbww :BLines <c-r><c-w><CR>
map <silent> <Space>sbwe :BLines <c-r><c-a><CR>
" search all buffer lines
map <silent> <Space>sbj :Lines<CR>
" search commands
map <silent> <Space>sc :Commands<CR>
" search project string
map <silent> <Space>sps :Ag<CR>
" search filetype
map <silent> <Space>sf :Filetype<CR>
" search git project
map <silent> <Space>sgp :GFiles<CR>
" search git changed
map <silent> <Space>sgc :GFiles?<CR>
" search git string
function! s:get_git_root()
  let root = split(system('cd ' . expand('%:p:h') . ' && git rev-parse --show-toplevel'), '\n')[0]
  return v:shell_error ? '' : root
endfunction
command! RGCurrentProject call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview({'dir': s:get_git_root()}), <bang>0)
map <silent> <Space>sgs :RGCurrentProject<CR>
" search git word (current word under cursor into ripgrep)
" CTRL-R CTRL-F				*c_CTRL-R_CTRL-F* *c_<C-R>_<C-F>*
" CTRL-R CTRL-P				*c_CTRL-R_CTRL-P* *c_<C-R>_<C-P>*
" CTRL-R CTRL-W				*c_CTRL-R_CTRL-W* *c_<C-R>_<C-W>*
" CTRL-R CTRL-A				*c_CTRL-R_CTRL-A* *c_<C-R>_<C-A>*
" CTRL-R CTRL-L				*c_CTRL-R_CTRL-L* *c_<C-R>_<C-L>*
" 		Insert the object under the cursor:
" 			CTRL-F	the Filename under the cursor
" 			CTRL-P	the Filename under the cursor, expanded with
" 				'path' as in |gf|
" 			CTRL-W	the Word under the cursor
" 			CTRL-A	the WORD under the cursor; see |WORD|
" 			CTRL-L	the line under the cursor
map <silent> <Space>sgww :Rg! <c-r><c-w><cr>
map <silent> <Space>sgwe :Rg! <c-r><c-a><cr>
" search project
map <silent> <Space>sp :FZF<CR>
" search tags current
map <silent> <Space>st :BTags<CR>
" search tags project
" map <silent> <Space>stp :Tags<CR>
" search history
map <silent> <Space>sh :History<CR>
" search windows
map <silent> <Space>sa :Windows<CR>
" search maps
map <silent> <Space>sm :Maps<CR>
" search jumpdir jd
" inspired from: https://github.com/junegunn/fzf/issues/1274
"                https://github.com/junegunn/fzf.vim/issues/837#issuecomment-509901611
" also see: https://github.com/junegunn/fzf/blob/master/README-VIM.md#fzfrun
function! FIND_IN_DIR(dir)
  call fzf#run(fzf#wrap({'source': 'git ls-files', 'dir': a:dir}))
endfunction
command! JD
  \ call fzf#run(fzf#wrap({'source': 'zsh -lc "jdl"',
  \'sink': {line -> FIND_IN_DIR(line)}}))
map <silent> <Space>sj :JD<CR>
" search workspace dir
command! WFD
  \ call fzf#run(fzf#wrap({'source': 'find . -type d',
  \ 'dir': '~/workspace',
  \ 'sink': {line -> FIND_IN_DIR(line)}}))
map <silent> <Space>sk :WFD<CR>
" search jumpdir string with ripgrep
command! -bang -nargs=* JDS
  \ call fzf#run(fzf#wrap({'source': 'zsh -lc "jdl"', 'sink':
  \ {line -> fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview({'dir': line}), <bang>0)}}))
map <silent> <Space>sl :JDS<CR>


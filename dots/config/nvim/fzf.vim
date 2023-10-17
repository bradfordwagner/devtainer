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

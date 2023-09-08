" zoom - goyo
map <silent> <Space>zz :Goyo<cr> " enter goyo
" map <silent> <Space>zz :! tmux resize-pane -Z && sleep .2<CR><C-g>     " enter goyo
map <silent> <Space>zx :Goyo!<CR>:! tmux resize-pane -Z<CR>            " quit goyo
function! s:goyo_enter()
  if executable('tmux') && strlen($TMUX)
    silent !tmux set status off
    silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z

    let l:timeout = reltimefloat(reltime()) + 0.5
    while reltimefloat(reltime()) < l:timeout
      let l:res = system("sh -c \"tmux list-panes -F '#{E:window_zoomed_flag}' | head -c 1\"")
      sleep 1m
      if l:res == '1'
        break
      endif
    endwhile
    " Need to pass default width (80) to Goyo to tell
    " it to turn on rather than toggle.
    " execute 'Goyo 75%x100%'
    execute 'Goyo 75%+7%x100%'
  endif
endfunction
function! s:goyo_leave()
  if executable('tmux') && strlen($TMUX)
    silent !tmux set status on
    silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
  endif
endfunction
autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()


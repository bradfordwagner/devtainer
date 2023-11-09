-- fix divider color - goyo resets it to black which is very hard to see
vim.cmd([[
  function! s:tweak_colors()
    hi WinSeparator guifg=#ff5458
  endfunction
  autocmd! ColorScheme * call s:tweak_colors()
]])

-- auto tmux zoon on goyo
vim.cmd ([[
  function! s:goyo_enter()
    if executable('tmux') && strlen($TMUX)
      " silent !tmux set status off
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
      " silent !tmux set status on
      silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
    endif
  endfunction
  autocmd! User GoyoEnter nested call <SID>goyo_enter()
  autocmd! User GoyoLeave nested call <SID>goyo_leave()
]])

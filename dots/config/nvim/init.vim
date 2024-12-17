filetype plugin indent on " required

" this will eventually replace init.vim
" source configurations
source ~/.config/nvim/lua/init.lua
source ~/.config/nvim/coc.vim
source ~/.config/nvim/fzf.vim

" automatic commands
autocmd VimResized * wincmd = " evenly resize splits when resizing window

" Custom keybinds / hotkeys

" select pasted content
nnoremap gp `[v`]

" swap go to mark exact instead of the line, and center it
" https://stackoverflow.com/questions/59408739/how-to-bring-the-marker-to-middle-of-the-screen
nnoremap <expr> ' "`"

" tmux mappings
map <silent> <Space>aa :! tmux resize-pane -Z<CR>
map <silent> <Space>ah :! tmux select-pane -L<CR>
map <silent> <Space>aj :! tmux select-pane -D<CR>
map <silent> <Space>ak :! tmux select-pane -U<CR>
map <silent> <Space>al :! tmux select-pane -R<CR>
" tmux navigator - match tmux conf
let g:tmux_navigator_no_mappings = 1
noremap <silent> <M-h> :<C-U>TmuxNavigateLeft<cr>
noremap <silent> <M-j> :<C-U>TmuxNavigateDown<cr>
noremap <silent> <M-k> :<C-U>TmuxNavigateUp<cr>
noremap <silent> <M-l> :<C-U>TmuxNavigateRight<cr>
" noremap <silent> {Previous-Mapping} :<C-U>TmuxNavigatePrevious<cr>
" -end tmux navigator

" window management
map <silent> <Space>we :wincmd T<CR>
map <silent> <Space>ww :vsplit<cr> :wincmd T<CR>
map <silent> <Space>wn :tabe<CR>
map <silent> <Space>wl :vsplit<CR>
map <silent> <Space>wa :vsplit<cr>:AINewChat<cr><space>k:q<cr>
map <silent> <Space>wj :split<CR>
map <silent> <Space>wt :tabonly<CR>
map <silent> <Space>wo :only<CR>
map <silent> <Space>wq :tabclose<CR>

" shell bindings
let &shell='/bin/zsh -l' " set deafult shell to zsh login  shell to pull configurations
map <silent> <Space>el :vsplit<CR>:terminal<CR>i clear<CR>
map <silent> <Space>ek :split<CR>:terminal<CR>i clear<CR>
map <silent> <Space>en :tabe<CR>:terminal<CR>i clear<CR>
map <silent> <Space>ee :let $VIM_DIR=expand('%:p:h')<CR>:tabe<CR>:terminal<CR>icd $VIM_DIR; clear<CR>
map <silent> <Space>er :tabe<CR>:terminal<CR>igrd; clear<CR>

" resizing
map <silent> <Space>rj :horizontal resize -10<CR>
map <silent> <Space>rk :horizontal resize +10<CR>
map <silent> <Space>rh :vertical resize -10<CR>
map <silent> <Space>rl :vertical resize +10<CR>
map <silent> <Space>r<Space> :wincmd = <CR>
map <silent> <Space>r<CR> <C-w>_

" pane navigation
map <silent> <Space>h <C-W>h
map <silent> <Space>j <C-W>j
map <silent> <Space>k <C-W>k
map <silent> <Space>l <C-W>l

" pane swap
map <silent> <Space>H <C-W>H
map <silent> <Space>J <C-W>J
map <silent> <Space>K <C-W>K
map <silent> <Space>L <C-W>L

" tab navigation
map <silent> <Space>c gT
map <silent> <Space>v gt

" changelist bindings - helps searching many files
map <silent> co :copen<CR>:horizontal resize 25%<CR>
map <silent> cc :cclose<CR>
map <silent> ck :cprev<CR>zz
map <silent> cj :cnext<CR>zz

" tmux buffer integratino courtesy of vim-tbone
map <silent> ty :Tyank<CR> " take current line and put it in buffer with CR
map <silent> tp :Tput<CR> " paste tmux buffer

" from blog for copy to mac system
" https://coderwall.com/p/v-st8w/vim-copy-to-system-clipboard-on-a-mac
vmap '' :w !pbcopy<CR><CR>

" setup highlighting
set hlsearch!
nnoremap <silent> <F3> :set hlsearch!<CR>

" vim markdown disable folding
let g:vim_markdown_folding_disabled = 1

" terraform configuration
let g:terraform_fmt_on_save = 0 " set terraform format on save

" copilot
" taken from: https://codeinthehole.com/tips/vim-and-github-copilot/
let g:enabled = v:true
let g:copilot_no_tab_map = v:true
let g:copilot_assume_mapped = v:true
" let g:copilot_proxy = 'localhost:3128'
let g:copilot_filetypes = {
    \ 'gitcommit': v:true,
    \ 'markdown': v:true,
    \ 'yaml': v:true,
    \ }
" had some trouble mapping this in lua
imap <silent><script><expr> <C-y> copilot#Accept("\<CR>")

" vim-go configs
let g:go_fmt_autosave = 1
let g:go_highlight_types = 1
let g:go_addtags_transform = "camelcase"
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
" " end vim-go

syntax on
" set additional tmux syntax highlighting
au BufReadPost *.tmux.conf set syntax=tmux
filetype on
set ignorecase " searches are now case insensitive
set encoding=UTF-8
set pastetoggle=ZP " setup paste toggling for indentation issues - removed from neovim 0.9

" set list
" set listchars=tab:>- " show tab whitespace

" spaces instead of tabs
" https://timmurphy.org/2012/05/23/using-spaces-instead-of-tabs-in-vim/
set tabstop=2
set shiftwidth=2
set expandtab

set cursorline

set noswapfile

set autoread " https://vimdoc.sourceforge.net/htmldoc/options.html#%27autoread%27g

"  vundle settings
set nocompatible " be iMproved, required

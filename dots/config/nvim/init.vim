" setup vim plug
" from: https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" Vundle plugins
Plugin 'VundleVim/Vundle.vim'
Plugin 'leafgarland/typescript-vim'
Plugin 'ryanoasis/vim-devicons'
Plugin 'towolf/vim-helm'
Plugin 'junegunn/goyo.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'ntpeters/vim-better-whitespace'      " shows trailing whitespace
Plugin 'tpope/vim-surround'
Plugin 'Align'
Plugin 'mattesgroeger/vim-bookmarks'
Plugin 'auwsmit/vim-active-numbers'          " show numbers in gutter from 0 current line up and down
Plugin 'tpope/vim-commentary'
Plugin 'christianrondeau/vim-base64'         " used for base64 easy encoding wahoo
Plugin 'tpope/vim-tbone'                     " lets us do our tmux yank - super important
Plugin 'tpope/vim-fugitive'                  " helps with git commands, blame, etc https://github.com/tpope/vim-fugitive
Plugin 'hashivim/vim-terraform'              " terraform support with completion of sub commands - https://github.com/hashivim/vim-terraform
Plugin 'flazz/vim-colorschemes'
Plugin 'challenger-deep-theme/vim', {'name': 'challenger-deep-theme'} " https://github.com/challenger-deep-theme/vim
Plugin 'christoomey/vim-tmux-navigator'      " https://github.com/christoomey/vim-tmux-navigator
" Plugin 'elzr/vim-json'                       " https://github.com/elzr/vim-json
Plugin 'yggdroot/indentline'                 " https://github.com/yggdroot/indentline
Plugin 'rrethy/vim-illuminate'               " https://github.com/RRethy/vim-illuminate - highlights word under cursor

" markdown support
Plugin 'godlygeek/tabular'
Plugin 'preservim/vim-markdown'
call vundle#end()            " required

filetype plugin indent on    " required

" vim-plug
call plug#begin('~/.vim/plugged')
" vim-plug plugins - run :PlugInstall

Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'ghifarit53/tokyonight-vim' " color scheme
Plug 'kmonad/kmonad-vim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'tpope/vim-commentary'        " gc commenting
Plug 'tpope/vim-sleuth'            " indentation
Plug 'norcalli/nvim-colorizer.lua' " https://github.com/norcalli/nvim-colorizer.lua
Plug 'pearofducks/ansible-vim'
Plug 'TamaMcGlinn/quickfixdd'      " allows deleting entries in quickfix list using dd - https://github.com/TamaMcGlinn/quickfixdd
Plug 'madox2/vim-ai'               " open ai integration: https://github.com/madox2/vim-ai
Plug 'tribela/vim-transparent'     " https://github.com/tribela/vim-transparent - enable transparency
Plug 'ibhagwan/fzf-lua', {'branch': 'main'}
Plug 'folke/noice.nvim'        " https://github.com/folke/noice.nvim - replaces messages, cmdline, popupmenu
Plug 'MunifTanjim/nui.nvim'    " required by noice
Plug 'rcarriga/nvim-notify'    " https://github.com/rcarriga/nvim-notify - pretty notifications
Plug 'akinsho/bufferline.nvim', { 'tag': '*' } " https://github.com/akinsho/bufferline.nvim

" lualine: https://github.com/nvim-lualine/lualine.nvim#installation
Plug 'nvim-lualine/lualine.nvim'
" If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'

Plug 'nvim-tree/nvim-tree.lua' " https://github.com/nvim-tree/nvim-tree.lua/wiki/Installation

if has("nvim")
  Plug 'neoclide/coc.nvim', {'branch': 'release'} " completions! - using release branch
  source ~/.config/nvim/coc.vim
endif

" Initialize plugin system
call plug#end()

let mapleader = '\'
let maplocalleader = ","

" lightspeed-disable-default-mappings
" must be loaded before lightspeed.vim
let g:lightspeed_no_default_keymaps = 1

" source configurations
source ~/.config/nvim/fzf.vim

" this will eventually replace init.vim
source ~/.config/nvim/lua/init.lua

" automatic commands
autocmd VimResized * wincmd = " evenly resize splits when resizing window

" disable mouse neovim
" https://www.reddit.com/r/neovim/comments/w1ujir/mouse_enabled_by_default_in_git_master/
set mouse=

" vim rooter to manual mode
let g:rooter_manual_only = 1

" Custom keybinds / hotkeys

" select pasted content
nnoremap gp `[v`]

" scroll configs
map <silent> <Space>zx :let &scrolloff=999-&scrolloff<CR>
set scrolloff=999 " auto center cursor

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
map <silent> <Space>wj :split<CR>
map <silent> <Space>wt :tabonly<CR>

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

" tab scheme
set showtabline=2 " hide tabline

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
nnoremap <F3> :set hlsearch!<CR>

" vim markdown disable folding
let g:vim_markdown_folding_disabled = 1

" terraform configuration
let g:terraform_fmt_on_save = 0 " set terraform format on save

" copilot
" taken from: https://codeinthehole.com/tips/vim-and-github-copilot/
let g:copilot_filetypes = {
    \ 'gitcommit': v:true,
    \ 'markdown': v:true,
    \ 'yaml': v:true
    \ }

" vim-go configs
let g:go_fmt_autosave = 0
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
" set relativenumber " show o as current 1 2 3 up and down
set number " show lines as their line number
set ignorecase " searches are now case insensitive
set encoding=UTF-8
set pastetoggle=ZP " setup paste toggling for indentation issues - removed from neovim 0.9

set list
set listchars=tab:>- " show tab whitespace

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

" enable transparency by default
let g:transparent_enabled=1

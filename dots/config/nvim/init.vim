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
Plugin 'scrooloose/nerdtree'
Plugin 'itchyny/lightline.vim'
Plugin 'hallzy/lightline-onedark'
Plugin 'ryanoasis/vim-devicons'
Plugin 'towolf/vim-helm'
Plugin 'junegunn/goyo.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'ntpeters/vim-better-whitespace'      " shows trailing whitespace
Plugin 'easymotion/vim-easymotion'
Plugin 'tpope/vim-surround'
Plugin 'Align'
Plugin 'mattesgroeger/vim-bookmarks'
Plugin 'auwsmit/vim-active-numbers'          " show numbers in gutter from 0 current line up and down
Plugin 'tpope/vim-commentary'
Plugin 'haya14busa/incsearch.vim'            " used with ez motion
Plugin 'haya14busa/incsearch-easymotion.vim' " used with ez motion
Plugin 'christianrondeau/vim-base64'         " used for base64 easy encoding wahoo
Plugin 'tpope/vim-tbone'                     " lets us do our tmux yank - super important
Plugin 'tpope/vim-fugitive'                  " helps with git commands, blame, etc https://github.com/tpope/vim-fugitive
Plugin 'hashivim/vim-terraform'              " terraform support with completion of sub commands - https://github.com/hashivim/vim-terraform
Plugin 'flazz/vim-colorschemes'

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

if has("nvim")
  Plug 'karb94/neoscroll.nvim' " sweet smooth scrolling
  Plug 'neoclide/coc.nvim', {'branch': 'release'} " completions! - using release branch
  source ~/.config/nvim/coc.vim
endif

" Initialize plugin system
call plug#end()

" colorizer
set termguicolors

"" lua configs
lua <<EOF
require('colorizer').setup()

require('neoscroll').setup({
    -- Set any options as needed
})
local t = {}
local speed = '100'
-- Syntax: t[keys] = {function, {function arguments}}
t['<C-u>'] = {'scroll', {'-vim.wo.scroll', 'true', speed}}
t['<C-d>'] = {'scroll', { 'vim.wo.scroll', 'true', speed}}
t['<C-b>'] = {'scroll', {'-vim.api.nvim_win_get_height(0)', 'true', speed}}
t['<C-f>'] = {'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', speed}}
t['<C-y>'] = {'scroll', {'-0.10', 'false', speed}}
t['<C-e>'] = {'scroll', { '0.10', 'false', speed}}
t['zt']    = {'zt', {speed}}
t['zz']    = {'zz', {speed}}
t['zb']    = {'zb', {speed}}
require('neoscroll.config').set_mappings(t)

require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all"
  ensure_installed = {"bash", "go", "gomod", "markdown", "javascript", "typescript", "yaml", "python"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- List of parsers to ignore installing (for "all")
  --ignore_install = {},

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    --disable = {"markdown"},

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
EOF

" automatic commands
" autocmd VimEnter * Goyo 50%+7%x100%
autocmd VimResized * wincmd = " evenly resize splits when resizing window

" disable mouse neovim
" https://www.reddit.com/r/neovim/comments/w1ujir/mouse_enabled_by_default_in_git_master/
set mouse=

" Custom keybinds / hotkeys
vmap <leader>y :w! /tmp/vitmp<CR> " yank into tmpfile - get around vim not sharing registers across instances
nmap <leader>p :r! cat /tmp/vitmp<CR> " paste from tmp file - get around vim not sharing registers across instances
map <C-n> :NERDTreeToggle<CR>
map <leader>r :NERDTreeFind<cr> " find nerd tree file expand
map <C-p> :FZF<CR>
map <leader>w :FZF ~/workspace<CR>
map <leader>c :FZF ~/workspace/github/bradfordwagner/src/bradfordwagner.src.cheatsheet<CR>
map <leader>d :FZF ~/workspace/github/bradfordwagner/github.bradfordwagner.dotfiles<CR>
map <leader>h :FZF ~/<CR>
map <C-f> :Ag<CR>
map <C-g> :Goyo 50%+7%x100%<CR>
map ZA :update<CR> " save current file
map ZD :r !date<CR> " insert current date
vmap ZSA :%sort u<CR> " close the current file
vmap ZSR :%sort! u<CR> " close the current file
" syntax bindings
map ZSY :set syntax=yaml<CR> " Syntax Yaml
map ZSH :set syntax=helm<CR> " Syntax Helm
map ZSB :set syntax=bash<CR> " Syntax Bash
map ZGB :Git blame<CR>       " Git Blame
map ZL :!zsh -lc cl<CR><CR>
map Zr :registers<CR>
map ZR :source $MYVIMRC<CR>
map ZT :Align \|<CR>
map ZY "+y<CR>
map Q :q!<CR> " quit current file no save

" pane navigation
map <C-h> <C-W>h
map <C-M-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l

" changelist bindings - helps searching many files
map co :copen<CR>
map cj :cprev<CR>
map ck :cnext<CR>

" tab navigation
map <C-M-h> gT
map <C-M-l> gt

" tmux buffer integratino courtesy of vim-tbone
map ty :Tyank<CR> " take current line and put it in buffer with CR
map tp :Tput<CR> " paste tmux buffer
vnoremap tt y<cr>:call system("tmux load-buffer -", @0)<cr>gv " copy selection into tmux buffer - gv - selects previously select block

" easymotion configuration
map z/ <Plug>(incsearch-easymotion-/)

" from blog for copy to mac system
" https://coderwall.com/p/v-st8w/vim-copy-to-system-clipboard-on-a-mac
vmap '' :w !pbcopy<CR><CR>

" setup highlighting
set hlsearch!
nnoremap <F3> :set hlsearch!<CR>

" vim markdown disable folding
let g:vim_markdown_folding_disabled = 1

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

let NERDTreeShowHidden=1
syntax on
" set additional tmux syntax highlighting
au BufReadPost *.tmux.conf set syntax=tmux
filetype on
" set relativenumber " show o as current 1 2 3 up and down
set number
set encoding=UTF-8
set pastetoggle=ZP " setup paste toggling for indentation issues

set list
set listchars=tab:>- " show tab whitespace

" spaces instead of tabs
" https://timmurphy.org/2012/05/23/using-spaces-instead-of-tabs-in-vim/
set tabstop=2
set shiftwidth=2
set expandtab

" workaround for lightline
set laststatus=2

set cursorline

set noswapfile

" set color schemes
let g:lightline = {
      \ 'colorscheme': 'onedark',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified'] ]
      \ },
      \ 'component': {
      \ },
      \ }

" for tokyo night only
set termguicolors
let g:tokyonight_style = 'storm' " available: night, storm
let g:tokyonight_enable_italic = 1

" https://github.com/junegunn/goyo.vim#faq
" this if you change the scheme we have to change the func
function! s:tweak_colors()
  " Your color customizations
  hi VertSplit ctermfg=magenta guifg=magenta
endfunction
autocmd! ColorScheme tokyonight call s:tweak_colors()
colorscheme tokyonight
" colorscheme smyck

"  vundle settings
set nocompatible " be iMproved, required

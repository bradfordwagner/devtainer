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

" lualine: https://github.com/nvim-lualine/lualine.nvim#installation
Plug 'nvim-lualine/lualine.nvim'
" If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'

if has("nvim")
  Plug 'neoclide/coc.nvim', {'branch': 'release'} " completions! - using release branch
  source ~/.config/nvim/coc.vim
endif

" source configurations
source ~/.config/nvim/fzf.vim
source ~/.config/nvim/goyo.vim

" Initialize plugin system
call plug#end()

" colorizer
set termguicolors

"" lua configs
lua <<EOF
require("noice").setup()
require("notify").setup {
  render = "default",
  stages = "slide",
  fps = 60,
  top_down = true,
}

local challenger_deep = require'lualine.themes.challenger_deep'
-- Change the background of lualine_c section for normal mode
-- challenger_deep.normal.c.bg = '#112233'
local colors = {
  red            = "#ff8080",
  green          = "#95ffa4",
  yellow         = "#ffe9aa",
  cyan           = "#aaffe4",
  white          = "#F3F3F3",
  dark_red       = "#ff5458",
  dark_green     = "#62d196",
  dark_yellow    = "#ffb378",
  dark_cyan      = "#63f2f1",
  dark_asphalt   = "#565575",
  asphalt_subtle = "#100E23",
}
-- override the inactive block, it wasn't visible enough
-- see base here for color scheme https://github.com/challenger-deep-theme/vim/blob/master/lua/lualine/themes/challenger_deep.lua
challenger_deep.inactive = {
    a = { fg = colors.green, bg = colors.dark_asphalt , gui = "bold", },
    c = { fg = colors.dark_cyan, bg = colors.dark_asphalt },
}
require('lualine').setup {
  options = {
    -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
    -- theme = 'onedark'
    theme = challenger_deep
  },
  sections = {
    lualine_a = {
      {
        'filename',
        path = 1,                -- 0: Just the filename
                                 -- 1: Relative path
                                 -- 2: Absolute path
                                 -- 3: Absolute path, with tilde as the home directory
      }
    },
  },
  inactive_sections = {
    lualine_a = {
      {
        'filename',
        path = 1,                -- 0: Just the filename
                                 -- 1: Relative path
                                 -- 2: Absolute path
                                 -- 3: Absolute path, with tilde as the home directory

      }
    },
  },
}

require('colorizer').setup()

require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all"
  ensure_installed = {
    "bash",
    "go",
    "gomod",
    "hcl",
    "javascript",
    "markdown",
    "python",
    "typescript",
    "yaml",
  },

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
autocmd VimResized * wincmd = " evenly resize splits when resizing window

" disable mouse neovim
" https://www.reddit.com/r/neovim/comments/w1ujir/mouse_enabled_by_default_in_git_master/
set mouse=

" Custom keybinds / hotkeys
vmap <silent> <leader>y :w! /tmp/vitmp<CR> " yank into tmpfile - get around vim not sharing registers across instances
nmap <silent> <leader>p :r! cat /tmp/vitmp<CR> " paste from tmp file - get around vim not sharing registers across instances
map <silent> <C-n> :NERDTreeToggle<CR>
map <silent> <leader>r :NERDTreeFind<cr> " find nerd tree file expand
map <silent> <C-p> :FZF<CR>
map <silent> <C-M-p> :GFiles<CR>
map <silent> <leader>w :FZF ~/workspace<CR>
map <silent> <leader>c :FZF ~/workspace/github/bradfordwagner/src/bradfordwagner.src.cheatsheet<CR>
map <silent> <leader>d :FZF ~/.dotfiles<CR>
map <silent> ZA :update<CR> " save current file
map <silent> ZD :r !date<CR> " insert current date
vmap <silent> ZSA :%sort u<CR> " close the current file
vmap <silent> ZSR :%sort! u<CR> " close the current file
" syntax bindings
map <silent> ZSY :set syntax=yaml<CR> " Syntax Yaml
map <silent> ZSH :set syntax=helm<CR> " Syntax Helm
map <silent> ZSB :set syntax=bash<CR> " Syntax Bash
map <silent> ZGB :Git blame<CR>       " Git Blame
map <silent> ZL :!zsh -lc cl<CR><CR>
map <silent> Zr :registers<CR>
map <silent> ZR :source $MYVIMRC<CR>:noh<CR>:CocRestart<CR>
map <silent> ZY "+y<CR>
map <silent> ZP :set paste<CR>
map <silent> Zp :set nopaste<CR>
map <silent> Q :q!<CR> " quit current file no save
" vimgrep helpers
" current file
map <expr><silent> <Space>ggi ":vimgrep /" . input("grep current file: ") . "/ % \<CR>co"
map <silent> <Space>ggww :vimgrep /<c-r><c-w>/ % <cr>co
map <silent> <Space>ggwe :vimgrep /<c-r><c-a>/ % <cr>co
" all files
map <expr><silent> <Space>gai ":vimgrep /" . input("grep all files: ") . "/ **/* \<CR>co"
map <silent> <Space>gaww :vimgrep /<c-r><c-w>/ **/* <cr>co
map <silent> <Space>gawe :vimgrep /<c-r><c-a>/ **/* <cr>co
" dir matching
map <expr><silent> <Space>gd ":vimgrep /" . input("grep files in directory: ") . "/ **/**" . input("dir match: ") . "**/* \<CR>co"

" toggle guides indentation
map <silent> <Space>i :IndentLinesToggle<CR>

" scroll configs
map <silent> <Space>zj :let &scrolloff=999-&scrolloff<CR>
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
let &shell='/bin/zsh -l' " set deafult shell to zsh login  shell to pull configurations
map <silent> <Space>sss :let $VIM_DIR=expand('%:p:h')<CR>:tabe<CR>:terminal<CR>icd $VIM_DIR; clear<CR>
map <silent> <Space>ssd :tabe<CR>:terminal<CR>igrd; clear<CR>

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
" set showtabline=0 " hide tabline

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
vnoremap <silent> tt y<cr>:call system("tmux load-buffer -", @0)<cr> " copy selection into tmux buffer - gv - selects previously select block

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

let NERDTreeShowHidden=1 " show hidden files
" Open the existing NERDTree on each new tab.
" autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif
syntax on
" set additional tmux syntax highlighting
au BufReadPost *.tmux.conf set syntax=tmux
filetype on
set relativenumber " show o as current 1 2 3 up and down
" set number " show lines as their line number
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

" workaround for lightline
set laststatus=2

set cursorline

set noswapfile

set autoread " https://vimdoc.sourceforge.net/htmldoc/options.html#%27autoread%27g

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
let g:tokyonight_style = 'night' " available: night, storm
let g:tokyonight_enable_italic = 0

" https://github.com/junegunn/goyo.vim#faq
" this if you change the scheme we have to change the func
function! s:tweak_colors()
  " Your color customizations
  hi VertSplit ctermfg=cyan guifg=cyan
  " hi VertSplit ctermfg=grey guifg=grey
endfunction
autocmd! ColorScheme tokyonight call s:tweak_colors()
autocmd! ColorScheme smyck call s:tweak_colors()
autocmd! ColorScheme challenger_deep call s:tweak_colors()
" colorscheme Chasing_Logic
" colorscheme coffee
" colorscheme deus
" colorscheme chance-of-storm
" colorscheme tokyonight
" colorscheme smyck
colorscheme challenger_deep

"  vundle settings
set nocompatible " be iMproved, required

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
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

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

" enable transparency by default
let g:transparent_enabled=1

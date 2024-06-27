Plug 'tpope/vim-surround'

let mapleader = " "
let maplocalleader = ","

" set options
set multiple-cursors
set surround
set pastetoggle=ZP " setup paste toggling for indentation issues

" which-key setup
set which-key
set timeoutlen=5000

" Setup AceJump
map zj :action AceAction<CR>

" save current file
map ZA :w<CR>
" insert current date
map ZD :r !date<CR>

" goto
map gd <action>(GotoDeclaration)

" navigation
map <M-h> <action>(TabShiftActions.MoveFocusLeft)
map <M-j> <action>(TabShiftActions.MoveFocusDown)
map <M-k> <action>(TabShiftActions.MoveFocusUp)
map <M-l> <action>(TabShiftActions.MoveFocusRight)
map Q :q!<cr>

" open file configuration
map <leader>F <action>(GotoFile)
map <Leader>f :action Tool_External Tools_file_open<CR>
map <Leader>dd :action Tool_External Tools_search_file<CR>
map <leader>o <action>(RecentFiles)
map <leader>ds <action>(FileStructurePopup)

" copilot.chat.show
imap <C-y> <action>(copilot.applyInlaysNextLine)
map <leader>sn <action>(HideAllWindows)
map <C-M-y> :action Tool_External Tools_wezterm<CR>

" close project
map <leader>Q <action>(CloseProject)

" window management
map <leader>we :wincmd T<CR>
map <leader>wl :vsplit<CR>
map <leader>wa <action>(copilot.chat.show)
map <leader>wj :split<CR>
map <leader>wt :tabonly<CR>
map <leader>wo :only<CR>
map <leader>wq :tabclose<CR>

" tab navigation
map <leader>c gT
map <leader>v gt

" comment
map gcc <action>(CommentByLineComment)

map <leader>rs :source ~/.ideavimrc<CR>
map <leader>rf <action>(VimFindActionIdAction)

" toggle split maximize
map <leader>zz <action>(MaximizeEditorInSplit)
map <leader>zx <action>(ToggleDistractionFreeMode)
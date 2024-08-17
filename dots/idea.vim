Plug 'tpope/vim-surround'

let mapleader = " "
let maplocalleader = ","

" set options
set multiple-cursors
set pastetoggle=ZP " setup paste toggling for indentation issues
set ignorecase
set surround

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
map gr <action>(FindUsages)
map gR <action>(RenameElement)
map gt <action>(ExpressionTypeInfo)

" change list
map cj <action>(NextOccurence)
map ck <action>(PreviousOccurence)

" bookmarks
map mm <action>(ToggleBookmark)
map mn <action>(GotoNextBookmarkInEditor)
map mp <action>(GotoPreviousBookmarkInEditor)
map ma <action>(ActivateBookmarksToolWindow)

" git
map <leader>mA <action>(Annotate)

" debug
map <leader>sd <action>(Debug)
map <leader>sD <action>(ChooseDebugConfiguration)
map <leader>ss <action>(Resume)
map <leader>sj <action>(StepOver)
map <leader>sk <action>(StepOut)
map <leader>sl <action>(StepInto)
map <leader>sx <action>(Stop)
map <leader>sh <action>(ToggleLineBreakpoint)
map <leader>sH <action>(ViewBreakpoints)
map <leader>sc <action>(Coverage)
map <leader>sC <action>(HideCoverage)
map <leader>sv <action>(ActivateDebugToolWindow)

" visual mode
" sort
vmap <leader>sa <action>(EditorSortLines)
vmap <leader>rr <action>(ReformatCode)

" navigation
map <leader>h <action>(TabShiftActions.MoveFocusLeft)
map <leader>j <action>(TabShiftActions.MoveFocusDown)
map <leader>k <action>(TabShiftActions.MoveFocusUp)
map <leader>l <action>(TabShiftActions.MoveFocusRight)
map Q :q!<cr>

" open file configuration
map <leader>F <action>(GotoFile)
map <leader>f :action Tool_External Tools_open_file<CR>
map <leader>dd :action Tool_External Tools_search_file<CR>
map <leader>da :action Tool_External Tools_search_files<CR>
map <leader>o <action>(RecentFiles)
map <leader>ds <action>(FileStructurePopup)

" copilot.chat.show
imap <C-y> <action>(copilot.applyInlaysNextLine)
map <C-M-y> :action Tool_External Tools_terminal<CR>

" github actions
map <leader>gh <action>(ActivateGitHubActionsToolWindow)

" close project
map <leader>Q <action>(CloseProject)

" select pasted content
nnoremap gp `[v`]

" window management
map <leader>we :wincmd T<CR>
map <leader>wl :vsplit<cr>
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

" idea vim plugin helpers
map <leader>rs :source ~/.ideavimrc<CR>
map <leader>re :e ~/.ideavimrc<CR>
map <leader>rf <action>(VimFindActionIdAction)

" views
map <leader>zx <action>(MaximizeEditorInSplit)
map <leader>zz <action>(ToggleDistractionFreeMode)
map <leader>xx <action>(ToggleZenMode)
map <leader>xc <action>(HideAllWindows)

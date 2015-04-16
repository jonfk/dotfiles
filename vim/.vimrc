"forget being compatible with good ol' vi
set nocompatible


" Remove the annoying bell
set visualbell

set encoding=utf-8
" Get that filetype stuff happening
filetype on
filetype plugin on
filetype indent on

" Turn on that syntax highlighting
syntax on
set showmatch

" Take care of indentation
set autoindent
"set si

" searching
" Incremental search
set incsearch
" highlight search
set hlsearch

" Hides changed hidden buffers
set hidden

" Don't update the display while executing macros
set lazyredraw


" Show Line numbers on the left side
set number
set numberwidth=1

" Enable enhanced command-line completion. Presumes you have compiled
" with +wildmenu.  See :help 'wildmenu'
set wildmenu

" Map leader for <leader> to be ,
let mapleader = ","

" Let's make it easy to edit this file (mnemonic for the key sequence is
" 'e'dit 'v'imrc)
nmap <silent> <leader>ev :e $MYVIMRC<cr>

" And to source this file as well (mnemonic for the key sequence is
" 's'ource 'v'imrc)
nmap <silent> <leader>sv :so $MYVIMRC<cr>

""Java anonymous classes. Sometimes, you have to use them.
set cinoptions+=j1
let java_mark_braces_in_parens_as_errors=1
let java_highlight_all=1
let java_highlight_debug=1
let java_ignore_javadoc=1
let java_highlight_java_lang_ids=1
let java_highlight_functions="style"
let java_minlines = 150

" This is for whitespace when using tab (default)
set expandtab
set shiftwidth=4
set softtabstop=4

" Indentation based on filetype
autocmd FileType sml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
autocmd FileType hs setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
autocmd FileType java setlocal shiftwidth=4 softtabstop=4 expandtab
autocmd FileType py setlocal shiftwidth=8 tabstop=8 softtabstop=8 expandtab

" Set colorscheme
colorscheme desert


" At least let yourself know what mode you're in
set showmode
" Set the status line the way I like it
set stl=%f\ %m\ %r\ Line:\ %l/%L[%p%%]\ Col:\ %c\ Buf:\ #%n\ [%b][0x%B]%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\

" Copied to get file encoding and bomb
set statusline=%<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P


" tell Vim to always put a status line in, even if there is only one
" window
set laststatus=2

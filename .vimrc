" Basic settings
set number
set splitright
set tabstop=4
set shiftwidth=4
set hidden
set conceallevel=2
set foldlevelstart=99
set clipboard=unnamedplus
set background=dark

" Tags for library navigation, load only language-specific tags
augroup language_tags
	au!
	autocmd FileType java setlocal tags+=~/.vim/tags/jdk8tags
	autocmd FileType cs setlocal tags+=~/.vim/tags/dotnet8tags
	autocmd FileType c setlocal tags+=~/.vim/tags/c-stdlib-tags
augroup END

" Cursor shape: line in insert mode, block in normal mode
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Auto-install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Sensible Vim Defaults
Plug 'tpope/vim-sensible'

" Vim Language Server Protocol
Plug 'prabirshrestha/vim-lsp', { 'commit': '6d4719e' }
Plug 'mattn/vim-lsp-settings', { 'commit': 'aef09c6' }

" Auto-closing Pairs
Plug 'jiangmiao/auto-pairs'

" Autocompletion Popup
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" File Explorer
Plug 'preservim/nerdtree'

" Code Outline
Plug 'preservim/tagbar'

" Vim Buffer Tabline
Plug 'ap/vim-buftabline'

" Vimspector Debugger Manager
Plug 'puremourning/vimspector'

" Vim Markdown
Plug 'preservim/vim-markdown'

" GruvBox Theme
Plug 'morhetz/gruvbox'

call plug#end()

" LSP Performance Boost
let g:lsp_use_native_client = 1

" Disable inline diagnostic text
let g:lsp_diagnostics_virtual_text_enabled = 0

" Show diagnostics with signs
let g:lsp_diagnostics_signs_enabled = 1

" Show diagnostics in floating window on hover
let g:lsp_diagnostics_float_cursor = 1

" Activate asyncomplete
let g:asyncomplete_auto_popup = 1

" NERDTree show hidden files
let NERDTreeShowHidden = 1

" Enable Vimspector
let g:vimspector_enable_mappings = 'HUMAN'

" Asyncomplete settings

" Scroll down through suggestions 
inoremap <expr> <C-j>   	pumvisible() ? "\<C-n>" : "\<C-j>"
inoremap <expr> <C-Down>	pumvisible() ? "\<C-n>" : "\<C-j>"
" Scroll up through suggestions
inoremap <expr> <C-k>   	pumvisible() ? "\<C-p>" : "\<C-k>"
inoremap <expr> <C-Up>		pumvisible() ? "\<C-p>" : "\<C-k>"
" Accept suggestion
inoremap <expr> <Tab>   	pumvisible() ? asyncomplete#close_popup() : "\<Tab>"
" Enter is for new line only (doesn't accept suggestion)
inoremap <expr> <cr>    	pumvisible() ? asyncomplete#close_popup() . "\<cr>" : "\<cr>"
" Arrow keys close popup and move cursor normally
inoremap <expr> <Up>   		pumvisible() ? asyncomplete#close_popup() . "\<Up>" : "\<Up>"
inoremap <expr> <Down> 		pumvisible() ? asyncomplete#close_popup() . "\<Down>" : "\<Down>"

let g:smart_goto_in_progress = 0

" Clangd configuration
if executable('clangd')
	augroup lsp_clangd
		au!
		au User lsp_setup call lsp#register_server({
			\ 'name': 'clangd',
			\ 'cmd': {server_info->['clangd']},
			\ 'allowlist': ['c', 'cpp'],
			\ })
	augroup END
endif

" Typescript LSP configuration
if executable('typescript-language-server')
	augroup LspTypeScript	
		au!
		au User lsp_setup call lsp#register_server({
			\ 'name': 'typescript-language-server',
			\ 'cmd': {server_info->['typescript-language-server', '--stdio']},
			\ 'allowlist': ['javascript', 'typescript'],
			\ })
	augroup END
endif

" Vim markdown settings
let g:vim_markdown_folding_disabled = 0
let g:vim_markdown_folding_level = 1
let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_auto_insert_bullets = 1
let g:vim_markdown_follow_anchor = 1

" Smart logic for <C-]> keybind, searches locally with :LspDefinition and then
" searches source tags if that fails
function! SmartFindDefinition()
	" Prevent overlapping calls
	if g:smart_goto_in_progress
		echo "Already searching..."
		return
	endif
	let g:smart_goto_in_progress = 1

	" Save current buffer and position
	let l:start_buf = bufnr('%')
	let l:start_pos = getpos('.')
	let l:buffers_before = len(getbufinfo({'buflisted': 1}))
	
	" Try LspDefinition first
	let l:lsp_available = execute('LspStatus') !~# 'not running'

	" If LSP server is available, proceed
	if l:lsp_available
		" Try LspDefinition
		LspDefinition
		
		" Handle async nature of LspDefinition
		" Wait for variable amount of time based on polling
		let l:max_wait = 300
		" Check every 50 milliseconds
		let l:wait_interval = 50
		let l:waited = 0

		while l:waited < l:max_wait
			sleep 50m
			let l:waited += l:wait_interval

			" Check if buffer is different or cursor moved
			let l:end_buf = bufnr('%')
			let l:end_pos = getpos('.')
			let l:buffers_after = len(getbufinfo({'buflisted': 1}))

			" Check if LSP succeeded, ie. buffer is different, new one was created or position
			" moved within same buffer
			if l:start_buf != l:end_buf || l:buffers_after > l:buffers_before || l:start_pos != l:end_pos
				let g:smart_goto_in_progress = 0
				return
			endif
		endwhile
	endif

	" Try tags next
	try
		execute "normal! \<C-]>"
	catch
		echohl ErrorMsg
		echo "No definition found"
		echohl None
	endtry

	let g:smart_goto_in_progress = 0
endfunction

" SmartFindDefinition keybind
nnoremap <C-]> :call SmartFindDefinition()<CR>

" Show diagnostic messages in Vim console
nnoremap <Leader>e :LspDocumentDiagnostics<CR>

" Show hover documentation info
nnoremap <Leader>h :LspHover<CR>

" Window Navigation in Normal Mode
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <C-Left> <C-w>h
nnoremap <C-Down> <C-w>j
nnoremap <C-Up> <C-w>k
nnoremap <C-Right> <C-w>l

" Window Navigation in Terminal Mode
tnoremap <C-h> <C-w>h
tnoremap <C-j> <C-w>j
tnoremap <C-k> <C-w>k
tnoremap <C-l> <C-w>l
tnoremap <C-Left> <C-w>h
tnoremap <C-Down> <C-w>j
tnoremap <C-Up> <C-w>k
tnoremap <C-Right> <C-w>l

" Terminal shortcut
nnoremap <Leader>t :botright term ++rows=16<CR>

" Buffer switching shortcuts
nnoremap <Tab> :bnext!<CR>
nnoremap <S-Tab> :bprevious!<CR>

" Close buffer without closing split shortcut
nnoremap <Leader>q :bp\|bd #<CR>

" Add new lines in Normal mode
nnoremap <Leader>O O<Esc>
nnoremap <Leader>o o<Esc>

" Start GruvBox theme (comment out for base16 transparent)
autocmd VimEnter * ++nested colorscheme gruvbox

" Auto-open NERDTree and Tagbar
autocmd VimEnter * NERDTree | wincmd l
autocmd VimEnter * nested :TagbarOpen

" Exclude terminal buffers from tabline
autocmd TerminalOpen * setlocal nobuflisted
let g:buftabline_show = 1


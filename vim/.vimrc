call plug#begin()

" Aquí van los plugins que quieras instalar
" plugin para que sea tipo ide
Plug 'preservim/nerdtree'
" plugin para terminal en vim
Plug 'voldikss/vim-floaterm'
" plugin para colorido en vim
Plug 'vim-airline/vim-airline'
" plugin para ver los cambios de git (+, -, ~)
Plug 'airblade/vim-gitgutter'
 " Líneas de indentación
Plug 'Yggdroot/indentLine'
" Múltiples cursores
Plug 'terryma/vim-multiple-cursors' 
" El motor de autocompletado (requiere Node.js instalado en tu sistema)
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Surround para eliminar y agregar caracteres envolventes
Plug 'tpope/vim-surround'

call plug#end()

" Configuración extra para abrirlo con un atajo (ejemplo: Ctrl+n)
nnoremap <C-l> :set number!<CR>
let g:floaterm_keymap_toggle = '<F12>'

" --- Configuración opcional para GitGutter ---
" Actualiza los signos más rápido (por defecto son 4 segundos)
set updatetime=100

" Usar Tab para navegar por las sugerencias de autocompletado
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

" Configuración para que indentLine se vea bien
let g:indentLine_char = '┆'

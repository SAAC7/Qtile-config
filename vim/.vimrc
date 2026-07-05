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

call plug#end()

" Configuración extra para abrirlo con un atajo (ejemplo: Ctrl+n)
nnoremap <C-n> :set number!<CR>
let g:floaterm_keymap_toggle = '<F12>'

" --- Configuración opcional para GitGutter ---
" Actualiza los signos más rápido (por defecto son 4 segundos)
set updatetime=100

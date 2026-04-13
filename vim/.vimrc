call plug#begin()

" Aquí van los plugins que quieras instalar
Plug 'preservim/nerdtree'
Plug 'voldikss/vim-floaterm'
Plug 'vim-airline/vim-airline'

call plug#end()

" Configuración extra para abrirlo con un atajo (ejemplo: Ctrl+n)
nnoremap <C-n> :set number!<CR>
let g:floaterm_keymap_toggle = '<F12>'

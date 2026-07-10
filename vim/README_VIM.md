# Manual de Uso: Configuración de Vim para Node.js

Esta es una guía rápida para dominar tu entorno de desarrollo personalizado basado en Vim. Esta configuración está diseñada para potenciar tu productividad en proyectos de Node.js.

## 1. Gestión de Archivos y Navegación
### NERDTree (`preservim/nerdtree`)
Permite ver la estructura de carpetas como en un IDE.
- **Abrir/Cerrar:** Ejecuta `:NERDTreeToggle` en el modo normal.
- **Dentro del árbol:** Usa `j` y `k` para moverte, `Enter` para abrir un archivo, y `o` para abrir en una nueva ventana.

---

## 2. Productividad y Edición
### Múltiples Cursores (`terryma/vim-multiple-cursors`)
Esta es una herramienta extremadamente poderosa para editar múltiples líneas a la vez.

**¿Cómo usarlo?**
1. **Selección inicial:** Coloca el cursor sobre la palabra que quieres editar.
2. **Activar:** Presiona `Ctrl + n` (configuración por defecto). Esto seleccionará la palabra actual y creará un cursor.
3. **Seleccionar el siguiente:** Presiona `Ctrl + n` nuevamente para saltar a la siguiente ocurrencia de la palabra y seleccionarla también.
4. **Editar:** Una vez tengas todos los cursores necesarios, presiona `c` para borrar y cambiar, o `i` para insertar texto en todos a la vez.
5. **Salir:** Presiona `Esc` una vez para volver al modo normal con un solo cursor.

**Trucos:**
- Usa `Ctrl + x` para saltar una ocurrencia si seleccionaste algo por error.
- Usa `Ctrl + p` para retroceder en la selección de ocurrencias.

### Líneas de Indentación (`Yggdroot/indentLine`)
Ayuda a visualizar los bloques de código (muy útil en callbacks y promesas de Node.js).
- Se activa automáticamente al abrir archivos.
- Si necesitas ocultarlas temporalmente: `:IndentLinesToggle`.

---

## 3. Autocompletado e Inteligencia (`coc.nvim`)
Con la instalación de las extensiones (`coc-tsserver`, etc.), tienes lo siguiente:
- **Autocompletado:** Aparece automáticamente mientras escribes. Usa `Tab` para seleccionar la sugerencia.
- **Ir a definición:** Coloca el cursor sobre una función y presiona `gd` (si configuraste el atajo) para saltar a donde fue definida.
- **Formateo:** Tu código se formateará automáticamente al guardar (`:w`) gracias a Prettier.

---

## 4. Terminal e Información
### Terminal Integrada (`voldikss/vim-floaterm`)
- **Abrir/Cerrar:** Presiona `F12`. Es excelente para ejecutar `node index.js` sin salir del editor.
- **Navegación:** Usa `Ctrl+\` y luego `Ctrl+n` para salir del modo terminal y volver al control de Vim.

### Estado y Git (`airline` + `gitgutter`)
- **Vim-Airline:** Muestra información útil en la barra inferior (modo actual, línea, nombre de archivo).
- **GitGutter:** Verás signos en la columna izquierda:
  - `+`: Línea añadida.
  - `-`: Línea eliminada.
  - `~`: Línea modificada.

---

## 5. Resumen de Atajos Clave
| Comando / Atajo | Acción |
| :--- | :--- |
| `:set number!` | Alternar visualización de números de línea (`Ctrl + n` en tu config) |
| `F12` | Alternar terminal flotante |
| `Ctrl + n` | Crear múltiples cursores (con cursor sobre palabra) |
| `:w` | Guardar y aplicar formato automático (Prettier) |
| `:PlugInstall` | Instalar nuevos plugins después de editar el `.vimrc` |

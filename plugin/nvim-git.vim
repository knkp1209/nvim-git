if exists('g:nvim-git') || &cp
  finish
endif
let g:nvim-git = 1

command! ShowLineAuthors lua require'nvim-git'.show_line_authors()

nnoremap <silent> <Leader>bl :ShowLineAuthors<CR>


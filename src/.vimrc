" Insert the following lines in your global .vimrc to use this
" project-specific vimrc automatically:
"   set exrc
"   set secure

hi PpxSexpGroup ctermfg=Green
au BufRead,BufNewFile *.ml call matchadd('PpxSexpGroup', '%sexp')
au BufRead,BufNewFile *.ml call matchadd('PpxSexpGroup', '%sfxp')
au BufRead,BufNewFile *.ml call matchadd('PpxSexpGroup', '%sp')
au BufRead,BufNewFile *.ml call matchadd('PpxSexpGroup', '%spls')

hi RawDangerGroup ctermfg=Red
au BufRead,BufNewFile *.ml call matchadd('RawDangerGroup', 'RAW')

" Insert the following lines in your global .vimrc to use this
" project-specific vimrc automatically:
"   set exrc
"   set secure

hi PpxSexpGroup ctermfg=Green
call matchadd('PpxSexpGroup', '%sexp')
call matchadd('PpxSexpGroup', '%sfxp')
call matchadd('PpxSexpGroup', '%sp')
call matchadd('PpxSexpGroup', '%spls')

hi RawDangerGroup ctermfg=Red
call matchadd('RawDangerGroup', 'RAW')

" ===============================================================
"  File:    namazu.vim
"  Version: 0.01
"  Author:  Kyosuke Takayama (support@mc.neweb.ne.jp)
"
"  $Id: namazu.vim 2 2005-02-10 14:21:48Z takayama $
" ===============================================================
"
" Do not support updating the namazu index.
" Please manually update it.
"
" What's NAMAZU:
"
"   See http://www.namazu.org/
"
" Install:
"   Put namazu.vim into your vim plugin directory.
"   And then, you need namazu command-line client, of course.
"
" Options:
"
"   let g:namazu_cmd   = '/path/to/namazu'
"                        (default: namazu)
"
"   let g:namazu_index = '/path/to/indexdirectory'
"                        (Can be a space-separated list)
"
"   let g:namazu_range = NUMBER
"                        Set the number of documents shown to NUMBER.
"                        (default: 30)
"
"   let g:namazu_color = NUMBER
"                        Set this to zero to disable syntax
"                        highlighting.  (default: 1)
"
" Usage:
"
"   Type :Namazu<CR> to start searching.
"
"   <enter> : Open a selected file.
"   r       : Research.
"   s       : Set a sort METHOD (score, date)
"   k       : Move to a previous result.
"   j       : Move to a next result.
"   h       : Move to a previous page.
"   l       : Move to a next page.
"   q       : Close the namazu window.
"

if exists('g:namazu_disable')
   finish
endif

function! s:NamazuMain()
   call s:NamazuInit()
   let file = tempname()
   let file = substitute(file, '\v\d+$', '__Namazu__', '')
   let keyword = input('Enter keyword: ')

   let winno = bufwinnr('__Namazu__')
   silent! exe winno.'wincmd w'

   enew
   silent! exe 'edit ++enc='.&enc.' ++ff='.&ff.' '.file
   silent! setlocal nobackup noswf

   if has('syntax') && g:namazu_color == 1
      syntax match Title /\v^\d+(,\d+)?\. .*$/
      syntax match Statement /^  .*$/
      syntax match Comment /^   .*$/
      syntax match None /^   .*$/
   endif

   let s:page = 0
   let s:sort = 'score'
   call s:NamazuSearch(keyword)

   nnoremap <silent> <buffer> <cr> :call <SID>NamazuView(0)<cr>
   nnoremap <silent> <buffer> r :call <SID>NamazuResearch()<cr>
   nnoremap <silent> <buffer> s :call <SID>NamazuSort()<cr>

   nnoremap <silent> <buffer> j :call <SID>NamazuScroll(0)<cr>
   nnoremap <silent> <buffer> k :call <SID>NamazuScroll(1)<cr>

   nnoremap <silent> <buffer> h :call <SID>NamazuWhence(0)<cr>
   nnoremap <silent> <buffer> l :call <SID>NamazuWhence(1)<cr>

   nnoremap <silent> <buffer> q :call <SID>NamazuQuit()<cr>
endfun

function! s:NamazuSearch(keyword)
   setlocal modifiable
   let keyword = escape(a:keyword, '"')
   silent! exe "%!".s:namazu_cmd.' --sort='.s:sort.' -H -n '.s:namazu_range.' -w '.s:page.' "'.keyword.'" '.s:namazu_index
   silent! %s/\n\n\+/\r\r/
   let s:keyword = keyword

   if has('win32')
      silent! %s/\//\\/g
      silent! %s/\|/:/g
   endif

   let i = 0
   while i <= line('$')
      if getline(i) =~ '\v^\d+(,\d+)?\. '
         let f = 1
         while f <= 3
            call cursor(i+f, 1)
            normal! I  
            let f = f + 1
         endwhile

         let i = i + 3
         let buf = getline(i)
            normal! I  
         while strlen(buf) > 77
            call cursor(i, 77)
            exe "normal!i\<CR>"
            let buf = getline('.')
            let i = i + 1
         endwhile

         let i = i + 2
      endif
      let i = i + 1
   endwhile

   silent! write!
   setlocal nomodifiable
   call cursor(1, 1)
   call s:NamazuScroll(0)

   let line  = getline(5)
   let s:hit = substitute(line, '\v.* (\d+) .*', '\1', '')
endfun

function! s:NamazuSort()
   while 1
      let sort = input("Sort key (score or date): ")
      if sort == 'score' || sort == 'date'
         break
      endif
      " TODO
      echo 'invalid input'
   endwhile
   let s:sort = sort
   call s:NamazuSearch(s:keyword)
endfun

function! s:NamazuResearch()
   let keyword = input('Enter keyword: ', s:keyword)
   let s:keyword = keyword
   let s:page = 0
   call s:NamazuSearch(s:keyword)
endfun

function! s:NamazuWhence(mode)
   let s:hit
   let page = (a:mode == 1) ? s:page + s:namazu_range : s:page - s:namazu_range

   if page < 0
      let page = (s:hit - (s:hit % s:namazu_range))
   endif
   if page >= s:hit
      let page = 0
   endif

   if s:page != page
      let s:page = page
      call s:NamazuSearch(s:keyword)
   endif
endfun

function! s:NamazuScroll(mode)
   let before = @/
   let @/ = '\v^\d+(,\d+)?\. '
   silent! execute 'normal!' (a:mode == 0) ? 'n' : 'N'
   let @/ = before

   if has('syntax') && g:namazu_color == 1
      syntax match DiffText /^.*\%#.*$/
   endif
endfun

function! s:NamazuView(mode)
   let before = @/
   let @/ = '\v^\S+'
   silent! execute 'normal!n'
   let @/ = before
   let line = getline('.')

   let file  = substitute(line, '\v^(.*) \(.{-}\)$', '\1', '')
   call s:NamazuScroll(1)

   if file == ''
      return
   endif

   silent! exe 'edit '.file
endfun

function! s:NamazuQuit()
   bw
endfun


function! s:NamazuInit()
   if !exists('g:namazu_index')
      let g:namazu_index = input('Namazu index directory: ')
   endif
   if !exists('g:namazu_cmd')
      let g:namazu_cmd = 'namazu'
   endif
   if !exists('g:namazu_range')
      let g:namazu_range = 30
   endif
   if !exists('g:namazu_color')
      let g:namazu_color = 1
   endif

   let s:namazu_index = g:namazu_index
   let s:namazu_range = g:namazu_range
   let s:namazu_cmd   = g:namazu_cmd
endfun

command! Namazu call s:NamazuMain()


" Vim syntax file
" Language: Pongo Assembly
" Maintainer: Your Name
" Latest Revision: 2025-10-14

if exists("b:current_syntax")
  finish
endif

" Comments - inline comments starting with semicolon
syn match pongoComment ";.*$" contains=pongoTodo
syn keyword pongoTodo		FIXME NOTE NOTES TODO XXX contained

" Preprocessor directives - statements beginning with !
syn match pongoPreProc "!\w\+"

" Labels - identifiers followed by colon (bold white)
syn match pongoLabel "^\s*\w\+:"

" Strings - quoted strings
syn region pongoString start='"' end='"' skip='\\"' contains=pongoEscape
syn region pongoString start="'" end="'" skip="\\'" contains=pongoEscape

" (copied from python)
syn match   pongoEscape	+\\[abfnrtv'"\\]+ contained
syn match   pongoEscape	"\\\o\{1,3}" contained
syn match   pongoEscape	"\\x\x\{2}" contained
syn match   pongoEscape	"\%(\\u\x\{4}\|\\U\x\{8}\)" contained
syn match   pongoEscape	"\\N{\a\+\%(\s\a\+\)*}" contained
syn match   pongoEscape	"\\$"

" Number constants (i'm so sorry)
syn match pongoNumber "[#]\=\(\(0[xX]\|\$\)[0-9a-fA-F]\+\|0[bB][01]\+\|[0-9]\+\)"
syn match pongoNumber "[#]"

" Operators and special characters
syn match pongoOperator "[-+*/>?]"
syn match pongoOperator "?>"

" Registers and identifiers (common ones from your example)
syn keyword pongoRegister IndiHi IndiLo IndirectUp IndirectDown UseIndirect
syn keyword pongoRegister IpHi IpLo
syn keyword pongoRegister LoopHi LoopLo LoopDown
syn keyword pongoRegister SixteenWide WaitForFrame InhibitIfZero
syn keyword pongoRegister Nand Flow

syn keyword pongoVirtReg Loop Ip Indi OpA OpB Add TmpA TmpB TmpC TmpD TmpE

" Indirection operator
syn match pongoIndirect "\*"

" Raw regions
syn region pongoRaw start='(' end=')' contains=pongoComment,pongoNumber,pongoIndirect

" Bitfields
syn region pongoBitfield start='#\[' end='\]' contains=pongoRegister


" Define highlighting
hi def link pongoComment Comment
hi def link pongoTodo Todo
hi def link pongoPreProc PreProc
hi def link pongoString String
hi def link pongoEscape Special
hi def link pongoNumber Number
hi def link pongoOperator Operator
hi def link pongoRegister Identifier
hi def link pongoVirtReg Underlined
hi def link pongoIndirect SpecialChar
hi def link pongoLabel Statement
hi def link pongoRaw Type
hi def link pongoBitfield Number

" Labels - bold white
"hi pongoLabel ctermfg=White cterm=bold guifg=White gui=bold

let b:current_syntax = "pongo"

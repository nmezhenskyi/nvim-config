if vim.b.current_syntax then
   return
end

vim.cmd([[
  syntax case match

  " Top-level directives (anchored to line start so module paths like .../go or .../tool aren't matched)
  syntax match gomodDirective /^\s*\zs\<\%(go\|toolchain\)\>\ze\s/ nextgroup=gomodGoVersion skipwhite
  syntax match gomodDirective /^\s*\zs\<\%(module\|require\|exclude\|replace\|retract\|tool\|ignore\)\>\ze\%(\s\|$\)/
  syntax match gomodGoVersion /\S\+/ contained

  " Semver versions (including pseudo-versions, pre-releases, and +incompatible)
  syntax match gomodVersion /\<v\d\+\.\d\+\.\d\+\%(-[0-9A-Za-z.-]\+\)\?\%(+[0-9A-Za-z.-]\+\)\?/

  " Operators, delimiters, strings, and comments
  syntax match gomodArrow /=>/
  syntax match gomodDelimiter /[()\[\],]/
  syntax region gomodString start=/"/ skip=/\\./ end=/"/
  syntax region gomodString start=/`/ end=/`/
  syntax match gomodIndirect /\/\/\s*\zsindirect\>/ contained
  syntax match gomodComment /\/\/.*$/ contains=gomodIndirect
]])

local links = {
   gomodDirective = "@keyword",
   gomodGoVersion = "Number",
   gomodVersion = "Constant",
   gomodArrow = "Operator",
   gomodDelimiter = "Delimiter",
   gomodString = "String",
   gomodComment = "Comment",
   gomodIndirect = "SpecialComment",
}

for group, target in pairs(links) do
   vim.api.nvim_set_hl(0, group, { default = true, link = target })
end

vim.b.current_syntax = "gomod"

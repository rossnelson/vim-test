if !exists('g:test#javascript#nx#file_pattern')
  let g:test#javascript#nx#file_pattern = '\v(__tests__/.*|(spec|test))\.(js|jsx|coffee|ts|tsx)$'
endif

function! test#javascript#nx#test_file(file) abort
  if a:file =~# g:test#javascript#nx#file_pattern
      if exists('g:test#javascript#runner')
          return g:test#javascript#runner ==# 'nx'
      else
        return test#javascript#has_package('nx')
      endif
  endif
endfunction

function! test#javascript#nx#build_position(type, position) abort
  let project = ''

  let l:project_json = findfile('project.json', '.;')

  if filereadable(project_json)
    let l:project_json_file = readfile(project_json)
    if exists('*json_decode')
      let project = json_decode(join(project_json_file, ''))['name']
    endif
  else
    let executable = test#javascript#nx#base_executable()
    let output = system(executable . ' show projects --json')

    if exists('*json_decode')
      let l:projects = json_decode(output)
      for p in l:projects
        if stridx(a:position['file'], p) >= 0
          let project = p
          break
        endif
      endfor
    endif
  endif

  if a:type ==# 'nearest'
    let name = s:nearest_test(a:position)
    if !empty(name)
      let name = '-t '.shellescape(name, 1)
    endif
    return [project, name, '--test-file', a:position['file']]
  elseif a:type ==# 'file'
    return [project, '--test-file', a:position['file']]
  else
    return [project]
  endif
endfunction

let s:yarn_command = '\<yarn\>'
function! test#javascript#nx#build_args(args) abort
  if exists('g:test#javascript#nx#executable')
    \ && g:test#javascript#nx#executable =~# s:yarn_command
    return filter(a:args, 'v:val != "--"')
  else
    return a:args
  endif
endfunction

function! test#javascript#nx#base_executable() abort
  if filereadable('node_modules/.bin/nx')
    return 'node_modules/.bin/nx'
  else
    return 'nx'
  endif
endfunction

function! test#javascript#nx#executable() abort
  let base = test#javascript#nx#base_executable()

  if exists('g:test#javascript#nx#project')
    return base . ' test ' . g:test#javascript#nx#project
  endif

  return base . ' test '
endfunction

function! s:nearest_test(position) abort
  let name = test#base#nearest_test(a:position, g:test#javascript#patterns)
  return (len(name['namespace']) ? '^' : '') .
       \ test#base#escape_regex(join(name['namespace'] + name['test'])) .
       \ (len(name['test']) ? '$' : '')
endfunction

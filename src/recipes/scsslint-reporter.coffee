path = require('path')
chalk = require('chalk')
_ = require('lodash')

exports = module.exports = ({relativePath}={relativePath:'.'}) ->
  (file) ->
   if !file.scsslint.success
     severity =
       warning:
         icon: '  ⚠  '
         style: chalk.yellow
       error:
         icon: '  ✖  '
         style: chalk.red
     sevGroups = _.groupBy file.scsslint.issues, 'severity'

     console.log chalk.underline path.relative(relativePath, file.path)

     for issue in file.scsslint.issues
       sev = severity[issue.severity]
       console.log chalk.gray "#{sev.icon}line #{issue.line}  #{chalk.blue issue.linter}  #{chalk.gray issue.reason}"

     for group, issues of sevGroups
       sev = severity[group]
       console.log sev.style "\n#{sev.icon.trim()} #{issues.length} #{group}#{if issues.length > 1 then 's' else ''}\n"

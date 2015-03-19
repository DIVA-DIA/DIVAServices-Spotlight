fs = require('fs')
chalk = require('chalk')
Q = require('q')

ResultJsonOutputFileReader = ->

  _readFile = (fileName) ->
    deferred = Q.defer()
    fs.readFile fileName, 'utf8', (err, data) ->
      if err
        deferred.reject new Error(err)
      else
        deferred.resolve JSON.parse(data)
      return
    deferred.promise

  _getTestBody = (test) ->
    if test.passed then '  ' + chalk.green('ok') else '  ' + chalk.red(test.errorMsg) + '\n  ' + chalk.gray(test.stackTrace)

  _getTests = (title, tests) ->
    tests.reduce ((output, test) ->
      output + _getTestBody(test)
    ), title + '\n'

  _getScenarioTitle = (scenario) ->
    chalk.bold(scenario.description) + chalk.gray(' (' + scenario.duration + 'ms)')

  _getScenarios = (scenarios) ->
    scenarios.reduce ((output, scenario) ->
      output + _getTests(_getScenarioTitle(scenario), scenario.assertions) + '\n\n'
    ), '\n'

  _getLog = (filePath) ->
    deferred = Q.defer()
    _readFile(filePath).then (scenarios) ->
      deferred.resolve _getScenarios(scenarios)
      return
    deferred.promise

  {
    getLog: _getLog
    getLogFromJSON: (json) ->
      _getScenarios json
    printLog: (filePath) ->
      _getLog(filePath).then (data) ->
        console.log data
        return
      return
    printFromJson: (json) ->
      console.log _getScenarios(json)
      return

  }

module.exports = new ResultJsonOutputFileReader

# ---
# generated by js2coffee 2.0.1
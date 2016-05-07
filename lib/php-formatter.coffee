PhpFormatterView = require './php-formatter-view'
{CompositeDisposable} = require 'atom'
child_process = require 'child_process'

module.exports = PhpFormatter =
  phpFormatterView: null
  modalPanel: null
  subscriptions: null

  config:
    phpDir:
      type: 'string'
      default: 'C:\\php'
      title: 'PHP Dir Path'
    phpCsFixerDir:
      type: 'string'
      default: 'C:\\php\\php-cs-fixer.phar'
      title: 'php-cs-fixer Path'
    phpcbfDir:
      type: 'string'
      default: 'C:\\php\\phpcbf.phar'
      title: 'phpcbf Path'

  activate: (state) ->
    @phpFormatterView = new PhpFormatterView(state.phpFormatterViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @phpFormatterView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'php-formatter:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @phpFormatterView.destroy()

  serialize: ->
    phpFormatterViewState: @phpFormatterView.serialize()

  toggle: ->
    editor = atom.workspace.getActiveTextEditor();

    # phpdir = "D:\\php"
    phpdir = atom.config.get('php-formatter.phpDir')
    fixerPath = atom.config.get('php-formatter.phpCsFixerDir') + " fix "
    phpcbfPath = atom.config.get('php-formatter.phpcbfDir') + " --no-patch "
    tmpPath = phpdir + "\\" + editor.getTitle()
    phpPath = phpdir + "\\php"

    if /.*\.php/.test(tmpPath)
      fs = require "fs"
      # 編集内容を一時ファイルに保存
      fs.writeFile tmpPath, editor.getText(), (error) -> console.error("Error writing file", error) if error

      child_process.exec(phpPath + " " + phpcbfPath + tmpPath, null, (error, stdout, stderr) ->
        console.error(error) if error
        console.error(stderr) if stderr

        child_process.exec(phpPath + " " + fixerPath + tmpPath, null, (error, stdout, stderr) ->
          console.error(error) if error
          console.error(stderr) if stderr

          fs = require "fs"
          fs.readFile tmpPath, 'utf8', (error, data) ->
            console.error(error) if error
            editor.setText(data)
            # 後処理
            fs.unlink tmpPath, (error) -> console.error("Error delete file", error) if error
      ))
    else
      editorElement = atom.views.getView(editor)
      atom.commands.dispatch editorElement, 'atom-beautify:beautify-editor'

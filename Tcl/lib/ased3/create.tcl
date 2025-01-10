#create.tcl

package require msgcat

proc Editor::createFonts {} {
    global EditorData
    
    variable configError
    variable Font_var
    variable FontSize_var
    
    catch {font create nbFrameFont -size 8}
    font create "Code" \
            -size $EditorData(options,fontSize)\
            -family $EditorData(options,fontFamily)
    set EditorData(options,fonts,editorFont) "Code"
    return
}

proc Editor::setDefault {} {
    global tcl_platform
    global EditorData
    global ASEDsRootDir
    variable current
    variable configError
    variable toolbar1
    variable toolbar2
    variable showConsoleWindow
    variable showProcWindow
    variable sortProcs
    variable showProc
    variable checkNestedProc
    variable options
    variable lineNo
    variable toolbarButtons
    
    set current(is_procline) 0; #is needed for checkProcs
    set current(procLine) 0
    set current(autoUpdate) 1
    set current(procSelectionChanged) 0
    set current(procListHistoryPos) 0
    set current(procListHistory) [list "mark1"]
    set current(procList_hist_maxLength) 20
    set current(lastPos) "1.0"
    set current(isNode) 0
    set current(checkRootNode) 0
    set current(isUpdate) 0
    # next is used to mask tk_getOpenFile button-release-event
    set EditorData(getFileMode) 0
    
    # set keywords 
    set fd [open [file join $ASEDsRootDir keywords.txt ] r]
    set keyList ""
    while {![eof $fd]} {
        gets $fd word
        lappend keyList $word
    }
    close $fd

    set EditorData(keywords) $keyList
    set EditorData(files) {}
    set EditorData(curFile) ""
    set EditorData(find) {}
    set EditorData(find,lastOptions) ""
    set EditorData(replace) {}
    set EditorData(projectFile) ""
    set EditorData(cursor,line) 1
    set EditorData(cursor,pos) 0
    set EditorData(cursorPos) "Line: 1   Pos: 0"
    set Editor::lineNo $EditorData(cursor,line)
    
    set locale [msgcat::mclocale]
    if {$locale == ""} {
        set locale "default"
    }
    
    if $configError {
        set EditorData(options,sessionList) {}
        set options(sessionList) {}
        set EditorData(options,useEvalServer) 1
        set options(useEvalServer) 1
        set EditorData(options,serverPort) 9001
        set options(serverPort) 9001
        if {$EditorData(starkit)} {
            set EditorData(options,serverWish) {}
            set options(serverWish) {}
        } else {
            set EditorData(options,serverWish) [list [info nameofexecutable]]
            set options(serverWish) [list [info nameofexecutable]]
        }
        set EditorData(options,useIndent) 1
        set options(useIndent) 1
        set EditorData(options,useSyntaxIndent) 1
        set options(useSI) 1
        # set EditorData(options,indentSize) 4
        set EditorData(options,changeTabs) 1
        set options(changeTabs) 1
        set EditorData(options,tabSize) 4
        set EditorData(options,useHL) 1
        set options(useHL) 1
        set EditorData(options,useTemplates) 1
        set options(useTemplates) 1
        set EditorData(options,useTemplatesForKeywords) 1
        set options(useKeywordTemplates) 1
        set EditorData(options,useTemplatesForBrace) 1
        set options(useBracesTemplates) 1
        set EditorData(options,useTemplatesForParen) 1
        set options(useParenTemplates) 1
        set EditorData(options,useTemplatesForBracket) 1
        set options(useBracketTemplates) 1
        set EditorData(options,useTemplatesForQuoteDbl) 1
        set options(useQuotesTemplates) 1
        set EditorData(options,showToolbar1) 1
        set EditorData(options,showToolbar2) 0
        set options(showConsole) 1
        set EditorData(options,showConsole) $showConsoleWindow
        set options(showProcs) 1
        set EditorData(options,showProcs) $showProcWindow
        set options(sortProcs) 1
        set EditorData(options,sortProcs) $sortProcs
        set options(autoUpdate) 1
        set EditorData(options,autoUpdate) 1
        set options(showProc) 1
        set EditorData(options,showProc) $showProc
        set options(defaultProjectFile) "none"
        set EditorData(options,defaultProjectFile) "none"
        set current(project) "none"
        set options(workingDir) "~"
        set EditorData(options,workingDir) "~"
        set options(showSolelyConsole) 0
        set EditorData(options,showSolelyConsole) 0
        set options(useDefaultExtension) 1
        set EditorData(options,useDefaultExtension) 1
        set EditorData(options,language) $locale
        set options(language) $locale
        set EditorData(options,restoreSession) 1
        set options(restoreSession) 1
        set EditorData(options,showLineNo) 1
        set options(showLineNo) 1
        set EditorData(options,defaultmode) "tcl"
        set options(defaultmode) "tcl"
        set EditorData(options,endOfLineMode) "lf"
        set options(endOfLineMode) "ls"
        set EditorData(options,zoomed) 0
        set options(zoomed) 0
        set EditorData(options,skipCheck) 0
        set options(skipCheck) 0
        set EditorData(options,skipWarnings) 0
        set options(skipWarnings) 0
        set EditorData(options,skipVarWarnings) 0
        set options(skipVarWarnings) 0
        set EditorData(options,createBackupFiles) 1
        set options(createBackupFiles) 1
    } else {
        set toolbar1 $EditorData(options,showToolbar1)
        set toolbar2 $EditorData(options,showToolbar2)
        set options(useEvalServer) $EditorData(options,useEvalServer)
        set options(serverPort) $EditorData(options,serverPort)
        set options(useIndent) $EditorData(options,useIndent)
        set options(useSI) $EditorData(options,useSyntaxIndent)
        set options(useHL) $EditorData(options,useHL)
        set options(useTemplates) $EditorData(options,useTemplates)
        set options(useKeywordTemplates) $EditorData(options,useTemplatesForKeywords)
        set options(useBracesTemplates) $EditorData(options,useTemplatesForBrace)
        set options(useParenTemplates) $EditorData(options,useTemplatesForParen)
        set options(useBracketTemplates) $EditorData(options,useTemplatesForBracket)
        set options(useQuotesTemplates) $EditorData(options,useTemplatesForQuoteDbl)
        set options(changeTabs) $EditorData(options,changeTabs)
        set options(tabSize) $EditorData(options,tabSize)
        set options(showConsole) $EditorData(options,showConsole)
        set options(showProcs) $EditorData(options,showProcs)
        set options(showProc) $EditorData(options,showProc)
        set options(autoUpdate) $EditorData(options,autoUpdate)
        set options(sortProcs) $EditorData(options,sortProcs)
        set options(defaultProjectFile) $EditorData(options,defaultProjectFile)
        set current(project) $EditorData(options,defaultProjectFile)
        set options(workingDir) $EditorData(options,workingDir)
        set options(showSolelyConsole) $EditorData(options,showSolelyConsole)
        set options(serverWish) $EditorData(options,serverWish)
        set options(useDefaultExtension) $EditorData(options,useDefaultExtension)
        set options(language) $EditorData(options,language)
        set options(restoreSession) $EditorData(options,restoreSession)
        set options(sessionList) $EditorData(options,sessionList)
        set options(showLineNo) $EditorData(options,showLineNo)
        set options(defaultmode) $EditorData(options,defaultmode)
        set options(endOfLineMode) $EditorData(options,endOfLineMode)
        set options(zoomed) $EditorData(options,zoomed)
        set options(skipCheck) $EditorData(options,skipCheck)
        set options(skipWarnings) $EditorData(options,skipWarnings)
        set options(skipVarWarnings) $EditorData(options,skipVarWarnings)
        set options(createBackupFiles) $EditorData(options,createBackupFiles)
    }
    
    set EditorData(indentString) ""
    if {$EditorData(options,changeTabs)} {
        for {set i 0} {$i < $EditorData(options,tabSize)} {incr i} {
            append EditorData(indentString) " "
        }
    } else {
        append EditorData(indentString) "\t"
    }
    return
}

proc Editor::call_tk_popup {menu x y args} {
    catch {Editor::tselectObject $args}
    tk_popup $menu $x $y
}

proc Editor::NotebookPages {filename} {
    global notebook_pages
    
    return $notebook_pages($filename)
}

proc Editor::create { } {
    global tcl_platform
    global clock_var
    global EditorData
    global ASEDsRootDir
    global asedMacros
    global langArray
    global conWindow
    global mainConsole
    
    variable _wfont
    variable notebook
    variable list_notebook
    variable con_notebook
    variable pw2
    variable pw1
    variable procWindow
    variable treeWindow
    variable markWindow
    variable mainframe
    variable font
    variable prgtext
    variable prgindic
    variable status
    variable search_combo
    variable argument_combo
    variable current
    variable clock_label
    variable defaultFile
    variable defaultProjectFile
    variable Font_var
    variable FontSize_var
    variable options
    variable configError
    variable toolbarButtons
    variable treeMenu
    variable textMenu
    variable mainMenu
    
    # set default values
    if {$tcl_platform(platform) == "windows"} {
        set EditorData(options,fontSize) 10
        set EditorData(options,fontFamily) "Courier"
    } else {
        set EditorData(options,fontSize) 0
        set EditorData(options,fontFamily) {}
    }
    set configError 1
    Editor::setDefault
    
    # overwrite with values from config-file
    set configFile [file join "~" ased.cfg]
    if {[file exists $configFile]} {
        set result [catch {source [file join "~" ased.cfg]} info]
        if {$result} {
            # reading failed, nothing to do
        } else {
            # set options
            set configError 0
            Editor::setDefault
        }
    }
    set ctext::highlightOn $EditorData(options,useHL)
    load_languageFile $EditorData(options,language)
    Editor::createFonts
    # _create_intro
    # update
    
    Editor::load_search_defaults
    Editor::tick
    Editor::createMainMenu
    Editor::createPopMenuTreeWindow
    Editor::createPopMenuEditorWindow
    
    set Editor::prgindic -1
    set Editor::status ""
    set mainframe [MainFrame::create .mainframe \
            -menu $Editor::mainMenu \
            -textvariable Editor::status \
            -progressvar  Editor::prgindic \
            -progressmax 100 \
            -progresstype normal \
            -progressfg blue]
    $mainframe showstatusbar progression
    
    Editor::createMainToolbar
    Editor::createFontToolbar
    
    
    # set statusbar indicator for file-directory clock and Line/Pos
    set temp [MainFrame::addindicator $mainframe -text [tr "Current Startfile: "] ]
    set temp [MainFrame::addindicator $mainframe -textvariable Editor::current(project) ]
    set temp [MainFrame::addindicator $mainframe -text [tr " File: "] ]
    set temp [MainFrame::addindicator $mainframe -textvariable Editor::current(file) ]
    set temp [MainFrame::addindicator $mainframe -textvariable EditorData(cursorPos)]
    set temp [MainFrame::addindicator $mainframe -textvariable clock_var]
    
    # NoteBook creation
    
    set frame    [$mainframe getframe]
    
    set pw1 [panedwindow $frame.pw -orient vertical]
    set pw2 [panedwindow $pw1.pw -orient horizontal]
    
    set list_notebook [NoteBook $pw2.nb1 -internalborderwidth 1]
    set notebook [NoteBook $pw2.nb2 -internalborderwidth 1]
    set con_notebook [NoteBook $pw1.nb -internalborderwidth 1]
    set pf1 [EditManager::create_treeWindow $list_notebook]
    set treeWindow $pf1.sw.objTree
    
    # Binding on tree widget
    $treeWindow bindText <ButtonRelease-1> Editor::tselectObject
    $treeWindow bindImage <ButtonRelease-1> Editor::tselectObject
    $treeWindow bindText <ButtonPress-3> {Editor::call_tk_popup $Editor::treeMenu %X %Y}
    $treeWindow bindImage <ButtonPress-3> {Editor::call_tk_popup $Editor::treeMenu %X %Y}
    
    set f0 [EditManager::create_text $notebook [tr "Untitled"]]
    
    NoteBook::compute_size $list_notebook
    
    NoteBook::compute_size $notebook
    
    set cf0 [EditManager::create_conWindow $con_notebook]
    set mainConsole $conWindow
    NoteBook::compute_size $con_notebook
    $pw1 add $pw2 -sticky news
    $pw1 add $con_notebook -minsize 100 -sticky news
    $pw2 add $list_notebook -minsize 250 -sticky news
    $pw2 add $notebook -minsize 300 -sticky news
    pack $pw1 -fill both -expand yes
    
    $list_notebook raise objtree
    $con_notebook raise asedCon
    $notebook raise [lindex $f0 1]
    
    pack $mainframe -fill both -expand yes
    
    update
    # destroy .intro
    wm protocol . WM_DELETE_WINDOW Editor::exit_app
    
    if {!$configError} {
        Editor::restoreWindowPositions
    } else {
        wm geometry . 790x590
        wm deiconify .
        tkwait visibility .
        update idletasks
        catch {
            $pw1 sash place 0 [lindex [$pw1 sash coord 0] 0] 350
        }
        catch {
            $pw2 sash place 0 200 [lindex [$pw2 sash coord 0] 1]
        }
        ::tk::PlaceWindow . center
    }
}

proc Editor::createMainMenu {} {
    # Menu description
    set Editor::mainMenu [list \
            [tr File] {} {} 0 [list \
            [list command [tr New] {} [tr "New File"] {} -command Editor::newFile] \
            [list command [tr Open] {} [tr "Open File"] {Ctrl o} -command Editor::openFile] \
            [list command [tr Save] {noFile}  [tr "Save active File"] {Ctrl s} -command Editor::saveFile] \
            [list command [tr "Save &as ..."] {noFile}  [tr "Save active File as .."] {} -command Editor::saveFileas] \
            [list command [tr "Save all"] {noFile}  [tr "Save all Files"] {} -command Editor::saveAll] \
            [list command [tr "Close"] {noFile} [tr "Close active File"] {} -command Editor::closeFile ] \
            {separator} \
            [list command [tr "E&xit"] {}  [tr "Exit ASED"] {Alt x} -command Editor::exit_app] \
            ]\
            [tr "&Edit"] {noFile} {} 0 [list \
            [list command [tr "Copy"] {} [tr "Copy to Clipboard"] {Ctrl c} -command Editor::copy ]\
            [list command [tr "Cut"] {} [tr "Cut to Clipboard"] {Ctrl x} -command Editor::cut ]\
            [list command [tr "Paste"] {} [tr "Paste from Clipboard"] {Ctrl v} -command Editor::paste ]\
            [list command [tr "Delete"] {} [tr "Delete Selection"] {} -command Editor::delete ]\
            [list command [tr "Delete Line"] {} [tr "Delete current line"] {} -command {Editor::delLine ; break} ]\
            {separator}\
            [list command [tr "Select all"] {} [tr "Select All"] {} -command Editor::SelectAll ]\
            {separator}\
            [list command [tr "Insert File ..."] {} [tr "Insert file at current cursor position"] {} -command Editor::insertFile ]\
            {separator}\
            [list command [tr "Goto Line ..."] {} [tr "Goto Line"] {} -command Editor::gotoLineDlg ]\
            {separator}\
            [list command [tr "Search ..."] {} [tr "Search dialog"] {} -command Editor::search_dialog ]\
            [list command [tr "Search in files ..."] {} [tr "Search in files"] {} -command Editor::findInFiles]\
            [list command [tr "Replace ..."] {} [tr "Replace dialog"] {} -command Editor::replace_dialog ]\
            {separator}\
            [list command [tr "Undo"] {} [tr "Undo"] {CtrlAlt u} -command Editor::undo ]\
            [list command [tr "Redo"] {} [tr "Redo"] {} -command Editor::redo ]\
            {separator}\
            [list command [tr "AutoIndent File"] {} [tr "AutoIndent current file"] {} -command editorWindows::autoIndent]\
            ]\
            [tr "&Test"] {} {} 0 [list \
            [list command [tr "Check Syntax"] {noFile} [tr "Check Syntax of current File"] {} -command Editor::checkSyntax ]\
            [list command [tr "Run"] {noFile} [tr "Test current File"] {CtrlAlt r} -command Editor::execFile ]\
            [list command [tr "Stop"] {noFile} [tr "Terminate Execution of current File"] {CtrlAlt s} -command Editor::terminate  ]\
            {separator}\
            [list command [tr "Set Default Startfile..."] {} [tr "Set Default Startfile"] {} -command Editor::setDefaultProject ]\
            [list command [tr "Unset Default Startfile"] {} [tr "Unset Default Startfile"] {} -command {Editor::setDefaultProject "none"} ]\
            {separator}\
            [list command [tr "Set Startfile for current file..."] {noFile} [tr "Associate a Startfile to the current File"] {} -command Editor::associateProject ]\
            [list command [tr "Unset Startfile for current file..."] {noFile} [tr "Clear current Startfile Association"] {} -command Editor::unsetProjectAssociation ]\
            {separator}\
            [list checkbutton [tr "Use EvalServer"] {all option} [tr "Use EvalServer for Testing Apps"] {} \
            -variable Editor::options(useEvalServer) \
            -command  {set EditorData(options,useEvalServer) $Editor::options(useEvalServer)}\
            ]\
            [list command [tr "Change Serverport ..."] {} [tr "Change Port for EvalServer"] {} -command {Editor::changeServerPort} ]\
            [list command [tr "Choose Interpreter ..."] {} [tr "Choose Interpreter for EvalServer"] {} -command {Editor::chooseWish} ]\
            [list checkbutton [tr "Skip Syntaxcheck"] {all option} [tr "Eval code without prior syntaxcheck"] {} \
            -variable Editor::options(skipCheck) \
            -command  {set EditorData(options,skipCheck) $Editor::options(skipCheck)}\
            ]\
            [list checkbutton [tr "Skip variable Warnings"] {all option} [tr "Syntaxcheck should not report Warnings regarding variables"] {} \
            -variable Editor::options(skipVarWarnings) \
            -command  {set EditorData(options,skipVarWarnings) $Editor::options(skipVarWarnings)}\
            ]\
            [list checkbutton [tr "Skip all Warnings"] {all option} [tr "Syntaxcheck should only report Errors"] {} \
            -variable Editor::options(skipWarnings) \
            -command  {set EditorData(options,skipWarnings) $Editor::options(skipWarnings)}\
            ]\
            ]\
            [tr "&Options"] all options 0 [list \
            [list checkbutton [tr "Sort Code Browser Tree"] {all option} [tr "Sort Treenodes in Code Browser"] {} \
            -variable Editor::options(sortProcs) \
            -command  {set editorData(options,sortProcs) $Editor::options(sortProcs)
                Editor::toggleTreeOrder} \
            ]\
            [list checkbutton [tr "Highlight current node"] {all option} [tr "Highlight current node in Code Browser"] {} \
            -variable Editor::options(showProc) \
            -command  {set EditorData(options,showProc) $Editor::options(showProc)
                catch {Editor::selectObject 0}} \
            ]\
            [list checkbutton [tr "Auto Update"] {all option} [tr "Automatic Code Browser Update"] {} \
            -variable Editor::options(autoUpdate) \
            -command  {set EditorData(options,autoUpdate) $Editor::options(autoUpdate)
                catch {Editor::updateObjects}} \
            ]\
            {separator}\
            [list checkbutton [tr "Syntax &Highlighting"] {all option} [tr "Use Keyword Highlighting"] {} \
            -variable Editor::options(useHL) \
            -command  {
                set EditorData(options,useHL) $Editor::options(useHL)
                set ctext::highlightOn $EditorData(options,useHL)
                if {$EditorData(options,useHL)} {
                    set mode [string trimleft [string tolower [file extension $Editor::current(file)]] .]
                    if {$mode == ""} {
                        set mode $EditorData(options,defaultmode)
                    }
                    if {[info exists EditorData($mode)]} {
                        set Editor::text_win($Editor::index_counter,mode) $mode
                        # Editor::mode_$mode $text
                    } else {
                        set modefile [file join $ASEDsRootDir highlighters $mode.mode]
                        if {[file exists $modefile]} {
                            source $modefile
                            # Editor::mode_$mode $text
                            set EditorData($mode) 1
                            set Editor::text_win($Editor::index_counter,mode) $mode
                        }
                    }
                    if {($EditorData(options,useHL) == 1 ) && ($Editor::text_win($Editor::index_counter,mode) != "")} {
                        ::Editor::mode_$Editor::text_win($Editor::index_counter,mode) $Editor::current(text)
                    }
                    catch editorWindows::colorize
                } else {
                    foreach tag [$editorWindows::TxtWidget tag names] {
                        $editorWindows::TxtWidget tag remove $tag "1.0" "end-1c"
                    }
                }
                
            } \
            ]\
            [list checkbutton [tr "&Indent"] {all option} [tr "Use Indent"] {} \
            -variable Editor::options(useIndent) \
            -command  {set EditorData(options,useIndent) $Editor::options(useIndent) } \
            ]\
            [list checkbutton [tr "&SyntaxIndent"] {all option} [tr "Use Syntax Indent"] {} \
            -variable Editor::options(useSI) \
            -command  {set EditorData(options,useSyntaxIndent) $Editor::options(useSI) }\
            ]\
            [list checkbutton [tr "Auto Completion for Keywords"] {all option} [tr "Use Templates for Keywords"] {} \
            -variable Editor::options(useKeywordTemplates) \
            -command  {set EditorData(options,useTemplatesForKeywords) $Editor::options(useKeywordTemplates) }\
            ]\
            [list checkbutton [tr "Auto Completion for \{"] {all option} [tr "Use Templates for Braces"] {} \
            -variable Editor::options(useBracesTemplates) \
            -command  {set EditorData(options,useTemplatesForBrace) $Editor::options(useBracesTemplates) }\
            ]\
            [list checkbutton [tr "Auto Completion for \("] {all option} [tr "Use Templates for Paren"] {} \
            -variable Editor::options(useParenTemplates) \
            -command  {set EditorData(options,useTemplatesForParen) $Editor::options(useParenTemplates) }\
            ]\
            [list checkbutton [tr "Auto Completion for \["] {all option} [tr "Use Templates for Bracket"] {}\
            -variable Editor::options(useBracketTemplates) \
            -command  {set EditorData(options,useTemplatesForBracket) $Editor::options(useBracketTemplates) }\
            ]\
            [list checkbutton [tr "Auto Completion for \""] {all option} [tr "Use Templates for DblQuotes"] {} \
            -variable Editor::options(useQuotesTemplates) \
            -command  {set EditorData(options,useTemplatesForQuoteDbl) $Editor::options(useQuotesTemplates) }\
            ]\
            {separator}\
            [list checkbutton [tr "Change tabs into spaces"] {all option} [tr "Change tabs into spaces"] {} \
            -variable Editor::options(changeTabs) \
            -command  {set EditorData(options,changeTabs) $Editor::options(changeTabs) ; Editor::changeTabs}\
            ]\
            [list command [tr "Change Tab Size ..."] {} [tr "Change Tab Size"] {} -command {Editor::changeTabSize} ]\
            [list checkbutton [tr "Use Default Extension"] {all option} [tr "Use Default Extension \".tcl\""] {} \
            -variable Editor::options(useDefaultExtension) \
            -command  {set EditorData(options,useDefaultExtension) $Editor::options(useDefaultExtension) }\
            ]\
            {separator}\
            [list checkbutton [tr "Create Backup Files"] {all option} [tr "Create Backup Files"] {} \
            -variable Editor::options(createBackupFiles) \
            -command  {set EditorData(options,createBackupFiles) $Editor::options(createBackupFiles) }\
            ]\
            [list checkbutton [tr "Save/Restore Session"] {all option} [tr "Save/Restore Session"] {} \
            -variable Editor::options(restoreSession) \
            -command  {set EditorData(options,restoreSession) $Editor::options(restoreSession) }\
            ]\
            {separator}\
            [list command [tr "Choose Language"] {} [tr "Choose Language"] {} -command {Editor::chooseLanguage} ]\
            ] \
            [tr "&View"] all options 0 [list \
            [list checkbutton [tr "Main Toolbar"] {all option} [tr "Show/hide Main Toolbar"] {} \
            -variable Editor::toolbar1 \
            -command  {$Editor::mainframe showtoolbar 0 $Editor::toolbar1
                set EditorData(options,showToolbar1) $Editor::toolbar1
            }\
            ]\
            [list checkbutton [tr "&Font Toolbar"] {all option} [tr "Show/hide Font Toolbar"] {} \
            -variable Editor::toolbar2 \
            -command  {$Editor::mainframe showtoolbar 1 $Editor::toolbar2
                set EditorData(options,showToolbar2) $Editor::toolbar2} \
            ]\
            {separator}\
            [list command [tr "Increase Fontsize"] {} [tr "Increase Fontsize"] {} -command {Editor::increaseFontSize up} ]\
            [list command [tr "Decrease Fontsize"] {} [tr "Decrease Fontsize"] {} -command {Editor::increaseFontSize down} ]\
            {separator}\
            [list checkbutton [tr "Show Console"] {all option} [tr "Show Console Window"] {} \
            -variable Editor::options(showConsole) \
            -command  {set EditorData(options,showConsole) $Editor::options(showConsole)
                Editor::showConsole $EditorData(options,showConsole)
                update idletasks
                catch {$Editor::current(text) see insert}
            } \
            ]\
            [list checkbutton [tr "Show Code Browser"] {all option} [tr "Show Code Browser"] {} \
            -variable Editor::options(showProcs) \
            -command  {set EditorData(options,showProcs) $Editor::options(showProcs)
                Editor::showTreeWin $EditorData(options,showProcs)
                update idletasks
                catch {$Editor::current(text) see insert}
            } \
            ]\
            [list checkbutton [tr "Solely Console"] {all option} [tr "Only Console Window"] {} \
            -variable Editor::options(solelyConsole) \
            -command  {set EditorData(options,solelyConsole) $Editor::options(solelyConsole)
                Editor::showSolelyConsole $EditorData(options,solelyConsole)
                update idletasks
            }\
            ]\
            ]\
            [tr "&Help"] {} {} 0 [list \
            [list command [tr "About"] {} [tr "About"] {} -command Editor::aboutBox ]\
            ]
    ]
}

proc Editor::createPopMenuTreeWindow {{update 0}} {
    variable treeWindow
    
    if {$update == 0} {
        set Editor::treeMenu [menu .treemenu -tearoff 0]
    }
    
    $Editor::treeMenu delete 0 end
    
    $Editor::treeMenu add command -label [tr "copy"] \
            -command {
                set start [lindex [$Editor::treeWindow itemcget $Editor::current(node) -data] 2]
                set end [lindex [$Editor::treeWindow itemcget $Editor::current(node) -data] 3]
                set text [$Editor::current(text) get $start $end]
                editorWindows::flashRegion $start $end 500 lightgrey
                clipboard clear
                clipboard append $text
            }
    catch {
        if {[interp exists $Editor::current(slave)]} {
            $Editor::treeMenu add command -label [tr "exec proc"] \
                    -command {
                        set start [lindex [$Editor::treeWindow itemcget $Editor::current(node) -data] 2]
                        set end [lindex [$Editor::treeWindow itemcget $Editor::current(node) -data] 3]
                        set text [$Editor::current(text) get $start $end]
                        $Editor::current(slave) eval [list puts $Editor::current(sock) $text]
                    }
        }
    }
    $Editor::treeMenu add separator
    
    $Editor::treeMenu add command -label [tr "Top"] \
            -command {
                $Editor::current(text) mark set insert 1.0
                $Editor::current(text) see insert
            }
    $Editor::treeMenu add command -label [tr "Bottom"] \
            -command {
                $Editor::current(text) mark set insert end
                $Editor::current(text) see insert
            }
    $Editor::treeMenu add command -label [tr "Last Line"] \
            -command {
                if {$Editor::current(node) != ""} {
                    set markName $Editor::current(node)
                    append markName "_end_of_proc"
                    $Editor::current(text) mark set insert $markName
                    $Editor::current(text) see insert
                }
            }
    $Editor::treeMenu add separator
    $Editor::treeMenu add checkbutton -label [tr "sort tree"] \
            -variable Editor::options(sortProcs) \
            -command  {set editorData(options,sortProcs) $Editor::options(sortProcs)
                Editor::toggleTreeOrder}
    $Editor::treeMenu add separator
    $Editor::treeMenu add command -label [tr "update tree"] \
            -command {set cursor [. cget -cursor]
                . configure -cursor watch
                update
                set updateState $EditorData(options,autoUpdate)
                set EditorData(options,autoUpdate) 1
                Editor::updateObjects
                set EditorData(options,autoUpdate) $updateState
                . configure -cursor $cursor
                Editor::selectObject 0
                update
            }
}

proc Editor::createPopMenuEditorWindow {{update 0}} {
    
    if {$update == 0} {
        set Editor::textMenu [menu .textmenu -tearoff 0]
    }
    
    $Editor::textMenu delete 1 end
    
    $Editor::textMenu add command -label [tr "Cut"] -command Editor::cut
    $Editor::textMenu add command -label [tr "Copy"] -command Editor::copy
    $Editor::textMenu add command -label [tr "Paste"] -command Editor::paste
    $Editor::textMenu add separator
    $Editor::textMenu add command -label [tr "Undo"] -command Editor::undo
    $Editor::textMenu add command -label [tr "Redo"] -command Editor::redo
    $Editor::textMenu add separator
    $Editor::textMenu add command -label [tr "Collaps selection"] -command  {$Editor::current(text) collaps}
    $Editor::textMenu add command -label [tr "Expand all"] -command  {$Editor::current(text) expandall}
    $Editor::textMenu add command -label [tr "Auto Indent Selection"] -command editorWindows::autoIndent
    $Editor::textMenu add separator
    $Editor::textMenu add checkbutton -label [tr "Auto Update"] \
            -variable Editor::options(autoUpdate) \
            -command  {
                set EditorData(options,autoUpdate) $Editor::options(autoUpdate)
                set EditorData(options,showProc) $Editor::options(autoUpdate)
                set Editor::options(showProc) $Editor::options(autoUpdate)
                catch {
                    if {$Editor::options(autoUpdate)} {
                        Editor::updateObjects
                    }
                }
            }
    $Editor::textMenu add checkbutton -label [tr "Show Console"] \
            -variable Editor::options(showConsole) \
            -command  {
                set EditorData(options,showConsole) $Editor::options(showConsole)
                Editor::showConsole $EditorData(options,showConsole)
                update idletasks
                catch {$Editor::current(text) see insert}
            }
    $Editor::textMenu add checkbutton -label [tr "Show Code Browser"] \
            -variable Editor::options(showProcs) \
            -command  {
                set EditorData(options,showProcs) $Editor::options(showProcs)
                Editor::showTreeWin $EditorData(options,showProcs)
                update idletasks
                catch {$Editor::current(text) see insert}
            }
    $Editor::textMenu add checkbutton -label [tr "Solely Console"] \
            -variable Editor::options(solelyConsole) \
            -command  {
                set EditorData(options,solelyConsole) $Editor::options(solelyConsole)
                Editor::showSolelyConsole $EditorData(options,solelyConsole)
                update idletasks
            }
    
}

proc Editor::createMainToolbar {{update 0}} {
    global   images
    variable mainframe
    variable search_combo
    variable argument_combo
    variable current
    variable toolbarButtons
    variable tb1
    variable argument_var
    
    # toolbar 1 creation
    if {$update == 0} {
        set tb1  [MainFrame::addtoolbar $mainframe]
    }
    set bbox [ButtonBox::create $tb1.bbox1 -spacing 0 -padx 1 -pady 1]
    set toolbarButtons(new) [ButtonBox::add $bbox -image $images(new) \
        -takefocus 0 -relief link \
        -helptext [tr "Create a new file"] -command Editor::newFile ]
    set toolbarButtons(open) [ButtonBox::add $bbox -image $images(open) \
        -takefocus 0 -relief link \
        -helptext [tr "Open an existing file"] -command Editor::openFile ]
    set toolbarButtons(save) [ButtonBox::add $bbox -image $images(save) \
        -takefocus 0 -relief link \
        -helptext [tr "Save file"] -command Editor::saveFile]
    set toolbarButtons(saveAll) [ButtonBox::add $bbox -image $images(saveAll) \
        -takefocus 0 -relief link \
        -helptext [tr "Save all files"] -command Editor::saveAll]
    set toolbarButtons(close) [ButtonBox::add $bbox -image $images(delete) \
        -takefocus 0 -relief link \
        -helptext [tr "Close File"] -command Editor::closeFile]
    
    pack $bbox -side left -anchor w
    
    set sep0 [Separator::create $tb1.sep0 -orient vertical]
    pack $sep0 -side left -fill y -padx 4 -anchor w
    
    set bbox [ButtonBox::create $tb1.bbox2 -spacing 0 -padx 1 -pady 1]
    set toolbarButtons(cut) [ButtonBox::add $bbox -image $images(cut) \
        -takefocus 0 -relief link \
        -helptext [tr "Cut selection"] -command Editor::cut]
    set toolbarButtons(copy) [ButtonBox::add $bbox -image $images(copy) \
        -takefocus 0 -relief link \
        -helptext [tr "Copy selection"] -command Editor::copy]
    set toolbarButtons(paste) [ButtonBox::add $bbox -image $images(paste) \
        -takefocus 0 -relief link \
        -helptext [tr "Paste from Clipboard"] -command Editor::paste]
    
    pack $bbox -side left -anchor w
    set sep2 [Separator::create $tb1.sep2 -orient vertical]
    pack $sep2 -side left -fill y -padx 4 -anchor w
    
    set bbox [ButtonBox::create $tb1.bbox2b -spacing 0 -padx 1 -pady 1]
    set toolbarButtons(toglcom) [ButtonBox::add $bbox -image $images(toglcom) \
        -takefocus 0 -relief link \
        -helptext [tr "Toggle Comment"] -command "Editor::toggle_comment"]
    set toolbarButtons(comblock) [ButtonBox::add $bbox -image $images(comblock) \
        -takefocus 0 -relief link \
        -helptext [tr "Make Comment Block"] -command Editor::make_comment_block]
    set toolbarButtons(unindent) [ButtonBox::add $bbox -image $images(unindent) \
        -takefocus 0 -relief link \
        -helptext [tr "Unindent Selection"] -command editorWindows::unindentSelection]
    set toolbarButtons(indent) [ButtonBox::add $bbox -image $images(indent) \
        -takefocus 0 -relief link \
        -helptext [tr "Indent Selection"] -command editorWindows::indentSelection]
    pack $bbox -side left -anchor w
    
    set sep1c [Separator::create $tb1.sep1c -orient vertical]
    pack $sep1c -side left -fill y -padx 4 -anchor w
    
    set bbox [ButtonBox::create $tb1.bbox3 -spacing 0 -padx 1 -pady 1]
    
    set toolbarButtons(undo) [ButtonBox::add $bbox -image $images(undo) \
        -takefocus 0 -relief link \
        -helptext [tr "Undo"] -command Editor::undo]
    
    set toolbarButtons(redo) [ButtonBox::add $bbox -image $images(redo) \
        -takefocus 0 -relief link \
        -helptext [tr "Redo"] -command Editor::redo]
    pack $bbox -side left -anchor w
    
    set sep3 [Separator::create $tb1.sep3 -orient vertical]
    pack $sep3 -side left -fill y -padx 4 -anchor w
    
    set bbox [ButtonBox::create $tb1.bbox4 -spacing 0 -padx 1 -pady 1]
    
    set toolbarButtons(find) [ButtonBox::add $bbox -image $images(find) \
        -takefocus 0 -relief link \
        -helptext [tr "Find Dialog"] -command Editor::search_dialog]
    
    set toolbarButtons(replace) [ButtonBox::add $bbox -image $images(replace) \
        -takefocus 0 -relief link \
        -helptext [tr "Replace Dialog"] -command Editor::replace_dialog]
    
    pack $bbox -side left -anchor w
   
    set ::Editor::search_var ""
    set search_combo [ComboBox::create $tb1.combo \
        -textvariable ::Editor::search_var\
        -values {""} \
        -helptext [tr "Enter Searchtext"] \
        -width 15]
    pack $search_combo -side left
    
    set bbox [ButtonBox::create $tb1.bbox5 -spacing 1 -padx 1 -pady 1]

    set down_arrow [ButtonBox::add $bbox -image $images(down) \
        -takefocus 0 -relief link \
        -helptext [tr "Search forwards"] -command Editor::search_forward]    
    set up_arrow [ButtonBox::add $bbox -image $images(up) \
        -takefocus 0 -relief link \
        -helptext [tr "Search backwards"] -command Editor::search_backward]

    pack $bbox -side left -anchor w
    
    set sep [Separator::create $tb1.sep -orient vertical]
    pack $sep -side left -fill y -padx 4 -anchor w
    set bbox [ButtonBox::create $tb1.bbox7 -spacing 0 -padx 1 -pady 1]
    set toolbarButtons(checksyntax) \
	[ButtonBox::add $bbox \
	     -image $images(braces) \
	     -takefocus 0 -relief link \
	     -helptext [tr "Check Syntax"] \
	     -command Editor::checkSyntax]
    pack $bbox -side left -anchor w
    set sep [Separator::create $tb1.sep5 -orient vertical]
    pack $sep -side left -fill y -padx 4 -anchor w
    set bbox [ButtonBox::create $tb1.bbox1b -spacing 0 -padx 1 -pady 1]
    ButtonBox::add $bbox -image $images(stop) \
        -takefocus 0 -relief link \
        -helptext [tr "Terminate Execution"] -command Editor::terminate
    
    pack $bbox -side left -anchor w -padx 2
    
    set bbox [ButtonBox::create $tb1.bbox1c -spacing 1 -padx 1 -pady 1]
    ButtonBox::add $bbox -image $images(run) \
        -takefocus 0 -relief link \
        -helptext [tr "Test Application"] \
        -command {
            set code [catch Editor::execFile cmd]
            if $code {
                tk_messageBox -message $errorInfo -title Error -icon error -parent .
            }
        }
    
    pack $bbox -side left -anchor w -padx 2

    set ::Editor::argument_var ""
    set argument_combo [ComboBox::create $tb1.combo2 \
        -textvariable ::Editor::argument_var\
        -values {""} \
        -helptext [tr "Enter optional argument"] \
        -width 15]
    pack $argument_combo -side left
    
    set sep4 [Separator::create $tb1.sep4 -orient vertical]
    pack $sep4 -side left -fill y -padx 4 -anchor w
    
    set bbox [ButtonBox::create $tb1.bbox6 -spacing 1 -padx 1 -pady 1]
    ButtonBox::add $bbox -image $images(exitdoor) \
        -takefocus 0 -relief link \
        -helptext [tr "Exit Ased"] -command Editor::exit_app
    pack $bbox -side right -anchor w
    
    # get Entry path out of Combo Widget
    set childList [winfo children $search_combo]
    foreach w $childList {if {[winfo class $w] == "TEntry"} { set entry $w ; break}}
    bind $entry <KeyRelease-Return> {Editor::search_forward ; break}
    set childList [winfo children $argument_combo]
    foreach w $childList {if {[winfo class $w] == "TEntry"} { set entry2 $w ; break}}
    bind $entry2 <KeyRelease-Return> {
        set code [catch Editor::execFile cmd]
        if $code {
            tk_messageBox -message $errorInfo -title [tr "Error"] -icon error -parent .
        }
        break
    }
}

proc Editor::createFontToolbar {{update 0}} {
    global images
    global EditorData
    global ASEDsRootDir
    variable mainframe
    variable search_combo
    variable argument_combo
    variable mode_combo
    variable class_combo
    variable colorButton
    variable current
    variable toolbarButtons
    variable tb2
    
    # toolbar 2 creation
    if {$update == 0} {
        set tb2  [MainFrame::addtoolbar $mainframe]
    }
    
    set bbox [ButtonBox::create $tb2.bbox2 -spacing 0 -padx 1 -pady 1]
    
    set toolbarButtons(incFont) [ButtonBox::add $bbox -image $images(incfont) \
        -takefocus 0 -relief link \
        -helptext [tr "Increase Fontsize"] -command {Editor::increaseFontSize up}]
    pack $bbox -side left -anchor w
    
    set toolbarButtons(decFont) [ButtonBox::add $bbox -image $images(decrfont) \
        -takefocus 0 -relief link \
        -helptext [tr "Decrease Fontsize"] -command {Editor::increaseFontSize down}]
    pack $bbox -side left -anchor w
    set sep3 [Separator::create $tb2.sep3 -orient vertical]
    pack $sep3 -side left -fill y -padx 4 -anchor w
    set ::Editor::Font_var [font configure "Code" -family]
    set Font_combo [ComboBox::create $tb2.combo \
        -textvariable ::EditorData(options,fontFamily)\
        -values [lsort -dictionary [font families]] \
        -helptext [tr "Choose Font"] \
        -modifycmd {editorWindows::onFontChange}\
    ]
    pack $Font_combo -side left
    set ::Editor::FontSize_var [font configure "Code" -size]
    set FontSize_combo [ComboBox::create $tb2.combo2 -width 2 \
        -textvariable ::EditorData(options,fontSize)\
        -values {8 9 10 11 12 14 16 20 24 30} \
        -helptext [tr "Choose Fontsize"] \
        -modifycmd {editorWindows::onFontChange}\
    ]
    pack $FontSize_combo -side left
    
    set ckbShowLine [ttk::checkbutton $tb2.chkbShowLineNo  \
        -text [tr "Show Line Numbers"] \
        -variable ::EditorData(options,showLineNo) \
        -command {
            $::Editor::current(text) configure -linemap $::EditorData(options,showLineNo)
        }
    ]
    pack $ckbShowLine -side left -padx 4
    
    set sep0 [Separator::create $tb2.sep0 -orient vertical]
    pack $sep0 -side left -fill y -padx 4 -anchor w
    
    foreach file [glob [file join $ASEDsRootDir highlighters *.mode]] {
        set name [file tail $file]
        regexp {^[^\.]+} $name mode
        lappend ::EditorData(modes) $mode
    }
    set mode_combo [ComboBox::create $tb2.combo3  \
        -width 10 \
        -textvariable ::Editor::current(mode)\
        -values $::EditorData(modes) \
        -helptext [tr "Choose Highlight-Mode"] \
        -modifycmd {Editor::changeHLMode $::Editor::current(mode)}\
    ]
    pack $mode_combo -side left
    
    set ::Editor::current(class) ""
    set ::Editor::current(classes) {}
    set class_combo [ComboBox::create $tb2.combo4  \
        -width 10 \
        -textvariable ::Editor::current(class)\
        -values {""} \
        -helptext [tr "Choose Highlight-Class"] \
        -modifycmd {Editor::changeHLClass $::Editor::current(class)}\
    ]
    
    pack $class_combo -side left
    
    set colorButton [ttk::button $tb2.fgcolorb \
        -text [tr Color] \
        -image $images(color) \
        -command "Editor::setClassColor $tb2 \$::Editor::current(class)" \
	-style Toolbutton
    ]
    # set ::EditorData(buttonbgColor) [$colorButton cget -background]
    pack $colorButton -side left -pady 4
    set class_weight [ComboBox::create $tb2.combo5  \
        -width 10 \
        -textvariable ::Editor::current(weight)\
        -values "[tr normal] [tr bold]" \
        -helptext [tr "Choose Font Weight"] \
        -modifycmd {
            set font [$::Editor::current(text) tag cget $::Editor::current(class) -font]
            font configure $font -weight [tr $::Editor::current(weight)]
            set EditorData(options,fonts,$::Editor::current(class)) [font configure $font]
        }\
    ]
    pack $class_weight -side left
    
    $::Editor::mainframe showtoolbar 0 $::Editor::toolbar1
    $::Editor::mainframe showtoolbar 1 $::Editor::toolbar2
}

proc Editor::setClassColor {win class} {
    global EditorData
    variable colorButton
    
    set fgcolor [SelectColor::menu $win.fgcolorm \
            [list below $win.fgcolorb] \
            ]
    if {[string length $fgcolor]} {
        set EditorData(options,fgcolor,$Editor::current(class)) $fgcolor
        $Editor::current(text) tag configure $Editor::current(class) \
                -foreground $fgcolor
        # $colorButton configure -background $fgcolor
    }
}

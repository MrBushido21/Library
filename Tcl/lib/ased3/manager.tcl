################################################################################
# manager.tcl -
#
# creates the main windows (editor, console, code browser etc.)
# was originally based upon BWidget´s Demo
#
# Copyright 1999-2000 by Andreas Sievers
################################################################################

namespace eval EditManager {
    variable _progress 0
    variable _afterid  ""
    variable _status "Compute in progress..."
    variable _homogeneous 0
    variable _newPageCounter 0
    variable lastPage ""
}

proc EditManager::focus_text {nb pagename} {
    global images
    global EditorData
    variable treeWindow

    if {[info exists Editor::current(pagename)] && $Editor::current(pagename) eq $pagename} {
        return
    } else {
        catch {
            set node $Editor::current(file)
            regsub -all " " $node \306 node
            regsub ":$" $node \327 node
            regsub -all "\\\$" $node "²" node
            $treeWindow itemconfigure $node -open 0
            $treeWindow itemconfigure $node -image $images(folder)
        }
    }

    set text_page [$nb getframe $pagename]
	#save values of last active textWindow
    if {[info exists Editor::current(text)]} {\
        set f0 $Editor::current(text)
        set p0 $Editor::current(pagename)
        if {[info exists Editor::index($f0)]} {\
            set idx $Editor::index($f0)
            # set Editor::text_win($idx,hasChanged) [$Editor::current(text) edit modified]
            set Editor::text_win($idx,file) $Editor::current(file)
            set Editor::text_win($idx,slave) $Editor::current(slave)
            set Editor::text_win($idx,project) $Editor::current(project)
            set Editor::text_win($idx,history) $Editor::current(procListHistory)
            set Editor::text_win($idx,writable) $Editor::current(writable)
            set Editor::text_win($idx,mode) $Editor::current(mode)
            set Editor::text_win($idx,class) $Editor::current(class)
            set Editor::text_win($idx,weight) $Editor::current(weight)
            set Editor::text_win($idx,path) $Editor::current(text)
            set Editor::text_win($idx,inCommentMode) $Editor::current(inCommentMode)
        }
    }
    set Editor::current(text) $text_page.sw.textWindow
    set Editor::current(page) $text_page
    set idx $Editor::index($Editor::current(text))
    # set Editor::current(undo_id)  $Editor::text_win($idx,undo_id)
    # $Editor::current(text) edit modified $Editor::text_win($idx,hasChanged)
    set Editor::current(file) $Editor::text_win($idx,file)
    set Editor::current(pagename) $Editor::text_win($idx,pagename)
    set Editor::current(slave) $Editor::text_win($idx,slave)
    set Editor::current(project) $Editor::text_win($idx,project)
    set Editor::current(procListHistory) $Editor::text_win($idx,history)
    set Editor::current(writable) $Editor::text_win($idx,writable)
    set Editor::current(mode) $Editor::text_win($idx,mode)
    set Editor::current(class) $Editor::text_win($idx,class)
    set Editor::current(weight) $Editor::text_win($idx,weight)
    set Editor::current(inCommentMode) $Editor::text_win($idx,inCommentMode)
    set Editor::current(inExpandMode) 0

    #restore Cursor position
    set Editor::last(index) $idx

    NoteBook::see $nb $pagename
    set editorWindows::TxtWidget $Editor::current(text)
    set EditorData(curFile) $Editor::current(file)
    $Editor::current(text) see insert
    editorWindows::ReadCursor 0
    editorWindows::flashLine
    if {!$Editor::current(initDone)} {
        Editor::updateObjects
        Editor::selectObject 0
        set Editor::current(initDone) 1
    } elseif {$EditorData(options,showProcs)} {
        set node $Editor::current(file)
        regsub -all " " $node \306 node
        regsub ":$" $node \327 node
        regsub -all "\\\$" $node "²" node
        if {[catch {$treeWindow itemconfigure $node -open 1}]} {
            Editor::updateObjects
            catch {$treeWindow itemconfigure $node -open 1}
        }
	catch {
            $treeWindow itemconfigure $node -image $imaged(openfold)
            $treeWindow configure -redraw 1
	}
        Editor::selectObject 0
    }

    $Editor::current(text) configure -linemap $EditorData(options,showLineNo)
    ComboBox::configure $Editor::class_combo -values [$Editor::current(text) cget -classes]
    catch {$Editor::con_notebook raise $pagename}
    focus [$Editor::current(text) cget -textWidget]
    set Editor::status ""
}
proc EditManager::setBindings {win } {
    global tcl_platform
    global EditorData

    # create bindings

    if {$tcl_platform(platform) ne "windows"} {
        bind [$win cget -textWidget] <Control-Insert> "editorWindows::copy; break"
        bind [$win cget -textWidget] <Control-Delete> "editorWindows::cut; break"
        bind [$win cget -textWidget] <Shift-Insert>   "editorWindows::paste; break"
    }
    bind [$win cget -textWidget] <Tab> "editorWindows::OnTabPress; break"
    bind [$win cget -textWidget] <Shift-KeyRelease-Tab> {Editor::delEvent %A; Editor::onShiftTab %A; break}
    bind [$win cget -textWidget] <KeyRelease-F2> {Editor::delEvent %A; editorWindows::onF2 %A; break}
    bind [$win cget -textWidget] <Control-a> "editorWindows::selectAll; break"
    bind [$win cget -textWidget] <KeyPress-Return> [list editorWindows::onKeyPressReturn %A ]
    bind [$win cget -textWidget] <KeyRelease-Return> "editorWindows::IndentCurLine ; editorWindows::OnKeyRelease"
    bind [$win cget -textWidget] <KeyRelease-space> "editorWindows::OnSpaceRelease;editorWindows::OnKeyRelease"
    bind [$win cget -textWidget] <KeyRelease-parenleft> "editorWindows::OnLeftParenRelease;editorWindows::OnKeyRelease"
    bind [$win cget -textWidget] <KeyRelease-quotedbl> "editorWindows::OnQuoteDblRelease;editorWindows::OnKeyRelease"
    bind [$win cget -textWidget] <Key-Delete> {editorWindows::delete %A ; break}
    bind [$win cget -textWidget] <Control-h> {editorWindows::delete %A bs ; break}
    bind [$win cget -textWidget] <BackSpace> {editorWindows::delete %A bs ; break}
    bind [$win cget -textWidget] <KeyRelease> {Editor::delEvent %A; Editor::expandCommand %W %A; break}
    bind [$win cget -textWidget] <KeyPress> {editorWindows::OnKeyPress %A }
    bind [$win cget -textWidget] <Button-3> {tk_popup $Editor::textMenu %X %Y ; break}
    bind [$win cget -textWidget] <ButtonRelease> editorWindows::OnMouseRelease
    bind [$win cget -textWidget] <Control-x> "Editor::cut; break"
    bind [$win cget -textWidget] <Control-c> "Editor::copy; break"
    bind [$win cget -textWidget] <Control-v> "Editor::paste; break"
    bind [$win cget -textWidget] <Control-y> "Editor::delLine ; break"
    bind [$win cget -textWidget] <KeyPress-Home> "editorWindows::gotoFirstChar 0;break"
    bind [$win cget -textWidget] <Shift-KeyPress-Home> "editorWindows::gotoFirstChar 1;break"
    bind [$win cget -textWidget] <Control-l> "repeat_last_search $win"
    bind [$win cget -textWidget] <<Modified>> "Editor::modified"
    bind [$win cget -textWidget] <F1> "Editor::showHelp %W"
    return
}

proc EditManager::file2pagename {filename} {
    regsub -all {\.} $filename "#" pagename
    regsub -all {\ } $pagename "²" pagename
    return [string tolower $pagename]
}

proc EditManager::create_text {nb file} {
    global EditorData
    global ASEDsRootDir
    variable TxtWidget
    variable _newPageCounter

    incr _newPageCounter
    set pageName "[file2pagename $file]"
    set filename [file tail $file]
    set prjFile [file join [file dirname $file] [lindex [split $filename .] 0]].prj
    set frame [$nb insert end $pageName \
        -text $filename \
	-raisecmd "EditManager::focus_text $nb $pageName"]
    set sw [ScrolledWindow::create $frame.sw -auto none]
    pack $sw -fill both -expand yes

    set text [ctext $sw.textWindow \
        -bg white \
        -wrap none \
        -height 20 \
        -width 80 \
        -linemap $EditorData(options,showLineNo) \
        -font "Code" \
        -undo 1 \
    ]

    ScrolledWindow::setwidget $sw $text
    pack $sw -fill both -expand yes

    $text tag configure sel -background lightgrey
    if {$EditorData(options,tabSize) == 8 ||
        $EditorData(options,tabSize) <= 0} {
        set tabList {}
    } else {
        set tabSize [expr {$EditorData(options,tabSize) * [font measure "Code" -displayof $text.t " "]}]
        set tabList [list $tabSize left]
    }
    set font [$text cget -font]
    font configure $font -size $EditorData(options,fontSize)
    set fontattr [font configure $font]
    $text configure \
        -tabs $tabList -tabstyle wordprocessor \
        -font $fontattr
    $text tag configure pair -background red

    # init bindings for the text widget
    set editorWindows::TxtWidget $text
    EditManager::setBindings $editorWindows::TxtWidget
    incr Editor::index_counter
    set Editor::index($text) $Editor::index_counter
    set Editor::text_win($Editor::index_counter,page) $frame
    set Editor::text_win($Editor::index_counter,path) $text
    set Editor::text_win($Editor::index_counter,hasChanged) 0
    set Editor::text_win($Editor::index_counter,file) $file
    set Editor::text_win($Editor::index_counter,writable) 1
    set Editor::text_win($Editor::index_counter,pagename) $pageName
    set Editor::text_win($Editor::index_counter,slave) "none"

    set Editor::text_win($Editor::index_counter,weight) ""
    set Editor::text_win($Editor::index_counter,history) [list "mark1"]
    if {[file exists $prjFile]} {
        set fd [open $prjFile r]
        set Editor::text_win($Editor::index_counter,project) [read $fd]
        close $fd
    } else {
        set Editor::text_win($Editor::index_counter,project) $EditorData(options,defaultProjectFile)
    }
    set Editor::text_win($Editor::index_counter,class) ""
    set Editor::text_win($Editor::index_counter,mode) ""
    set Editor::text_win($Editor::index_counter,inCommentMode) 0
    set mode [string trimleft [string tolower [file extension $file]] .]
    if {$mode eq ""} {
        set mode $EditorData(options,defaultmode)
    }
    if {[info exists EditorData($mode)]} {
        set Editor::text_win($Editor::index_counter,mode) $mode

        # Editor::mode_$mode $text
    } else {
        set modefile [file join $ASEDsRootDir highlighters $mode.mode]
        if {[file exists $modefile]} {
            source $modefile
            set EditorData($mode) 1
            set Editor::text_win($Editor::index_counter,mode) $mode
        } else {
            set mode $EditorData(options,defaultmode)
            set modefile [file join $ASEDsRootDir highlighters $mode.mode]
            if {[file exists $modefile]} {
                source $modefile
                set EditorData($mode) 1
                set Editor::text_win($Editor::index_counter,mode) $mode
            }
        }
    }
    if {($EditorData(options,useHL) == 1) && ($Editor::text_win($Editor::index_counter,mode) ne "")} {
        ::Editor::mode_$Editor::text_win($Editor::index_counter,mode) $text
        set Editor::text_win($Editor::index_counter,class) [lindex [$text cget -classes ] 0]
        # Editor::changeHLClass {$Editor::text_win($Editor::index_counter,class)}
        set font [$text tag cget $Editor::text_win($Editor::index_counter,class) -font]
        set Editor::text_win($Editor::index_counter,weight) [tr [font configure $font -weight]]
    }

    set Editor::current(initDone) 0
    set Editor::current(inCommentMode) 0
    return [list $frame $pageName $text]
}

proc EditManager::create_conWindow {nb } {
    global conWindow

    set pagename asedCon
    set frame [$nb insert end $pagename -text [tr "Console"]]

    set sw [ScrolledWindow::create $frame.sw -auto both]
    pack $sw -fill both -expand yes

    set conWindow [consoleInit $sw]
    $conWindow configure -wrap none -font "Code"
    ScrolledWindow::setwidget $sw $conWindow

    bind $conWindow <Double-1> "Editor::showlineFromCon %W"
    return $frame
}

proc EditManager::create_testTerminal {nb pagename title} {

    set pn [EditManager::file2pagename $pagename]

    set frame [$nb insert end $pn \
        -text $title \
        -raisecmd [list $Editor::notebook raise $pn]]

    set sw [ScrolledWindow::create $frame.sw -auto both]
    pack $sw -fill both -expand yes

    if {[interp exists $Editor::current(slave)]} {
        set slave $Editor::current(slave)
    } else {
        set slave {}
    }
    set termWindow [testTermInit $sw $slave]
    $termWindow configure -wrap none
    ScrolledWindow::setwidget $sw $termWindow

    return $termWindow
}

################################################################################
#
#  proc EditManager::create_treeWindow
#
#  create a tree window for the object tree, using BWidgets treewidget
#
#  zerbst@tu-harburg.d
#
#  enhanced by Andreas Sievers
################################################################################

proc EditManager::create_treeWindow {nb } {
    global images
    variable TxtWidget
    variable treeWindow

    set pagename "objtree"
    set frame [$nb insert end $pagename -text "Code Browser"]
    # no auto scrollbar due to a bug in BWidgets tree
    set sw [ScrolledWindow::create $frame.sw -auto none]
    set objTree [Tree $frame.sw.objTree \
        -width 15\
        -highlightthickness 0\
        -bg white  \
        -deltay 18 \
        -opencmd   "Editor::tmoddir 1"  \
        -closecmd  "Editor::tmoddir 0"
    ]
    set treeWindow $objTree
    $sw setwidget $objTree

    #navigator frame
    set naviframe [ttk::frame $frame.naviFrame -width 150]
    #History Buttons
    set buttonFrame [ttk::frame $naviframe.buttonFrame]
    set button_prev [Button::create $buttonFrame.bp \
        -image $images(left) \
        -relief link\
        -helptext [tr "Goto previous Position"]\
        -command {Editor::procList_history_get_prev}]
    set button_next [Button::create $buttonFrame.bn\
        -image $images(right) \
        -relief link\
        -helptext [tr "Goto next Position"]\
        -command {Editor::procList_history_get_next}]
    # Line number etc.

    set entryFrame [ttk::frame $naviframe.entryFrame]
    set Editor::lineEntryCombo [ComboBox::create $entryFrame.combo \
        -textvariable Editor::lineNo\
        -values {""} \
        -helptext [tr "Enter Linenumber"] \
        -width 6]

    set button_go [Button::create $entryFrame.go\
        -image $images(go) \
        -relief link \
        -helptext [tr "Goto Line"]\
        -command {Editor::lineNo_history_add ; Editor::gotoLine $Editor::lineNo}]

    pack $button_prev -side left -expand yes
    pack $button_next -side left -expand yes
    pack $Editor::lineEntryCombo -side left -expand yes
    pack $button_go -side left -expand yes
    pack $buttonFrame -side left -fill both -expand yes
    pack $entryFrame -side left -fill both -expand yes
    pack $naviframe -side bottom -fill x
    pack $sw -side top -fill both -expand yes -pady 1

    set childList [winfo children $Editor::lineEntryCombo]
    foreach w $childList {if {[winfo class $w] eq "TEntry"} { set lineEntry $w ; break}}
    bind $lineEntry <KeyRelease-Return> {Editor::lineNo_history_add ; Editor::gotoLine $Editor::lineNo}
    return $frame
}


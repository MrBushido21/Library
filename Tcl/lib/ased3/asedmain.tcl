################################################################################
# asedmain.tcl -
#
# Copyright 1999-2004 by Andreas Sievers
#
# andreas.sievers@t-online.de
################################################################################

proc Editor::tick {} {
    global clock_var
    variable mainframe
    variable startTime
    set seconds [expr [clock seconds]  - $startTime]
    set clock_var [clock format $seconds -format %H:%M:%S -gmt 1]
    after 1000 Editor::tick
}

proc Editor::aboutBox {} {
    tk_messageBox -message \
            [tr "ASED Tcl/Tk-IDE 3.0.b16 build 051204
(c) Andreas Sievers, 1999-2004

This Software is distributed under the terms
of the GNU General Public License!

Parts of ASED are based upon
the BWidget Toolkit Demo from UNIFIX and
Tcldev from Alexey Kakunin

Special Thanks to Carsten Zerbst who provided
the basics of the Code Browser Window and iTcl-support
Please report any comments or bugs to
andreas.sievers@t-online.de

(*) Johann Oberdorfer, 2014-2016
Code modified and various packages updated.

(*) chw 2020 shrinked and repackaged for vanillawish"] \
        -type ok \
        -title About \
        -icon info \
        -parent .
}

proc Editor::getWindowPositions {} {
    global EditorData
    global tcl_platform
    variable pw1
    variable pw2
    variable notebook
    variable list_notebook
    variable con_notebook
    variable current

    update idletasks
    catch {set EditorData(options,sash1) [$pw1 sash coord 0]}
    catch {set EditorData(options,sash2) [$pw2 sash coord 0]}
    #    get position of mainWindow
    if {$tcl_platform(platform) eq "windows"} {
        if {[wm state .] eq "zoomed"} {
            set EditorData(options,zoomed) 1
        } else {
            set EditorData(options,zoomed) 0
        }
    }
    set EditorData(options,mainWinSize) [wm geom .]
}

proc Editor::restoreWindowPositions {} {
    global EditorData
    global tcl_platform
    variable pw1
    variable pw2
    variable notebook
    variable list_notebook
    variable con_notebook

    if {$tcl_platform(platform) eq "windows"} {
        if {$EditorData(options,zoomed)} {
            wm state . zoomed
        } else {
            wm geometry . $EditorData(options,mainWinSize)
        }
    } else {
        wm geometry . $EditorData(options,mainWinSize)
    }
    wm deiconify .
    tkwait visibility .
    update idletasks
    if {$EditorData(options,showConsole)} {
        catch {
            $pw1 sash place 0 [lindex [$pw1 sash coord 0] 0] [lindex $EditorData(options,sash1) 1]
        }
    } else {
        $pw1 forget $pw1.nb
    }
    if {$EditorData(options,showProcs)} {
        catch {
            $pw2 sash place 0 [lindex $EditorData(options,sash2) 0] [lindex [$pw2 sash coord 0] 1]
        }
    } else {
        $pw2 forget $pw2.nb1
    }
}

################################################################################
# proc Editor::saveOptions
# called when ASED exits
# saves only "EditorData(options,...)"
# but might be easily enhanced with other options
################################################################################

proc Editor::saveOptions {} {
    global EditorData
    global ASEDsRootDir

    Editor::getWindowPositions

    set configData "#ASED Configuration File\n\n"
    set configFile [file join "~" ased.cfg]
    set optionlist [array names EditorData]
    foreach option $optionlist {
        set optiontext EditorData($option)
        if {![string match "*(options*" $optiontext]} {
            continue
        }
        set value \"[subst \$[subst {$optiontext}]]\"
        append configData "set EditorData($option) $value\n"
    }
    set result [Editor::_saveFile $configFile $configData]
}

proc Editor::changeServerPort {} {
    global EditorData

    if {[winfo exists .sptop]} {
        return
    }
    set dialog [toplevel .sptop]
    wm transient .sptop .
    set e [frame $dialog.e]
    label $dialog.e.l -text [tr "Enter Port Number"]
    set port $EditorData(options,serverPort)
    set portEntry [ttk::entry $dialog.e.e -width 5 -textvar ::EditorData(options,serverPort)]
    set EditorData(oldPort) $EditorData(options,serverPort)
    set f [frame $dialog.f]
    button $dialog.f.ok -text [tr "Ok"] -width 8 -command {
        destroy .sptop
    }
    button $dialog.f.c -text [tr "Cancel"] -width 8 -command {
        global EditorData
        destroy .sptop
        set EditorData(options,serverPort) $EditorData(oldPort)
    }
    pack $dialog.e.l $portEntry -side left -padx 5 -pady 5
    pack $dialog.f.ok $dialog.f.c -padx 5 -pady 5 -side left -fill both -expand yes
    pack $e $f
    focus $portEntry
    bind $portEntry <KeyRelease-Return> {
        destroy .sptop
        break
    }
    wm title $dialog [tr "Enter Port"]
    ::tk::PlaceWindow $dialog widget .
}

proc Editor::modified {} {
    global images
    variable current

    if {![info exists current(text)]} {
	return
    }

    if {[$current(text) edit modified]} {
        $Editor::notebook itemconfigure $current(pagename) -image $images(redball)
    } else {
        catch {$Editor::notebook itemconfigure $current(pagename) -image ""}
    }
}

proc Editor::changeTabs {} {
    global EditorData

    set EditorData(indentString) ""
    if {$EditorData(options,changeTabs)} {
        for {set i 0} {$i < $EditorData(options,tabSize)} {incr i} {
            append EditorData(indentString) " "
        }
    } else {
        append EditorData(indentString) "\t"
    }
}

proc Editor::changeTabSize {} {
    global EditorData

    if {[winfo exists .top]} {
        return
    }
    set dialog [toplevel .top]
    wm transient .top .
    set e [frame $dialog.e]
    label $dialog.e.l -text [tr "Enter Tab-Size"]
    set tabEntry [ttk::entry $dialog.e.e -width 5 -textvar ::EditorData(options,tabSize)]
    set EditorData(oldSize) $EditorData(options,tabSize)
    set f [frame $dialog.f]
    button $dialog.f.ok -text [tr "Ok"] -width 8 -command {
        destroy .top
	Editor::changeTabs
        editorWindows::onFontChange
        return
    }
    button $dialog.f.c -text [tr "Cancel"] -width 8 \
        -command {
            global EditorData
            destroy .top
            set EditorData(options,tabSize) $EditorData(oldSize)
        }
    pack $dialog.e.l $tabEntry -side left -padx 5 -pady 5
    pack $dialog.f.ok $dialog.f.c -padx 5 -pady 5 -side left -fill both -expand yes
    pack $e $f
    focus $tabEntry
    bind $tabEntry <KeyRelease-Return> {
        destroy .top
        break
    }
    wm title $dialog [tr "Enter Tab-Size"]
    ::tk::PlaceWindow $dialog widget .
}

proc Editor::newFile {{force 0}} {
    variable notebook
    variable current
    variable newFileCount
    global EditorData

    set pages [NoteBook::pages $notebook]
    if {([llength $pages] > 0) && ($force == 0)} {
        if {[info exists current(text)]} {
            set f0 [NoteBook::raise $notebook]
            set text [NoteBook::itemcget $notebook $f0 -text]
            set data [$current(text) get 1.0 end-1c]
            if {($data eq "") && ([string trimright $text 0123456789] eq [tr "Untitled"])} {return}
        }
    }
    # set temp [$current(text) edit modified]
    incr newFileCount
    set f0 [EditManager::create_text $notebook [tr "Untitled"]$newFileCount]

    # set Editor::text_win($Editor::index_counter,undo_id) [new textUndoer [lindex $f0 2]]
    # $current(text) edit modified $temp
    NoteBook::raise $notebook [lindex $f0 1]
    $current(text) edit modified 0
    set current(writable) 1
    $Editor::mainframe setmenustate noFile normal
    updateObjects
}

proc Editor::scanLine {} {
    variable current

    # is current line a proc-line?
    set result [$current(text) search "proc " "insert linestart" "insert lineend"]
    if {$result eq ""} {
        # this is not a proc-line
        # was it a proc-line?
        if {$current(is_procline)} {
            set current(is_procline) 0
            set current(procSelectionChanged) 1
        } else {
            set current(is_procline) 0
            set current(procSelectionChanged) 0
        }
    } else {
        # is current line really a proc-line?
        set line [$current(text) get "$result linestart" "$result lineend"]
        set temp [string trim $line \ \t\;]
        set proc ""
        set procName ""
        # is it really a proc-line?
        if {[scan $temp %\[proc\]%s proc procName] != 2} {
            set result ""
        } elseif {$proc ne "proc"} {
            set result ""
        }
        if {$result ne ""} {
            if {$current(procName) ne $procName} {
                set current(procName) $procName
                set current(procSelectionChanged) 1
                set current(is_procline) 1
            } else {
                set current(procSelectionChanged) 0
            }
        } else {
            if {$current(is_procline)} {
                set current(is_procline) 0
                set current(procSelectionChanged) 1
            } else {
                set current(is_procline) 0
                set current(procSelectionChanged) 0
            }
        }
    }
    return $result
}

proc Editor::updateOnIdleNew {range} {
    variable current

    catch {after cancel $current(idleID)}
    set current(range) $range
    set current(idleID) [after 500 {after idle Editor::updateObjects $Editor::current(range)}]
    return
}

proc Editor::updateOnIdle {range} {
    variable current

    # if there's a pending update only store new range
    if {$current(isUpdate)} {
        if {[$current(text) compare $current(updateStart) > [lindex $range 0]]} {
            set current(updateStart) [$current(text) index [lindex $range 0]]
        }
        if {[$current(text) compare $current(updateEnd) < [lindex $range 1]]} {
            set current(updateEnd) [$current(text) index [lindex $range 1]]
        }
    } else {
        set current(isUpdate) 1
        set current(updateStart) [$current(text) index [lindex $range 0]]
        set current(updateEnd) [$current(text) index [lindex $range 1]]
        after idle {
            # wait for a longer idle period
            for {set i 0} {$i <= 10000} {incr i} {
                update
                set Editor::current(idleID) [after idle {
                    update
                    after idle {set Editor::current(idleID) ""}
                }]
                vwait Editor::current(idleID)
                if {$i == 100} {
                    set range [editorWindows::deleteMarks $Editor::current(updateStart) $Editor::current(updateEnd) ]
                    Editor::updateObjects $range
                    Editor::selectObject 0
                    set Editor::current(isUpdate) 0
                    break
                }
            }
        }
    }
}

################################################################################
#  proc Editor::updateObjects
#
#  reparse the complete file and rebuild object tree
#
# zerbst@tu-harburg.d
#
# adopted for ASED by A.Sievers, dated 02/06/00
#
################################################################################

proc Editor::updateObjects {{range {}}} {
    global EditorData
    variable current
    variable treeWindow

    if {!$EditorData(options,autoUpdate) || !$EditorData(options,showProcs)} {
        return
    }
    while {[llength $range] == 1} {
        eval set range $range
    }

    if {$range eq {}} {
        # switch on progressbar
        set Editor::prgindic 0
        set current(checkRootNode) 0
        set start 1.0
        set end "end-1c"
        catch {
            editorWindows::deleteMarks "1.0" "end -1c"
        }
        Editor::tdelNode $current(file)
    } else {
        set current(checkRootNode) 1
    }
    set code {
        set temp [expr int($nend / $end * 100)]
        if {!$recursion && $temp > $Editor::prgindic && [expr $temp % 10] == 0 } {
            set Editor::prgindic [expr int($nend / $end * 100)]
            set Editor::status "Parsing: $Editor::prgindic % "
            update idletasks
        }
    }

    # call parser
    set nodeList [Parser::parseCode $current(file) $current(text) $range $code]
    # switch off progressbar
    set Editor::prgindic -1
    if {[string first $Editor::status "Parsing:"] != -1} {
        set Editor::status ""
    }

    foreach node $nodeList {
        catch {Editor::tnewNode $node}
    }
    update
    if {$Editor::options(sortProcs)} {catch {Editor::torder $current(file)}}
}

################################################################################
#  proc Editor::selectObject
#
#  selects an object by a given position in the text
#
# zerbst@tu-harburg.d
#
# adopted for ASED by A.Sievers, dated 02/06/00
#
################################################################################

proc Editor::selectObject {{update 1} {Idx insert}} {
    global EditorData
    variable current
    variable treeWindow
    variable procMarks

    if {!$EditorData(options,showProcs) || !$EditorData(options,showProc)} {
        set current(node) ""
        return ""
    }
    if {$update != 0} {
        set rexp "^( |\t|\;)*((namespace )|(proc )|(::)*(itcl::)*(class )|(::)*(itcl::)*(body )|(::)*(itcl::)*(configbody )|(private )|(public )|(protected )|(method )|(constructor )|(destructor ))"
        # set rexp {^(( |\t|\;)*((namespace )|(class )|(proc )|(body )|(configbody )))|((( |\t|\;)*[^\#]*)((method )|(constructor )|(destructor )))}
        if {[regexp -- $rexp [$current(text) get "$Idx linestart" "$Idx lineend"]]} {
            set start [$current(text) index $Idx]
            set end [$current(text) index $Idx]
            set range [editorWindows::deleteMarks $start $end]
            updateObjects $range
            set current(isNode) 1
        } else {
            set current(isNode) 0
        }
    }
    set index [$current(text) index $Idx]
    # marknames equal nodenames
    set node $Idx
    set markList [array names procMarks]
    #get the right mark
    while {[lsearch $markList $node] == -1 || $procMarks($node) eq "dummy"} {
        set index [$current(text) index $node]
        set result -1
        foreach {type node idx} [$current(text) dump -mark $index] {
            set result [lsearch $markList $node]
            if {$result != -1} {
                if {$procMarks([lindex $markList $result]) ne "dummy"} {
                    break
                } else {
                    set result -1
                }
            }
        }
        if {$result == -1 && $index != 1.0} {
            set node [$current(text) mark previous $index]
            if {$node eq ""} {
                break
            }
        } elseif {$result == -1} {
            set node ""
            break
        }
    }
    if {$node eq ""} {
        $treeWindow selection clear
        set current(node) $node
        return $node
    }
    #if it is an end_of_proc mark skip this proc
    if {[string match "*_end_of_proc" $node]} {
        set count -2
        while {$count != 0} {
            set node [$current(text) index $node]
            set node [$current(text) mark previous "$node -1c"]
            if {$node eq ""} {
                break
            }
            while {[lsearch $markList $node] == -1 || $procMarks($node) eq "dummy"} {
                set index [$current(text) index $node]
                foreach { type node idx} [$current(text) dump -mark $index] {
                    set result [lsearch $markList $node]
                    if {$result != -1} {
                        if {$procMarks($node) ne "dummy"} {
                            break
                        } else {
                            set result -1
                        }
                    }
                }
                if {$result == -1 && $index != 1.0} {
                    set node [$current(text) mark previous $index]
                    if {$node eq ""} {
                        break
                    }
                } elseif {$result == -1}  {
                    set node ""
                    break
                }
            }
            if {$node eq ""} {
                break
            }
            if {[string match "*_end_of_proc" $node]} {
                incr count -1
            } else {
                incr count
            }
        }
    }
    $treeWindow selection clear
    if {$node ne ""} {
        $treeWindow selection set $node
        set pnode $node
        while {![$treeWindow visible $node]} {
            # open parent nodes
            if {[catch {set parent [$treeWindow parent $pnode]}]} {
                break
            }
            $treeWindow itemconfigure $parent -open 1
            update
            set pnode $parent
        }
        $treeWindow see $node
    }
    set current(node) $node
    return $node
}

################################################################################
#
# Gui components of the treewidget
#
################################################################################

################################################################################
#
#  proc Editor::tdelNode
#
#  deletes a node and its children from the tree
#
# zerbst@tu-harburg.d
################################################################################

proc Editor::tdelNode {node} {
    variable treeWindow

    regsub -all " " $node \306 node
    regsub ":$" $node \327 node
    regsub -all "\\\$" $node "²" node
    $treeWindow delete $node
}


################################################################################
#
#  proc Editor::tnewNode
#
#  inserts a new node into the tree. Gets a string representation of
#  the namspace/class/method/proc name and the type of object
#
# zerbst@tu-harburg.d
#
# adopted for ASED by A.Sievers, dated 02/06/00
# updated by A.Sievers for use with BWidget 1.6
# exchange # with |
#
################################################################################

proc Editor::tnewNode {nodedata} {
    global images
    variable current
    variable treeWindow
    set instanceNo 0

    set node [lindex $nodedata 0]
    set type [lindex $nodedata 1]
    set startIndex [lindex $nodedata 2]
    set endIndex [lindex $nodedata 3]
    # if we want an args-node
    set args [lindex $nodedata 4]

    # mask spaces in the node name
    regsub -all {\ } $node \306 node
    # mask ending single : in node name
    regsub {:$} $node \327 node
    # mask "$" in nodename
    regsub -all {\\\$} $node "²" node
    # mask instance number
    # regsub {\367.+\376$} $node "" node

    if {[string index $node [expr {[string length $node] -1}]] eq "\u018b"} {
        append node "{}"
    }
    #check current namespace in normal editing mode
    if {$current(checkRootNode) != 0} {
        # if node doesn't present a qualified name,
        # which presents it's rootnode by itself (e.g. test::test)
        # try to set it's rootnode
        # use regsub to count qualifiers (| in nodes instead of ::)
        if {[regsub -all -- \u018b $node "" dummy] > 1} {
            # do nothing
        } else {
            set rootNode [selectObject 0 "insert linestart -1c"]
            if {$rootNode ne ""} {
                set name [string range $node [expr {[string last \u018b $node]+1}] end]
                if {$name eq ""} {
                    set name $node
                }
                set node "$rootNode\u018b$name"
            }
        }
    }

    set rootnode [string range $node 0 [expr {[string last \u018b $node] -1}]]
    set name [string range $node [expr {[string last \u018b $node]+1}] end]

    # get rid of the Æ in the node
    regsub -all {\306} $name " " name
    regsub {\327} $name ":" name
    regsub -all {²} $name "\$" name
    # get rid of the type_postfixes in the node
    regsub {_[^_]$} $name "" name
    if {$name eq ""} {
        set name $node
    }

    #Does the rootnode exist ? Otherwise call tnewNode recursively
    if {![string match $type file]} {
        if {![$treeWindow exists $rootnode]} {
            set rnode [string range $rootnode 0 [expr {[string last \u018b $rootnode] -1}]]
            set rname [string range $rootnode [expr {[string last \u018b $rootnode]+1}] end]
            set rootnode "$rnode\u018b$rname\_n"
            if {![$treeWindow exists $rootnode]} {
                switch -- $type {
                    "body" -
                    "method" -
                    "public method" -
                    "private method" -
                    "protected method" -
                    "class" -
                    "constructor" -
                    "destructor" -
                    "forward" {
                        tnewNode [list $rootnode class $startIndex $endIndex]
                    }
                    "default" {
                        tnewNode [list $rootnode namespace $startIndex $endIndex]
                    }
                }
            }
        }
    }

    #don't allow duplicates
    if {[$treeWindow exists $node]} {
        puts "duplicate node: $node"
        return ""
    }
    switch -- $type {
        "file" {
            $treeWindow insert end root $node -text [file tail $name] \
                    -open 1 -data $nodedata -image $images(openfold)
        }

        "code" {
            $treeWindow insert end $rootnode $node -text $name \
                    -open 1 -data $nodedata  -image $images(openlin)
            if {$name eq "<Top>"} {
                $treeWindow itemconfigure $node -image $images(top)
            } elseif {$name eq "<Bottom>"}  {
                $treeWindow itemconfigure $node -image $images(bottom)
            } else {
                $treeWindow itemconfigure $node -image $images(qmark)
            }
        }

        "namespace" {
            $treeWindow insert end  $rootnode $node  -text "$type: $name" \
                    -open 1 -data $nodedata -image $images(namespace)
        }
        "class" {
            $treeWindow insert end  $rootnode $node  -text "$type: $name" \
                    -open 1 -data $nodedata -image $images(openfold)
        }
        "dummy" {
            $treeWindow insert end  $rootnode $node  -text "namespace: $name" \
                    -open 1 -data $nodedata -image $images(namespace)
        }
        "proc" {
            $treeWindow insert end  $rootnode $node  -text "$type: $name" \
                    -open 0 -data $nodedata -image $images(file)
            if {![$treeWindow exists $node]} {
                set nodelist [$treeWindow nodes $rootnode]
            }
        }
        "args" {
            $treeWindow insert end  $rootnode $node  -text "$type: $args" \
                    -open 0 -data $nodedata
        }
        "method" -
        "public method" -
        "private method" -
        "protected method" {
            $treeWindow insert end  $rootnode $node  -text "$type: $name" \
                    -open 0 -data $nodedata -image $images(file)
        }
        "forward" {
            $treeWindow insert end  $rootnode $node  -text $name \
                    -open 0 -data $nodedata -image $images(oplink)
        }
        "body" {
            $treeWindow insert end  $rootnode $node  -text $name \
                    -open 0 -data $nodedata -image $images(file)
        }
        "configbody" {
            $treeWindow insert end  $rootnode $node  -text "$type: $name" \
                    -open 0 -data $nodedata -image $images(file)
        }

        "constructor" -
        "destructor" {
            $treeWindow insert end  $rootnode $node  -text $type \
                    -open 0 -data $nodedata -image $images(file)
        }

        default {puts "Oops $nodedata"}
    }
    switch -- $name {
        "<Top>" -
        "<Bottom>" {
            set end_of_proc_name $node
            append end_of_proc_name "_end_of_proc"
            $Editor::current(text) mark set $node $startIndex
            if {$name eq "<Top>"} {
                $Editor::current(text) mark gravity $node left
                $Editor::current(text) mark gravity $end_of_proc_name left
            }
            $Editor::current(text) mark set $end_of_proc_name $endIndex
            return $node
        }
        "file" {return ""}

        default {
	    if {$type ne "args"} {
                set Editor::procMarks($node) $type
                set end_of_proc_name $node
                append end_of_proc_name "_end_of_proc"
                set Editor::procMarks($end_of_proc_name) $type
	    }
            $Editor::current(text) mark set $node $startIndex
            $Editor::current(text) mark set $end_of_proc_name $endIndex
            $Editor::current(text) mark gravity $end_of_proc_name left
            return $node
        }
    }
}

################################################################################
#
#  proc Editor::tgetData
#
#  gets the data for a given node
#
# zerbst@tu-harburg.d
################################################################################

proc Editor::tgetData {node} {
    variable treeWindow

    if {[catch {$treeWindow itemcget $node -data} data]} {
        set data ""
    }
    return $data
}

################################################################################
#
#  proc Editor::tmoddir
#
#  needed to open / close a node in the tree. Gets open/close in $idx and
#  the name of the node in $node
#
# zerbst@tu-harburg.d
################################################################################

proc Editor::tmoddir { idx node } {
    global images
    variable treeWindow

    set data [$treeWindow itemcget $node -data]
    set type [lindex $data 1]
    set img ""
    switch -- $type {
        "namespace" {
            if $idx {
                set img namespace
            }
        }
        "class" -
        "file" {
            if $idx {
                #Open
                if { [llength [$treeWindow nodes $node]] } {
                    set img openfold
                } else {
                    set img folder
                }
            } else {
                #close
                set img folder
            }
        }
        "code" {
            if $idx {
                #Open
                set name [lindex $data 1]
                if {$name eq "<Top>"} {
                    set img top
                } elseif {$name eq "<Bottom>"} {
                    set img bottom
                } else {
                    set img qmark
                }
            }
        }
        "forward" {
            if $idx {
                #Open
                set img oplink
            }
        }
        "proc" -
        "configbody" -
        "body" -
        "constructor" -
        "destructor" -
        "method" -
        "public method" -
        "private method" -
        "protected method" {
            if $idx {
                #Open
                set img file
            }
        }

        default {
            if $idx {
                #Open
                set img openfold
            }
        }
    }
    if {$img ne ""} {
        $treeWindow itemconfigure $node -image $images($img)
    }
}

################################################################################
#
#  proc Editor::topen
#
#  opens the complete tree
#
# zerbst@tu-harburg.d
################################################################################

proc Editor::topen {} {
    variable treeWindow
    variable current

    regsub -all " " $current(file) \306 node
    regsub ":$" $node \327 node
    regsub -all "\\\$" $node "²" node
    $treeWindow opentree $node 0
}

################################################################################
#
#  proc Editor::tclose
#
#  closes the complete tree
#
# zerbst@tu-harburg.d
################################################################################
proc Editor::tclose {} {
    variable treeWindow
    variable current

    set node $current(file)
    regsub -all " " $node \306 node
    regsub ":$" $node \327 node
    regsub -all "\\\$" $node "²" node
    $treeWindow closetree $node
}

################################################################################
#
#  proc Editor::tselectObject
#
#  selects the objects choosen from the tree
#
# zerbst@tu-harburg.d
################################################################################

proc Editor::tselectObject {node} {
    variable current
    variable treeWindow
    variable notebook
    variable procMarks

    Editor::procList_history_add
    $treeWindow selection clear
    $treeWindow selection set $node

    #Switch to the right notebook
    set filename [lindex [split $node \u018b] 0]
    # get rid of the Æ (as a substitude for a space) in the filename
    regsub -all \306 $filename " " filename
    set pagelist [array names ::Editor::text_win]
    set found 0
    set pagename ""
    foreach nbPage $pagelist {
        if {$Editor::text_win($nbPage) eq $filename} {
            set i [lindex [split $nbPage ,] 0]
            set pagename $::Editor::text_win($i,pagename)
            set found 1
            break
        }
    }

    catch {$notebook raise $pagename}
    if {[catch {$current(text) mark set insert $node}]} {
        return
    }
    $current(text) see insert
    editorWindows::flashLine
    Editor::selectObject 0
    editorWindows::ReadCursor
    Editor::procList_history_add
    set current(lastPos) [$current(text) index insert]
    focus [$current(text) cget -textWidget]
    return
}

################################################################################
#
#  proc Editor::tsee
#
#  show the now
#
# zerbst@tu-harburg.d
################################################################################
proc Editor::tsee {node} {
    variable treeWindow

    $treeWindow see $node
}

################################################################################
#
#  proc Editor::torder
#
#  order the tree by types and alphabet
#
#  zerbst@tu-harburg.de
#
#  rewritten by A.Sievers 02/06/00
#
################################################################################

proc Editor::torder {node} {
    variable treeWindow
    variable current

    regsub -all " " $node \306 node
    regsub ":$" $node \327 node
    regsub -all "\\\$" $node "²" node

    proc sortTree {node} {
        variable treeWindow
        set children [$treeWindow nodes $node]
        if {[llength $children] == 0} {
            return
        }
        set tempList ""
        foreach child $children {
            sortTree $child
            set childText [$treeWindow itemcget $child -text]
            if {$childText eq "<Top>" || $childText eq "<Bottom>"} {
                continue
            }
            lappend tempList "$childText\#$child"
        }
        set sortedList ""
        set tempList [lsort -dictionary $tempList]

        foreach childNode $tempList {
            set nodeName [string range $childNode [expr [string first \# $childNode]+1] end]
            lappend sortedList $nodeName
        }
        $treeWindow reorder $node $sortedList
        return
    }

    proc realorderTree {node} {
        variable treeWindow
        variable current

        set children [$treeWindow nodes $node]
        if {[llength $children] == 0} {
            return
        }
        set indexList {}
        foreach child $children {
            set childText [$treeWindow itemcget $child -text]
            if {$childText eq "<Top>" || $childText eq "<Bottom>"} {
                continue
            }
            realorderTree $child

if {[catch {$current(text) index $child}]} {
    puts stderr [$current(text) mark names]
}
            set index [$current(text) index $child]
            set newItem $index
            lappend newItem $child
            lappend indexList $newItem
        }
        #now we have a list of children with "index name"
        set itemList [lsort -dictionary $indexList]
        set realorderList {}
        foreach item $itemList {
            lappend realorderList [lindex $item 1]
        }
        #now we have a realorderList for child
        $treeWindow reorder $node $realorderList
        return
    }

    if {$Editor::options(sortProcs)} {
        sortTree $node
    } else {
        realorderTree $node
    }
}

################################################################################
# proc Editor::evalMain
# will be called from within a slave-interpreter to do something within
# the main-interpreter
################################################################################

proc Editor::evalMain {args} {
    uplevel #0 eval $args
}

proc Editor::setTestTermBinding {sock terminal} {
    variable current
    set Editor::current(sock) $sock
    bind $terminal <KeyPress-Return> {%W mark set insert "prompt lineend"}
    bind $terminal <KeyRelease-Return> {
        set command [getCommand %W]
        %W tag configure output -foreground blue
        interp eval $Editor::current(slave) [list set termCommand $command]
        interp eval $Editor::current(slave) {
            puts $sock $termCommand
        }
        break
    }
}

proc Editor::deleteTestTerminal {pagename} {
    variable con_notebook

    $con_notebook delete $pagename
    $con_notebook raise asedCon
}

proc Editor::checkSyntaxFrink {{file {}}} {
    variable current
    global EditorData
    set result ""
    if {[catch {exec frink -V} info]} {
        conPuts "Couldn't find \"frink\" (syntax-checker): No syntaxcheck supported!" error
        return ""
    } else {
        if {$file eq {}} {
            if {[$current(text) edit modified]} {
                Editor::saveFile
            }
            set file $current(file)
        }
        catch {exec -keepnewline frink -J -M -H -Y -U $file} res
        conPuts "\nSyntaxCheck Results for $file:\nUsed Syntax-Checker: $info" output {} 0 1 0
        foreach line [split $res \n] {
            set temp [lindex [split $line :] 0]
            if {[string tolower [lindex $temp end]] eq "error"} {
                conPuts $line error {} 0 1 0
                append result $line\n
            } else {
                if {$EditorData(options,skipWarnings)} {
                    #do nothing
                } elseif {$EditorData(options,skipVarWarnings)} {
                    if {[regexp -- {Warning : variable} $line]} {
                        # skip line
                    } else {
                        conPuts $line output {} 0 1 0
                        append result $line\n
                    }
                } else {
                    conPuts $line output {} 0 1 0
                    append result $line\n
                }
            }
        }
        if {$result ne ""} {
            conPuts [tr "Syntax-Check done."]
            conPuts [tr "Double click on a line above to edit"]
        } else {
            conPuts [tr "Syntax-Check done."]
        }
        return $result
    }
}

proc Editor::checkSyntax {{file {}}} {
    variable current
    global EditorData
    global ASEDsRootDir
    set result ""
    set tdkchecker [file join $ASEDsRootDir .. TDK checker]
    set tdkchecker [file normalize $tdkchecker]
    if {![file readable $tdkchecker]} {
	tailcall checkSyntaxFrink $file
    }
    if {$file eq {}} {
	if {[$current(text) edit modified]} {
	    Editor::saveFile
	}
	set file $current(file)
    }
    set fullfile [file normalize $file]
    catch {exec -keepnewline [info nameofexecutable] $tdkchecker -- -W3 $fullfile} res
    conPuts "\nSyntaxCheck Results for $file:\nUsed Syntax-Checker: checker" output {} 0 1 0
    set shownext 0
    foreach line [split $res \n] {
	if {[string first "scanning:" $line] == 0 ||
	    [string first "checking:" $line] == 0 ||
	    $line eq "child process exited abnormally"} {
	    set shownext 0
	    continue
	}
	if {$shownext} {
	    conPuts $line output {} 0 1 0
	    append result $line\n
	    incr shownext -1
	    continue
	}
	if {[string match -nocase {[A-Z]:} $line]} {
	    set index [string first ":" $line 2]
	} else {
	    set index [string first ":" $line]
	}
	if {$index > 1} {
	    incr index
	    set temp [string range $line $index end]
	    if {[string match "*error*" $temp]} {
		conPuts $line error {} 0 1 0
		append result $line\n
		incr shownext 2
	    } elseif {$EditorData(options,skipWarnings)} {
		# do nothing
	    } elseif {$EditorData(options,skipVarWarnings)} {
		if {[string match "*warnUndefinedVar*" $temp]} {
		    # skip line
		} else {
		    conPuts $line output {} 0 1 0
		    append result $line\n
		    incr shownext 2
		}
	    } else {
		conPuts $line output {} 0 1 0
		append result $line\n
		incr shownext 2
	    }
	}
    }
    if {$result ne ""} {
	conPuts [tr "Syntax-Check done."]
	conPuts [tr "Double click on a line above to edit"]
    } else {
	conPuts [tr "Syntax-Check done."]
    }
    return $result
}

proc Editor::showlineFromCon {w} {
    set line [$w get "insert linestart" "insert lineend"]
    if {[string trim $line] eq ""} {
        return
    }
    set index -1
    if {[regexp -- {:[0-9]+ } $line lineNo]} {
	# seems to be a checker result line with file name and line number
	if {[string match -nocase {[A-Z]:} $line]} {
	    set index [string first ":" $line 2]
	} else {
	    set index [string first ":" $line]
	}
	if {$index < 1} {
	    set index -1
	}
    }
    if {$index > 0 || [regexp -- {([0-9]+)(\))*$} $line lineNo]} {
        set cursorMainWindow [. cget -cursor]
        set cursorConsole [$w cget -cursor]
        set cursorEditor [$Editor::current(text) cget -cursor]
        . configure -cursor watch
        $w configure -cursor watch
        $Editor::current(text) configure -cursor watch
	if {$index <= 0} {
	    regexp -- {[0-9]+} $lineNo lineNo
	}
	if {$index > 0} {
	    # seems to be a checker result line with file name and line number
	    set file [string range $line 0 $index]
	    incr index
	    scan [string range $line $index end] %d lineNo
            if {![file readable $file]} {
                set file $Editor::current(file)
            }
            # openNewPage filename nocomplain=1 if file is already opened
            $Editor::current(text) configure -cursor $cursorEditor
            Editor::openNewPage $file 1
            Editor::gotoLine $lineNo
	} elseif {[string first "*** " $line] == 0} {
            # seems to be a frink-result-line
            set line [lindex [split $line :] 0]
            set file [string range $line 4 [expr [string wordstart $line end-1]-2]]
            if {![file readable $file]} {
                set file $Editor::current(file)
            }
            # openNewPage filename nocomplain=1 if file is already opened
            $Editor::current(text) configure -cursor $cursorEditor
            Editor::openNewPage $file 1
            Editor::gotoLine $lineNo
        } elseif {[regexp -- {\%[\t\ ]+\(.*proc} $line]} {
            # probably an error-message
            # try getting the right file and line
            # proc-name-line
            regsub {^.*\%[\t\ ]+\(.*proc[^\ ]*} $line "" temp
            set newline [string trim $temp]
            scan $newline %s procname
            set procname [string trim $procname \"\,\;]
            set fif::fif(findFilter) "*.\{tcl,tk,itk,itcl,exp,test\}"
            set fif::fif(caseOff) 1
            set fif::fif(rexpOn) 1
            set fif::fif(subfolderOn) 1
            set fif::fif(command) ""
            set fif::fif(workingDir) [file dirname [info script]]
            set fif::fif(findDir) $fif::fif(workingDir)
            set fif::fif(findStr) "\^\[\\t\\ \]*proc $procname\ "
            set resultList [fif::grep [file dirname [info script]] 1]
            foreach {entry} $resultList {
                set file [lindex $entry 0]
                if {[file readable $file]} {
                    break
                } else {
                    set file ""
                }
            }
            if {$file eq ""} {
                return
            } else {
                set lineNumber [lindex [split [lindex $entry 1] "."] 0]
                incr lineNumber $lineNo
                incr lineNumber -1
                # openNewPage filename nocomplain=1 if file is already opened
                $Editor::current(text) configure -cursor $cursorEditor
                Editor::openNewPage [file normalize $file] 1
                Editor::gotoLine $lineNumber
            }
        } elseif {[regexp -- {\%[\t\ ]+\(.*file\ } $line]} {
            # line with filename
            regsub {^.*\%[\t\ ]+\(.*file\ } $line "" temp
            set newline [string trim $temp]
            # scan $newline %s file
            set file [lindex $newline 0]
            set file [string trim $file \"]
            tk_messageBox -message $file -parent .
            $Editor::current(text) configure -cursor $cursorEditor
            Editor::openNewPage $file 1
            Editor::gotoLine $lineNo
        } else {
            # try lineNo for current file
            set file $Editor::current(file)
            $Editor::current(text) configure -cursor $cursorEditor
            Editor::openNewPage $file 1
            Editor::gotoLine $lineNo
        }
        . configure -cursor $cursorMainWindow
        $w configure -cursor $cursorConsole
        $Editor::current(text) configure -cursor $cursorEditor
    }
}

################################################################################
# proc Editor::execFile
# runs current editor-data without saving to file,
# or associated or default projectfile with data of the current window
################################################################################

proc Editor::execFile {} {
    global tk_library
    global tcl_library
    global tcl_platform
    global images
    global auto_path
    global conWindow
    global code
    global EditorData
    variable current

    if {$EditorData(options,useEvalServer)} {
        serverExecFile
        return
    }

    Editor::argument_history_add
    #aleady running ?
    if {[interp exists $current(slave)]} {
        switch -- [tk_messageBox -message "$current(file) is already running!\nRestart ?" -type yesnocancel -icon question -title "Question" -parent .] {
            yes {
                Editor::exitSlave $current(slave)
                set tempFile "$current(file)\~~"
                if {[Editor::file_copy $tempFile $current(file)] == 0} {
                    file delete $tempFile
                }
                after idle Editor::execFile
                return
            }
            no {}
            cancel {}
            default {}
        }
        return
    }
    set cursor [. cget -cursor]
    . configure -cursor watch

    set hasChanged [$current(text) edit modified]
    if {[string trimright $current(file) 0123456789] ne [tr "Untitled"] && $current(writable)} {
        if {[file_copy $current(file) "$current(file)\~~"]} {
            Editor::saveFile
            file_copy $current(file) "$current(file)\~~"
        } else {
            Editor::saveFile
        }
    }
    if {$EditorData(options,skipCheck) == 0} {
        set res [Editor::checkSyntax $current(file)]
        if {$res ne ""} {
            switch -- [tk_messageBox \
			    -message [tr "Failed Syntaxcheck"].\n[tr "Continue anyway?"] \
			    -parent . \
			    -type yesno \
			    -icon warning \
			    -title [tr "Warning"] \
                    ] {
                        "yes" {
                            # continue
                        }
                        "no" -
                        "default" {
                            . configure -cursor $cursor
                            return
                        }
                    }
        }
    }
    update
    set current(slave) [interp create]
    set Editor::slaves($current(slave)) $Editor::current(pagename)
    interp eval $current(slave) set page $current(pagename)
    $current(slave) alias _exitSlave Editor::exitSlave
    if {$tcl_platform(platform) eq "windows"} {
        $current(slave) alias conPuts conPuts
        interp eval $current(slave) {
            rename puts origPuts
            proc puts {args} {
                switch -- [llength $args] {
                    0 {return}
                    1 {eval conPuts $args}
                    2 {if {[lindex $args 0] eq "-nonewline"} {
                            eval conPuts $args
                        } else {
                            eval origPuts $args
                        }}
                    default {eval origPuts $args}
                }
            }
        }
    }
    $current(slave) alias evalMain Editor::evalMain
    if {($current(project) eq "none") || ([string trimright $current(file) 0123456789] eq [tr "Untitled"] || $current(file) eq $current(project))} {
        set current(data) [$current(text) get 1.0 end-1c]
        interp eval $current(slave) set data [list $current(data)]
    } else {
        if {[file exists $current(project)]} {
            set fd [open $current(project) r]
            interp eval $current(slave) set data [list [read $fd]]
            close $fd
        } else {
	    set tmp " "
	    append tmp [tr "ProjectFile"] "<" $current(project) ">"
	    append tmp [tr "not found"] "!"
            tk_messageBox -message $tmp -title [tr "Error"] -icon error -parent .
            after idle Editor::exitSlave $current(slave)
            return
        }
    }
    # ToDo:
    # setup for interpreter environment via dialog
    set tmp [tr "start test of"]
    append tmp " " $current(file)
    conPuts $tmp
    interp eval $current(slave) set slave $current(slave)
    interp eval $current(slave) set conWindow $conWindow
    interp eval $current(slave) set argv [list $Editor::argument_var]
    interp eval $current(slave) set argc [llength [list $Editor::argument_var]]
    interp eval $current(slave) set argv0 [list $current(file)]
    interp eval $current(slave) set tcl_library [list $tcl_library]
    interp eval $current(slave) set tk_library [list $tk_library]
    interp eval $current(slave) set auto_path [list $auto_path]
    $current(slave) alias tr tr
    interp eval $current(slave) {
        proc _exitProc {{exitcode 0}} {
            global slave
            catch {_exitSlave $slave}
        }
        cd [file dirname $argv0]
        lappend auto_path [file dirname $argv0]
        # conPuts $auto_path
        load {} Tk
        interp alias {} exit {} _exitProc
        wm protocol . WM_DELETE_WINDOW {_exitProc}
        set code [catch {eval $data} info]
        # catch {
        if {$code} {
            tk_messageBox -message $errorInfo -title [tr "Error"] -icon error -parent .
            after idle _exitProc
        }
        # }
    }
    if {[string trimright $current(file) 0123456789] ne [tr "Untitled"]} {
        set tempFile "$current(file)\~~"
        if {![Editor::file_copy $tempFile $current(file)]} {
            file delete $tempFile
        }
    }
    $current(text) edit modified $hasChanged
    if {[$current(text) edit modified]} {
        $Editor::notebook itemconfigure $current(pagename) -image $images(redball)
    }
    update idletasks
    . configure -cursor $cursor
    catch {
        interp eval $current(slave) {
            if {[wm title .] ne ""} {
		set tmp [tr "ASED is running: "]
		append tmp ">>" [wm title .] "<<"
		wm title . $tmp
            } else {
                if {$current(project) ne "none" && $current(project) ne $current(file)} {
		    set tmp [tr "ASES is running: "]
		    append tmp $current(project) [tr " - Test of :"]
		    append tmp ">>" $current(file) "<<"
                    wm title . $tmp
                } else {
		    set tmp [tr "ASES is running: "]
		    append tmp ">>" $current(file) "<<"
                    wm title . $tmp
                }
            }
        }
    }
}

proc Editor::chooseWish {} {
    global tcl_platform
    global EditorData
    global ASEDsRootDir
    variable serverUp

    if {$serverUp} {
        switch -- [tk_messageBox \
		       -message [tr "Restart Server ?"]\n[tr "This will shutdown currently running applications!"] \
		       -icon warning \
		       -parent . \
		       -title [tr "Restart Server ?"] \
		       -type yesnocancel] {
                    yes {
                        foreach slaveInterp [interp slaves] {
                            # don't delete console interpreter
                            if {$slaveInterp ne "asedCon"} {
                                catch {Editor::exitSlave $slaveInterp}
                            }
                        }
                        set slave [interp create exitInterp]
                        interp eval $slave set ASEDsRootDir [list $ASEDsRootDir]
                        interp eval $slave {set argv0 "shutdown Server"}
                        # interp eval $slave {load {} Tk}
                        interp eval $slave source [list [file join $ASEDsRootDir evalClient.tcl]]
                        $slave alias _exitSlave Editor::exitSlave
                        interp eval $slave set slave $slave
                        interp eval $slave {
                            proc _exitProc {} {
                                global slave
                                after 500 {_exitSlave $slave}
                            }
                            interp alias {} exit {} _exitProc
                            # wm protocol . WM_DELETE_WINDOW _exitProc
                        }
                        interp eval $slave Client::exitExecutionServer $EditorData(options,serverPort)
                        interp delete $slave
                    }
                    default {
                        return
                    }
                }
    }
    if {$tcl_platform(platform) eq "windows"} {
        set filePatternList [list [tr "Executables { *.exe }"] [tr "All-Files {*.*}"]]
    } else {
        set filePatternList [list [tr "All-Files {*}"]]
    }
    if {$EditorData(options,serverWish) ne ""} {
        set initialFile $EditorData(options,serverWish)
        set initialDir [file dirname $EditorData(options,serverWish)]
    } else {
        set initialFile [info nameofexecutable]
        set initialDir [file dirname [info nameofexecutable]]
    }

    set serverWish [tk_getOpenFile \
            -filetypes $filePatternList \
            -initialdir $initialDir \
            -initialfile $initialFile \
            -title [tr "Choose an Interpreter"]]
    if {$serverWish ne {}} {
        set EditorData(options,serverWish) $serverWish
    }
    return
}

################################################################################
# proc Editor::serverExecFile
# runs current editor-data via the evalServer without saving to file,
# or associated or default projectfile with data of the current window
################################################################################

proc Editor::serverExecFile {} {
    global tk_library
    global tcl_library
    global tcl_platform
    global images
    global auto_path
    global conWindow
    global mainConsole
    global ASEDsRootDir
    global EditorData
    variable current
    variable con_notebook

    Editor::argument_history_add
    #aleady running ?
    if {[interp exists $current(slave)]} {
        switch -- [tk_messageBox \
		       -message "$current(file) [tr "is already running!"]\n[tr "Restart ?"]" \
		       -parent . \
		       -type yesnocancel \
		       -icon question \
		       -title [tr "Question"] \
	] {
            yes {
                Editor::exitSlave $current(slave)
                set tempFile "$current(file)\~~"
                if {![Editor::file_copy $tempFile $current(file)]} {
                    file delete $tempFile
                }
                after idle Editor::serverExecFile
                return
            }
            no {
                set dummy 0
            }
            cancel {
                set dummy 0
            }
            default {
            }
        }
        return
    }

    if {$EditorData(options,serverWish) eq {}} {
        set EditorData(options,serverWish) [info nameofexecutable]
    }
    # if ased was updated and ased itself was choosen as executable (=default)
    # then update evalServer to the new version to avoid ased to hang
    if {[string first "ased" [file tail $EditorData(options,serverWish)]] == 0} {
        set EditorData(options,serverWish) [info nameofexecutable]
    }

    set cursor [. cget -cursor]
    . configure -cursor watch

    set hasChanged [$current(text) edit modified]
    if {[string trimright $current(file) 0123456789] ne [tr "Untitled"] && $current(writable)} {
        if {$hasChanged} {
            # make safety copy to tmp file
            if {[file_copy $current(file) "$current(file)\~~"]} {
                Editor::saveFile
                file_copy $current(file) "$current(file)\~~"
            } else {
                Editor::saveFile
            }
        }
    }
    set tmp [tr "start test of"]
    append tmp " " $current(file)
    conPuts $tmp
    if {$EditorData(options,skipCheck) == 0} {
        conPuts [tr "performing Syntax-Check"]
        set res [Editor::checkSyntax]
        if {$res ne ""} {
            switch -- [tk_messageBox \
                -message [tr "Failed Syntaxcheck"].\n[tr "Continue anyway?"] \
                -type yesno \
                -icon warning \
		-parent . \
                -title [tr "Warning"] \
            ] {
                "yes" {
                    # continue
                }
                "no" -
                "default" {
                    . configure -cursor $cursor
                    return
                }
            }
        }
    } else {
        conPuts [tr "skipping Syntax-Check"]
    }
    update
    set current(slave) [interp create]
    set Editor::slaves($current(slave)) $Editor::current(pagename)
    interp eval $current(slave) set page $current(pagename)
    $current(slave) alias _exitSlave Editor::exitSlave
    $current(slave) alias ConPuts conPuts
    $current(slave) alias EvalMain Editor::evalMain
    $current(slave) alias NoteBookDelete Editor::deleteTestTerminal
    $current(slave) alias SetTestTermBinding Editor::setTestTermBinding
    $current(slave) alias tr tr
    if {($current(project) eq "none") || ([string trimright $current(file) 0123456789] eq [tr "Untitled"] || $current(file) eq $current(project))} {
        set current(data) [$current(text) get 1.0 end-1c]
        interp eval $current(slave) [list set data $current(data)]
    } else {
        if {[file exists $current(project)]} {
            set fd [open $current(project) r]
            interp eval $current(slave) [list set data [read $fd]]
            close $fd
            cd [file dirname $current(project)]
        } else {
            tk_messageBox -message <$current(project)>[tr "ProjectFile not found !"] -title [tr "Error"] -icon error -parent .
            after idle Editor::exitSlave $current(slave)
            conPuts [tr "ProjectFile not found !"]
            return
        }
    }
    #create testTerminal
    set testTerminal [EditManager::create_testTerminal $con_notebook $current(pagename) [file tail $current(file)]]
    $con_notebook raise $current(pagename)
    set tmp [tr "output of"]
    append tmp " " $Editor::current(file) ":"
    conPuts $tmp output
    # ToDo:
    # setup for interpreter environment via dialog
    interp eval $current(slave) set slave $current(slave)
    interp eval $current(slave) set conWindow $conWindow
    interp eval $current(slave) set mainConsole $mainConsole
    interp eval $current(slave) set argv [list $Editor::argument_var]
    interp eval $current(slave) set argc [llength [list $Editor::argument_var]]
    interp eval $current(slave) set argv0 [list $current(file)]
    interp eval $current(slave) set tcl_library [list $tcl_library]
    interp eval $current(slave) set tk_library [list $tk_library]
    interp eval $current(slave) set auto_path [list $auto_path]
    interp eval $current(slave) set ASEDsRootDir [list $ASEDsRootDir]
    interp eval $current(slave) set title [file tail $current(file)]
    interp eval $current(slave) set testTerminal $testTerminal
    interp eval $current(slave) set con_notebook $con_notebook
    interp eval $current(slave) set pagename $current(pagename)
    interp eval $current(slave) set port $EditorData(options,serverPort)
    interp eval $current(slave) set serverWish \"$EditorData(options,serverWish)\"
    interp eval $current(slave) set starkitMode $EditorData(starkit)
    if {$EditorData(starkit)} {
        interp eval $current(slave) set starkitTopdir \"$::starkit::topdir\"
    }
    interp eval $current(slave) {
        proc _exitProc {{exitcode 0}} {
            global slave
            global pagename
            NoteBookDelete $pagename
            catch {_exitSlave $slave}
            return
        }
        set newDir [cd [file dirname $argv0]]
        interp alias {} exit {} _exitProc
        source [file join $ASEDsRootDir evalClient.tcl]

        # new Client handler, overwrites default handler
        proc Client::newSockHandler {testTerminal sock} {
            variable serverResult

            if [eof $sock] {
                catch {close $sock}
                ConPuts "Socket closed $sock" error $testTerminal
                # EvalMain conPuts [list Socket closed $sock] error
                exit
                return
            }
            while {[gets $sock serverResult] > -1 } {
                if {$serverResult ne ""} {
                    set res ""
                    if {[string first "#echo:" $serverResult] == 0} {
                        lappend res [ConPuts $serverResult prompt $testTerminal]
                        EvalMain conPuts $res prompt
                    } else {
                        lappend res [ConPuts $serverResult output $testTerminal]
                        EvalMain conPuts $res output
                    }
                }
            }
            return
        }

        if {$starkitMode} {
            set homeDir [file normalize ~]
            if {[info nameofexecutable] eq $starkitTopdir} {
                # starpack-mode
                if {$serverWish eq [info nameofexecutable]} {
                    # use ASED itself
                    set sock [Client::initExecutionClient \
                        localhost \
                        $port \
                        "Client::newSockHandler $testTerminal" \
                        "-x evalServer.tcl" \
                        $serverWish \
                    ]
                } else {
                    # check if evalServer.tcl is already available outside of vfs
                    if {[file readable [file join $homeDir evalServer.tcl]]} {
                        set sock [Client::initExecutionClient \
                            localhost \
                            $port \
                            "Client::newSockHandler $testTerminal" \
                            [file join $homeDir evalServer.tcl] \
                            $serverWish \
                        ]
                    } else {
                        # we have to copy evalServer.tcl to some dir outside of the vfs
                        if {[catch {file copy [file join "$starkitTopdir" evalServer.tcl] [file join $homeDir evalServer.tcl]}]} {
                            ConPuts "Could not copy evalServer.tcl" error
                            after 1000 {_exitProc 1}
                            return
                        } else {
                            set sock [Client::initExecutionClient \
                                localhost \
                                $port \
                                "Client::newSockHandler $testTerminal" \
                                [file join $homeDir evalServer.tcl] \
                                $serverWish \
                            ]
                        }
                    }
                }
            } else {
                # starkit-mode: use tclkit to execute
                if {$serverWish eq [info nameofexecutable]} {
                    # starkitmode: use ASED to eval
                    set sock [Client::initExecutionClient \
                        localhost \
                        $port \
                        "Client::newSockHandler $testTerminal" \
                        "-x evalServer.tcl" \
                        $serverWish \
                    ]
                } else {
                    # check if evalServer.tcl is already available outside of vfs
                    if {[file readable [file join $homeDir evalServer.tcl]]} {
                        set sock [Client::initExecutionClient \
                            localhost \
                            $port \
                            "Client::newSockHandler $testTerminal" \
                            [file join $homeDir evalServer.tcl] \
                            $serverWish \
                        ]
                    } else {
                        if {[catch {file copy [file join $starkitTopdir evalServer.tcl] [file join $homeDir evalServer.tcl]}]} {
                            ConPuts "Could not copy evalServer.tcl" error
                            after 1000 {_exitProc 1}
                            return
                        } else {
                            # copy evalServer.tcl to some dir outside of the vfs
                            set sock [Client::initExecutionClient \
                                localhost \
                                $port \
                                "Client::newSockHandler $testTerminal" \
                                [file join $homeDir evalServer.tcl] \
                                $serverWish \
                            ]
                        }
                    }
                }
            }
        } else {
            # "normal operation"
            set sock [Client::initExecutionClient \
                localhost \
                $port \
                "Client::newSockHandler $testTerminal" \
                [file join $ASEDsRootDir evalServer.tcl] \
                $serverWish \
            ]
        }
        if {$sock eq {}} {
            after 10 exit
            return
        }
        EvalMain {
            set Editor::serverUp 1
            Editor::createPopMenuTreeWindow 1
        }
        SetTestTermBinding $sock $testTerminal

        puts $sock [list set argv $argv]
        puts $sock [list set argc $argc]
        puts $sock [list set argv0 $argv0]
        set data [split $data \n]
        foreach line $data {
            if {[catch {puts $sock $line}]} {
                ConPuts [tr "Error: connection to evalServer broken"] error
                set kill_command [auto_execok kill]
                if {$kill_command ne ""} {
                    exec $kill_command -f $::Client::serverPID
                }
                after 10 exit
                return
            }
        }
        puts $sock [list catch {wm deiconify .}]
        puts $sock [list catch [list set wmTitle "ASED Test Server ([file tail $serverWish]): $title"]]
        puts $sock [list catch {wm title . $wmTitle} ]
        puts $sock "catch {focus .}"
        puts $sock [list catch {bind . <Destroy> exit}]
    }
    # restore original file from tmp file
    if {[string trimright $current(file) 0123456789] ne [tr "Untitled"]} {
        set tempFile "$current(file)\~~"
        if {![Editor::file_copy $tempFile $current(file)]} {
            file delete $tempFile
        }
    }
    $current(text) edit modified $hasChanged
    if {[$current(text) edit modified]} {
        $Editor::notebook itemconfigure $current(pagename) -image $images(redball)
    }
    update idletasks
    . configure -cursor $cursor
    return
}

################################################################################
# proc Editor::terminate
# terminates execution of current editor-file or associated projectfile
################################################################################

proc Editor::terminate {} {
    variable current

    Editor::exitSlave $current(slave)
    set tempFile "$current(file)\~~"
    if {[file exists $tempFile] && [file mtime $tempFile] > [file mtime $current(file)]} {
        if {![Editor::file_copy $tempFile $current(file)]} {
            file delete $tempFile
        }
    } elseif {[file exists $tempFile]} {
        file delete $tempFile
    }
    Editor::createPopMenuTreeWindow 1
    # Editor::terminateEvalServer
}

proc Editor::exitSlave {slave} {
    variable current
    variable serverUp

    if {[interp exists $slave]} {
        interp eval $slave {
            set taskList [after info]
            foreach id $taskList {
                after cancel $id
            }
        }
        catch {$Editor::notebook raise $Editor::slaves($slave)}
        catch {Editor::deleteTestTerminal $Editor::current(pagename)}
        catch {interp delete $slave}
        unset Editor::slaves($slave)
        set current(slave) "none"
        catch {$Editor::con_notebook delete $current(pagename)}
        conPuts [tr "Application terminated!"] output {} 0 1 1
    }
    Editor::createPopMenuTreeWindow 1
    . configure -cursor {}
    set serverUp 0
    return
}

proc Editor::file_copy {in out} {
    if {[file exists $in]} {
        file copy -force $in $out
        return 0
    } else {
        return 1
    }
}

################################################################################
# proc Editor::getFile
# openfile dialog
# returns filename and content of the file
################################################################################

proc Editor::getFile {{filename {}}} {
    global EditorData
    variable treeWindow
    # workaround to avoid button1 events to be processed in ASED-windows while
    # double clicking a file in tk_getOpenFile
    bind $treeWindow <Button-Release-1> {}
    set EditorData(getFileMode) 1
    if {$filename eq {}} {
        if {$EditorData(options,useDefaultExtension)} {
            # set defaultExt .tcl
            set filePatternList [list [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] [tr "All {*.* *}"]]
        } else {
            # set defaultExt ""
            set filePatternList [list [tr "All {*.* *}"] [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] ]
        }
        set defaultExt ""
        set initialFile ""
        set filename [tk_getOpenFile -filetypes $filePatternList -initialdir $EditorData(options,workingDir) -title [tr "Open File"]]
    }
    if {[file exists $filename]} {
        set cursor [. cget -cursor]
        . configure -cursor watch
        update
        if {[file writable $filename]} {
            set fd [open $filename r+]
        } elseif {[file readable $filename]}  {
            tk_messageBox -message [tr "File is write protected!"]\n[tr "Opened file as read only!"] -parent .
            set fd [open $filename r]
        } else {
            tk_messageBox -message [tr "Permission denied!"] -parent .
            return ""
        }
        set data [read $fd]
        close $fd
        . configure -cursor $cursor
        set EditorData(options,workingDir) [file dirname $filename]
        after 10000 {catch {
                # if anything failes, we will fall back to normal behaviour
                # for button-release-events after 10 sec
                global EditorData
                set EditorData(getFileMode) 0
            }
        }
        return [list $filename $data]
    } else {
        return ""
    }
}

proc Editor::openNewPage {{file {}} {nocomplain 0}} {
    global EditorData
    variable notebook
    variable current

    set temp [Editor::getFile $file];#returns filename and textdata
    if {$temp eq ""} {
        return 1
    }
    set filename [lindex $temp 0]
    if {$filename eq ""} {
        return 1
    }

    # If file already open: return
    foreach textWin [array names ::Editor::index] {
        set idx $Editor::index($textWin)
        if {$Editor::text_win($idx,file) eq $filename} {
            if {$nocomplain} {
            } else {
                tk_messageBox -message [tr "File already opened !"] -title [tr "Warning"] -icon warning -parent .
            }
            $notebook raise $Editor::text_win($idx,pagename)
            return 1
        }
    }

    set EditorData(options,workingDir) [file dirname $filename]
    set f0 [EditManager::create_text $notebook $filename ]
    set data [lindex $temp 1]

    set temp [$editorWindows::TxtWidget edit modified]
    set editorWindows::TxtWidget [lindex $f0 2]
    $editorWindows::TxtWidget fastinsert 1.0 $data
    $editorWindows::TxtWidget mark set insert 1.0
    $editorWindows::TxtWidget edit modified $temp

    # set Editor::text_win($Editor::index_counter,undo_id) [new textUndoer $editorWindows::TxtWidget]
    NoteBook::raise $notebook [lindex $f0 1]
    $Editor::mainframe setmenustate noFile normal
    update
    #Now the new textwindow is the current
    #needs TxtWidget !
    editorWindows::colorize
    if {[file writable $filename]} {
        set current(writable) 1
    } elseif {[file readable $filename]}  {
        set current(writable) 0
    } else {
        tk_messageBox -message [tr "Permission denied!"] -parent .
        return 1
    }
    $editorWindows::TxtWidget edit reset
    $editorWindows::TxtWidget edit modified 0
    set current(lastPos) [$current(text) index insert]
    return 0
}

################################################################################
# proc Editor::setDefaultProject
# if default project file is set then this will be run from any window by
# pressing the Test button instead of the current file, except for the current
# file is associated to another projectfile
################################################################################

proc Editor::setDefaultProject {{filename {}}} {
    global EditorData
    variable current

    if {$filename eq "none"} {
        switch -- [tk_messageBox -message [tr "Do you want to unset current default project ?"] \
		       -type yesnocancel -icon question \
		       -parent . \
		       -title [tr "Question"]] {
                    yes {
                        set EditorData(options,defaultProjectFile) "none"
                        set current(project) "none"
                    }
                    default {}
                }
        return
    }

    if {$filename eq {}} {
        if {$EditorData(options,useDefaultExtension)} {
            # set defaultExt .tcl
            set filePatternList [list [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] [tr "All {*.* *}"]]
        } else {
            # set defaultExt ""
            set filePatternList [list [tr "All {*.* *}"] [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] ]
        }
        set defaultExt ""
        set initialFile ""
        set filename [tk_getOpenFile -filetypes $filePatternList -initialdir $EditorData(options,workingDir) -title "Select Default Project File"]
    }
    if {$filename ne ""} {
        set oldfile $EditorData(options,defaultProjectFile)
        set EditorData(options,defaultProjectFile) $filename
        # only set current(project) if it is not set by projectassociaion
        if {$current(project) eq $oldfile} {
            set current(project) $filename
        }
    }
}

################################################################################
# proc Editor::associateProject
# if there is a projectfile associated to the current file,
# this file will be started by pressing the test button.
# This overrides the option for the default project file
################################################################################

proc Editor::associateProject {} {
    global EditorData
    variable current

    if {$EditorData(options,useDefaultExtension)} {
        # set defaultExt .tcl
        set filePatternList [list [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] [tr "All {*.* *}"]]
    } else {
        # set defaultExt ""
        set filePatternList [list [tr "All {*.* *}"] [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] ]
    }
    set defaultExt ""
    set initialFile ""
    set filename [tk_getOpenFile -filetypes $filePatternList -initialdir $EditorData(options,workingDir) -title "Select Project File"]
    if {$filename ne ""} {
        set current(project) $filename
        set prjFile [file rootname $current(file)].prj
        set result [Editor::_saveFile $prjFile $current(project)]
    }
}

proc Editor::unsetProjectAssociation {} {
    global EditorData
    variable current

    set prjFile [file rootname $current(file)].prj
    if {[file exists $prjFile]} {
        file delete $prjFile
    }
    set current(project) $EditorData(options,defaultProjectFile)
}

proc Editor::openFile {{file {}} {nocomplain 0}} {

    variable notebook
    variable current
    variable index
    variable last

    set deleted 0
    # test if there is a page opened
    set pages [NoteBook::pages $notebook]
    if {[llength $pages] == 0} {
        Editor::openNewPage $file $nocomplain
        return
    } else {
        # test if current page is empty
        if {[info exists current(text)]} {
            set f0 $current(pagename)
            set text [NoteBook::itemcget $notebook $f0 -text]

            set data [$current(text) get 1.0 end-1c]
            set delpage 0
            if {($data eq "") && ([string trimright $text 0123456789] eq [tr "Untitled"])} {
                # page is empty, parameter 1 causes closeFile not to open a new page
                Editor::closeFile 1
                set deleted 1
            }
        }

        set result [Editor::openNewPage $file $nocomplain]
        #if no file was opened craete a new blank page
        if {$deleted && $result} {
            set force 1
            Editor::newFile force
        }
    }
}

proc Editor::saveAll {} {
    global EditorData
    foreach textWin [array names ::Editor::index] {
        set idx $Editor::index($textWin)
        if {$Editor::text_win($idx,writable) == 0} {
            set filename $Editor::text_win($idx,file)
            tk_messageBox -message $filename\n[tr "File is write protected!"]\n[tr "Can't save "] -parent .
            continue
        }
        set data [$textWin get 1.0 "end -1c"]
        set filename $Editor::text_win($idx,file)
        if {$EditorData(options,createBackupFiles)} {
            catch {Editor::file_copy $filename "$filename\~"}
        }
        Editor::_saveFile $filename $data
        $textWin edit modified 0
        $Editor::notebook itemconfigure $Editor::text_win($idx,pagename) -image ""
    }
}

proc Editor::_saveFile {filename data} {
    global EditorData
    variable current

    if {[string trimright $filename 0123456789] eq [tr "Untitled"]} {
        Editor::_saveFileas $filename $data
        return
    }
    set cursor [. cget -cursor]
    . configure -cursor watch
    update
    if {[catch {set fd [open $filename w+]}]} {
	set tmp $filename
	append tmp " " [tr "is write protected!"] "\n"
	append tmp [tr "Use SAVE AS.. instead!"]
        tk_messageBox -message $tmp -parent .
        return
    }
    fconfigure $fd -translation $EditorData(options,endOfLineMode)
    puts -nonewline $fd $data
    flush $fd
    close $fd
    . configure -cursor $cursor
    return
}

proc Editor::saveFile {} {
    variable notebook
    variable current
    variable index
    global EditorData

    if {[$notebook pages] eq {}} {
        # No open file
        return
    }

    set filename $current(file)
    if {[string trimright $filename 0123456789] eq [tr "Untitled"]} {
        Editor::saveFileas
        return
    }
    if {[file writable $filename] == 0} {
	set tmp $filename
	append tmp " " [tr "is write protected!"] "\n"
	append tmp [tr "Use SAVE AS.. instead!"]
        tk_messageBox -message $tmp -parent .
        Editor::saveFileas
        return
    }

    set data [$current(text) get 1.0 end-1c]
    if {$EditorData(options,createBackupFiles)} {
        catch {Editor::file_copy $filename "$filename\~"}
    }
    set result [Editor::_saveFile $current(file) $data]
    $current(text) edit modified 0
    $Editor::notebook itemconfigure $current(pagename) -image ""
    set idx $index($current(text))
    set Editor::text_win($idx,hasChanged) [$current(text) edit modified]
    if {$current(project) ne "none"} {
        set prjFile [file rootname $current(file)].prj
        set result [Editor::_saveFile $prjFile $current(project)]
    }
}

proc Editor::_saveFileas {filename data} {
    global EditorData

    set filePatternList [list [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] [tr "All {*.* *}"]]
    if {$EditorData(options,useDefaultExtension)} {
        # set defaultExt .tcl
        set filePatternList [list [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] [tr "All {*.* *}"]]
    } else {
        # set defaultExt ""
        set filePatternList [list [tr "All {*.* *}"] [tr "Tcl-Files {*.tcl *.tk *.itcl *.itk}"] ]
    }
    set defaultExt ""
    set initialFile $filename
    set file [tk_getSaveFile -filetypes $filePatternList -initialdir $EditorData(options,workingDir) \
            -initialfile $filename -defaultextension $defaultExt -title [tr "Save File"]]
    if {$file ne ""} {
        if {[file exists $file]} {
            if {[file writable $file]} {
                set cursor [. cget -cursor]
                . configure -cursor watch
                update
                set fd [open $file w+]
                fconfigure $fd -translation $EditorData(options,endOfLineMode)
                puts -nonewline $fd $data
                close $fd
                . configure -cursor $cursor
            } else {
                tk_messageBox -message [tr "No write permission!"] -parent .
                set file ""
            }
        } else {
            # new filename
            if {[catch {
                    set cursor [. cget -cursor]
                    . configure -cursor watch
                    update
                    set fd [open $file w+]
                    fconfigure $fd -translation $EditorData(options,endOfLineMode)
                    puts -nonewline $fd $data
                    close $fd
                    . configure -cursor $cursor
                }]} {
                tk_messageBox -message [tr "Can't save file "]$file\n[tr "Maybe no write permission!"]] -parent .
                set file ""
            }
        }
    }

    set EditorData(options,workingDir) [file dirname $file]
    return $file
}

proc Editor::saveFileas {} {
    variable notebook
    variable current

    if {[$notebook pages] eq {}} {
        # no open file
        return 1
    }

    set filename $current(file)
    set data [$current(text) get 1.0 end-1c]
    set result [Editor::_saveFileas $current(file) $data]
    if {$result eq ""} {
        return 1
    }
    set insertCursor [$current(text) index insert]
    Editor::closeFile 0 1 ;# nocomplain
    Editor::openFile $result
    $current(text) mark set insert $insertCursor
    $current(text) see insert
    Editor::selectObject 0

    #if there was already a .prj-File then copy to new name too
    if {[file exists [file rootname $filename].prj]} {
        set prjFile [file rootname $current(file)].prj
        set result [Editor::_saveFile $prjFile $current(project)]
    }
    return 0
}

proc Editor::showConsole {show} {
    variable pw1

    set win $pw1.nb
    if {$show} {
        $pw1 add $win -minsize 100 -sticky news
        catch {
            $pw1 sash place 0 [lindex [$pw1 sash coord 0] 0] [lindex $EditorData(options,sash1) 1]
        }
    } else {
        catch {set EditorData(options,sash1) [$pw1 sash coord 0]}
        $pw1 forget $win
    }
}

proc Editor::showTreeWin {show} {
    global EditorData
    variable pw2

    set win $pw2.nb1
    if {$show} {
        $pw2 add $win -minsize 250 -sticky news
        $pw2 paneconfigure $win -before $pw2.nb2
        catch {
            $pw2 sash place 0 [lindex $EditorData(options,sash2) 0] [lindex [$pw2 sash coord 0] 1]
        }
        Editor::updateObjects
        Editor::selectObject
    } else {
        catch {set EditorData(options,sash2) [$pw2 sash coord 0]}
        $pw2 forget $win
    }
}

proc Editor::showSolelyConsole {show} {
    global EditorData
    variable pw1
    variable pw2

    if {$show} {
        catch {set EditorData(options,sash1) [$pw1 sash coord 0]}
        $pw1 forget $pw2
    } else {
        $pw1 add $pw2

		# added (hans):
        catch { $pw1 paneconfigure $pw2 -before $pw1.nb }

		catch {
            $pw1 sash place 0 [lindex [$pw1 sash coord 0] 0] [lindex $EditorData(options,sash1) 1]
        }
    }
}

################################################################################
# proc Editor::close_dialog
# called whenever the user wants to exit ASED and there are files
# that have changed and are still not saved yet
################################################################################

proc Editor::close_dialog {} {
    variable notebook
    variable current
    variable index
    variable text_win
    set result [tk_messageBox -message <$current(file)>[tr " : File has been changed! Save it ?"] -type yesnocancel -icon warning -title [tr "Question"] -parent .]
    switch -- $result {
        yes {
            if {[file writable $current(file)]} {
                Editor::saveFile
                return 0
            } else {
                return [Editor::saveFileas]
            }
        }
        no  {return 0}
        cancel {return 1}
        default {}
    }
}

proc Editor::closeFile {{exit 0} {nocomplain 0}} {
    variable notebook
    variable current
    variable index
    variable last
    variable text_win
    variable procWindow
    variable mainframe

    # Is there an open window
    if {[$notebook pages] eq {}} {
        return ""
    }
    if {[$current(text) edit modified] && ($nocomplain == 0)} {
        set result [Editor::close_dialog]
        if {$result} {return $result}
    }
    # catch {if {[info exists current(undo_id)]} {delete_id}}
    # if current file is running terminate execution
    Editor::terminate
    NoteBook::delete $notebook $current(pagename)
    set idx $Editor::index($current(text))
    foreach entry [array names Editor::text_win "$idx,*"] {
        unset Editor::text_win($entry)
    }
    unset index($current(text))
    unset current(text)
    #delete node
    tdelNode $current(file)
    set indexList [NoteBook::pages $notebook]
    if {[llength $indexList] != 0} {
        NoteBook::raise $notebook [lindex $indexList end]
    } else {
        if {$exit == 0} {Editor::newFile}
    }
    return 0
}

proc Editor::terminateEvalServer {} {
    global EditorData
    global ASEDsRootDir
    variable serverUp

    if {$serverUp} {
        set slave [interp create]
        interp eval $slave set ASEDsRootDir [list $ASEDsRootDir]
        interp eval $slave set argv0 shutdown_Server
        # interp eval $slave {load {} Tk}
        interp eval $slave source [list [file join $ASEDsRootDir evalClient.tcl]]
        interp eval $slave set Client::port $EditorData(options,serverPort)
        interp eval $slave Client::exitExecutionServer
        catch {interp delete $slave}
        set serverUp 0
    }
}

proc Editor::exit_app {} {
    global EditorData
    global ASEDsRootDir
    variable notebook
    variable current
    variable index
    variable text_win
    variable serverUp

    set taskList [after info]
    foreach id $taskList {
        after cancel $id
    }
    set EditorData(options,recentPage) $current(pagename)
    set EditorData(options,recentPos) [$current(text) index insert]
    if {[$current(text) edit modified]} {
        if {[catch {set idx $index($current(text))}]} {
            exit
        }
        set text_win($idx,hasChanged) [$current(text) edit modified]
    }
    set newlist ""
    set index_list [array names index]
    foreach idx $index_list {
        set newlist [concat $newlist  $index($idx)]
    }

    Editor::getWindowPositions

    #    if no window is open, we can exit at once
    if {[llength $newlist] eq ""} {
        exit
    }

    set EditorData(options,sessionList) {}
    foreach idx $newlist {
        set current(text) $text_win($idx,path)
        set current(page) $text_win($idx,page)
        set current(pagename) $text_win($idx,pagename)
        $current(text) edit modified $text_win($idx,hasChanged)
        set current(file) $text_win($idx,file)
        lappend  EditorData(options,sessionList) $current(file)
        set current(slave) $text_win($idx,slave)
        set current(writable) $text_win($idx,writable)
        set result [Editor::closeFile exit]
        if {$result} {
            NoteBook::raise $notebook $current(pagename)
            return
        }
    }
    Editor::terminateEvalServer
    Editor::saveOptions
    exit
}

proc Editor::gotoLineDlg {} {
    variable current

    if {[winfo exists .dlg]} {
        return
    }
    set gotoLineDlg [toplevel .dlg]
    wm transient .dlg .
    set entryLabel [label .dlg.label -text [tr "Please enter line number"]]
    if {![info exists ::lineNo]} {
	set ::lineNo ""
    }
    set lineEntry [ttk::entry .dlg.entry -textvariable ::lineNo]
    set buttonFrame [frame .dlg.frame]
    set okButton [button $buttonFrame.ok -width 8 -text [tr "Ok"] -command {catch {destroy .dlg};Editor::gotoLine $lineNo}]
    set cancelButton [button $buttonFrame.cancel -width 8 -text [tr "Cancel"] -command {catch {destroy .dlg}}]
    wm title .dlg [tr "Goto Line"]
    bind $lineEntry <KeyRelease-Return> {.dlg.frame.ok invoke}
    pack $entryLabel
    pack $lineEntry
    pack $okButton $cancelButton -padx 5 -pady 5 -side left -fill both -expand yes
    pack $buttonFrame
    ::tk::PlaceWindow .dlg widget .
    focus $lineEntry
}

proc Editor::gotoLine {lineNo} {
    variable current

    switch -- [string index $lineNo 0] {
        "-" -
        "+" {set curLine [lindex [split [$current(text) index insert] "."] 0]
            set lineNo [expr $curLine $lineNo]}
        default {}
    }
    if {[catch {$current(text) mark set insert $lineNo.0}]} {
        tk_messageBox -message [tr "Line number out of range!"] -icon warning -title [tr "Warning"] -parent .
    }
    $current(text) see insert
    editorWindows::flashLine
    editorWindows::ReadCursor
    selectObject 0
    focus [$current(text) cget -textWidget]
}

proc Editor::cut {} {
    variable current

    editorWindows::cut
    set current(lastPos) [$current(text) index insert]
}

proc Editor::copy {} {
    variable current
    editorWindows::copy
}

proc Editor::paste {} {
    variable current

    editorWindows::paste
    set current(lastPos) [$current(text) index insert]
}

proc Editor::delete {} {
    variable current
    editorWindows::delete
    set current(lastPos) [$current(text) index insert]
}

proc Editor::delLine {} {
    global EditorData
    variable current
    if {[$current(text) tag range sel] ne ""} {
        Editor::delete
    }
    set curPos [$current(text) index insert]
    if {$EditorData(options,autoUpdate)} {
        set range [editorWindows::deleteMarks "$curPos linestart" "$curPos lineend"]
        $current(text) delete "$curPos linestart" "$curPos lineend +1c"
        Editor::updateOnIdle $range
    } else {
        $current(text) delete "$curPos linestart" "$curPos lineend +1c"
    }
    set current(lastPos) [$current(text) index insert]
}

proc Editor::SelectAll {} {
    variable current

    $current(text) tag remove sel 1.0 end-1c
    $current(text) tag add sel 1.0 end-1c
}

proc Editor::insertFile {} {
    variable current

    set temp [Editor::getFile];#returns filename and textdata
    set filename [lindex $temp 0]
    if {$filename eq ""} {return 1}
    if {$filename eq $current(file)} {
        tk_messageBox -message [tr "File already opened !"] -title [tr "Warning"] -icon warning -parent .
        return 1
    }
    set EditorData(options,workingDir) [file dirname $filename]
    set data [lindex $temp 1]
    set index [$current(text) index insert]
    $current(text) insert insert $data
    $current(text) see insert
    set end [$current(text) index insert]
    editorWindows::ColorizeLines [lindex [split $index "."] 0] [lindex [split [$editorWindows::TxtWidget index insert] "."] 0 ]

    updateObjects "$index $end"
    torder $current(file)
    selectObject 0
    set current(lastPos) [$current(text) index insert]
    return 0
}

proc Editor::getFirstChar { index } {

    set w $Editor::current(text)
    set curLine [lindex [split [$w index $index] "."] 0]
    set pos $curLine.0
    set char [$w get $pos]
    for {set i 0} {$char eq " " || $char eq "\t"} {incr i} {
        set pos $curLine.$i
        set char [$w get $pos]
    }
    return [list $char $pos]
}

proc Editor::make_comment_block {} {
    variable current
    variable treeWindow

    set commentLineString [string repeat \# 80]
    append commentLineString \n

    if {[$current(text) tag ranges sel] eq ""} {
        #no selection
        if {[$current(text) get "insert linestart" "insert lineend"] eq ""} {
            # empty line
            $current(text) insert insert $commentLineString
            $current(text) insert insert "# "
            set insertpos [$current(text) index insert]
            $current(text) insert insert "\n"
            $current(text) insert insert $commentLineString
            $current(text) mark set insert $insertpos
            $current(text) see insert
            set current(inCommentMode) 1
        } elseif {[$current(text) get "insert linestart" "insert linestart wordend"] eq "proc"}  {
            # insert descriptionblock template for proc
            if {([lindex [split [$current(text) index insert] .] 0] > 2) && [lindex [getFirstChar [$current(text) index "insert-2l"]] 0] eq "#"} {
                # there is probably already a comment, so skip
            } else {
                # no comment found, insert standard proc-description
                set nodeData [tgetData $current(node)]
                scan [$current(text) get "insert linestart" "insert lineend"] %s%s what proc_name
                # set proc_name [$treeWindow itemcget $current(node) -text]
                if {[lindex $nodeData 4] eq ""} {
                    set proc_args ""
                } else {
                    eval set proc_args [lindex $nodeData 4]
                }
                $current(text) insert "insert linestart" "\n"
                $current(text) mark set insert "insert - 1l"
                $current(text) insert insert $commentLineString
                $current(text) insert insert "# \n"
                $current(text) insert insert "# $what $proc_name \n"
                $current(text) insert insert "# \n"
                $current(text) insert insert "# [tr description]: "
                set editPos [$current(text) index insert]
                $current(text) insert insert "\n# \n"
                if {$proc_args eq ""} {
                    $current(text) insert insert "# [tr arguments]: [tr "none"]\n"
                } else {
                    $current(text) insert insert "# [tr arguments]:\n"
                    foreach {proc_arg} $proc_args {
                        if {[llength $proc_arg] > 1} {
                            set arg [lindex $proc_arg 0]
                            set default [lindex $proc_arg 1]
                            $current(text) insert insert "#     $arg ([tr "optional"]) [tr "default"]: $default\n"
                        } else {
                            set arg $proc_arg
                            set default ""
                            $current(text) insert insert "#     $arg \n"
                        }
                    }
                }
                $current(text) insert insert "# \n"
                $current(text) insert insert "# return value: \n"
                $current(text) insert insert "# \n"
                $current(text) insert insert $commentLineString
                $current(text) mark set insert $editPos
                $current(text) see insert
                set current(inCommentMode) 1
            }
        } elseif {[lindex [Editor::getFirstChar [$current(text) index insert]] 0] eq "#"} {
            set current(inCommentMode) 1
            return ""
        } else {
            # line is not empty
            $current(text) tag add sel "insert linestart" "insert lineend"
            Editor::make_comment_block
            return ""
        }
    } else {
        set firstLine [lindex [split [$current(text) index sel.first] "."] 0]
        set lastLine [lindex [split [$current(text) index sel.last] "."] 0]
        for {set line $firstLine} {$line <= $lastLine} {incr line} {
            $current(text) insert $line.0 "# "
        }
        $current(text) insert $firstLine.0 $commentLineString
        set lastLine [expr $lastLine+2]
        $current(text) insert $lastLine.0 $commentLineString
        for {set line $firstLine} {$line <= $lastLine} {incr line} {
            editorWindows::ColorizeLine $line
        }
        $current(text) mark set insert "insert+2l linestart"
    }
    selectObject
    return ""
}

################################################################################
# proc Editor::toggle_comment
# toggles the comment status of the current line or selection
################################################################################

proc Editor::toggle_comment {} {
    variable current

    if {[$current(text) tag ranges sel] eq ""} {
        #no selection
        set curPos [$current(text) index insert]
        set result [Editor::getFirstChar $curPos]
        if {[lindex $result 0] eq "#"} {
            $current(text) delete [lindex $result 1]
            while {[$current(text) get [lindex $result 1]] eq " " \
                        || [$current(text) get [lindex $result 1]] eq "\t"} {
                $current(text) delete [lindex $result 1]
            }
            set curLine [lindex [split [$current(text) index $curPos] "."] 0]
            editorWindows::ColorizeLine $curLine
        } else {
            set curLine [lindex [split [$current(text) index $curPos] "."] 0]
            $current(text) insert [lindex $result 1] "# "
            editorWindows::ColorizeLine $curLine
        }
        updateOnIdle [list $curLine.0 "$curLine.0 lineend"]
    } else {
        set sel_first [$current(text) index sel.first]
        set sel_last [$current(text) index sel.last]
        set firstLine [lindex [split [$current(text) index sel.first] "."] 0]
        set lastLine [lindex [split [$current(text) index sel.last] "."] 0]
        set result [Editor::getFirstChar $firstLine.0]
        set char [lindex $result 0]
        if {$char eq "#"} {
            #if first char of first line is # then uncomment selection complete
            for {set line $firstLine} {$line <= $lastLine} {incr line} {
                set result [Editor::getFirstChar $line.0]
                if {[lindex $result 0] eq "#"} {
                    $current(text) delete [lindex $result 1]
                    while {[$current(text) get [lindex $result 1]] eq " " \
                                || [$current(text) get [lindex $result 1]] eq "\t"} {
                        $current(text) delete [lindex $result 1]
                    }
                    editorWindows::ColorizeLine $line
                }
            }
        } else {
            #if first char of first line is not # then comment selection complete
            for {set line $firstLine} {$line <= $lastLine} {incr line} {
                set insertPos [lindex [getFirstChar $line.0] 1]
                $current(text) insert $insertPos "# "
                editorWindows::ColorizeLine $line
            }
        }
        $current(text) tag add sel $sel_first $sel_last
        set start [$current(text) index sel.first]
        set end [$current(text) index sel.last]
        updateOnIdle [list $start $end]
        $current(text) tag remove sel sel.first sel.last
    }
    selectObject
}

proc Editor::procList_history_get_prev {} {
    variable current

    if {[$current(text) tag ranges sel] ne ""} {
        #remove selection
        $current(text) tag remove sel [$current(text) index sel.first] [$current(text) index sel.last]
    }

    if  {$current(procListHistoryPos) == 0} {
        set index [$Editor::current(text) index insert]
        set Editor::current(lastPos) $index
        Editor::procList_history_add $index
    } elseif {$current(procListHistoryPos) == -1} {
        incr current(procListHistoryPos)
        set index [$Editor::current(text) index insert]
        set Editor::current(lastPos) $index
        Editor::procList_history_add $index
    }
    if {$current(procListHistoryPos) < [expr [llength $current(procListHistory)]-1]} {
        incr current(procListHistoryPos)
    } else {
        selectObject 0
        return
    }

    catch {$current(text) mark set insert [lindex $current(procListHistory) $current(procListHistoryPos)]}
    $current(text) see insert
    focus [$current(text) cget -textWidget]
    editorWindows::ReadCursor 0
    editorWindows::flashLine
    selectObject 0
}

proc Editor::procList_history_get_next {} {
    variable current

    if {[$current(text) tag ranges sel] ne ""} {
        #remove selection
        $current(text) tag remove sel [$current(text) index sel.first] [$current(text) index sel.last]
    }
    if {$current(procListHistoryPos) > 0} {
        incr current(procListHistoryPos) -1
    } else {
        set current(procListHistoryPos) "-1"
        selectObject 0
        return
    }
    catch {$current(text) mark set insert [lindex $current(procListHistory) $current(procListHistoryPos)]}
    if {$current(procListHistoryPos) == 0} {
        set current(procListHistoryPos) "-1"
    }

    $current(text) see insert
    focus [$current(text) cget -textWidget]
    editorWindows::ReadCursor 0
    editorWindows::flashLine

    selectObject 0
}

proc Editor::procList_history_update {} {
    variable current

    if {![info exists current(procListHistory)]} {
        procList_history_add $current(lastPos)
    } elseif {$current(procListHistoryPos) == 0} {
        set index [$current(text) index $current(lastPos)]
        set lineNum [lindex [split $index "."] 0]
        set mark "mark$lineNum"
        lreplace $current(procListHistory) 0 0 $mark
    } else {
        procList_history_add $current(lastPos)
    }
}

proc Editor::procList_history_add {{pos {}}} {
    variable current

    if {$pos eq {}} {
        set index [$Editor::current(text) index insert]
    } else {
        set index [$Editor::current(text) index $pos]
    }
    set lineNum [lindex [split $index "."] 0]
    set mark "mark$lineNum"

    if {![info exists Editor::current(procListHistory)]} {
        # set Editor::current(procListHistory) [list "mark1"]
        set Editor::current(procListHistory) [list $mark]
    } elseif {[lsearch $Editor::current(procListHistory) $mark] == 0} {
        $Editor::current(text) mark set $mark $index
        set Editor::current(procListHistoryPos) 0
        return
    }

    catch {$Editor::current(text) mark set $mark $index}

    set Editor::current(procListHistory) [linsert $Editor::current(procListHistory) 0 $mark]
    if {[llength $Editor::current(procListHistory)] > $Editor::current(procList_hist_maxLength)} {
        $Editor::current(text) mark unset [lindex $Editor::current(procListHistory) end]
        set Editor::current(procListHistory) [lreplace $Editor::current(procListHistory) end end]
    }
    set Editor::current(procListHistoryPos) 0
}

proc Editor::lineNo_history_add {} {
    variable lineEntryCombo
    variable lineNo
    set newlist [ComboBox::cget $lineEntryCombo -values]
    if {[lsearch -exact $newlist $lineNo] != -1} {return}
    set newlist [linsert $newlist 0 $lineNo]
    ComboBox::configure $lineEntryCombo -values $newlist
}

proc Editor::argument_history_add {} {
    variable argument_combo
    variable argument_var
    set newlist [ComboBox::cget $argument_combo -values]
    if {[lsearch -exact $newlist $argument_var] != -1} {return}
    set newlist [linsert $newlist 0 $argument_var]
    ComboBox::configure $argument_combo -values $newlist
}

proc Editor::search_history_add {} {
    variable search_combo
    variable search_var
    set newlist [ComboBox::cget $search_combo -values]
    if {[lsearch -exact $newlist $search_var] != -1} {return}
    set newlist [linsert $newlist 0 $search_var]
    ComboBox::configure $search_combo -values $newlist
}

proc Editor::search_forward {} {
    global search_option_icase search_option_match search_option_blink
    variable search_combo
    variable current
    Editor::search_history_add
    set search_string $Editor::search_var
    set result [Editor::search $current(text) $search_string search $search_option_icase\
            forwards $search_option_match $search_option_blink]
    focus [$current(text) cget -textWidget]
    selectObject 0
}

proc Editor::search_backward {{searchText {}}} {
    global search_option_icase search_option_match search_option_blink
    variable search_combo
    variable current

    if {$searchText eq {}} {
        Editor::search_history_add
        set search_string $Editor::search_var
        set result [Editor::search $current(text) $search_string search $search_option_icase\
                backwards $search_option_match $search_option_blink]

    } else {
        set result [Editor::search $current(text) $searchText search 0\
                backwards $search_option_match 0]
    }

    if {$result ne ""} {$current(text) mark set insert [lindex $result 0]}
    focus [$current(text) cget -textWidget]
    selectObject 0
}

proc Editor::load_search_defaults {} {
    search_default_options
}

proc Editor::search {textWindow search_string tagname icase where match blink} {
    variable current
    set result [search_proc $textWindow $search_string $tagname $icase $where $match $blink]
    editorWindows::ReadCursor 0
    set current(lastPos) [$current(text) index insert]
    return $result
}

proc Editor::search_dialog {} {
    variable current

    search_dbox $current(text)
    Editor::search_history_add
    focus [$current(text) cget -textWidget]
}

proc Editor::replace_dialog {} {
    variable current

    replace_dbox $current(text)
    focus [$current(text) cget -textWidget]
}

proc Editor::findInFiles {} {
    global EditorData

    set resultList [fif::openFifDialog $EditorData(options,workingDir)]
}

proc Editor::showResults {resultList} {
    variable resultWindow
    variable TxtWidget
    variable con_notebook
    variable searchResults

    catch {
        NoteBook::delete $Editor::con_notebook resultWin
        NoteBook::raise $Editor::con_notebook asedCon
    }
    set resultWindow [EditManager::createResultWindow $con_notebook]
    foreach entry [array names searchResults] {
        unset searchResults($entry)
    }
    foreach entry $resultList {
        set line "File: [lindex $entry 0] --> \"[lindex $entry 3]\""
        set searchResults($line) $entry
        $resultWindow insert 0 $line
    }
    $resultWindow see 0
    $con_notebook raise resultWin
    bind $resultWindow <Button-1> {
        $Editor::resultWindow selection clear 0 end
        $Editor::resultWindow selection set @%x,%y
        set index [$Editor::resultWindow curselection]
        set result [$Editor::resultWindow get $index]
        set result $Editor::searchResults($result)
        Editor::openFile [lindex $result 0]
        set index "[lindex $result 1].[lindex $result 2]"
        $editorWindows::TxtWidget mark set insert $index
        $editorWindows::TxtWidget see insert
        editorWindows::flashLine
        Editor::selectObject 0
    }
}

proc Editor::undo {} {
    variable notebook
    variable current

    set cursor [. cget -cursor]
    . configure -cursor watch
    update
    set range {}
    if {![catch {$current(text) edit undo}]} {
        # getting boundaries for highlighting
        set end [$current(text) index insert]
        foreach knowntag [$::Editor::current(text) cget -classes] {
            set tagrange [$current(text) tag prevrange $knowntag insert]
            if {$tagrange eq {}} {
                # not found
                continue
            } else {
                set start [lindex $tagrange 1]
                break
            }
        }
        if {$tagrange eq {}} {
            #nothing found, so set it to 1.0
            set start 1.0
        }
        set range [list $start $end]
    }
    . configure -cursor $cursor
    if {$range ne {}} {
        set curPos [lindex $range 1]
        if {[$current(text) compare [lindex $range 0] == [lindex $range 1]]} {
            #delete all marks at insert
            set range [editorWindows::deleteMarks [$current(text) index insert] [$current(text) index insert]]
        } else {
            set range [editorWindows::deleteMarks [lindex $range 0] [lindex $range 1]]
        }
        set startLine [lindex [split [$current(text) index [lindex $range 0]] "."] 0]
        set endLine [lindex [split [$current(text) index [lindex $range 1]] "."] 0]
        update
        after idle "editorWindows::ColorizeLines $startLine $endLine"
        updateObjects $range
        #updateOnIdle $range
        $Editor::current(text) mark set insert $curPos
    }

    set current(lastPos) [$current(text) index insert]
    focus [$current(text) cget -textWidget]
}

proc Editor::redo {} {
    variable notebook
    variable current

    set cursor [. cget -cursor]
    . configure -cursor watch
    update
    set range {}
    if {![catch {$current(text) edit redo}]} {
        # getting boundaries for highlighting
        set end [$current(text) index insert]
        foreach knowntag [$::Editor::current(text) cget -classes] {
            set tagrange [$current(text) tag prevrange $knowntag insert]
            if {$tagrange eq {}} {
                # not found
                continue
            } else {
                set start [lindex $tagrange 1]
                break
            }
        }
        if {$tagrange eq {}} {
            #nothing found, so set it to 1.0
            set start 1.0
        }
        set range [list $start $end]
    }
    . configure -cursor $cursor

    if {$range ne {}} {
        set curPos [lindex $range 1]
        if {[$current(text) compare [lindex $range 0] == [lindex $range 1]]} {
            #delete all marks at insert
            set range [editorWindows::deleteMarks [$current(text) index insert] [$current(text) index insert]]
        } else {
            set range [editorWindows::deleteMarks [lindex $range 0] [lindex $range 1]]
        }
        set startLine [lindex [split [$current(text) index [lindex $range 0]] "."] 0]
        set endLine [lindex [split [$current(text) index [lindex $range 1]] "."] 0]
        after idle "editorWindows::ColorizeLines $startLine $endLine"
        updateObjects $range
        $Editor::current(text) mark set insert $curPos
    }

    set current(lastPos) [$current(text) index insert]
    focus [$current(text) cget -textWidget]
}

proc Editor::toggleTreeOrder {} {
    global EditorData
    if {$EditorData(options,sortProcs)} {
        set Editor::options(sortProcs) 0
        Editor::torder $Editor::current(file)
    } else {
        set Editor::options(sortProcs) 1
        Editor::torder $Editor::current(file)
    }
    set EditorData(options,sortProcs) $Editor::options(sortProcs)
    Editor::selectObject 0
}

proc Editor::increaseFontSize {direction} {
    global EditorData
    global conWindow

    variable notebook
    variable current
    variable text_win
    variable list_notebook
    variable pw2
    variable con_notebook
    variable pw1
    variable mainframe
    variable FontSize_var

    set minSize 8
    set maxSize 30

    if {$direction eq "up"} {
        foreach fontClass [font names] {
            switch -glob -- $fontClass {
                 Tk* - *Font { continue }
            }
            if {[font configure $fontClass -size] == $maxSize} {
                continue
            } else {
                font configure $fontClass -size [expr [font configure $fontClass -size]+1]
                set EditorData(options,fontopts,$fontClass) [font configure $fontClass]
            }
        }
    } else {
        foreach fontClass [font names] {
            switch -glob -- $fontClass {
                 Tk* - *Font { continue }
            }
            if {[font configure $fontClass -size] == $minSize} {
                continue
            } else {
                font configure $fontClass -size [expr [font configure $fontClass -size]-1]
                set EditorData(options,fontopts,$fontClass) [font configure $fontClass]
            }
        }
    }

    set EditorData(options,fontSize) [font configure "Code" -size]
    editorWindows::onFontChange

    $conWindow configure -font "Code"
}

proc Editor::update_font { newfont } {
    variable _wfont
    variable notebook
    variable font
    variable font_name
    variable current
    variable con_notebook

    . configure -cursor watch
    if { $font ne $newfont } {
        SelectFont::configure $_wfont -font $newfont
        set raised [NoteBook::raise $notebook]
        $current(text) configure -font $newfont
        NoteBook::raise $con_notebook
        $con_notebook configure -font $newfont
        set font $newfont
    }
    . configure -cursor ""
}

proc Editor::getLangList {} {
    global ASEDsRootDir

    set LangList {}
    set pattern [file join $ASEDsRootDir lang *.msg]
    set fileList [glob -nocomplain -- $pattern]
    foreach file $fileList {
        set lang [file tail [file rootname $file]]
        lappend langList $lang
    }
    return $langList
}

proc Editor::chooseLanguage {} {
    global EditorData

    if {[winfo exists .langDlg]} {
	return
    }
    toplevel .langDlg
    wm transient .langDlg .
    wm withdraw .langDlg
    wm title .langDlg [tr "Choose Language"]

    set language $EditorData(options,language)
    label .langDlg.l -text [tr "Choose Language"]
    set lang_combo [ComboBox::create .langDlg.combo \
        -textvariable ::language \
        -text $EditorData(options,language) \
        -values {""} \
        -helptext [tr "Choose Language"] \
        -width 15]
    set langList [getLangList]
    ComboBox::configure $lang_combo -values $langList
    set f [frame .langDlg.f]
    set okButton [button .langDlg.f.ok -text [tr "Ok"] -width 10 -command {
        set EditorData(options,language) $language
        destroy .langDlg
        Editor::updateMenus
    }]
    set cancelButton [button .langDlg.f.cancel -width 10 -text [tr "Cancel"] -command {
        destroy .langDlg
        return
    }]
    pack .langDlg.l
    pack $lang_combo
    pack $f -fill both -expand yes -pady 5 -padx 10
    pack $okButton $cancelButton -padx 5 -pady 5 -side left -fill both -expand yes
    wm deiconify .langDlg
    ::tk::PlaceWindow .langDlg widget .
}

proc Editor::updateMenus {} {
    global EditorData
    variable toolbarButtons
    variable tb1
    variable tb2

    load_languageFile $EditorData(options,language)
    Editor::createMainMenu
    set topW [winfo parent $Editor::mainframe]
    destroy [$topW cget -menu]
    $topW configure -menu {}
    set menu [Widget::getoption $Editor::mainframe -menu]
    MainFrame::_create_menubar $Editor::mainframe $Editor::mainMenu

    foreach w [winfo children $tb1] {
        destroy $w
    }
    foreach w [winfo children $tb2] {
        destroy $w
    }

    Editor::createMainToolbar 1
    Editor::createFontToolbar 1

    Editor::createPopMenuEditorWindow 1
    Editor::createPopMenuTreeWindow 1
}

proc Editor::changeHLMode {mode} {
    global EditorData
    global ASEDsRootDir

    set  ::Editor::current(mode) $mode
    if {$mode eq ""} {
        set mode $::EditorData(options,defaultmode)
    }
    if {[info exists EditorData($mode)]} {
        set ::Editor::current(mode) $mode
        Editor::mode_$mode $::Editor::current(text)
    } else {
        set modefile [file join $ASEDsRootDir highlighters $mode.mode]
        if {[file exists $modefile]} {
            source $modefile
            Editor::mode_$mode $::Editor::current(text)
            set EditorData($mode) 1
            set ::Editor::current(mode) $mode
        }
    }
    if {$::Editor::current(mode) ne ""} {

        ComboBox::configure $::Editor::class_combo \
                -values [$::Editor::current(text) cget -classes]
        set ::Editor::current(class) [lindex [$::Editor::current(text) cget -classes] 0]
        Editor::changeHLClass $Editor::current(class)
        editorWindows::colorize
    }
    return
}

proc Editor::changeHLClass {class} {
    if {$class eq ""} {
        return
    }
    # $::Editor::colorButton configure -bg [$::Editor::current(text) tag cget $::Editor::current(class) -foreground]
    set font [$Editor::current(text) tag cget $Editor::current(class) -font]
    set Editor::current(weight) [tr [font configure $font -weight]]
    return
}

proc Editor::showHelp { {window {}}} {
    global libDir
    global ASEDsRootDir

    if {$window eq {}} {
        set helpFile index.htm
    } else {
        set word [$window get "insert wordstart" "insert wordend"]
        set firstChar [$window get "insert wordstart-1c" ]
        if {$firstChar eq "-"} {
            set helpFile options.html
        } elseif { [ string equal -length 3 $word tk_ ] } {
            if { [ string equal -length 5 $word tk_get ] } {
                set helpFile getOpenfile.html
            } elseif { [ string equal -length 5 $word tk_foc ] } {
                set helpFile focusNext.html
            } elseif { [ string equal -length 5 $word tk_tex ] } {
                set helpFile text.html
            } elseif { [ string equal -length 5 $word tk_bis ] || \
                        [ string equal -length 5 $word tk_set ]} {
                set helpFile palette.html
            } else {
                set word [$window get "insert wordstart+3c"  "insert wordend"]
                set helpFile $word.html
            }
        } elseif {[ string length $word] == 0} {
            # tk_messageBox -message "No help available for:\n\n $manWord" -title Info -icon info -parent .
            set helpFile index.htm
        } else {
            set helpFile $word.html
        }
    }
    set HelpViewer::HelpBaseDir [file join $ASEDsRootDir help]
    if {$helpFile eq "index.htm"} {
        HelpViewer::HelpWindow [file join $ASEDsRootDir help index.htm]
    } else {
        set found 0
        # first have a look at tcl/tk
        foreach dir [list TclCmd TkCmd] {
            set subdir [file join $ASEDsRootDir help TclTk $dir]
            # seach .html
            set tempFile [file join $subdir $helpFile]
            if {[file exists $tempFile]} {
                set helpFile $tempFile
                set found 1
                break
            }
            # search .htm
            set helpFile $word.htm
            set tempFile [file join $subdir $helpFile]
            if {[file exists $tempFile]} {
                set helpFile $tempFile
                set found 1
                break
            }
            # search man (.n.html)
            set helpFile $word.n.html
            set tempFile [file join $subdir $helpFile]
            if {[file exists $tempFile]} {
                set helpFile $tempFile
                set found 1
                break
            }
            set helpFile $word.html
        }

        if {$found == 0} {
            HelpViewer::HelpWindow [file join $ASEDsRootDir help index.htm]
            HelpViewer::HelpSearchWord $word
        } else {
            HelpViewer::HelpWindow $helpFile
        }
    }
}

proc Editor::expandCommand {win key} {
    variable current
    global EditorData
    global tk_library
    global tcl_library
    global tcl_platform
    global auto_path

    if {[Editor::checkEventList $key] == 1} {
        # this is to avoid messing eventhandling in case of rapid typing
        # we only have to catch the latest event
        editorWindows::OnKeyRelease $key
        return ""
    }
    if {$EditorData(options,useTemplatesForKeywords) == 0} {
        editorWindows::OnKeyRelease $key
        return ""
    }
    switch -regexp -- $key {
        {.} {
            # printable char: continue
        }
        default {
            # no printable char
            editorWindows::OnKeyRelease $key
            return ""
        }
    }
    # set current(inExpandMode) 0
    set lineNo [lindex [split [$win index insert] .] 0]
    set startIndex 0
    set line [$win get "insert linestart" "insert -1c wordend"]
    #check for former 'left-bracket' as a new command start
    #skip completed commands
    while {[regsub -- {\[[^\[]*\]} $line "" line]} {}
    set i [string last \[ $line ]
    if {$i > -1} {
        incr i
        set startIndex $lineNo.$i
        set line [$win get $startIndex "insert -1c wordend"]
    }
    #check for former 'left-braces' as a new command start
    #skip completed commands
    while {[regsub -- {\{[^\{]*\}} $line "" line]} {}
    set j [string last \{ $line ]
    if {$j > $i} {
        incr j
        set startIndex $lineNo.$j
        set line [$win get $startIndex "insert -1c wordend"]
    }
    #mask special chars like parentheses, ampersand etc.
    regsub -all -- {[\(\)\&\?\^\<\>\*\.\+]} $line "" line
    set line [string trimleft $line "\t\ \{\["]
    if {$line eq ""} {
        editorWindows::OnKeyRelease $key
        return ""
    }
    set wordlist [split $line]
    set cmdList {}
    set cmd [lindex $wordlist 0]
    set cmd [ string trim $cmd \[\]\{\}]
    if {[string index $cmd 0 ] eq "\$"} {
        # don't try to handle vars
        editorWindows::OnKeyRelease $key
        return ""
    }
    if {[string length $cmd] <= 1} {
        editorWindows::OnKeyRelease $key
        return ""
    }
    if {[llength $wordlist] == 1} {
        # simple command
        set subStr $cmd
        foreach command $EditorData(keywords) {
            if {[string first $cmd $command] == 0} {
                lappend cmdList $command
            }
        }
    } else {
        # is cmd a valid command?
        if {[lsearch $EditorData(keywords) $cmd] == -1} {
            editorWindows::OnKeyRelease $key
            return ""
        }
        #investigate options
        set subStr [lindex $wordlist [expr [llength $wordlist] -1]]
        set subStr [string trim $subStr \[\]\{\}]
        regsub -all {(.*)[0-9,;\:#+~\\/\t\.'](.*)} $subStr "" subStr

        if {[string index $subStr 0 ] eq "\$"} {
            # don't try to handle vars
            editorWindows::OnKeyRelease $key
            return ""
        }
        set cmdList {}
        set cmd [lindex $wordlist 0]
        set cmd [ string trim $cmd \[\]\{\}]
        switch -regexp -- [string index $subStr 0] {
            {-} {
                # this is an option
                # try to fetch command and possible options
                if {(![info exists EditorData(testInterp)]) || (![interp exists $EditorData(testInterp)])} {
                    set EditorData(testInterp) [interp create]
                    if {[catch {$EditorData(testInterp) eval package require Tk}]} {
                        $EditorData(testInterp) eval load {} Tk
                    }
                    $EditorData(testInterp) eval package require snit
                    $EditorData(testInterp) eval wm withdraw .
                }
                if {[catch {
                        interp eval $EditorData(testInterp) set subStr $subStr
                        interp eval $EditorData(testInterp) set cmd $cmd
                    }]} {
                    editorWindows::OnKeyRelease $key
                    return ""
                }
                interp eval $EditorData(testInterp) {
                    set cmdList ""
                    catch {$cmd -?} info
                    if {[string first "bad option" $info] == 0} {
                        # seems to be an optionlist
                        set optList [split $info :]
                        set optList [lindex $optList 1]
                        set options {}
                        if {[llength $optList] > 3} {
                            foreach item $optList {
                                switch -- $item {
                                    must -
                                    be -
                                    or {continue}
                                    default {
                                        if {[string first $subStr $item] == 0} {
                                            set option [string trim $item \,]
                                            lappend cmdList $option
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                #end of testInterp
                set cmdList [interp eval $EditorData(testInterp) set dummy \[set cmdList\]]
                if {[llength $cmdList] == 0} {
                    #test widget options
                    set cmd [lindex $wordlist 0]
                    set cmd [ string trim $cmd \[\]\{\}]
                    set cmdList [Editor::getWidgetOptions $cmd $subStr]
                }
            }
            {[a-z]} {
                # no leading -
                set cmdList {}
                # test commandOptions
                if {(![info exists EditorData(testInterp)]) || (![interp exists $EditorData(testInterp)])} {
                    set EditorData(testInterp) [interp create]
                    if {[catch {$EditorData(testInterp) eval package require Tk}]} {
                        $EditorData(testInterp) eval load {} Tk
                    }
                    $EditorData(testInterp) eval package require snit
                    $EditorData(testInterp) eval wm withdraw .
                }
                if {[catch {
                        interp eval $EditorData(testInterp) set subStr $subStr
                        interp eval $EditorData(testInterp) set cmd $cmd
                    }]} {
                    editorWindows::OnKeyRelease $key
                    return ""
                }
                interp eval $EditorData(testInterp) {
                    set cmdList ""
                    catch {$cmd -?} info
                    if {[string first "bad option" $info] == 0} {
                        # seems to be an optionlist
                        set optList [split $info :]
                        set optList [lindex $optList 1]
                        set options {}
                        if {[llength $optList] > 3} {
                            foreach item $optList {
                                switch -- $item {
                                    must -
                                    be -
                                    or {continue}
                                    default {
                                        if {[string first $subStr $item] == 0} {
                                            set option [string trim $item \,]
                                            lappend cmdList $option
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                #end of testInterp
                set cmdList [interp eval $EditorData(testInterp) set dummy \[set cmdList\]]
                if {$cmdList eq ""} {
                    #test widget-options
                    set cmd [lindex $wordlist 0]
                    set cmd [ string trim $cmd \[\]\{\}]
                    if {[catch {eval [list set cmdList [Editor::getWidgetOptions $cmd $subStr]]}]} {
                        editorWindows::OnKeyRelease $key
                        return ""
                    }
                }
            }
            default {
                # everything else
                editorWindows::OnKeyRelease $key
                return ""
            }
        }
    }
    if {$cmdList ne ""} {
        set current(cmdList) $cmdList
        switch -regexp -- $key {
            {\t} {
                # $win tag configure sel -background SystemHighlight
                $win tag remove sel insert "insert wordend"
                $win mark set insert "insert wordend"
                event generate $win <KeyPress-space>
                event generate $win <KeyRelease-space>
                set current(inExpandMode) 0
                set Editor::status ""
            }
            {\b} {
                # backspace: do nothing
                # needed cause Linux handles \b as prontable char
                set current(inExpandMode) 0
                set Editor::status ""
            }
            {.} {
                set command [lindex $cmdList 0]
                set current(cmdListIndex) 0
                if {[catch {regsub -- [set subStr] $command "" expCmd}]} {
                    set expCmd ""
                }
                if {$expCmd ne ""} {
                    set sel_start [$win index insert]
                    $win fastinsert insert $expCmd
                    $win tag add sel $sel_start "insert -1c wordend"
                    $win mark set insert $sel_start
                    set current(inExpandMode) 1
                    set Editor::status [tr "press TAB to accept or F2 to switch"]
                }
            }
            default {
                # set current(inExpandMode) 0
            }
        }
    }
    editorWindows::OnKeyRelease $key
    return "break"
}

proc Editor::onShiftTab {key} {
    variable current

    if {$current(inExpandMode) != 1} {
        editorWindows::OnKeyRelease $key
        return
    }
    incr current(cmdListIndex)
    if {$current(cmdListIndex) == [llength $current(cmdList)]} {
        set current(cmdListIndex) 0
    }
    set cmd [lindex $current(cmdList) $current(cmdListIndex)]
    if {[$current(text) get "sel.first wordstart -1c"] eq "-"} {
        set subStr [$current(text) get "sel.first wordstart -1c" "sel.first"]
    } else {
        set subStr [$current(text) get "sel.first wordstart" "sel.first"]
    }

    if {[catch {regsub -- [set subStr] $cmd "" expCmd}]} {
        set expCmd ""
    }
    if {$expCmd ne ""} {
        update idletasks
        set sel_start [$current(text) index insert]
        $current(text) delete $sel_start "$sel_start wordend"
        $current(text) fastinsert insert $expCmd
        $current(text) tag add sel $sel_start "insert -1c wordend"
        $current(text) mark set insert $sel_start
        set current(inExpandMode) 1
    }
    editorWindows::OnKeyRelease $key
}

proc Editor::getWidgetOptions {widget subStr} {
    global EditorData

    if {($widget eq "") || ([string index $widget 0] eq "\$")} {
        return ""
    }
    if {(![info exists EditorData(testInterp)]) || (![interp exists $EditorData(testInterp)])} {
        set EditorData(testInterp) [interp create]
        if {[catch {$EditorData(testInterp) eval package require Tk}]} {
            $EditorData(testInterp) eval load {} Tk
        }
        $EditorData(testInterp) eval wm withdraw .
    }
    if {[catch {interp eval $EditorData(testInterp) set widget $widget}]} {
        return ""
    }
    if {[catch {eval [list interp eval $EditorData(testInterp) set subStr [set subStr]]}]} {
        return ""
    }

    interp eval $EditorData(testInterp) {
        set break 0
        set tmpWidget ""
        if {[catch {set tmpWidget [$widget .asedTmpWidget]}]} {
            set break 1
        }
        if {$tmpWidget eq ""} {
            set break 1
        }
        if {[catch {set options [$tmpWidget configure]}]} {
            set break 1
        }
        if {$break == 1} {
            set cmdList {}
        } else {
            set cmdList ""
            foreach item $options {
                set option [lindex $item 0]
                if {[string first $subStr $option] == 0} {
                    lappend cmdList $option
                }
            }
        }
        catch {destroy $tmpWidget}
    }
    set cmdList [interp eval $EditorData(testInterp) set dummy \[set cmdList\]]
    return $cmdList
}

proc Editor::addEvent {key} {
    global keyEvents
    if {![info exists keyEvents]} {
        set keyEvents {}
    }
    switch -regexp -- $key {
        "[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]" {
            lappend keyEvents $key
        }
        default {}
    }
}

proc Editor::delEvent {key} {
    global keyEvents
    if {![info exists keyEvents]} {
        return
    }
    set index [lsearch $keyEvents $key]
    while {$index >= 0} {
        set keyEvents [lreplace $keyEvents $index $index]
        set index [lsearch $keyEvents $key]
    }
}

proc Editor::checkEventList {key} {
    global keyEvents
    if {![info exists keyEvents]} {
        return 0
    }
    if {[llength $keyEvents] == 0} {
        return 0
    } else {
        return 1
    }
}

proc Editor::execTool {tool} {
    global EditorData
    global ASEDsRootDir

    if {$EditorData(options,serverWish) eq {}} {
        set EditorData(options,serverWish) [info nameofexecutable]
    }

    if {[namespace exists ::starkit]} {
        # set installDir [file dirname $::starkit::topdir]
        set toolDir [file join $::starkit::topdir tools]
        switch -- $tool {
            "tkcon" {
                set filename [file join $toolDir tkcon tkcon.tcl]
            }
            "tkdiff" {
                set filename [file join $toolDir tkdiff tkdiff.tcl]
            }
            "tcltutor" {
                set filename [file join $toolDir tcltutor TclTutor.tcl]
            }
            "visualregexp" {
                set filename [file join $toolDir visualregexp visual_regexp.tcl]
            }
            default {}
        }
        if {[info nameofexecutable] eq $::starkit::topdir} {
            # starpack-mode: use ASED itself to execute
            set command [list [info nameofexecutable] -x $filename ]
        } else {
            # starkit-mode: use tclkit to execute
            set command [list [info nameofexecutable] $::starkit::topdir -x $filename]
        }
    } else {
        set installDir $ASEDsRootDir
        set toolDir [file join $installDir tools]
        switch -- $tool {
            "tkcon" {
                set filename [file join $toolDir tkcon tkcon.tcl]
            }
            "tkdiff" {
                set filename [file join $toolDir tkdiff tkdiff.tcl]
            }
            "tcltutor" {
                set filename [file join $toolDir tcltutor TclTutor.tcl]
            }
            "visualregexp" {
                set filename [file join $toolDir visualregexp visual_regexp.tcl]
            }
            default {}
        }
        set command [list $EditorData(options,serverWish) $filename ]
    }
    eval exec $command &
    return
}

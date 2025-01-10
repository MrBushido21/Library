##############################################################################
#    editor.tcl --
#    Copyright (C) 1999-2002  Andreas Sievers
#    andreas.sievers@t-online.de
#    Parts are based upon Tcl Developer Studio by Alexey Kakunin
#    last update: 2002/06/13: improvment for indentation
#
##############################################################################

namespace eval editorWindows {

    namespace export create selectAll
    namespace export gotoMark gotoProc findNext setCursor replace replaceAll
    namespace export enableHL disableHL onTabSize onFontChange

    variable This
    variable TxtWidget ""
    variable Text ""
    variable UndoID
}

proc editorWindows::OnKeyPress {key} {
    variable TxtWidget
    global EditorData

    Editor::addEvent $key
    set Editor::current(char) $key
    switch -regexp -- $key {

        {.} {
            #printable chars and Return
            if {[$TxtWidget tag ranges sel] ne "" && $EditorData(options,autoUpdate)} {
                set start [$TxtWidget index sel.first]
                set end [$TxtWidget index sel.last]
                set range [editorWindows::deleteMarks $start $end]
                $TxtWidget mark set delStart [lindex $range 0]
                $TxtWidget mark gravity delStart left
                $TxtWidget mark set delEnd [lindex $range 1]
                if {[$TxtWidget compare insert > delEnd]} {
                    $TxtWidget mark set delEnd insert
                }
                # Editor::updateOnIdle [list [$TxtWidget index delStart] [$TxtWidget index delEnd]]
                $TxtWidget mark unset delStart
                $TxtWidget mark unset delEnd
                return break
            } else {
                set rexp {^(( |\t|\;)*((namespace )|(class )|(proc )|(body )|(configbody )))|((( |\t|\;)*[^\#]*)((method )|(constructor )|(destructor )))}
                if {[regexp -- $rexp [$TxtWidget get "insert linestart" "insert lineend"]]} {
                    set Editor::current(isNode) 1
                } else {
                    set Editor::current(isNode) 0
                }
            }
        }

        default  {
            #non printable chars
            return list
        }
    }
    return list
}

proc editorWindows::onF2 {key} {

    if {$Editor::current(inExpandMode) != 1} {
        editorWindows::OnKeyRelease $key
        return
    }
    incr Editor::current(cmdListIndex)
    if {$Editor::current(cmdListIndex) == [llength $Editor::current(cmdList)]} {
        set Editor::current(cmdListIndex) 0
    }
    set cmd [lindex $Editor::current(cmdList) $Editor::current(cmdListIndex)]
    if {[$Editor::current(text) get "sel.first wordstart -1c"] eq "-"} {
        set subStr [$Editor::current(text) get "sel.first wordstart -1c" "sel.first"]
    } else {
        set subStr [$Editor::current(text) get "sel.first wordstart" "sel.first"]
    }

    if {[catch {regsub -- [set subStr] $cmd "" expCmd}]} {
        set expCmd ""
    }
    if {$expCmd ne ""} {
        update idletasks
        set sel_start [$Editor::current(text) index insert]
        $Editor::current(text) delete $sel_start "$sel_start wordend"
        $Editor::current(text) fastinsert insert $expCmd
        $Editor::current(text) tag add sel $sel_start "insert -1c wordend"
        $Editor::current(text) mark set insert $sel_start
        set Editor::current(inExpandMode) 1
    }
    editorWindows::OnKeyRelease $key
}

proc editorWindows::gotoFirstChar {{shiftMode 0}} {
    variable TxtWidget

    set curPos [$TxtWidget index insert]
    set result [Editor::getFirstChar $curPos]
    set firstCharPos [lindex $result 1]
    if {[$TxtWidget compare $curPos == $firstCharPos] } {
        if {[$TxtWidget tag ranges sel] ne ""} {
            $TxtWidget mark set insert "insert linestart"
            set endOfSel [$TxtWidget index sel.last]
            $TxtWidget tag remove sel [$TxtWidget index sel.first] $endOfSel
            $TxtWidget tag add sel "$curPos linestart" $endOfSel
        } else {
            $TxtWidget mark set insert "insert linestart"
        }
    } else {
        if {$shiftMode} {
            $TxtWidget mark set insert $firstCharPos
            $TxtWidget tag remove sel "$curPos linestart" "$curPos lineend"
            $TxtWidget tag add sel $firstCharPos $curPos
        } else {
            $TxtWidget mark set insert $firstCharPos
        }
    }
    $TxtWidget see insert
}

# edit-copy
proc editorWindows::copy {} {
    variable TxtWidget

    if {[catch {$TxtWidget index sel.first}]} {
        return
    }

    set lineStart [lindex [split [$TxtWidget index sel.first] "."] 0]
    set lineEnd [lindex [split [$TxtWidget index sel.last] "."] 0]

    tk_textCopy $TxtWidget

    ReadCursor
    # ColorizeLines $lineStart $lineEnd

    return
}

# edit-cut
proc editorWindows::cut {} {
    variable TxtWidget
    global EditorData
    if {$TxtWidget eq ""} {
        return
    }
    if {[$TxtWidget tag ranges sel] ne "" && $EditorData(options,autoUpdate)} {
        set start [$TxtWidget index sel.first]
        set end [$TxtWidget index sel.last]
        set rexp {(^( |\t|\;)*namespace )|(^( |\t|\;)*class )|(^( |\t|\;)*proc )|(method )|(^( |\t|\;)*body )|(constructor )|(destructor )}
        if {[regexp -- $rexp [$TxtWidget get $start $end]]} {
            set range [editorWindows::deleteMarks $start $end]
            $TxtWidget mark set delStart [lindex $range 0]
            $TxtWidget mark gravity delStart left
            $TxtWidget mark set delEnd [lindex $range 1]
            $TxtWidget cut
            Editor::updateOnIdle [list [$editorWindows::TxtWidget index delStart] [$TxtWidget index delEnd]]
            $TxtWidget mark unset delStart
            $TxtWidget mark unset delEnd
        } else {
            $TxtWidget cut
            update
        }
    } else {
        $TxtWidget cut
        update
    }
    ReadCursor

    set lineNum [lindex [split [$TxtWidget index insert] "."] 0]

    ColorizeLines $lineNum $lineNum

    return
}

# edit-paste
proc editorWindows::paste {} {
    global tcl_platform
    global EditorData
    variable TxtWidget

    if {$TxtWidget eq "" || [focus] ne [$TxtWidget cget -textWidget] } {
        return
    }
    # if {$EditorData(options,useSyntaxIndent)} {
        # set ctext::highlightOn 0
    # }
    if {$EditorData(options,autoUpdate)} {
        if {[$TxtWidget tag ranges sel] eq "" } {
            #get prev NodeIndex boundaries
            # set range [getUpdateBoundaries insert]
            # set start [lindex $range 0]
            # set end [lindex $range 1]
            set start [$TxtWidget index insert]
            tk_textPaste $TxtWidget
            set end [$TxtWidget index insert]
            $TxtWidget see insert
            if {[$TxtWidget compare insert > $end]} {
                set end [$TxtWidget index insert]
            }
            Editor::updateOnIdle [list $start $end]
        } else {
            set lineStart [lindex [split [$TxtWidget index sel.first] "."] 0]
            set start [$TxtWidget index sel.first]
            set end [$TxtWidget index sel.last]
            set range [editorWindows::deleteMarks $start $end]
            $TxtWidget mark set delStart [lindex $range 0]
            $TxtWidget mark gravity delStart left
            $TxtWidget mark set delEnd [lindex $range 1]
            if {$tcl_platform(platform) eq "unix"} {
                catch { $TxtWidget delete sel.first sel.last }
            }
            tk_textPaste $TxtWidget
            $TxtWidget see insert
            if {[$TxtWidget compare insert > $end]} {
                set end [$TxtWidget index insert]
            }
            Editor::updateOnIdle [list $start $end]
            $TxtWidget mark unset delStart
            $TxtWidget mark unset delEnd
        }
    }
    update idletasks
    ReadCursor
    set lineStart [lindex [split [$TxtWidget index $start] "."] 0]
    set lineEnd [lindex [split [$TxtWidget index $end] "."] 0]
    if {$EditorData(options,useSyntaxIndent)} {
        # set ctext::highlightOn 1
        autoIndent $lineStart.0 "$lineEnd.0 lineend"
    } else {
        # ColorizeLines $lineStart $lineEnd
    }
    return
}

proc editorWindows::getMarkNames {start end} {
    variable TxtWidget

    if {[$TxtWidget index end] eq $end} {
        set end "end -1c"
    }
    set markList [array names Editor::procMarks]
    set resultList ""
    set markIndex [$TxtWidget index $start]
    while {[$TxtWidget compare $markIndex <= $end]} {
        #get the right mark
        foreach { type markName index} [$TxtWidget dump -mark $markIndex] {
            set result [lsearch $markList $markName]
            if {$result != -1} {
                lappend resultList $markName
            }
        }
        set markName [$TxtWidget mark next "$markIndex +1c"]
        if {$markName eq ""} {
            break
        } else {
            set markIndex [$TxtWidget index $markName]
        }
    }
    return $resultList
}

proc editorWindows::getUpdateBoundaries {start {end insert}} {
    variable TxtWidget
    set start [$TxtWidget index "$start linestart"]
    set end [$TxtWidget index "$end lineend"]
    set markList [editorWindows::getMarkNames $start $end]
    if {$markList eq ""} {
        return [list $start $end]
    }
    # set boundaries to start or end of a node array
    foreach markName $markList {
        #get counterMark
        set counterMark ""
        if {[regexp "(_end_of_proc)$" $markName]} {
            #this is an end mark
            regsub "(_end_of_proc)$" $markName "" counterMark
            if {[$TxtWidget compare $counterMark < $start]} {
                set start $counterMark
            }
        } else {
            #this is a start mark
            append counterMark $markName "_end_of_proc"
            if {[$TxtWidget compare $counterMark > $end]} {
                set end $counterMark
            }
        }
    } ;#end of foreach
    #now we should have the correct boundaries
    set start [$TxtWidget index $start]
    set end [$TxtWidget index $end]
    return [list $start $end]
}

proc editorWindows::deleteMarks {start end} {
    global EditorData
    variable TxtWidget

    set range [getUpdateBoundaries $start $end]
    set start [lindex $range 0]
    set end [lindex $range 1]
    set markList [editorWindows::getMarkNames $start $end]
    if {$markList ne ""} {
        foreach markName $markList {
            #do not delete duplicates or namespaces or classes with children
            if {[$TxtWidget compare $markName > $end] || [$TxtWidget compare $markName < $start]} {
                continue
            }
            set tempName $markName
            regsub {_end_of_proc} $markName "" tempName
            if {[$Editor::treeWindow exists $tempName]} {
                set type [lindex [$Editor::treeWindow itemcget $tempName -data] 1]
            } else {
                set type normal
            }
            switch -- $type {
                "class" -
                "namespace" {
                    # if there are remaining nodes, don´t delete namespace/class
                    if {[$Editor::treeWindow nodes $tempName] ne ""} {
                        $TxtWidget mark set $markName 1.0
                    } else {
                        if {$markName eq $tempName} {
                            Editor::tdelNode $tempName
                        }
                        #get counterMark
                        set counterMark ""
                        if {[regexp "(_end_of_proc)$" $markName]} {
                            #this is an end mark
                            regsub "(_end_of_proc)$" $markName "" counterMark
                        } else {
                            #this is a start mark
                            append counterMark $markName "_end_of_proc"
                        }
                        catch {$TxtWidget mark unset $markName}
                        catch {unset Editor::procMarks($markName)}
                    }
                }
                "file" -
                "code" {
                    #skip
                }
                default {
                    if {$markName eq $tempName} {
                        Editor::tdelNode $markName
                    }
                    catch {$TxtWidget mark unset $markName}
                    catch {unset Editor::procMarks($markName)}
                }
            }
        }
    }
    return [list $start $end]
}

# edit-delete
proc editorWindows::delete {{key {}} {backspace ""}} {
    global tcl_platform
    global EditorData
    variable TxtWidget

    set Editor::current(char) $key

    if {$TxtWidget eq "" || !$EditorData(options,autoUpdate)} {
        return list
    }
    set rexp {(^( |\t|\;)*namespace )|(^( |\t|\;)*class )|(^( |\t|\;)*proc )|(method )|(^( |\t|\;)*body )|(constructor )|(destructor )}
    if {[$TxtWidget tag ranges sel] ne ""} {
        set start [$TxtWidget index "sel.first linestart"]
        set end [$TxtWidget index "sel.last lineend"]
        $TxtWidget delete [$TxtWidget index sel.first] [$TxtWidget index sel.last]
    } else {
        set start [$TxtWidget index "insert linestart"]
        set end [$TxtWidget index "insert lineend"]
        if {$backspace eq {}} {
            $TxtWidget delete insert
        } else {
            $TxtWidget delete "insert -1c"
        }
    }
    if {[regexp -- $rexp [$TxtWidget get $start $end]]} {
        Editor::updateOnIdle [list $start $end]
    }
    ReadCursor
    return break
}

proc editorWindows::selectAll {} {
    variable TxtWidget

    if {$TxtWidget eq ""} {
        tk_messageBox -message "no widget" -parent .
        return
    }
    $TxtWidget tag add sel 0.0 end-1c
}

# set cursor to the function
proc editorWindows::gotoMark { markName } {
    global EditorData
    variable TxtWidget

    $TxtWidget mark set insert $markName
    $TxtWidget see insert
    focus [$TxtWidget cget -textWidget]
    ReadCursor 0
    flashLine
}

proc editorWindows::gotoProc {procName} {
    global EditorData
    variable TxtWidget

    set expression "^( |\t|\;)*proc( |\t)+($procName)+( |\t)"
    set result [$TxtWidget search -regexp -- $expression insert]

    if {$result ne ""} {
        $TxtWidget mark set insert $result
        $TxtWidget see insert
        focus [$TxtWidget cget -textWidget]
        ReadCursor 0
        flashLine
    }
}

proc editorWindows::gotoObject {name} {
    #Reassemble the node name
    set node [file join [split [lrange $name 1 end] ::]]
}

proc editorWindows::flashLine {} {
    variable TxtWidget
    $TxtWidget tag add procSearch "insert linestart" "insert lineend"
    $TxtWidget tag configure procSearch -background yellow
    after 2000 {catch {$editorWindows::TxtWidget tag delete procSearch} }
}

proc editorWindows::flashRegion {start end {time 2000} {color yellow}} {
    variable TxtWidget
    $TxtWidget tag add regionSearch $start $end
    $TxtWidget tag configure regionSearch -background $color
    after $time {catch {$editorWindows::TxtWidget tag delete regionSearch} }
}

# parse file and create proc file
proc editorWindows::ReadMarks { fileName } {
    global EditorData
    variable TxtWidget

    # clear all marks in this file
    foreach name [array names EditorData files,$EditorData(curFile),marks,] {
        unset EditorData($name)
    }

    set EditorData(files,$fileName,marks) {}

    set result [$TxtWidget search -forwards "proc " 1.0 end]

    while {$result ne ""} {
        set lineNum [lindex [split $result "."] 0]
        set line [$TxtWidget get $lineNum.0 "$lineNum.0 lineend"]
        set temp [string trim $line \ \t\;]
        if {[scan $temp %\[proc\]%s proc name] == 2} {
            if {$proc eq "proc"} {
                set markName $name
                lappend EditorData(files,$fileName,marks) $markName
                set EditorData(files,$fileName,marks,$markName,name) $name
            }
        }
        set result [$TxtWidget search -forwards "proc" "$result lineend" end ]
    }
}

proc editorWindows::IndentCurLine {} {
    variable TxtWidget

    IndentLine [lindex [split [$TxtWidget index insert] "."] 0]
}

proc editorWindows::IndentLine {lineNum} {
    variable TxtWidget
    global EditorData

    if {$EditorData(options,useSyntaxIndent)} {
        set end [$TxtWidget index "$lineNum.0 lineend"]
        incr lineNum -1
        set start [$TxtWidget index $lineNum.0]
        autoIndent $start $end
    } elseif {$EditorData(options,useIndent)} {
        if {$lineNum > 1} {
            # get previous line text
            incr lineNum -1
            set prevText [$TxtWidget get $lineNum.0 "$lineNum.0 lineend"]
            regexp "^(\ |\t)*" $prevText spaces
            set braces [CountBraces $prevText]
            if {$braces > 0} {
                #indent
                incr lineNum
                $TxtWidget insert $lineNum.0 $spaces
                return
            }
        }
    } else {
        return
    }
}

proc editorWindows::indentSelection {} {
    variable TxtWidget
    global tclDevData

    set selFlag [$TxtWidget tag ranges sel]
    #check for selection & get start and end lines
    if {$selFlag eq ""} {
        set startLine [lindex [split [$TxtWidget index insert] "."] 0]
        set endLine [lindex [split [$TxtWidget index insert] "."] 0]
        set oldpos [$TxtWidget index insert]
    } else {
        set startLine [lindex [split [$TxtWidget index sel.first] "."] 0]
        set endLine [lindex [split [$TxtWidget index sel.last] "."] 0]
        set selFirst [$TxtWidget index sel.first]
        set selLast [$TxtWidget index sel.last]
        set anchor [$TxtWidget index anchor]
    }

    if {$endLine == [lindex [split [$TxtWidget index end] "."] 0]} {
        #skip last line in widget
        incr endLine -1
    }

    for {set lineNum $startLine} {$lineNum <= $endLine} {incr lineNum} {
        set text " "
        append text [$TxtWidget get $lineNum.0 "$lineNum.0 lineend"]

        $TxtWidget delete $lineNum.0 "$lineNum.0 lineend"
        $TxtWidget fastinsert $lineNum.0 $text
    }

    # highlight
    ColorizeLines $startLine $endLine

    # set selection
    if {$selFlag ne ""} {
        set selFirst $selFirst+1c
        set selLast $selLast+1c
        $TxtWidget tag add sel $selFirst $selLast
        $TxtWidget mark set anchor $anchor
        $TxtWidget mark set insert $selLast
    } else {
        $TxtWidget mark set insert $oldpos+1c
    }
}

proc editorWindows::unindentSelection {} {
    variable TxtWidget
    global tclDevData

    set selFlag [$TxtWidget tag ranges sel]
    #check for selection & get start and end lines
    if {$selFlag eq ""} {
        set startLine [lindex [split [$TxtWidget index insert] "."] 0]
        set endLine [lindex [split [$TxtWidget index insert] "."] 0]
        set oldpos [$TxtWidget index insert]
    } else {
        set startLine [lindex [split [$TxtWidget index sel.first] "."] 0]
        set endLine [lindex [split [$TxtWidget index sel.last] "."] 0]
        set selFirst [$TxtWidget index sel.first]
        set selLast [$TxtWidget index sel.last]
        set anchor [$TxtWidget index anchor]
    }

    if {$endLine == [lindex [split [$TxtWidget index end] "."] 0]} {
        #skip last line in widget
        incr endLine -1
    }

    for {set lineNum $startLine} {$lineNum <= $endLine} {incr lineNum} {
        if {[$TxtWidget get $lineNum.0 "$lineNum.0 +1 char"] eq " "} {
            $TxtWidget delete $lineNum.0 "$lineNum.0 +1 char"
        }
    }
    # highlight
    ColorizeLines $startLine $endLine

    # set selection
    if {$selFlag ne ""} {
        if {[lindex [split $selFirst "."] 1] != 0} {
            set selFirst $selFirst-1c
        }
        # if {[lindex [split $selLast "."] 1] != 0} {
            # set selLast $selLast-1c
        # }
        $TxtWidget tag add sel $selFirst $selLast
        $TxtWidget mark set anchor $anchor
        $TxtWidget mark set insert $selLast
    } else {
        $TxtWidget mark set insert $oldpos-1c
    }
}

proc editorWindows::autoIndent {{start ""} {end ""}} {
    global EditorData
    variable TxtWidget

    set cursor [. cget -cursor]
    set textCursor [$TxtWidget cget -cursor]
    . configure -cursor watch
    $TxtWidget configure -cursor watch
    if {$start eq "" || $end eq ""} {
        if {[$TxtWidget tag ranges sel] eq ""} {
            #no selection: auto indent the whole file
            set start "1.0"
            set end "end-1c"
            set Editor::prgindic 0
            set Editor::status ""
        } else {
            # only indent selection
            set start [$TxtWidget index "sel.first linestart"]
            set end [$TxtWidget index "sel.last lineend"]
            $TxtWidget tag remove sel $start $end
        }
    }
    # check for line continuation
    while {[$TxtWidget search -regexp {[\\]$} $start "$start lineend"] ne "" && $start ne "1.0"} {
        set start [$TxtWidget index "$start -1l linestart"]
    }
    set level 0
    set levelCorrection 0
    set comment 0
    set lineExpand 0
    set firstLine [$TxtWidget get "$start linestart" "$start lineend"]
    set curLine [$TxtWidget get "insert linestart" "insert lineend"]
    set cursorPos [lindex [split [$TxtWidget index insert] "."] 1]
    set cursorLine [lindex [split [$TxtWidget index insert] "."] 0]
    regexp {^[ \t]*} $curLine temp
    regsub -all {\t} $temp $EditorData(indentString) offset
    set cursorPos [expr {$cursorPos - [string length $offset]}]
    regexp {^[ \t]*} $firstLine temp
    regsub -all {\t} $temp $EditorData(indentString) offset
    while {[expr {[string length $offset] % [string length $EditorData(indentString)]}]} {
        append offset " "
    }
    set spaces $offset
    set currentSpaces $spaces
    set level [expr {[string length $offset] / [string length $EditorData(indentString)]}]
    set lineNum [lindex [split [$TxtWidget index $start] "."] 0]
    set startLine $lineNum
    set endLine [lindex [split [$TxtWidget index $end] "."] 0]
    set newBlock ""
    while {$lineNum <= $endLine} {
        if {$Editor::prgindic != -1} {
            set Editor::prgindic [expr {int($lineNum.0 / $endLine * 100)}]
            set Editor::status "Indention progress: $Editor::prgindic % "
            # update idletasks
        }
        set oldLine [$TxtWidget get $lineNum.0 "$lineNum.0 lineend"]
        set line [string trim $oldLine " \t"]
        set firstChar [string index $line 0]
        switch -- $firstChar {
            "\#" {
                #skip
                set comment 1
            }
            "\}" {
                #unindent line
                set spaces ""
                set comment 0
                if {$lineNum != $startLine} {
                    #skip the first line, otherwise it will be unindented
                    incr level -1
                }
                if {$level >= 0} {
                    for  {set i 0} {$i < $level} {incr i} {
                        append spaces "$EditorData(indentString)"
                    }
                    incr level
                } else {
                    set level 0
                }
            }
            default {
                set comment 0
            }
        }
        set newLine "$spaces$line"
        if {$comment} {
            append newBlock $newLine\n
            incr lineNum
            set currentSpaces $spaces
            continue
        }
        set bracecount [CountBraces $line]
        set bracketcount [CountBrackets $line]
        incr level $bracecount
        if {$level < 0} {
            set level 0
        }
        set lastChar [string index $line end]
        switch -- $lastChar {
            "\\" {
                #is there a leading openbrace at the lineend?
                if [regexp {\{[ \t]*\\$} $line] {
                    #ignore backslash
                } else {
                    # line continues with next line
                    if {$lineExpand} {
                        #skip
                    } else {
                        #this is the first line of new line concatenation
                        set lineExpand 1
                        set oldlevel $level
                        incr level 2
                        set oldlevel $level
                        incr levelCorrection -2
                    }
                }
            }

            default {
                #is this the end of line concatenation ?
                if {$lineExpand} {

                    if {(($bracecount <= 0) || ($bracketcount <= 0)) && ($level <= $oldlevel)} {
                        # do correction
                        if {$level > 0} {
                            incr level $levelCorrection
                            set levelCorrection 0
                        }
                        set lineExpand 0
                    } else {
                        #if there´s an open command do the indent correction later
                    }
                } elseif {($bracecount < 0) || ($bracketcount < 0)} {
                    #now the open command within a line concatenation should be completed
                    #so we add the correction value
                    incr level $levelCorrection
                    set levelCorrection 0
                }
            }
        }
        #end of switch

        # now setting the offset (spaces) for the next line
        set spaces ""
        for  {set i 0} {$i < $level} {incr i} {
            append spaces $EditorData(indentString)
        }
        append newBlock $newLine\n
        incr lineNum
    }
    #end of while

    $TxtWidget fastdelete $start $end
    $TxtWidget insert $start [string range $newBlock 0 end-1]
    Editor::updateOnIdle [list $start $end]
    set startLine [lindex [split [$TxtWidget index $start] "."] 0]
    set endLine [lindex [split [$TxtWidget index $end] "."] 0]
    . configure -cursor $cursor
    $TxtWidget configure -cursor $textCursor
    # update

    #restore cursor position
    incr cursorPos [lindex [split [lindex [Editor::getFirstChar $cursorLine.0] 1] . ] 1]
    $TxtWidget mark set insert $cursorLine.$cursorPos
    $TxtWidget see insert
    set Editor::prgindic -1
    set Editor::status ""
}

# change tab to spaces
proc editorWindows::OnTabPress {} {
    variable TxtWidget
    global EditorData

    if {[$TxtWidget tag ranges sel] ne {}} {
        # break
    } else {
        $TxtWidget fastinsert insert $EditorData(indentString)
        Editor::selectObject 0
    }
}

proc editorWindows::onKeyPressReturn {key} {
    global EditorData
    variable TxtWidget

    set Editor::current(char) "\n"
    if {!$EditorData(options,autoUpdate)} {
        return list
    }
    if {[$TxtWidget tag ranges sel] ne "" && $EditorData(options,autoUpdate)} {
        set start [$TxtWidget index sel.first]
        set end [$TxtWidget index sel.last]
        set range [editorWindows::deleteMarks $start $end]
        $TxtWidget mark set delStart [lindex $range 0]
        $TxtWidget mark gravity delStart left
        $TxtWidget mark set delEnd [lindex $range 1]
        # $TxtWidget delete sel.first sel.last
        # $TxtWidget insert insert $key
        catch {
            if {[$TxtWidget compare insert > delEnd]} {
                $TxtWidget mark set delEnd insert
            }
        }
        Editor::updateOnIdle [list [$TxtWidget index delStart] [$TxtWidget index delEnd]]
        $TxtWidget mark unset delStart
        $TxtWidget mark unset delEnd
        return break
    } else {
        if {$Editor::current(inCommentMode)} {
            if {[lindex [Editor::getFirstChar [$TxtWidget index insert]] 0] ne "#"} {
                set Editor::current(inCommentMode) 0
            }
        }
        return list
    }
}

# reaction on key releasing
proc editorWindows::OnKeyRelease {{key {}}} {
    global EditorData
    variable TxtWidget

    catch {
        switch -regexp -- $Editor::current(char) {
            "\n" {
                # Return
                if {$Editor::current(inCommentMode)} {
                    $Editor::current(text) insert insert "# "
                } elseif {[lindex [Editor::getFirstChar [$TxtWidget index "insert+1l"]] 0] eq "#"} {
                    if {[lindex [Editor::getFirstChar [$TxtWidget index "insert-1l"]] 0] eq "#"} {
                        set Editor::current(inCommentMode) 1
                        set Editor::status [tr "Comment-Mode: On"]
                        $Editor::current(text) insert insert "# "
                    }
                } else {
                    set Editor::status ""
                }
                set Editor::current(lastPos) [$Editor::current(text) index insert]
                set Editor::current(procListHistoryPos) 0
            }
            {.} {
                #printable chars
                switch -- $Editor::current(char) {
                    "\{" {editorWindows::OnLeftBraceRelease}
                    "\}" {editorWindows::IndentCurLine}
                    "\[" {editorWindows::OnLeftBracketRelease}
                    default {}
                }
                if {$Editor::current(isNode) && $EditorData(options,autoUpdate)} {
                    #if there´s a pending update only store new range
                    Editor::updateOnIdle [list [$TxtWidget index insert] [$TxtWidget index insert]]
                    set Editor::current(inCommentMode) 0
                    set Editor::status [tr "Click on Button \"Make Comment Block\" to create a proc description"]
                } elseif {$EditorData(options,autoUpdate)}  {
                    Editor::selectObject 1
                    set Editor::status ""
                } else {
                    Editor::selectObject 0
                    set Editor::status ""
                }
                if {$Editor::current(inCommentMode) && ([lindex [getFirstChar [$current(text) index insert]] 0] ne "#")} {
                    set Editor::current(inCommentMode) 0
                    set Editor::status ""
                }
                set Editor::current(lastPos) [$Editor::current(text) index insert]
                set Editor::current(procListHistoryPos) 0
            }
            default  {
                #non printable chars
                if {$Editor::current(inCommentMode) && ([lindex [getFirstChar [$current(text) index insert]] 0] ne "#")} {
                    set Editor::current(inCommentMode) 0
                }
                Editor::selectObject 0
                set Editor::current(lastPos) [$Editor::current(text) index insert]
            }
        }
    }
    ReadCursor
    set Editor::current(char) ""
}

#reaction on space release
proc editorWindows::OnSpaceRelease {} {
    global EditorData
    variable TxtWidget
    variable current

    if {!$EditorData(options,useTemplates) || !$EditorData(options,useTemplatesForKeywords)} {
        return 1
    }
    set templateKeyword [GetTemplateKeyword [$TxtWidget get "insert linestart" "insert lineend"]]
    set curPos [$TxtWidget index insert]
    set lineNum [lindex [split $curPos "."] 0]

    switch -- $templateKeyword {
        "if" -
        "elseif" {
            $TxtWidget insert insert "\{\} \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos+1c
        }

        "for" {
            $TxtWidget insert insert "\{\} \{\} \{\} \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos+1c
        }

        "foreach" {
            $TxtWidget insert insert "\{\} \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos+1c
        }

        "while" {
            $TxtWidget insert insert "\{\} \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos+1c
        }

        "switch" {
            $TxtWidget insert insert "-- \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos+3c
        }

        "proc" {
            $TxtWidget insert insert " \{\} \{\n\}"
            incr lineNum
            IndentLine $lineNum
            $TxtWidget mark set insert $curPos
        }

        "else" {
            $TxtWidget insert insert "\{\n\n\}"
            ColorizeLine $lineNum
            incr lineNum
            IndentLine $lineNum
            incr lineNum
            IndentLine $lineNum
            incr lineNum -1
            $TxtWidget mark set insert "$lineNum.0 lineend"
        }

        default {
            OnKeyRelease $Editor::current(char)
        }
    }
    ReadCursor
    return 0
}

proc editorWindows::OnLeftBraceRelease {} {
    variable TxtWidget
    global EditorData

    if {!$EditorData(options,useTemplates) || !$EditorData(options,useTemplatesForBrace)} {
        return
    }
    set curPos [$TxtWidget index insert]
    $TxtWidget insert insert "\}"
    $TxtWidget mark set insert $curPos
    return
}

proc editorWindows::OnLeftParenRelease {} {
    variable TxtWidget
    global EditorData

    if {!$EditorData(options,useTemplates) || !$EditorData(options,useTemplatesForParen)} {
        return
    }
    set curPos [$TxtWidget index insert]
    $TxtWidget insert insert "\)"
    $TxtWidget mark set insert $curPos
    Editor::selectObject 0
    return
}

proc editorWindows::OnLeftBracketRelease {} {
    variable TxtWidget
    global EditorData

    if {!$EditorData(options,useTemplates) || !$EditorData(options,useTemplatesForBracket)} {
        return
    }

    set curPos [$TxtWidget index insert]
    $TxtWidget insert insert "\]"
    $TxtWidget mark set insert $curPos
    return
}

proc editorWindows::OnQuoteDblRelease {} {
    variable TxtWidget
    global EditorData

    if {!$EditorData(options,useTemplates) || !$EditorData(options,useTemplatesForQuoteDbl)} {
        return
    }
    set curPos [$TxtWidget index insert]
    $TxtWidget insert insert "\""
    $TxtWidget mark set insert $curPos
    Editor::selectObject 0
    return
}

# reaction on mouse button release

proc editorWindows::OnMouseRelease {} {
    global EditorData
    variable TxtWidget

    if {$EditorData(getFileMode)} {
        set EditorData(getFileMode) 0
        return
    }
    ReadCursor
    ColorizePair
    set oldNode $Editor::current(node)
    set curNode [Editor::selectObject 0]
    if {$oldNode ne $curNode} {
        Editor::procList_history_add $Editor::current(lastPos)
    } else {
        Editor::procList_history_update
    }
    set Editor::current(lastPos) [$TxtWidget index insert]
}

# read information about cursor and set it to the global variables
proc editorWindows::ReadCursor {{selectProc 1}} {
    variable TxtWidget
    global EditorData

    set insertPos [split [$TxtWidget index insert] "."]
    set EditorData(cursor,line) [lindex $insertPos 0]
    set EditorData(cursor,pos) [expr {[lindex $insertPos 1]}]
    set EditorData(cursorPos) "Line: $EditorData(cursor,line)   Pos: $EditorData(cursor,pos)"
    set Editor::lineNo $EditorData(cursor,line)
    return
}

proc editorWindows::enableHL {} {
    variable TxtWidget

    if {$TxtWidget ne ""} {
        colorize
    }

    return
}

proc editorWindows::colorize {} {
    variable TxtWidget
    variable EditorData
    $TxtWidget highlight "1.0" "end-1c"
}

proc editorWindows::ColorizeLines {StartLine EndLine} {
    variable TxtWidget
    $TxtWidget highlight $StartLine.0 "$EndLine.0 lineend"
}

proc editorWindows::ColorizeLine {lineNum} {
    variable TxtWidget
    global EditorData
    $TxtWidget highlight $lineNum.0 "$lineNum.0 lineend"
}

proc editorWindows::IsComment {line lineNum} {
    variable TxtWidget

    set a ""
    regexp "^( |\t)*\#" $line a

    if {$a ne ""} {
        return [list $lineNum.[expr {[string length $a]-1}] $lineNum.[string length $line]]
    } else {
        regexp "^(.*\;( |\t)*)\#" $line a
        if {$a ne ""} {
            $TxtWidget tag remove comment $lineNum.0 "$lineNum.0 lineend"
            set range [GetKeywordCoord $line $lineNum]
            if {$range ne {}} {
                eval $TxtWidget tag add keyword $range
            } else {
                $TxtWidget tag remove keyword $lineNum.0 "$lineNum.0 lineend"
            }
            return [list $lineNum.[expr {[string length $a]-1}] $lineNum.[string length $line]]
        } else {
            return {}
        }
    }
}

proc editorWindows::GetKeywordCoord {line lineNum} {
    global EditorData

    set name ""

    set temp [string trim $line \ \t\;\{\[\]\}]
    if {![scan $temp %s name]} {
        return {}
    }

    set nameStart [string first $name $line]
    set nameEnd [string wordend $line $nameStart]

    # is it keyword?
    if {[lsearch $EditorData(keywords) $name] != -1 || $name eq "else" || $name eq "elseif"} {
        return [list $lineNum.$nameStart $lineNum.$nameEnd]
    } else {
        return {}
    }
}

proc editorWindows::GetTemplateKeyword { line } {
    global EditorData

    set a ""
    regexp "^( |\t|\;)*\[a-z\]+ $" $line a

    if {$a ne ""} {
        # gets name
        set b ""
        regexp "^( |\t)*" $line b
        set nameStart [string length $b]
        set nameEnd [string length $a]
        set name [string range $a [string length $b] end]

        #return name without last space
        return [string range $name 0 [expr {[string length $name] - 2}]]
    } else {
        # check for else
        set a ""
        regexp "^( |\t)*\}( |\t)*else $" $line a

        if {$a ne ""} {
            return "else"
        }

        # check for elseif
        set a ""
        regexp "^( |\t)*\}( |\t)*elseif $" $line a

        if {$a ne ""} {
            return "elseif"
        }
    }

    return ""
}

proc editorWindows::setCursor {lineNum pos} {
    variable TxtWidget

    $TxtWidget mark set insert $lineNum.$pos
    $TxtWidget see insert
    focus [$TxtWidget cget -textWidget]
    ReadCursor
}

#reaction on changing tab size
proc editorWindows::onTabSize {} {
    variable TxtWidget
    global EditorData

    if {$TxtWidget ne ""} {
        if {$EditorData(options,tabSize) == 8 ||
            $EditorData(options,tabSize) <= 0} {
            set tabList {}
        } else {
            set tabSize [expr {$EditorData(options,tabSize) * [font measure "Code" -displayof $TxtWidget.t " "]}]
            set tabList [list $tabSize left]
        }
        $TxtWidget configure -tabs [list $tabList] -tabstyle wordprocessor
    }
}

# reaction on change font
proc editorWindows::onFontChange {} {
    variable TxtWidget
    global EditorData

    if {$TxtWidget ne ""} {
        $TxtWidget configure -font "Code"
        foreach fontname [font names] {
            switch -glob -- $fontname {
                 Tk* - *Font { continue }
            }
            font configure $fontname \
                    -size $EditorData(options,fontSize) \
                    -family $EditorData(options,fontFamily)
                    set EditorData(options,fonts,$fontname) [font configure $fontname]
        }
	if {$EditorData(options,tabSize) == 8 ||
	    $EditorData(options,tabSize) <= 0} {
	    set tabList {}
	} else {
	    set tabSize [expr {$EditorData(options,tabSize) * [font measure "Code" -displayof $TxtWidget " "]}]
	    set tabList [list $tabSize left]
	}
    }
    foreach textWin [array names ::Editor::index] {
        set idx $Editor::index($textWin)
        $Editor::text_win($idx,path) configure -font "Code"
	if {[info exists tabList]} {
	    $Editor::text_win($idx,path) configure -tabs $tabList -tabstyle wordprocessor
	}
    }
}

proc editorWindows::onChangeFontSize {editWin} {
    global EditorData

    foreach fontname [font names] {
        font configure $fontname -size $EditorData(options,fontSize)
        set EditorData(options,fonts,$fontname) [font configure $fontname]
    }
}

proc editorWindows::GetOpenPair {symbol {index ""}} {
    variable TxtWidget

    if {$index eq ""} {
        set index insert
    }

    set count -1

    switch -- $symbol {
        "\}" {set rexp {(^[ \t\;]*#)|(\{)|(\\)|(\})}}
        "\]" {set rexp {(^[ \t\;]*#)|(\[)|(\\)|(\])}}
        "\)" {set rexp {(^[ \t\;]*#)|(\()|(\\)|(\))}}
        default {
            # unknown symbol
            return ""
        }
    }
    while {$count != 0} {
        set index [$TxtWidget search -backwards -regexp $rexp $index "1.0"]

        if {$index eq ""} {
            break
        }
        #check for quoting
        if {[$TxtWidget get "$index -1c"] ne "\\"} {
            switch -- [$TxtWidget get $index] {
                "\{" {incr count}
                "\[" {incr count}
                "\(" {incr count}
                "\}" {incr count -1}
                "\]" {incr count -1}
                "\)" {incr count -1}
                default {
                    # other char, should never reach this line!
                }
            }
        }
    }

    if {$count == 0} {
        return $index
    } else {
        return ""
    }
}

proc editorWindows::GetClosePair {symbol {index ""}} {
    variable TxtWidget

    if {$index eq ""} {
        set index "insert"
    }

    set count 1

    switch -- $symbol {
        "\{" {set rexp {(^[ \t\;]*#)|(\})|(\{)|(\\)}}
        "\[" {set rexp {(^[ \t\;]*#)|(\[)|(\\)|(\])}}
        "\(" {set rexp {(^[ \t\;]*#)|(\()|(\\)|(\))}}
        default {
            # unknown symbol
            return ""
        }
    }
    while {$count != 0} {
        set index [$TxtWidget search -regexp $rexp "$index +1c" end ]
        if {$index eq ""} {
            break
        }
        switch -- [$TxtWidget get $index] {
            "\{" {incr count}
            "\[" {incr count}
            "\(" {incr count}
            "\}" {incr count -1}
            "\]" {incr count -1}
            "\)" {incr count -1}
            "\\" {set index "$index +1ch"}
            default {
                #this is a comment line
                set index [$TxtWidget index "$index lineend"]
            }
        }
        if {[$TxtWidget compare $index >= "end-1c"]} {
            break
        }
    }
    if {$count == 0} {
        return [$TxtWidget index $index]
    } else {
        return ""
    }
}

#process line for openSymbol
proc editorWindows::ProcessLineForOpenSymbol {line symbol countName} {
    upvar $countName count

    switch -- $symbol {
        "\}" {
            set openSymbol "\{"
        }
        "\]" {
            set openSymbol "\["
        }
        "\)" {
            set openSymbol "\("
        }
        default {
            # unknown symbol
            return ""
        }
    }

    #process line
    for {set i [expr {[string length $line] - 1}]} {$i >= 0} {incr i -1} {
        set curChar [string index $line $i]

        if {$curChar eq $openSymbol} {
            # increment count
            if {[string index $line [expr {$i - 1}]] eq "\\"} {
                #skip it
                incr i -1
            } else {
                incr count
                if {$count > 0} {
                    return $i
                }
            }
        } elseif {$curChar eq $symbol } {
            # decrement count
            if {[string index $line [expr {$i - 1}]] eq "\\"} {
                #skip it
                incr i -1
            } else {
                incr count -1
            }
        }
    }

    return ""
}

#process line for closeSymbol
proc editorWindows::ProcessLineForCloseSymbol {line symbol countName} {
    upvar $countName count

    switch -- $symbol {
        "\{" {
            set closeSymbol "\}"
        }
        "\[" {
            set closeSymbol "\]"
        }
        "\(" {
            set closeSymbol "\)"
        }
        default {
            #unknown symbol
            return ""
        }
    }

    #process line
    set len [string length $line]
    for {set i 0} {$i < $len} {incr i } {
        set curChar [string index $line $i]

        if {$curChar eq $closeSymbol} {
            # increment count
            incr count
            if {$count > 0} {
                return $i
            }
        } elseif {$curChar eq $symbol} {
            # decrement count
            incr count -1
        } elseif {$curChar eq "\\"} {
            #skip next symbol
            incr i
        }
    }
    return ""
}

# count braces in text
proc editorWindows::CountBraces {text {count 0}} {
    set rexp_open {\{}
    set rexp_close {\}}
    #ignore comment lines
    regsub -all {^[ \t\;]#[^\n]*} $text "" dummy
    #ignore quoted braces
    regsub -all {(\\\\)} $dummy "" dummy
    regsub -all {(\\\{|\\\})} $dummy "" text
    set openBraces [regsub -all -- $rexp_open $text "*" dummy]
    set closeBraces [regsub -all -- $rexp_close $text "*" dummy]
    return [expr {$openBraces - $closeBraces}]
}

proc editorWindows::CountBrackets {text {count 0}} {
    set rexp_open {\[}
    set rexp_close {\]}
    #ignore comment lines
    regsub -all {^[ \t\;]#[^\n]*} $text "" dummy
    #ignore quoted brackets
    regsub -all {(\\\\)} $dummy "" dummy
    regsub -all {(\\\[|\\\])} $dummy "" text
    set openBrackets [regsub -all -- $rexp_open $text "*" dummy]
    set closeBrackets [regsub -all -- $rexp_close $text "*" dummy]
    return [expr {$openBrackets - $closeBrackets}]
}

# colorize pair
proc editorWindows::ColorizePair {} {
    variable TxtWidget

    $TxtWidget tag remove pair 0.0 end

    #get current char
    set curChar [$TxtWidget get insert]

    switch -- $curChar {
        "\}" {
            set result [GetOpenPair "\}"]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        "\]" {
            set result [GetOpenPair "\]"]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        "\)" {
            set result [GetOpenPair "\)"]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        "\{" {
            set result [GetClosePair "\{"]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        "\[" {
            set result [GetClosePair "\["]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        "\(" {
            set result [GetClosePair "\("]
            if {$result ne ""} {
                $TxtWidget tag add pair $result "$result +1ch"
            }
        }
        default {return}
    }
}

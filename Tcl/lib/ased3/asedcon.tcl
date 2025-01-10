#ASED asedCon
global asedCon
global conWindow

proc flashWin {win delay} {
    set color [$win cget -bg]
    $win configure -bg red
    update
    after $delay
    $win configure -bg $color
    update
}

proc reset {} {
    global asedCon
    interp eval $asedCon {
        if {[lsearch [package names] Tk] != -1 &&
            ![catch {winfo exists .}]} {
            foreach child [winfo children .] {
                if {[winfo exists $child]} {destroy $child}
            }
            wm withdraw .
        }
    }
}

proc conPuts {var {tag output} {win {}} {flash 0} {see 1} {showPrompt 1}} {
    global prompt
    global conWindow
    if {$win == {}} {
        set win $conWindow
    }
    $win mark set insert end
    $win mark gravity prompt right
    $win insert end $var $tag
    if {[string index $var end] != "\n"} {
        $win insert end "\n"
    }
    if {$showPrompt} {
        set prompt [pwd]
        $win insert end "$prompt % " prompt
        $win mark gravity prompt left
    }
    if $see {$win see insert}
    update idletasks
    if $flash {
        flashWin $win $flash
    }
    return $var
}

proc consolePuts {args} {
    global prompt
    global conWindow
    global errorInfo

    catch {eval set args $args}
    set argcounter [llength $args]
    if {[llength $args] > 3} {
        conPuts [tr "invalid arguments"] error
        return
    }
    set newline "\n"
    if {[string match "-nonewline" [lindex $args 0]]} {
        set newline ""
        set args [lreplace $args 0 0]
    }
    if {[llength $args] == 1} {
        set chan stdout
        set string [lindex $args 0]$newline
    } else {
        set chan [lindex $args 0]
        set string [lindex $args 1]$newline
    }
    if [regexp (stdout|stderr) $chan] {
        eval conPuts [list $string]
    } else {
        uplevel origPuts -nonewline $chan $string
    }
}

proc evalCommand {window Interp command} {
    global errorInfo
    global env
    global code
    global result
    global prompt
    global historyIndex
    global tcl_platform
    global buffer

    set historyIndex 0
    proc SetValues {_code _result _errorInfo} {
        global code result errorInfo
        set code $_code
        set result $_result
        set errorInfo $_errorInfo
    }

    if {$command != {} && $command != "\n"} {
        if {$command == "reset\n"} {
            set buffer ""
            conPuts [tr "current command canceled !"] error
            return
        } elseif {$command == "cls\n"} {
            $window delete 1.0 end-1c
            $window insert end "$prompt % " prompt
            $window mark set prompt insert
            $window mark gravity prompt left
            return
        }
        append buffer $command
        if {[info complete $buffer]} {
            set evalCommand $buffer
            # delete last \n
            set evalCommand [string range $evalCommand 0 end-1]
            set buffer ""
            history add $evalCommand
            # if {[regexp -- {^[\ \t]*puts\ } $evalCommand]} {
                # if {([llength $evalCommand] == 3) && ([lindex $evalCommand 1] != "-nonewline")} {
                    # # eval in interp
                # } elseif {[llength $evalCommand] == 4} {
                    # # eval in interp
                # } else {
                    # # grab puts
                    # regsub {puts } $evalCommand "" evalCommand
                    # consolePuts $evalCommand
                    # return
                # }
            # }
            interp eval $Interp set evalCommand [list $evalCommand]
            interp eval $Interp {
		if {![info exists errorInfo]} {set errorInfo ""}
                set code [catch "eval [list $evalCommand]" result]
                setValues $code $result $errorInfo
            }
            update idletasks
            if {!$code} {
                if {$result != {}} {
                    eval [list conPuts $result]
                } else {
                    set prompt [pwd]
                    $window mark gravity prompt right
                    $window insert end "$prompt % " prompt
                    $window mark gravity prompt left
                    $window see insert
                }
            } else {
                if {[info commands [lindex $evalCommand 0]] != ""} {
                    eval [list conPuts $errorInfo error]
                } else {
                    if {$tcl_platform(platform) == "windows"} {
                        set comspec [file split $env(COMSPEC)]
                        set temp ""
                        foreach item $comspec {
                            set temp [file join $temp $item]
                        }
                        set execComspec [concat $temp /c $evalCommand]
                    } else {
                        set execComspec $evalCommand
                    }
                    set code [catch {eval exec $execComspec} result]
                    # conPuts "code:$code - result:$result"
                    if {!$code} {
                        if {$result != {}} {
                            eval [list conPuts $result output]
                        } else {
                            set prompt [pwd]
                            $window mark gravity prompt right
                            $window insert end "$prompt % " prompt
                            $window mark gravity prompt left
                            $window see insert
                        }
                    } else {
                        eval [list conPuts $errorInfo error]
                    }
                }
            }
        }
    } else {
        set prompt [pwd]
        $window mark gravity prompt right
        $window insert end "$prompt % " prompt
        $window mark gravity prompt left
        $window see insert
    }
    set prompt [pwd]
}

# proc evalCommand
# executes commands within a seperate interpreter
# runs also windows commands via exec
proc evalRuntimeCommand {window Interp command} {
    global errorInfo
    global env
    global code
    global result
    global prompt
    global historyIndex
    global tcl_platform
    global buffer

    if {![interp exists $Editor::current(slave)]} {
        return
    }
    set historyIndex 0
    proc SetValues {_code _result _errorInfo} {
        global code result errorInfo
        set code $_code
        set result $_result
        set errorInfo $_errorInfo
    }

    if {$command != {} && $command != "\n"} {
        if {$command == "reset\n"} {
            set buffer ""
            conPuts [tr "current command canceled !"] error
            return
        } elseif {$command == "cls\n"} {
            $window delete 1.0 end-1c
            $window insert end "$prompt % " prompt
            $window mark set prompt insert
            $window mark gravity prompt left
            return
        }
        append buffer $command
        if {[info complete $buffer]} {
            set evalCommand $buffer
            set buffer ""
            history add $evalCommand
            set code [catch "$Editor::current(slave) eval [list puts $Editor::current(sock) $evalCommand]" result]
            setValues $code $result $errorInfo
            # update idletasks
            if {!$code} {
                if {$result != {}} {
                    eval [list conPuts $window $result]
                } else {
                    set prompt [pwd]
                    $window mark gravity prompt right
                    $window insert end "$prompt % " prompt
                    $window mark gravity prompt left
                    $window see insert
                }
            } else {
                if {[info commands [lindex $evalCommand 0]] != ""} {
                    eval [list conPuts $window $errorInfo error]
                }
            }
        }
    } else {
        set prompt [pwd]
        $window mark gravity prompt right
        $window insert end "$prompt % " prompt
        $window mark gravity prompt left
        $window see insert
    }
    set prompt [pwd]
}


proc getCommand {window} {
    global prompt
    set command [$window get prompt end-1c]
    $window mark set prompt insert
    return $command
}

proc searchHistory {direction} {
    global historyIndex
    switch -- $direction {
        backwards {
            if {$historyIndex > -20} {
                set command [history event $historyIndex]
                incr historyIndex -1
                return $command
            } else {
                return {}
            }
        }
        forwards {
            if {$historyIndex < -1} {
                incr historyIndex
                set command [history event [expr $historyIndex+1]]
                return $command
            } else {
                return {}
            }
        }
        default {tk_messageBox -message [tr "Internal Error"] -type ok; return}
    }
}

proc onKeyPressed {win} {
    if {[$win compare insert < prompt]} {
        $win mark set insert prompt
        $win see insert
    }
}

proc onButtonPressed {win} {
}

proc onKeyHome {win} {
    $win mark set insert prompt
}

proc onKeyUp {win} {
    if {[$win compare insert >= prompt]} {
        $win mark set insert prompt
        $win delete prompt end
        set command [searchHistory backwards]
        $win insert prompt $command
        $win see insert
    } else {
        $win mark set insert "insert - 1line"
    }
}

proc onKeyDown {win} {
    if {[$win compare insert >= prompt]} {
        $win mark set insert prompt
        $win delete prompt end
        set command [searchHistory forwards]
        $win insert prompt $command
        $win see insert
    } else {
        $win mark set insert "insert + 1line"
    }
}

proc onKeyLeft {win} {
    if {[$win compare insert >= prompt]} {
        set curPos [lindex [split [$win index insert] "."] 1]
        set promptPos [lindex [split [$win index prompt] "."] 1]
        if {$curPos <= $promptPos} {
            return {}
        } else {
            $win mark set insert insert-1c
        }
    } else {
        $win mark set insert "insert -1c"
    }
}

proc onKeyRight {win} {
    $win mark set insert "insert +1c"
}

proc onKeyBackSpace {win} {

    if {[$win compare insert <= prompt]} {
        return {}
    } else {
        $win delete insert-1c
    }
}

proc consoleInit {win {width 60} {height 5}} {
    global asedCon
    global prompt
    global window
    global historyIndex
    global EditorData

    set historyIndex 0
    set window $win
    set prompt [pwd]
    set EditorData(console,initargs) [list $win $width $height]

    if {$window eq "."} {
        set window ""
    }
    set asedCon [interp create]

    $asedCon alias setValues SetValues
    $asedCon alias exit reset
    $asedCon alias cputs consolePuts
    interp eval $asedCon {
        rename puts origPuts
        proc puts {args} {
            switch -- [llength $args] {
                1 {cputs $args}
                2 {
                    if {[lindex $args 0] == "-nonewline"} {
                        cputs $args
                    } else {
                        eval origPuts $args
                    }
                }
                3 {eval origPuts $args}
                default {eval origPuts $args}
            }
        }
    }

    if {[winfo exists $window.t]} {
        return $window.t
    }

    text $window.t -width $width -height $height -bg white
	### pack $window.t -fill both -expand yes

    catch {$window.t configure -font "Code"}
    $window.t tag configure output -foreground blue
    $window.t tag configure prompt -foreground grey40
    $window.t tag configure error -foreground red
    $window.t insert end "$prompt % " prompt
    $window.t mark set prompt insert
    $window.t mark gravity prompt left
    bind $window.t <KeyPress-Return> {%W mark set insert "end-1c"}
    bind $window.t <KeyRelease-Return> {evalCommand %W $asedCon [getCommand %W];break}
    bind $window.t <Key-Up> {onKeyUp %W ; break}
    bind $window.t <Key-Down> {onKeyDown %W ; break}
    bind $window.t <Key-Left> {onKeyLeft %W ; break}
    bind $window.t <Key-Right> {onKeyRight %W ; break}
    bind $window.t <Key-BackSpace> {onKeyBackSpace %W;break}
    bind $window.t <Key-Home> {onKeyHome %W ;break}
    bind $window.t <Control-c> {set dummy nothing}
    # bind $window.t <Control-v> {set dummy nothing}
    bind $window.t <KeyPress> {onKeyPressed %W}

    return $window.t
}

proc testTermInit {win {interp {}} {width 60} {height 5}} {
    global prompt
    global historyIndex
    global EditorData

    set historyIndex 0
    set prompt [pwd]

    set termWin [text $win.t -width $width -height $height -bg white -wrap none ]
    catch {$termWin configure -font $EditorData(options,fonts,editorFont)}
    $termWin tag configure output -foreground blue
    $termWin tag configure prompt -foreground grey40
    $termWin tag configure error -foreground red
    $termWin insert end "$prompt % " prompt
    $termWin mark set prompt insert
    $termWin mark gravity prompt left
    bind $termWin <KeyPress-Return> {%W mark set insert "prompt lineend"}
    bind $termWin <KeyRelease-Return> {evalRuntimeCommand \%W $interp [getCommand %W] ; break}
    bind $termWin <Key-Up> {onKeyUp %W ; break}
    bind $termWin <Key-Down> {onKeyDown %W ; break}
    bind $termWin <Key-Left> {onKeyLeft %W ; break}
    bind $termWin <Key-Right> {onKeyRight %W ; break}
    bind $termWin <Key-BackSpace> {onKeyBackSpace %W;break}
    bind $termWin <Key-Home> {onKeyHome %W ;break}
    bind $termWin <Control-c> {set dummy nothing}
    bind $termWin <KeyPress> {onKeyPressed %W}
    return $termWin
}

# this won't be executed if asedcon.tcl is sourced by another app
if {[string compare [info script] $argv0] == 0} {
    consoleInit .
}

package require msgcat

global testMode

set testMode 0

proc load_languageFile {{language {}} } {
    global langArray
    global ASEDsRootDir
    global EditorData

    if {$language == {}} {
        set language [msgcat::mclocale]
        if {$language != ""} {
            set language [string range $language 0 1]
            set langfile [file join $ASEDsRootDir lang $language.msg]
            if {[file exists $langfile]} {
                # ok
            } else {
                set langfile [file join $ASEDsRootDir lang default.msg]
            }
        }
    } else {
        set langfile [file join $ASEDsRootDir lang $language.msg]
        if {[file exists $langfile]} {
            # ok
        } else {
            set language [msgcat::mclocale]
            if {$language != ""} {
                set language [string range $language 0 1]
                set langfile [file join $ASEDsRootDir lang $language.msg]
                if {[file exists $langfile]} {
                    # ok
                } else {
                    set langfile [file join $ASEDsRootDir lang default.msg]
                }
            }
        }
    }
    array unset langArray *
    # read native language file
    set fd [open $langfile r]
    while {![eof $fd]} {
        gets $fd line
        set langArray([lindex $line 0]) [lindex $line 1]
    }
    close $fd
}

proc tr {expression} {
    global langArray
    global testMode
    global ASEDsRootDir
    global EditorData

    if {[info exists langArray($expression)]} {
        set txt $langArray($expression)
    } else {
        set txt $expression
        if {$testMode} {
            set fd [open [file join $ASEDsRootDir lang $EditorData(options,language).missing ] a+]
            set data [read $fd]
            append data \"$expression\"
            puts $fd $data
            close $fd
        }
    }
    return $txt
}

# load_languageFile filename

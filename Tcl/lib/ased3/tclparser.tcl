################################################################################
#
# tclparser.tcl
#
# this file builds the tree for the code browser
# original version by zerbst@tu-harburg.de
#
# Changed by A.Sievers, last updated 01/04/04
# - bugfixes for itcl-support
# - this file only parses the textfile and returns a nodelist
#   each entry including name, type, startindex and endindex
#
#
#################################################################################


namespace eval Parser {
}

################################################################################
#
#  proc Parser::parseCode
#
# wannabe replacement of the current code parsing. Should do everything:
#
# syntax highlighting, inclusive [incr tcl] support
# tree with objects (namespace, class, procs etc.) [more or less done]
# perhaps one day inheritance
#
# Changes: 28.01.2000 Changed Top and Bottom to <Top> and <Bottom> to avoid
#                     mixing it up with a proc
#
#                     Changed names of treenodes. The new syntax starts with the
#                     filename, then a # separated list of objetc,type names
#                     1. It's easy to get the filename now
#                     2. It's possible to have a namespace and proc of the same name e.g.
#
# zerbst@tu-harburg.d
#
# Changes: 15.03.00 by Andreas Sievers (andreas.sievers@t-online.de)
#     parseCode works now independent from a specific application
#     and returns a list of "nodes", each including
#     - name
#     - type
#     - startIndex
#     - endIndex
#
# Changes: 04.01.03 by Andreas Sievers
#     distinguish between tcl and itcl (different reg-exps) depending upon mode
#
# args:
#     - rootnode: rootnode, e.g. filename
#     - textWidget: the text widget, whose text has to be parsed
#     - range: an optional range in the form "[list start end]"
#              if range is empty {} the whole text will be parsed
#     - code: an optional code will be executed while parsing
#             e.g. code for a progressbar
#
################################################################################
proc Parser::parseCode {rootnode textWidget {range {}} {code {}} } {
    variable TxtWidget

    set mode $::Editor::current(mode)
    set TxtWidget $textWidget
    if {$range ne {} && [$TxtWidget compare [lindex $range 0 ] == [lindex $range 1 ]]} {
        return {}
    }
    set rexp_tcl "^( |\t|\;)*((namespace )|(proc ))"
    set rexp_itcl "^( |\t|\;)*((namespace )|(proc )|(::)*(itcl::)*(class )|(::)*(itcl::)*(body )|(::)*(itcl::)*(configbody )|(private )|(public )|(protected )|(method )|(constructor )|(destructor ))"
    set rexp_itk $rexp_itcl

    if {[catch {set rexp [set rexp_$mode]}]} {
        return {}
    }

    if {$range eq {}} {
        set start 1.0
        set end "end -1c"
        eval [list set NodeList [parse $start $end $rootnode $rexp 0 $code]]
        set NodeList [linsert $NodeList 0 [list $rootnode\u018b<Bottom> code "end -1lines" "end -1lines lineend" ]]
        set NodeList [linsert $NodeList 0 [list $rootnode\u018b<Top> code 1.0 "1.0 lineend"]]
        set NodeList [linsert $NodeList 0 [list $rootnode file "1.0" "end -1c"]]
    } else {
        set start [lindex $range 0]
        set end [lindex $range 1]
        set NodeList [parse $start $end $rootnode $rexp 0 $code]
    }
    # catch {tk_messageBox -message "Caller: [info level -1]\nNodelist: $NodeList"}
    return $NodeList
}

proc Parser::GetClosePair {symbol {index ""}} {
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
    while {($count != 0) && ([$TxtWidget compare $index < "end-1c"])} {
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
    }
    if {$count == 0} {
        return [$TxtWidget index $index]
    } else {
        return ""
    }
}

proc Parser::GetClosePair.orig {symbol {index ""}} {
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
    while {($count != 0) && ([$TxtWidget compare $index < "end-1c"])} {
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
        # if {[$TxtWidget compare $index >= "end-1c"]} {
            # break
        # }
    }
    if {$count == 0} {
        return [$TxtWidget index $index]
    } else {
        return ""
    }
}

################################################################################
#
#  proc Parser::parse
#
#  parses code between $start and $end. Found objects likes namespaces,
#  classes and procs are reported to Editor::tnewNode to be inserted in the
#  tree. The type and start and end is saved in the tree as data
#
#  No syntax highlighting yet, no inheritance yet
#
#  Changes: 28.01.2000 Changed name of treenodes, see parseCode
#           01.02.2000 Handle itcl forward declaration correct
#                      Handle itcl inheritance correct and save inheritance to tree
#
#  zerbst@tu-harburg.d
#
#  Changes by A.Sievers:
#  04.01.2004    Several bugfixes for itcl-support in code-browser
#                Ignore inheritance
#                Handle public, private and protected statements for method
#
################################################################################

proc Parser::parse {start end node rexp {recursion 0} {code {}} } {
    variable TxtWidget

    set nodeList {}

    if {$start eq ""} {
        return ""
    }
    set end [$TxtWidget index $end]
    set nend $start

    # brace_rexp will skip all white-chars including line-concatenations
    set brace_rexp {[^ \t\n(\\\n)]}
    set proc_rexp {^[ \t\;]*(proc)[ \t]+}

    set result [$TxtWidget search -forwards -regexp $rexp  $start $end]
    set ancestors {}

    while {$result ne ""} {
        set line [$TxtWidget get $result "$result lineend"]
        set rights ""
        set temp [string trim $line \ \t\;]
        set nend $result
        #perhaps look at rights later
        # regsub {(^private )|(^protected )|(^public )} $temp "" temp
        regsub {;(.)+} $temp "" temp
        regsub -all {[ \t]+} $temp " " temp
        regsub {\{(\ |\t)*\}(\ |\t)*$} $temp "" temp
        regsub {(\{)(\ |\t)*$} $temp "" temp
        if {[catch {foreach {token arg1 arg2 arg3 arg4} $temp {}}]} {
            scan $temp %s%s%s%s%s token arg1 arg2 arg3 arg4
        }
        if {![info exists arg1]} {
            set nend "$nend +1lines"
            if {[$TxtWidget compare $nend >= "end -1c"]} {
                break
            }
            set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
            continue
        }
        switch -- $token {
            "public" -
            "private" -
            "protected" {
                set rights $token
                set token $arg1
                set arg1 $arg2
                set arg2 $arg3
                set arg3 $arg4
            }
            default {}
        }
        set arglist {}

        #get the first token and decide furtheron
        switch -- $token {

            "namespace" {
                #Really a new namespace ?
                if {![string match eval $arg1] || [catch {set name $arg2}]} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Get the name
                set name $arg2
                regsub {^::} $name "" name
                regsub -all {::} $name \u018b name
                #Get the start end end of the namespace
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$start +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Create a node
                set nname "$node\u018b$name\_n"
                lappend nodeList [list $nname namespace "$result linestart" "$nend +1c" $arglist]
                if {[$TxtWidget compare $nend > $end]} {
                    editorWindows::deleteMarks $end $nend
                }
                foreach NamespaceNode [parse $nstart $nend $nname $rexp 1] {
                    lappend nodeList $NamespaceNode
                }
            }

            "class" -
            "itcl::class" -
            "::itcl::class" {

                #setting newline sensivity
                #allowing whitespaces at linestart followed by one of the alternative keywords
                #or allowing any char but no hash (with possible leading white spaces)
                #at linestart followed by one of the alternative keywords
                # set rexp {^(( |\t|\;)*((namespace )|(::)*(itcl::)*(class )|(proc )|(::)*(itcl::)*(body )|(::)*(itcl::)*(configbody )))|((( |\t|\;)*[^\#]*)((method )|(constructor )|(destructor )))}
                #Get the name
                set name $arg1
                ##puts stderr "\tname $name"
                regsub {^::} $name "" name
                regsub -all {::} $name \u018b name

                #Get the start end end of the class
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$start +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Create a node
                set nname "$node\u018b$name"
                lappend nodeList [list $nname class "$result linestart" "$nend +1c" $arglist]
                foreach ClassNode [parse $nstart $nend $nname $rexp 1] {
                    lappend nodeList $ClassNode
                }
            }

            "proc"  {
                if {[info exists arg2]} {
                    if {[regexp {\{.*\}} $temp arglist]} {
                        # set arglist [string trim $arglist \{\} ]
                    } else {
                        set arglist {}
                    }
                    # tk_messageBox -message $arglist
                }
                #Get the name
                set name $arg1
                regsub {^::} $name "" name
                regsub -all {::} $name \u018b name
                #Skip the arguments
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }

                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines linestart"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }

                #Get the body of the proc
                set nstart [$TxtWidget search -regexp $brace_rexp "$nend+1c" "end-1c"]
                if {$nstart eq ""} {
                    set nstart "$nend+1c"
                }
                if {[$TxtWidget get $nstart] ne "\{"} {
                    set nend "$nend +1lines linestart"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines linestart"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Create a node
                set nname "$node\u018b$name\_p"
                lappend nodeList [list $nname proc "$result linestart" "$nend +1c" $arglist]
                if {$arglist ne "\{\}"} {
                    lappend nodeList [list $nname\u018bargs args "$result linestart" "$nend + 1c" $arglist]
                }
                foreach ProcNode [parse $nstart $nend $nname $proc_rexp 1] {
                    lappend nodeList $ProcNode
                }
            }

            "method" {
                #Get the name
                set name $arg1
                #Skip the arguments
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines linestart"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Get the start end end of the method
                if {$rights ne ""} {
                    set display_name "$rights method"
                } else {
                    set display_name "method"
                }
                set nstart [$TxtWidget search -regexp $brace_rexp "$nend+1c" "$nend lineend"]
                if {($nstart eq "") || ([$TxtWidget get $nstart] ne "\{")} {
                    #this is a forward declaration!
                    #Create a node
                    set nname "$node\u018b$name"
                    if {![$Editor::treeWindow exists $nname]} {
                        lappend nodeList [list $nname $display_name "$result linestart" "$nend +1c"]
                    }
                    set nname "$node\u018b$name\u018bdeclaration"
                    lappend nodeList [list $nname forward "$result linestart" "$nend +1c" $arglist]
                } else {
                    set nend [GetClosePair "\{" $nstart]
                    if {$nend eq ""} {
                        set nend "$nstart +1lines"
                        if {[$TxtWidget compare $nend >= "end -1c"]} {
                            break
                        }
                        set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                        continue
                    }
                    #Create a node
                    set nname "$node\u018b$name"
                    lappend nodeList [list $nname $display_name "$result linestart" "$nend +1c" $arglist]
                }
            }

            "body" -
            "itcl::body" -
            "::itcl::body" {
                #Get the name
                set name $arg1
                regsub -- {^::} $name "" name
                regsub -all {::} $name \u018b name

                #Skip the arguments
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Get the start end end of the body

                set nstart [$TxtWidget search -regexp $brace_rexp "$nend+1c" end]
                if {[$TxtWidget get $nstart] ne "\{"} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }

                #Create a node
                set nname "$node\u018b$name\u018bbody"
                lappend nodeList [list $nname body "$result linestart" "$nend +1c" $arglist]
            }

            "configbody" -
            "itcl::configbody" -
            "::itcl::configbody" {
                #Get the name
                set name $arg1

                regsub {^::} $name "" name
                regsub -all {::} $name \u018b name
                #Get the start end end of the configbody
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {[$TxtWidget get $nstart] ne "\{"} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }

                #Create a node
                set nname "$node\u018b$name"
                lappend nodeList [list $nname configbody "$result linestart" "$nend +1c" $arglist]
            }

            "constructor" {
                set name $token
                #Skip the arguments
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {$nstart eq ""} {
                    set nend "$nend +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                set nend [GetClosePair "\{" $nstart]
                if {$nend eq ""} {
                    set nend "$nstart +1lines linestart"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                }
                #Get the start end end of the constructor

                set nstart [$TxtWidget search -regexp $brace_rexp "$nend+1c" end]
                if {([$TxtWidget get $nstart] ne "\{") || ([$TxtWidget get "$nstart+1c"] eq "\}")} {
                    #this is a forward declaration!
                    #Create a node
                    set nname "$node\u018b$name"
                    if {![$Editor::treeWindow exists $nname]} {
                        lappend nodeList [list $nname constructor "$result linestart" "$nend +1c"]
                    }
                    set nname "$node\u018b$name\u018bdeclaration"
                    lappend nodeList [list $nname forward "$result linestart" "$nend +1c" $arglist]
                } else {
                    set nend [GetClosePair "\{" $nstart]
                    if {$nend eq ""} {
                        set nend "$nstart +1lines"
                        if {[$TxtWidget compare $nend >= "end -1c"]} {
                            break
                        }
                        set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                        continue
                    }
                    #Create a node
                    set nname "$node\u018b$name"
                    lappend nodeList [list $nname constructor "$result linestart" "$nend +1c" $arglist]
                }
            }

            "destructor" {
                set name $token
                #Get the start and end of the body
                set nstart [$TxtWidget search -forward \{ $result "$result lineend"]
                if {($nstart eq "") || ([$TxtWidget get $nstart] ne "\{") || ([$TxtWidget get "$nstart+1c"] eq "\}")} {
                    #this is a forward declaration!
                    #Create a node
                    set nname "$node\u018b$name"
                    if {![$Editor::treeWindow exists $nname]} {
                        lappend nodeList [list $nname destructor "$result linestart" "$nend +1c"]
                    }
                    set nname "$node\u018b$name\u018bdeclaration"
                    lappend nodeList [list $nname forward "$result linestart" "$nend +1c" $arglist]
                    set nend "$nstart +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                } else {
                    set nend [GetClosePair "\{" $nstart]
                    if {$nend eq ""} {
                        set nend "$nstart +1lines"
                        if {[$TxtWidget compare $nend >= "end -1c"]} {
                            break
                        }
                        set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                        continue
                    }
                    #Create a node
                    set nname "$node\u018b$name"
                    lappend nodeList [list $nname destructor "$result linestart" "$nend +1c" $arglist]
                }
            }

            default {
                #skip line
                if {$nend eq ""} {
                    set nend "$nstart +1lines"
                    if {[$TxtWidget compare $nend >= "end -1c"]} {
                        break
                    }
                    set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]
                    continue
                } else {
                    set nend "$nend +1lines"
                }
            }
        }
        # end of switch

        set result [$TxtWidget search -forwards -regexp $rexp $nend $end ]

        set nend [$TxtWidget index $nend]
        if {$code ne {}} {
            eval $code
        }
    }
    #end of while
    return $nodeList
}

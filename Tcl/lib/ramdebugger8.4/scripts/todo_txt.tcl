
#################################################################################
#   process_todo_txt, process_todo_txt_edit
#   process_todo_txt_help_menu, process_todo_txt_non_edit_menu
#   process_todo_txt_save, process_todo_txt_save_file
#   process_todo_txt_modify, process_todo_txt_modify_property
#################################################################################

# this comes from external ramdebugger
proc RamDebugger::process_todo_txt_save {} {
    variable process_todo_txt_data
    
    if { [dict_getd $process_todo_txt_data normal_edit 0] } {
        return continue
    } else {
        process_todo_txt_save_file
        return break
    }
}

proc RamDebugger::process_todo_txt_end { args } {
    variable text
    variable mainframe
    variable process_todo_txt_data
    
    set optional {
        { -noclosebar "" 0 }
    }
    set compulsory ""
    parse_args $optional $compulsory $args
    
    if { $noclosebar == 0 } {
        $mainframe showtoolbar 2 0
    }
    set ipos [lsearch [bindtags $text] todo.txt]
    if { $ipos != -1 } {
        bindtags $text [lreplace [bindtags $text] $ipos $ipos]
    }
    set ipos [lsearch [bindtags $text] todo.txtA]
    if { $ipos != -1 } {
        bindtags $text [lreplace [bindtags $text] $ipos $ipos]
    }
    $text configure -state normal
    set process_todo_txt_data ""
}

proc RamDebugger::process_todo_set_normal_edit {} {
    variable text
    variable files
    variable currentfile
    variable process_todo_txt_data
    
    process_todo_txt_end
    
    $text delete 1.0 end
    $text insert end [string map [list "\t" "        "] $files($currentfile)]
    $text tag add normal 1.0 end
    
    dict set process_todo_txt_data normal_edit 1
    MarkAsNotModified
}

# this is internal
proc RamDebugger::process_todo_txt_save_file {} {
    variable files
    variable filesmtime
    variable currentfile
    variable currentfile_endline
    variable options
    variable process_todo_txt_data
    
    set lines [lsort -integer -index 0 [dict get $process_todo_txt_data lines]]
    set lines [lsort -nocase -increasing -index 4 $lines]

    set files($currentfile) ""
    foreach line $lines {
        append files($currentfile) [string trim [lindex $line 7]] "\n"
    }

    set err [catch { _savefile_only -file_has_been_read 1 \
                -file_endline $currentfile_endline \
                $currentfile $files($currentfile)} errstring]
    if { $err } {
        tk_messageBox -message [_ "Could not save file '%s' (%s)" $currentfile $errstring]
    } else {
        MarkAsNotModified
        set filesmtime($currentfile) [file mtime $currentfile]
        add_to_recent_files $currentfile
        set options(defaultdir) [file dirname $currentfile]
        RamDebugger::VCS::indicator_update
        SetMessage [_ "Saved file '%s'" $currentfile]
    }
}

proc RamDebugger::process_todo_txt_modify { args } {
    variable process_todo_txt_data
    
    set optional {
        { -save boolean 1 }
    }
    set compulsory "line_num lineN txt"
    parse_args $optional $compulsory $args
    
    set lines [dict get $process_todo_txt_data lines]
    
    if { $lineN eq "" } {
        set idxP [llength $lines]
        set numP [expr {$idxP+1}]
    } else {
        set idxP [lsearch -index 0 $lines $lineN]   
        set numP $lineN
    }
    set d [set_sorting_line $numP $txt]
    if { $lineN eq "" } {
        dict lappend process_todo_txt_data undo_stack [list c]
        lappend lines [dict get $d line]
        dict set process_todo_txt_data text_line_to_line $line_num $numP
    } else {
        set old_line [lindex $lines $idxP]
        dict lappend process_todo_txt_data undo_stack [list m $old_line]
        lset lines $idxP [dict get $d line]
    }
    dict lappend process_todo_txt_data stack_idx ""
    dict set process_todo_txt_data lines $lines
    
    set projects [dict get $process_todo_txt_data projects]
    set contexts [dict get $process_todo_txt_data contexts]
    lappend projects {*}[dict get $d projects]
    lappend contexts {*}[dict get $d contexts] 
    dict set process_todo_txt_data projects [lsort -unique -dictionary $projects]
    dict set process_todo_txt_data contexts [lsort -unique -dictionary $contexts]
    
    if { $save } {
        process_todo_txt_save_file
    }
}

proc RamDebugger::process_todo_txt_modify_property { args } {
    variable process_todo_txt_data
    variable text
    
    set optional {
        { -increase "" 0 }
        { -decrease "" 0 }
        { -remove "" 0 }
        { -dobreak boolean 0 }
    }
    set compulsory "property"
    parse_args $optional $compulsory $args
    
    set lineNList ""
    foreach "sel1 sel2" [$text tag ranges sel] {
        regexp {^\d+} $sel1 l1
        regexp {^\d+} $sel1 l2
        for { set i $l1 } { $i <= $l2 } { incr i } {
            set lineN [dict_getd $process_todo_txt_data text_line_to_line $i ""]
            if { $lineN ne "" } {
                lappend lineNList [list $i $lineN]
            }
        }
    }
    if { [llength $lineNList] == 0 } { return }
    
    for { set i 0 } { $i < [llength $lineNList] } { incr i } {
        lassign [lindex $lineNList $i] line_num lineN
        set idxP [lsearch -index 0 [dict get $process_todo_txt_data lines] $lineN]
        set line [lindex [dict get $process_todo_txt_data lines] $idxP]
        set d [split_task [lindex $line 7]]
        set txt [dict get $d txtF]
        switch $property {
            priority {
                if { [dict get $d completion] } {
                    continue
                }
                if { [dict exists $d priority] } {
                    if { $remove } {
                        dict unset d priority
                    } else {
                        set p [scan [dict get $d priority] %c]
                        if { $increase } {
                            incr p -1
                        } elseif { $decrease } {
                            incr p 1
                        }
                        if { $p < [scan A %c] } {
                            set p [scan A %c]
                        } elseif { $p > [scan Z %c] } {
                            set p [scan Z %c]
                        }
                        dict set d priority [format %c $p]
                    }
                }
                if { [dict exists $d priority] } {
                    set p [dict get $d priority]
                    if { [dict exists $d priority_idxs] } {
                        set txt [string replace $txt {*}[dict get $d priority_idxs] "($p) "]
                    } else {
                        set txt "($p) $txt"
                    }
                } elseif { [dict exists $d priority_idxs] } {
                    set txt [string replace $txt {*}[dict get $d priority_idxs] ""]
                }
            }                
            due_date {
                if { [dict exists $d due_date] } {
                    if { $remove } {
                        dict unset d due_date
                    } else {
                        set date [dict get $d due_date]
                        if { $increase } {
                            set date [clock format [clock add [clock scan $date] 1 day] -format "%Y-%m-%d"]
                        } elseif { $decrease } {
                            set date [clock format [clock add [clock scan $date] -1 day] -format "%Y-%m-%d"]
                        }
                        dict set d due_date $date
                    }
                } elseif { !$remove } {
                    dict set d due_date [clock format [clock seconds] -format "%Y-%m-%d"]
                }
                if { [dict exists $d due_date] } {
                    set date "due:[dict get $d due_date]"
                    if { [dict exists $d due_date_idxs] } {
                        set txt [string replace $txt {*}[dict get $d due_date_idxs] "$date "]
                    } else {
                        set txt "$txt $date"
                    }
                } elseif { [dict exists $d due_date_idxs] } {
                    set txt [string replace $txt {*}[dict get $d due_date_idxs] ""]
                }
            }
            complete {
                if { [regexp {\s*x\s+\d{4}-\d{2}-\d{2}\s+(.*)} $txt {} rest] } {
                    set txt $rest
                } else {
                    set date [clock format [clock seconds] -format "%Y-%m-%d"]
                    set txt "x $date $txt"
                }
            }
        }
        process_todo_txt_modify -save 0 $line_num $lineN $txt
    }
    process_todo_txt_save_file
    process_todo_txt
    if { $dobreak } {
        return -code break
    }
}

proc RamDebugger::process_todo_txt_edit { args } {
    variable text
    variable process_todo_txt_data
    
    set optional {
        { -append "" 0 }
    }
    set compulsory ""
    parse_args $optional $compulsory $args
    
    $text configure -state normal
    set idx [$text index insert]
    
    regexp {^\d+} $idx line_num
    
    set lineN [dict_getd $process_todo_txt_data text_line_to_line $line_num ""]
    if { $lineN eq "" } {
        return
    }
    set idxP [lsearch -index 0 [dict get $process_todo_txt_data lines] $lineN]
    set line [lindex [dict get $process_todo_txt_data lines] $idxP]
    
    if { $append } {
        set list [dict keys [dict get $process_todo_txt_data text_line_to_line]]
        set max [lindex [lsort -integer $list] end]
        for { set i $max } { $i >= $line_num } { incr i -1 } {
            set lineN [dict_getd $process_todo_txt_data text_line_to_line $i ""]
            if { $lineN eq "" } { continue } 
            dict set process_todo_txt_data text_line_to_line [expr {$i+1}] $lineN
        }
        dict set process_todo_txt_data text_line_to_line $line_num ""
        
        set d [split_task [lindex $line 7]]
        set txt ""
        if { [dict exists $d priority] } {
            append txt "([dict get $d priority]) "
        }
        set today [clock format [clock seconds] -format "%Y-%m-%d"]
        append txt "$today "
        foreach project [dict_getd $d projects ""] {
            append txt "$project "
        }
        foreach context [dict_getd $d contexts ""] {
            append txt "$context "
        }
        set line [list 0 "" "" "" "" "" $txt]
        
        lset line 0 ""
        lset line 1 0
        lset line 2 ""
        lset line 4 $today
        lset line 6 ""
        lset line 7 $txt
    }

    $text tag remove sel 1.0 end
    $text tag add noediting 1.0 end
    
    if { !$append } {
        $text delete "$idx linestart" "$idx lineend+1c"
    }
    set idx [$text index "$idx linestart"]
    process_todo_txt_insert_line -idx $idx -full $line
    
    $text tag add editing $idx "$idx lineend+1c"
    if { !$append } {
        $text mark set insert "$idx lineend"
    } else {
        set txt [$text get $idx "$idx lineend+1c"]
        if { [regexp -indices {[+@]} $txt idxs] } {
            $text mark set insert "$idx +[lindex $idxs 0]c"
        } else {
            $text mark set insert "$idx lineend"
        }
    }
    $text tag configure noediting -background #dddddd
    $text tag configure editing -borderwidth 2 -relief groove -background #ffffff -foreground black
    $text tag raise editing
    $text tag raise sel
    MarkAsNotModified
}

proc RamDebugger::process_todo_txt_end_edit { accept_cancel } {
    variable text
    variable process_todo_txt_data

    ptt_menu_destroy $text
    
    lassign [$text tag range editing] e1 e2
    if { $e1 eq "" } {
        $text tag remove noediting 1.0 end
        $text tag remove editing 1.0 end
        $text configure -state disabled
        process_todo_txt_keys -dobreak 0 Selection ""
        return
    }
    set idx [$text index $e1]
    regexp {^\d+} $idx line_num
    set lineN [dict get $process_todo_txt_data text_line_to_line $line_num]
    
    if { $accept_cancel eq "cancel" } {
        lassign [$text tag range editing] e1 e2
        if { $e1 ne "" } {
            $text delete $e1 $e2
        }
        if { $lineN ne "" } {
            set idxP [lsearch -index 0 [dict get $process_todo_txt_data lines] $lineN]
            set line [lindex [dict get $process_todo_txt_data lines] $idxP]
            set idx [$text index "$idx linestart"]
            process_todo_txt_insert_line -idx $idx $line
            $text mark set insert $idx
        }
        MarkAsNotModified
    } else {
        lassign [$text tag range editing] e1 e2
        if { $e1 ne "" } {
            set txt [string trim [$text get $e1 $e2]]
            process_todo_txt_modify $line_num $lineN $txt
        }
    }
    $text tag remove noediting 1.0 end
    $text tag remove editing 1.0 end
    $text configure -state disabled
    process_todo_txt_keys -dobreak 0 Selection ""
}

proc RamDebugger::process_todo_txt_keys_after { args } {
    variable text
    
    if { [$text cget -state] ne "disabled" } {
        lassign [$text tag range editing] e1 e2
        if { $e1 ne "" } {
            set idx [$text index insert]
            if { [$text compare $idx < $e1] || [$text compare $idx > $e2] } {
                process_todo_txt_end_edit accept
            }
        }
    }
    process_todo_txt_help_menu $text
}

proc RamDebugger::process_todo_txt_keys { args } {
    variable text
    variable last_selection
    variable last_selection_doing
    variable process_todo_txt_data

    set optional {
        { -dobreak boolean 1 }
    }
    set compulsory "what key"
    parse_args $optional $compulsory $args
       
    switch $what {
        Control-KeyPress {
            return
        }
        BR1 {
            set idx [$text index $key]
            if { [$text cget -state] ne "disabled" } {
                lassign [$text tag range editing] e1 e2
                if { $e1 eq "" || [$text compare $idx < $e1] || [$text compare $idx > $e2] } {
                    process_todo_txt_end_edit accept
                    return -code break
                } else {
                    return
                }
            }
            lassign [$text tag range sel] sel1 sel2
            if { $sel1 ne "" && [$text compare $idx >= $sel1] && [$text compare $idx < $sel2] } {
                $text tag add sel "$sel1 linestart" "$sel2"
            } else {
                $text tag add sel "$idx linestart" "$idx lineend+1c"
            }
            #after idle [list RamDebugger::process_todo_txt_non_edit_menu]
        }
        DBR1 {
            if { [$text cget -state] ne "disabled" } {
                return
            }
            process_todo_txt_edit
        }
        Selection {
            if { [$text cget -state] ne "disabled" } {
                return
            }
            set sel1 [lindex [$text tag ranges sel] 0]
            set sel2 [lindex [$text tag ranges sel] end]
            if { $sel1 eq "" } { 
                set sel1 [$text index insert]
                set sel2 $sel1
                set idx1 ""
            } else {
                set idx1 $sel1   
            }
            set last_selectionL [list $sel1 $sel2]
            if { $last_selectionL eq [set! last_selection] } { return }
            
            if { [set! last_selection_doing] == 1 } { return }
            set last_selection_doing 1
            
            $text tag remove sel 1.0 end
            lassign "0 0" has_selection has_finished
            foreach "idx1 idx2" [$text tag ranges lines] {
                regexp {^\d+} $idx1 l1
                regexp {^\d+} $idx2 l2
                for { set i $l1 } { $i <= $l2 } { incr i } {
                    if { [$text compare $i.0 >= "$sel1 linestart"] } {
                        if { [$text compare $i.0 < $sel2] } {
                            $text tag add sel "$i.0" "$i.0 lineend+1c"
                            set has_selection 1
                        } else {
                            if { !$has_selection } {
                                $text tag add sel "$i.0" "$i.0 lineend+1c"
                            }
                            set has_finished 1
                            break
                        }
                    }
                }
                if { $has_finished } {
                    break
                }
            }
            set sel1 [lindex [$text tag range sel] 0]
            set sel2 [lindex [$text tag range sel] end]
            set last_selection [list $sel1 $sel2]
            set last_selection_doing 0
            
            if { $dobreak } { return -code break }
        }
        KeyPress - Shift-KeyPress {
            if { [$text cget -state] eq "disabled" } {
                lassign [$text tag range sel] sel1 sel2
                if { $sel1 ne "" } {
                    $text mark set insert $sel1
                }
                switch $key {
                    F2 {
                        set ret [catch [bind $text <Key-F2>] retstring]
                        if { $ret != 3 } {
                            error $retstring
                        }
                        $text tag remove sel 1.0 end
                        process_todo_txt_keys -dobreak 0 Selection ""
                        return -code break
                    }
                    Up - Down {
#                         if { $what eq "Shift-KeyPress" } {
#                             return 
#                         }
                        set idx [$text index insert]
                        while 1 {
                            if { $key eq "Up" } {
                                set idx [$text index "$idx -1l"]
                            } else {
                                set idx [$text index "$idx +1l"]
                            }
                            if { [$text compare "$idx linestart" == "1.0"] } { break }
                            if { [lsearch [$text tag names $idx] title] != -1 } { continue }
                            if { [lsearch [$text tag names $idx] lines] == -1 } {
                                break
                            }
                            if { [$text compare "$idx linestart" == "end-1l"] } {
                                set idx [$text index "$idx-1l"]
                                break
                            }
                            break
                        }
                        if { [lsearch [$text tag names $idx] lines] == -1 } {
                            if { $dobreak } { return -code break }
                            return
                        }
                        $text mark set insert $idx
                        if { $what ne "Shift-KeyPress" } {
                            $text tag remove sel 1.0 end
                        }
                        $text tag add sel "$idx linestart" "$idx lineend"
                        if { $dobreak } { return -code break }
                    }
                    c {
                        process_todo_toggle_view view_completed 1   
                    }
                    d {
                        process_todo_toggle_view create_date 1
                    }
                    e {
                        process_todo_txt_edit   
                    }
                    n {
                        process_todo_txt_edit -append
                    }
                    f - Tab {
                        set w [dict_getd $process_todo_txt_data search_widget ""]
                        if { $w ne "" } {
                            tk::TabToWindow $w
                        }
                    }
                    Return {
                        process_todo_txt_non_edit_menu
                    }
                }
                if { $dobreak } { return -code break }
            } else {
                switch $key {
                    Up - Down {
                        process_todo_txt_end_edit accept
                        if { $dobreak } { return -code break }
                    }
                    Return {
                        process_todo_txt_end_edit accept
                        if { $dobreak } { return -code break }
                    }
                    Escape {
                        process_todo_txt_end_edit cancel
                        if { $dobreak } { return -code break }
                    }
                    BackSpace {
                        set idx [$text index insert]
                        lassign [$text tag range editing] e1 e2
                        if { [$text compare $idx <= $e1] } {
                            if { $dobreak } { return -code break }
                        }
                    }
                }
            }
        }
    }
}

proc RamDebugger::split_task { txt } {
    
    set d ""
    set txt [string trim $txt]
    
    if { [regexp -indices {^\s*(x)\s} $txt all_idxs c_idxs] } {
        dict set d completion 1
        dict set d completion_idxs $c_idxs
        set start [expr {[lindex $all_idxs 1]+1}]

        if { [regexp -start $start -indices {\A\s*(\d{4}\-\d{2}\-\d{2})\s} $txt all_idxs d_idxs] } {
            dict set d completion_date [string range $txt {*}$d_idxs]
            dict set d completion_date_idxs $d_idxs
            set start [expr {[lindex $all_idxs 1]+1}]
        }
    } else {
        dict set d completion 0
        set start 0
    }
    if { [regexp -start $start -indices {\A\s*(\(([A-Z])\)\s)} $txt all_idxs pF_idxs p_idxs] } {
        dict set d priority [string range $txt {*}$p_idxs]
        dict set d priority_idxs $pF_idxs
        set start [expr {[lindex $all_idxs 1]+1}]
    }
    if { [regexp -start $start -indices {\A\s*(\d{4}\-\d{2}\-\d{2})\s} $txt all_idxs d_idxs] } {
        dict set d start_date [string range $txt {*}$d_idxs]
        dict set d start_date_idxs $d_idxs
        set start [expr {[lindex $all_idxs 1]+1}]
    }
    
    set projects ""
    foreach "- - p" [regexp -inline -all {(\s+|^)([+][^\s]+)} $txt] {
        lappend projects $p
    }
    set contexts ""
    foreach "- - p" [regexp -inline -all {(\s+|^)([@][^\s]+)} $txt] {
        lappend contexts $p
    }

    dict set d projects $projects
    dict set d contexts $contexts

    if { [regexp -start $start -indices {due:(\d{4}\-\d{2}\-\d{2})} $txt all_idxs d_idxs] } {
        dict set d due_date [string range $txt {*}$d_idxs]
        dict set d due_date_idxs $all_idxs
    }
    if { [regexp -start $start -indices {n:(\S+)} $txt all_idxs n_idxs] } {
        dict set d note [string range $txt {*}$n_idxs]
        dict set d note_idxs $all_idxs
    }
    dict set d txtF $txt
    dict set d txtS [string trim [string range $txt $start end]]
    regsub -all {(\+|@|due:|t:|n:)\S+} [dict get $d txtS] {} t
    dict set d txtSS $t
    return $d    
}

proc RamDebugger::set_sorting_line { idx txt } {
    
    set d [split_task $txt]
    
    if { ![dict exists $d priority] } {
        dict set d priority ZZ
    }
    dict set d project [lindex [dict_getd $d projects ""] 0]
    if { [dict get $d project] eq "" } {
        dict set d project +ZZZZZZZ
    }
    dict set d line [list $idx \
            [dict get $d completion] \
            [dict_getd $d completion_date ""] \
            [dict_getd $d priority ""] \
            [dict_getd $d start_date ""] \
            [dict_getd $d project ""] \
            [dict_getd $d due_date ""] \
            $txt]
    dict set d projects [dict_getd $d projects ""]
    dict set d contexts [dict_getd $d contexts ""]
    return $d
}

proc RamDebugger::process_todo_txt_insert_line { args } {
    variable text
    variable process_todo_txt_data
    variable process_todo_txt_view_create_date
    variable process_todo_txt_view_completed
    
    set optional {
        { -orderby_txt orderby_txt ""  }
        { -idx idx "end" }
        { -search string "" }
        { -full "" 0 }
    }
    set compulsory "line"
    parse_args $optional $compulsory $args
    
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    
    lassign $line lineN completion completion_date priority \
        start_date project due_date txt
    
    if { $search ne "" && ![string match -nocase *$search* $txt] } { return 0 }
    
    if { !$full } {
        set d [split_task $txt]
        if { $process_todo_txt_view_completed == 0 && [dict get $d completion] } {
            return 0
        }
        if { $process_todo_txt_view_create_date == 0 } {
            set txt ""
            if { [dict get $d completion] } {
                append txt "x "
            }
            if { [dict exists $d priority] } {
                append txt "([dict get $d priority]) "
            }
            append txt [dict get $d txtS]
        }
    }
    
    if { $orderby_txt ne "" } {
        $text insert end "\n$orderby_txt\n" title
    }
    if { $completion } {
        set tag completed
    } elseif { $due_date eq "" || $due_date > $today } {
        set tag normal
    } elseif { $due_date == $today } {
        set tag today
    } else {
        set tag old
    }
    if { $idx eq "end" } { set idx "end-1c" }
    set idx [$text index $idx]
    $text insert $idx "$txt\n" "$tag lines"
    
    regexp {^\d+} $idx line_num
    dict set process_todo_txt_data text_line_to_line $line_num $lineN
    return 1
}

proc RamDebugger::process_todo_search { w } {
    variable process_todo_txt_data
    variable process_todo_txt_str
    
    process_todo_txt_help_menu $w
    
    after cancel [dict_getd $process_todo_txt_data afterid 0]
    set a [after 200 [list RamDebugger::process_todo_txt -search $process_todo_txt_str]]
    dict set process_todo_txt_data afterid $a
}

proc RamDebugger::process_todo_txt_help_menu_insert { w txt } {

    if { [winfo class $w] eq "Text" } {
        set idx [$w index insert]
        set txtW [$w get "$idx linestart" "$idx"]
    } else {
        set txtW [$w get]
    }
    if {![regexp {^((.*\s+|))$} $txtW {} start] &&
        ![regexp {^(.*)(due|t|n):\S*$} $txtW {} start] &&
        ![regexp {^(\s*)([(][A-Z]?)$} $txtW {} start] && 
        ![regexp {^(.*)([+@][^+@ \t]*)$} $txtW {} start] } {
        ptt_menu_destroy $w
        return
    }
    if { [winfo class $w] eq "Text" } {
        set tags [$w tag names "$idx linestart"]
        $w delete "$idx linestart" "$idx"
        $w insert "$idx linestart" $start$txt $tags
        $w mark set insert "$idx linestart +[string length $start$txt]c"
    } else {
        $w delete 0 end
        $w insert end $start$txt
        $w icursor end
    }
    after idle [list RamDebugger::process_todo_txt_help_menu $w]
}

proc RamDebugger::process_todo_txt_help_menu { w } {
    variable process_todo_txt_data
    
    if { [$w cget -state] eq "disabled" } { return }
        
    if { [winfo class $w] eq "Text" } {
        set idx [$w index insert]
        set txt [$w get "$idx linestart" "$idx"]
    } else {
        set txt [$w get]
    }
    if { [regexp -indices {(\s+)$} $txt {} idxs] } {
        set prefix ""
    } elseif { [regexp -indices {((due|t|n):\S*)$} $txt {} idxs] } {
        set prefix [string range $txt {*}$idxs]
    } elseif { [regexp -indices {^\s*([(][A-Z]?)$} $txt {} idxs] } {
        set prefix [string range $txt {*}$idxs]
    } elseif { [regexp -indices {([+@][^+@ \t]*)$} $txt {} idxs] } {
        set prefix [string range $txt {*}$idxs]
    } else {
        ptt_menu_destroy $w
        return
    }
    
    if { $prefix eq "" } {
        set list [list "+" "@" "due:" "t:" "n:"]
    } elseif { [regexp {(n):\S*} $prefix {} p] } {
        if { ![regexp {^\s*(\d{4}-\d{2}-\d{2})} $txt {} date] } {
            set date [clock format [clock seconds] -format "%Y-%m-%d"]
        }
        set list [list $p:$date.md]

        set listN ""
        set lines [dict get $process_todo_txt_data lines]
        foreach line $lines {
            if { [regexp {n:(\S+)} [lindex $line 7] {} name] } {
                lappend listN n:$name
            }
        }
        lappend list {*}[lsort -dictionary -unique $listN]
    } elseif { [regexp {(due|t):\S*} $prefix {} p] } {
        set today [clock format [clock seconds] -format "%Y-%m-%d"]
        set list [list $p:$today]
    } elseif { [regexp {\(.*} $prefix] } {
        set list [list (A) (B) (C) (D) (E) (F)]
    } elseif { [string match @* $prefix] } {
        set list [dict get $process_todo_txt_data contexts]
    } else {
        set list [dict get $process_todo_txt_data projects] 
    }
    
    if { $prefix in $list } {
        ptt_menu_destroy $w
        return
    }
    set listR ""
    foreach p $list {
        if { [string match $prefix* $p] } {
            lappend listR $p
        }
    }
    set cmd [list RamDebugger::process_todo_txt_help_menu_insert]
    
    if { [winfo class $w] eq "Text" } {
        set idx [$w index "$idx linestart+[lindex $idxs 0]c"]
    } else {
        set idx [lindex $idxs 0]
    }
    ptt_menu $w $idx $listR $cmd
}

proc RamDebugger::process_todo_txt_non_edit_menu {} {
    variable text
    variable process_todo_txt_data

    set list [list [_ "Edit"]]

    set sel1 [lindex [$text tag ranges sel] 0]
    set sel2 [lindex [$text tag ranges sel] end]
    if { [$text compare $sel1 != "$sel2-1l"] } {
        return
    }
    set idx [$text index insert]
    regexp {^\d+} $idx line_num
    set lineN [dict_getd $process_todo_txt_data text_line_to_line $line_num ""]
    if { $lineN eq "" } {
        return
    }
    set idxP [lsearch -index 0 [dict get $process_todo_txt_data lines] $lineN]
    set line [lindex [dict get $process_todo_txt_data lines] $idxP]
    set txt [lindex $line 7]
    set d [split_task $txt]
    if { [dict exists $d note] } {
        lappend list [_ "Edit note"] [_ "View note"]
    }
    
    set cmd "RamDebugger::process_todo_txt_non_edit_menu_eval"
    
    ptt_menu $text $idx $list $cmd
}

proc RamDebugger::process_todo_txt_non_edit_menu_eval { w what } {
    variable text
    variable process_todo_txt_data
    variable currentfile
    
    if { $what eq [_ "Edit"] } {
        process_todo_txt_edit
    } elseif { $what eq [_ "Edit note"] || $what eq [_ "View note"] } {
        set idx [$text index insert]
        regexp {^\d+} $idx line_num
        set lineN [dict_getd $process_todo_txt_data text_line_to_line $line_num ""]
        if { $lineN eq "" } {
            return
        }
        set idxP [lsearch -index 0 [dict get $process_todo_txt_data lines] $lineN]
        set line [lindex [dict get $process_todo_txt_data lines] $idxP]
        set txt [lindex $line 7]
        set d [split_task $txt]
        if { ![dict exists $d note] } {
            tk_messageBox -message [_ "Current entry has no note"] -parent $w
            return
        }
        if { [file extension [dict get $d note]] eq ".pdf" } {
            set dir [file join [file dirname $currentfile] notes]
            set file [file join $dir [dict get $d note]]
            exec {*}[auto_execok start] $file
            return
        }
        if { [file extension [dict get $d note]] ne ".md" } {
            tk_messageBox -message [_ "only notes with .md extension are supported"] -parent $w
            return
        }
        set dir [file join [file dirname $currentfile] docs]
        set file [file join $dir [dict get $d note]]
        if { ![file exists $file] } {
            set dir [file join [file dirname $currentfile] notes]
            file mkdir $dir
        }
        set file [file join $dir [dict get $d note]]
        if { ![file exists $file] } {
            if { $what eq [_ "View note"] } {
                tk_messageBox -message [_ "note '%s' does not exist" [dict get $d note]] -parent $w
                return
            }
            set fout [open $file w]
            fconfigure $fout -encoding utf-8
            puts $fout "---"
            puts $fout "title:         [dict get $d txtSS]  "
            puts $fout "projects:      [join [dict get $d projects] {, }]  "
            puts $fout "date:          [dict_getd $d start_date {}]  "
            puts $fout "css:           css/markdown.css  "
            puts $fout "---"
            close $fout
        } else {
            set fin [open $file r]
            fconfigure $fin -encoding utf-8
            set data [read $fin]
            close $fin
            if { [regexp {^(---\s*?\n.*?\n---\s*?\n\n)(.*)$} $data {} header rest] } {
                set data $header
                if { [regexp [dict_getd $d start_date {}] [string range $rest 0 100]]==0 } {
                    append data "# [dict get $d txtSS] - [dict_getd $d start_date {}]\n\n"
                    append data $rest
                    set fout [open $file w]
                    fconfigure $fout -encoding utf-8
                    puts $fout $data
                    close $fout
                }
            }
        }
        if { $what eq [_ "Edit note"] } {
            OpenFileF $file
        } else {
            process_markdown -to html5 $file
        }
    }
}

proc RamDebugger::ptt_menu { w idx list cmd } {
            
    set bbox [$w bbox $idx]
    if { $bbox eq "" && [winfo class $w] eq "Text" } {
        set bbox [$w dlineinfo $idx]
        if { [lindex $bbox 0] < 10 } { lset bbox 0 10 }
    }
    if { $bbox eq "" } { return }
    if { ![winfo exists $w.t] } {
        toplevel $w.t
        wm attributes $w.t -topmost 1
        wm overrideredirect $w.t 1
        grab $w.t
        bind $w.t <ButtonPress-1> [list RamDebugger::ptt_menu_grab $w %X %Y]
    }
    set x [expr {[winfo rootx $w]+[lindex $bbox 0]}]
    set y [expr {[winfo rooty $w]+[expr {[lindex $bbox 1]+[lindex $bbox 3]}]}]
    wm geometry $w.t +$x+$y
    
    if { [llength $list] > 15 } {
        set list [lrange $list 0 14]
    }
        
    destroy {*}[winfo children $w.t]
    set idx 1
    foreach p $list {
        set b [button $w.t.b$idx -text $p -bd 1 -relief ridge -padx 0 -pady 0 \
                -anchor w -command [list RamDebugger::ptt_menu_eval $w $p $cmd]]
        bind $b <Return> [list $b invoke]
        bind $b <Escape> [list RamDebugger::ptt_menu_destroy $w]
        if { $idx > 1 } {
            set b_prev $w.t.b[expr {$idx-1}]
            bind $b_prev <Down> [list focus $b]
            bind $b <Up> [list focus $b_prev]
        }
        grid $b -sticky ew
        incr idx
    }
    if { $idx == 1 } {
        ptt_menu_destroy $w
        return
    }
     
    if { [lsearch [bindtags $w] MM] == -1 } {
        bindtags $w [linsert [bindtags $w] 0 MM]
    }
    bind MM <Down> "[list focus $w.t.b1]; break"
    bind MM <Up> "[list focus $w.t.b[expr {$idx-1}]]; break"
    bind MM <FocusOut> [list RamDebugger::ptt_menu_focus $w]
    foreach e [list <Escape> <Return> <Left> <Right>] {
        bind MM $e "[list RamDebugger::ptt_menu_destroy $w]; break"
    }
}

proc RamDebugger::ptt_menu_eval { w value cmd } {

    uplevel #0 [list {*}$cmd $w $value]
    ptt_menu_destroy $w 
}

proc RamDebugger::ptt_menu_grab { w X Y } {
    
    if { ![winfo exists $w.t] } { return }
    
    set x [expr {$X-[winfo rootx $w]}]
    set y [expr {$Y-[winfo rooty $w]}]
    
    if { $X < [winfo rootx $w.t] || $X > [winfo rootx $w.t]+[winfo width $w.t] || \
        $Y < [winfo rooty $w.t] || $Y > [winfo rooty $w.t]+[winfo height $w.t] } {
        ptt_menu_destroy $w
        event generate $w <ButtonPress-1> -rootx $x -rooty $y -x $x -y $y
    }
}

proc RamDebugger::ptt_menu_focus { w } {

    if { [focus] eq "$w" } { return }
    if { ![winfo exists $w.t] } { return }
    if { [focus] eq [focus -lastfor $w.t] } { return }

    ptt_menu_destroy $w
}

proc RamDebugger::ptt_menu_destroy { w } {
    
    destroy $w.t
    set ipos [lsearch [bindtags $w] MM]
    if { $ipos != -1 } {
        bindtags $w [lreplace [bindtags $w] $ipos $ipos]
    }
    focus $w
}

proc RamDebugger::process_todo_toggle_view { what toggle } {
    variable text
    variable process_todo_txt_view_create_date
    variable process_todo_txt_view_completed
    
    if { [$text cget -state] ne "disabled" } {
        return
    }
    if { $toggle } {
        switch $what {
            create_date {
                if { $process_todo_txt_view_create_date } {
                    set process_todo_txt_view_create_date 0
                } else {
                    set process_todo_txt_view_create_date 1
                }
            }
            view_completed {
                if { $process_todo_txt_view_completed } {
                    set process_todo_txt_view_completed 0
                } else {
                    set process_todo_txt_view_completed 1
                }
            }
        }
    }
    process_todo_txt
#     if { $toggle } {
#         return -code break
#     }
}

proc nice_acc { acc } {
    foreach "n v" [list Control Ctrl Shift \u21e7 Left \u2190 Up \u2191 \
            Right \u2192 Down \u2193 Key- ""] {
        regsub -all $n $acc $v acc
    }
    return $acc
}

#################################################################################
#    process_todo_txt main function
#################################################################################

proc RamDebugger::process_todo_txt { args } {
    variable text
    variable mainframe
    variable files
    variable currentfile
    variable currentfileIsModified
    variable options
    variable process_todo_txt_data
    variable process_todo_txt_view_create_date
    variable process_todo_txt_view_completed
    variable process_todo_txt_order
    
    set optional {
        { -search search "-" }
        { -order order "-" }
    }
    set compulsory ""
    parse_args $optional $compulsory $args
    
    package require compass_utils
    #mylog::init -view_binding <Control-L> debug
    #mylog::debug start
    
    if { ![info exists process_todo_txt_data] } {
        set process_todo_txt_data ""
    }
    
    if { ![info exists options(todo.txt)] } {
        set options(todo.txt) ""
    }
    set currentfileT [file tail $currentfile]
    
    if { ![dict exists $process_todo_txt_data normal_edit] } {
        dict set process_todo_txt_data normal_edit 0
    }
    if { [dict get $process_todo_txt_data normal_edit] } {
        return
    }
    
    if { $search ne "-" } {
        dict set process_todo_txt_data search $search
    } else {
        set search [dict_getd $process_todo_txt_data search ""]
    }
    if { $order ne "-" } {
        dict set process_todo_txt_data order $order
    } else {
        set order [dict_getd $options(todo.txt) $currentfileT order "project_priority"]
        set order [dict_getd $process_todo_txt_data order $order]
    }
    if { ![info exists process_todo_txt_view_create_date] } {
        set process_todo_txt_view_create_date [dict_getd $options(todo.txt) \
                $currentfileT view_create_date 1]
    }
    if { ![info exists process_todo_txt_view_completed] } {
        set process_todo_txt_view_completed [dict_getd $options(todo.txt) \
                $currentfileT view_completed 1]
    }
    
    dict set options(todo.txt) $currentfileT order $order
    dict set options(todo.txt) $currentfileT view_create_date $process_todo_txt_view_create_date
    dict set options(todo.txt) $currentfileT view_completed $process_todo_txt_view_completed
    
    dict set process_todo_txt_data order_labels [dict create \
            project_priority [dict create n [_ "Project+priority"] acc Control-Key-1] \
            project_creationdate [dict create n [_ "Project+creation date"] acc Control-Key-2] \
            creationdate [dict create n [_ "Creation date"] acc Control-Key-3] \
            priority [dict create n [_ "Priority"] acc Control-Key-4] \
            ]
    
    dict set process_todo_txt_data menu [list \
            [dict create n [_ "New task"] acc_print n \
                cmd "process_todo_txt_edit -append"] \
            [dict create n [_ "Edit task"] acc_print e \
                cmd "process_todo_txt_edit"] \
            [dict create] \
            [dict create n [_ "View create date"] var process_todo_txt_view_create_date \
                acc_print d cmd "process_todo_toggle_view create_date 0"] \
            [dict create n [_ "View completed"] var process_todo_txt_view_completed \
                acc_print c cmd "process_todo_toggle_view view_completed 0"] \
            [dict create] \
            [dict create n [_ "Increase priority"] acc Control-Up \
                cmd "process_todo_txt_modify_property -increase priority"] \
            [dict create n [_ "Decrease priority"] acc Control-Down \
                cmd "process_todo_txt_modify_property -decrease priority"] \
            [dict create n [_ "Remove priority"] acc Control-Left,Control-Right \
                cmd "process_todo_txt_modify_property -remove priority"] \
            [dict create n [_ "Increase due date"] acc Control-Shift-Up \
                cmd "process_todo_txt_modify_property -increase due_date"] \
            [dict create n [_ "Decrease due date"] acc Control-Shift-Down \
                cmd "process_todo_txt_modify_property -decrease due_date"] \
            [dict create n [_ "Remove due date"] acc Control-Shift-Left,Control-Shift-Right \
                cmd "process_todo_txt_modify_property -remove due_date"] \
            [dict create n [_ "Complete"] acc "Control-End" \
                cmd "process_todo_txt_modify_property complete"] \
            [dict create] \
            [dict create n [_ "Normal edition"]  \
                cmd "process_todo_set_normal_edit"] \
            ]
    
    if { ![info exists process_todo_txt_view_create_date] } {
        set process_todo_txt_view_create_date 1
    }
    if { ![info exists process_todo_txt_view_completed] } {
        set process_todo_txt_view_completed 1
    }
    
    set process_todo_txt_order [dict get $process_todo_txt_data order_labels $order n]
    
    if { [lsearch [bindtags $text] todo.txt] == -1 } {
        bindtags $text [linsert [bindtags $text] 0 todo.txt]
        bindtags $text [list {*}[bindtags $text] todo.txtA]
    }
    bind todo.txt <KeyPress> [list RamDebugger::process_todo_txt_keys KeyPress %K]
    bind todo.txt <Shift-KeyPress> [list RamDebugger::process_todo_txt_keys Shift-KeyPress %K]
    bind todo.txt <Control-KeyPress> [list RamDebugger::process_todo_txt_keys Control-KeyPress %K]
    bind todo.txt <ButtonRelease-1> [list RamDebugger::process_todo_txt_keys BR1 @%x,%y]
    bind todo.txt <Double-ButtonRelease-1> [list RamDebugger::process_todo_txt_keys DBR1 @%x,%y]
    bind todo.txt <<Selection>> [list RamDebugger::process_todo_txt_keys Selection ""]
    bind todo.txtA <KeyPress> [list RamDebugger::process_todo_txt_keys_after]
    
    dict for "n v" [dict get $process_todo_txt_data order_labels] {
        set cmd [list RamDebugger::process_todo_txt -order $n]
        bind todo.txt <[dict get $v acc]> "$cmd;break"
    }
    foreach d [dict get $process_todo_txt_data menu] {
        set acc [dict_getd $d acc ""]
        if { $acc eq "" } { continue }
        if { [dict exists $d cmd_acc] } {
            set cmd RamDebugger::[dict get $d cmd_acc]
        } else {
            set cmd RamDebugger::[dict get $d cmd]
        }
        foreach acc [split $acc ","] {
            bind todo.txt <$acc> "$cmd; break"
        }
    }
    
    $mainframe showtoolbar 2 1
    set f [$mainframe gettoolbar 2]
    
    if { ![winfo exists $f.l] } {
        ttk::label $f.l -text [_ "Search"]:
        ttk::entry $f.e1 -width 30 -textvariable ::RamDebugger::process_todo_txt_str
        dict set process_todo_txt_data search_widget $f.e1
        
        bind $f.e1 <Tab> "[list focus $text]; break"
        bind $f.e1 <Escape> "[list $f.e1 delete 0 end]; break"
        
        # to avoid problems with paste, that sometimes pastes too to the main window
        bind $f.e1 <<Paste>> "[bind [winfo class $f.e1] <<Paste>>]; break"
        trace add variable ::RamDebugger::process_todo_txt_str write \
            "[list RamDebugger::process_todo_search $f.e1];#"
        
        ttk::menubutton $f.m -textvariable RamDebugger::process_todo_txt_order -menu $f.m.mb
        menu $f.m.mb
        
        dict for "n v" [dict get $process_todo_txt_data order_labels] {
            set cmd [list RamDebugger::process_todo_txt -order $n]
            set acc [nice_acc [dict_getd $v acc_print [dict_getd $v acc ""]]]
            $f.m.mb add command -label [dict get $v n] -acc $acc \
                -command $cmd
            if { [dict exists $v acc] } {
                bind $f.e1 <[dict get $v acc]> "$cmd;break"
            }
        }
        
        ttk::menubutton $f.m2 -text [_ "Tasks"] -menu $f.m2.mb
        menu $f.m2.mb
        
        foreach d [dict get $process_todo_txt_data menu] {
            if { [dict exists $d var] } {
                $f.m2.mb add checkbutton
            } elseif { [dict exists $d cmd] } {
                $f.m2.mb add command
            } else {
                $f.m2.mb add separator
                continue
            }
            set acc [nice_acc [dict_getd $d acc_print [dict_getd $d acc ""]]]
            $f.m2.mb entryconfigure end -label [dict get $d n] -acc $acc \
                -command RamDebugger::[dict get $d cmd]
            if { [dict exists $d var] } {
                $f.m2.mb entryconfigure end -variable RamDebugger::[dict get $d var]
            }
            if { [dict exists $d acc] } {
                if { [dict exists $d cmd_acc] } {
                    set cmd RamDebugger::[dict get $d cmd_acc]
                } else {
                    set cmd RamDebugger::[dict get $d cmd]
                }
                foreach acc [split [dict get $d acc] ","] {
                    bind $f.e1 <$acc> "$cmd; break"
                }
            }
        }
        grid $f.l $f.e1 $f.m $f.m2 -sticky ew
        grid columnconfigure $f 1 -weight 0
    }
    set currentfileIsModified_save $currentfileIsModified

    lassign "" lineNList currentN
    if { ![dict exists $process_todo_txt_data lines] } {
#         lassign "" data projects contexts
#         set on 1
#         foreach "key value index" [$text dump 1.0 end] {
#             switch $key {
#                 text {
#                     if { $on } {
#                         append data $value
#                     }
#                 }
#                 tagon {
#                     if { $value eq "title" } {
#                         set on 0
#                     }
#                 }
#                 tagoff {
#                     if { $value eq "title" } {
#                         set on 1
#                     }
#                 }
#             }
#         }
        
        #mylog::debug AA1
        set data [string map [list "\t" "        "] $files($currentfile)]
        #mylog::debug AA2
        lassign "" lines projects contexts
        set idx 1
        foreach txt [split [string trim $data] \n] {
            set d [set_sorting_line $idx $txt]
            lappend lines [dict get $d line]
            lappend projects {*}[dict get $d projects]
            lappend contexts {*}[dict get $d contexts]
            incr idx
        }
        #mylog::debug AA3
        dict set process_todo_txt_data projects [lsort -unique -dictionary $projects]
        dict set process_todo_txt_data contexts [lsort -unique -dictionary $contexts]
        #mylog::debug AA4
    } else {
        set lines [dict get $process_todo_txt_data lines]
        foreach "sel1 sel2" [$text tag ranges sel] {
            if { [$text compare $sel2 == "$sel2 linestart"] } {
                set sel2 [$text index "$sel2 -1 line lineend"]
            }
            regexp {^\d+} $sel1 l1
            regexp {^\d+} $sel2 l2
            for { set i $l1 } { $i <= $l2 } { incr i } {
                set lineN [dict_getd $process_todo_txt_data text_line_to_line $i ""]
                if { $lineN ne "" } {
                    lappend lineNList $lineN
                }
            }
        }
        set idx [$text index insert]
        if { $idx ne "" } {
            regexp {^\d+} $idx l1
            set currentN [dict_getd $process_todo_txt_data text_line_to_line $l1 ""]
        }
    }
    switch $order {
        project_priority {
            set lines [lsort -nocase -index 3 $lines]
            set lines [lsort -nocase -index 5 $lines]
            set orderby 5
        }
        project_creationdate {
            set lines [lsort -nocase -decreasing -index 4 $lines]
            set lines [lsort -nocase -index 5 $lines]
            set orderby 5
        }
        creationdate {
            set lines [lsort -nocase -index 3 $lines]
            set lines [lsort -nocase -decreasing -index 4 $lines]
            set orderby 4
        }
        priority {
            set lines [lsort -nocase -decreasing -index 4 $lines]
            set lines [lsort -nocase -index 3 $lines]
            set orderby 3
        }
    }
    #mylog::debug AA5
    set lines [lsort -nocase -index 1 $lines]
    #mylog::debug AA6
    
    set fontbold [font actual [$text cget -font]]
    set ipos [lsearch $fontbold -weight]
    set fontbold [lreplace $fontbold $ipos+1 $ipos+1 bold]
    
    $text tag configure title -font $fontbold
    $text tag configure lines -lmargin1 10
    $text tag configure completed -foreground grey -overstrike 1
    $text tag configure today -foreground green
    $text tag configure old -foreground red
    $text tag configure strip -background #fafafa
    $text tag lower strip
    
    $text configure -state normal
    $text delete 1.0 end
    lassign "0 0 0" has_selection has_insert idx_group
    foreach line $lines {
        set orderby_txt [lindex $line $orderby]
        if { ![info exists orderby_txt_prev] || $orderby_txt ne $orderby_txt_prev } {
            if { $orderby_txt eq "+ZZZZZZZ" || $orderby_txt eq "ZZ" } {
                set orderby_txt [_ "(NONE)"]
            }
        } else {
            set orderby_txt ""
        }
        if { [lindex $line 1] } {
            if { ![info exists orderby_txt_prevC] } {
                set orderby_txt [_ "(Completed)"]
                set orderby_txt_prevC 1
            } else {
                set orderby_txt ""
            }
        }
        set ret [process_todo_txt_insert_line -orderby_txt \
                $orderby_txt -search $search $line]
        if { !$ret } {
            continue
        }
        set orderby_txt_prev [lindex $line $orderby]
        
        if { $orderby_txt ne "" } {
            set idx_group 0
        }
        
        set idx [$text index end-2c]
        if { [lindex $line 0] in $lineNList } {
            $text tag add sel "$idx linestart" "$idx lineend+1c"
            set has_selection 1
        }
        if { [lindex $line 0] == $currentN } {
            $text mark set insert "$idx linestart"
            set has_insert 1
        }
        if { $idx_group%2 == 0 } {
            $text tag add strip "$idx linestart" "$idx lineend+1c"
        }
        incr idx_group
    }
    #mylog::debug AA7
    if { !$has_selection } {
        $text tag add sel 1.0 "1.0 lineend+1c"
    }
    if { !$has_insert } {
        $text mark set insert 1.0
    }
    $text see insert
    $text configure -state disabled
    process_todo_txt_keys -dobreak 0 Selection ""
    
    if { $currentfileIsModified && !$currentfileIsModified_save } {
        MarkAsNotModified
    }
    dict set process_todo_txt_data lines $lines
    #mylog::debug AA8
}






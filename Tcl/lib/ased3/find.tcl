#-----------------------------------------------------------------------+
#		=================
#		SEARCH PROCEDURES
#		=================
#-----------------------------------------------------------------------+

# source [file join $rootDir search.tcl]


proc grep {findStr path fileMasks args} {

    #parse args
    set subFolders 0

    set argLen [llength $args]

    for {set i 0} {$i < $argLen} {incr i} {
        set option [lindex $args $i]
        incr i

        set value [lindex $args $i]

        switch -- $option {
            "-subfolders" {
                set subFolders $value
            }
        }
    }

    if {[file tail $path] ne ""} {
        append path "/"
    }

    set pattern ""
    foreach fileMask $fileMasks {
        append pattern $path
        append pattern "$fileMask "
    }

    set result {}
    set findStrLen [string length $findStr]

    set files [eval "glob -nocomplain -- $pattern"]

    foreach file $files {
        switch -- [file type $file] {
            "file" {
                #process file
                set fileID [open $file "r"]
                set lineNum 1

                while {[gets $fileID line] != -1} {
                    set startIndex 0
                    set lineStr $line

                    while {[string first $findStr $line] != -1} {
                        set index [string first $findStr $line]

                        # set string after founded string
                        set line [string range $line [expr {$index + $findStrLen}] end]

                        #append to result
                        lappend result [list $file $lineNum [expr {$startIndex + $index}] $lineStr]

                        # set string after founded string
                        set startIndex [expr {$startIndex + $index + $findStrLen}]
                        set line [string range $line [expr {$index + $findStrLen}] end]
                    }

                    incr lineNum
                }

                close $fileID
            }

            "directory" {
                if {$subFolders} {
                    #process directory
                    set fileResult [grep $findStr $file $fileMasks $args]
                    #append into the list
                    foreach i $fileResult {
                        lappend result $l
                    }
                }
            }

            "link" {
                # nothing to do. Now, we skip links
            }
            default {}
        }
    }

    return $result
}


#-----------------------------------------------------------------------+
#		Search line no...
#-----------------------------------------------------------------------+

proc search_line_proc {w tag line} {
    if {$line eq ""} return
    $w mark set insert $line.0
    $w see insert

    global search_option_blink
    set blink $search_option_blink
    if {$blink ne "off"} {
        textHiliteLineNo $w $line $tag
    }

    focus .
    focus $w

    if {$blink eq "during"} {
        after 2000 blinkoff_search_proc $w $tag
    }
}

#-----------------------------------------------------------------------+
#		Search boxes...
#-----------------------------------------------------------------------+

proc blinkoff_search_proc {w tag} {
    $w tag remove $tag 0.0 end
}

proc search_proc {w string tag icase where match blink} {
    global search_var_string search_option_icase search_option_area search_option_match search_option_blink search_count

    $w tag remove $tag 0.0 end
    if {$string eq ""} {
        return ""
    }

    set search_var_string $string
    set cur [$w index insert]

    if {$where eq "global"} {
        set cur 1.0
        set where forwards
    }

    if {$where eq "forwards"} {
        set stopIndex end
    } elseif {$where eq "backwards"} {
        $w mark set insert "insert-1 chars"
        $w mark set insert "insert wordstart"
        set cur [$w index insert]
        set stopIndex 1.0
    }

    if {$icase == 1} {
        set icase -nocase
    } else {
        set icase -$match
    }
    set cur [$w search -count search_count $icase -$where -$match -- $string $cur $stopIndex]
    if {$cur eq ""} {
        tk_messageBox -message "\"$string\"\n[tr "not found!"]" -type ok -icon info -parent .
        return
    }
    if {$blink ne "off"} {

        $w tag add $tag $cur "$cur + $search_count char"
        $w tag configure $tag -background yellow
    }

    $w mark set insert "$cur + $search_count char"

    $w see insert

    focus $w

    if {$blink eq "during"} {
        after 2000 blinkoff_search_proc $w $tag
        return "$cur $search_count"
    }
}

proc search_default_options {} {

    global search_var_string
    set search_var_string ""

    global search_option_icase
    set search_option_icase 1

    global search_option_prompt
    set search_option_prompt 1

    global search_option_area
    set search_option_area forwards

    global search_option_match
    set search_option_match "exact"

    global search_option_blink
    set search_option_blink during

}

# on startup set options to defaults
search_default_options

#---------------------------------------------------------------------
#	search options subroutine
#---------------------------------------------------------------------

proc search_options_sub {w {replace 1}} {

    # shared common proc for drawing search options
    # used by both search & replace dialogs

    #---------------------------------------------------------------------
    #	search options
    #---------------------------------------------------------------------

    frame $w.option -relief flat
    pack $w.option -fill both -expand yes -padx 5

    frame $w.option.header -relief flat
    pack  $w.option.header -side top -fill both -expand yes

    label $w.option.header.l -text [tr "Options"]
    pack $w.option.header.l -side left -fill both -expand yes -padx 5 -pady 5

    ttk::button $w.option.header.default -text [tr "Default options"] \
        -command search_default_options
    pack $w.option.header.default -side left -padx 5 -pady 5

    #---------------------------------------------------------------------
    #	search options:mix
    #---------------------------------------------------------------------

    frame $w.option.mix -relief groove -bd 2
    pack $w.option.mix -fill both -side left -expand yes -padx 5 -pady 5

    #---------------------------------------------------------------------
    #	search options: ignore case
    #---------------------------------------------------------------------

    ttk::checkbutton $w.option.mix.case -variable search_option_icase -text [tr "ignore case"]
    pack $w.option.mix.case -anchor w -padx 5 -pady 5

    #---------------------------------------------------------------------
    #	search options: prompt/pause before replace
    #---------------------------------------------------------------------

    if {$replace} {
        ttk::checkbutton $w.option.mix.prompt -variable search_option_prompt \
            -text [tr "prompt before replace"]
        pack $w.option.mix.prompt -anchor w -padx 5 -pady 5
    }

    #---------------------------------------------------------------------
    #	search options: area
    #---------------------------------------------------------------------

    frame $w.option.direction -relief groove -bd 2
    pack $w.option.direction -fill both -side left -expand yes -padx 5 -pady 5

    label $w.option.direction.label -text [tr " Area : "]
    pack $w.option.direction.label -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.direction.forward -variable search_option_area \
        -text [tr "Forwards"] -value forwards
    pack $w.option.direction.forward -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.direction.backward -variable search_option_area \
        -text [tr "Backwards"] -value backwards
    pack $w.option.direction.backward -anchor w -padx 5

    ttk::radiobutton $w.option.direction.global -variable search_option_area \
        -text [tr "Global"] -value global
    pack $w.option.direction.global -anchor w -padx 5 -pady 5

    #---------------------------------------------------------------------
    #	search options: match
    #---------------------------------------------------------------------

    frame $w.option.match -relief groove -bd 2
    pack $w.option.match -fill both -side left -anchor nw -expand yes -padx 5 -pady 5

    label $w.option.match.label -text [tr " Match : "]
    pack $w.option.match.label -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.match.exact -variable search_option_match \
        -text [tr "exact"] -value exact
    pack $w.option.match.exact -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.match.regexp -variable search_option_match \
        -text [tr "regexp"] -value regexp
    pack $w.option.match.regexp -anchor w -padx 5 -pady 5

    #---------------------------------------------------------------------
    #	search options: blink
    #---------------------------------------------------------------------

    frame $w.option.blink -relief groove -bd 2
    pack $w.option.blink -fill both -side left -anchor nw -expand yes -padx 5 -pady 5

    label $w.option.blink.label -text [tr " Blink : "]
    pack $w.option.blink.label -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.blink.during -variable search_option_blink \
        -text [tr "during search"] -value during
    pack $w.option.blink.during -anchor w -padx 5 -pady 5

    ttk::radiobutton $w.option.blink.off -variable search_option_blink \
        -text [tr "off"] -value off
    pack $w.option.blink.off -anchor w -padx 5

    ttk::radiobutton $w.option.blink.always -variable search_option_blink \
        -text [tr "always"] -value always
    pack $w.option.blink.always -anchor w -padx 5 -pady 5
}

proc search_dbox {t} {
    set w .search
    catch "destroy $w"
    toplevel $w
    wm transient $w .
    wm title	 $w	[tr "Search "]
    wm iconname	 $w	[tr "Search "]

    label $w.msg -text [tr " Enter search string: "] -anchor w
    pack $w.msg -fill x -padx 10 -pady {5 0}

    ttk::entry $w.entry -textvariable search_var_string
    pack $w.entry -fill x -padx 10 -pady 5

    #---------------------------------------------------------------------
    #	call search options built-in frame
    #---------------------------------------------------------------------

    search_options_sub $w 0

    #---------------------------------------------------------------------

    frame $w.butn
    pack $w.butn -fill x

    ttk::button $w.butn.ok -text [tr "OK"] -command "
    set s \[$w.entry get\]
		# puts stdout \$s
    search_proc $t \$s search \$search_option_icase \$search_option_area \$search_option_match \$search_option_blink
    destroy $w
    " \
        -width 12 -under 0 -default active
    pack  $w.butn.ok -side left -expand 1 \
        -padx 3m -pady 2m
    ttk::button $w.butn.cancel -text [tr "Cancel"] -command "destroy $w" \
        -width 12 -under 0

    pack  $w.butn.cancel -side left -expand 1 \
        -padx 3m -pady 2m

    bind $w.entry <Key-Return> "$w.butn.ok invoke"
    bind $w.entry <Key-Escape> "$w.butn.cancel invoke"

    focus $w
    focus $w.entry

    ::tk::PlaceWindow $w pointer

    bind $t <Control-L> "repeat_last_search $t"
    bind $t <Control-l> "repeat_last_search $t"
}

proc search_files_dbox {} {
    set w .search
    catch "destroy $w"
    toplevel $w
    wm transient $w .
    wm title	 $w	[tr "Search "]
    wm iconname	 $w	[tr "Search "]

    label $w.msg -text [tr " Enter search string: "] -anchor w
    pack $w.msg -fill x -padx 10 -pady {5 0}

    ttk::entry $w.entry -textvariable search_var_string
    pack $w.entry -fill x -padx 10 -pady 5

    frame $w.butn
    pack $w.butn -fill x

    ttk::button $w.butn.ok -text [tr "OK"] -command {
        set s [.search.entry get]
        set result [grep $s [pwd] *.tcl ]
        destroy .search
        if {$result ne {}} {
            Editor::showResults $result
        } else {
            tk_messageBox -message "\"$s\" [tr "not found!"]" -title "ASED Information" -icon info -parent .
        }
    } \
        -width 12 -under 0 -pady 0 -default active
    pack  $w.butn.ok -side left -expand 1 \
        -padx 3m -pady 2m
    ttk::button $w.butn.cancel -text [tr "Cancel"] -command "destroy $w" \
        -width 12 -under 0 -pady 0

    pack  $w.butn.cancel -side left -expand 1 \
        -padx 3m -pady 2m

    bind $w.entry <Key-Return> "$w.butn.ok invoke"
    bind $w.entry <Key-Escape> "$w.butn.cancel invoke"

    focus $w
    focus $w.entry

    ::tk::PlaceWindow $w pointer
}

# bind .t <Control-L> repeat_last_search
# bind .t <Control-l> repeat_last_search

proc repeat_last_search { t} {
    global search_var_string search_option_icase search_option_area search_option_match search_option_blink

    search_proc $t $search_var_string search $search_option_icase $search_option_area $search_option_match $search_option_blink
}

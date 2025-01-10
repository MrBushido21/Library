#-----------------------------------------------------------------------+
#		Replace boxes...
#-----------------------------------------------------------------------+

proc YNC_messageBox {{message {}} {title {}}} {
    global answer

    if {$message eq {}} {
        catch {destroy .message}
        return
    }

    if {![winfo exists .message]} {
        set messageWin [toplevel .message]
	wm transient .message .
        wm title .message $title
        set messageFrame [ttk::frame .message.f1]
        set buttonFrame [ttk::frame .message.f2]
        set msg [label .message.f1.message -text $message -anchor w]
        set yb [ttk::button .message.f2.yes -width 8 -text [tr "Yes"] -command {set answer "yes"}]
        set nb [ttk::button .message.f2.no -width 8 -text [tr "No"] -command {set answer "no"}]
        set cb [ttk::button .message.f2.cancel -width 8 -text [tr "Cancel"] -command {set answer "cancel"}]
        pack $msg -expand yes -fill both -ipadx 10 -ipady 10 -padx 10 -pady {10 0}
        pack $yb $nb $cb -side left -padx 10 -pady 10 -expand yes
        pack $messageFrame $buttonFrame -fill both -expand yes
        grab $messageWin
        wm protocol .message WM_DELETE_WINDOW {
            set answer "cancel"
        }
        wm resizable .message 0 0
        focus -force .message
    }
    set answer ""
    tkwait variable answer

    if {$answer eq "cancel"} {
        catch {destroy .message}
    }
    return $answer
}


proc replace_proc {w search_string tag replace_string icase where match blink} {
    global search_count
    $w tag remove $tag 0.0 end
    if {$search_string eq ""} {
        return
    }
    set cur [$w index insert]

    if {$where eq "global"} {
        set cur 1.0
        set where forwards
    }

    if {$where eq "forwards"} {
        set stopIndex end
    } elseif {$where eq "backwards"} {
        set stopIndex 1.0
    }

    if {$icase == 1} {
        set icase -nocase
    } else {
        set icase -$match
    }

    while 1 {
        set cur [$w index insert]
        set cur [$w search -count search_count $icase -$where -$match -- $search_string $cur $stopIndex]
        if {$cur eq ""} {
            YNC_messageBox ;#This will close the messageBox
            tk_messageBox -message [tr "Searchstring"]\n>>$search_string<<\n[tr "not found!"] -parent .
            Editor::updateObjects
            break
        }
        if {$blink ne "off"} {
            $w tag add $tag $cur "$cur + $search_count char"
            $w tag configure $tag -background yellow
        }
        $w mark set insert $cur
        $w see insert
        Editor::selectObject 0
        global search_option_prompt
        if {$search_option_prompt} {
            set answer [ YNC_messageBox 	[tr " Replace this occurrence ? "] [tr " Replace  ? "]]
            $w tag delete $tag
        } else {
            set answer yes
        }
        switch -- $answer {
            "cancel" {
                Editor::updateObjects
                break
            }
            "no"	{
                set cur [$w index "$cur + $search_count char"]
                $w mark set insert $cur
                continue
            }
            "yes" {
                $w delete $cur "$cur + $search_count char"
                $w insert $cur $replace_string $tag
                update idletasks
                editorWindows::ColorizeLine [lindex [split $cur "."] 0]
                set range [editorWindows::getUpdateBoundaries $cur]
                Editor::updateOnIdle $range
            }
        }
        $w mark set insert "$cur + [string length $replace_string] char"
        $w see insert
    }

    focus .
    focus $w
    if {$blink eq "during"} {
        after 2000 blinkoff_search_proc $w $tag
    }
}

proc replace_dbox {t} {
    set w .replace
    catch "destroy $w"
    toplevel $w
    wm transient $w .
    wm title	 $w	[tr "Replace "]
    wm iconname	 $w	[tr "Replace "]

    label $w.search_msg -text [tr " Search for string: "] -anchor w
    pack $w.search_msg -fill x -padx 10 -pady {5 0}

    ttk::entry $w.search_entry -textvariable search_var_string
    pack $w.search_entry -fill x -padx 10 -pady 5

    label $w.replace_msg -text [tr " Replace with string: "] -anchor w
    pack $w.replace_msg -fill x -padx 10 -pady {5 0}

    ttk::entry $w.replace_entry -textvariable replace_var_string
    pack $w.replace_entry -fill x -padx 10 -pady 5

    search_options_sub $w

    frame $w.butn
    pack $w.butn -fill x

    ttk::button $w.butn.ok -text [tr "OK"] -command "
    set s \[$w.search_entry  get\]
    set r \[$w.replace_entry get\]
		# puts stdout \$s
    destroy $w
    replace_proc $t \$s search \$r \$search_option_icase \$search_option_area \$search_option_match \$search_option_blink
    " \
        -width 12 -under 0 -default active

    pack  $w.butn.ok -side left -expand 1 \
        -padx 3m -pady 2m

    ttk::button $w.butn.cancel -text [tr Cancel] -command "destroy $w" \
        -width 12 -under 0

    pack  $w.butn.cancel -side left -expand 1 \
        -padx 3m -pady 2m

    bind $w.search_entry <Key-Return> [list focus $w.replace_entry]
    bind $w.search_entry <Key-Escape> [list $w.butn.cancel invoke]

    bind $w.replace_entry <Key-Return> [list $w.butn.ok invoke]
    bind $w.replace_entry <Key-Escape> [$w.butn.cancel invoke]

    ::tk::PlaceWindow $w pointer

    focus $w
    focus $w.search_entry
}

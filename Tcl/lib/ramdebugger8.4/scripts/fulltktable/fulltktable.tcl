

package require Tktable
package require snit
#package require tile
package require autoscroll
#package require BWidget
package require msgcat
#package require dialogwin
# és necessari??
package require customLib_utils

package provide fulltktable 1.1

namespace eval fulltktable {
	variable topdir [file normalize [file dirname [info script]]]
}

# lognoter, for instance, uses it's own interpreter...
if { [ tk windowingsystem] eq "aqua"} {
    set ::acceleratorKey Command
    set ::acceleratorText Command
} else {
    set ::acceleratorKey Control
    set ::acceleratorText Ctrl
}

snit::widget fulltktable::table {
    option -varname                 ;# variable that holds the table values as a sparse matrix
    option -entryvarname            ;# variable that holds the value of the field being edited
    option -formulae 0              ;# chooses wheather to have formulae (=2 includes an entry widget)
    option -formulaevarname ""      ;# variable to hold formulae
    option -modifycmd               ;# commands gets called after a modification in the table 
		                    ;# is made; additional arguments for cmd: idx oldvalue
    option -beforemodifycmd         ;# called before leaving edition of a field. If cmd returns
		                    ;# different than 0, it is not left (arg: idx entry)
    option -contextualmenu ""       ;# gets called when user press button-3 on a cell
		                    ;# the selection is not modified (arg: cmd commands)
    option -scrolling ""            ;# selects to have scrolling on both, vertical or horizontal
		                    ;# positions (arg:  both|v|h)
    option -disablecolumns ""       ;# A list of 0 or 1 ; if it is 1, column cannot be edited 
		                    ;# a unique 'all' disable all table (arg:  0|1 0|1 ...)
		                    ;# to obtain just a warning, use number 2 and 'allwarn'
    option -disablecells ""         ;# A list of cell indexes that cannnot be edited 

    option -createline 0            ;# if set, a line at the end of the table will be created if 
		                    ;# users go there (arg: 0|1)
    option -editwithcombo           ;# If set, edition is made with a combobox. fillcommand is  
		                    ;# called just before opening combo with args: combo row and
		                    ;# col; (arg: fillcommand 0|1...)
		                    ;# 1 means editable 0 means no editable; -1 means no combo 
		                    ;# for every column in list (arg:  fillcommand -1|0|1...)
    option -editwithtext            ;# If set, edition is made with a text. 
		                    ;# 1 means edit with text; 0 means no text
		                    ;# for every column in list ; a unique 'all', activates all
		                    ;# (arg: 0|1...)
    option -tooltips ""             ;# a command that returns a text (arg: cmd)
    option -titlerows 

    variable table
    variable myentry ""
    variable mytext ""
    
    variable MaxIdxWithFormula
    variable SelectionNums ""
    variable SelectionFormulae ""
    variable SelectionCell
    variable lastmovedcell ""
    variable clipboard_data
    
    variable default_var
    variable default_entryvar
    variable default_formulaevar

    variable tooltip_current_idx ""
    variable tooltip_current_afterid

    typevariable ismcload 0
    typemethod mcload {} {
	if { $ismcload } { return }
	::msgcat::mcload [file join $::fulltktable::topdir msgs]
	set ismcload 1
    }
    
    if { [info commands ::_] eq "" } {
	proc ::_ { args } {
	    set ret [uplevel 1 ::msgcat::mc $args]
	    regexp {(.*)#C#(.*)} $ret {} ret
	    return $ret
	}
    }

    delegate method * to table
    delegate option * to table

    constructor {args} {
	fulltktable::table mcload

	$hull configure -bd 0

	install table as ::table $win.t -rows 30 -cols 10 \
	    -width 0 -height 31 \
	    -titlerows 1 -titlecols 1 \
	    -roworigin 0 -colorigin 0 \
	    -colstretchmode unset -rowstretchmode none \
	    -selectmode extended -sparsearray 0 -colwidth 15 -rowheight 1\
	    -resizeborders both -bg white -padx 3 \
	    -rowseparator \n -colseparator \t \
	    -drawmode fast -highlightthickness 0 -anchor w -exportselection 0 \
	    -bordercursor sb_h_double_arrow -wrap 1 -anchor nw \
	    -xscrollcommand [list $win.sh set] \
	    -yscrollcommand [list $win.sv set]

	install vscrollbar as ttk::scrollbar $win.sv -orient vertical -command [list $win.t yview]	
	install hscrollbar as ttk::scrollbar $win.sh -orient horizontal -command [list $win.t xview]

	autoscroll::autoscroll $win.sh
	autoscroll::autoscroll $win.sv

	#$table conf -drawmode compatible -relief raised -bd 1 -highlightthickness 0

	set myentry $table.entry
	set mytext $table.entry.text

	set MaxIdxWithFormula 0,0
	$table width 0 3
	$table tag conf active -bg white -fg black -relief sunken
	$table tag conf sel -bg grey
	$table tag conf title -anchor center  -bd 2 -relief raised
	$table conf -state disabled
	#$table tag conf inactive -state disabled

	$self initbindings

	grid $win.t $win.sv -sticky ns
	grid $win.sh -sticky ew
	grid configure $win.t -sticky nsew
	grid columnconfigure $win 0 -weight 1
	grid rowconfigure $win 0 -weight 1

	if { ![info exists $options(-varname)] } {
	    set options(-varname) [varname default_var]
	    $table configure -variable [varname default_var]
	}
	if { ![info exists $options(-entryvarname)] } {
	    set options(-entryvarname) [varname default_entryvar]
	}
	$self configurelist $args
    }
    onconfigure -scrolling {value} {
	set options(-scrolling) $value
	
	switch $options(-scrolling) {
	    "" - none {
		autoscroll::unautoscroll $win.sh
		autoscroll::unautoscroll $win.sv
	    }
	    h {
		autoscroll::autoscroll $win.sh
		autoscroll::unautoscroll $win.sv
	    }
	    v {
		autoscroll::unautoscroll $win.sh
		autoscroll::autoscroll $win.sv
	    }
	    both {
		autoscroll::autoscroll $win.sh
		autoscroll::autoscroll $win.sv
	    }
	}
    }
    onconfigure -varname {value} {
	set options(-varname) $value
	if { ![info exists table] } { return }
	$table configure -variable $value
    }
    onconfigure -titlerows {value} {
	if { ![info exists table] } { return }
	$table configure -titlerows $value
	if { $value == 0 } { $table width 0 default }
    }
    onconfigure -formulae {value} {
	set options(-formulae) $value

	if { $value } {
	    if { $options(-formulaevarname) eq "" } {
		set options(-formulaevarname) [varname default_formulaevar]
	    }
	}
	if { $value == 2 } {
	    if { ![winfo exists $win.fentry] } {
		entry $win.fentry -textvariable $options(-entryvarname) \
		    -state disabled
		$win.fentry configure -disabledbackground [$win.fentry cget \
		        -background] -disabledforeground grey60
		grid $win.fentry -row 0 -column 0 -sticky nwe -pady "0 3"
		bind $win.fentry <Return> [mymethod _movecell 1 0 {} 1]
	    }
	} elseif { [winfo exists $win.fentry] } {
	    destroy $win.fentry
	}
    }
    onconfigure -disablecells {value} {
	set options(-disablecells) [lsort $value]
    }
    method bind { args } {
	return [eval bind [list $table] $args]
    }
    method clearall {} {

	array unset $options(-varname)
	if { [info exists options(-formulaevarname)] } {
	    array unset $options(-formulaevarname)
	}
	set MaxIdxWithFormula 0,0
    }
    method havecontents {} {

	foreach i [array names $options(-varname)] {
	    if { [string match 0,* $i] } { continue }
	    if { [string match *,0 $i] } { continue }
	    if { [set $options(-varname)($i)] ne "" } {
		return 1
	    }
	}
	if { $options(-formulaevarname) ne "" } {
	    foreach i [array names $options(-formulaevarname)] {
		if { [set $options(-formulaevarname)($i)] ne "" } {
		    return 1
		}
	    }
	}
	return 0
    }
    method givecontents { retvarname } {
	upvar $retvarname retvar
	
	set retvar ""
	foreach i [array names $options(-varname)] {
	    if { [string match 0,* $i] } { continue }
	    if { [string match *,0 $i] } { continue }
	    if { [set $options(-varname)($i)] ne "" } {
		lappend retvar $i [set $options(-varname)($i)]
	    }
	}
	if { $options(-formulaevarname) ne "" } {
	    lappend retvar formulaevarname ""
	    foreach i [array names $options(-formulaevarname)] {
		if { [set $options(-formulaevarname)($i)] ne "" } {
		    lappend retvar $i [set $options(-formulaevarname)($i)]
		}
	    }
	}
	lappend retvar MaxIdxWithFormula $MaxIdxWithFormula
    }

    method givefullcontents { } {        
	set retvar ""
	set indexes [array names $options(-varname)]
	set nrows 0
	set ncols 0
	set i -1
	set j -1
	foreach idx $indexes {
	    regexp {(.*),(.*)} $idx -> i j
	    if { $i > $nrows } {
		set nrows $i
	    }
	    if { $j > $ncols } {
		set ncols $j
	    }
	}
	for { set i 0 } { $i <= $nrows } { incr i } {
	    for { set j 0 } { $j <= $ncols } { incr j } {
		set optname $options(-varname)($i,$j)
		if { [info exists $optname] } {
		    lappend retvar $i,$j [set $optname]
		} else {
		    lappend retvar $i,$j ""
		}
	    }
	}
	return $retvar
    }
	
    method setcontents { contents } {

	$self clearall

	set enterf 0
	foreach "idx val" $contents {
	    if { $idx == "MaxIdxWithFormula" } {
		set MaxIdxWithFormula $val
	    }
	    if { $idx == "formulaevarname" } {
		set enterf 1
		continue
	    }
	    if { !$enterf } {
		set $options(-varname)($idx) $val
	    } else {
		set $options(-formulaevarname) $val
	    }
	}
    }

    method _enterfocus {} {
	if { [winfo exists $mytext] } {
	    focus $mytext
	} elseif { [winfo exists $myentry] } {
	    focus $myentry
	} elseif { [$table curselection] == "" } {
	    $table selection set [$table cget -titlerows],[$table cget -titlecols]
	    $self _setasactive [$table cget -titlerows],[$table cget -titlecols]
	}
    }
    method _buttonrelease1 { x y } {
	if { $::tk::table::Priv(mousetype) == "resize" } { return }
	if { $::tk::table::Priv(mousetype) == "" } { return }
	if { $::tk::table::Priv(mousetype) == "Double-1" } { return }
	if {[winfo exists $table]} {
	    ::tk::table::CancelRepeat
	    
	    if { !$::tk::table::Priv(mouseMoved) } {
		#focus $table
		if { $::tk::table::Priv(mousetype) == "1" } {
		    $table selection clear all
		}
		#$table activate @$x,$y
		if { $::tk::table::Priv(mousetype) == "Shift-1" && [$table curselection] != "" } {
		    $table selection set [lindex [$table curselection] 0] @$x,$y
		    focus $table
		} else {
		    $table selection set @$x,$y
		    if { ![$self _setasactive @$x,$y] } {
		        focus $table
		    }
		}
	    } else {
		if { ![$self _setasactive [$table index anchor]] } {
		    focus $table
		}
	    }
	}
    }
    method _doublebutton1 { x y } {
	set ::tk::table::Priv(mousetype) Double-1
	if { [catch { [$table index active] } active] } { set active "" }
	$self _browse $active [$table index @$x,$y]
	#%W activate @%x,%y
    }
    method _buttonrelease3 { x y X Y } {
	if { $::tk::table::Priv(borderresize) == "" && $options(-contextualmenu) != "" } {
	    if { ![$table selection includes @$x,$y] } {
		$table selection clear all
		$table selection set @$x,$y
	    }
	    uplevel #0 $options(-contextualmenu) $self [$table index @$x,$y] $X $Y
	}
    }
    method _keypress { A K } {

	if { $K eq "F2" } {
	    if { [llength [$table tag cell sel]] != 0 } {
		if { [catch { [$table index active] } active] } { set active "" }
		$self _browse $active [lindex [$table tag cell sel] 0]
	    }
	}
	if { ![string equal $A  ""] && [llength [$table tag cell sel]] != 0 } {
	    if { [catch { [$table index active] } active] } { set active "" }
	    $self _browse $active [lindex [$table tag cell sel] 0] $A
	}
    }
    method initbindings {} {

	################################################################################
	# general bindings
	################################################################################
	
	bind $win <FocusIn> [list focus $table]
	bind $table <FocusIn> "[mymethod _enterfocus] ; break"
	bind $table <FocusOut> [mymethod browseclear]
	$table configure -browsecmd [mymethod browse %s %S]


	################################################################################
	# mouse bindings
	################################################################################

	bind $table <1> {
	    # [%W tag includes title [%W index @%x,%y]]
	    
	    if {[winfo exists %W] &&  [%W border mark %x %y col] != "" && \
		    ([%W index @%x,%y row] == 0 || [%W index @%x,%y col] == 0) } {
		set idx [%W border mark %x %y]
		set ::tk::table::Priv(borderresize) $idx
		set ::tk::table::Priv(mousetype) resize
		break
	    }
	    %W selection anchor @%x,%y
	    if {[winfo exists %W] && [%W tag includes title [%W index @%x,%y]]} {
		::tk::table::fullBeginSelect %W [%W index @%x,%y]
		#focus %W
		set ::tk::table::Priv(mouseMoved) 1
	    } else { set ::tk::table::Priv(mouseMoved) 0 }
	    array set ::tk::table::Priv {x %x y %y}
	    set ::tk::table::Priv(mousetype) 1
	    break
	}
	bind $table <B1-Motion> {
	    if { $::tk::table::Priv(mousetype) == "resize" } {
		%W border dragto %x %y ; break
	    }

	    if { !$::tk::table::Priv(mouseMoved) && \
		     (abs(%x-$::tk::table::Priv(x)) > 1 \
		          || abs(%y-$::tk::table::Priv(y)) > 1) } {
		if {[winfo exists %W]} {
		    ::tk::table::fullBeginSelect %W [%W index @%x,%y]
		    #focus %W
		}
	    }
	    
	    # If we already had motion, or we moved more than 1 pixel,
	    # then we start the Motion routine
	    if {
		$::tk::table::Priv(mouseMoved)
		|| abs(%x-$::tk::table::Priv(x)) > 1
		|| abs(%y-$::tk::table::Priv(y)) > 1
	    } {
		
		set ::tk::table::Priv(mouseMoved) 1
	    }
	    if {$::tk::table::Priv(mouseMoved)} {
		::tk::table::Motion %W [%W index @%x,%y]
	    }
	    break
	}
	set ::tk::table::Priv(mousetype) ""
	bind $table <ButtonRelease-1> "[mymethod _buttonrelease1 %x %y] ; break"
	bind $table <Shift-1>        {
	    %W selection anchor @%x,%y
	    if {[winfo exists %W] && [%W tag includes title [%W index @%x,%y]]} {
		::tk::table::fullBeginSelect %W [%W index @%x,%y]
		#focus %W
		set ::tk::table::Priv(mouseMoved) 1
	    } else { set ::tk::table::Priv(mouseMoved) 0 }
	    array set ::tk::table::Priv {x %x y %y}
	    set ::tk::table::Priv(mousetype) Shift-1
	    break
	}
	bind $table <${::acceleratorKey}-1>        {
	    if { [%W tag includes sel [%W index @%x,%y]] } {
		%W sel clear [%W index @%x,%y]
		set ::tk::table::Priv(mousetype) ""
		break
	    }
	    %W selection anchor @%x,%y
	    if {[winfo exists %W] && [%W tag includes title [%W index @%x,%y]]} {
		::tk::table::fullBeginSelect %W [%W index @%x,%y]
		#focus %W
		set ::tk::table::Priv(mouseMoved) 1
	    } else { set ::tk::table::Priv(mouseMoved) 0 }
	    array set ::tk::table::Priv {x %x y %y}
	    set ::tk::table::Priv(mousetype) Control-1
	    break
	}
	bind $table <Double-1> "[mymethod _doublebutton1 %x %y] ; break"
	bind $table <3> {
	    set idx [%W border mark %x %y]
	    set ::tk::table::Priv(borderresize) $idx
	    break
	}
	bind $table <B3-Motion>        { %W border dragto %x %y ; break }
	bind $table <ButtonRelease-3> "[mymethod _buttonrelease3 %x %y %X %Y] ; break"

	bind $table <Motion> [mymethod table_motion %x %y]

	################################################################################
	# Mouse wheel for UNIX
	################################################################################

	if {[string equal "unix" $::tcl_platform(platform)]} {
	    bind $table <4> {
		%W yview scroll -5 units
	    }
	    bind $table <5> {
		%W yview scroll 5 units
	    }
	}

	################################################################################
	# Mouse wheel for Windows
	################################################################################

	bind $table <MouseWheel> {
	    %W yview scroll [expr {- (%D / 120) * 4}] units
	}

	################################################################################
	# keyboard bindings
	################################################################################

	bind $table <KeyPress> "[mymethod _keypress %A %K]; break"
	bind $table <Alt-KeyPress> {
	    # nothing
	}
	bind $table <Meta-KeyPress>        {
	    # nothing
	}
	bind $table <${::acceleratorKey}-KeyPress>        {
	    # nothing
	}
	bind $table <${::acceleratorKey}-KeyPress><${::acceleratorKey}-KeyPress>  {
	    # nothing
	}
	bind $table <${::acceleratorKey}-Shift-KeyPress>        {
	    # nothing
	}
	bind $table <${::acceleratorKey}-equal>        {
	    # nothing
	}
	bind $table <${::acceleratorKey}-minus>        {
	    # nothing
	}


	bind $table <${::acceleratorKey}-c> "[mymethod cutcopypaste copy] ; break"
	bind $table <${::acceleratorKey}-x> "[mymethod cutcopypaste cut] ; break"
	bind $table <${::acceleratorKey}-v> "[mymethod cutcopypaste paste] ; break"

	bind $table <Return>        "[mymethod _movecell 1 0] ; break"
	bind $table <Any-Tab> "[mymethod _movecell 0 1] ; break"
	bind $table <Shift-Return> "[mymethod _movecell -1 0 ]; break"
	bind $table <Shift-Any-Tab> "[mymethod _movecell 0 -1 ]; break"
	bind $table <<PrevWindow>> "[mymethod _movecell 0 -1 ]; break"
	bind $table <Left> "[mymethod _movecell 0 -1] ; break"
	bind $table <Right>  "[mymethod _movecell 0 1 ]; break"
	bind $table <Up> "[mymethod _movecell -1 0] ; break"
	bind $table <Down> "[mymethod _movecell 1 0 ]; break"
	bind $table <Delete>    "[mymethod delete]; break"
	bind $table <Escape> { break }
	bind Table <Prior>                {
	    %W yview scroll -1 pages; #%W activate @0,0
	}
	bind Table <Next>                {
	    %W yview scroll  1 pages; #%W activate @0,0
	}
	bind Table <Home>                "[mymethod _movecell 0 first]; break"
	bind Table <End>                "[mymethod _movecell 0 last]; break"

	################################################################################
	# keyboard shift bindings
	################################################################################

	bind $table <Shift-Left> "[mymethod _movecell 0 -1 yes]; break"
	bind $table <Shift-Right>  "[mymethod _movecell 0 1 yes]; break"
	bind $table <Shift-Up> "[mymethod _movecell -1 0 yes]; break"
	bind $table <Shift-Down> "[mymethod _movecell 1 0 yes]; break"

	################################################################################
	# keyboard control bindings
	################################################################################

	bind $table <Control-Prior>        {%W xview scroll -1 pages}
	bind $table <Control-Next>        {%W xview scroll  1 pages}
	bind $table <Control-Home>        "[mymethod _movecell first first]; break"
	bind $table <Control-End>        "[mymethod _movecell last 0]; break"

	################################################################################
	# keyboard shift-control bindings
	################################################################################

	bind $table <Shift-Control-Home>        "[mymethod _movecell first first yes]; break"
	bind $table <Shift-Control-End>        "[mymethod _movecell last last yes]; break"

    }
    method _check_tooltips_destroy { w x y X Y { force "" } } {
	if { $force ne "" || abs($x-$X) > 3 || abs($y-$Y) > 3 } {
	    destroy $w
	}
    }
    method _check_tooltips_do { txt } {

	catch { destroy $w }
	set w [toplevel $win._tooltips]
	wm overrideredirect $w 1
	pack [label $w.l -text $txt -bg white -fg black -bd 1 -relief ridge -padx 2]
	set x [winfo pointerx $win]
	set y [winfo pointery $win]
	set ypos [expr {$y-int(1.6*[winfo reqheight $w.l])}]
	wm geometry $w +$x+$ypos
	bind $w <1> [mymethod _check_tooltips_destroy $w $x $y - - force]
	bind $w <KeyPress> [mymethod _check_tooltips_destroy $w $x $y - - force]
	bind $w <Motion> [mymethod _check_tooltips_destroy $w $x $y %X %Y]
	#focus $w
	grab $w

    }
    method check_tooltips { idx } {
	if { $options(-tooltips) eq "" } { return }
	if { $tooltip_current_idx ne "" } {
	    if { $tooltip_current_idx != $idx } {
		after cancel $tooltip_current_afterid
		set tooltip_current_idx ""
	    } else { return }
	}
	set txt [uplevel \#0 $options(-tooltips) $idx]
	if { $txt eq "" } { return }
	set tooltip_current_idx $idx
	set tooltip_current_afterid [after 1000 [mymethod _check_tooltips_do $txt]]
    }
    method table_motion { x y } {
	foreach "row col" [list "" ""] break
	foreach "row col" [$table border mark $x $y] break
	scan [$table index @$x,$y] "%d,%d" r c
	if { $r != 0 && $c != 0 } { foreach "row col" [list "" ""] break }
	if { $row ne "" && $col ne "" } {
	    $table configure -bordercursor crosshair
	    $table configure -cursor crosshair
	} elseif { $row ne "" } {
	    $table configure -bordercursor sb_v_double_arrow
	    $table configure -cursor sb_v_double_arrow
	} elseif { $col ne "" } {
	    $table configure -bordercursor sb_h_double_arrow
	    $table configure -cursor sb_h_double_arrow
	} else {
	    $table configure -cursor xterm
	    $table configure -cursor xterm
	    $self check_tooltips [$table index @$x,$y]
	}
    }

    method delete {} {
	if { $options(-disablecolumns) != "" } {
	    if { $options(-disablecolumns) == "allwarn" } {
		set text [_ "Table is disabled and should no be modified. Proceed?"]
		set retval [tk_messageBox -default cancel -icon warning -message \
		                $text -parent $table -type okcancel]
		if { $retval == "cancel" } {
		    return
		}
	    } elseif { $options(-disablecolumns) == "all" } {
		return
	    } else {
		foreach idx [$table curselection] {
		    set col [$self givecol $idx]
		    if { [lindex $options(-disablecolumns) $col] == 2 } {
		        set text [_ "Column is disabled and should no be modified. Proceed?"]
		        set retval [tk_messageBox -default cancel -icon warning -message \
		                        $text -parent $table -type okcancel]
		        if { $retval == "cancel" } {
		            return
		        } else { break }
		    } elseif { [lindex $options(-disablecolumns) $col] == 1 } {
		        return
		    }
		}
	    }
	}
	if { $options(-disablecells) ne "" } {
	    foreach idx [$table curselection] {
		if { [lsearch -sorted $options(-disablecells) $idx] != -1 } {
		    return
		}
	    }
	}
	$table conf -state normal
	if { [$table icursor] != -1 } {
	    $table delete active insert
	} else {
	    if { $options(-formulaevarname) != "" } {
		set varname $options(-formulaevarname)
		foreach idx [$table curselection] {
		    if { [info exists ${varname}($idx)] } {
		        unset ${varname}($idx)
		    }
		}
	    }
	    set active [lindex [$table curselection] 0]
	    # sets selected items to void
	    $table curselection ""
	    if { $options(-formulaevarname) != "" } { $self recomputetable }
	}
	$table conf -state disabled
	if { [info exists active] } {
	    $self _setasactive $active
	}
    }
    method _storecopyformulae {} {
	if { $options(-formulaevarname) != "" } {
	    set SelectionCell [lindex [$table curselection] 0]
	    set SelectionNums [$self _getselection]
	    set SelectionFormulae ""
	    set varname $options(-formulaevarname)
	    set rsep [$table cget -rowseparator]
	    set csep [$table cget -colseparator]
	    set lastrow ""
	    foreach idx [$table curselection] {
		if { [info exists ${varname}($idx)] } {
		    set val [set ${varname}($idx)]
		} else {
		    set val [$table get $idx]
		}
		set row [$self giverow $idx]
		if { $lastrow == "" } {
		    append SelectionFormulae $val
		} elseif { $row == $lastrow } {
		    append SelectionFormulae $csep$val
		} else {
		    append SelectionFormulae $rsep$val
		}
		set lastrow $row
	    }
	    #set SelectionNums [::tk::table::GetSelection $table]
	    set SelectionNums [$self _getselection]
	} else {
	    set SelectionFormulae ""
	    set SelectionNums ""
	}
    }
    method _retrievecopyformulae {} {

	if { $::tcl_platform(platform) == "windows" } {
	    set data [::tk::table::GetSelection $table CLIPBOARD]
	} else {
	    set data [::tk::table::GetSelection $table PRIMARY]
	}
	
	if { $options(-formulaevarname) != "" } {
	    if { $data == $SelectionNums } {
		return $SelectionFormulae
	    } else {
		return $data
	    }
	} else {
	    return $data
	}
    }
    method _sval2rowcol { sval } {

	set sval [string toupper $sval]
	regexp {([A-Z]+)([0-9]+)} $sval {} letters row

	scan A %c letmin
	scan Z %c letmax
	set col 0
	set factor 1
	for { set j [expr [string length $letters]-1] } { $j >= 0 } { incr j -1 } {
	    scan [string index $letters $j] %c letter
	    incr col [expr ($letter-$letmin+1)*$factor]
	    set factor [expr $factor*($letmax-$letmin+1)]
	}
	if { ![$table cget -titlerows] } { incr row -1 }
	if { ![$table cget -titlecols] } { incr col -1 }

	return $row,$col
    }
    method _rowcol2sval { idx } {

	regexp {([0-9]+),([0-9]+)} $idx {} row col

	if { ![$table cget -titlerows] } { incr row }
	if { ![$table cget -titlecols] } { incr col }

	scan A %c letmin
	scan Z %c letmax
	set fac [expr $letmax-$letmin+1]
	set letters ""
	while { $col > 0 } {
	    set letpos [expr $letmin+($col-1)%$fac]
	    set letters [format %c $letpos]$letters
	    set col [expr ($col-1)/$fac]
	}
	return $letters$row
    }

    method _updateref { ref increr increc } {

	set idx [$self _sval2rowcol $ref]
	regexp {([0-9]+),([0-9]+)} $idx {} row col
	incr row $increr
	incr col $increc
	return [$self _rowcol2sval $row,$col]
    }

    method _actualizerefs { item oldidx idx } {

	regexp {([0-9]+),([0-9]+)} $oldidx {} oldrow oldcol
	regexp {([0-9]+),([0-9]+)} $idx {} row col

	set increr [expr $row-$oldrow]
	set increc [expr $col-$oldcol]

	set regsub1 {([a-zA-Z]+)([0-9]+)(?![()0-9])}
	append regsub2 "\[[mymethod _updateref] " {\1\2}  " $increr $increc\]"
	regsub -all $regsub1 $item $regsub2 item
	return [subst -nobackslashes -novariables $item]
    }
    method _pastecell { row col item cell } {

	if { $options(-formulaevarname) != "" } {
	    set varname $options(-formulaevarname)
	    if { [string match =* $item] } {
		set item [$self _actualizerefs $item $SelectionCell $cell]
		set ${varname}($row,$col) $item
	    } else {
		catch { unset ${varname}($row,$col) }
		$table set $row,$col $item
	    }
	    regexp {([0-9]+),([0-9]+)} $MaxIdxWithFormula {} maxrow maxcol
	    if { $row > $maxrow } { set maxrow $row }
	    if { $col > $maxcol } { set maxcol $col }
	    set MaxIdxWithFormula $maxrow,$maxcol
	} else {
	    $table set $row,$col $item
	}
    }

    method _getselection {} {

	set csep [$table cget -colseparator]
	set rsep [$table cget -rowseparator]
	set retval ""
	set currow ""
	foreach i [$table curselection] {
	    set data [$table get $i]
	    if { [string first $csep $data] != -1 || \
		     [string first $rsep $data] != -1 } {
		set data "\"$data\""
	    }
	    if { $currow == "" } {
		append retval $data
	    } elseif { [$table index $i row] == $currow } {
		append retval $csep$data
	    } else { append retval $rsep$data }
	    set currow [$table index $i row]
	}
	return $retval
    }
    method _setexternalselection { data } {
	if { $::tcl_platform(platform) == "windows" } {
	    clipboard clear -displayof $table
	    clipboard append -displayof $table $data
	} else {
	    set clipboard_data $data
	    selection own $table
	    selection handle $table [mymethod _returnxselection]
	}
    }
    method _returnxselection { offset maxChars } {
	return [string range $clipboard_data $offset [expr $offset+$maxChars]]
    }

    method cutcopypaste { what } {

	switch $what {
	    copy {
		$self _storecopyformulae
		$self _setexternalselection [$self _getselection]
	    }
	    copyformulae {
		$self _storecopyformulae
		$self _setexternalselection $SelectionFormulae
	    }
	    cut {
		$table configure -state normal
		$self _storecopyformulae
		$self _setexternalselection [$self _getselection]
		$table configure -state disabled
		$self delete
	    }
	    paste {
		if {[catch {$self _retrievecopyformulae} data]} {
		    return
		}
		set cell [lindex [$table curselection] 0]
		$table conf -state normal

		set rows        [expr {[$table cget -rows]-[$table cget -roworigin]}]
		set cols        [expr {[$table cget -cols]-[$table cget -colorigin]}]
		set r        [$table index $cell row]
		set c        [$table index $cell col]
		set rsep        [$table cget -rowseparator]
		set csep        [$table cget -colseparator]
		## Assume separate rows are split by row separator if specified
		## If you were to want multi-character row separators, you would need:
		# regsub -all $rsep $data <newline> data
		# set data [join $data <newline>]
		set disabledwarning 0
		set forcepaste 0

		if {[string comp {} $rsep]} { set data [split $data $rsep] }
		set row        $r
		foreach line $data {
		    if {$row >= $rows} {
		        if { $options(-createline) } {
		            $table conf -rows [expr [$table cget -rows]+1]
		            if { [$table cget -titlecols] != 0 } {
		                $table set $row,0 [expr [$table get [expr $row-1],0]+1]
		            }
		            #ConfigureFrame $table
		            $table see $row,0
		        } else {
		            $table conf -state disabled
		            if { $options(-formulaevarname) != "" } { $self recomputetable }
		            return
		        }
		        set rows [expr {[$table cget -rows]-[$table cget -roworigin]}]
		    }
		    set col        $c
		    ## Assume separate cols are split by col separator if specified
		    ## Unless a -separator was specified
		    if {[string comp {} $csep]} { set line [split $line $csep] }
		    ## If you were to want multi-character col separators, you would need:
		    # regsub -all $csep $line <newline> line
		    # set line [join $line <newline>]
		    foreach item $line {
		        if {$col > $cols} { break }

		        set canpaste 1
		        if { $options(-disablecells) ne "" } {
		            if { [lsearch -sorted $options(-disablecells) $row,$col] != -1 } {
		                set canpaste 0
		                set disabledwarning 1
		            }
		        }
		        if { !$forcepaste && $options(-disablecolumns) != "" } {
		            if { $options(-disablecolumns) == "allwarn" } {
		                set text [_ "Table is disabled and should no be pasted. Proceed?"]
		                set retval [tk_messageBox -default cancel -icon warning -message \
		                                $text -parent $table -type okcancel]
		                if { $retval == "cancel" } {
		                    set forcepaste -1
		                }
		            } elseif { $options(-disablecolumns) == "all" } {
		                set canpaste 0
		                set disabledwarning 1
		            } elseif { [lindex $options(-disablecolumns) $col] == 2 } {
		                set text [_ "Column is disabled and should no be pasted. Proceed?"]
		                set retval [tk_messageBox -default cancel -icon warning -message \
		                                $text -parent $table -type okcancel]
		                if { $retval == "cancel" } {
		                    set forcepaste -1
		                }
		            } elseif { [lindex $options(-disablecolumns) $col] == 1 } {
		                set canpaste 0
		                set disabledwarning 1
		            }
		        }

		        if { $canpaste && $forcepaste != -1 } {
		            $self _pastecell $row $col $item $cell
		        }
		        incr col
		    }
		    incr row
		}
		$table conf -state disabled
		if { $options(-formulaevarname) != "" } { $self recomputetable }
		if { $disabledwarning } {
		    WarnWin [_ "Some cells could not be pasted because they are disabled"] $table
		}
	    }
	}
    }

    # it does NOT perform the selection
    method _setasactive { idx } {
	set idx [$table index $idx]

	if { [$self browseclear] } { return -1 }

	if { $options(-entryvarname) != "" } {
	    if { $options(-formulaevarname) != "" } {
		set varname $options(-formulaevarname)
		regexp {([0-9]+),([0-9]+)} $idx {} row col
		if { [info exists ${varname}($row,$col)] } {
		    set $options(-entryvarname) [set ${varname}($row,$col)]
		} else {
		    set $options(-entryvarname) [$table get $idx]
		}
	    } else {
		set $options(-entryvarname) [$table get $idx]
	    }
	}
	return 0
    }
    method _movecell { incrrow incrcol { extendsel "" } {forceout 0 } } {

	set found 0
	foreach oldidx [$table window names] {
	    if { [string equal [$table window cget $oldidx -window] $myentry] } {
		set found 1
		break
	    }
	}
	if { !$found } { set oldidx "" }

	if { $oldidx == "" } {
	    if { [$table curselection] != "" } {
		if { [lsearch [$table curselection] $lastmovedcell] != -1 } {
		    set oldidx $lastmovedcell
		} else {
		    set oldidx [lindex [$table curselection] 0]
		}
	    } else { set oldidx "" }
	}

	if { $oldidx == "" } { return }

	if { [$self _browseout $oldidx $forceout] } { return }
	
	set idx [$self _incridx $oldidx $incrrow $incrcol]

	if { [$table tag includes title $idx]} {
	    return
	}
	set row [$self giverow $idx]
	if { $row == [$table cget -rows] } {
	    if { $options(-createline) } {
		$table conf -rows [expr [$table cget -rows]+1]
		if { [$table cget -titlecols] != 0 } {
		    $table conf -state normal
		    $table set $row,0 [expr [$table get [expr $row-1],0]+1]
		    $table conf -state disabled
		}
		#ConfigureFrame $table
		$table see $row,0
	    } else {
		set idx $oldidx
	    }
	}
	if { $extendsel == "" } {
	    $table selection clear all
	    $table selection set $idx
	} else {
	    foreach "minrow mincol maxrow maxcol" [$self _giveselectionbox] break
	    if { $minrow == "" } {
		$table selection set $idx
	    } else {
		regexp {([0-9]+),([0-9]+)} $idx {} row col
		regexp {([0-9]+),([0-9]+)} $oldidx {} oldrow oldcol
		if { $row < $minrow } {
		    set minrow $row
		} elseif { $row > $maxrow } {
		    set maxrow $row
		} else {
		    if { $row < $oldrow } {
		        set maxrow $row
		    } elseif { $row > $oldrow } {
		        set minrow $row
		    }
		}
		if { $col < $mincol } {
		    set mincol $col
		} elseif { $col > $maxcol } {
		    set maxcol $col
		} else {
		    if { $col < $oldcol } {
		        set maxcol $col
		    } elseif { $col > $oldcol } {
		        set mincol $col
		    }
		}

		$table selection clear all
		$table selection set $minrow,$mincol $maxrow,$maxcol
	    }
	}
	$table see $idx
	$self _setasactive $idx
	set lastmovedcell $idx
	focus $table
    }
    method _giveselectionbox {} {
	set isinit 0

	foreach idx [$table curselection] {
	    regexp {([0-9]+),([0-9]+)} $idx {} row col
	    if { !$isinit || $row < $minrow } { set minrow $row }
	    if { !$isinit || $row > $maxrow } { set maxrow $row }
	    if { !$isinit || $col < $mincol } { set mincol $col }
	    if { !$isinit || $col > $maxcol } { set maxcol $col }
	    set isinit 1
	}
	if { !$isinit } {
	    return [list "" "" "" ""]
	} else {
	    return [list $minrow $mincol $maxrow $maxcol]
	}
    }
    method giverow { idx } {
	regexp {([0-9]+),([0-9]+)} $idx {} row col
	return $row
    }
    method givecol { idx } {
	regexp {([0-9]+),([0-9]+)} $idx {} row col
	return $col
    }
    method _incridx { idx incrrow incrcol} {

	regexp {([0-9]+),([0-9]+)} $idx {} row col
	switch -- $incrrow {
	    first { set row [$table cget -titlerows] }
	    last { set row [expr [$table cget -rows]-1] }
	    default {
		set row [expr $row+$incrrow]
		if { $row < [$table cget -titlerows] } {
		    set row [$table cget -titlerows]
		}
	    }
	}
	switch -- $incrcol {
	    first { set col [$table cget -titlecols] }
	    last { set col [expr [$table cget -cols]-1] }
	    default {
		set col [expr $col+$incrcol]
		if { $col < [$table cget -titlecols] } {
		    if { $row > [$table cget -titlerows] } {
		        incr row -1
		        set col [expr [$table cget -cols]-1]
		    } else { set col [$table cget -titlecols] }
		}
	    }
	}
	if { $col == [$table cget -cols] } {
	    incr row
	    set col [$table cget -titlecols]
	}
	return $row,$col
    }
    method browseclear {} {
	foreach idx [$table window names] {
	    if { [string equal [$table window cget $idx -window] $myentry] } {
		return [$self _browseout $idx]
	    }
	}
	return 0
    }
    method _browseediting {} {
	if { [winfo exists $myentry] } { return 1 }
	return 0
    }
    method _formulaebefore {} {
	if { [winfo exists $mytext] } { return 0 }
	if { ![string match =* [$myentry get]] } { return 0 }

	if { [llength [$table curselection]] == 1 } {
	   set txt [$self _rowcol2sval [$table curselection]]
	} elseif { [llength [$table curselection]] > 1 } {
	    set isinit 0
	    foreach i [$table curselection] {
		regexp {([0-9]+),([0-9]+)} $i {} row col
		if { !$isinit || $row < $minrow } { set minrow $row }
		if { !$isinit || $row > $maxrow } { set maxrow $row }
		if { !$isinit || $col < $mincol } { set mincol $col }
		if { !$isinit || $col > $maxcol } { set maxcol $col }
		set isinit 1
	    }
	    if { [string trim [$myentry get]] == "=" } {
		append txt "sum([$self _rowcol2sval $minrow,$mincol]:"\
		    "[$self _rowcol2sval $maxrow,$maxcol])"
	    } else {
		set txt [$self _rowcol2sval $minrow,$mincol]:[$self _rowcol2sval $maxrow,$maxcol]
	    }
	}
	if { [winfo exists $win.fentry] && [focus] eq "$win.fentry" } {
	    $win.fentry insert insert $txt
	} else {
	    $myentry insert insert $txt
	}
	return -1
    }
    method _browseout { idx { force 0 } } {

	if { [winfo exists $myentry] } {
	    if { !$force && $options(-formulaevarname) != "" } {
		set retval [$self _formulaebefore]
		if { $retval != 0 } {
		    if { [winfo exists $mytext] } {
		        focus $mytext
		    } elseif { [winfo exists $win.fentry] && [focus] eq "$win.fentry" } {
		        focus $win.fentry
		    } else { focus $myentry }
		    return $retval
		}
	    }
	    if { !$force && $options(-beforemodifycmd) != "" } {
		set retval [eval [list $options(-beforemodifycmd) $idx $myentry]]
		if { $retval != 0 } {
		    if { [winfo exists $mytext] } {
		        focus $mytext
		    } else { focus $myentry }
		    return $retval
		}
	    }
	    $table conf -state normal
	    if { $options(-formulaevarname) != "" } {
		set varname $options(-formulaevarname)
		set row [$self giverow $idx]
		set col [$self givecol $idx]
		if { [info exists ${varname}($row,$col)] } {
		    set oldvalue [set ${varname}($row,$col)]
		} else {
		    set oldvalue [$table get $idx]
		}
		if { [string match =* [set $options(-entryvarname)]] } {
		    set ${varname}($row,$col) [set $options(-entryvarname)]
		    regexp {([0-9]+),([0-9]+)} $MaxIdxWithFormula {} maxrow maxcol
		    if { $row > $maxrow } { set maxrow $row }
		    if { $col > $maxcol } { set maxcol $col }
		    set MaxIdxWithFormula $maxrow,$maxcol
		} else {
		    catch { unset ${varname}($row,$col) }
		    set oldvalue [$table get $idx]
		    if { [winfo exists $mytext] } {
		        set $options(-entryvarname) [$mytext get 1.0 end-1c]
		        #set $options(-entryvarname) [string map {\n \\n} [$mytext get 1.0 end-1c]]
		    }
		    $table set $idx [set $options(-entryvarname)]
		}
	    } else {
		set oldvalue [$table get $idx]
		if { [winfo exists $mytext] } {
		    set $options(-entryvarname) [$mytext get 1.0 end-1c]
		    #set $options(-entryvarname) [string map {\n \\n} [$mytext get 1.0 end-1c]]
		}
		$table set $idx [set $options(-entryvarname)]
	    }
	    $table conf -state disabled
	    if { [focus] == "$myentry" || [focus] == "$mytext" } { focus $table }
	    set $options(-entryvarname) ""
	    if { [$table cget -multiline] } {
		set irow [$self giverow $idx]
		set nlines 0
		for { set icol 1 } { $icol < [$table cget -cols] } { incr icol } {
		    set nl [expr {[regexp -all {(\n|\\n)} [$table get $irow,$icol]]+1}]
		    if { $nl > $nlines } { set nlines $nl }
		}
		$table height $irow $nlines
	    } else {
		$table height [$self giverow $idx] 1
	    }
	    destroy $myentry
	    if { $options(-modifycmd) != "" } {
		eval $options(-modifycmd) $idx [list $oldvalue]
	    }
	    if { $options(-formulaevarname) != "" } { $self recomputetable }
	}
	if { [winfo exists $win.fentry] } {
	    $win.fentry configure -state disabled
	}
	return 0
    }

    method _browseoutnosave {} {

	if { [winfo exists $myentry] } {
	    set focuswin [focus]
	    if { $focuswin eq "" } { set focuswin . }
	    if { $focuswin eq $myentry || [winfo parent $focuswin] eq \
		$myentry || $focuswin eq $mytext } {
		focus $table
	    }
	    foreach idx [$table window names] {
		if { [string equal [$table window cget $idx -window] $myentry] } {
		    $table selection set $idx
		    break
		}
	    }
	    set $options(-entryvarname) ""

	    if { [$table cget -multiline] } {
		set irow [$self giverow $idx]
		set nlines 0
		for { set icol 1 } { $icol < [$table cget -cols] } { incr icol } {
		    set nl [expr {[regexp -all {(\n|\\n)} [$table get $irow,$icol]]+1}]
		    if { $nl > $nlines } { set nlines $nl }
		}
		$table height $irow $nlines
	    } else {
		$table height [$self giverow $idx] 1
	    }
	    destroy $myentry
	}
    }
    method _ssval { letters nums } {

	set letters [string toupper $letters]
	set varname $options(-varname)

	scan A %c letmin
	scan Z %c letmax
	
	set num 0
	set factor 1
	for { set j [expr [string length $letters]-1] } { $j >= 0 } { incr j -1 } {
	    scan [string index $letters $j] %c letter
	    incr num [expr ($letter-$letmin+1)*$factor]
	    set factor [expr $factor*($letmax-$letmin+1)]
	}
	if { ![$table cget -titlerows] } { incr nums -1 }
	if { ![$table cget -titlecols] } { incr num -1 }

	if { [info exists ${varname}($nums,$num)] } {
	    if { [set ${varname}($nums,$num)] == "" } {
		return 0.0
	    } else {
		set val [set ${varname}($nums,$num)]
		if { [string is double -strict $val] } {
		    return [expr {double($val)}]
		} else { return $val }
	    }
	} else { return 0.0 }
    }
    method _ssvalbox { l1 row1 l2 row2 } {

	set l1 [string toupper $l1]
	set l2 [string toupper $l2]

	scan A %c letmin
	scan Z %c letmax
	
	set col1 0
	set factor 1
	for { set j [expr [string length $l1]-1] } { $j >= 0 } { incr j -1 } {
	    scan [string index $l1 $j] %c letter
	    incr col1 [expr ($letter-$letmin+1)*$factor]
	    set factor [expr $factor*($letmax-$letmin+1)]
	}
	set col2 0
	set factor 1
	for { set j [expr [string length $l2]-1] } { $j >= 0 } { incr j -1 } {
	    scan [string index $l1 $j] %c letter
	    incr col2 [expr ($letter-$letmin+1)*$factor]
	    set factor [expr $factor*($letmax-$letmin+1)]
	}
	if { ![$table cget -titlerows] } { incr row1 -1 ; incr row2 -1 }
	if { ![$table cget -titlecols] } { incr col1 -1 ; incr col2 -1 }

	if { $col1 > $col2 } {
	    set tmp $col1
	    set col1 $col2
	    set col2 $tmp
	}
	if { $row1 > $row2 } {
	    set tmp $row1
	    set row1 $row2
	    set row2 $tmp
	}
	return [list $row1 $col1 $row2 $col2]
    }
    method _evalsum { string } {

	set varname $options(-varname)
	set sum 0
	foreach "- i" [regexp -all -inline {,?((?:[^(),]*\([^\)]*[\)])*[^,()]*),?} $string] {
	    if { [string is double -strict $i] } {
		set sum [expr $sum+$i]
	    } elseif { [regexp {^\s*([a-zA-Z]+)([0-9]+):([a-zA-Z]+)([0-9]+)\s*$} $i {} \
		            l1 num1 l2 num2] } {
		foreach "row1 col1 row2 col2" [$self _ssvalbox $l1 $num1 $l2 $num2] break
		for { set irow $row1 } { $irow <= $row2 } { incr irow } {
		    for { set icol $col1 } { $icol <= $col2 } { incr icol } {
		        if { [info exists ${varname}($irow,$icol)] } {
		            if { [set ${varname}($irow,$icol)] != "" } {
		                set sum [expr {$sum+[set ${varname}($irow,$icol)]}]
		            }
		        }
		    }
		}
	    } elseif { [regexp {^\s*([a-zA-Z]+)([0-9]+)\s*$} $i {} l1 num1]} {
		set sum [expr {$sum+[$self _ssval $l1 $num1]}]

	    } else {
		set sum [expr {$sum+[$self _evalfunction $i]}]
	    }
	}
	return $sum
    }
    method _evalfunction { exp } {
	
	regsub -all {(?i)pi\(\)} $exp 3.14159265358979323846 exp
	
	set regsubsum1 {SUM\((([^()]*\([^\)]*\)[^()]*)*[^\)]*)\)}
	set regsubsum2 "\[[mymethod _evalsum] "
	append regsubsum2 { "\1"]}
	regsub -all -nocase $regsubsum1 $exp $regsubsum2 exp
	set exp [subst -nobackslashes -novariables $exp]
	
	set regsub1 {([^0-9.]|^)([a-zA-Z]+)([0-9]+)(?![\(0-9])}
	set regsub2 "\\1\[[mymethod _ssval] "
	append regsub2 { \2 \3]}
	regsub -all $regsub1 $exp $regsub2 exp
	set exp [subst -nobackslashes -novariables $exp]
	set val [expr $exp]
	if { [string is double -strict $val] && $val == int($val) } {
	    set val [expr {int($val)}]
	}
	return $val
    }
    method recomputetable {} {
	
	set varname $options(-varname)
	set formulaevarname $options(-formulaevarname)
	if { $varname == "" } { return }
	
	
	regexp {([0-9]+),([0-9]+)} $MaxIdxWithFormula {} nrows ncols
	
	for { set i 0 } { $i < 10 } { incr i } {
	    set isdirty 0
	    for { set irow 1 } { $irow <= $nrows } { incr irow } {
		for { set icol 1 } { $icol <= $ncols } { incr icol } {
		    if { [info exists ${formulaevarname}($irow,$icol)] } {
		        set ${varname}($irow,$icol) !ERROR
		        set exp [string range [set ${formulaevarname}($irow,$icol)] 1 end]
		        if { [catch {
		            set val [$self _evalfunction $exp]
		        } errstring] } {
		            set ${varname}($irow,$icol) !ERROR
		        } else {
		            set ${varname}($irow,$icol) $val
		        }
		    }
		}
	    }
	    if { !$isdirty } { break }
	}
    }
    method _comboposting { idx command } {
	uplevel #0 $command $myentry [$table index $idx row] [$table index $idx col]
    }
    method _activate_text_more_lines { idx } {
	if { [$table height [$self giverow $idx]] == 1 } {
	    #autoscroll::unautoscroll $myentry.sv
	    $table height [$self giverow $idx] 4
	    #after 100 [list autoscroll::autoscroll $myentry.sv]
	}
    }
    method _browse { oldidx idx { text {} } { setfocus 1 } } {

	if { $oldidx != "" && [$self _browseout $oldidx] } { return }

	if { [llength [$table curselection]] > 1 } {
	    return
	}
	if { [$table tag includes title $idx]} {
	    return
	}
	if { $options(-disablecolumns) != "" } {
	    set col [$self givecol $idx]
	    if { $options(-disablecolumns) == "allwarn" } {
		set retval [tk_messageBox -default cancel -icon warning -message \
		                [_ "This cell should not be edited. Proceed?"] \
		                -parent $table -type okcancel]
		if { $retval == "cancel" } {
		    return
		}
	    } elseif { $options(-disablecolumns) == "all" } {
		WarnWin [_ "This cell cannot be edited"] $table
		return
	    } elseif { [lindex $options(-disablecolumns) $col] == 2 } {
		set retval [tk_messageBox -default cancel -icon warning -message \
		                [_ "This column should not be edited. Proceed?"] \
		                -parent $table -type okcancel]
		if { $retval == "cancel" } {
		    return
		}
	    } elseif { [lindex $options(-disablecolumns) $col] == 1 } {
		WarnWin [_ "This column cannot be edited"] $table
		return
	    }
	}
	if { $options(-disablecells) ne "" } {
	    if { [lsearch -sorted $options(-disablecells) $idx] != -1 } {
		WarnWin [_ "This cell cannot be edited"] $table
		return
	    }
	}

	set type entry
	if { $options(-editwithcombo) != "" } {
	    set col [expr [$self givecol $idx]+1] ;# adding 1 because pos 0 is command
	    set command [lindex $options(-editwithcombo) 0]
	    set editable [lindex $options(-editwithcombo) $col]
	    if { $editable == "" } { set editable -1 }
	    if { $editable != -1 } { set type combo }
	}
	if { $type == "entry" && $options(-editwithtext) != "" } {
	    set col [$self givecol $idx]
	    if { $options(-editwithtext) == "all" } {
		set editable 1
	    } else {
		set editable [lindex $options(-editwithtext) $col]
	    }
	    if { $editable == "" } { set editable 0 }
	    if { $editable != 0 } { set type text }
	}
	destroy $myentry
	switch $type {
	    entry {
		entry $myentry -bd 0 -textvar $options(-entryvarname)
	    }
	    combo {
		switch $editable 1 { set state "" } 0 { set state readonly }
		ttk::combobox $myentry -textvariable $options(-entryvarname) -state $state \
		    -postcommand [mymethod _comboposting $idx \
		        [lindex $options(-editwithcombo) 0]]
		# dirty trick
		#$myentry.a.c configure -cursor arrow
		$myentry configure -cursor arrow
		foreach i [list ButtonPress-1 B1-Motion ButtonRelease-1] {
		    bind $myentry <$i> "[bind TCombobox <$i>];break"
		}
	    }
	    text {
		frame $myentry
		text $mytext -background [$table cget -bg] -wrap word \
		    -height 1 -bd 0 \
		    -yscrollcommand [list $myentry.sv set]
		ttk::scrollbar $myentry.sv -orient vertical -command [list $mytext yview]
		#autoscroll::autoscroll $myentry.sv
 
		grid $mytext $myentry.sv -sticky nsew
		grid columnconfigure $myentry 0 -weight 1
		$myentry.sv configure -cursor arrow
	    }
	}
	set $options(-entryvarname) ""

	if { $text == "" } {
	    if { $options(-formulaevarname) != "" } {
		set row [$self giverow $idx]
		set col [$self givecol $idx]
		set varname $options(-formulaevarname)
		if { [info exists ${varname}($row,$col)] } {
		    set $options(-entryvarname) [set ${varname}($row,$col)]
		} else {
		    set $options(-entryvarname) [$table get $idx]
		}
	    } else {
		set $options(-entryvarname) [$table get $idx]
	    }
	    catch {
		$myentry sel range 0 end
	    }
	} else {
	    set $options(-entryvarname) $text
	}
	if { $type eq "text" } {
	    $mytext del 1.0 end
	    $mytext insert end [string map {\\n \n} [set $options(-entryvarname)]]
	    $mytext tag add sel 1.0 end
	    if { [$mytext index end-1c] >= 2 } {
		set oldheight [$table height [$self giverow $idx]]
		if { $oldheight < 4 } {
		    $table height [$self giverow $idx] 4
		    $mytext conf -height 4
		}
	    }
	    $table window conf $idx -window $myentry -sticky nsew -pady 0

	    update idletasks
	    set ypixels [$mytext count -update -ypixels 1.0 end]
	    set height [winfo height $mytext]
	    if { $height < $ypixels + 5 } {
		set oldheight [$table height [$self giverow $idx]]
		if { $oldheight < 4 } {
		    $table height [$self giverow $idx] 4
		    $mytext conf -height 4
		}
	    }
	} else {
	    $table window conf $idx -window $myentry -sticky ew
	}
	switch $type {
	    entry { set entry $myentry }
	    combo {
		# dirty trick to make things work
		#set entry $myentry.e
		set entry $myentry
	    }
	    text { set entry $mytext }
	}

	if { $setfocus } {
	    if { $type eq "entry" } {
		focus -force $entry
	    } else {
		focus $entry
	    }
	}
	
	if { $text != "" } {
	    update
	    if { $type != "text" } {
		$entry selection clear
		$entry icursor end
	    } else {
		$entry tag remove sel 1.0 end
		$entry mark set insertion end
	    }
	}
	bind $entry <Escape> "[mymethod _browseoutnosave]; break"
	if { $type ne "text" } {
	    bind $entry <Return> "[mymethod _movecell 1 0 {} 1]; break"
	    foreach i "<<Cut>> <<Copy>> <<Paste>>" {
		bind $entry $i "[bind Entry $i] ; break"
	    }
	} else {
	    bind $entry <Return> [mymethod _activate_text_more_lines $idx]
	    foreach i "<<Cut>> <<Copy>> <<Paste>>" {
		bind $entry $i "[bind Text $i] ; break"
	    }
	}
	bind $entry <Any-Tab> "[mymethod _movecell 0 1 {} 1]; break"
	bind $entry <Shift-Return> "[mymethod _movecell -1 0 {} 1]; break"
	bind $entry <Shift-Tab> "[mymethod _movecell 0 -1 {} 1]; break"

	if { [winfo exists $win.fentry] } {
	    $win.fentry configure -state normal
	}
    }
}

# ::tk::table::fullBeginSelect --
#
# This procedure is typically invoked on button-1 presses. It begins
# the process of making a selection in the table. Its exact behavior
# depends on the selection mode currently in effect for the table;
# see the Motif documentation for details.
#
# Arguments:
# w        - The table widget.
# el        - The element for the selection operation (typically the
#        one under the pointer).  Must be in row,col form.
# extracted from: TkTable.tcl

namespace eval ::tk::table {}
proc ::tk::table::fullBeginSelect {w el} {
    variable Priv
    if {[scan $el %d,%d r c] != 2} return
    switch [$w cget -selectmode] {
	multiple {
	    if {[$w tag includes title $el]} {
		## in the title area
		if {$r < [$w cget -titlerows]+[$w cget -roworigin]} {
		    ## We're in a column header
		    if {$c < [$w cget -titlecols]+[$w cget -colorigin]} {
		        ## We're in the topleft title area
		        set inc topleft
		        set el2 end
		    } else {
		        set inc [$w index topleft row],$c
		        set el2 [$w index end row],$c
		    }
		} else {
		    ## We're in a row header
		    set inc $r,[$w index topleft col]
		    set el2 $r,[$w index end col]
		}
	    } else {
		set inc $el
		set el2 $el
	    }
	    if {[$w selection includes $inc]} {
		$w selection clear $el $el2
	    } else {
		$w selection set $el $el2
	    }
	}
	extended {
	    $w selection clear all
	    if {[$w tag includes title $el]} {
		if {$r < [$w cget -titlerows]+[$w cget -roworigin]} {
		    ## We're in a column header
		    if {$c < [$w cget -titlecols]+[$w cget -colorigin]} {
		        ## We're in the topleft title area
		        $w selection set $el end
		    } else {
		        if { [$w spans $el] ne "" } {
		            scan [$w spans $el] %d,%d dr dc
		            set c2 [expr {$c+$dc}]
		        } else { set c2 $c }
		        $w selection set $el [$w index end row],$c2
		    }
		} else {
		    ## We're in a row header
		    if { [$w spans $el] ne "" } {
		        scan [$w spans $el] %d,%d dr dc
		        set r2 [expr {$r+$dr}]
		    } else { set r2 $r }
		    $w selection set $el $r2,[$w index end col]
		}
	    } else {
		$w selection set $el
	    }
	    $w selection anchor $el
	    set Priv(tablePrev) $el
	}
	default {
	    if {![$w tag includes title $el]} {
		$w selection clear all
		$w selection set $el
		set Priv(tablePrev) $el
	    }
	    $w selection anchor $el
	}
    }
}


if 0 {
    fulltktable::table .t -formulae 1 -editwithcombo [list fillcombo -1 -1 1] \
	-disablecolumns [list 0 1] -tooltips tooltipstxt
    pack .t -fill both -expand 1

    proc fillcombo { combo args } {
	$combo configure -values [list aa bb]
    }
    proc tooltipstxt { idx } {
	scan $idx %d,%d r c
	if { $c == 2 } {
	    return "row=$r column=$c"
	}
	return ""
    }

    .t conf -state normal
    .t set 1,0 pepet
    .t conf -state disabled
    .t spans 1,0 3,0
}

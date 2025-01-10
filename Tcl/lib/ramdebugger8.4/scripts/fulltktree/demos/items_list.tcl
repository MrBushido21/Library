
package require fulltktree
package require compass_utils
package require sqlite3 
package require msgcat
interp alias "" _ "" msgcat::mc

image create photo on-16 -data {
R0lGODdhEAAQAJEAAP///wAAAP///////ywAAAAAEAAQAAACK4SPacHtfZ5kMaiKlaXLJsoB
YLV5Ynl6IehkZ2e+XfSZoWZPD6nf1w9UFAAAOw==
}

image create photo off-16 -data {
    R0lGODdhEAAQAJEAAP///wAAAP///////ywAAAAAEAAQAAACJYSPacHtfZ5kMaiKL6DLar55
    FwgqpGiKZXJqYTaq01PNkIvnRwEAOw==
}

if { [winfo screenwidth .] < 350 } {
    set ispocket 1
} else {
    set ispocket 0
}

cu::init_tile_styles

namespace eval items_list {
    variable active_filter
    variable search ""
    variable afteridle ""
    variable topdir [file dirname [info script]]
}

proc items_list::init { w } {
    variable active_filter
    variable topdir
    
    sqlite3 db [file join $topdir items_list.db3]
    set db db
    
    set schema {
	create table shopping(
	id integer primary key,
	active text,
	name text unique,
	quant text,
	category text,
	notes text);

	create trigger shopping1 after update of active
	on shopping
	when new.quant=0
	begin update shopping set quant=1 where id=new.id; end;
    }
    set ret [$db eval { select name from sqlite_master where type='table' 
	    and name='shopping' }]
    if { ![llength $ret] } {
	db eval $schema
    }
    
    set columns ""
    foreach "- name dtype null default -" [db eval { pragma table_info(shopping) }] {
	switch $name {
	    active { set l 6 }
	    name { set l 12 }
	    default { set l 8 }
	}
	lappend columns [list $l $name left text 1]
    }
    
    toplevel $w
    if { !$::ispocket } {
	wm geometry $w 240x268+600+200
    } else {
	wm geometry $w 240x268+-2+26
	bind $w <ConfigureRequest> {::etcl::autofit %W }
	::etcl::autofit $w
	# depending on PDA, F1 and F11 are left soft button
	#bind $win <KeyRelease-F11> [mymethod view_fullscreen_menu_left]
	#bind $win <KeyRelease-F1> [mymethod view_fullscreen_menu_left]
    }
    set menu [menu $w.menu -tearoff 0]

    $menu add cascade -label [_ "Tools"] -menu $menu.tools
    menu $menu.tools -tearoff 0
    $w configure -menu $menu
    $menu.tools add command -label [_ "Exit"] -command exit
    
    set filters [dict create all [_ "All"] non_disabled [_ "Non disabled"]]
    
    ttk::menubutton $w.cb1 -width 6 -menu $w.cb1.m
    menu $w.cb1.m -tearoff 0
    dict for "n v" $filters {
	$w.cb1.m add command -label $v -command [list set items_list::active_filter $n]
    }
    
    ttk::label $w.l1 -text [_ "Search:"]
    ttk::combobox $w.cb2 -textvariable items_list::search -values ""
    
    fulltktree $w.t -columns $columns -width 300 -showlines 0 -indent 0 -selectmode extended \
	-sensitive_cols all -showbuttons 0 \
	-contextualhandler_menu [list items_list::contextual db] \
	-editaccepthandler [list items_list::edit_accept db]
    
    $w.t column configure 0 -visible 0
    $w.t style layout window e_window -sticky w -iexpand "" -expand e -detach 1

    grid $w.cb1 $w.l1 $w.cb2 -sticky w -padx 1
    grid $w.t - - -sticky nsew -padx 1
    grid columnconfigure $w 2 -weight 1
    grid rowconfigure $w 1 -weight 1
    
    bind [$w.t givetreectrl] <KeyPress-Right> [list items_list::generate_contextual $w.t]
    bind [$w.t givetreectrl] <KeyPress> [list items_list::generate_keypress $w.t $w.cb2 %K %A]

    set cmd [list items_list::fill_afteridle $db $w.t]
    trace add variable items_list::search write "$cmd;#"
  
    set cmd [list items_list::change_filter $db $w.t $w.cb1 $filters]
    trace add variable items_list::active_filter write "$cmd;#"
  
    focus -force $w.t
    set active_filter all
    
    return db
}

proc items_list::change_filter { db tree mb filters } {
    variable active_filter
    
    $mb configure -text [dict get $filters $active_filter]
    fill $db $tree
}

proc items_list::generate_keypress { tree combo K A } {
    variable search
    
    switch -- $K {
	BackSpace { set search [string range $search 0 end-1] }
	Up - Down - Left - Right - Tab { return }
	default {
	    if { [string length $K] == 1 } {
		append search $A
	    }
	}
    }
    
}

proc items_list::generate_contextual { tree } {
    
    set x [expr {[lindex [$tree item bbox active 1] 0]}]
    set y [expr {[lindex [$tree item bbox active 1] 1]}]
    set X [expr {[winfo rootx $tree]+$x}]
    set Y [expr {[winfo rooty $tree]+$y}]

    event generate [$tree givetreectrl] <ButtonRelease-3> -rootx $X -rooty $Y -x $x -y $y
}
  
proc items_list::_give_cols { db } {
    set scols ""
    foreach "- name dtype null default -" [$db eval { pragma table_info(shopping) }] {
	lappend scols $name
    }
    return $scols
}

proc items_list::fill_afteridle { db tree } {
    variable afteridle
    
    after cancel $afteridle
    set afteridle [after idle [list items_list::fill $db $tree]]
}
    
proc items_list::fill { db tree } {
    variable active_filter
    variable search
    
    set af $active_filter
    if { [string trim $search] ne "" && $af eq "non_disabled" } {
	set af all
    }
    
    switch --  $af {
	all {
	    set searchP "%$search%"
	    set cmd { select * from shopping where name like $searchP
		order by active desc,name }
	}
	non_disabled {
	    set cmd { select * from shopping where active != ''
		order by active desc,name }
	}
    }
	
    set scols [_give_cols $db]

    set selection ""
    foreach item [$tree selection get] {
	lappend selection [$tree item text $item 0]
    }
    set selection [lsort -integer $selection]
    set active [$tree item text [$tree item id active] 0]
    
    $tree item delete all
    set idx 0
    foreach $scols [$db eval $cmd] {
	set line ""
	foreach i $scols { lappend line [set $i] }
	set item [fill_one $db $tree end 0 $line $active]
	if { [lsearch -integer -sorted $selection $id] != -1 } {
	    $tree selection add $item
	}
	if { $id eq $active } {
	    $tree activate $item
	}
    }
    if { [llength [$tree selection get]] == 0 } {
	catch { $tree selection add "first visible" }
    }
    if { [lsearch [$tree selection get] [$tree item id active]] == -1 } {
	set item [lindex [$tree selection get] 0]
	catch { $tree activate $item }
    }
}

proc items_list::fill_one { db tree where parent_or_sibling line active } {

    if { $parent_or_sibling eq "" || $parent_or_sibling == 0 } {
	set parent_or_sibling 0
	set where end
    }
    set item [$tree insert $where $line $parent_or_sibling]

    switch $active {
	1 { set icon on-16 }
	0 { set icon off-16 }
	default { set icon "" }
    }
    
    destroy $tree.m$item
    menubutton $tree.m$item -image $icon -menu $tree.m$item.m \
	-relief flat -bd 1 -highlightthickness 0 \
	-background white -foreground blue -activeforeground red \
	-width 16
    
    menu $tree.m$item.m -tearoff 0
    $tree.m$item.m add command -label [_ Activate] -command [list items_list::change $db \
	    $tree $item activate]
    $tree.m$item.m add command -label [_ Deactivate] -command [list items_list::change $db \
	    $tree $item deactivate]
    $tree.m$item.m add command -label [_ Disable] -command [list items_list::change $db \
	    $tree $item disable]
    
    $tree item style set $item 1 window
    $tree item element configure $item 1 e_window -window $tree.m$item
    $tree configure -itemheight 20
    return $item
}

proc items_list::change { db tree itemList what } {
    foreach item $itemList {
	set id [$tree item text $item 0]
	switch $what {
	    activate {
		$db eval { update shopping set active=1 where id=$id }
	    }
	    deactivate {
		$db eval { update shopping set active=0 where id=$id }
	    }
	    disable {
		$db eval { update shopping set active='' where id=$id }
	    }
	    remove {
		$db eval { delete from shopping where id=$id }
	    }
	}
    }
    fill $db $tree
}

proc items_list::new { db tree } {
    variable search
    
    if { [string trim $search] ne "" } {
	set name $search
    } else {
	set name unnamed
    }
    while { [$db eval { select name from shopping where name = $name }] ne "" } {
	set num ""
	regexp {^(\w*\D)(\d+)$} $name {} name num
	if { $num ne "" } { incr num } else { set num 2 }
	set name $name$num
    }
    $db eval { insert into shopping (active,name,quant) values(1,$name,1) }
    set line [$db eval { select * from shopping where name=$name }]
    set next_item [$tree item id "first visible"]
    set item [fill_one $db $tree prev $next_item $line 1]
    $tree selection clear
    $tree selection set $item
    $tree activate $item
    $tree see $item
    event generate [$tree givetreectrl] <F2>
}

proc items_list::contextual { db tree menu item selection } {

    foreach what [list activate deactivate disable remove] \
	name [list [_ Activate] [_ Deactivate] [_ Disable] [_ Remove]] {
	    $menu add command -label $name -command [list items_list::change $db \
	    $tree $selection $what]
    }
    $menu add separator
    $menu add command -label [_ "New"] -command [list items_list::new $db $tree]
    return 0
}

proc items_list::edit_accept { db tree item col text } {
    
    set tree [winfo parent $tree]
    if { [$tree item text $item $col] eq $text } { return }
    set scols [_give_cols $db]
    set colname [lindex $scols $col]
    set id [$tree item text $item 0]
    set cmd "update shopping set $colname="
    append cmd {$text where id=$id }
    set err [catch { $db eval $cmd } errstring]
    if { $err } {
	tk_messageBox -message $errstring
    }
    fill $db $tree
}

proc items_list::check_exit { w toplevel } {
    if { $w eq $toplevel } { exit }
}

proc items_list::import_from_handyshopper { db w } {
    set file [tk_getOpenFile -defaultextension .txt -filetypes [list \
		[list [_ "Text files"] [list ".txt"]] \
		[list [_ "All files"] [list "*"]]] \
	    -parent $w -title [_ "Import handyshopper file"]]
    if { $file == "" } { return }
    set fin [open $file r]
    fconfigure $fin -encoding unicode
    set data [read $fin]
    close $fin
    
    $db eval { begin }
    
    set rex {\u2022\s+(?:(\d+)@)?([^\u2022|]+)(?:|([^\u2022]+))}
    foreach "- num name notes" [regexp -inline -all $rex $data] {
	set num [string trim $num]
	set name [string trim $name]
	set notes [string trim $notes]
	$db eval { insert  into shopping (active,name,quant,notes)
	    values ('',$name,$num,$notes) }
    }
    $db eval { commit }
}

wm withdraw .
set db [items_list::init .t]
bind .t <Destroy> [list items_list::check_exit %W .t]
#items_list::import_from_handyshopper $db .t














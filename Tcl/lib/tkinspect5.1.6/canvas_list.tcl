# Handles browsing canvas items.

widget canvas_list {
    object_include tkinspect_list
    param title "Canvases"
    method get_item_name {} { return canvas }
    method update_self {target} {
	$slot(main) windows_info update $target
	$self update $target
    }
    method update {target} {
	$self clear
	foreach w [$slot(main) windows_info get_windows] {
	    set class [$slot(main) windows_info get_class $target $w]
	    if {$class eq "Canvas" || $class eq "PathCanvas"} {
		$self append $w
	    }
	}
    }
    method retrieve {target canvas} {
	set items [send $target $canvas find all]
	set class [send $target winfo class $canvas]
	set result "# canvas $canvas has [llength $items] items\n"
	foreach item $items {
	    if {$item == 0 && $class eq "PathCanvas"} {
		# leave out the root item of a tkp::canvas for now
		continue
	    }
	    set type [send $target $canvas type $item]
	    append result "# item $item ($type) is tagged [list [send $target $canvas gettags $item]]\n"
	    if {![catch {$canvas coords $item} coords]} {
		append result "$canvas coords $item \\\n\t$coords\n"
	    }
	    append result "$canvas itemconfigure $item"
	    foreach spec [send $target [list $canvas itemconfig $item]] {
		append result " \\\n\t[lindex $spec 0] [list [lindex $spec 4]]"
	    }
	    append result "\n"
	}
	return $result
    }
    method send_filter {value} {
	return $value
    }
}

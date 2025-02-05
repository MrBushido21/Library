
package require snit

proc set! { varName args } {
    
    upvar 1 $varName v
    if { [llength $args] == 0 && ![info exists v] } {
        return ""
    }
    return [uplevel 1 [list set $varName {*}$args]]
}

proc info_fullargs { procname } {
    set ret ""
    foreach arg [uplevel 1 [list info args $procname]] {
        if { [uplevel 1 [list info default $procname $arg value]] } {
            upvar 1 value value
            lappend ret [list $arg $value]
        } else {
            lappend ret $arg
        }
    }
    return $ret
}

namespace eval cu {}
namespace eval cu::file {}

# for tclIndex to work 
proc cu::menubutton_button { args } {}

snit::widgetadaptor cu::menubutton_button {
    option -command ""
    option -image ""
    option -text ""

    delegate method * to hull
    delegate option * to hull
    delegate option -_image to hull as -image
    delegate option -_text to hull as -text

    variable xmin
    variable is_button_active 1
    variable press_after ""
    
    constructor args {
        installhull using ttk::menubutton -style Toolbutton
        bind $win <ButtonPress-1> [mymethod BP1 %x %y]
        bind $win <ButtonRelease-1> [mymethod BR1 %x %y]
        bind $win <Down> [list ttk::menubutton::Popdown %W]
        bind $win <Motion> [mymethod check_cursor %x %y]
        bind $win <Configure> [mymethod  _calc_xmin]

        $self configurelist $args
    }
    onconfigure -image {img} {
        set options(-image) $img

        if { $options(-text) ne "" } {
            $self configure -_image $img
            return
        } 
        set new_img [cu::add_down_arrow_to_image $img]
        $self configure -_image $new_img
        bind $win <Destroy> +[list image delete $new_img]
    }
    onconfigure -text {value} {
        set options(-text) $value

        if { $options(-text) ne "" } {
            $self configure -style ""
            if { $options(-image) ne "" } {
                $self configure -_image $options(-image)
            }
        }
        $self configure -_text $value
    }
    method _calc_xmin {} {
        if { [winfo width $win] > 1 } {
            set xmin  [expr {[winfo width $win]-12}]
        } else {
            set xmin  [expr {[winfo reqwidth $win]-12}]
        }
    }
    method give_is_button_active_var {} {
        return [myvar is_button_active]
    }
    method BP1 { x y } {
        if { !$is_button_active } { return }
        
        if { $x < $xmin && $options(-command) ne "" } {
            $win instate !disabled {
                catch { tile::clickToFocus $win }
                catch { ttk::clickToFocus $win }
                $win state pressed
            }
            set press_after [after 700 [mymethod BP1_after]]
            return -code break
        }
    }
    method BP1_after {} {
        set press_after ""
        $win instate {pressed !disabled} {
            ttk::menubutton::Pulldown $self
        }
    }
    method BR1 { x y } {
        if { !$is_button_active } { return }
        
        if { $press_after ne "" } {
            after cancel $press_after
        }
        if { $press_after ne "" && $x < $xmin && $options(-command) ne "" } {
            $win instate {pressed !disabled} {
                $win state !pressed
                uplevel #0 $options(-command)
            }
            set press_after ""
            return -code break
        }
        set press_after ""
    }
    method check_cursor { x y } {
        if { $x < $xmin } {
            $win configure -cursor ""
        } else {
            $win configure -cursor bottom_side
        }
    }
}

snit::widgetadaptor cu::combobox {
    option -valuesvariable ""
    option -textvariable ""
    option -statevariable ""
    option -values ""
    option -dict ""
    option -dictvariable ""

    variable _translated_textvariable ""

    delegate method * to hull
    delegate option * to hull
    delegate option -_values to hull as -values
    delegate option -_textvariable to hull as -textvariable

    constructor args {
        installhull using ttk::combobox

        cu::add_contextual_menu_to_entry $win init
        bind $win <<ComboboxSelected>> [mymethod combobox_selected]
        $self configurelist $args
    }
    destructor {
        catch {
            if { $options(-valuesvariable) ne "" } {
                upvar #0 $options(-valuesvariable) v
                trace remove variable v write "[mymethod _changed_values_var];#"
            }
            if { $options(-dictvariable) ne "" } {
                upvar #0 $options(-dictvariable) v
                trace remove variable v write "[mymethod _changed_values_var];#"
            }
            if { $options(-textvariable) ne "" } {
                upvar #0 $options(-textvariable) v
                trace remove variable v write "[mymethod _written_textvariable];#"
            }
            if { $options(-statevariable) ne "" } {
                upvar #0 $options(-statevariable) v
                trace remove variable v write "[mymethod _written_statevariable];#"
                trace remove variable v read "[mymethod _read_statevariable];#"
            }
        }
    }
    onconfigure -textvariable {value} {
        set options(-textvariable) $value
        $self configure -_textvariable [myvar _translated_textvariable]

        upvar #0 $options(-textvariable) v
        trace add variable v write "[mymethod _written_textvariable];#"
        trace add variable [myvar _translated_textvariable] write \
            "[mymethod _read_textvariable];#"
        if { [info exists v] } {
            $self _written_textvariable
        }
    }
    onconfigure -dictvariable {value} {
        set options(-dictvariable) $value
        $self _changed_values_var
        upvar #0 $options(-dictvariable) v
        trace add variable v write "[mymethod _changed_values_var];#"
    }
    onconfigure -statevariable {value} {
        set options(-statevariable) $value

        upvar #0 $options(-statevariable) v
        trace add variable v write "[mymethod _written_statevariable];#"
        trace add variable v read "[mymethod _read_statevariable];#"
        if { [info exists v] } {
            set v $v
        }
    }
    onconfigure -valuesvariable {value} {
        set options(-valuesvariable) $value

        upvar #0 $options(-valuesvariable) v

        if { $options(-dictvariable) ne "" } {
            upvar #0 $options(-dictvariable) vd
            if { [info exists vd] } {
                set dict $vd
            } else {
                set dict ""
            }
        } else {
            set dict $options(-dict)
        }
        if { ![info exists v] } {
            set v ""
            foreach value [$self cget -_values] {
                catch { 
                    set value [dict get [dict_inverse $dict] $value]
                }
                lappend v $value
            }
        } else {
            set vtrans ""
            foreach value $v {
                catch { set value [dict get $dict $value] }
                lappend vtrans $value
            }
            $self configure -_values $vtrans
        }
        trace add variable v write "[mymethod _changed_values_var];#"
    }
    onconfigure -dict {value} {
        set options(-dict) $value
        $self _changed_values_var
    }
    onconfigure -values {values} {
        if { $options(-valuesvariable) ne "" } {
            upvar #0 $options(-valuesvariable) v
            set v $values
        } else {
            if { $options(-dictvariable) ne "" } {
                upvar #0 $options(-dictvariable) vd
                if { [info exists vd] } {
                    set dict $vd
                } else {
                    set dict ""
                }
            } else {
                set dict $options(-dict)
            }
            set vtrans ""
            foreach value $values {
                catch { set value [dict get $dict $value] }
                lappend vtrans $value
            }
            $self configure -_values $vtrans
        }
    }
    oncget -values {
        set v ""
        foreach value [$self cget -_values] {
#             catch {
#                 set value [dict get [dict_inverse $options(-dict)] $value]
#             }
            lappend v $value
        }
        return $v
    }
    method _changed_values_var {} {
        if { $options(-valuesvariable) ne "" } {
            upvar #0 $options(-valuesvariable) v
        } else {
            set v [$self cget -values]
        }
        if { $options(-dictvariable) ne "" } {
            upvar #0 $options(-dictvariable) vd
            if { [info exists vd] } {
                set dict $vd
            } else {
                set dict ""
            }
        } else {
            set dict $options(-dict)
        }
        set vtrans ""
        foreach value $v {
            catch { set value [dict get $dict $value] }
            lappend vtrans $value
        }
        $self configure -_values $vtrans
        $self _written_textvariable
    }
    method _written_textvariable { args } {

        set optional {
            { -force_dict "" 0 }
        }
        set compulsory ""
        parse_args $optional $compulsory $args

        upvar #0 $options(-textvariable) v
        if { ![info exists v] } { return }
        set value $v
        if { $options(-dictvariable) ne "" } {
            upvar #0 $options(-dictvariable) vd
            if { [info exists vd] } {
                set dict $vd
            } else {
                set dict ""
            }
        } else {
            set dict $options(-dict)
        }
        if { $force_dict || [$self instate readonly] } {
            catch { set value [dict get $dict $value] }
        }
        if { $_translated_textvariable ne $value } {
            set _translated_textvariable $value
        }
    }
    method _read_textvariable {} {
        upvar #0 $options(-textvariable) v
        set value $_translated_textvariable
        if { $options(-dictvariable) ne "" } {
            upvar #0 $options(-dictvariable) vd
            if { [info exists vd] } {
                set dict $vd
            } else {
                set dict ""
            }
        } else {
            set dict $options(-dict)
        }
        catch {
            set value [dict get [dict_inverse $dict] $value]
        }
        if { ![info exists v] || $v ne $value } {
            set v $value
        }
    }
    method _written_statevariable {} {
        upvar #0 $options(-statevariable) v
        $self state $v
    }
    method _read_statevariable {} {
        upvar #0 $options(-statevariable) v
        set v [$self state]
    }
    method combobox_selected {} {
        if { ![$self instate readonly] } {
            $self _written_textvariable -force_dict
        }
    }
}

################################################################################
#    check_listbox
################################################################################

snit::widgetadaptor cu::check_listbox {
    option -values
    option -add_new_button 0
    option -permit_rename 0
    option -permit_delete 0

    delegate method * to hull
    delegate option * to hull

    variable tree
    variable is_built
    variable itemDict ""
    variable exclusiveDict ""
    variable prev_selection ""
    variable add_item ""
    
    constructor args {
        
        package require fulltktree
        
        set is_built 0
        
        set columns [list \
                [list 25 Groups left imagetext 1] \
                ]
        
        installhull using ::fulltktree -width 130 -height 150 \
            -columns $columns -expand 1 \
            -selectmode extended -showlines 1 -showrootlines 0 -indent 1 -showbutton 1 \
            -showheader 0 -sensitive_cols all -buttonpress_open_close 0 \
            -have_vscrollbar 1 \
            -contextualhandler_menu [mymethod contextual_menu]  \
            -editbeginhandler [mymethod edit_name_begin] \
            -editaccepthandler [mymethod edit_name_accept] \
            -selecthandler [mymethod _selection]
        set tree $self
        
        $tree state define check
        $tree state define on
        
        set is_built 1
        $self configurelist $args
    }
    onconfigure -values { values } {
        set options(-values) $values
        
        if { !$is_built } { return }
        $self _update_from_values
    }
    onconfigure -add_new_button { value } {
        set options(-add_new_button) $value
        
        if { !$is_built } { return }
        $self _update_from_values
    }
    oncget -values {
        foreach i [range 0 [llength $options(-values)]] {
            set elm [lindex $options(-values) $i]
            foreach j [range [llength $elm] 4] { lappend elm "" }
            lassign $elm name state parentName open_close
            set item [dict get $itemDict values_idx $i]

            if { [$tree item state get $item on] } {
                lset elm 1 on
            } else {
                lset elm 1 off
            }
            if { $parentName ne "" } {
                if { [$tree item state get $item open] } {
                    lset elm 3 open
                } else {
                    lset elm 3 close
                }
            }
            lset options(-values) $i $elm
        }
        return $options(-values)
    }
    method _update_from_values {} {
        
        $tree item delete all
        set itemDict ""
        set exclusiveDict ""
        set values_idx 0
        foreach value $options(-values)  {
            $self _insert end $value $values_idx
            incr values_idx
        }
        if { $options(-add_new_button) } {
            $self _create_add_button
        }
    }
    method contextual_menu { - menu item selection } {
        
        $menu add command -label [_ "Activate"] -command [mymethod set_state $selection on]
        $menu add command -label [_ "Dectivate"] -command [mymethod set_state $selection !on]
        
        set children [$tree item children [$tree item parent $item]]
        set ipos [lsearch -exact $children $add_item]
        if { $ipos != -1 } {
            set children [lreplace $children $ipos $ipos]
        }
        if { [lsearch -exact $children $item] > 0 } {
            $menu add command -label [_ "Move up"] -command [mymethod move_item $item up]
        }
        if { [lsearch -exact $children $item] < [llength $children]-1 } {
            $menu add command -label [_ "Move down"] -command [mymethod move_item $item down]
        }
        $menu add separator
        
        if { $options(-permit_rename) } {
            $menu add command -label [_ "Rename"] -command [mymethod rename [lindex $selection 0]]
        }
        if { $options(-add_new_button) } {
            $menu add command -label [_ "Add"] -command [mymethod add_new_item]
        }
        if { $options(-permit_delete) } {
            $menu add separator
            $menu add command -label [_ "Delete"] -command [mymethod delete_items $selection]
        }
    }
    method rename { { item "" } } {
        if { $item ne "" } {
            $tree selection clear
            $tree selection add $item
            $tree activate $item
            $tree see $item
        }
        focus [$tree givetreectrl]
        update
        event generate $tree <F2>
    }
    method _create_add_button {} {
        set b [$tree givetreectrl].message
        destroy $b
        button $b -text [_ "Add"] \
            -foreground blue -background white -bd 0 -cursor hand2 \
            -command [mymethod add_new_item]
        set font [concat [font actual [$b cget -font]] -underline 1]
        $b configure -font $font
        
        set add_item [$tree insert end ""]
        $tree item style set $add_item 0 window
        $tree item element configure $add_item 0 e_window -destroy 1 \
            -window $b
    }
    method add_new_item {} {
        
        foreach item [$tree item children 0] {
            if { [$tree item style set $item 0] eq "window" } {
                $tree item delete $item
                break
            }
        }
        set idx 1
        while { [lsearch -index 0 $options(-values) [_ "Unnamed%d" $idx]] != -1 } {
            incr idx
        }
        set value [list [_ "Unnamed%d" $idx] on "" open]
        set values_idx [llength $options(-values)]
        lappend options(-values) $value
        set item [$self _insert end $value $values_idx]
        if { $options(-add_new_button) } {
            $self _create_add_button
        }
        $tree selection clear
        $tree selection add $item
        $tree activate $item
        $tree see $item
        #focus $tree
        focus [$tree givetreectrl]
        update
        event generate $tree <F2>
    }
    method edit_name_begin { args } {
        if { $options(-permit_rename) == 0 } {
            return 0
        }
        return 1
    }
    method edit_name_accept { args } {

        lassign $args - item col text
        
        if { ![regexp {[-\w.]{2,}} $text] } {
            tk_messageBox -message [_ "Name can only contain letters, digits, -_.'"] -parent $win
            return
        }
        $tree item text $item 0 $text
        set values_idx [dict get $itemDict item $item]
        lset options(-values) $values_idx 0 $text
    }
    method move_item { item up_down } {
        
        set values_idx [dict get $itemDict item $item]
        
        switch $up_down {
            up {
                set sibling [$tree item prevsibling $item]
                set values_idx_sibling [dict get $itemDict item $sibling]

                set v [lindex $options(-values) $values_idx]
                lset options(-values) $values_idx [lindex $options(-values) $values_idx_sibling]
                lset options(-values) $values_idx_sibling $v
                $tree item prevsibling $sibling $item
            }
            down {
                set sibling [$tree item nextsibling $item]
                set values_idx_sibling [dict get $itemDict item $sibling]

                set v [lindex $options(-values) $values_idx]
                lset options(-values) $values_idx [lindex $options(-values) $values_idx_sibling]
                lset options(-values) $values_idx_sibling $v
                $tree item nextsibling $sibling $item
            }
        }
    }
    method delete_items { itemList } {
        
        for { set il 0 } { $il < [llength $itemList] } { incr il } {
            set item [lindex $itemList $il]
            if { [$tree item id $item] eq "" } { continue }
            
            set values_idx [dict get $itemDict item $item]
            set options(-values) [lreplace $options(-values) $values_idx $values_idx]
            while 1 {
                set values_idx_next [expr {$values_idx+1}]
                if { ![dict exists $itemDict values_idx $values_idx_next] } {
                    dict unset itemDict values_idx $values_idx_next
                    break
                }
                set item [dict get $itemDict values_idx $values_idx_next]
                dict set itemDict values_idx $values_idx $item
                dict set itemDict item $item $values_idx
                set values_idx $values_idx_next
            }
            lappend itemList {*}[$tree item children $item]
            $tree item delete $item
        }
    }
    method get_selected_comma_list { args } {
        set optional {
            { -varname name "" }
        }
        set compulsory ""
        parse_args $optional $compulsory $args

        set ret ""
        set map [list "," "&#44;"]
        foreach elm [$self cget -values] {
            if { [lindex $elm 1] eq "on" } {
                lappend ret [string map $map [lindex $elm 0]]
            }
        }
        if { $varname ne "" } {
            uplevel 1 [list set $varname [join $ret ","]]
        } else {
            return [join $ret ","]
        }
    }
    method set_selected_comma_list { args } {
        set optional {
            { -varname name "" }
            { -insert "" 0 }
        }
        set compulsory "data"
        set args [parse_args -raise_compulsory_error 0 \
                $optional $compulsory $args]
        
        if { $varname ne "" } {
            set data [uplevel 1 [list set $varname]]
        }
        set map [list "&#44;" "," "&comma;" ","]
        set list ""
        foreach i [split $data ","] {
            lappend list [string map $map $i]
        }
        set list [lsort $list]
        
        foreach i [range 0 [llength $options(-values)]] {
            set elm [lindex $options(-values) $i]
            lassign $elm name state parentName open_close
            
            set item [dict get $itemDict values_idx $i]

            if { [llength [lindex $options(-values) $i]] < 2 } {
                set v [list [lindex $options(-values) $i 0] on]
                lset options(-values) $i $v
            }
            if { [lsearch -sorted $list $name] != -1 } {
                $tree item state set $item on
                lset options(-values) $i 1 on
            } else {
                $tree item state set $item !on
                lset options(-values) $i 1 off
            }
        }
        if { $insert } {
            set changes 0
            set values $options(-values)
            foreach i $list {
                if { [lsearch -index 0 $values $i] == -1 } {
                    lappend values [list $i on "" open]
                    set changes 1
                }
            }
            if { $changes } {
                $self configure -values $values
            }
        }
    }
    method _insert { index list values_idx } {

        set imgState [list \
                [cu::get_image_selected internet-check-on] {selected check on} \
                [cu::get_image_selected internet-check-off] {selected check} \
                [cu::get_image internet-check-on] {check on} \
                [cu::get_image internet-check-off] {check} \
                ]
        
        lassign $list name state parentName open_close
        
        if { $parentName eq "" } {
            set parent 0
        } else {
            set parent [dict get $itemDict name $parentName]
        }
        set newlist [list [list ::cu::images::internet-check-off $name]]
        set item [$tree insert $index $newlist $parent]
        
        dict set itemDict name $name $item
        dict set itemDict item $item $values_idx
        dict set itemDict values_idx $values_idx $item

        $tree item state set $item check
        if { $state eq "on" } {
            $tree item state set $item on
        }
        switch $open_close {
            open { $tree item expand $item }
            close { $tree item collapse $item }
            disabled { $tree item enabled $item 0 }
        }
        $tree item element configure $item 0 e_image -image $imgState
        return $item
    }
    method _recursive_change_state { item state } {
        $tree item state set $item $state
        foreach child [$tree item children $item] {
            $self _recursive_change_state $child $state
        }
    }
    method add_exclusive_item { name } {
        
        set item [dict get $itemDict name $name]
        dict set exclusiveDict $item [$tree item state get $item on]
    }
    method set_state { itemList state } {
        set sel [lsort -integer $itemList]
        foreach item $sel {
            $self _recursive_change_state $item $state
        }
    }
    method _selection { _tree ids } {
        
        set sel [lsort -integer $ids]
        
        foreach item [dict keys $exclusiveDict] {
            dict set exclusiveDict $item [$tree item state get $item on]
        }
        set num_activated 0
    
        if { $sel eq $prev_selection } {
            set item active
            if { [$tree item state get $item on] } {
                $self _recursive_change_state $item !on
            } else {
                $self _recursive_change_state $item on
                incr num_activated
            }
        } else {
            foreach item $sel {
                if { [lsearch -integer -sorted $prev_selection $item] == -1 } {
                    if { [$tree item state get $item on] } {
                        $self _recursive_change_state $item !on
                    } else {
                        $self _recursive_change_state $item on
                        incr num_activated
                    }
                }
            }
        }
        set prev_selection $sel
        
        foreach item [dict keys $exclusiveDict] {
            set new_state [$tree item state get $item on]
            if { $new_state && ![dict get $exclusiveDict $item] } {
                foreach child [$tree item children 0] {
                    $self _recursive_change_state $child !on
                }
                foreach item_in [dict keys $exclusiveDict] {
                    dict set exclusiveDict $item_in 0
                }
                $tree item state set $item on
                dict set exclusiveDict $item 1
                return
            }
        }
        if { $num_activated } {
            foreach item [dict keys $exclusiveDict] {
                $tree item state set $item !on
                dict set exclusiveDict $item 0
            }
        }
    }
}

################################################################################
# cu::multiline_entry
################################################################################

snit::widget cu::multiline_entry {
    option -textvariable ""
    option -takefocus 0 ;# option used by the tab standard bindings
    option -values ""
    option -valuesvariable ""
    option -state ""
    option -justify ""
    option -height ""

    hulltype frame

    variable text
    variable updating 0
    
    variable toctree
    variable fnames ""
    variable no_active_items ""
    variable no_active_values ""
    variable cmd_items ""
    
    delegate method * to text
    delegate method _insert to text as insert
    delegate option * to text
    delegate option -_state to text as -state
    delegate option -_height to text as -height
    
    delegate method tree_item to toctree as item
    delegate option -columns_list to toctree
    
    constructor args {

        $hull configure -background #a4b97f -bd 0
        install text using text $win.t -wrap word -width 40 -height 3 -borderwidth 0 -highlightthickness 0
        
        cu::add_contextual_menu_to_entry $text init

        grid $text -padx 1 -pady 1 -sticky nsew
        grid columnconfigure $win 0 -weight 1
        grid rowconfigure $win 0 -weight 1

        bind $self <Configure> [mymethod _check_configure]
        bind $text <Tab> "[bind all <Tab>] ; break"
        bind $text <<PrevWindow>> "[bind all <<PrevWindow>>] ; break"
        bind $text <KeyPress> [mymethod keypress]
        bindtags $text [list $win $text [winfo class $win] [winfo class $text] [winfo toplevel $text] all]
        bind $win <FocusIn> [list focus $text]
        $self configurelist $args
    }
    destructor {
        $self _clean_traces
    }
    onconfigure -state {value} {
        set options(-state) $value
        $self _update_state
    }
    onconfigure -height {value} {
        set options(-height) $value
        
        $self configure -_height [lindex $value 0]
    }
    onconfigure -textvariable {value} {
        $self _clean_traces
        set options(-textvariable) $value

        set cmd "[mymethod _check_textvariable_read] ;#"
        trace add variable $options(-textvariable) read $cmd
        set cmd "[mymethod _check_textvariable_write] ;#"
        trace add variable $options(-textvariable) write $cmd
        $self _check_textvariable_write
    }
    onconfigure -values {value} {
        set options(-values) $value
        
        if { $options(-values) ne "" || $options(-valuesvariable) ne "" } {
            $self activate_menubutton

            $self tree_item delete all
            $self tree_insert end [_ "(Clear)"] "" 0
            foreach i $value {
                $self tree_insert end $i $i 0
            }
        } elseif { ![winfo exists $win.b] } {
            destroy $win.b
        }
    }
    onconfigure -valuesvariable {value} {
        set options(-valuesvariable) $value

        
        if { $options(-values) ne "" || $options(-valuesvariable) ne "" } {
            $self activate_menubutton
        }
        upvar #0 $options(-valuesvariable) v

        if { [info exists v] } {
            $self _changed_values_var
            trace add variable v write "[mymethod _changed_values_var];#"
        } elseif { ![winfo exists $win.b] } {
            destroy $win.b
        }
    }
    method activate_menubutton {} {

        if { [winfo exists $win.b] } { return }

        if { [info command ::cu::multiline_entry::nav1downarrow16] eq "" } {
            image create photo ::cu::multiline_entry::nav1downarrow16 -data {
                R0lGODlhEAAQAIAAAPwCBAQCBCH5BAEAAAAALAAAAAAQABAAAAIYhI+py+0PUZi0zmTtypflV0Vd
                RJbm6fgFACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNpb24gMi41DQqpIERldmVsQ29y
                IDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29t
                ADs=
            }
        }
        ttk::menubutton $win.b -image ::cu::multiline_entry::nav1downarrow16 -style Toolbutton
        
        bind $win.b <ButtonPress-1> [mymethod BP1 %x %y]
        bind $win.b <ButtonRelease-1> [mymethod BR1 %x %y]
        
        set toctree $win.b.m
        cu::_menubutton_tree_helper $toctree -parent $win \
            -button1handler [mymethod press] -returnhandler [mymethod press_return]
        wm withdraw $toctree
        
        bind  $win.b.m <space> [mymethod post]
        bind  $win.b.m <Return> [mymethod post]
        
        bind $toctree <<ComboboxSelected>> [mymethod endpost]
        
        grid $win.b -row 0 -column 1 -padx "0 1" -pady 1 -sticky wns
    }
    method give_win {} {
        return $text
    }
    method give_tree {} {
        return $toctree
    }
    method set_text { txt } {
        focus $text
        update idletasks
        $text delete 1.0 end
        $text insert end $txt
        $text tag add sel 1.0 end-1c
        $self _check_configure
        $self _update_state
    }
    method insert { args } {
        $self _insert {*}$args
        $self _check_configure
        $self _update_state
    }
    method keypress {} {
        after idle [mymethod _check_configure]
        after idle [mymethod _update_state]
    }
    method _update_state {} {
        
        switch $options(-state) {
            disabled {
                $self configure -_state disabled -foreground grey -highlightthickness 0
                grid configure $text -padx 1 -pady 1
            }
            readonly {
                $self configure -_state disabled -foreground black -highlightthickness 0
                grid  configure $text -padx 0 -pady 0
            }
            default {
                $self configure -_state normal -foreground black -highlightthickness 1
                grid  configure $text -padx 1 -pady 1
            }
        }
        if { $options(-justify) ne "" } {
            $self tag configure justify -justify $options(-justify)
            $self tag add justify 1.0 end
        }
    }
    method _clean_traces {} {
        if { $options(-textvariable) ne "" } {
            set cmd "[mymethod _check_textvariable_read] ;#"
            trace remove variable $options(-textvariable) read $cmd
            set cmd "[mymethod _check_textvariable_write] ;#"
            trace remove variable $options(-textvariable) write $cmd
        }
        if { $options(-valuesvariable) ne "" } {
            upvar #0 $options(-valuesvariable) v
            trace remove variable v write "[mymethod _changed_values_var];#"
        }
    }
    method BP1 { x y } {
       $self post
    }
    method BR1 { x y } {
        $win.b instate {pressed !disabled} {
            $win.b state !pressed
        }
        return -code break
    }
    method press_return { t ids } {
        $self press $t $ids [list item [lindex $ids 0] column 0 elem e_text_sel] "" ""
    }
    method press { t ids identify x y } {
        set id [lindex $ids 0]
        
        if { ![regexp {item \S+ column \S+ elem (\S+)} $identify {} elem] } {
            return
        }
        if { $elem eq "e_image_r" } {
            return [$self clear_tree_entry $id]
        }
        if { [dict exists $cmd_items $id] } {
            if { ![dict exists $no_active_items $id] } { 
                $self action LBCancel
            }
            uplevel #0 [dict get $cmd_items $id] $id
            return
        }
        if { [dict exists $no_active_items $id] } { return }
        
        $self set_text [dict get $fnames $id]
        #uplevel #0 $options(-command) [list [dict get $fnames $id]]
        $toctree unpost
    }
    method clear_tree_entry { id } {
        set txt [dict get $fnames $id]
        if { $options(-textvariable) ne "" } {
            upvar #0 $options(-valuesvariable) v
            set ipos [lsearch -exact $v $txt]
            set v [lreplace $v $ipos $ipos]
        } else {
            error "error in clear_tree_entry. not implemented"
        }
    }
    method post {} {
        $win.b instate !disabled {
            catch { tile::clickToFocus $win.b }
            catch { ttk::clickToFocus $win.b }
            $win.b state pressed
            set x [winfo rootx $win]
            set y [expr {[winfo rooty $win]+[winfo height $win]}]
            $toctree deiconify $x $y [expr {[winfo width $win]-0}]
        }
    }
    method endpost {} {
        $win.b instate {pressed !disabled} {
            $win.b state !pressed
        }
        event generate $win.b <<ComboboxSelected>>
    }
    method _check_textvariable_read {} {
        if { $updating } { return }
        upvar #0 $options(-textvariable) v
        set v [$text get 1.0 end-1c]
    }
    method _check_textvariable_write {} {
        upvar #0 $options(-textvariable) v
        $text delete 1.0 end
        set updating 1
        if { [info exists v] } {
            $text insert end $v
        }
        set updating 0
        $self _check_configure
        $self _update_state
    }
    method _changed_values_var {} {
        if { $options(-valuesvariable) ne "" } {
            upvar #0 $options(-valuesvariable) v
            
            $self tree_item delete all
            $self tree_insert end [_ "(Clear)"] "" 0
            foreach i $v {
                $self tree_insert end $i $i 0
            }
        }
    }
    method _check_configure {} {
        
        if { [winfo width $win] <= 1 } { return }
        if { [llength $options(-height)] < 2 } { return }
        set ds [$win count -displaylines 1.0 end]
        lassign $options(-height) min max
        if { $ds < $min } { set ds $min }
        if { $ds > $max } { set ds $max }
        if { $ds != [$win cget -_height] } {
            $win configure -_height $ds
        }
    }
    method tree_insert { args } {
        set optional {
            { -image image "" }
            { -collapse boolean 0 }
            { -active boolean 1 }
            { -command cmd "" }
        }
        set compulsory "idx name fullname parent"
        parse_args $optional $compulsory $args

        if { $image eq "" } {
            set image appbook16
        } elseif { $image eq "-" } {
            set image ""
        }
        if { [$self cget -columns_list] eq "" } {
            set data [list [list $image $name]]
        } else {
            set data [list [list $image [lindex $name 0]]]
            lappend data {*}[lrange $name 1 end]
        }
        set id [$toctree insert $idx $data $parent]
        if { $collapse } {
            $toctree item collapse $id
        }
        if { !$active } {
            dict set no_active_items $id ""
            dict set no_active_values $fullname ""
        }
        if { ![info exists cmd_items] } {
            set cmd_items ""
        }
        if { $command ne "" } {
            dict set cmd_items $id $command
        }
        dict set fnames $id $fullname
        
        $toctree item style set $id 0 imagetextimage
        $toctree item element configure $id 0 e_text_sel -text $name
        $toctree item element configure $id 0 e_image -image $image
        catch {
            $toctree item element configure $id 0 e_image_r -image [cu::get_image actitemdelete16]
        }
        return $id
    }
}

################################################################################
#    menubutton_tree
################################################################################

snit::widget cu::_menubutton_tree_helper {
    option -parent ""
    option -columns_list ""
    hulltype toplevel
    
    delegate method * to tree
    delegate option * to tree

    variable tree
    variable marker_resize_xy0

    constructor args {
        wm overrideredirect $win 1

        package require fulltktree
        set columns [list [list 20 "" left imagetext 1]]
        set tree [fulltktree $win.tree -height 50 -has_sizegrip 1 \
                -columns $columns -expand 1]
        
        grid $tree -sticky nsew
        grid columnconfigure $win 0 -weight 1
        grid rowconfigure $win 0 -weight 1
        
        $self configure -bd 1 -relief solid -background white
        $self configurelist $args

        grid configure $tree.t -rowspan 2

        bind $win <ButtonPress-1> [mymethod check_unpost %x %y]
        bind $win <Escape> "[mymethod unpost] ; break"
    }
    onconfigure -columns_list { value } {
        if { $value eq $options(-columns_list) } { return }
        set options(-columns_list) $value

        set columns ""
        set idx 0
        foreach i $options(-columns_list) {
            lassign $i name dict
            if { $idx == 0 } {
                set type imagetext
            } else {
                set type text
            }
            foreach "opt default" [list len 10 justify left is_editable 1 expand ""] {
                set $opt [dict_getd $dict $opt $default]
            }
            lappend columns [list $len $name $justify $type $is_editable $expand]
            incr idx
        }
        $tree configure -expand 0 -columns $columns
    }
    method deiconify { x y min_width } {
                
        set n [$tree index last]
        if { $n < 7 } { set n 7 }
        if { $n > 15 } { set n 15 }
        if { [$tree cget -itemheight] != 0 } {
            set h [expr {[$tree cget -itemheight]*$n}]
        } else {
            set h [expr {[$tree cget -minitemheight]*$n}]
        }
        $tree configure -height $h
        set wi [winfo width $win]
        if { $wi < $min_width } { set wi $min_width }
        if { $wi+$x > [winfo screenwidth $win] } {
            set wi [expr {[winfo screenwidth $win]-$x}]
        }
        if { $y+$h+10 > [winfo screenheight $win] } {
            set h [expr {[winfo screenheight $win]-$y-10}]
        }
        wm geometry $win ${wi}x$h+$x+$y
        update
        wm deiconify $win
        focus $tree
        grab -global $win
    }
    method check_unpost { x y } {
        if { $x < 0 || $x > [winfo width $win] || 
            $y < 0 || $y > [winfo height $win] } {
            $self unpost
        }
    }
    method unpost {} {
        
        $tree close_search_label

        grab release $win
        wm withdraw $win
        event generate $win <<ComboboxSelected>> 
    }
}

################################################################################
#    cu::adapt_text_length
################################################################################

# remember to grid the label to fill all space. For example with -sticky ew
proc cu::adapt_text_length { args } {
    foreach w $args {
        bind $w <Configure> [list cu::_adapt_text_length_do $w]
    }
}

proc cu::_adapt_text_length_do { w } {
    if { [winfo width $w] > 1 } {
        $w configure -wraplength [winfo width $w] -justify left
    }
}

################################################################################
#    add_contextual_menu_to_entry
################################################################################

proc cu::add_contextual_menu_to_entry { w what args } {
    switch $what {
        init {
            bind $w <ButtonRelease-3> [list cu::add_contextual_menu_to_entry $w post %X %Y]
        }
        post {
            lassign $args x y
            set menu $w.menu
            catch { destroy $menu }
            menu $menu -tearoff 0
            foreach i [list cut copy paste --- select_all --- clear] \
                txt [list [_ "Cut"] [_ "Copy"] [_ "Paste"] --- [_ "Select all"] --- [_ "Clear"]] {
                if { $i eq "---" } {
                    $menu add separator
                } else {
                    $menu add command -label $txt -command [list cu::add_contextual_menu_to_entry $w $i]
                }
            }
            tk_popup $menu $x $y
        }
        clear {
            if { [winfo class $w] eq "Text" } {
                $w delete 1.0 end
            } else {
                $w delete 0 end
            }
        }
        cut {
            event generate $w <<Cut>>
        }
        copy {
            event generate $w <<Copy>>
        }
        paste {
            event generate $w <<Paste>>
        }
        select_all {
            if { [winfo class $w] eq "Text" } {
                $w tag add sel 1.0 end-1c
            } else {
                $w selection range 0 end
            }
        }
    }
}

################################################################################
#     cu::text_entry_bindings
################################################################################

proc cu::text_entry_bindings { w } {

    if { ![info exists ::control] } {
        if { $::tcl_platform(platform) eq "windows" } {
            set ::control Control
        } elseif { [tk windowingsystem] eq "aqua" } {
            set ::control Command
        } else {
            set ::control Control
        }
    }
    # "backslash" and "c" are here to help with a problem in Android VNC
    bind $w <$::control-backslash> "[list cu::text_entry_insert $w];break"
    bind $w <$::control-less> "[list cu::text_entry_insert $w];break"
    foreach "acc1 acc2 c" [list plus "" {[]} c "" {{}} ccedilla "" {{}} 1 "" || 1 1 \\ 3 "" {#}] {
        set cmd "[list cu::text_entry_insert $w $c];break"
        if { $acc2 eq "" } {
            set k2 ""
        } else {
            set k2 <KeyPress-$acc2>
        }
        bind $w <$::control-less><KeyPress-$acc1>$k2 $cmd
        bind $w <$::control-backslash><KeyPress-$acc1>$k2 $cmd
    }
    
    if { $::tcl_platform(platform) ne "windows" } {
        foreach "ev k" [list braceleft \{ braceright \} bracketleft \[ bracketright \] backslash \\ \
                bar | at @ numbersign # asciitilde ~] {
            # EuroSign €
            # they are class bindings so as search in text widgets can continue working
            bind Text <$ev> "[list tk::TextInsert %W $k]; break"
            bind TEntry <$ev> "[list ttk::entry::Insert %W $k]; break"
            bind TCombobox <$ev> "[list ttk::entry::Insert %W $k]; break"
            bind Entry <$ev> "[list tk::EntryInsert %W $k]; break"
        }
    }
}

proc cu::text_entry_insert { w { what "" } } {
    variable last_text_enty_bindings
    
    if { ![info exists last_text_enty_bindings] } {
        set last_text_enty_bindings ""
    }
    set list [list "{}" "\[\]" "||" "\\" "#"]
    set t [clock milliseconds]
    lassign [dict_getd $last_text_enty_bindings $w ""] time d
    
    if { $d eq "" } { set d "{}" }
    if { $time ne "" && $t < $time+3000 } {
        if { [winfo class $w] eq "Text" } {
            set idx [$w search $d insert-1c]
            if { [$w compare $idx == insert-1c] } {
                if { [string length $d] == 1 } {
                    $w delete insert-1c
                } else {
                    $w delete insert-1c insert+1c
                }
            }
        } else {
            set idx [$w index insert]
            if { $idx > 0 } {
                set idx1 [expr {$idx-1}]
                set idx2 [expr {$idx-1+[string length $d]}]
                set txt [string range [$w get] $idx1 $idx2]
                if { [string equal $d $txt] } {
                    $w delete $idx1 $idx2
                }
            }
        }
        if { $what eq "" } {
            set ipos [lsearch -exact $list $d]
            incr ipos
            if { $ipos >= [llength $list] } {
                set ipos 0
            }
            set d [lindex $list $ipos]
        }
    }
    if { $what ne "" } {
        set d $what
    }
    if { [winfo class $w] eq "Text" } {
        set idx [$w index insert]
        $w insert insert $d
        $w mark set insert "$idx+1c"
    } else {
        set idx [$w index insert]
        $w insert insert $d
        $w icursor [expr {$idx+1}]
    }
    dict set last_text_enty_bindings $w [list $t $d]
}

################################################################################
#     cu::text operations on text widget
################################################################################

namespace eval cu::text {}

proc cu::text::get_selection_or_word { args } {
    
    set optional {
        { -return_range boolean 0 }
    }
    set compulsory "text idx"
    parse_args $optional $compulsory $args
    
    set range [$text tag ranges sel]
    if { $range != "" && [$text compare [lindex $range 0] <= $idx] && \
        [$text compare [lindex $range 1] >= $idx] } {
        if { $return_range } {
            return $range
        } else {
            return [$text get {*}$range]
        }
    } else {
        if { $idx != "" } {
            set var ""
            set idx0 $idx
            set char [$text get $idx0]
            if { [regexp {[\s,;]} $char] } {
                set c [$text get "$idx0-1c"]
                if { [string is wordchar $c] } {
                    set idx [$text index "$idx0-1c"]
                    set idx0 $idx
                    set char [$text get $idx0]
                }
            }
            while { [string is wordchar $char] } {
                #  || $char == "(" || $char == ")"
                set var $char$var
                set idx0 [$text index $idx0-1c]
                if { [$text compare $idx0 <= 1.0] } { break }
                set char [$text get $idx0]
            }
            set idx1 [$text index $idx+1c]
            set char [$text get $idx1]
            while { [string is wordchar $char] } {
                #  || $char == "(" || $char == ")"
                append var $char
                set idx1 [$text index $idx1+1c]
                if { [$text compare $idx1 >= end-1c] } { break }
                set char [$text get $idx1]
            }
            if { ![regexp {[^()]*\([^\)]+\)} $var] } {
                set var [string trimright $var "()"]
            }
        } else { set var "" }
    }
    if { $return_range } {
        return [list [$text index "$idx0+1c"] [$text index "$idx1"]]
    } else {
        return $var
    }
}

################################################################################
#    store preferences
################################################################################

proc cu::store_program_preferences { args } {

    set optional {
        { -valueName name "" }
    }
    set compulsory "program_name data"

    parse_args $optional $compulsory $args

    if { $valueName eq "" } {
        set valueNameF IniData
    } else {
        set valueNameF IniData_$valueName
    }

    if { $::tcl_platform(platform) eq "windows" && $::tcl_platform(os) ne "Windows CE" } {
        set key "HKEY_CURRENT_USER\\Software\\Compass\\$program_name"
        package require registry
        registry set $key $valueNameF $data
    } else {
        package require tdom
        if { $::tcl_platform(os) eq "Windows CE" } {
            set dir [file join / "Application Data" Compass $program_name]
            file mkdir $dir
            set file [file join $dir prefs]
        } elseif { [info exists ::env(HOME)] } {
            set file [file normalize ~/.compass_${program_name}_prefs]
        } else {
            set file [file normalize [file join /tmp compass_${program_name}_prefs]]
        }
        set err [catch { tDOM::xmlReadFile $file } xml]
        if { $err } { set xml "<preferences/>" }
        set doc [dom parse $xml]
        set root [$doc documentElement]
        set domNode [$root selectNodes "pref\[@n=[xpath_str $valueNameF]\]"]
        if { $domNode ne "" } { $domNode delete }
        set p [$root appendChildTag pref]
        $p setAttribute n $valueNameF
        $p appendChildText $data

        set fout [open $file w]
        fconfigure $fout -encoding utf-8
        puts $fout [$doc asXML]
        close $fout
    }
}
proc cu::get_program_preferences { args } {

    set optional {
        { -valueName name "" }
        { -default default_value "" }
    }
    set compulsory "program_name"

    parse_args $optional $compulsory $args

    if { $valueName eq "" } {
        set valueNameF IniData
    } else {
        set valueNameF IniData_$valueName
    }

    set data $default
    if { $::tcl_platform(platform) eq "windows" && $::tcl_platform(os) ne "Windows CE" } {
        set key "HKEY_CURRENT_USER\\Software\\Compass\\$program_name"
        package require registry
        set err [catch { registry get $key $valueNameF } data]
        if { $err } {
            set data $default
        }
    } else {
        package require tdom
        if { $::tcl_platform(os) eq "Windows CE" } {
            set dir [file join / "Application Data" Compass $program_name]
            file mkdir $dir
            set file [file join $dir prefs]
        } elseif { [info exists ::env(HOME)] } {
            set file [file normalize ~/.compass_${program_name}_prefs]
        } else {
            set file [file normalize [file join /tmp compass_${program_name}_prefs]]
        }
        set err [catch { tDOM::xmlReadFile $file } xml]
        if { !$err } {
            set doc [dom parse $xml]
            set root [$doc documentElement]
            set domNode [$root selectNodes "pref\[@n=[xpath_str $valueNameF]\]"]
            if { $domNode ne "" } {
                set data [$domNode text]
            }
        }
    }
    return $data
}

################################################################################
#    cu::set_window_geometry u::give_window_geometry
################################################################################

proc cu::give_window_geometry { w } {

    regexp {(\d+)x(\d+)([-+])([-\d]\d*)([-+])([-\d]+)} [wm geometry $w] {} width height m1 x m2 y
    if { $::tcl_platform(platform) eq "unix" } {
        # note: this work in ubuntu 9.04
        incr x -4
        incr y -24
    }
    return ${width}x$height$m1$x$m2$y
}

proc cu::set_window_geometry { w geometry } {

    if { ![regexp {(\d+)x(\d+)([-+])([-\d]\d*)([-+])([-\d]+)} $geometry {} width height m1 x m2 y] } {
        regexp {(\d+)x(\d+)} $geometry {} width height
        lassign [list 0 0 + +] x y m1 m2
    }
    if { $x < 0 } { set x 0 }
    if { $y < 0 } { set y 0 }
    if { $x > [winfo screenwidth $w]-100 } { set x [expr {[winfo screenwidth $w]-100}] }
    if { $y > [winfo screenheight $w]-100 } { set y [expr {[winfo screenheight $w]-100}] }
    
    if { $m2 eq "+" && $y+$height > [winfo screenheight $w] } {
        if { $y > 0.5*[winfo screenheight $w] } {
            set y [expr {round(0.5*[winfo screenheight $w])}]
        }
        set height [expr {[winfo screenheight $w]-$y}]
    }
    wm geometry $w ${width}x$height$m1$x$m2$y
}

proc cu::create_tooltip_toplevel { args } {

    set optional {
        { -withdraw "" 0 }
    }
    set compulsory "b"
    parse_args $optional $compulsory $args

    toplevel $b -class Tooltip
    if { $withdraw } {
        wm withdraw $b
    }
    if {[tk windowingsystem] eq "aqua"} {
        ::tk::unsupported::MacWindowStyle style $b help none
    } else {
        wm overrideredirect $b 1
    }
    catch {wm attributes $b -topmost 1}
    # avoid the blink issue with 1 to <1 alpha on Windows
    catch {wm attributes $b -alpha 0.99}
    wm positionfrom $b program
    if { [tk windowingsystem]  eq "x11" } {
        set focus [focus]
        focus -force $b
        raise $b
        if { $focus ne "" } {
            after 100 [list focus -force $focus]
        }
    }
    return $b
}

proc cu::give_widget_background { w } {
 
    set err [catch { $w cget -background } bgcolor]
    if { $err } {
        set err [catch {
                set style [$w cget -style]
                if { $style eq "" } {
                    set style [winfo class $w]
                }
                set bgcolor [ttk::style lookup $style -background]
            }]
        if { $err } {
            if { $::tcl_platform(platform) eq "windows" } {
                set bgcolor SystemButtonFace
            } else {
                set bgcolor grey
            }
        }
    }
   return $bgcolor
}

################################################################################
#    add_down_arrow_to_image
################################################################################

proc cu::add_down_arrow_to_image { args } {
    variable add_down_arrow_to_image_delta
    
    set optional {
        { -color color black }
        { -w widget "" }
    }
    set compulsory "img"
    parse_args $optional $compulsory $args

    if {![info exists add_down_arrow_to_image_delta] } {
        set add_down_arrow_to_image_delta 7
    }
    if { $img ne "" } {
        set width [image width $img]
        set height [image height $img]
    } else {
        lassign [list 0 16] width height
    }
    set new_img [image create photo -width [expr {$width+$add_down_arrow_to_image_delta}] -height $height]
    if { $img ne "" } { $new_img copy $img -to 0 0 }
    set coords {
        -3 -1
        -4 -2 -3 -2 -2 -2
        -5 -3 -4 -3 -3 -3 -2 -3 -1 -3
    }
    foreach "x y" $coords {
        $new_img put $color -to [expr {$width+$add_down_arrow_to_image_delta+$x}] [expr {$height+$y}]
    }
    if { $w ne "" } {
        $w configure -image $new_img
        bind $w <Destroy> +[list image delete $new_img]
    }
    return $new_img
}

################################################################################
#    XML & xpath utilities
################################################################################

proc xpath_str { str } {
    
    foreach "strList type pos" [list "" "" 0] break
    while 1 {
        switch $type {
            "" {
                set ret [regexp -start $pos -indices {['"]} $str idxs]
                if { !$ret } {
                    lappend strList "\"[string range $str $pos end]\""
                    break
                }
                set idx [lindex $idxs 0]
                switch -- [string index $str $idx] {
                    ' { set type apostrophe }
                    \" { set type quote }
                }
            }
            apostrophe {
                set ret [regexp -start $pos -indices {["]} $str idxs]
                if { !$ret } {
                    lappend strList "\"[string range $str $pos end]\""
                    break
                }
                set idx [lindex $idxs 0]
                lappend strList "\"[string range $str $pos [expr {$idx-1}]]\""
                set type quote
                set pos $idx
            }
            quote {
                set ret [regexp -start $pos -indices {[']} $str idxs]
                if { !$ret } {
                    lappend strList "'[string range $str $pos end]'"
                    break
                }
                set idx [lindex $idxs 0]
                lappend strList "'[string range $str $pos [expr {$idx-1}]]'"
                set type apostrophe
                set pos $idx
            }
        }
    }
    if { [llength $strList] > 1 } {
        return "concat([join $strList ,])"
    } else {
        return [lindex $strList 0]
    }
}

proc format_xpath { string args } {
    set cmd [list format $string]
    foreach i $args {
        lappend cmd [xpath_str $i]
    }
    return [eval $cmd]
}

namespace eval ::dom::domNode {}

# args can be one or more tags
proc ::dom::domNode::appendChildTag { node args } {
    if { [::llength $args] == 0 } {
        error "error in appendChildTag. At list one tag"
    }
    ::set doc [$node ownerDocument]
    foreach tag $args {
        if { [string match "text() *" $tag] } {
            ::set newnode [$doc createTextNode [lindex $tag 1]]
            $node appendChild $newnode
            ::set node $newnode
        } elseif { [string match "attributes() *" $tag] } {
            foreach "n v" [lrange $tag 1 end] {
                $node setAttribute $n $v
            }
        } else {
            ::set newnode [$doc createElement $tag]
            $node appendChild $newnode
            ::set node $newnode
        }
    }
    return $newnode
}

proc ::dom::domNode::appendChildText { node text } {
    ::set doc [$node ownerDocument]
    foreach child [$node selectNodes text()] { $child delete }
    ::set newnode [$doc createTextNode $text]
    $node appendChild $newnode
    return $newnode
}

proc dict_getd { args } {
    
    set dictionaryValue [lindex $args 0]
    set keys [lrange $args 1 end-1]
    set default [lindex $args end]
    if { [dict exists $dictionaryValue {*}$keys] } {
        return [dict get $dictionaryValue {*}$keys]
    }
    return $default
}

proc linsert0 { args } {
    set optional {
        { -max_len len "" }
        { -remove_prefixes "" 0 }
    }
    set compulsory "list element"
    parse_args $optional $compulsory $args

    set ipos [lsearch -exact $list $element]
    if { $ipos != -1 } {
        set list [lreplace $list $ipos $ipos]
    }
    if { $remove_prefixes } {
        for { set i 0 } { $i < [llength $list] } { incr i } {
            if { [string match "[lindex $list $i]*" $element] } {
                set list [lreplace $list $i $i]
                incr i -1
            }
        }
    }
    set list [linsert $list 0 $element]
    if { $max_len ne "" } {
        set list [lrange $list 0 $max_len-1]
    }
    return $list
}

################################################################################
#     cu::file::execute, cu::kill and cu::ps
################################################################################

proc cu::kill { pid } {

    if { $::tcl_platform(platform) eq "windows" } {
        package require compass_utils::c
        return [cu::_kill_win $pid]
    } else {
        exec kill $pid 
    }
}

proc cu::ps { args } {

    if { $::tcl_platform(platform) eq "windows" } {
        package require compass_utils::c
        set ps_args ""
        foreach i $args {
            if { $i eq "" } { continue }
            if { ![string is integer -strict $i] } {
                if { ![regexp {^\*} $i] } {
                    set i "*$i"
                }
                if { ![regexp {\*$} $i] } {
                    set i "$i*"
                }
            }
            lappend ps_args $i
        }
        set ret [cu::_ps_win {*}$ps_args]
        catch { package require twapi }
        set retret ""
        foreach i $ret {
            lassign $i cmd pid
            if { [info command ::twapi::get_process_info] ne "" } {
                set d [twapi::get_process_info $pid -createtime -privilegedtime -workingset]
                if { [string is digit -strict [dict get $d -createtime]] } {
                    set start [clock format [twapi::large_system_time_to_secs [dict get $d -createtime]] \
                            -format "%H:%M:%S"]
                    set cputime [clock format [twapi::large_system_time_to_secs \
                                [dict get $d -privilegedtime]] -format "%H:%M:%S" -timezone :UTC]
                    set size [expr {[dict get $d -workingset]/1024}]
                    set i [list $cmd $pid $start $cputime $size]
                }
            }
            lappend retret $i
        }
        return $retret
    } else {
        # does not do exactly the same than in Windows
        #set err [catch { exec pgrep -l -f [lindex $args 0] } ret]
        #set retList  [split $ret \n]
        lassign $args pattern
        if { $pattern eq "" } {
            set err [catch { exec ps -u $::env(USER) --no-headers -o pid,start,time,pcpu,size,cmd } ret]
        } elseif { [string is integer -strict $pattern] } {
            set err [catch { exec ps --pid $pattern --no-headers -o pid,start,time,pcpu,size,cmd } ret]
        } else {
            set err [catch { exec ps -u $::env(USER) --no-headers -o pid,start,time,pcpu,size,cmd | grep -i $pattern } ret]
        }        
        if { $err } {
            return ""
        } else {
            set retList ""
            foreach line [split $ret \n] {
                regexp {(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)} $line {} pid start cputime \
                    pcpu size cmd
                catch { format "%02.0f%%" $pcpu } pcpu
                if { $pattern ne "" && $cmd eq "grep -i $pattern" } { continue }

                set err [catch { clock scan $start -format "%H:%M:%S" } secs]
                if { $err } {
                    set secs [clock scan $start -format "%b"]
                }
                set start [clock format $secs -format "%Y-%m-%d %H:%M:%S"]
                lappend retList [list $cmd $pid $start "$cputime ($pcpu)" $size]
            }
            return $retList
        }
    }
}

proc cu::file::correct_name { file } {
    if { $::tcl_platform(platform) eq "windows" } {
        regsub -all {[:*?""<>|]} $file {_} file
    }
    return [string trim $file]
}

proc cu::file::execute { args } {
    
    set optional {
        { -workdir directory "" }
        { -wait boolean 0 }
        { -hide_window boolean 0 }
    }
    set compulsory "what file"

    set args [parse_args -raise_compulsory_error 0 $optional $compulsory $args]

    switch -- $what {
        gid {
            set exe [get_executable_path gid]
            if { $exe eq "" } { return }
            if { $wait || $hide_window } {
                set err [catch { package require twapi }]
                if { $err } { set has_twapi 0 } else { set has_twapi 1 }
            }
            if { !$wait || $has_twapi } { lappend args & }
            set pid [exec $exe $file {*}$args]
           
            if { !$wait && !$hide_window } { return }
            if { !$has_twapi } { return }

            if { $hide_window } {
                foreach hwin [twapi::find_windows -pids $pid -visible true] {
                    twapi::hide_window $hwin
                }
            }
            if { $wait } {
                while { [twapi::process_exists $pid] } {
                    after 200
                }
            }
        }
        emacs {
            exec runemacs -g 100x72 &
        }
        wish {
            set pwd [pwd]
            cd [file dirname $file]
            eval exec wish [list [file normalize $file]] $args &
            cd $pwd
        }
        tkdiff {
            set pwd [pwd]
            cd [file dirname $file]
            exec wish ~/myTclTk/tkcvs/bin/tkdiff.tcl -r [file tail $file] &
            cd $pwd
        }
        start {
            if { $::tcl_platform(platform) eq "unix" } {
                set programs [list xdg-open gnome-open]
                if { $::tcl_platform(os) eq "Darwin" } {
                    set programs [linsert $programs 0 open]
                }
                foreach i $programs {
                    if { [auto_execok $i] ne "" } {
                        exec $i $file &
                        return
                    }
                }
                error "could not open file '$file'"
            } elseif { [regexp {[&]} $file] } {
                set bat [file join [file dirname $file] a.bat]
                set fout [open $bat w]
                puts $fout "start \"\" \"$file\""
                close $fout
                exec $bat 
                file delete $bat
            } else {
                eval exec [auto_execok start] \"\" [list $file] {*}$args &
            }
        }
        url {
            if { [regexp {^[-\w.]+$} $file] } {
                set file http://$file
            }
            if { ![regexp {(?i)^\w+://} $file] && ![regexp {(?i)^mailto:} $file] } {
                set txt [_ "url does not begin with a known handler like: %s. Proceed?" \
                        "http:// ftp:// mailto:"]
                set retval [tk_messageBox -default ok -icon question -message $txt \
                        -type okcancel]
                if { $retval == "cancel" } { return }
            }
            if { $::tcl_platform(platform) eq "windows" } {
                exec rundll32 url.dll,FileProtocolHandler $file &
            } else {
                set programs [list xdg-open gnome-open]
                if { $::tcl_platform(os) eq "Darwin" } {
                    set programs [linsert $programs 0 open]
                }
                foreach i $programs {
                    if { [auto_execok $i] ne "" } {
                        exec $i $file &
                        return
                    }
                }
                set cmdList ""
                foreach i [list firefox konqueror mozilla opera netscape] {
                    lappend cmdList "$i \"$file\""
                }
                exec sh -c [join $cmdList "||"] & 
            }
        }
        exec {
            if { $workdir ne "" } {
                set pwd [pwd]
                cd $workdir
            }
            set err [catch { exec $file {*}$args } errstring opts]
            
            if { $err && $::tcl_platform(platform) eq "windows" } {
                package require registry
                set key0 {HKEY_CLASSES_ROOT\Applications\%s\shell\open\command}
                set file [file root [file tail $file]].exe
                set key [format $key0 $file]
                set err [catch { registry get $key "" } value]
                if { !$err } {
                    set cmd [string map [list %1 [lindex $args 0]] $value]
                    regsub -all {\\} $cmd / cmd
                    lappend cmd {*}[lrange $args 1 end]
                    set err [catch { exec {*}$cmd } errstring opts]
                }
            }
            
            if { $workdir ne "" } { cd $pwd }
            if { $err } {
                error $errstring [dict get $opts -errorinfo]
            }
        }
        execList {
            foreach i $file {
                if { [auto_execok [lindex $i 0]] ne "" } {
                    exec {*}$i &
                    return
                }
            }
          error "Could not execute files"
        }
        default {
            if { $workdir ne "" } {
                set pwd [pwd]
                cd $workdir
            }
            set err [catch { exec $file {*}$args & } errstring]
            if { $workdir ne "" } { cd $pwd }
            if { $err } {
                error $errstring $::errorInfo
            }
        }
    }  
}

package require compass_utils::math
package require math::linearalgebra
package require compass_utils

namespace eval m {
    namespace import -force ::math::linearalgebra::*
}

namespace eval svgml {

}

# package re compass_utils::img
# cu::img::clipboard get -type image/x-inkscape-svg

# gid_groups_conds::apply_condition { args } {
#     variable doc
#     
#     set optional {
#         { -ov point|line|surface|volume "" }
#         { -noactualizegroups "" 0 }
#     }
#     set compulsory "xpathCnd group_name values_dict"
# }
# set n1 {container[@n='Properties']/container[@n='Shells']/condition[@n='Isotropic_Shell']}
# set n2 {container[@n='Conditions']/container[@n='Constraints']/condition[@n='Fixed_constraints']}
# set n3 {container[@n='loadcases']/blockdata[@n='loadcase'][1]/container[@n='Shells']/condition[@n='Self_weight_shell']}
# 
# <gidpost_batch version='1.0'>
# <a n="create_line" a="line {{{} 0.0 0.0 0.0} {{} 5 0.0 0.0} {{coords_type {relative {0.0 1 0.0}}}} {{coords_type {relative {-5 0.0 0.0}}}} {{coords_type close} 0.0 0.0 0.0}}" f="1"/>
# <a n='create_surface' a='by_contour {last-3 last-2 last-1 last}'/>
# 
# <a n="start_group" a="" f=""/>
# <a n='create_group' a='-make_name_unique 1 {Name {Isotropic shell Auto}}' f='1'/>
# <a n='add_group_entities' a='{Isotropic shell Auto} {surface last}' f='1'/>
# 
# <a n="gid_groups_conds::addF" a="{$n1} group {n {Isotropic shell Auto}}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n1/group[@n='Isotropic shell Auto']} value {n Thickness pn Thickness unit_magnitude L state {[check_state {Beams_shells Shells Plane_stress Plates Beams_shells_solids All}]} v 0.0 units m}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n1/group[@n='Isotropic shell Auto']} value {n Material pn Material editable 0 values_tree {[give_materials_list -no_has_container material_anisotropic_elastic -has_supra_container Structural]} state {} v {Steel S-355N}}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n1/group[@n='Isotropic shell Auto']} value {n E pn E help {Young modulus} unit_magnitude P state {} v 2.1e11 units N/m^2}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n1/group[@n='Isotropic shell Auto']} value {n nu pn {\u03bd} help {Poisson coefficient} string_is double state {} v 0.3}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n1/group[@n='Isotropic shell Auto']} value {n Specific_weight pn {Specific weight} unit_magnitude F/L^3 state {} v 76930 units N/m^3}" f="1"/>
# <a n="change_group_properties" a="{{Isotropic shell Auto}} type BC" f="1"/>
# <a n="end_group" pn="" a="" f=""/>
# 
# <a n="gid_groups_conds::addF" a="{$n2} group {n {Fixed constraints Auto2} ov point}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']} container {n Activation pn Activation}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n X_Constraint pn {X Constraint} values 1,0 state {[check_state_inv Plates]} v 1}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n Y_Constraint pn {Y Constraint} values 1,0 state {[check_state_inv Plates]} v 1}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n Z_Constraint pn {Z Constraint} values 1,0 state {[check_state_inv {Plane_strain Plane_stress}]} v 1}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n theta_x_Constraint pn {?x Constraint} values 1,0 state {[check_state_inv {Plane_strain Plane_stress Plates Solids}]} v 0}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n theta_y_Constraint pn {?y Constraint} values 1,0 state {[check_state_inv {Plane_strain Plane_stress Solids}]} v 0}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n theta_z_Constraint pn {?z Constraint} values 1,0 state {[check_state_inv {Plane_strain Plane_stress Solids}]} v 1}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Activation']} value {n Local_axes pn {Local axes} values 0,1 editable 0 local_axes disabled help {If the direction to define is not coincident with the global axes, it is possible to define a set of local axes and define the displacements related to that local axes} state {} v 0}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']} container {n Values pn Values}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n X_Value pn {X value} unit_magnitude L state {[check_state_inv Plates]} v 0.0 units m}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n Y_Value pn {Y value} unit_magnitude L state {[check_state_inv Plates]} v 0.0 units m}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n Z_Value pn {Z value} unit_magnitude L state {[check_state_inv {Plane_strain Plane_stress}]} v 0.0 units m}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n theta_x_Value pn {?x value} unit_magnitude Rotation state {[check_state_inv {Plane_strain Plane_stress Plates Solids}]} v 0.0 units deg}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n theta_y_Value pn {?y value} unit_magnitude Rotation state {[check_state_inv {Plane_strain Plane_stress Solids}]} v 0.0 units deg}" f="1"/>
# <a n="gid_groups_conds::addF" a="{$n2/group[@n='Fixed constraints Auto2']/container[@n='Values']} value {n theta_z_Value pn {?z value} unit_magnitude Rotation state {[check_state_inv {Plane_strain Plane_stress Solids}]} v 0.0 units deg}" f="1"/>
# 
# <a n="gid_groups_conds::addF" a="{$n3} group {n {Self weight load Auto}}" f="1"/>
# <a n="change_group_properties" pn="Change group properties to group Self weight load Auto - type = BC" a="{{Self weight load Auto}} type BC" f="1"/>
# <a n="gid_groups_conds::setAttributesF" pn="setattributes" a="{container[@n='loadcases']/blockdata[@n='loadcase'][1]} {active 1}" f="1"/>
# 
# </gidpost_batch>

proc svgml::parse_props { content accept_add line } {
    
    set props ""
    if { !$accept_add } {
        set rex {()\m([a-zA-Z][-\w]*)\s*:([^;]*);}
    } else {
        set rex {(\+)?\m([a-zA-Z][-\w]*)\s*:([^;]*);}
    }
    set c 0
    foreach "allI addI nI vI" [regexp -inline -all -indices $rex $content] {
        foreach i [list add n v] {
            set $i [string range $content {*}[set ${i}I]]
        }
        regsub -all {(?i)(^|[^\\])\\003B} $v {\1;} v
        regsub -all {(?i)\\(\\003B)} $v {\1} v

        if { !$accept_add } {
            lappend props $n $v
        } else {
            lappend props $add $n $v
        }
        set prev [string range $content $c [lindex $allI 0]-1]
        if { [regexp {\w+} $prev] } {
            error "error with data '$prev' --- $line"
        }
        set c [expr {[lindex $allI 1]+1}] 
    }
    set prev [string range $content $c end]
    if { [regexp {\w+} $prev] } {
        error "error with data '$prev' --- $line"
    }
    return $props
}

proc svgml::append_line { d_name id line content } {
    upvar $d_name d
    
    dict set d ids $id line $line
    dict set d ids $id props [parse_props $content 0 $line]
}

proc svgml::set_error { d id txt } {
    error "error: $txt --- line:[dict get $d ids $id line]"
}

proc svgml::give_prop { d id name } {
    
    if { ![dict exists $d ids $id props $name] } {
        set_error $d $id "property '$name' does not exist"
    }
    return [dict get $d ids $id props $name]
}

proc svgml::give_propD { d id name default } {
    
    if { ![dict exists $d ids $id props $name] } {
        return $default
    }
    return [dict get $d ids $id props $name]
}

proc svgml::bbox_to_points { bbox } {
    lassign $bbox x y w h  
    return [list "$x $y" [list [expr {$x+$w}] [expr {$y+$h}]]]
}

proc svgml::add_to_bbox { id bbox } {
    variable d
    
    if { [dict exists d ids $id bbox] } {
        set pnts ""
        lappend pnts {*}[bbox_to_points [dict get d ids $id bbox]]
        lappend pnts {*}[bbox_to_points $bbox]
        foreach pnt $pnts {
            if { ![info exists x0] || [lindex $pnt 0]<$x0 } { set x0 [lindex $pnt 0] }
            if { ![info exists y0] || [lindex $pnt 1]<$y0 } { set y0 [lindex $pnt 1] }
        }
        foreach pnt $pnts {
            if { ![info exists w] || [lindex $pnt 0]-$x0 > $w } {
                set w [expr {[lindex $pnt 0]-$x0}]
            }
            if { ![info exists h] || [lindex $pnt 1]-$y0 > $h } {
                set h [expr {[lindex $pnt 1]-$y0}]
            }
        }
        set bbox [list $x0 $y0 $w $h]
    }
    dict set d ids $id bbox $bbox
}

proc svgml::rotate_angles { anglexy anglez } {
        
    set anglexy_R [expr {$m::degtorad*($anglexy+90.0)}]
    set anglez_R [expr {-1.0*$m::degtorad*($anglez-90.0)}]
    set a [m::quaternion::rotation [list 0.0 0.0 1.0] $anglexy_R]
    set newaxis [m::quaternion::rotation [list 1.0 0.0 0.0] $anglez_R]
    set rotation_vector [m::quaternion::multiply $a $newaxis]
    return [m::quaternion::normalizeP $rotation_vector 6]
}

proc svgml::is_number { text } {

    if { [scan $text "%f %n" number len] == 0 } { return 0 }
    if { ![info exists len] } { return 0 }
    if { $len != [string length $text] } { return 0 }
    return 1
}

# x,y where values are: -1,0,1
proc svgml::give_anchor_axes { d id } {
    
    set anchor [split [give_propD $d $id anchor ""] ""]
    
    lassign "0 0" x y
        
    if { "w" in $anchor && "e" in $anchor } {
        set x 0
    } elseif { "w" in $anchor } {
        set x 1
    } elseif { "e" in $anchor } {
        set x -1
    }
    if { "n" in $anchor && "s" in $anchor } {
        set y 0
    } elseif { "n" in $anchor } {
        set y 1
    } elseif { "s" in $anchor } {
        set y -1
    }
    return [list $x $y]
}

proc svgml::split_text { text } {
    
    set ret ""
    if { [regexp {\n} $text] } {
        set iline 0
        foreach line [split $text \n] {
            set retL [split_text $line]
            if { $iline > 0 && [llength $retL] } {
                lset retL 0 0 [list {*}[lindex $retL 0 0] newline]
            }
            incr iline
            lappend ret {*}$retL
        }
    } elseif { [regexp -indices {[~^*_]{1,2}} $text idxs] } {
        set v [string range $text {*}$idxs]
        set c [expr {[lindex $idxs 1]+1}]
        set rex "\\[string index $v 0]\{[string length $v]\}"
        if { ![regexp -start $c -indices $rex $text idxsN] } {
            return [list [list "" $text]]
        }
        set str [string range $text 0 [lindex $idxs 0]-1]
        set retL [split_text $str]
        lappend ret {*}$retL
        
        set types [list {~ sub} {^ sup} {* italic} {_ italic} {** bold} {__ bold}]
        set ipos [lsearch -index 0 -exact $types $v]
        set type [lindex $types $ipos 1]
        
        set str [string range $text $c [lindex $idxsN 0]-1]
        set retL [split_text $str]
        foreach i $retL {
            lset i 0 [list {*}[lindex $i 0] $type]
            lappend ret $i
        }
        
        set str [string range $text [lindex $idxsN 1]+1 end]
        set retL [split_text $str]
        lappend ret {*}$retL
    } elseif { [string length $text] } {
        lappend ret [list "" $text]
    }
    return $ret
}

proc svgml::xml_quote { text } {
    set map [list "<" "&lt;" ">" "&gt;" "&" "&amp;"]
    return [string map $map $text]
}

proc svgml::append_tspans { x text } {
    
    regsub -all {[ \t]+} $text { } text
    regsub -all {[ \t]*\n[ \t]*} $text "\n" text
    
    set xml ""
    foreach i [svgml::split_text $text] {
        lassign $i types txt
        append xml "<tspan"
        set st ""
        foreach type $types {
            switch $type {
                newline { append xml " x='$x' dy='1.2em'" }
                sub { append st "font-size:65%;baseline-shift:sub;" }
                sup { append st "font-size:65%;baseline-shift:sup;" }
                italic { append st "font-style:italic;" }
                bold { append st "font-weight:bold;" }
            }
        }
        if { $st ne "" } {
            append xml " style='$st'"
        }
        append xml ">[xml_quote $txt]</tspan>"
    }
    return $xml
}

proc svgml::create { txt } {
    variable d
    variable xml
    
#################################################################################
#    initial parsing by lines
#################################################################################
    
    lassign "" d line
    
    dict set d classes ""
    
    foreach ln [split $txt \n] {
        regsub -all {<!--.*? -->} $ln {} ln
        if { [regexp {(.*[^\\])\\\s*$} $ln {} prefix] } {
            append line $prefix
            continue
        } else {
            append line $ln 
        }
        if { [regexp {^\s*\+svgml(\S+)\s+(.*)} $line {} version content] } {
            append_line d 0 $line $content
            dict set d version $version

            set width [give_prop $d 0 width]
            set height [give_prop $d 0 height]

            if { [regexp {(\d+)%} $height {} p] } {
                set height [expr {int($p/100.0*$width)}]
            }
            dict set d ids __ROOT bbox [list 0 0 100 100]
            dict set d ids __ROOT props ""
            dict set d ids 0 bbox [list 0 0 $width $height]
            dict set d ids 0 bboxL [dict get $d ids 0 bbox]
            dict set d ids 0 angle 0
        } elseif { [regexp {^\s*\+alias\s+(\S.*)} $line {} content] } {
            foreach "long short" [parse_props $content 0 $line] {
                dict set d alias $short $long
            }
        } elseif { [regexp {^\s*\+variables\s+(\S.*)} $line {} content] } {
            foreach "add n v" [parse_props $content 1 $line] {
                if { $add ne "" } {
                    set vOld [dict get $d variables $n]
                    append vOld $v
                    dict set d variables $n $vOld
                } elseif { [dict exists $d variables $n] } {
                    error "repeated variable '$line'"
                } else {
                    dict set d variables $n $v
                }
            }
        } elseif { [regexp {^\s*(\w\S*)\s+(\w+)\s+(\S.*)} $line {} id cmd content] } {
            if { [dict exists $d ids $id] } {
                set_error $d $id "repeated id in line"
            }
            append_line d $id $line $content
            dict set d ids $id cmd $cmd
            dict set d ids_short [lindex [split $id .] end] $id
        } elseif { [regexp {^\s*\.(\S+)\s+(\S.*)} $line {} class content] } {
            dict set d classes $class $content
        } elseif { ![regexp {^\s*$|^\s*#} $line] } {
            error "unknown line '$line'"
        }
        set line ""
    }
    
#################################################################################
#    substitute alias and variables
#################################################################################
    
    foreach id [dict keys [dict get $d ids]] {
        set p ""
        foreach "n v" [dict get $d ids $id props] {
            set n [dict_getd $d alias $n $n]
            if { [regexp {^\s*:(\w[-\w]*)} $v {} variable] } {
                if { ![dict exists $d variables $variable] } {
                    set_error $d $id "unknown variable '$variable'"  
                }
                set v [dict get $d variables $variable]
            }
            set v [subst -nocommands -novariables $v]
            lappend p $n $v
        }
        dict set d ids $id props $p
    }
    
#################################################################################
#    header
#################################################################################
    
    if { ![dict exists $d ids 0] } {
        error "there is no svgml header"
    }
    lassign [dict get $d ids 0 bbox] - - width height
    
    set xmlH "<?xml version='1.0' encoding='UTF-8' standalone='no'?>\n"
    append xmlH "<svg xmlns='http://www.w3.org/2000/svg' "
    append xmlH "xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' "
    append xmlH "width='$width' height='$height'>\n"
    append xmlH "<!--created with svgml-RamDebugger <http://www.compassis.com/ramdebugger>-->"
    append xmlH "<defs>\n"
    
    set stP "stroke:#000000;stroke-width:1pt;fill:#000000;"
    append xmlH "<marker orient='auto' refY='0.0' refX='-4.5' id='TriangleInL' style='overflow:visible'>\n"
    append xmlH "<path d='M 4.5,0.0 L -2.3,4.0 L -2.3,-4.0 L 4.5,0.0 z' "
    append xmlH "fill='context-stroke' stroke='context-stroke' style='$stP' transform='scale(-1.0)'/>\n"
    append xmlH "</marker>\n"
    
    append xmlH "<marker orient='auto' refY='0.0' refX='4.5' id='TriangleOutL' style='overflow:visible'>\n"
    append xmlH "<path d='M 4.5,0.0 L -2.3,4.0 L -2.3,-4.0 L 4.5,0.0 z' "
    append xmlH "fill='context-stroke' stroke='context-stroke' style='$stP'/>\n"
    append xmlH "</marker>\n"
    
    append xmlH "<marker orient='auto' refY='0.0' refX='0.0' id='circle' style='overflow:visible'>\n"
    append xmlH "<circle cx='0.0' cy='0' r='1.5' "
    append xmlH "fill='context-stroke' stroke='context-stroke' style='$stP'/>\n"
    append xmlH "</marker>\n"
    
    append xmlH "<filter id='shadow' x='-20%' y='-20%' width='140%' height='140%'>"
    append xmlH "<feGaussianBlur stdDeviation='2 2' result='shadow'/>"
    append xmlH "<feOffset dx='6' dy='6'/>"
    append xmlH "</filter>"
    
    append xmlH "<filter id='glow' x='-30%' y='-30%' width='160%' height='160%'>"
    append xmlH "<feGaussianBlur stdDeviation='10 10' result='glow'/>"
    append xmlH "<feMerge>"
    append xmlH "<feMergeNode in='glow'/>"
    append xmlH "<feMergeNode in='glow'/>"
    append xmlH "<feMergeNode in='glow'/>"
    append xmlH "</feMerge>"
    append xmlH "</filter>"
    
    dict for "class content" [dict get $d classes] {
        set c ""
        foreach contentI [split $content ";"] {
            if { $contentI eq "" } { continue }
            lassign [split $contentI :] n v
            if { $n eq "fill" && [regexp {radial-gradient\((.*)\)} $v {} vs] } {
                lassign [split $vs ,] color1 color2
                if { ![info exists radial_gradient] } {
                    set radial_gradient 1
                } else {
                    incr radial_gradient
                }
                set id radial_gradient$radial_gradient
                append xmlH "<radialGradient id='$id' cx='50%' cy='50%' r='50%' fx='50%' fy='50%'>\n"
                append xmlH "<stop offset='0%' style='stop-color:$color1;stop-opacity:0' />\n"
                append xmlH "<stop offset='100%' style='stop-color:$color2;stop-opacity:1' />\n"
                append xmlH "</radialGradient>\n"
                set v "url(#$id)"
            }
            append c "$n:$v;"
        }
        dict set d classes $class $c
    }
    
    append xmlH "</defs>\n"
        
#################################################################################
#    loop on entities. The tries are here to solve dependencies of dependencies
#################################################################################
    
    for { set i_try 0 } { $i_try < 10 } { incr i_try } {
        set xml $xmlH
        dict set d needs_recalculate 0
        dict for "id ent" [dict get $d ids] {
            if { $id in "0 __ROOT" } { continue }
            if 1 { puts "$i_try   [dict get $ent line]" }
            
            set ret [catch { create_entity $id "" } str opts]
            if { $ret != 0 && $ret != 4 } {
                error $str [dict get $opts -errorinfo]
            } elseif { $ret == 4 } {
                dict set d needs_recalculate 1
            }
        }
        if { ![dict get $d needs_recalculate] } {
            break
        }
    }
    append xml "</svg>\n"
    return $xml
}

proc svgml::resolve_id { id id_from } {
    variable d
    
    if { $id eq "" } { return 0 }
    
    if { ![dict exists $d ids $id] && [dict exists $d ids_short $id] } {
        set id [dict get $d ids_short $id]
    }
    if { ![dict exists $d ids $id] } {
        set_error $d $id_from "unknown id #$id"
    }
    return $id
}

proc svgml::calculate_parent { id } {
    variable d
    
    set parent [join [lrange [split $id .] 0 end-1] "."]
    return [resolve_id $parent $id]
}
proc svgml::copy_operation { id pnt npoint copy_info } {
    variable d

    set cmd [dict get $d ids $id cmd]
    set c [dict_getd $copy_info operations ""]
    
    lassign $pnt n x y z parameters
    set p [list $x $y]
    set p_prev $p
    
    if { $n ni "z Z" } {
        for { set i 0 } { $i < [llength $c] } { incr i } {
            set cI [lindex $c $i]
            if { [dict size [dict get $cI delta_points]] } {
                set dist_max 0.0
                set deltas ""
                dict for "pL vL" [dict get $cI delta_points] {
                    set dist [m::norm_two [m::sub $p $pL]]
                    lappend deltas $dist $vL
                    if { $dist > $dist_max } {
                        set dist_max $dist
                    }
                }
                set delta "0 0"
                set fac_tot 0.0
                foreach "dist v" $deltas {
                    set fac [expr {($dist_max-$dist)**3}]
                    set delta [m::axpy $fac $v $delta]
                    set fac_tot [expr {$fac_tot+$fac}]   
                }
                if { $fac_tot != 0 } {
                    set delta [m::scale [expr {1.0/$fac_tot}] $delta]
                }
            } else {
                set delta [dict get $cI delta]
            }
            set p [m::add $p $delta]
            if { $i < [llength $c]-1 } {
                set p_prev [m::add $p_prev $delta]  
            }
        }
    }
    
    if { [dict get $copy_info connect] ne "" && $cmd ne "copy" } {
        regsub -all {\.}  [dict get $copy_info id] _ idF
        set idC __copy_${idF}_${npoint}_[llength $c]

        set pList ""
        if { [dict get $copy_info connect] eq "points" } {
            if { $n in "point M L l A a" } {
                set pList "point:#__ROOT,[join $p_prev ,],#__ROOT,[join $p ,];"
            }
        } elseif { [dict get $copy_info connect] eq "lines" } {
            set ok "point M L l A a z Z"
            if { $n in $ok && [dict exists $d prev_copy_info $idF] && $npoint > 0 } {
                set c [dict_getd $d prev_copy_info $idF ""]
                if { $n in "point M L l A a" } {
                    lappend c [list $n $p_prev $p $pnt]
                } else {
                    lappend c [dict get $d prev_copy_info0 $idF]
                }
                set pList "point:"
                set idx 0
                foreach i $c {
                    lassign $i nL p_prevL pL pntL
                    if { $idx == 0 || $nL in "point M" } {
                        append pList #__ROOT,[join $p_prevL ,],
                    } else {
                        append pList "#__ROOT,$nL,"
                        if { [lindex $pntL 4] ne "" } {
                            append pList "[join [lindex $pntL 4] ,],"
                        }
                        append pList "[join $p_prevL ,],"
                    }
                    incr idx
                }
                lassign "" nL_prev pnt_prevL
                foreach i [lreverse $c] {
                    lassign $i nL p_prevL pL pntL
                    if { $idx == 0 || $nL in "point M" } {
                        append pList #__ROOT,[join $pL ,],
                    } else {
                        append pList "#__ROOT,$nL,"
                        if { [lindex $pnt_prevL 4] ne "" } {
                            set params [lindex $pnt_prevL 4]
                            lset params 3 [expr {([lindex $params 3])?0:1}]
                            append pList "[join $params ,],"
                        }
                        append pList "[join $pL ,],"
                    }
                    set nL_prev $nL
                    set pnt_prevL $pntL
                    incr idx
                }
                append pList "z;"
                set c [lrange $c end end]
                dict set d prev_copy_info $idF $c
            } elseif { $n ni "z Z" } {
                if { $npoint == 0 } {
                    dict set d prev_copy_info0 $idF [list $n $p_prev $p $pnt]
                    set c ""
                } else {
                    set c [dict_getd $d prev_copy_info $idF ""]
                }
                lappend c [list $n $p_prev $p $pnt]
                dict set d prev_copy_info $idF $c
            }
        }
        if { $pList ne "" } {
            set content "$pList"
            if { [dict get $copy_info style_name] ne "" } {
                append content " class:[dict get $copy_info style_name];"
            }
            set line "$idC line $content"
            if { ![dict exists $d ids $idC] } {
                append_line d $idC $line $content
                dict set d ids $idC cmd line
                dict set d needs_recalculate 1
            }
        }
    }
    return [lreplace $pnt 1 2 {*}$p]
}

proc svgml::process_cube { id what args } {
    variable d
    
    lassign [dict get $d ids $id bbox] x0 y0 w h
    set pnts [dict get $d ids $id pnts]
    
    set angles [give_propD $d $id angles "45deg,45deg"]
    set anglesList [split $angles ","]
    if { [llength $anglesList] != 2 } {
        set_error $d $id "properties angles must be: angles:45deg,45deg;"
    }
    set anglesN ""
    foreach a $anglesList {
        if { [regexp {^\s*([-+\d.e]+)\s*deg\s*$} $a {} value] } {
            lappend anglesN $value
        } elseif { [regexp {^\s*([-+\d.e]+)\s*rad\s*$} $a {} value] } {
            lappend anglesN [expr {$m::radtodeg*$value}]
        } else {
            set_error $d $id "properties angles must be: angles:45deg,45deg;"
        }
    }
    set q [svgml::rotate_angles {*}$anglesN]
    
    set ipos [lsearch -index 0 $pnts "width-height"]
    set height ""
    if { $ipos != -1 } {
        set height [lindex $pnts $ipos 3]
    }
    if { $height eq "" } {
        set height $w
    }
    
    set point_to_axes {{0 0 0} {1 0 0} {1 1 0} {0 1 0} {0 0 1} {1 0 1} {1 1 1} {0 1 1}}
    set face_to_points {{0 1 2 3} {0 4 5 1} {1 2 6 5} {3 7 6 2} {0 3 7 4} {4 5 6 7}}
    set ariste_to_points {{0 1} {1 2} {3 2} {0 3} {0 4} {1 5} {2 6} {3 7} {4 5} {5 6} {7 6} {4 7}}
    set face_to_normal {2 1 0 1 0 2}
    set face_to_normal_prev_next {0 0 1 1 0 1}
    
    set p0 [list [expr {$x0+0.5*$w}] [expr {$y0+0.5*$h}]]
    
    if { $what eq "faces" } {
        set idx_faces [list 0 1 4 2 3 5]
        set faces ""
        foreach idx_face $idx_faces {
            set face "$idx_face"
            set center_face "0 0"
            for { set i 0 } { $i < 4 } { incr i } {
                set idx_point [lindex $face_to_points $idx_face $i]
                set vL [lindex $point_to_axes $idx_point]
                set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
                set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
                set zL [expr {[lindex $vL 2]*$height}]
                set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
                set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}]]
                set pnt [m::add $p0 $v]
                lappend face $pnt
                set center_face [m::axpy 0.25 $pnt $center_face]
            }
            lappend faces $face
        }
        return $faces
    } elseif { $what eq "draw_labels" } {
        set xml ""
        
        if { [lindex $args 0] in "face all" } {
            for { set idx_face 0 } { $idx_face < 6 } { incr idx_face } {
                set center_face "0 0"
                for { set i 0 } { $i < 4 } { incr i } {
                    set idx_point [lindex $face_to_points $idx_face $i]
                    set vL [lindex $point_to_axes $idx_point]
                    set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
                    set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
                    set zL [expr {[lindex $vL 2]*$height}]
                    set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
                    set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}]]
                    set pnt [m::add $p0 $v]
                    set center_face [m::axpy 0.25 $pnt $center_face]
                }
                lassign $center_face x y
                append xml [format "<text x='%.4g' y='%.3g' style='fill: red;'>" $x $y]
                append xml "[expr {$idx_face+1}]</text>"
                
                set style "stroke-width: 1.0px; stroke: black;fill:none;marker-end:url(#TriangleOutL);"
                set styleT "font-size: 18px; fill: black; font-family: sans-serif;"
                set pnt [process_cube $id face [expr {$idx_face+1}] 70 50] 
                set pnt [m::add $center_face [m::scale 50 [m::unitLengthVector [m::sub $pnt $center_face]]]]
                append xml "<path d='M$center_face L$pnt' style='$style'/>"
                append xml [format "<text x='%.3g' y='%.3g' style='%s'>x'</text>" \
                        [lindex $pnt 0] [lindex $pnt 1] $styleT]
                set pnt [process_cube $id face [expr {$idx_face+1}] 50 70]
                set pnt [m::add $center_face [m::scale 50 [m::unitLengthVector [m::sub $pnt $center_face]]]]
                append xml "<path d='M$center_face L$pnt' style='$style'/>"
                append xml [format "<text x='%.3g' y='%.3g' style='%s'>y'</text>" \
                        [lindex $pnt 0] [lindex $pnt 1] $styleT]
            }
        }
        if { [lindex $args 0] in "ariste all" } {
            for { set idx_ariste 0 } { $idx_ariste < 12 } { incr idx_ariste } {
                set center_ariste "0 0"
                for { set i 0 } { $i < 2 } { incr i } {
                    set idx_point [lindex $ariste_to_points $idx_ariste $i]
                    set vL [lindex $point_to_axes $idx_point]
                    set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
                    set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
                    set zL [expr {[lindex $vL 2]*$height}]
                    set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
                    set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}]]
                    set pnt [m::add $p0 $v]
                    set center_ariste [m::axpy 0.5 $pnt $center_ariste]
                }
                lassign $center_ariste x y
                append xml [format "<text x='%.3g' y='%.3g' style='fill: blue;'>" $x $y]
                append xml "[expr {$idx_ariste+1}]</text>"
            }
        }
        if { [lindex $args 0] in "vertex all" } {
            for { set idx_point 0 } { $idx_point < 8 } { incr idx_point } {
                set vL [lindex $point_to_axes $idx_point]
                set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
                set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
                set zL [expr {[lindex $vL 2]*$height}]
                set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
                set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}]]
                set pnt [m::add $p0 $v]
                lassign $pnt x y
                append xml [format "<text x='%.3g' y='%.3g' style='fill: green;'>" $x $y]
                append xml "[expr {$idx_point+1}]</text>"
            }
        }
        return $xml
    } elseif { $what eq "face" } {
        lassign $args idx_face x y z
        incr idx_face -1
        set x [expr {$x/100.0}]
        set y [expr {$y/100.0}]
        set z [expr {($z eq "")?0:$z/100.0}]
        lappend p0 0.0
        
        set face ""
        for { set i 0 } { $i < 4 } { incr i } {
            set idx_point [lindex $face_to_points $idx_face $i]
            set vL [lindex $point_to_axes $idx_point]
            set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
            set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
            set zL [expr {[lindex $vL 2]*$height}]
            set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
            set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}] [lindex $v 2]]
            set pnt [m::add $p0 $v]
            lappend face $pnt
        }
        set normal [m::vector_normal_triangle {*}[lrange $face 0 2]]
        set sign [expr {([lindex $face_to_normal_prev_next $idx_face]==1)?-1:1}]
        set normal [m::scale [expr {$sign*$w}] [m::unitLengthVector $normal]]
        
        set dx [m::scale $x [m::sub [lindex $face 1] [lindex $face 0]]]
        set dy [m::scale $y [m::sub [lindex $face 3] [lindex $face 0]]]
        set dz [m::scale $z $normal]
        
        set p [m::add [lindex $face 0] [m::add $dx [m::add $dy $dz]]]
        return [lrange $p 0 1]
    } elseif { $what eq "vertex" } {
        lappend p0 0.0
        lassign $args idx_point
        incr idx_point -1
        set vL [lindex $point_to_axes $idx_point]
        set xL [expr {(-1+2*[lindex $vL 0])*0.5*$w}]
        set yL [expr {(-1+2*[lindex $vL 1])*0.5*$h}]
        set zL [expr {[lindex $vL 2]*$height}]
        set v [m::matmul [m::transpose [m::quaternion::matrix $q]] [list $xL $yL $zL]]
        set v [list [lindex $v 0] [expr {-1*[lindex $v 1]}] [lindex $v 2]]
        set pnt [m::add $p0 $v]
        return [lrange $pnt 0 1]
    }
}

proc svgml::get_geometry_point { id vertex_ariste_face pntsG num args } {
    variable d
    
    
    if { [dict get $d ids $id cmd] eq "cube" } {
        return [process_cube $id $vertex_ariste_face $num {*}$args]
    } else {
        if { $vertex_ariste_face eq "face" } {
            set_error $d $id "face only allowed for 'cube'"
        }
        if { $vertex_ariste_face eq "ariste" } {
            if { [lindex $args 0] ne "normal" } {
                set coord [expr {[lindex $args 0]/100.0}]
            }
        }
        set idx 1
        set pnts [dict_getd $d ids $id pnts ""]
        for { set i 0 } { $i < [llength $pnts] } { incr i } {
            lassign [lindex $pnts $i] type x y
            if { $type in "z Z q Q c C C2" } { continue }
            if { $num == $idx } {
                if { $vertex_ariste_face eq "vertex" } {
                    return [list $x $y]
                } else {
                    set i_next $i
                    for { set i_try 0 } { $i_try < 3 } { incr i_try } {
                        if { $i_next < [llength $pnts]-1 } {
                            set i_next [expr {$i_next+1}]
                        } else {
                            set i_next 0
                        }
                        if { [lindex $pnts $i_next] ni "z Z" } {
                            break
                        }
                    }
                    lassign [lindex $pnts $i_next] type_n x_n y_n
                    if { $type_n in "Q C" } {
                        if { [lindex $args 0] eq "normal" } {
                            set_error $d $id "not implemented ariste,n,normal in quadratic or cubic path"
                        }
                       
                        set bpnts [list $x $y $x_n $y_n]
                        if { $type_n in "C" } {
                            lassign [lindex $pnts $i_next] type_n x_n y_n z_n xC yC zC
                            lappend bpnts $xC $yC
                        }
                        set i_next2 $i_next
                        for { set i_try 0 } { $i_try < 3 } { incr i_try } {
                            if { $i_next2 < [llength $pnts]-1 } {
                                set i_next2 [expr {$i_next2+1}]
                            } else {
                                set i_next2 0
                            }
                            if { [lindex $pnts $i_next2] ni "z Z" } {
                                break
                            }
                        }
                        lassign [lindex $pnts $i_next2] type_n2 x_n2 y_n2
                        if { $type_n2 ne "point" } { error "aa $type_n2" }
                        lappend bpnts $x_n2 $y_n2
                        if { $type_n in "Q" } {
                            set pnt [m::eval_quadratic_bezier {*}$bpnts $coord]
                        } else {
                            set pnt [m::eval_cubic_bezier {*}$bpnts $coord] 
                        }
                    } else {
                        if { [lindex $args 0] eq "normal" } {
                            lassign [lindex $pntsG end] typeP xP yP
                            set v [m::sub "$x $y" "$xP $yP"]
                            set t [m::sub "$x_n $y_n" "$x $y"]
                            set n [list [expr {-1*[lindex $t 1]}] [lindex $t 0]]
                            set n0 [m::unitLengthVector $n]
                            set dot [m::dotproduct $v $n0]
                            set pnt [m::axpy $dot $n0 "$xP $yP"]
                        } else {
                            set pnt [m::eval_linear $x $y $x_n $y_n $coord]
                        }
                    }
                    if { [llength $args] > 1 } {
                        set t [m::sub "$x_n $y_n" "$x $y"]
                        set n [list [expr {-1*[lindex $t 1]}] [lindex $t 0]]
                        set coordY [expr {[lindex $args 1]/100.0}]
                        set pnt [m::axpy $coordY $n $pnt]
                    }
                    return $pnt
                }
            }
            incr idx
        }
    }
    if { $num <= 0 || $num > [llength $pnts] } {
        set_error $d $id "incorrect point num must be >0 <npoints"
        return
    }
    set_error $d $id "incorrect point"
}

proc svgml::transform { pnt type bboxPx bboxPy bboxPz } {
    
    lassign $pnt x y z
    
    if { $type in "point M L C Q A" } {
        set x [expr {[lindex $bboxPx 0]+$x/100.0*[lindex $bboxPx 2]}]
        set y [expr {[lindex $bboxPy 1]+$y/100.0*[lindex $bboxPy 3]}]
        if { $z ne "" } {
            set z [expr {[lindex $bboxPz 0]+$z/100.0*[lindex $bboxPz 2]}]
        }
    } else {
        set x [expr {$x/100.0*[lindex $bboxPx 2]}]
        set y [expr {$y/100.0*[lindex $bboxPy 3]}]
        if { $z ne "" } {
            set z [expr {$z/100.0*[lindex $bboxPz 2]}]
        }
    }
    return [list $x $y $z]
}

proc svgml::calculate_points { id copy_info } {
    variable d
    
    set parent [calculate_parent $id]
    
    set pnts ""
    foreach "n v" [dict get $d ids $id props] {
        if { $n ni "point delta-point width-height" } { continue }
        #puts "---calculate_points $n --- $v"
        
        set parentL $parent
        set pnt ""
        set nL $n
        set parents ""
        set calculate_type ""
        set vList [split $v ,]
        for { set i 0 } { $i < [llength $vList] } { incr i } {
            set c [string trim [lindex $vList $i]]
            if { [regexp {^#(\S+)$} $c {} idP] } {
                set parentL [resolve_id $idP $id]
            } elseif { [regexp {^([-+\d.]+)$} $c {} value] } {
                lappend pnt $value
                lappend parents $parentL
            } elseif { [regexp {^normal$} $c value] } {
                lappend pnt $value
                lappend parents $parentL
            } elseif { [regexp {^[mMCcqQzZlL]$} $c] } {
                set nL $c
            } elseif { [regexp {^[aA]$} $c] } {
                set nL $c
                set parameters [lrange $vList $i+1 $i+5]
                incr i 5
                continue
            } elseif { [regexp {^AA$} $c] } {
                set nL $c
                set parameters [lrange $vList $i+1 $i+1]
                incr i 1
                continue
            } elseif { [regexp {vertex|ariste|face} $c] } {
                set calculate_type $c
            } else {
                set_error $d $id "incorrect format '$n:$v'"
            }
            if { $nL in "z Z" } {
                lappend pnts [list z]
                if { [dict size $copy_info] } {
                    lassign [copy_operation $id [list $nL "" ""] [llength $pnts] $copy_info]
                }
                continue 
            }
            if { $calculate_type eq "vertex" } {
                if { [llength $pnt] < 1 } {
                    continue
                }
            } elseif { $calculate_type eq "ariste" } {
                if { [llength $pnt] < 2 } {
                    continue
                }
                if { [llength $pnt] == 2 && $i == [llength $vList]-2 && 
                    [is_number [lindex $vList $i+1]] } {
                    continue
                }
            } elseif { $calculate_type eq "face" } {
                if { [llength $pnt] < 3 } {
                    continue
                }
                if { [llength $pnt] == 3 && $i == [llength $vList]-2 && 
                    [is_number [lindex $vList $i+1]] } {
                    continue
                }
            } elseif { $nL eq "width-height" && [llength $vList] == 3 && \
                [llength $pnt] < 3 } {
                continue
            } elseif { [llength $pnt] < 2 } {
                continue
            }
            lassign $pnt x y z
            
            if { $calculate_type in "vertex ariste face" } {
                if { ![dict exists $d ids $parentL bbox] } {
                    if { ![dict exists $d ids $parentL] } {
                        error "error: unknown parent id #$parentL for id #$id"
                    }
                    return -code continue
                }
                lassign [get_geometry_point $parentL $calculate_type $pnts {*}$pnt] x y
                set calculate_type ""
            } else {
                foreach parentL $parents {
                    if { ![dict exists $d ids $parentL bbox] } {
                        if { ![dict exists $d ids $parentL] } {
                            error "error: unknown parent id #$parentL for id #$id"
                        }
                        return -code continue
                    }
                }
                set bboxPx [dict get $d ids [lindex $parents 0] bbox]
                set bboxPy [dict get $d ids [lindex $parents 1] bbox]
                if { $z ne "" } {
                    set bboxPz [dict get $d ids [lindex $parents 2] bbox]
                } else {
                    set bboxPz ""
                }
                lassign [transform "$x $y $z" $nL $bboxPx $bboxPy $bboxPz] x y z

                if { $nL in "a A" } {
                    lassign $parameters rx ry x-axis-rotation large-arc-flag sweep-flag
                    set rx [expr {$rx/100.0*[lindex $bboxPx 2]}]
                    set ry [expr {$ry/100.0*[lindex $bboxPx 3]}]
                    set parameters [list $rx $ry ${x-axis-rotation} ${large-arc-flag} ${sweep-flag}]
                } elseif { $nL in "AA" } {
                    lassign $parameters r
                    set r [expr {$r/100.0*[lindex $bboxPx 2]}]
                    set parameters [list $r]
                }
            }
            if { [lindex $pnts end 0] eq "C" } {
               set nL C2
            } elseif { [lindex $pnts end 0] eq "c" } {
               set nL c2
            }
            
            set pnt [list $nL $x $y]
            if { $z ne "" } {
                lappend pnt $z
            }
            if { $nL in "a A AA" } {
                if { $z eq "" } {
                    lappend pnt 0
                }
                lappend pnt $parameters
            }
            if { $nL in "point m M L C C2 Q A AA" && [dict size $copy_info] } {
                set pnt [copy_operation $id $pnt [llength $pnts] $copy_info]
            }
            
            lappend pnts $pnt
            set pnt ""
            set nL $n
            set parentL $parent
            set parents ""
        }
        if { [llength $pnt] == 1 } {
            set_error $d $id "bad number of components '$n:$v'"
        }
    }
    
#################################################################################
#    converting AA to A
#################################################################################
    
    for { set i 0 } { $i < [llength $pnts] } { incr i } {
        lassign [lindex $pnts $i] type x y
        if { $type ne "AA" } { continue }
        lassign [lindex $pnts $i] type x2 y2 z parameters
        lassign $parameters r
        lassign [lindex $pnts $i-1] - x1 y1
        lassign [lindex $pnts $i+1] - x3 y3
        set p12 [m::sub "$x1 $y1" "$x2 $y2"]
        set p32 [m::sub "$x3 $y3" "$x2 $y2"]
        set norm12 [m::norm $p12]
        set norm32 [m::norm $p32]
        set angle [expr {acos([m::dotproduct $p12 $p32]/($norm12*$norm32))}]
        set L [expr {$r/tan($angle/2.0)}]
        set alpha [expr {$L/$norm12}]
        set p1_n [m::axpy $alpha $p12 "$x2 $y2"]
        set alpha [expr {$L/$norm32}]
        set p2_n [m::axpy $alpha $p32 "$x2 $y2"]
        set sweep_flag 0
        set p12_3D [list {*}$p12 0]
        set p32_3D [list {*}$p32 0]
        set cross [m::crossproduct $p12_3D $p32_3D]
        if { [lindex $cross 2] < 0 } {
            set sweep_flag 1
        }
        lset pnts $i [list point {*}$p1_n]
        set pnts [linsert $pnts $i+1 [list A {*}$p2_n 0 [list $r $r 0 0 $sweep_flag]]]
    }
    
#################################################################################
#    storing pnts
#################################################################################
    
    if { [dict size $copy_info] == 0 } {
        dict set d ids $id pnts $pnts
    } else {
        set idC [dict get $copy_info id]
        set pntsO [dict_getd $idC pnts ""]
        lappend pntsO {*}$pnts
        dict set d ids $idC pnts $pnts
    }
    return $pnts
}

proc svgml::give_descendants { id id_avoid } {
    variable d
    
    set idsList ""
    set idL [split $id "."]
    set n [expr {[llength $idL]-1}]
    foreach idC [dict keys [dict get $d ids]] {
        if { $idC eq $id_avoid } { continue }
        set idCL [split $idC "."]
        if { [llength $idCL] <= [llength $idL] } { continue }
        if { [lrange [split $idC "."] 0 $n] eq $idL } {
            lappend idsList $idC
        }
    }
    return $idsList
}

proc pngsize_data { data } {

    if {[string length $data] < 33} {
        error "File not large enough to contain PNG header"
    }

    # Read PNG file signature
    binary scan [string range $data 0 7] c8 sig
    foreach b1 $sig b2 {-119 80 78 71 13 10 26 10} {
        if {$b1 != $b2} {
            error "data is not a PNG file"
        }
    }

     # Read IHDR chunk signature
    binary scan [string range $data 8 15] c8 sig
    foreach b1 $sig b2 {0 0 0 13 73 72 68 82} {
        if {$b1 != $b2} {
            error "data is missing a leading IHDR chunk"
        }
     }

     # Read off the size of the image
    binary scan [string range $data 16 23] II width height
     # Ignore the rest of the data, including the chunk CRC!
     #binary scan [read $f 5] ccccc depth type compression filter interlace
     #binary scan [read $f 4] I chunkCRC

    return [list $width $height]
 }

proc svgml::create_entity { id copy_info } {
    variable d
    variable xml
    
    set ret [catch { calculate_points $id $copy_info } pnts opts]
    if { $ret != 0 } {
        return -code $ret -errorinfo \
            [dict_getd $opts -errorinfo ""] $pnts
    }

    lassign [give_anchor_axes $d $id] anchorX anchorY
    
    set pntsBBOX ""
    foreach p $pnts {
        lassign $p type x y
        if { $type eq "width-height" } {
            lassign $p - b h
            if { [llength $pntsBBOX] } {
                lassign [lindex $pntsBBOX end] x y
            } else {
                set ipos [lsearch -index 0 $pnts point]
                if { $ipos == -1 } {
                    set_error $d $id "property 'width-height' needs a 'point'"
                }
                lassign [lindex $pnts $ipos] - x y
            }
            set a1x [expr {-0.5*(1.0-$anchorX)}]
            set a2x [expr {0.5*(1.0+$anchorX)}]
            set a1y [expr {-0.5*(1.0-$anchorY)}]
            set a2y [expr {0.5*(1.0+$anchorY)}]
            
            lappend pntsBBOX [list [expr {$x+$a1x*$b}] [expr {$y+$a1y*$h}]]
            lappend pntsBBOX [list [expr {$x+$a2x*$b}] [expr {$y+$a2y*$h}]]
        } elseif { $type in "point L C Q A" } {
            lappend pntsBBOX [list $x $y]
        }  elseif { $type in "delta-point q l c a" && [llength $pntsBBOX] } {
            lassign [lindex $pntsBBOX end] xp yp
            set x [expr {$x+$xp}]
            set y [expr {$y+$yp}]
            lappend pntsBBOX [list $x $y]
        }
    }
    
    lassign "" x0 y0 x1 y1
    if { [llength $pntsBBOX] } {
        foreach p $pntsBBOX {
            lassign $p x y
            if { $x0 eq "" || $x < $x0 } { set x0 $x }
            if { $x1 eq "" || $x > $x1 } { set x1 $x }
            if { $y0 eq "" || $y < $y0 } { set y0 $y }
            if { $y1 eq "" || $y > $y1 } { set y1 $y }
        }
        set w [expr {$x1-$x0}]
        set h [expr {$y1-$y0}]
        set bbox [list $x0 $y0 $w $h]
    } else {
        set bbox ""
    }
    if { [dict size $copy_info] == 0 } {
        dict set d ids $id bbox $bbox
    } else {
        add_to_bbox [dict get $copy_info id] $bbox
    }
    
    set style ""
    foreach "n v" [dict get $d ids $id props] {
        if { $n eq "class" } {
            append style "[dict get $d classes $v]"
        }
    }
    append style [dict_getd $copy_info style ""]
    
    set cmd [dict get $d ids $id cmd]
    
    switch $cmd {
        region {
            if { $bbox eq "" } {
                set_error $d $id "region needs a box definition"
            }
        }
        image {
            lassign $bbox x0 y0 w h
            set txt [give_propD $d $id text ""]
            set err [catch { open $txt rb } fin]
            if { $err } {
                set_error $d $id "image '$txt' not found"
            }
            set data [read $fin]
            close $fin            
            set href "data:image/png;base64,[base64::encode $data]"
            set preserveAspectRatio "xMinYMin"
            
            if { [give_propD $d $id anchor ""] ne "" && $anchorX == 0 && $anchorY == 0 } {
                set preserveAspectRatio "none"
            }
            
            append xml "<image x='$x0' y='$y0' width='$w' height='$h' id='$id' style='$style' "
            append xml "xlink:href='$href' preserveAspectRatio='$preserveAspectRatio'/>"
            
            if { [regexp {border-stroke-width:\s*((\d+)[^;]+)} $style {} value num] && $num > 0 } {
                if { [regexp {border-stroke:\s*([^;]+)} $style {} s] } {
                    set stroke $s
                } else {
                    set stroke black   
                }
                set styleB "$style;stroke-width:$value;stroke:$stroke;fill:none;"
                
                if { $preserveAspectRatio ne "none" } {
                    lassign [pngsize_data $data] width height
                    set r1 [expr {double($w)/$h}]
                    set r2 [expr {double($width)/$height}]
                    if { $r2 > $r1 } {
                        set h [expr {$h*$r1/$r2}]
                    } else {
                        set w [expr {$w*$r2/$r1}]
                    }
                    
                }
                append xml "<rect x='$x0' y='$y0' width='$w' height='$h' "
                append xml "id='$id-border' style='$styleB'/>"
            }
            
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL $bbox
                dict set d ids $id angle 0
            }
        }
        rect {
            lassign $bbox x0 y0 w h
            append xml "<rect x='$x0' y='$y0' width='$w' height='$h' id='$id' style='$style'"
            if { [regexp {border-radius\s*:\s*(\d+)} $style {} r] } {
                append xml " rx='$r' ry='$r'"
            }
            append xml "/>\n"
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL $bbox
                dict set d ids $id angle 0
            }
        }
        circle {
            lassign $bbox x0 y0 w h
            set cx [expr {$x0+0.5*$w}]
            set cy [expr {$y0+0.5*$h}]
            set r [expr {0.5*$w}]
            append xml "<circle cx='$cx' cy='$cy' r='$r' id='$id' style='$style'/>\n"
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL $bbox
                dict set d ids $id angle 0
            }
        }
        cube {
            set labels [give_propD $d $id labels ""]
            if { $labels in [list "" 0] && [dict exists $copy_info labels] } {
                set labels [dict get $copy_info labels]
            }
            if { $labels ne "" && $labels ne "0" } {
                if { $labels ni "vertex ariste face" } {
                    set labels all
                }
                append xml [process_cube $id draw_labels $labels]
                append style "fill:none;"
            }
            set faces [process_cube $id faces]
            foreach face $faces {
                set ds ""
                for { set i 0 } { $i < [llength $face] } { incr i } {
                    if { $i == 0 } {
                        set idx_face [lindex $face $i]
                        continue
                    }
                    set pnt [lindex $face $i]
                    if { $ds eq "" } {
                        append ds "M$pnt"
                    } else {
                        append ds " L$pnt"
                    }
                }
                append ds "z"
                append xml "<path d='$ds' id='$id-$idx_face' style='$style'/>\n"
            }
            
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL $bbox
                dict set d ids $id angle 0
            }
        }
        line {
            set labels [give_propD $d $id labels ""]
            if { $labels in [list "" 0] && [dict exists $copy_info labels] } {
                set labels [dict get $copy_info labels]
            }
            if { $labels ne "" && $labels ne "0" } {
                set labelsFlag 1
            } else {
                set labelsFlag 0   
            }
            set labelsList [split $labels ,]
            if { [llength $labelsList] < 2 } {
                set labelsList ""
            }
            lassign "" ds type_prev pnts_text
            for { set i 0 } { $i < [llength $pnts] } { incr i } {
                lassign [lindex $pnts $i] type x y
                if { $ds eq "" } {
                    append ds [format "M%.3g,%.3g" $x $y]
                    lappend pnts_text "$x $y"
                } elseif { $type in "point L" && $type_prev in "q Q C c C2 c2" } {
                    append ds [format " %.3g,%.3g" $x $y]
                    lappend pnts_text "$x $y"
                } elseif { $type in "point L M" } {
                    append ds [format " L%.3g,%.3g" $x $y]
                    lappend pnts_text "$x $y"
                } elseif { $type in "delta-point l c2" && $type_prev in "q Q C c C2 c2" } {
                    append ds [format " %.3g,%.3g" $x $y]
                    set pnt [m::add [lindex $pnts_text end] "$x $y"]
                    lappend pnts_text $pnt
                } elseif { $type in "delta-point l m" } {
                    append ds [format " l%.3g,%.3g" $x $y]
                    if { [llength $pnts_text] } {
                        set pnt [m::add [lindex $pnts_text end] "$x $y"]
                    } else {
                        set pnt "$x $y"
                    }
                    lappend pnts_text $pnt
                } elseif { $type in "q Q" } {
                    append ds [format " %s%.3g,%.3g" $type $x $y]
                } elseif { $type in "c C" } {
                    append ds [format " %s%.3g,%.3g" $type $x $y]
                } elseif { $type in "C2" } {
                    append ds [format " %.3g,%.3g" $x $y]
                } elseif { $type in "a A" } {
                    lassign [lindex $pnts $i] type x y z parameters
                    append ds " $type [join $parameters ,]" [format " %.3g,%.3g" $x $y]
                    if { $type eq "A" } {
                        lappend pnts_text "$x $y"
                    } else {
                        set pnt [m::add [lindex $pnts_text end] "$x $y"]
                        lappend pnts_text $pnt
                    }
                } elseif { $type in "z Z" } {
                    append ds " $type"
                }
                set type_prev $type
            }
            if { $labelsFlag } {
                set idx 1
                foreach i $pnts_text {
                    lassign $i x y
                    set x [expr {$x+5}]
                    set y [expr {$y-5}]
                    if { [llength $labelsList] } {
                        set txt [lindex $labelsList $idx-1]
                    } elseif { $idx == 1 } {
                        set txt "$id: $idx"   
                    } else {
                        set txt "$idx"
                    }
                    set styleT "font-size: 18px; fill: black; font-family: sans-serif;"
                    append xml [format "<text x='%.3g' y='%.3g' text-anchor='start' style='%s'>\n" \
                            $x $y $styleT]
                    append xml [append_tspans $x $txt]
                    append xml "</text>\n"
                    incr idx
                }
                append style "marker-start:url(#circle);marker-mid:url(#circle);"
                append style "marker-end:url(#circle);"
            }
            append xml "<path d='$ds' id='$id' style='$style'/>\n"
            
            set pnt1 [lindex $pntsBBOX 1]
            set pnt0 [lindex $pntsBBOX 0]
            set L [m::norm [m::sub $pnt1 $pnt0]]
            set angle [expr {atan2([lindex $pnt1 1]-[lindex $pnt0 1],
                    [lindex $pnt1 0]-[lindex $pnt0 0])}]
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL [list $x0 $y0 $L $L]
                dict set d ids $id angle $angle
            }
        }
        label - dimension - text {
            set text [give_propD $d $id text ""]
            if { [regexp {font-family\s*:\s*(.+)} $style {} font_family] } {
                set font_family [lindex [split $font_family ,] 0]
                set font_family [string trim $font_family \"]
            } else {
                set font_family Verdana
                append style "font-family: Verdana;sans-serif;"
            }
            if { ![regexp {font-size\s*:\s*(\d+)} $style {} font_size] } {
                set font_size 14
                append style "font-size: 14px;"
            }
            
            set err [catch {
                    load {C:\Users\ramsan\Documents\myTclTk\RamDebugger\utils\test_markdown\markdownLib.dll} markdown
                    set text_box [measure_text $text $font_family $font_size]
                }]
            if { $err } {
                set text_box [list 0 [expr {-0.2*$font_size}] [expr {0.5*[string length $text]*$font_size}] \
                        [expr {0.85*$font_size}]]
            }
                        
            set ipos [lsearch -index 0 $pnts delta-point]
            if { $ipos != -1 } {
                set delta [lrange [lindex $pnts $ipos] 1 2]
            } else {
                set delta ""
            }
            if { $cmd eq "dimension" } {
                set parent [calculate_parent $id]
                set cmdP [dict_getd $d ids $parent cmd ""]
                set hv [give_propD $d $id horizontal-vertical ""]
                if { [llength $pntsBBOX] >= 2 } {
                    set p0 [lindex $pntsBBOX 0]
                    set vT [m::sub [lindex $pntsBBOX 1] $p0]
                    set vN [m::unitLengthVector "[expr {-1*[lindex $vT 1]}] [lindex $vT 0]"]
                    if { $hv eq "v" } {
                        set vN [m::scale $anchorX "1 0"]
                    } elseif { $hv eq "h" } {
                        set vN [m::scale $anchorY "0 1"]
                    }
                } elseif { $cmdP eq "rect" } {
                    set b [dict get $d ids $parent bbox]
                    set p0 [lrange $b 0 1]
                    set vT "[lindex $b 2] 0"
                    set vN "0 $anchorY"
                    set ariste [give_propD $d $id ariste "s"]
                    switch $ariste {
                        s {
                            set p0 [m::add $p0 "0 [lindex $b 3]"] 
                        }
                        w {
                            set vT "0 [lindex $b 3]" ; set vN "$anchorX 0"
                        }
                        e {
                            set p0 [m::add $p0 "[lindex $b 2] 0"]
                            set vT "0 [lindex $b 3]" ; set vN "$anchorX 0"
                        }
                    }
                }                       
                
                set p1 [m::add $p0 $vT]
                
                if { $hv eq "h" } {
                    lset vT 1 0
                    set vc [lindex $vN 1]
                    if { $vc != 0 } {
                        set vN "0 [expr {$vc/abs($vc)}]"                         
                    }
                } elseif { $hv eq "v" } {
                    lset vT 0 0
                    set vc [lindex $vN 0]
                    if { $vc != 0 } {
                        set vN "[expr {$vc/abs($vc)}] 0"
                    }
                }
                set fac [expr {0.8*$font_size}]
                set vN [m::scale $fac $vN]
                if { $delta eq "" } {
                    set vNd $vN
                } else {
                    set vNd $delta
                }
                
                set p0D1 [m::axpy 1 $vNd $p0]
                set p1D1 [m::axpy 1 $vNd $p1]
                
                set p0D2 [m::axpy 1 $vN $p0D1]
                set p1D2 [m::axpy 1 $vN $p1D1]
                
                if { $hv eq "h" } {
                    lset p1D1 1 [lindex $p0D1 1]
                    lset p1D2 1 [lindex $p0D2 1]
                } elseif { $hv eq "v" } {
                    lset p1D1 0 [lindex $p0D1 0]
                    lset p1D2 0 [lindex $p0D2 0]
                }
                set pLabel [m::scale 0.5 [m::add $p0D1 $p1D1]]
                set pLabel [m::axpy 0.7 $vN $pLabel]
            } else {
                set pLabel [lrange $bbox 0 1]
                set vN "$anchorX $anchorY"
            }
            if { $cmd eq "dimension" } {                        
                set st "stroke:black;stroke-width:1px;$style"
                append xml "<path d='M$p0 L$p0D2' id='$id-DL1' style='$st'/>\n"
                append xml "<path d='M$p1 L$p1D2' id='$id-DL2' style='$st'/>\n"
                
                append st "marker-end:url(#TriangleOutL);" \
                    "marker-start:url(#TriangleInL);"
                append xml "<path d='M$p0D1 L$p1D1' id='$id-DL' style='$st'/>\n"
            } elseif { $delta ne "" && [m::norm_two $delta] > 20 } {
                set p0D [m::add $pLabel $delta]
                set p1D [m::axpy 0.1 $delta $pLabel]
                set delta ""
                
                set st "stroke:black;stroke-width:1px;$style"
                append st "marker-end:url(#TriangleOutL);"
                append xml "<path d='M$p0D L$p1D' id='$id-DL' style='$st'/>\n"
                set pLabel $p0D
                set cmd labelarrow
            }
            
#             if { $cmd eq "text" } {
#                 set fsX "0 0 0"
#                 set fsY "0 0 0.8"
#             } elseif { $cmd eq "labelarrow" } {
#                 set fsX "0 0 0"
#                 set fsY "-0.2 0.0 1"
#             } else {
#                 set fsX "-0.3 0 0.3"
#                 set fsY "-0.5 0.2 1"
#             }
#             catch {
#                 set vN [m::unitLengthVector $vN]
#             }
#             lassign "0 0" fac1 fac2
#             if { abs([lindex $vN 0])>0.2 } {
#                 set fac1 [expr {abs([lindex $fsX $anchorX+1]*$font_size)}]
#             }
#             if { abs([lindex $vN 1])>0.2 } {
#                 set fac2 [expr {abs([lindex $fsY $anchorY+1]*$font_size)}]
#             }
#             set fac [expr {($fac1>$fac2)?$fac1:$fac2}]
#             set pLabel [m::axpy $fac $vN $pLabel]
            
            if { $anchorY == 1 } {
                lset pLabel 1 [expr {[lindex $pLabel 1]+([lindex $text_box 1]+[lindex $text_box 3])}]
            } elseif { $anchorY == -1 } {
                lset pLabel 1 [expr {[lindex $pLabel 1]+[lindex $text_box 1]}]
            }
            
            if { $delta ne "" && $cmd ne "dimension" } {
                set pLabel [m::add $pLabel $delta]
            } elseif { $cmd eq "label" } {
                lset pLabel 0 [expr {[lindex $pLabel 0]+0.5*$anchorX*$font_size}]
            }
            
            if { $anchorX == -1 } {
                set ta "end"
            } elseif { $anchorX == 1 } {
                set ta "start"
            } else {
                set ta "middle"
            }
            
            lassign $pLabel x y
            
            if { [regexp {border-stroke-width:\s*((\d+)[^;]+)} $style {} value num] && $num > 0 } {
                if { [regexp {border-stroke:\s*([^;]+)} $style {} s] } {
                    set stroke $s
                } else {
                    set stroke black   
                }
                if { [regexp {padding:\s*((\d+)[^;]+)} $style {} padding] == 0 } {
                    set padding [expr {0.5*$font_size}]
                }
                lassign $pLabel xR yR
                if { $anchorX == -1 } {
                    set xR [expr {$xR-[lindex $text_box 2]}]
                } elseif { $anchorX == 0 } {
                    set xR [expr {$xR-0.5*[lindex $text_box 2]}]
                }
                set xR [expr {$xR-$padding}]
                set yR [expr {$yR-([lindex $text_box 1]+[lindex $text_box 3])-$padding}]
                set w [expr {[lindex $text_box 2]+2*$padding}]
                set h [expr {[lindex $text_box 3]+2*$padding}]
                
                set styleB "$style;stroke-width:$value;stroke:$stroke;fill:none;"
                append xml "<rect x='$xR' y='$yR' width='$w' height='$h' "
                append xml "id='$id-border' style='$styleB'"
                if { [regexp {border-radius\s*:\s*(\d+)} $style {} r] } {
                    append xml " rx='$r' ry='$r'"
                }
                append xml "/>\n"
                
                set bbox [list $xR $yR $w $h]
            } else {
                set w [lindex $text_box 2]
                set h [lindex $text_box 3]
                set xB $x
                if { $anchorX == -1 } {
                    set xB [expr {$xB-[lindex $text_box 2]}]
                } elseif { $anchorX == 0 } {
                    set xB [expr {$xB-0.5*[lindex $text_box 2]}]
                }
                set yB [expr {$y-([lindex $text_box 1]+[lindex $text_box 3])}]
                set bbox [list $xB $yB $w $h] 
            }
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bbox $bbox
            } else {
                add_to_bbox [dict get $copy_info id] $bbox
            }
            
            append xml [format "<text x='%.3g' y='%.3g' text-anchor='%s' id='%s' style='%s'>" \
              $x $y $ta $id $style]
            append xml [append_tspans $x $text]
            append xml "</text>\n"
            if { [dict size $copy_info] == 0 } {
                dict set d ids $id bboxL [dict_getd $d ids $id bbox ""]
                dict set d ids $id angle 0
            }
        }
        copy {
            set idC [join [lrange [split $id .] 0 end-1] .]
            set idC [resolve_id $idC $id]
            set idsList [list $idC]
            set ic [give_propD $d $id include_children 0]
            if { $ic } {
                lappend idsList {*}[give_descendants $idC $id]
            }
            
            set n [give_propD $d $id number 1]
            
            set style_name ""
            foreach "nL vL" [dict get $d ids $id props] {
                if { $nL eq "class" } {
                    if { $style_name eq "" } {
                        set style_name $vL
                    }
                } elseif { $nL eq "connect-class" } {
                    set style_name $vL
                }
            }
            if { $style_name eq "" } {
                set style_name [give_propD $d $idC class ""]
            }
            
            lassign [split [give_propD $d $id operation translation] ,] \
                operation op
            
            dict set copy_info style $style
            dict set copy_info labels [give_propD $d $id labels ""]
            if { ![dict exists $copy_info style_name] } {
                dict set copy_info style_name $style_name
            }
            dict set copy_info id $id
            if { ![dict exists $copy_info connect] } {
                dict set copy_info connect [give_propD $d $id connect ""]
            }
            
            lassign "" delta delta_points points
            for { set i 0 } { $i < [llength $pnts] } { incr i } {
                lassign [lindex $pnts $i] type x y
                if { $type eq "delta-point" } {
                    if { $i == 0 || [lindex $pnts $i-1 0] ne "point" } {
                        set delta "$x $y"
                    } else {
                        lassign [lindex $pnts $i-1] - xP yP
                        dict set delta_points "$xP $yP" "$x $y"
                    }
                } else {
                    lappend points "$x $y"
                }
            }
            if { $op ne "" } {
                set delta "0 0"
                set c 0
                set rex {\A\s*([-+\de.]+)[*]P(\d+)}
                while { [regexp -start $c -indices $rex $op all alphaI pI] } {
                    set alpha [string range $op {*}$alphaI]
                    set p [string range $op {*}$pI]
                    set v [lrange [lindex $pnts $p-1] 1 2]
                    set delta [m::axpy $alpha $v $delta]
                    set c [expr {[lindex $all 1]+1}]
                }
                if { ![regexp -start $c {\A\s*$} $op] } {
                    set_error $d $id "'copy' expression not correct"
                }
            } elseif { $delta eq "" && [dict size $delta_points] == 0 } {
                if { [llength $points] == 2 } {
                    set delta [m::sub [lindex $points 1] [lindex $points 0]]
                } else {
                    set_error $d $id "'copy' must have a delta-point property or two points"
                }
            }
            
            for { set i 1 } { $i <= $n } { incr i } {
                set c [dict_getd $copy_info operations ""]
                lappend c [dict create operation $operation delta \
                        $delta delta_points $delta_points]
                dict set copy_info operations $c
                foreach idC $idsList {
                    set idC [resolve_id $idC $id]
                    create_entity $idC $copy_info
                }
            }
        }
        default {
            set_error $d $id "unknown command '$cmd'"
        }
    }
}

proc svgml::paste_entity { node ent_type props text mT stylesN style_numN } {
    upvar 1 $stylesN styles
    upvar 1 $style_numN style_num
    
    set propsV [list fill stroke opacity stroke-width stroke-dasharray \
            font-style font-weight font-size font-family]
    
    set nodes [list $node]
    lappend nodes {*}[$node sn *]
    
    set stylesD ""
    foreach nodeI $nodes {
        foreach nv [split [$nodeI @style ""] ";"] {
            lassign [split $nv :] n v
            if { $n in $propsV } {
                if { $n eq "font-size" } {
                    regexp {([-+\de.]+)\s*(\w*)} $v {} vv unit
                    lassign [m::matmul $mT "$vv 0"] vv
                    set v "[format %.0f $vv]$unit"
                }
                dict set stylesD $n $v
            }
        }
    }
    set style ""
    dict for "n v" $stylesD { append style "$n:$v;" }
    
    if { [dict exists $styles v $style] } {
        set style_name [dict get $styles v $style]
    } else {
        set style_name "style$style_num"
        incr style_num
        dict set styles n $style_name $style
        dict set styles v $style $style_name
    }
    set id [$node @id ""]
    set txt "$id"
    if { [string length $id] < 15 } {
        append txt [string repeat " " [expr {15-[string length $id]}]]
    } else {
        append txt " "
    }
    append txt "$ent_type $props cl:$style_name;\n"
    $text insert insert $txt
}

proc svgml::paste { xml } {
    
    package require compass_utils::c
    set doc [p::xml parse $xml]
    
    set widthG 800
    
    set svgNode [$doc documentElement]
    set width [$svgNode @width 100]
    set height [$svgNode @height 100]
    set viewBox [$svgNode @viewBox "0 0 $width $height"]
    
    set text $RamDebugger::text
    set idx [$text index insert]
    regexp {^\d+} $idx line
    set found_start 0
    for { set i $line } { $i >= 1 } { incr i -1 } {
        if { [regexp {^\s*~~~~\s*$} [$text get $i.0 "$i.0 lineend"]] } {
            break
        }
        if { [regexp {^\s*~~~~.*svgml} [$text get $i.0 "$i.0 lineend"]] } {
            set found_start 1
            break
        }
    }
    if { [$text compare $idx == "$idx linestart"] == 0 } {
        $text insert insert "\n"
        set idx [$text index "$idx + 1l linestart"]
    }
    if { [$text compare $idx == "$idx lineend"] == 0 } {
        $text insert insert "\n"
        $text mark set insert "insert-1c"
    }
    
    if { !$found_start } {
        set r [expr {1.0*[$svgNode @width 800]/[$svgNode @height $widthG]}]
        set heightG [format %0.f [expr {$widthG/$r}]]
        $text insert insert "~~~~ { svgml=\"1\" file=\"image.svg\" }\n"
        $text insert insert "+svgml1             width:$widthG; height:$heightG;\n"
        $text insert insert "+alias              point:p; delta-point:dp; width-height:wh; text:t;\n"
        $text insert insert "+alias              anchor:a; horizontal-vertical:hv; class:cl; number:n;\n\n"
    }
    
    set m [m::mkMatrix 3 3 0]
    m::setelem m 0 0 [expr {100.0/[lindex $viewBox 2]}]
    m::setelem m 0 2 [expr {-100.0*[lindex $viewBox 0]/[lindex $viewBox 2]}]
    m::setelem m 1 1 [expr {100.0/[lindex $viewBox 3]}]
    m::setelem m 1 2 [expr {-100.0*[lindex $viewBox 1]/[lindex $viewBox 3]}]
    
    set mS [m::mkMatrix 2 2 0]
    m::setelem mS 0 0 [m::getelem $m 0 0]
    m::setelem mS 1 1 [m::getelem $m 1 1]
    
    set mT [m::mkMatrix 2 2 0]
    m::setelem mT 0 0 [expr {1.0*$widthG/[lindex $viewBox 2]}]
    m::setelem mT 1 1 [expr {1.0*$widthG/[lindex $viewBox 3]}]
    
    set styles ""; set style_num 1
    foreach pathNode [$svgNode sn "path"] {
        set vs [regexp -inline -all {[a-zA-Z]|[-+e0-9.]+} [$pathNode @d ""]]
        set dN ""
        set cmd_prev ""
        set pnt_prev ""
        for { set i 0 } { $i < [llength $vs] } { incr i } {
            switch [lindex $vs $i] {
                a - A {
                    lassign [lrange $vs $i $i+7] type rx ry x-axis-rotation large-arc-flag \
                        sweep-flag x y
                    lassign [m::matmul $mS "$rx $ry"] rx ry
                    if { $type eq "A" } {
                        lassign [m::matmul $m "$x $y 1"] x y
                    } else {
                        lassign [m::matmul $mS "$x $y"] x y
                        lassign [m::add $pnt_prev "$x $y"] x y
                        set type A
                    }
                    set pnt_prev "$x $y"
                    lappend dN $type {*}[format "%.0f %.0f" $rx $ry] ${x-axis-rotation} \
                        ${large-arc-flag} ${sweep-flag} {*}[format "%.0f %.0f" $x $y]
                    set cmd_prev [lindex $vs $i]
                    incr i 7
                }
                m - M - l - L - q - Q - c - C - s - S {
                    switch [lindex $vs $i] {
                        m - M - l - L { set npoints 1 }
                        q - Q - s - S { set npoints 2 }
                        c - C { set npoints 3 }
                    }
                    set type [lindex $vs $i]
#                     if { $i == 0 && $type eq "m" } {
#                         set type "M"
#                     }
                    lappend dN [string toupper $type]
                    for { set j 0 } { $j < $npoints } { incr j } {
                        set idx [expr {$i+2*$j+1}]
                        lassign [lrange $vs $idx $idx+1] x y
                        if { $type in "M L Q C S" } {
                            lassign [m::matmul $m "$x $y 1"] x y
                        } elseif { $type eq "m" && $i == 0 } {
                            lassign [m::matmul $m "$x $y 1"] x y
                        } else {
                            lassign [m::matmul $mS "$x $y"] x y
                            lassign [m::add $pnt_prev "$x $y"] x y
                        }
                        if { $j == $npoints-1 } {
                            set pnt_prev "$x $y"
                        }
                        lappend dN {*}[format "%.0f %.0f" $x $y]
                    }
                    set cmd_prev $type
                    incr i [expr {2*$npoints}]
                }
                h - H - v - V {
                    lassign [lrange $vs $i $i+1] type xy
                    switch [lindex $vs $i] {
                        h - H { set x $xy ; set y 0 }
                        v - V { set x 0   ; set y $xy }
                    }
                    if { [lindex $vs $i] in "H V" } {
                        lassign [m::matmul $m "$x $y 1"] x y
                        if { [lindex $vs $i] eq "H" } {
                            set y [lindex $pnt_prev 1]
                        } else {
                            set x [lindex $pnt_prev 0]
                        }
                    } else {
                        lassign [m::matmul $mS "$x $y"] x y
                        lassign [m::add $pnt_prev "$x $y"] x y
                    }
                    set pnt_prev "$x $y"
                    lappend dN L {*}[format "%.0f %.0f" $x $y]
                    set cmd_prev [string toupper [lindex $vs $i]]
                    incr i 1
                }
                z - Z {
                    lappend dN [lindex $vs $i]
                    set cmd_prev [lindex $vs $i]
                }
                default {
                    if { $cmd_prev eq "" || $cmd_prev in "M m" } {
                        if { $cmd_prev eq "m" } {
                            set cmd_prev "l"
                        } else {
                            set cmd_prev "L"
                        }
                    }
                    set vs [linsert $vs $i $cmd_prev]
                    incr i -1
                }
            }
        }
        
        set ent_type "line"
        set props "p:[join $dN ,];"
        paste_entity $pathNode $ent_type $props $text $mT styles style_num
    }
    foreach circleNode [$svgNode sn "circle"] {
        set x [$circleNode @cx 0]
        set y [$circleNode @cy 0]
        set r [$circleNode @r 0]
        lassign [m::matmul $m "$x $y 1"] x y
        lassign [m::matmul $mS "$r 0"] r
        set d [expr {2*$r}]
        
        set ent_type "circle"
        set props "p:[format "%.0f,%.0f" $x $y]; wh:[format "%.0f,%.0f" $d $d];"
        paste_entity $circleNode $ent_type $props $text $mT styles style_num
    }    
    foreach rectNode [$svgNode sn "rect"] {
        set x [$rectNode @x 0]
        set y [$rectNode @y 0]
        set width [$rectNode @width 0]
        set height [$rectNode @height 0]
        lassign [m::matmul $m "$x $y 1"] x y
        lassign [m::matmul $mS "$width $height"] width height
        
        set ent_type "rect"
        set props "p:[format "%.0f,%.0f" $x $y]; a:nw; "
        append props "wh:[format "%.0f,%.0f" $width $height];"
        paste_entity $rectNode $ent_type $props $text $mT styles style_num
    }
    foreach textNode [$svgNode sn "text"] {
        set x [$textNode @x 0]
        set y [$textNode @y 0]
        lassign [m::matmul $m "$x $y 1"] x y
        set txtList ""
        foreach node [$textNode sn {tspan}] {
            lappend txtList [$node sn string(.)]
        }
        set txt [join $txtList \\n]
        
        set ent_type "text"
        set props "p:[format "%.0f,%.0f" $x $y]; a:w; "
        append props "t:$txt;"
        paste_entity $textNode $ent_type $props $text $mT styles style_num
    }
    
    dict for "n v" [dict_getd $styles n ""] {
        $text insert insert ".$n $v\n"
    }
    if { !$found_start } {
        $text insert insert "~~~~\n"
    }
}

proc svgml::create_file { args } {
    variable svgfile
    
    set optional {
        { -file svgfile "" }
        { -inkscape "" 0 }
        { -samefile "" 0 }
        { -open "" 0 }
    }
    set compulsory "txt"
    parse_args $optional $compulsory $args
        
    set xml [create $txt]
    
    if { $file ne "" } {
        set svgfile $file
    } elseif { $samefile } {
        close [file tempfile tmp]
        set svgfile [file dirname $tmp]/testfile.svg
    } else {
        close [file tempfile tmp]
        set svgfile [file root $tmp].svg
    }
    file mkdir [file dirname $svgfile]
    
    set write 1
    if { [file exists $svgfile] } {
        set fin [open  $svgfile r]
        set data [read $fin]
        fconfigure $fin -encoding utf-8
        close $fin
        if { $data eq $xml } {
            set write 0
        }
    }
    if { $write } {
        set fout [open $svgfile w]
        fconfigure $fout -encoding utf-8
        puts -nonewline $fout $xml
        close $fout
    }
    if { $open } {
        if { !$inkscape } {
            cu::file::execute start $svgfile &
        } else {
            cu::file::execute exec inkscape $svgfile &
        }
    }
    # puts svgfile=$svgfile
}

# U+0394 Greek Capital Letter Delta Unicode Character

set txt {
    +svgml1             width:900; height:40%;
    +alias              point:p; delta-point:dp; width-height:wh; text:t;
    +alias              anchor:a; horizontal-vertical:hv; class:cl;
         
    deb                 rect      p:0,0; p:100,100; cl:line-debug;
    #R1.deb              rect      p:0,0; p:100,100; cl:line-debug;
    #debT                rect      p:50,10;  wh:60,8; a:s; cl:line-debug;
         
    title               text      p:50,10;  t::TITLE; a:s; cl:textTITLE;
    R1                  region    p:25,50;  wh:35,90; a:nsew;
    R1.box              rect      p:50,40;  wh:65,30; a:nsew; cl:rounded_box;
    R1.box.lyg          line      p:-10,90; p:110,90; cl:line1;
    R1.box.lyg.l1       label     p:0,100;  t:y~g~; a:se; cl:text1;
    R1.box.x0y0         label     p:0,100;   t:x~0~,y~0~; a:ne; cl:text1;
    R1.box.dimx         dimension ariste:s; a:n; t:\u0394x; cl:text1;
    R1.box.dimy         dimension ariste:e; a:w; t:\u0394y; cl:text1;
    #R1.box.txt          text      p:2,80;   t:acBj; cl:textint;
    R1.tdesc            text      p:10,80; a:sw; t::BDESC; cl:textDESC;
         
    R2                  region    p:75,50;  wh:35,90; a:nsew;
    R2.box              rect      p:50,40;  wh:65,30; a:nsew; cl:rounded_box;
    R2.box.lyg          line      p:-10,90; p:110,90; cl:line1;
    R2.box.lyg.l1       label     p:0,100;  t:y~g,p~; a:se; cl:text1;
    R2.box.x0y0         label     p:0,100;  t:x~0,p~,y~0,p~; a:ne; cl:text1;
    R2.box.boxin        rect      p:92,10;  wh:60,40; a:ne; cl:rounded_box;
    R2.box.boxin.lyg    line      p:-10,80; p:110,80; cl:line1;
    R2.box.boxin.lyg.l1 label     p:0,100;  t:y~g~; a:se; cl:text1;
    R2.box.dimx         dimension p:0,100;  p:#R2.box.boxin,0,100; hv:h; a:n; t:x~0~; cl:text1;
    R2.box.dim1         dimension p:#R2.box.lyg,100,0;  p:#R2.box.boxin,100,100; hv:v; a:w; t:y~0~; cl:text1;
    R2.box.dim2         dimension p:#R2.box.lyg,100,0;  p:#R2.box.boxin.lyg,100,0; hv:v; a:w; t:y~g~; dp:30,0; cl:text1;
    R2.tdesc            text      p:10,80; a:sw; t::BDESCP; cl:textDESC;
    
    .rounded_box   border-radius: 5px; stroke-width: 3px; stroke: orange; fill: yellow;
    .line1         stroke-width: 2px; stroke: orange; fill:none;
    .line-debug    stroke-width: 1px; stroke: red; fill:none; stroke-dasharray: 5 5;
    .textTITLE     font-size: 24px; fill: #0800d8; stroke:#585858; stroke-width:0 font-family: sans-serif; text-decoration: underline;
    .textDESC      font-size: 16px; fill: black; font-family: sans-serif;
    .textint       font-size: 36px; fill: black; font-family: sans-serif;
    .text1         font-size: 18px; fill: black; font-family: sans-serif;
    
    +variables     TITLE:Boxes definition for calculating HTML display;
    +variables     BDESC:**box**=[x~0~,y~0~,\u0394x,\u0394y]\n**box~0~**=[0,0,Page~width~,Page~height~];
    +variables     BDESCP: **x~0~, y~0~** and **y~g~** values are relative \n to parent **x~0,p~, y~g,p~**\n;
    +variables     +BDESCP: **\u0394x,\u0394y** are in the same scale than **\u0394x~p~,\u0394y~p~**;
}

if 0 {
    svgml::create_file -open $txt
#svgml::create_file -inkscape $txt
#svgml::create_file -samefile -open=0 $txt

exit
}

























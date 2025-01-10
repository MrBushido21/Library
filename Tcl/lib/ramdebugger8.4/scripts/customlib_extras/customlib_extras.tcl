package require customLib
package provide customlib_extras 0.4

namespace eval customlib {
    variable current_xml_root    
    variable mat_dict   
    set current_xml_root ""    
    set mat_dict [dict create]
}

proc customlib::UpdateDocument { } {
    variable current_xml_root    
    variable mat_dict
    if { [info exists ::gid_groups_conds::doc] } {
        set current_xml_root [$::gid_groups_conds::doc documentElement]
    } else {
        set current_xml_root ""
        W "customlib::Init. variable gid_groups_conds::doc doesn't exists"
    }
    set mat_dict [dict create]
}

proc customlib::ProcessIncludes { dir } {
    foreach elem [[customlib::GetBaseRoot] getElementsByTagName "include"] {
        set active 1
        if {[$elem hasAttribute "active"]} {
            set active [$elem getAttribute "active"]
        }
        if {$active} {
            set path [$elem getAttribute "path"]            
            set filename [file join $dir $path]
            set processednode [ProcessIncludesRecurse $filename $dir]
            set elemparent [$elem parent]
            $elemparent replaceChild $processednode $elem
            $elem delete
        }
    }    
}

proc customlib::ProcessIncludesRecurse { filename basedir } {
    set xml [tDOM::xmlReadFile $filename]
    set newnode [dom parse [string trim $xml]]
    set xmlNode [$newnode documentElement]
    foreach elem [$xmlNode getElementsByTagName "include"] {
        set active 1
        if {[$elem hasAttribute "active"]} {
            set active [$elem getAttribute "active"]
        }
        if {$active} {
            set path [$elem getAttribute "path"]
            set f [file join $basedir $path]
            set processednode [customlib::ProcessIncludesRecurse $f $basedir]
            set elemparent [$elem parent]
            foreach att [$elem attributes] {
                if {$att ni [list "n" "active" "path"]} {
                    $processednode setAttribute $att [$elem getAttribute $att]
                }
            }
            $elemparent replaceChild $processednode $elem
            $elem delete
        }
    }
    return $xmlNode
}

proc customlib::GetNumberOfMaterials { {state all }} {
    return [llength [dict keys [customlib::GetMaterials $state]]]
}

proc customlib::GetMaterials { {state all }} {
    variable mat_dict
    if {$mat_dict eq ""} {
        customlib::InitMaterials
    }
    if {$state eq "used"} {
        set usedMaterials [dict create]
        foreach material [dict keys $mat_dict] {
            if {[dict exists $mat_dict $material MID]} {
                dict set usedMaterials $material [dict get $mat_dict $material]
            }
        }
        return $usedMaterials
    } else {
        return $mat_dict
    }
}

# unit_mode can be default or active or none
proc customlib::GetElementsFormats {condition_n parameters {unit_mode "default"}} {
    set mat_dict ""
    set formats "" ;
    set condNodes [[customlib::GetBaseRoot] getElementsByTagName condition]
    set condNode ""
    foreach condNode $condNodes {
        if {[$condNode @n] eq $condition_n} {
            break
        }
    }
    if {$condNode ne ""} {
        set groups [$condNode getElementsByTagName group]
        set xp2 {.//value[@n="material"]}
        foreach gNode $groups {
            set group [$gNode @n]
            set ov ""
            catch {set ov [$gNode @ov]}
            if {$ov eq ""} {
                set ov [[$gNode parent] @ov]
            }
            lassign [customlib::GetElementTypeAndAmountNodes $group $ov] etype nnodes
            if {$nnodes ne ""} {
                set my_mat ""
                set valueNode [$gNode selectNodes $xp2]
                if {$valueNode ne ""} {
                    if {$mat_dict eq ""} {
                        set mat_dict [customlib::GetMaterials used]
                    }
                    set material_name [get_domnode_attribute $valueNode v]
                    if {![dict exists $mat_dict $material_name MID]} {
                        error [= "It's mandatory to call customlib::InitMaterials with the used conditions"]
                    } else {
                        set my_mat [dict get $mat_dict $material_name]
                    }
                }
                set val [customlib::GetFormatDict $gNode $my_mat $parameters $unit_mode]
                #if {$val eq ""} {set val " "}
                dict set formats $group "$val\n"
            }
        }
        return $formats
    }
}

# unit_mode can be default or active or none
proc customlib::GetFormatDict {gNode material parameters {unit_mode "default"}} {
    set unit_conversion_system convert_value_to_default
    if {$unit_mode ne "default"} {set unit_conversion_system convert_value_to_active}
    if {$gNode ne ""} {
        set group [$gNode @n]
        set ov ""
        catch {set ov [$gNode @ov]}
        if {$ov eq ""} {
            set ov [[$gNode parent] @ov]
        }
        set f ""
        lassign [customlib::GetElementTypeAndAmountNodes $group $ov] etype nnodes
    }
    foreach item $parameters {
        lassign $item fmt what attr
        switch $what {
            "element" {
                if {$attr eq "id"} {append f "$fmt "}
                if {$attr eq "connectivities"} {append f "[string repeat "$fmt " $nnodes]"}
                
            }
            "node" {
                if {$attr eq "id"} {append f "$fmt "}
            }
            "material" {
                set attr [dict get $material $attr]
                append f "[format $fmt $attr]"
            }
            "property" {
                set xp2 {.//value[@n=$attr]} 
                set valueNode [$gNode selectNodes $xp2]
                if {$unit_mode ne "none"} {
                    set value [gid_groups_conds::$unit_conversion_system $valueNode]
                } else {
                    set value [get_domnode_attribute $valueNode v]
                }
                append f "[format $fmt $value]"
            }
            "string" {
                append f "[format $fmt $attr]"
            }
            default {
                error [= "Error defining parameters for %s - %s - %s" $group $attr $what]
            }
        }
    }
    return $f
}

proc customlib::GetElementTypeAndAmountNodes {group ov} {
    set isquadratic [customlib::IsQuadratic]
    set ret [list "" ""]
    if {$ov eq "point"} {
        set ret [list Point 1]
    }
    if {$ov eq "line"} {
        switch $isquadratic {
            0 { set ret [list Linear 2] }
            default { set ret [list Linear 2] }                                         
        } 
    }    
    if {$ov eq "surface"} {
        if {[GiD_EntitiesGroups get $group elements -count -element_type Triangle]} {          
            switch $isquadratic {
                0 { set ret [list Triangle 3]  }
                default { set ret [list Triangle 6]  }
            }
        }
        if {[GiD_EntitiesGroups get $group faces -count -element_type Tetrahedra]} {
            switch $isquadratic {
                0 { set ret [list Triangle 3]  }
                default { set ret [list Triangle 6]  }
            }
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Quadrilateral]} {
            switch $isquadratic {
                0 { set ret [list Quadrilateral 4]  }                
                1 { set ret [list Quadrilateral 8]  }                
                2 { set ret [list Quadrilateral 9]  }                
            }
        }
        if {[GiD_EntitiesGroups get $group faces -count -element_type Hexahedra]} {
            switch $isquadratic {
                0 { set ret [list Quadrilateral 4]  }                
                1 { set ret [list Quadrilateral 8]  }                
                2 { set ret [list Quadrilateral 9]  }                
            }
        }
    }    
    if {$ov eq "volume"} {
        if {[GiD_EntitiesGroups get $group elements -count -element_type Tetrahedra]} {       
            switch $isquadratic {
                0 { set ret [list Tetrahedra 4]  }               
                1 { set ret [list Tetrahedra 10] }                
                2 { set ret [list Tetrahedra 10] }  
            }
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Hexahedra]} {   
            switch $isquadratic {
                0 { set ret [list Hexahedra 8]  } 
                1 { set ret [list Hexahedra 20]  }
                2 { set ret [list Hexahedra 27]  }
            }
        }
    }    
    return $ret
}

proc customlib::IsQuadratic {} { 
    return [GiD_Set Model(QuadraticType)]
}

proc customlib::InitWriteFile {filename} {
    GiD_WriteCalculationFile init $filename ;#initialize writting
    set root [$::gid_groups_conds::doc documentElement] ;#xml document to get some tree data
    customlib::SetBaseRoot $root
}

proc customlib::EndWriteFile { } {
    GiD_WriteCalculationFile end
}

proc customlib::WriteString { str } {
    GiD_WriteCalculationFile puts $str
}

proc customlib::SetBaseRoot {root} {
    variable current_xml_root
    set current_xml_root $root
}

proc customlib::GetBaseRoot {} {
    variable current_xml_root
    return $current_xml_root
}

# elements_conditions is a list of every <condition> where we use a material
# unit_mode can be default or active or none
proc customlib::InitMaterials {elements_conditions {unit_mode "default"} } {
    variable mat_dict    
    set unit_conversion_system convert_value_to_default
    if {$unit_mode ne "default"} {set unit_conversion_system convert_value_to_active}
    set root [customlib::GetBaseRoot]
    set mats ""
    #foreach xmlopt [$root getElementsByTagName container] {if {[$xmlopt @n] eq "materials"} {set mats [$xmlopt getElementsByTagName material]; break}}
    #W $mats
    set xp2 {.//container[@n="materials"]/blockdata[@n="material"]}
    set mats [$root selectNodes $xp2]
    if {$mats eq ""} {error [= "No materials block found"]}
    foreach matnode $mats {
        set mat_name [$matnode @name]
        #if {[dict exists $mat_dict $mat_name] } {set props_dict [dict get $mat_dict $mat_name]} {set props_dict [dict create] }
        set props_dict [dict create]
        foreach prop_node [$matnode selectNodes value] {
            set value [get_domnode_attribute $prop_node v]
            if {$unit_mode ne "none"} {set value [gid_groups_conds::$unit_conversion_system $prop_node]}
            dict set props_dict [$prop_node @n] $value
        }
        dict set mat_dict $mat_name $props_dict
    }
    set material_number 0
    set condNodes [[customlib::GetBaseRoot] getElementsByTagName condition]
    foreach condNode $condNodes {
        if {[$condNode @n] in $elements_conditions} {
            set groups [$condNode getElementsByTagName group]
            set xp2 {.//value[@n="material"]}
            foreach gNode $groups {
                set valueNode [$gNode selectNodes $xp2]
                set material_name [get_domnode_attribute $valueNode v]
                if {![dict exists $mat_dict $material_name MID]} {
                    incr material_number
                    dict set mat_dict $material_name MID $material_number 
                }
            }
        }
    }
}

# unit_mode can be default or active or none
proc customlib::WriteConnectivities {list_condition_n parameters {unit_mode "default"}} {
    foreach condition_n $list_condition_n {
        set formats [customlib::GetElementsFormats $condition_n $parameters $unit_mode]
        GiD_WriteCalculationFile connectivities -elements_faces all $formats
    }
}

# unit_mode can be default or active or none
proc customlib::WriteNodes {list_condition_n parameters {flags ""} {unit_mode "default"}} {
    set formats [dict create]
    foreach cond $list_condition_n {
        foreach {k v} [customlib::GetElementsFormats $cond $parameters $unit_mode] {
            dict set formats $k $v
        }
    }
    if {$flags eq ""} {
        set result [GiD_WriteCalculationFile nodes $formats]
    } else {
        set result [GiD_WriteCalculationFile nodes $flags $formats]
    }
    return $result
}

proc customlib::GetNumberOfNodes {list_condition_n {flags ""} } {
    #return [GiD_WriteCalculationFile nodes -count [customlib::GetElementsFormats $list_condition_n ""]]
    return [customlib::WriteNodes $list_condition_n "" [lappend $flags -count]]
}

# unit_mode can be default or active or none
proc customlib::GetNodes {list_condition_n parameters {flags ""} {unit_mode "default"}} {
    return [customlib::WriteNodes $list_condition_n $parameters [lappend $flags -return] $unit_mode]
}

proc customlib::GetCoordinates {formats} {
    return [customlib::WriteCoordinates $formats -return]
}

proc customlib::GetNumberCoordinates {formats} {
    return [customlib::WriteCoordinates $formats -count]
}

proc customlib::WriteCoordinates {formats {flags ""}} {
    # Geometry factor (here the geometry unit declared by the user is converted to 'm')  
    set mesh_unit [gid_groups_conds::give_mesh_unit]
    set mesh_factor [lindex [gid_groups_conds::give_unit_factor L $mesh_unit] 0]
    # efficient CustomLib specialized procedure to print everything related with nodes or elements
    if {$flags eq ""} {
        set result [GiD_WriteCalculationFile coordinates -factor $mesh_factor $formats]
    } else {
        set result [GiD_WriteCalculationFile coordinates $flags -factor $mesh_factor $formats]
    } 
    return $result
}

# user_mode must be default or active or none
proc customlib::WriteMaterials { parameters {state "used"} {unit_mode "default"}} {
    set mat_dict [GetMaterials $state]
    foreach material [dict values $mat_dict] {
        set str [customlib::GetFormatDict "" $material $parameters $unit_mode]
        GiD_WriteCalculationFile puts $str
        #GiD_WriteCalculationFile puts "[format "%4d %13.5e" [dict get $mat_dict $material MID] [format "%13.5e" [dict get $mat_dict $material Density]]]\n"
    }
}


# Add a group to a condition and returns the created spd node
proc customlib::AddConditionGroupOnXPath {xpath groupid} {
    set doc $gid_groups_conds::doc
    set root [$doc documentElement]
    set node [$root selectNodes $xpath]
    return [AddConditionGroupOnNode $node $groupid]
}
proc customlib::AddConditionGroupOnNode {basenode groupid} {
    set prev [$basenode selectNodes "./group\[@n='$groupid'\]"]
    if {$prev ne ""} {return $prev}
    set newNode [gid_groups_conds::addF [$basenode toXPath] group [list n $groupid]]
    foreach val [$basenode childNodes] {
        if {[$val nodeName] eq "value"} {
            set newChild [$val cloneNode -deep]
            $newNode appendChild $newChild
        }
    }
    return $newNode
}

proc customlib::GetNodeValue { xpath } {
    set value ""
    set document [$::gid_groups_conds::doc documentElement]
    set xml_node [$document selectNodes $xpath]
    if { [llength $xml_node] == 1 } {
        set value [get_domnode_attribute $xml_node v]
   }
   return $value
}

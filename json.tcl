proc json_value {value} {
    join [list \" [string map {\" \\\" \n \\n \r \\r \t \\t \\ \\\\} $value] \"] ""
}

proc json_pair {name value} {
    return [json_value $name]:$value
}

proc json_array {args} {
    return \[[join $args ", "]\]
}

proc json_list {args} {
    # args = name0 value0 name1 value1 append
    set result {}
    if {[llength $args] % 2} {
        foreach {n v} [lrange $args 0 end-1] {
            lappend result [json_value $n]:$v
        }
        set append [lindex $args end]
        if {$append ne ""} {
            lappend result $append
        }
    } else {
        foreach {n v} $args {
            lappend result [json_value $n]:$v
        }
    }
    return \{[join $result ,]\}
}

proc json_create {name data} {
    return [json_list $name [json_array {*}[lmap a $data {json_value $a}]]]
}
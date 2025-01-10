proc json_value {value} {
    join [list \" [string map {\" \\\" \n \\n \r \\r \t \\t \\ \\\\} $value] \"] ""
}

proc json_pair {name value} {
    return [json_value $name]:$value
}

proc json_array {args} {
    return \[[join $args ,]\]
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


puts value:[json_value "foo bar"]
puts array:[json_array [json_value foo] [json_value bar]]
puts list:[json_list foo1 [json_value bar2] foo2 [json_value bar2]]

puts example:[json_pair mnc [json_list stamp [json_value "1970-01-01 02:00:00"] ping [json_value pong]]]

package require tcldbf
package require json
source utils.tcl
source json.tcl

proc takeBookList {username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtils $data $username]
    set field [$d get $rowid BOOKS]

    set json {}
    foreach book $field {
        set name [lindex $book 0]
        set currentTime [lindex $book 1]
        set backTime [lindex $book 2]

        lappend json [subst {"name":"$name", "currentTime":"$currentTime", "backTime":"$backTime"}] ","
    }

    return \[[string range $json 0 end-1]\]

    $d close
}

puts [createBookList "oleglis"]


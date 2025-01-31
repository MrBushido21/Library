package require tcldbf
source utils.tcl
source json.tcl

proc createBookList {bookname username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtils $data $username]
    set field [$d get $rowid BOOKS]
    set curentTime [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set backTime [clock format [clock add [clock seconds] 5 minutes] -format "%Y-%m-%d %H:%M:%S"]
    set bookAndTime "\{$bookname\} \{$curentTime\} \{$backTime\}"

    if {$field eq ""} {
        $d update $rowid BOOKS \{$bookAndTime\}
    }

    if {$field ne "" && [lsearch -exact $field $bookname] == -1} {
        lappend field $bookAndTime
        $d update $rowid BOOKS $field
    }

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
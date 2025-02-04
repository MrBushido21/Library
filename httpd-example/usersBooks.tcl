package require tcldbf
source utils.tcl
source json.tcl

proc createBookList {bookname username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtilsStrict $data $username]
    set field [$d get $rowid BOOKS]
    set curentTime [clock format [clock seconds] -format "%H:%M:%S"]
    set backTime [clock format [clock add [clock seconds] 1 minutes] -format "%H:%M:%S"]
    set bookAndTime "\{$bookname\} \{$curentTime\} \{$backTime\}"

    set booknames {}
    foreach list $field {
        lappend booknames [lindex $list 0]
    }

    if {$field eq ""} {
        $d update $rowid BOOKS \{$bookAndTime\}
    }

    if {$field ne "" && [lsearch -exact $booknames $bookname] == -1} {
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

    set requests [$d get $rowid REQUESTS]

    set index [searchUtilsStrict $requests $bookname]
    set newRequests [lreplace $requests $index $index]
    $d update $rowid REQUESTS $newRequests

    return \[[string range $json 0 end-1]\]

    $d close
}


proc takeBookList {username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtilsStrict $data $username]
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

proc updateBookList {bookname username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtilsStrict $data $username]
    set field [$d get $rowid BOOKS]

    set index [searchUtilsStrict $field $bookname]
    set newField [lreplace $field $index $index]
    $d update $rowid BOOKS $newField

    set json {}
    foreach book $newField {
        set name [lindex $book 0]
        set currentTime [lindex $book 1]
        set backTime [lindex $book 2]

        lappend json [subst {"name":"$name", "currentTime":"$currentTime", "backTime":"$backTime"}] ","
    }
    return \[[string range $json 0 end-1]\]
}

proc getFines {bookname username} {
    set file_name "users.dbf"
    dbf d -open $file_name
    set data [$d values NAME]
    set rowid [searchUtilsStrict $data $username]
    set fines [$d get $rowid FINES]
    set fine "Fine 100$ for $bookname" 
    if {$fines eq ""} {
        $d update $rowid FINES "\{Fine 100$ for $bookname\}"
    }

    if {$fines ne "" && [lsearch -exact $fines $fine] == -1} {
        lappend fines $fine
        $d update $rowid FINES $fines
    }
    
    $d close
    return [json_create "fines" $fines]
}
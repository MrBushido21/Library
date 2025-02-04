package require tcldbf
source utils.tcl
source json.tcl
source usersBooks.tcl

proc getuserrequests {username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtilsStrict $data $username]
    set requests [$d get $rowid REQUESTS]
    return [json_create "requests" $requests]
     $d close
}



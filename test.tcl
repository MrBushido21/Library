package require tcldbf
package require json
source utils.tcl
source json.tcl


proc updateBookList {bookname username} {
    set file_name "users.dbf"
    dbf d -open $file_name

    set data [$d values NAME]
    set rowid [searchUtils $data $username]
    set field [$d get $rowid BOOKS]

    set index [searchUtils $field $bookname]
    set newField [lreplace $field $index $index]
    $d update $rowid BOOKS $newField
    $d close
}

puts [updateBookList "Harry Potter" "oleglis"]
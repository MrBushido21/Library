package require tcldbf
package require json
source utils.tcl
source json.tcl


proc deleteBook {bookName} {
    set file_name "books.dbf"
    dbf d -open $file_name
    set bookNames [$d values bookName]    
    set rowid [searchUtilsStrict $bookNames $bookName]
    $d deleted $rowid false
    $d close
}

puts [deleteBook "Harry Potter"]


package require tcldbf
package require json
source utils.tcl
source json.tcl

# $d add id String 2
# $d add bookText String 100
# $d add bookName String 50
# $d add author String 50
# $d add date String 10

proc deleteBook {bookName} {
    set file_name "books.dbf"
    dbf d -open $file_name

    set data [$d values bookName]
    set rowid [searchUtilsStrict $data $bookName]
    puts [$d deleted $rowid]
}

puts [deleteBook "Harry Potter"]



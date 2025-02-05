package require tcldbf
source utils.tcl

proc searchBook {bookName field} {
      set file_name "books.dbf"
      dbf d -open $file_name
      set data [$d values $field]

      set rowid [searchUtils $data $bookName]
      
      set result {}
      foreach number $rowid {
            set row [$d record $number]
            lappend result [lindex $row 2]
      } 
      return [json_create "books" $result]
      $d close
}

proc search {bookName field} {
     return [searchBook $bookName $field]
}
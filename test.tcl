package require tcldbf
source utils.tcl

proc search {bookName} {
      set file_name "books.dbf"
      dbf d -open $file_name
      set data [$d values date]


      set rowid {}
      set i 0
      foreach name $data {
            if {[string match -nocase *$bookName* $name]} {
                  lappend rowid $i
            }
            incr i
      }

         
      return $rowid
      $d close
}

puts [search 1997]




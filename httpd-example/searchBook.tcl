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
            lappend result [lindex $row 1]
      } 
      set json {}
      foreach name $result {
            set rowid [searchUtilsStrict $result $name]
            set text [$d get $rowid bookText]
            set author [$d get $rowid author]
            set date [$d get $rowid date]
            set name $name

            lappend json [subst {"name":"$name", "text":"$text", "author":"$author", "date":"$date"}] ","
      }

      return \[[string range $json 0 end-1]\]
      $d close
}

proc search {bookName field} {
     return [searchBook $bookName $field]
}
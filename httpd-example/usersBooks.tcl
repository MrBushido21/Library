package require tcldbf
source utils.tcl
source json.tcl

proc createBookList {bookname username} {
      set file_name "users.dbf"
      dbf d -open $file_name

      set data [$d values NAME]
      set rowid [searchUtils $data $username]
        puts $rowid
      set field [$d get $rowid BOOKS]
      
      if {$field eq ""} {
          $d update $rowid BOOKS \{$bookname\} 
      }

      if {$field ne "" && [lsearch -exact $field $bookname] == -1} {
            lappend field $bookname
            $d update $rowid BOOKS $field
      } 
      
      return [json_create "usersersBooks" $field]
      
      $d close
}
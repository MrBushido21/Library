package require tcldbf
source utils.tcl

proc log {username userPass} {
      set file_name "users.dbf"
      dbf d -open $file_name
      set NAMES [$d values NAME]
      set PASSES [$d values PASSWORD]
      
      set relustTestUsername [testUsernameUtils $NAMES $username]
      set relustTestPass [testPassUtils $PASSES $userPass]
           
      if {$relustTestUsername == 1 && $relustTestPass == 1} {
            set rowid [searchUtilsStrict $NAMES $username]
            set STATUS [$d get $rowid STATUS]
            return $STATUS
      } else {
            return 0
      }
      $d close

}

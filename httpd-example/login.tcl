package require tcldbf
source utils.tcl

proc log {username userPass} {
      set file_name "users.dbf"
      dbf d -open $file_name
      set NAMES [$d values NAME]
      set PASSES [$d values PASS]
      
      set relustTestUsername [testUsernameUtils $NAMES $username]
      set relustTestPass [testPassUtils $PASSES $userPass]
           
      if {$relustTestUsername == 1 && $relustTestPass == 1} {
            return 1
      } else {
            return "uncorrect username or pass"
      }
      $d close

}

package require tcldbf
source utils.tcl

proc login {username userPass} {
      set file_name "test5.dbf"
      dbf d -open $file_name
      set NAMES [$d values NAME]
      set PASSES [$d values PASS]
      
      # set relustTestUsername [testUsername $NAMES $username]
      # set relustTestPass [testPass $PASSES $userPass]
   
      puts $NAMES
      # if {$relustTestUsername == 1 && $relustTestPass == 1} {
      #       return "correct"
      # } else {
      #       return "uncorrect username or pass"
      # }
      $d close

}

puts [login Oleg qweqqwqwqd]






	

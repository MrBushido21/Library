package require tcldbf
source utils.tcl

proc log {username userPass} {
      set file_name "users.dbf"
      dbf d -open $file_name

      set noDeletedName {}
      set noDeletedPasswords {}
      set total [lindex [$d info records] 0]
      for {set i 0} {$i < $total} {incr i} {
            if {![$d deleted $i] == 1} {
                  lappend noDeletedName [lindex [$d record $i] 0]
                  lappend noDeletedPasswords [lindex [$d record $i] 1]
            }
      }
      set relustTestUsername [testUsernameUtils $noDeletedName $username]
      set relustTestPass [testPassUtils $noDeletedPasswords $userPass]

      if {$relustTestUsername == 1 && $relustTestPass == 1} {
            set rowid [searchUtilsStrict $noDeletedName $username]
            set STATUS [$d get $rowid STATUS]
            set banstatus [$d get $rowid BANSTATUS]
            if {$banstatus eq "Ban"} {
                  return "Sorry but you have ban"
            }
            return $STATUS
      } else {
            return "Uncorect username or password"
      }
      $d close

}

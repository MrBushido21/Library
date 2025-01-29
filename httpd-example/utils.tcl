source json.tcl

# Login
#====================================================
proc testUsernameUtils {data username} {
    foreach name $data {
        if {[string match $username $name]} {
            return 1
        } 
    }
    return "wrong"
}

proc testPassUtils {data userPass} {
    foreach pass $data {
        if {[string match $userPass $pass]} {
                return 1
            } 
       }
       return "wrong pass"
}

#====================================================
# Search 

proc searchUtils {data bookName} {
    set rowid {}
      set i 0
      foreach name $data {
            if {[string match -nocase *$bookName* $name]} {
                  lappend rowid $i
            }
            incr i
      }

         
      return $rowid
}

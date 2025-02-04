proc sortUtils {records index decreasing} {
      if {$decreasing ne ""} {
           set sortedRecords [lsort -decreasing -index $index $records] 
      } else {
            set sortedRecords [lsort -index $index $records]
      }
      
      set books {}
      foreach list $sortedRecords {
            lappend books [lindex $list 2]
      }
      return $books
}

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

proc searchUtilsStrict {data username} {
    set rowid {}
      set i 0
      foreach name $data {
            if {[string match -nocase $username $name]} {
                  lappend rowid $i
            }
            incr i
      }

         
      return $rowid
}

proc testUsernameUtils {data username} {
    foreach name $data {
        if {[string match $username $name]} {
            return 1
        } 
    }
    return "wrong"
}
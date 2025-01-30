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
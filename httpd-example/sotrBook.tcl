package require tcldbf
source utils.tcl

proc sort {index decreasing} {
      set file_name "books.dbf"
      dbf d -open $file_name
      set quantity [$d info records]

      set records {}
      for {set i 0} {$i < $quantity} {incr i} {
            lappend records [$d record $i]
      }
      return [json_create "books" [sortUtils $records $index $decreasing]]
      $d close
}
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
      set sirtedList [sortUtils $records $index $decreasing]
      set json {}
      foreach name $sirtedList {
            set rowid [searchUtilsStrict $sirtedList $name]
            set text [$d get $rowid bookText]
            set author [$d get $rowid author]
            set date [$d get $rowid date]
            set name $name

            lappend json [subst {"name":"$name", "text":"$text", "author":"$author", "date":"$date"}] ","
      }

      return \[[string range $json 0 end-1]\]
      $d close
}
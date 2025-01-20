source json.tcl
package require tcldbf

proc database {} {
      set file_name "test5.dbf"
      dbf d -open $file_name
      set data [$d values NAME]
      $d close
      return [json_array $data]
}

puts [database]

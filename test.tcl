package require tcldbf
source json.tcl

# proc json_create {name args} {
#     json_list $name [json_array {*}[lmap a $args {json_value $a}]]
# }
# proc json_create {name args} {
#     return [json_list $name[json_array {*}[lmap a $args {json_value $a}]]]
# }
# Result {"username":["Oleg Ruslan Nekit Nekit Oleg Oleg Ruslan Ruslan Ruslan Ruslan"]}
proc database {} {
      set file_name "test5.dbf"
      dbf d -open $file_name
      set data [$d values NAME]
      $d close
      # return [json_create "username" $data]
      return [json_list "username" [json_array {*}[lmap a $data {json_value $a}]]]
}
#{"username":["Oleg", "Ruslan", "Nekit", "Nekit", "Oleg", "Oleg", "Ruslan", "Ruslan", "Ruslan", "Ruslan"]}
puts [database]
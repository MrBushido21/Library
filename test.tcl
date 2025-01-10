package require tcldbf
set file_name "test5.dbf"
dbf d -open $file_name
puts [$d update 1 age 20]
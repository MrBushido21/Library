#!/usr/bin/tclsh

package require tcldbf

set users {}

proc login {id} {
   global users
   puts "Enter name"
   flush stdout
   set name [gets stdin]
   puts "Enter age"
   flush stdout
   set age [gets stdin]	
   dict set users $id name $name
   dict set users $id age $age
}

set i 0

while {$i < 3} {
login $i 
incr i
}


# default codepage "LDID/87" ( 87 - system ANSI, 38/101 - cp866, 201 - cp1251 ) */


set file_name "test5.dbf"
          
  dbf d -create $file_name -codepage "LDID/38"
  $d add NAME String 12
  $d add AGE Integer 2
 dict for {i value} $users {
   $d insert $i [dict get $users $i name] [dict get $users $i age]	    
}
 $d close
puts "Succses"	
	

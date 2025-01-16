#!/usr/bin/tclsh

package require tcldbf

set users {}
set name ""
set pass ""

proc login {id name pass} {
   global users
   dict set users $id name $name
   dict set users $id age $pass
}


proc createUser {name pass} {
 global name
 global pass
 set name $name 
 set pass $pass
}

set i 0
proc generateId {id} {
   while {$i < $id} {
      login $i $name
      incr i
   }
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
	

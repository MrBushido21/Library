#!/usr/bin/tclsh

package require tcldbf

proc login {nameValue passValue} {
   set file_name "users.dbf"
   
    if {[file exists $file_name]} {
      dbf d -open $file_name
      $d update end NAME $nameValue PASS $passValue
      $d close
    } else {
      dbf d -create $file_name -codepage "LDID/38"
      $d add NAME String 12
      $d add PASS String 50
      $d insert 0 $nameValue $passValue
      $d close
    }     
   
   puts "Succses"	
}




# default codepage "LDID/87" ( 87 - system ANSI, 38/101 - cp866, 201 - cp1251 ) */



	

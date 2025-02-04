#!/usr/bin/tclsh

package require tcldbf

proc reg {nameValue passValue} {
   set file_name "users.dbf"
   
    if {[file exists $file_name]} {
      dbf d -open $file_name
      set data [$d values NAME]
      if {[lsearch -exact $data $nameValue] == -1} {
            $d update end NAME $nameValue PASSWORD $passValue STATUS "user"
            $d close       
        } else {
           return "A user with this name already exists, please think of another username"  
        }
    } else {
      dbf d -create $file_name -codepage "LDID/38"
      $d add NAME String 50
      $d add PASSWORD String 50
      $d add BOOKS String 250
      $d add FINES String 250
      $d add REQUESTS String 250
      $d add STATUS String 9
      $d add PASS String 1
      $d insert end $nameValue $passValue "" "" "" "admin" "0"
      $d close
    }     
}



	

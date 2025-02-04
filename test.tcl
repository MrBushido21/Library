package require tcldbf
package require json
source utils.tcl
source json.tcl

proc getusers {} {
    set file_name "users.dbf"
    dbf d -open $file_name
    set NAMES [$d values NAME]
    set PASSES [$d values PASS]
   
    set json {}
    foreach name $NAMES {
        set rowid [searchUtilsStrict $NAMES $name]
        set PASS [$d get $rowid PASS]
        set name $name

        lappend json [subst {"name":"$name", "pass":"$PASS"}] ","
    }

    return \[[string range $json 0 end-1]\] 
    $d close
}

puts [getusers]


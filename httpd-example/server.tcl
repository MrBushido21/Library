source json.tcl
source httpd.tcl
source registration.tcl
source login.tcl
package require tcldbf
namespace import httpd::*

### server

set wwwroot www
set wwwport 8000
set encoding cp1251

proc filecontent {filename} {
    set f [open [file join $::wwwroot $filename]]
    fconfigure $f -encoding $::encoding
    set d [read $f]
    close $f
    return $d
}


proc handler { op sock } {
    if { $op eq "handle" } {
        httpd loadrequest $sock data query
        if { [info exists data(url)] } {
            set path [string trimleft $data(url) /]
            puts "parse path '$path'"
            switch -glob -- $path {
                "register" {httpd return $sock [register data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "login"    {httpd return $sock [login data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                ""         {httpd return $sock [filecontent index.html] -mimetype "text/html"}
                "*.js"     {httpd return $sock [filecontent $path] -mimetype "text/javascript"}
                "*.gif"    {httpd returnfile $sock [file join $::wwwroot $path] $path "image/gif" [clock seconds] 1 -static }
                "*.png"    {httpd returnfile $sock [file join $::wwwroot $path] $path "image/png" [clock seconds] 1 -static }
                "*.jpg"    {httpd returnfile $sock [file join $::wwwroot $path] $path "image/jpeg" [clock seconds] 1 -static }
                "*.ico"    {httpd returnfile $sock [file join $::wwwroot $path] $path "image/x-icon" [clock seconds] 1 -static }
                "*.css"    {httpd return $sock [filecontent $path] -mimetype "text/css"}
                "*.html"   {httpd return $sock [filecontent $path] -mimetype "text/html"}
                default    {httpd error $sock 404 ""}
            }
        }
    }
}


### test url
set username ""

proc register {datavar query headers} {
    upvar $datavar data
    parray data

    set newData [json_value $data(postdata)]
    set arr [string map {"\"" " " "" "" ":" "" "," "" "\\" ""} $newData]
    set arrList [split $arr " "]
    set name [lindex $arrList 4]
    set pass [lindex $arrList 8]
    array set newArr "name $name pass $pass"
    set username $newArr(name)
    reg $newArr(name) $newArr(pass)
}
proc login {datavar query headers} {
    upvar $datavar data
    parray data

    set newData [json_value $data(postdata)]
    set arr [string map {"\"" " " "" "" ":" "" "," "" "\\" ""} $newData]
    set arrList [split $arr " "]
    set name [lindex $arrList 4]
    set pass [lindex $arrList 8]
    array set newArr "name $name pass $pass"
    log $newArr(name) $newArr(pass)
}



### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


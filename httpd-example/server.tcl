source json.tcl
source httpd.tcl
source registration.tcl
source login.tcl
source searchBook.tcl
source sotrBook.tcl
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
                "register"     {httpd return $sock [register data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "login"        {httpd return $sock [login data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "searchbooks"  {httpd return $sock [searchbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "sortbooks"    {httpd return $sock [sortbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "getbooks"     {httpd return $sock [getbooks] -mimetype "text/html"}
                ""             {httpd return $sock [filecontent index.html] -mimetype "text/html"}
                "*.js"         {httpd return $sock [filecontent $path] -mimetype "text/javascript"}
                "*.gif"        {httpd returnfile $sock [file join $::wwwroot $path] $path "image/gif" [clock seconds] 1 -static }
                "*.png"        {httpd returnfile $sock [file join $::wwwroot $path] $path "image/png" [clock seconds] 1 -static }
                "*.jpg"        {httpd returnfile $sock [file join $::wwwroot $path] $path "image/jpeg" [clock seconds] 1 -static }
                "*.ico"        {httpd returnfile $sock [file join $::wwwroot $path] $path "image/x-icon" [clock seconds] 1 -static }
                "*.css"        {httpd return $sock [filecontent $path] -mimetype "text/css"}
                "*.html"       {httpd return $sock [filecontent $path] -mimetype "text/html"}
                default        {httpd error $sock 404 ""}
            }
        }
    }
}


### test url


proc request {data indices} {
    set newData [json_value $data]
    set arr [string map {"\"" " " "" "" ":" "" "," "" "\\" ""} $newData]
    set arrList [split $arr " "]
    set result {}
    foreach {key idx} $indices {
        set value [lindex $arrList $idx]
        if {$value ne ""} {
            lappend result $key $value
        } else {
            lappend result $key ""
        }
    }
    array set newArr $result
    return [array get newArr]
}

#==================================
#GET
proc getbooks {} {
    set file_name "books.dbf"
    dbf d -open $file_name
    set data [$d values bookName]
    $d close
    return [json_create "books" $data]
}

#==================================
#POST
proc register {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata) {name 4 pass 8}]
    reg $arr(name) $arr(pass)
}
proc login {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata) {name 4 pass 8}]
    log $arr(name) $arr(pass)
}
proc searchbooks {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata) {name 4 field 8}]
    search $arr(name) $arr(field)
}
proc sortbooks {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata) {index 4 decreasing 8}]
    sort $arr(index) $arr(decreasing)
}



### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


source json.tcl
source httpd.tcl
source registration.tcl
source login.tcl
source searchBook.tcl
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
                "searchName"   {httpd return $sock [searchName data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "searchAuthor" {httpd return $sock [searchAuthor data [array get query] [httpd headers $sock]] -mimetype "text/json"}
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

proc request {data} {
    set newData [json_value $data]
    set arr [string map {"\"" " " "" "" ":" "" "," "" "\\" ""} $newData]
    set arrList [split $arr " "]
    set name [lindex $arrList 4]
    set pass [lindex $arrList 8]
    set arrList [list name $name]
    if {$pass ne ""} {
        lappend arrList pass $pass
    } else {
        lappend arrList pass ""
    }
    array set newArr $arrList
    return [array get newArr]
}


proc register {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata)]
    reg $arr(name) $arr(pass)
}
proc login {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata)]
    log $arr(name) $arr(pass)
}

proc getbooks {} {
    set file_name "books.dbf"
    dbf d -open $file_name
    set data [$d values bookName]
    $d close
    return [json_create "books" $data]
}

proc searchName {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata)]
    puts $arr(name)
    search "bookName" $arr(name)
}
proc searchAuthor {datavar query headers} {
    upvar $datavar data
    parray data
    array set arr [request $data(postdata)]
    puts $arr(name)
    search "author" $arr(name)
}

### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


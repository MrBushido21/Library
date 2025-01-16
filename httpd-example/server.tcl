source json.tcl
source httpd.tcl
source books.tcl

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
                "test*"  {httpd return $sock [gettest data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                ""       {httpd return $sock [filecontent index.html] -mimetype "text/html"}
                "*.js"   {httpd return $sock [filecontent $path] -mimetype "text/javascript"}
                "*.gif"  {httpd returnfile $sock [file join $::wwwroot $path] $path "image/gif" [clock seconds] 1 -static }
                "*.png"  {httpd returnfile $sock [file join $::wwwroot $path] $path "image/png" [clock seconds] 1 -static }
                "*.jpg"  {httpd returnfile $sock [file join $::wwwroot $path] $path "image/jpeg" [clock seconds] 1 -static }
                "*.ico"  {httpd returnfile $sock [file join $::wwwroot $path] $path "image/x-icon" [clock seconds] 1 -static }
                "*.css"  {httpd return $sock [filecontent $path] -mimetype "text/css"}
                "*.html" {httpd return $sock [filecontent $path] -mimetype "text/html"}
                "login"  {}
                default  {httpd error $sock 404 ""}
            }
        }
    }
}


### test url

proc gettest {datavar query headers} {
    upvar $datavar data
    parray data

    set l {}
    foreach i {url ipaddr proto protocol outputheaders version query} {
       if {[info exists data($i)]} {
           lappend l $i [json_value $data($i)]
       }
    }
    lappend l "query" [json_value $query]
    lappend l "headers" [json_value $headers]

    #json_list 
    set newData [json_value $data(postdata)]
    set arr [string map {"\"" " " "" "" ":" "" "," "" "\\" ""} $newData]
    set arrList [split $arr " "]
    set name [lindex $arrList 4]
    set pass [lindex $arrList 8]
    # array unset newArr
    array set newArr "name $name pass $pass"
    puts $newArr(name)
    # createUser $newArr(name) $newArr(pass)
    # generateId [llength [array names newArr]]
}

### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


source json.tcl
source httpd.tcl
source registration.tcl
source login.tcl
source searchBook.tcl
source sotrBook.tcl
source usersBooks.tcl
package require tcldbf
package require json
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
                "register"          {httpd return $sock [register data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "login"             {httpd return $sock [login data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "searchbooks"       {httpd return $sock [searchbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "sortbooks"         {httpd return $sock [sortbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "usersbooks"        {httpd return $sock [usersbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "updateusersbooks"  {httpd return $sock [updateusersbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "takeusersbooks"    {httpd return $sock [takeusersbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "getbooks"          {httpd return $sock [getbooks] -mimetype "text/html"}
                ""                  {httpd return $sock [filecontent index.html] -mimetype "text/html"}
                "*.js"              {httpd return $sock [filecontent $path] -mimetype "text/javascript"}
                "*.gif"             {httpd returnfile $sock [file join $::wwwroot $path] $path "image/gif" [clock seconds] 1 -static }
                "*.png"             {httpd returnfile $sock [file join $::wwwroot $path] $path "image/png" [clock seconds] 1 -static }
                "*.jpg"             {httpd returnfile $sock [file join $::wwwroot $path] $path "image/jpeg" [clock seconds] 1 -static }
                "*.ico"             {httpd returnfile $sock [file join $::wwwroot $path] $path "image/x-icon" [clock seconds] 1 -static }
                "*.css"             {httpd return $sock [filecontent $path] -mimetype "text/css"}
                "*.html"            {httpd return $sock [filecontent $path] -mimetype "text/html"}
                default             {httpd error $sock 404 ""}
            }
        }
    }
}


### test url

proc request {data} {
    set data [json::json2dict $data]
    
    return [dict values $data]
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
    set list [request $data(postdata)]
    reg [lindex $list 0] [lindex $list 1]
}
proc login {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    log [lindex $list 0] [lindex $list 1]
}
proc searchbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    search [lindex $list 0] [lindex $list 1]
}
proc sortbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    sort [lindex $list 0] [lindex $list 1]
}
proc usersbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    createBookList [lindex $list 0] [lindex $list 1]
}
proc takeusersbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    takeBookList [lindex $list 0]
}
proc updateusersbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    updateBookList [lindex $list 0] [lindex $list 1]
}



### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


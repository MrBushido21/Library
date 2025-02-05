source json.tcl
source utils.tcl
source httpd.tcl
source registration.tcl
source login.tcl
source searchBook.tcl
source sotrBook.tcl
source usersBooks.tcl
source librarian.tcl
source admin.tcl
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
                "getfines"          {httpd return $sock [getfines data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "createrequest"     {httpd return $sock [createrequest data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "takeusersbooks"    {httpd return $sock [takeusersbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "userrequests"      {httpd return $sock [userrequests data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "editbooks"         {httpd return $sock [editbooks data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "deletebook"        {httpd return $sock [deletebook data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "createbook"        {httpd return $sock [createbook data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "createlibrarian"   {httpd return $sock [createlibrarian data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "deleteduser"       {httpd return $sock [deleteduser data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "banuser"           {httpd return $sock [banuser data [array get query] [httpd headers $sock]] -mimetype "text/json"}
                "getbooks"          {httpd return $sock [getbooks] -mimetype "text/html"}
                "getusers"          {httpd return $sock [getusers] -mimetype "text/html"}
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
    set bookNames [$d values bookName]
        
    set noDeletedBooks {}
    set total [lindex [$d info records] 0]
    for {set i 0} {$i < $total} {incr i} {
        if {![$d deleted $i] == 1} {
            lappend noDeletedBooks [lindex [$d record $i] 1]
        }
    } 

    set json {}
    foreach name $noDeletedBooks {
        set rowid [searchUtilsStrict $noDeletedBooks $name]
        set text [$d get $rowid bookText]
        set author [$d get $rowid author]
        set date [$d get $rowid date]
        set name $name

        lappend json [subst {"name":"$name", "text":"$text", "author":"$author", "date":"$date"}] ","
    }

    return \[[string range $json 0 end-1]\]  
    $d close
}
proc getusers {} {
    set file_name "users.dbf"
    dbf d -open $file_name
    set NAMES [$d values NAME]

    set noDeletedUsers {}
    set total [lindex [$d info records] 0]
    for {set i 0} {$i < $total} {incr i} {
        if {![$d deleted $i] == 1} {
            lappend noDeletedUsers [lindex [$d record $i] 0]
        }
    }
    set json {}
    foreach name $noDeletedUsers {
        set rowid [searchUtilsStrict $noDeletedUsers $name]
        set PASS [$d get $rowid PASS]
        set STATUS [$d get $rowid STATUS]
        set BANSTATUS [$d get $rowid BANSTATUS]
        set name $name

        lappend json [subst {"name":"$name", "pass":"$PASS", "status": "$STATUS", "banstatus": "$BANSTATUS"}] ","
    }

    return \[[string range $json 0 end-1]\] 
    $d close
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
    takeBookList [lindex $list 1]
}
proc userrequests {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    getuserrequests [lindex $list 0]
}
proc updateusersbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    updateBookList [lindex $list 0] [lindex $list 1]
}
proc getfines {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    getFines [lindex $list 0] [lindex $list 1]
}
proc createrequest {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    createRequest [lindex $list 0] [lindex $list 1]
}
proc editbooks {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    editBooks [lindex $list 0] [lindex $list 1] [lindex $list 2] [lindex $list 3] [lindex $list 4]
}
proc deletebook {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    deleteBook [lindex $list 0]
}
proc createbook {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    createBook [lindex $list 0] [lindex $list 1] [lindex $list 2] [lindex $list 3]
}
proc createlibrarian {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    createLibrarian [lindex $list 0] [lindex $list 1]
}
proc deleteduser {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    deletedUser [lindex $list 0]
}
proc banuser {datavar query headers} {
    upvar $datavar data
    parray data
    set list [request $data(postdata)]
    banUser [lindex $list 0]
}






### start

puts "server listen on port: $wwwport"
httpd listen $wwwport handler
vwait forever


#

# rfc2396 unreserved URI characters, except for + which receives special treatment by the HTTP URL scheme.
set encodeurl_unreservedChars "-.!~*'()0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
set russian_A \u0410

proc Log {level id args} {puts stderr [list $id $level $args]}
proc bgerror args {puts stderr $args}

package ifneeded sqlite 3.0 "load [file join [testsDirectory] .. .. .. bin abonsql.dll] sqlite3; package provide sqlite 3.0"
package ifneeded tclodbc 2.2 "load [file join [testsDirectory] .. .. .. bin abonodbc.dll] tclodbc"
package ifneeded Oratcl 4.5 "load [file join [testsDirectory] .. .. .. bin abonora.dll] Oratcl"

proc HttpSource__encodeurl {string {encoding utf-8}} {
    set _noencodeurl "/?;=&$,-.!~*'()0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" ;# :@+
    set result ""
    foreach char [split [encoding convertto $encoding $string] ""] {
        if {[string first $char $_noencodeurl] >= 0} {
            append result $char
        } else {
            scan $char %c i
            append result [format %%%02X $i]
        }
    }
    return $result
}

proc testurl {url} {
    array set a [aserv::parseurl $url]
    return [list \
        $a(proto) \
        $a(user) \
        $a(password) \
        $a(host) \
        $a(port) \
        $a(path) \
        $a(form) \
        $a(hash)]
}

proc testpath {path} {
    array set a [aserv::parsepath $path]
    return [list \
        $a(path) \
        $a(form) \
        $a(hash)]
}

proc testquery {url {headerslist {}} {data {}}} {
    array set a [aserv::parseurl $url]
    set query $a(path)
    append query [expr {$a(form) ne "" ? "?$a(form)" : ""}]
    append query [expr {$a(hash) ne "" ? "#$a(hash)" : ""}]
    set headers ""
    foreach i $headerslist {
        append headers [join $i ": "] \n
    }
    if {$data eq {}} {
        set method "GET"
    } else {
        set method "POST"
        append headers "Content-Length: " [string length $data] \n\n
    }
    if {$headers ne ""} {
        set headers \n$headers
    }
    set version " HTTP/1.0"
    set chan [socket -async $a(host) $a(port)]
    fconfigure $chan -buffering none -blocking 0 -encoding binary -translation binary  
    fileevent $chan readable [format {
        append ::testquery_data [read -nonewline {%s}]
        if {[eof {%s}]} {set ::testquery_state ""}
    } $chan $chan]
    if {[info exists ::debug] && $::debug > 0} {
    puts stderr "$method $query$version$headers$data"
    }
    puts $chan  "$method $query$version$headers$data"
    puts $chan  ""
    flush $chan
    set ::testquery_data {}
    vwait ::testquery_state
    set result [encoding convertfrom utf-8 $::testquery_data]
    unset ::testquery_state ::testquery_data
    fileevent $chan readable {}
    if {[info exists ::debug] && $::debug > 0} {
    puts stderr ---\n$result\n---
    }
    close $chan
    return $result
}

proc parseresponse {what response} {
    switch -- $what {
        result {return [lindex [regexp -inline {(HTTP/.*?)\n} $response] 1]}
        headers {return [lindex [regexp -inline {\n(.*)\n\n} $response] 1]}         
        default {return [lindex [regexp -inline {\n\n(.*)}  $response] 1]}
    }  
}

proc stripxmlstamp {xml} {
    regsub {(\W)stamp=["']([0-9 :-]+)["'](\W)} $xml "\\1STAMP\\3"
}

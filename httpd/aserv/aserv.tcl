# $Id$

# Copyright (c) 2015,2018 by Oleg Oleinick
#

package require Tcl 8.4
package require tdom
package require msgcat

# patch msgcat for Russian lang 419
#set ::msgcat::WinRegToISO639(0419) ru_RU
#set ::msgcat::WinRegToISO639(419) ru_RU
# clean up error info after msgcat::init failed for windows encoding 419 (tcl8.4,msgcat1.3.3)
set ::errorInfo ""
set ::errorCode 0

namespace import -force ::msgcat::mc

namespace eval ::aserv {

    variable library [file dirname [info script]]
    variable version 1.2
    variable patchlevel 0

    variable root ""
    variable encoding ""

    proc log {level args} {
        if {$level == 0 || ([info exists ::debug] && $level <= $::debug)} {
            if {[info proc ::Log] ne ""} {
                if {$::debug >= 9} {
                   ::Log $level ASERV $args \n$::errorInfo
                } else {
                   ::Log $level ASERV $args
                }
            }
        }
    }

    proc locale {lang} {
        ::msgcat::mclocale $lang
        ::uplevel \#0 ::msgcat::mcload [file join $::aserv::library msgs]
    }

    proc patch {} {
        set i 0
        set dir [file join $::aserv::library patches]
        foreach ext {tcl tk tbc} {
            foreach patch [lsort [glob -nocomplain -type f -dir $dir *.$ext]] {
                uplevel \#0 source $patch
                incr i
            }
        }
        return $i
    }

    proc parseform {form} {
        set re {([^?=&]+)(=([^&]*))?}
        set result {}
        foreach {- key - value} [regexp -inline -all $re $form] {
            lappend result $key $value
        }
        return $result
    }
 
    proc parsepath {path} {
        set re {([^?#]*)(\?([^#]*))?(#(.*))?}
        if { ! [regexp $re $path - path - form - hash]} {
            error [mc "Invalid path '%s'" $path]
        }
        return [list path [file split $path] form [parseform $form] hash $hash]
    } 

    proc parseurl {url} {
        set re {^(([a-z]*)://)?(([^:@]*)?(:([^@]*))?@)?([^/:]+)(:([0-9]+))?(/.*)?$}
        foreach {proto user password host port srvpath path form hash} {{}} break
        if { ! [regexp -nocase $re $url - - proto - user - password host - port srvpath] } {
            set proto "file"
            set path $url
        } else {
            if { $proto eq "" }   {set proto "http"}
            if { $port eq "" }    {set port 80}
            if { $srvpath eq ""}  {set srvpath "/"}
            set re {([^?#]*)(\?([^#]*))?(#(.*))?}
            if { ! [regexp $re $srvpath - path - form - hash]} {
                error [mc "Invalid URL '%s'" $url]
            } 
        }
        return [list proto $proto user $user password $password host $host port $port path $path form $form hash $hash]
    }

    proc filecontents {filename} {
        set f [open [file join $aserv::root $filename]]
        if { $aserv::encoding ne ""} {
            fconfigure $filename -encoding $aserv::encoding
        }
        set d [read $f]
        close $f
        return $d
    }

    proc start {port} {
        set ::aserv::handle "start"
        httpd listen $port ::aserv::handler
    }
    
    proc wait {} {
        set ::aserv::handle "wait"
        vwait ::aserv::handle
    }

    proc break {} {
        set ::aserv::handle "break"
    }

    proc stop {} {
        httpd stop
        unset ::aserv::handle
    }

    proc handler {op sock} {
        log 4 handler [list $op $sock]
        if { $op eq "handle" } {
            log 5 handler [list loadrequest $sock data query]
            httpd loadrequest $sock data query
            log 4 handler [list request [array get data] query [array get query]]
            if { [info exists data(url)] } {
                set path [string trimleft $data(url) /]
                switch -glob -- $path {
                    "trap*"  {httpd return $sock [getmnctrap data [array get query] [httpd headers $sock]] -mimetype "text/plain"}
                    "ping*"  {httpd return $sock [getmncping $path] -mimetype "text/xml"}
                    "mnc/*"  {httpd return $sock [getmncpath $path] -mimetype "text/xml"}
                    ""       {httpd return $sock [filecontents index.html] -mimetype "text/html"}
                    "*.js"   {httpd return $sock [filecontents $path] -mimetype "text/javascript"}
                    "*.gif"  {httpd returnfile $sock [file join $aserv::root $path] $path "image/gif" [clock seconds] 1 -static }
                    "*.png"  {httpd returnfile $sock [file join $aserv::root $path] $path "image/png" [clock seconds] 1 -static }
                    "*.jpg"  {httpd returnfile $sock [file join $aserv::root $path] $path "image/jpeg" [clock seconds] 1 -static }
                    "*.ico"  {httpd returnfile $sock [file join $aserv::root $path] $path "image/x-icon" [clock seconds] 1 -static }
                    "*.css"  {httpd return $sock [filecontents $path] -mimetype "text/css"}
                    "*.html" {httpd return $sock [filecontents $path] -mimetype "text/html"}
                    default  {httpd error $sock 404 ""}
                }
            }
        }
    }

    proc getmnctrap {datavar query headers} {
        upvar $datavar data
        set l {}
        foreach i {url ipaddr proto protocol outputheaders version query} {
           if {[info exists data($i)]} {
               lappend l "trap $i: $data($i)"
           }
        }
        lappend l "trap getform: $query"
        lappend l "trap headers: $headers"
        return [join $l \n]
    }

    proc getmncping {path} {
        dom createDocument ping doc
        $doc documentElement mnc
        $mnc setAttribute stamp \
            [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        $mnc appendChild [$doc createTextNode "pong"]
        return [$mnc asXML]
    }
    
    proc getmncpath {path} {
        log 2 "getmncpath" "entry" $path 
        array set a [parsepath $path]
        log 3 "getmncpath" "parse" [array get a] 
        if {[lindex $a(path) 0] eq "mnc"} {
            set query [lindex $a(path) 1]
            foreach ns [namespace children ::aserv::source::] {
                if {[lsearch [${ns}::list] $query]} {
                    array set form $a(form)
                    set arglist {}
                    foreach arg [info args ${ns}::get-$query] {
                        if {[info exists form($arg)]} {
                            lappend arglist $form($arg)
                        } else {
                            lappend arglist {}
                        }
                    }
                    log 3 "getmncpath" "call" [list ${ns}::get-$query $arglist]
                    return [eval [list ${ns}::get-$query] $arglist]
                }
            }
        } 
        log 1 "getmncpath" "missing handler for $path"
        return "abstract: $path"
    }

    proc sourceinit {sourcetype args} {
        set sourcetypelib [file join $::aserv::library scripts aserv-$sourcetype.tbc]
        if {![file exists $sourcetypelib]} {
            set sourcetypelib [file join $::aserv::library scripts aserv-$sourcetype.tcl]
        }
        if {[file exists $sourcetypelib]} {
            source $sourcetypelib
            return [eval [list ::aserv::source::${sourcetype}::init] $args]
        }
        log 0 "source not found: $sourcetypelib"
        return false
    }

    proc sourcedone {sourcetype} {
        aserv::source::${sourcetype}::done
        namespace delete ::aserv::source::$sourcetype
        set source ""
    }

    proc sourceeval {sourcetype command args} {
        eval [list ::aserv::source::${sourcetype}::${command}] $args
    }
}

source [file join $::aserv::library scripts httpd.tcl]
                               
package provide Aserv $::aserv::version
package provide aserv $::aserv::version

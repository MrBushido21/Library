# Adapted from
#    https://wiki.tcl-lang.org/page/Tkcon+Remote+Access+over+TCP+Sockets
#
# Useful on Android in ~/.wishrc for remote control
#
#    package require tkconclient
#    tkconclient::start 12345
#
# when USB debugging is on, forward port 12345 of the device
# with the following adb command on the development system
#
#    adb forward tcp:12345 tcp:12345
#
# then use tkcon's attach to socket function with localhost 12345
# or alternatively use "netcat localhost 12345",
# or alternatively use "socat TCP:localhost:12345 STDIO",
# or use "telnet localhost 12345".

namespace eval tkconclient {
    variable script ""
    variable server ""
    variable socket ""
    namespace export start stop
    proc start {port {myaddr {}}} {
        variable socket
        variable server
        if {$socket ne "" || $server ne ""} {
            stop
        }
        if {$myaddr eq ""} {
            set server [socket -server [namespace current]::accept $port]
        } else {
            set server [socket -server [namespace current]::accept \
                            -myaddr $myaddr $port]
        }
    }
    proc stop {} {
        variable server
        if {$server ne ""} {
            closesocket
            close $server
            set server ""
        }
    }
    proc closesocket {} {
        variable socket
        if {$socket eq ""} {
            return
        }
        catch {close $socket}
        set socket ""
        # Restore puts command
        rename ::puts ""
        rename [namespace current]::puts ::puts
    }
    proc accept {sock host port} {
        variable socket
        fconfigure $sock -blocking 0 -buffering none
        if {$socket ne ""} {
            puts $sock "Only one connection at a time, please!"
            close $sock
        } else {
            set socket $sock
            fileevent $sock readable [namespace current]::handle
            # Redirect puts command
            rename ::puts [namespace current]::puts
            interp alias {} ::puts {} [namespace current]::_puts
        }
    }
    proc handle {} {
        variable script
        variable socket
        if {[eof $socket]} {
            closesocket
            return
        }
        if {![catch {read $socket} chunk]} {
            if {$chunk eq "bye\n"} {
                puts $socket "Bye!"
                closesocket
                return
            }
            append script $chunk
            if {[info complete $script]} {
                catch {uplevel "#0" $script} result
                if {$result ne ""} {
                    puts $socket $result
                }
                set script ""
            }
        } else {
            closesocket
        }
    }
    # Procedure partially borrowed from tkcon
    proc _puts args {
        variable socket
        set len [llength $args]
        lassign $args arg1 arg2 arg3
        switch $len {
            1 {
                puts $socket $arg1
                return
            }
            2 {
                switch -- $arg1 {
                    -nonewline {
                        puts -nonewline $socket $arg2
                        return
                    }
                    stdout - stderr {
                        puts $socket $arg2
                        return
                    }
                }
            }
            3 {
                if {$arg1 eq "-nonewline" &&
                    ($arg2 eq "stdout" || $arg2 eq "stderr")} {
                    puts -nonewline $socket $arg3
                    return
                }
            }
        }
        # not handled in switch above
        if {[catch [linsert $args 0 puts] msg]} {
            return -code error $msg
        }
        return $msg
    }
}

package provide tkconclient 1.0


#!/bin/sh
#\
exec wish "$0" ${1+"$@"}
# evalClient --
# starts the evalServer and set up connection to it
# provides an execution terminal which shows the output of the commands
# it´s also possible to execute commands via this terminal

# package require Tk

namespace eval Client {
    variable terminal
    variable port
    variable shutdown 0
    variable serverInitDone 0
    variable serverPID
    variable thisdir [file normalize [file dirname [info script]]]
}

proc Client::runTclApp {sock} {
    global tk_library
    global tcl_library
    global tcl_platform
    global auto_path

    set filename [tk_getOpenFile]
    if {$filename eq ""} {
        return
    }
    set fd [open $filename r]
    set data [read $fd]
    close $fd
    set curDir [pwd]
    puts $sock "cd [file dirname $filename]"
    puts $sock "set argv0 [list $filename]"
    puts $sock "set argv \"\" "
    puts $sock "set argc 0"
    puts $sock "set tcl_library [list $tcl_library]"
    puts $sock "set tk_library [list $tk_library]"
    puts $sock "set auto_path [list $auto_path]"
    puts $sock $data
    puts $sock "wm protocol . WM_DELETE_WINDOW \"puts $sock exit\""
    puts $sock "wm deiconify ."
    puts $sock "focus -force ."
    puts $sock "cd [file dirname $curDir]"

    return
}

proc Client::sockHandler {sock handleProc} {
    variable serverInitDone

    eval $handleProc $sock
    set serverInitDone 1
}

proc Client::showResult {sock} {
    variable terminal

    if [eof $sock] {
        catch {close $sock}
        exit
    }
    if {[gets $sock result] < 0 } {
        catch {close $sock}
        exit
    } elseif {$result ne ""} {
        $terminal(win) insert insert $result\n result
        $terminal(win) see insert
    }

    return
}

proc Client::exitExecutionServer {{serverPort {}} {host localhost}} {
    variable port
    variable shutdown
    global waitforexit

    if {$serverPort ne {}} {
        set port $serverPort
    }
    # setup client sock
    if {[catch {
            set sock [eval [list socket $host $port]]
        } errorInfo ]} {
        return
    }
    # send exit command
    puts $sock "exitASEDServer"
    catch {close $sock}
    set shutdown "done"
    return 0
}

proc Client::initExecutionClient {{host localhost} {port 9001} {sockHandleProc Client::showResult} {serverName ""} {serverWish {}} {timeout 10} {options {}}} {

    global serverUp
    variable serverInitDone
    variable thisdir

    if {$serverWish eq {}} {
        set serverWish [info nameofexecutable]
	if {$servername eq "-x evalServer.tcl"} {
	    set sn [file join $thisdir evalServer.tcl]
	    if {[file exists $sn]} {
		set serverName $sn
	    }
	}
    }
    if {$serverName eq {}} {
	set serverName [file join $thisdir evalServer.tcl]
    }
    # setup client sock
    if {[catch {
            set sock [eval [list socket $host $port]]
        }]} {
        # start execution server
        if {[file exists $serverName] || ($serverName eq "-x evalServer.tcl")} {
            set res [eval [list Client::initExecutionServer $port $serverName $serverWish $options]]
            if {$res == 0} {
                # init of evalServer failed
                puts "Couldn't start evalServer!"
                return ""
            }
            # try again
            after 10000 {set Client::serverInitDone timeout}
            while {[catch {set sock [eval [list socket $host $port]]}]} {
                if {$Client::serverInitDone eq "timeout"} {
                    break
                }
                after 1000 set ::go 1
                vwait ::go
            }
            if {$Client::serverInitDone eq "timeout"} {
                puts "Couldn't connect to evalServer!"
                return ""
            }
        } else {
            puts "Server \"$serverName\" not found!"
            return ""
        }
    }
    fileevent $sock readable [list Client::sockHandler $sock $sockHandleProc]
    fconfigure $sock -buffering none
    fconfigure $sock -blocking 0
    set serverUp 1
    return $sock
}

proc Client::initExecutionServer {{port 9001} {serverName ""} {serverWish {}} {options {}}} {
    global env
    global tcl_platform
    global serverUp
    variable serverPID
    variable thisdir

    if {$serverUp} {
        return
    }
    if {$serverWish eq {}} {
        set serverWish [info nameofexecutable]
	if {$serverName eq "-x evalServer.tcl"} {
	    set serverName [file join $thisdir evalServer.tcl]
	}
    }
    if {$serverName eq {} || $serverName eq "-x evalServer.tcl"} {
	set serverName [file join $thisdir evalServer.tcl]
    }
    # start execution server
    if {$options ne {}} {
        set command [list $serverWish $options $serverName $port]
    } else {
        set command [list $serverWish $serverName $port]
    }
    if {[catch {eval exec $command &} serverPID]} {
        return 0
    } else {
        set serverUp 1
        return 1
    }
}

proc Client::remoteExecute {sock command} {

    puts $sock $command

}

proc Client::initClientTerminal { \
        {host localhost} \
        {port 9001} \
        {serverName ""} \
        {sockHandleProc Client::showResult}} {

    variable terminal

    frame .ft
    set terminal(win) [text .ft.clientTerminal \
            -wrap word \
            -yscrollcommand [list .ft.sb set]]
    scrollbar .ft.sb -orient vertical -command [list .ft.clientTerminal yview]
    $terminal(win) tag configure result -foreground blue
    $terminal(win) tag configure error -foreground red

    # setup client sock
    set terminal(sock) [eval [list Client::initExecutionClient $host $port $sockHandleProc $serverName]]
    if {$terminal(sock) eq {}} {
        return {}
    }

    frame .f
    button .f.b -text "Exit" -command Client::exitExecutionServer
    button .f.c -text "Run Tcl App" -command "Client::runTclApp $terminal(sock)"

    pack $terminal(win) -expand yes -fill both -side left
    pack .ft.sb -fill y -side left
    pack .ft
    pack .f.b .f.c -side left -fill both -expand yes
    pack .f -fill both -expand yes
    bind $terminal(win) <Return> {
        #get command and execute it
        set command [$Client::terminal(win) get "insert linestart" "insert lineend"]
        eval [list puts $Client::terminal(sock) $command]
    }
    wm title . "ASED Execution Terminal"
    wm protocol . WM_DELETE_WINDOW {Client::exitExecutionServer}
    return $terminal(sock)
}

global serverUp
set serverUp 0

if {[string compare [info script] $argv0] == 0} {
    package require Tk

    switch -- $argc {
        0    {
            set Client::port 9001
            set serverName ""
            set sockHandleProc "Client::showResult"
        }
        1    {
            set Client::port [lindex $argv 0]
            set serverName ""
            set sockHandleProc "Client::showResult"
        }
        2    {
            set Client::port [lindex $argv 0]
            set serverName [lindex $argv 1]
            set sockHandleProc "Client::showResult"
        }
        3    {
            set Client::port [lindex $argv 0]
            set serverName [lindex $argv 1]
            set sockHandleProc [lindex $argv 2]
        }
        default {
            # sockHandleProc has to be the the name of the sockHandler proc
            eval [list puts "usage: evalClient.tcl ?port? ?serverName? ?sockHandlerProc?"]
            exit
        }
    }
    eval [list Client::initClientTerminal localhost $Client::port $serverName $sockHandleProc]
}

#!/bin/sh
#\
exec wish "$0" ${1+"$@"}
#########################################
# evalServer -- Version 3.0
# (c) 2004 by Andreas Sievers
# executes each socket in its own interpreter
#########################################


proc initServer {port {putsEcho 1}} {
    if {[catch {socket -server [list EvalAccept $putsEcho] $port } info]} {
        exit
    }
}

proc EvalAccept {echoOn newsock addr port} {
    global eval
    set eval(cmdbuf,$newsock) {}
    set eval(run,$newsock) 0
    set eval(interp,$newsock) [interp create]
    set eval(busy) 0
    set eval(exit_now) 0
    interp eval $eval(interp,$newsock) set sock $newsock
    interp eval $eval(interp,$newsock) set echoOn $echoOn
    interp eval $eval(interp,$newsock) set interp $eval(interp,$newsock)
    $eval(interp,$newsock) alias ExitApp exitApp
    if {$echoOn == 1} {
        $eval(interp,$newsock) alias ASEDServerEcho asedServerEcho
    }
    fileevent $newsock readable [list EvalRead $newsock $eval(interp,$newsock)]
    fconfigure $newsock -blocking 0
    if [catch {
        interp eval $eval(interp,$newsock) {
            # proc exitProc {} {
                # global interp sock
                # ExitApp $interp $sock
            # }
            proc echoPuts {args} {
                global interp sock
                ASEDServerEcho $interp $sock $args
            }
            proc fileputs {args} {
                global interp sock
                eval origPuts $args
            }
            # interp alias {} exit {} exitProc
            if {$echoOn} {
                # catch puts for slave-interps
                rename puts origPuts
                interp alias {} puts {} echoPuts

                rename interp orig_interp

                proc interp {args} {
                    global interp sock
                    if {[lindex $args 0] == "create"} {
                        set slave_interp [eval orig_interp $args]
                        orig_interp eval $slave_interp {rename puts origPuts}
                        orig_interp eval $slave_interp {rename interp orig_interp}
                        # interp alias {} puts {} echoPuts
                    } else {
                        eval orig_interp $args
                    }
                }
            }
        }
    } info] {
        puts "Connection rejected:\n$info"
        close $newsock
    }
}



proc exitApp {interp sock} {
    global eval

    set eval(exit_now) 1
    # wait until "EvalRead" has been finished
    if {$eval(busy)} {
        after 100 "exitApp $interp $sock"
        return
    }
    interp eval $interp {
        set taskList [after info]
        foreach id $taskList {
            after cancel $id
        }
    }
    puts $sock "exitASEDServer"
    catch {close $sock}
    interp delete $interp
    unset eval(cmdbuf,$sock)
    unset eval(cmdsbuf,$sock)
    return
}

proc asedServerEcho {interpret sock args} {
    global errorInfo errorCode

    set code 0
    eval set args $args
    set argcounter [llength $args]
    switch -- $argcounter {
        1 {
            catch {
                puts $sock $args
                flush $sock
            }
        }
        2 {
            if {[lindex $args 0] == "-nonewline"} {
                # for safety reasons we strip "-nonewline", since this might cause
                # the socket-communication resp. this application to hang
                catch {
                    puts $sock [lindex $args 1]
                    flush $sock
                }
            } else {
                #we have to write to a file or socket
                set code [catch {$interpret eval fileputs $args} info]
                if {$code} {
                    error $info $errorInfo
                } else {
                    # ok, do nothing
                }
            }
        }
        default {
            # three or more args, lets the original puts do the job
            set code [catch {$interpret eval fileputs $args} info]
            if {$code} {
                error $info $errorInfo
            } else {
                # ok, do nothing
            }
        }
    }
    catch {flush $sock}
}

proc getFirstChar {line} {

    set char [string index $line 0]
    for {set i 0} {$char == " " || $char == "\t"} {incr i} {
        if {$i > [string length $line]} {
            set char ""
            break
        }
        set char [string index $line $i]
    }
    return $char
}

# EvalRead  -- reads commands from the sock and executes them
proc EvalRead {sock interp} {
    fconfigure $sock -blocking 1
    global eval errorInfo errorCode
    global tcl_platform env

    if {$eval(exit_now)} {
        # do nothing
        set eval(busy) 0
        return ""
    }
    if {[eof $sock]} {
        exit
        # wait until open tasks have been finished
        while {$eval(busy)== 1} {
            after 1000 {
                global eval
                catch {
                    set dummy $eval(busy)
                }
            }
            vwait eval(busy)
        }
        exitApp $interp $sock
    } else {
        set code [catch {set result [gets $sock line]}]
        if {$code} {
            # wait until open tasks have been finished
            while {$eval(busy)== 1} {
                after 1000 {
                    global eval
                    catch {
                        set dummy $eval(busy)
                    }
                }
                vwait eval(busy)
            }
            catch {close $sock}
            exit
        } elseif {$result < 0} {
            catch {fconfigure $sock -blocking 0}
            return ""
        }
        if {$line == {}} {
            fconfigure $sock -blocking 0
            return ""
        } else {
            catch {
                #first time eval(concat will not exist)
                if $eval(concat) {
                    append eval(concatLine) $line
                    set line $eval(concatLine)
                    set eval(concatLine) ""
                }
            }
        }
        # in case of line concatenation get next line and save current one
        if {[string index $line end] == "\\"} {
            set eval(concat) 1
            set line [string trimright $line \\]
            set eval(concatLine) $line
            fconfigure $sock -blocking 0
            return ""
        } else {
            set eval(concat) 0
        }
        # skip comments
        if {[getFirstChar $line] == "#"} {
            fconfigure $sock -blocking 0
            return ""
        }

        # test for special commands
        switch -- $line {
            "resetServer" {
                #abort current command
                set eval(cmdbuf,$sock) {}
                catch {fconfigure $sock -blocking 0}
                return ""
            }

            "exitASEDServer" {
                # this should be clear
                exit
            }
            default {}
        }

        # now build command line
        eval [list append eval(cmdbuf,$sock) $line\n]
        if {[string length $eval(cmdbuf,$sock)] && [info complete $eval(cmdbuf,$sock)]} {
            # fill temporary commands buffer
            lappend eval(cmdsbuf,$sock) $eval(cmdbuf,$sock)
            # clear command line
            set eval(cmdbuf,$sock) {}
            # if there´s a pending command return
            if {$eval(busy)} {
                return ""
            }
            set eval(busy) 1
        } else {
            return ""
        }
        while {[string length $eval(cmdsbuf,$sock)]} {

            set eval(evalBuffer,$sock) $eval(cmdsbuf,$sock)
            # clear commands buffer
            set eval(cmdsbuf,$sock) {}
            # if we eval a command, which enters the event loop( i.e. tk_messageBox),
            # it might be possible, that additional commands arrive
            # in the meantime. These will be stored in the cmdsbuf
            # and after evaluation we check if there are new commands
            while {$eval(evalBuffer,$sock) != {} } {
                # we eval only one command with each call
                foreach command $eval(evalBuffer,$sock) {
                    if {$eval(exit_now)} {
                        break
                    }
                    set code [catch {
                        if {[string length $interp] == 0} {
                            uplevel #0 $command
                        } else {
                            interp eval $interp $command
                        }
                    } result]
                    if {$code != 0} {
                        if {[string first "origPuts ?-nonewline? ?channelId? string" $result] > -1} {
                            # drop internal stack-info
                            regsub -- {origPuts} $result "puts" res1
                            regsub -- {\n(.)*\n\"puts\ } $errorInfo "\n    while executing\n\"puts " temp
                            regsub -all -- {origPuts} $temp "puts" res2
                            set reply "Code:$code\nResult:$res1\nErrorinfo:$res2\nErrorcode:$errorCode\n"
                        } else {
                            set reply "Code:$code\nResult:$result\nErrorinfo:$errorInfo\nErrorcode:$errorCode\n"
                        }
                        puts -nonewline $sock $reply
                        flush $sock
                        catch {
                            tk_messageBox -icon error -title Error -message "$reply\n\n-->Abort Application now<--\n\nTry to double click on a line-number\nin the Console-Window if available" -parent .
                        }
                        exit
                    } else {
                        # catch {puts $sock $result}
                        # if {$result == 0} {
                            # catch {puts $sock $command}
                        # }
                    }
                }
                catch {
                    set eval(evalBuffer,$sock) {}
                    flush $sock
                    fconfigure $sock -blocking 0
                    update idletasks
                }
            }
            catch {
                flush $sock
                fconfigure $sock -blocking 0
            }
        }
        catch {
            flush $sock
            fconfigure $sock -blocking 0
        }
        set eval(busy) 0
    }
    return ""
}



if {[string compare [info script] $argv0] == 0} {

    switch -- $argc {
        0    {
            set port 9001
            set putsEcho 1
        }
        1    {
            set port [lindex $argv 0]
            set putsEcho 1
        }
        2    {
            set port [lindex $argv 0]
            set putsEcho [lindex $argv 1]
        }

        default {
            # port is portnumber as integer
            # putsEcho is boolean, if !=0 normal put commands are echoed back
            puts "usage: evalServer.tcl ?port? ?putsEcho?"
            exit
        }
    }
    puts "init server with port $port"
    initServer $port $putsEcho
    catch {wm iconify .}
    catch {wm protocol . WM_DELETE_WINDOW {exit}}
    update
    vwait forever
}


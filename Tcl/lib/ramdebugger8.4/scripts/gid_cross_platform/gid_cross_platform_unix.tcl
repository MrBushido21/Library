#Linux / Mac OS X
#generic implementation using exec of unix system commands        

namespace eval gid_cross_platform {
}

proc gid_cross_platform::end_process { pid } {
    return [exec kill $pid]
}

proc gid_cross_platform::process_exists { pid } {
    #return [expr ![catch {exec ps $pid} ret]]
    # file exists /proc/$pid does not work
    # beacause when the process ends it's still alive
    # until the parent retrieves it's return code status
    # i.e. it remains <defunct> or zombie
    # that's why we need to use 'ps'
    #return [file exists /proc/$pid]
    set exists 1
    set err [catch {exec ps $pid} err_txt]    
    if { $err } {
        set exists 0
        if { [string first $pid $err_txt] != -1} {
            set exists 1
        }
    }
    return $exists
}

proc gid_cross_platform::get_process_parent { pid } {
    set ppid ""
    set err [catch {exec ps -o ppid= $pid} err_txt]
    if { !$err} {
        set ppid [string trim $err_txt]
    }
    return $ppid
}

proc gid_cross_platform::get_process_childs { pid firstonly } {
    set ppids [list]
    #is this returning all childs or only the first?
    set err [catch {exec ps -o pid= --ppid $pid} err_txt]
    if { !$err} {
        set ppids [string trim $err_txt]
        if { $firstonly } {            
            set ppids [lindex $pids 0]
        }
    }
    return $ppids
}

proc gid_cross_platform::get_process_name { pid } {
    if { [catch {exec ps -p $pid --no-headers -o cmd} ret] } {
        set name ""
    } else {
        set name [file tail $ret]
    }
    return $name
}

proc gid_cross_platform::get_process_ids { } {
    return [join [exec ps -A --no-headers -o pid]]
}

proc gid_cross_platform::get_process_ids_from_name { name } {
    return [exec pidof $name]
}

proc gid_cross_platform::end_all_process_by_name { name } {
    return [exec killall $name]
}

#bytes
proc gid_cross_platform::get_process_info_memory { pid } {
    #rss  resident set size, the non-swapped physical memory that a task has used (in kiloBytes).                  
    if { [catch {exec ps -p $pid --no-headers -o rss} ret] } {
        set workingset 0
    } else {
        set ret [string trim $ret]
        set workingset [expr {$ret*1024}]
    }
    return $workingset
}

#bytes
proc gid_cross_platform::get_process_info_memory_peak { pid } {
    #vsz  virtual memory size of the process in KiB (1024-byte units). Device mappings are currently excluded
    if { [catch {exec ps -p $pid --no-headers -o vsz} ret] } {
        set workingset 0
    } else {
        set ret [string trim $ret]
        set workingset [expr {$ret*1024}]
    }
    return $workingset        
}

#seconds
proc gid_cross_platform::get_process_info_elapsedtime { pid } {
    #etime  elapsed time since the process was started, in the form [[dd-]hh:]mm:ss.
    if { [catch {exec ps -p $pid --no-headers -o etime} ret] } {
        set elapsedtime 0
    } else {                    
        set ret [string trim $ret]               
        lassign [lreverse [split $ret :-]] ss mm hh dd
        #remove left zeros to avoid consider as an octal number!!
        foreach variable_name {ss mm hh dd} {
            set $variable_name [string trimleft [string trim [set $variable_name]] 0]        
            if { [set $variable_name] == "" } {
                set $variable_name 0        
            }
        }
        set elapsedtime [expr {(($dd*24+$hh)*60+$mm)*60+$ss}]
    }
    return $elapsedtime
}

#seconds
proc gid_cross_platform::get_process_info_cputime { pid } {
    #etime  elapsed time since the process was started, in the form [[dd-]hh:]mm:ss.
    if { [catch {exec ps -p $pid --no-headers -o cputime} ret] } {
        set elapsedtime 0
    } else {                       
        set ret [string trim $ret]           
        lassign [lreverse [split $ret :-]] ss mm hh dd
        #remove left zeros to avoid consider as an octal number!!
        foreach variable_name {ss mm hh dd} {
            set $variable_name [string trimleft [string trim [set $variable_name]] 0]        
            if { [set $variable_name] == "" } {
                set $variable_name 0        
            }        
        }
        set elapsedtime [expr {(($dd*24+$hh)*60+$mm)*60+$ss}]
    }
    return $elapsedtime
}

proc gid_cross_platform::get_run_as_administrator_cmd { } {
    set cmd ""
    set lst_sudoers [list pkexec gksudo kdesudo gksu kdesu ]
    foreach try_cmd $lst_sudoers {
        # set err [catch {exec which $try_cmd} ret]
        # if { !$err} {
        #     # adding -- to finish passing arguments to XXsudo
        #     # set cmd [list $ret --]
	#     set cmd $ret
        #     break
        # }
        set cmd [ auto_execok $try_cmd]
        if { $cmd != ""} {
            break
        }
    }
    if { $cmd == "" } {
        # brute force....
        # set err_xterm [catch {exec which xterm} full_xterm]
        # set err_sudo [catch { exec which sudo } full_sudo]
        # if { !$err_xterm && !$err_sudo} {
        #     set cmd [list $full_xterm -e $full_sudo]
        # }
        set full_xterm [ auto_execok xterm]
        set full_sudo [ auto_execok sudo]
        if { ( $full_xterm != "") && ( $full_sudo != "")} {
            set cmd [list $full_xterm -e $full_sudo]
        }
    }
    return $cmd        
}

proc gid_cross_platform::get_run_as_administrator_cmdline { args} {
    set cmd ""
    if { $::tcl_platform(os) == "Darwin" } {
        # https://stackoverflow.com/questions/1517183/is-there-any-graphical-sudo-for-mac-os-x
        # osascript -e "do shell script \"$*\" with administrator privileges"
        set cmd [ list osascript -e \
                      "do shell script \"$args\" with administrator privileges" ]
    } else {
        # linux
        set run_as_administrator_cmd [gid_cross_platform::get_run_as_administrator_cmd]
        set cmd [ list {*}$run_as_administrator_cmd {*}$args]
    }
    return $cmd
}

proc gid_cross_platform::run_as_administrator { args } {
    set cmd [ gid_cross_platform::get_run_as_administrator_cmdline $args ]
    set err [catch {exec {*}$cmd} ret]
    if { $err} {
        error "Executing $run_as_administrator_cmd $args failed: $ret"
    }
    return $err
}

proc gid_cross_platform::get_desktop_workarea { } {
    if { [info commands winfo]!= "" && [winfo exists .] } {
        set w [winfo screenwidth .] 
        set h [winfo screenheight .]
    } else {
        set w 0
        set h 0
    }
    return [list 0 0 $w $h]
}

# Copy the contents of the photo image to clipboard
proc gid_cross_platform::image_to_clipboard { image } {
    #how to handle the clipboard image in Linux / MacOSX ?
    #there are lots of clipboard managers but nothing standard !
    return ""
}

# Copy the contents of the clipboard into a photo image. Return the photo identifier.
proc gid_cross_platform::clipboard_to_image {} {
    #how to handle the clipboard image in Linux / MacOSX ?
    #there are lots of clipboard managers but nothing standard !
    return ""
}

#to open the file explorer in a specified folder
proc gid_cross_platform::open_by_extension { url } {
    # open is the OS X equivalent to xdg-open on Linux, start is used on Windows
    if { $::tcl_platform(os) != "Darwin" } {
        set browser xdg-open
    } else {
        set browser open
    }
    set command [auto_execok $browser]    
    if {[string length $command] == 0} {
        return -code error "couldn't find browser"
    }
    # make gid dynamic libraries do not affect external programs
    if {[catch {exec sh -c "export LD_LIBRARY_PATH=; $command $url" &} error]} {
        return -code error "couldn't execute '$command': $error"
    }
}

# execute an external program with args
proc gid_cross_platform::execute_program_in_path { program args } {
    # GiD mangles with encodings, so the environment variable PATH in windows is invalid:
    # set err [ catch { set full_program [ exec which $program]} error]    
    set full_program [ auto_execok $program]
    if { $full_program == ""} {
        return -code error "couldn't execute '$program': $error"
    }
    # get first option
    set lst_programs [split $full_program \n]
    set full_program [lindex $lst_programs 0]
    set err 0
    set error_txt ""
    set err [catch {exec "$full_program" {*}$args &} error_txt]    
    if { $err} {
        return -code error "couldn't execute '$program': $error"
    }
}

#return one of:  "Windows 32" "Windows 64" "Linux 32" "Linux 64" "MacOSX 32" "MacOSX 64" "$::tcl_platform(os) ?"
proc gid_cross_platform::get_current_platform {} {
    if { $::tcl_platform(os) == "Linux" } {
        if { $::tcl_platform(machine) == "x86_64" } {
            set myplatform "Linux 64"
        } else {
            set myplatform "Linux 32"
        }
    } elseif { $::tcl_platform(os) == "Darwin" } {
        if { $::tcl_platform(machine) == "Power Macintosh" || $::tcl_platform(machine) == "i386" } {
            set myplatform "MacOSX 32"
        } else {
            set myplatform "MacOSX 64"
        }
    } else {
        #AIX , HP-UX, IRIX, SunOS, DragonFly, FreeBSD, NetBSD, OpenBSD, OSF1
        set myplatform "$::tcl_platform(os) ?"
    }
    return $myplatform
}

proc gid_cross_platform::get_path_separator { } {
    return ":"
}


namespace eval gid_cross_platform {
}

package require twapi              

#doesn't kill child process !!
proc gid_cross_platform::end_process { pid } {                
    return [twapi::end_process $pid -force]
}

proc gid_cross_platform::process_exists { pid } {
    return [twapi::process_exists $pid]
}

proc gid_cross_platform::get_process_parent { pid } {
    return [twapi::get_process_parent $pid]
}

#very expensive implementation!!
proc gid_cross_platform::get_process_childs { pid firstonly } {
    set child_pids [list]        
    foreach candidate_pid [gid_cross_platform::get_process_ids] {
        if { [gid_cross_platform::get_process_parent $candidate_pid] == $pid } {
            lappend child_pids $candidate_pid
            if { $firstonly } {
                break
            }
            lappend child_pids {*}[gid_cross_platform::get_process_childs $candidate_pid $firstonly]
        }
    }
    return $child_pids
}

proc gid_cross_platform::get_process_name { pid } {
    return [twapi::get_process_name $pid]
}

proc gid_cross_platform::get_process_ids { } {
    return [twapi::get_process_ids]
}

proc gid_cross_platform::get_process_ids_from_name { name } {
    return [twapi::get_process_ids -name $name]    
}

proc gid_cross_platform::end_all_process_by_name { name } {
    foreach pid [gid_cross_platform::get_process_ids_from_name $name] {
        gid_cross_platform::end_process $pid
    }
}

#bytes
proc gid_cross_platform::get_process_info_memory { pid } {
    return [lindex [twapi::get_process_info $pid -workingset] 1]
}
#bytes
proc gid_cross_platform::get_process_info_memory_peak { pid } {
    return [lindex [twapi::get_process_info $pid -workingsetpeak] 1]
}

#seconds
proc gid_cross_platform::get_process_info_elapsedtime { pid } {
    return [lindex [twapi::get_process_info $pid -elapsedtime] 1]
}

#seconds
proc gid_cross_platform::get_process_info_cputime { pid } {
    #-usertime The amount of user context CPU time used by the thread in 100ns units.
    #-privilegedtime The amount of privileged context CPU time used by the thread in 100ns units.        
    set cputime [expr {[lindex [twapi::get_process_info $pid -usertime] 1]*1e-7}] ;#100ns->seconds
    return $cputime
}

proc gid_cross_platform::get_run_as_administrator_cmd { } {
    set cmd ""
    if { [info commands GiD_RunAsAdministrator] != ""} {
        set cmd GiD_RunAsAdministrator
    }
    return $cmd
}

#this is untested, but if path and params are ok must work
proc gid_cross_platform::run_as_administrator_twapi { args } {
    set path [file nativename [lindex $args 0]]
    set params [lrange $args 1 end]
    twapi::shell_execute -path $path -params $params -verb runas
}

proc gid_cross_platform::get_run_as_administrator_cmdline { args} {
    set cmd ""
    set run_as_administrator_cmd [gid_cross_platform::get_run_as_administrator_cmd]
    set cmd [ list {*}$run_as_administrator_cmd {*}$args]
    return $cmd
}

proc gid_cross_platform::run_as_administrator { args } {
    return [ eval [ gid_cross_platform::get_run_as_administrator_cmdline {*}$args ] ]
}    

proc gid_cross_platform::get_desktop_workarea { } {
    return [twapi::get_desktop_workarea]
}    

# Copy the contents of the photo image to clipboard
proc gid_cross_platform::image_to_clipboard { image } {
    package require img::bmp      
    # First 14 bytes are bitmapfileheader - get rid of this
    #set data [binary decode base64 [$tk_image data -format png]]
    set data [string range [binary decode base64 [$image data -format bmp]] 14 end]
    twapi::open_clipboard
    twapi::empty_clipboard
    #twapi::write_clipboard 49406 $data ;#png?
    twapi::write_clipboard 8 $data
    twapi::close_clipboard
}


# Copy the contents of the clipboard into a photo image. Return the photo identifier.
proc gid_cross_platform::clipboard_to_image {} {
    package require img::bmp        
    twapi::open_clipboard    
    # Assume clipboard content is in format 8 (CF_DIB)
    set retVal [catch {twapi::read_clipboard 8} clipData]
    if { $retVal != 0 } {
        error "Invalid or no content in clipboard"
    }    
    # First parse the bitmap data to collect header information
    binary scan $clipData "iiissiiiiii" \
        size width height planes bitcount compression sizeimage \
        xpelspermeter ypelspermeter clrused clrimportant    
    # We only handle BITMAPINFOHEADER right now (size must be 40)
    if {$size != 40} {
        error "Unsupported bitmap format. Header size=$size"
    }    
    # We need to figure out the offset to the actual bitmap data
    # from the start of the file header. For this we need to know the
    # size of the color table which directly follows the BITMAPINFOHEADER
    if {$bitcount == 0} {
        error "Unsupported format: implicit JPEG or PNG"
    } elseif {$bitcount == 1} {
        set color_table_size 2
    } elseif {$bitcount == 4} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 16
    } elseif {$bitcount == 8} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 256
    } elseif {$bitcount == 16 || $bitcount == 32} {
        if {$compression == 0} {
            # BI_RGB
            set color_table_size $clrused
        } elseif {$compression == 3} {
            # BI_BITFIELDS
            set color_table_size 3
        } else {
            error "Unsupported compression type '$compression' for bitcount value $bitcount"
        }
    } elseif {$bitcount == 24} {
        set color_table_size $clrused
    } else {
        error "Unsupported value '$bitcount' in bitmap bitcount field"
    }    
    set image [image create photo]
    set filehdr_size 14 ;# sizeof(BITMAPFILEHEADER)
    set bitmap_file_offset [expr {$filehdr_size+$size+($color_table_size*4)}]
    set filehdr [binary format "a2 i x2 x2 i" \
            "BM" [expr {$filehdr_size + [string length $clipData]}] \
            $bitmap_file_offset]
    append filehdr $clipData
    $image put $filehdr -format bmp    
    twapi::close_clipboard
    return $image
}  

#to know if an exe or dll is x32 or x64
proc gid_cross_platform::get_image_file_machine { filename } {
    set target ""
    if {![file exists $filename] } {
        error "File '$filename' does not exists"
    }
    set file_size [file size $filename]    
    set fp [open $filename rb]
    set max_num_chars 1024
    if { $file_size < 1024 } {
        set data [read $fp]
    } else {
        set data [read $fp $max_num_chars]
    }
    close $fp
    set two_bytes [string range $data 60 61] ;#60=0x3C
    binary scan $two_bytes su offset_PE_signature ;#offset_PE_signature for example=288 in my example
    set PE_signature [string range $data $offset_PE_signature $offset_PE_signature+3] ;#"PE\0\0"
    binary scan $PE_signature iu integer_32_bit_signature
    if { $integer_32_bit_signature == 17744 } {
        #Windows PE format image file
        #see docs.microsoft.com/en-us/windows/desktop/Debug/pe-format
        set offset_COFF [expr $offset_PE_signature+4]
        set COFF_machine [string range $data $offset_COFF $offset_COFF+1]
        binary scan $COFF_machine su integer_16_bit_machine
        if { $integer_16_bit_machine == 34404 } {
            #IMAGE_FILE_MACHINE_AMD64 0x8664 (34404) x64
            set target win-x64
        } elseif { $integer_16_bit_machine == 332 } {
            #IMAGE_FILE_MACHINE_I386 0x14c (332) Intel 386 or later processors and compatible processors
            set target win-x32
        } else {
            set target win-?
        }
    } else {
        #it is not a Windows exe or dll
        set target ?
    }
    return $target
}

#to open the file explorer in a specified folder
proc gid_cross_platform::open_by_extension { url } {
    # open is the OS X equivalent to xdg-open on Linux, start is used on Windows
    set browser start
    set command [list {*}[auto_execok start] {}]    
    if {[string length $command] == 0} {
        return -code error "couldn't find browser"
    }    
    set url [string map {& ^&}  $url] ;#start is special with ampersand, must replace & by ^& to escape it
    if {[catch {exec {*}$command $url &} error]} {
        return -code error "couldn't execute '$command': $error"
    }
}

# execute an external program with args
proc gid_cross_platform::execute_program_in_path { program args } {
    # GiD mangles with encodings, so the environment variable PATH in windows is invalid:
    # set err [ catch { set full_program [ exec where $program]} error]    
    set full_program [ auto_execok $program]
    if { $full_program == ""} {
        return -code error "couldn't execute '$program': $error"
    }
    # get first option
    set lst_programs [split $full_program \n]
    set full_program [lindex $lst_programs 0]
    set err 0
    set error_txt ""
    set err [catch {exec cmd /c "$full_program" {*}$args &} error_txt]    
    if { $err} {
        return -code error "couldn't execute '$program': $error"
    }
}

#return one of:  "Windows 32" "Windows 64" "Linux 32" "Linux 64" "MacOSX 32" "MacOSX 64" "$::tcl_platform(os) ?"
proc gid_cross_platform::get_current_platform {} {    
    if { $::tcl_platform(machine) == "amd64" } {
        set myplatform "Windows 64"
    } else {
        set myplatform "Windows 32"
    }    
    return $myplatform
}

proc gid_cross_platform::get_path_separator { } {
    return ";"
}

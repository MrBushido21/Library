#common procedures, with body valid for all platforms

namespace eval gid_cross_platform {
}

#e.g. gid_cross_platform::track_process to follow an asyncronous process and raise callback events
# status will be= ok|user_stop|timeout
# proc my_finish_proc { pid status args } { ... }
# returned user_stop must be 0 or 1 (1 to kill the process)
# proc my_progress_proc { args }  { ... return $user_stop }
# set timeout 20000 ;#seconds, 0 to no limit
# set maxmemory 0 ;#bytes 0 to no limit
# set pid [eval exec $cmd &]
# gid_cross_platform::track_process $pid 1000 [clock seconds] $timeout $maxmemory [list my_finish_proc $args] [list my_progress_proc a b]
proc gid_cross_platform::track_process { pid ms t0 timeout maxmemory finish_procedure progress_procedure } {
    if { [gid_cross_platform::process_exists $pid] } {
        set memory_used [gid_cross_platform::get_process_info_memory $pid]
        if { ![string is integer $memory_used] } {
            #probably the process has finished
            set memory_used 0
        }
        if { $timeout > 0 && [clock seconds]-$t0 > $timeout } { 
            if { [catch {gid_cross_platform::end_process_and_childs $pid} err] } {
                W "error '$err'"        
            }
            [lindex $finish_procedure 0] $pid timeout {*}[lrange $finish_procedure 1 end]
        } elseif { $maxmemory > 0 && $memory_used > $maxmemory } { 
            if { [catch {gid_cross_platform::end_process_and_childs $pid} err] } {
                W "error '$err'"        
            }
            [lindex $finish_procedure 0] $pid maxmemory {*}[lrange $finish_procedure 1 end]
        } else {
            if { $progress_procedure != "" } {
                set user_stop [eval $progress_procedure]                
            } else {
                set user_stop 0
            }
            if { $user_stop } {
                if { [catch {gid_cross_platform::end_process_and_childs $pid} err] } {
                    W "error '$err'"        
                }
                [lindex $finish_procedure 0] $pid user_stop {*}[lrange $finish_procedure 1 end]
            } else {
                after $ms [list gid_cross_platform::track_process $pid $ms $t0 $timeout $maxmemory $finish_procedure $progress_procedure]
                update ;#to allow after to be processed, else the finish_procedure could be invoked later than the true end
            }
        }
    } else {
        [lindex $finish_procedure 0] $pid ok {*}[lrange $finish_procedure 1 end]
    }
}

proc gid_cross_platform::cancel_track_process { pid } {
    foreach id [after info] {
        lassign [after info $id] script kind_event
        if { $kind_event == "timer" } {
            if { [lindex $script 0] == "gid_cross_platform::track_process" && [lindex $script 1] == $pid } {
                after cancel $id
                break
            }
        }
    }
}

#kill also its recursive child process
proc gid_cross_platform::end_process_and_childs { pid } {
    set fail 0  
    set child_pids [gid_cross_platform::get_process_childs $pid 0]
    foreach child_pid $child_pids {
        if { [gid_cross_platform::process_exists $child_pid] } {
            gid_cross_platform::end_process $child_pid                            
        }
    }
    gid_cross_platform::end_process $pid    
    if { [gid_cross_platform::process_exists $pid] } {
        set fail 1
    } 
    return $fail
}


#create a raster image from a widget c with Img (image create photo -format window -data $c)
#limitation: to capture the image the whole window must be visible in screen
proc gid_cross_platform::capture_window { win } {
    package require img::window
    # package require Img
    regexp {([0-9]*)x([0-9]*)\+([0-9]*)\+([0-9]*)} [winfo geometry $win] - w h x y
    # Make the base image based on the window
    set image [image create photo -format window -data $win]
    foreach child [winfo children $win] {
        gid_cross_platform::_capture_sub_window $child $image 0 0
    }
    #save image to disk
    #$image write $filename -format GIF
    return $image
}

#auxiliary procedure, used by gid_cross_platform::capture_window
proc gid_cross_platform::_capture_sub_window { win image px py } {
    if {![winfo ismapped $win]} {
        return
    }
    regexp {([0-9]*)x([0-9]*)\+([0-9]*)\+([0-9]*)} [winfo geometry $win] - w h x y
    incr px $x
    incr py $y
    # Make an image from this widget
    set tempImage [image create photo -format window -data $win]
    # Copy this image into place on the main image
    $image copy $tempImage -to $px $py
    image delete $tempImage
    foreach child [winfo children $win] {
        gid_cross_platform::_capture_sub_window $child $image $px $py
    }
}

proc gid_cross_platform::path_append { item {set_first 0}} {
    if { [info exists ::env(PATH)] } {
        set separator [gid_cross_platform::get_path_separator]
        if { [lsearch [split $::env(PATH) $separator] $item] == -1 } {
            if { $set_first } {
                set ::env(PATH) $item$separator$::env(PATH)
            } else {
                append ::env(PATH) $separator$item
            }
        }
    } else {
        set ::env(PATH) $item
    }
}

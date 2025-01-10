
proc LoadLibrary_gid_cross_platform { dir basename } {
    if { $::tcl_platform(platform) == "windows" } {
        source [file join $dir gid_cross_platform_windows.tcl]        
    } else {
        #Linux / Mac OS X
        source [file join $dir gid_cross_platform_unix.tcl]
    }
    source [file join $dir gid_cross_platform_common.tcl]    
    package provide gid_cross_platform 1.7
}

package ifneeded gid_cross_platform 1.7 [list LoadLibrary_gid_cross_platform $dir gid_cross_platform]

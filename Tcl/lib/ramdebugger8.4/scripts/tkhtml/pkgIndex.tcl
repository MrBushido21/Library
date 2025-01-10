proc LoadLibrary_Tkhtml { dir basename } {     
    package require Tk 8.4
    if { $::tcl_platform(pointerSize) == 8} {
	set bits 64
    } else {
	set bits 32
    }
    set pref ""
    set suf ""
    if { $::tcl_platform(platform) == "unix"} {
	set pref "lib"
	set suf "3.0"
    }
    set library ${pref}${basename}${suf}_${bits}[info sharedlibextension]
    load [file join $dir $library] $basename  
    #load {C:\gid project\gidvs\x32\Debug\tkhtml3.dll} Tkhtml
    package provide Tkhtml 3.0 
}

package ifneeded Tkhtml 3.0 [list LoadLibrary_Tkhtml $dir Tkhtml]

# http://wiki.tcl.tk/8186
#
#  Clean up temporary files left by Tcl when loading shared libraries  from
#  within a virtual file system (VFS).
#
#  Only needed on certain platforms (the Tclkit version number
#  is in $vfs::tclkit_version)

proc Cleanup_TEMP_for_win {} {

	if { $::tcl_platform(platform) != "windows"} {
		return
	}

	set dir $::env(TEMP)
	set pattern "TCL????????"

	# note we silently ignore any errors
	catch {
		if {[file isdirectory $dir]} {
			set now [clock seconds]
			# number of seconds old that a temporary file must be before it will be
			# deleted - this is done to avoid the (extremely unlikely) race
			# condition wherein two copies of the application are run
			# currently, and this cleanup runs between the VFS creating the
			# temporary file and when it loads it
			set age 10
			cd $dir
			foreach file [glob $pattern] {
				# only those files owned by the current user
				if { [file owned $file] != 0 } {
					if {[expr {$now - [file mtime $file]}] > $age} {
						# delete directory along with everything in it, recursively:
						file delete -force -- $file
					}
				}
			}
		}
	} msg
	# puts stderr "msg = $msg"  ;# uncomment to debug
}



if {0} {
	#show the console window
	package require Tk
	wm withdraw .
	console show
	console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}

	Cleanup_TEMP_for_win
}

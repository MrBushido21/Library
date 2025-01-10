################################################################################
# fifDialog.tcl --
#
# a graphical grep in tcl
#
# (C) 2000 Andreas Sievers
################################################################################

namespace eval fif {
	variable fif
	variable fifDialog
	variable searchResults
	variable resultframe
}

proc fif::grep {dir subfolder} {
	variable fif

	if {[file tail $dir] ne ""} {
		append dir "/"
	}

	# set oldDir [pwd]
	# cd $dir
	#
	# # set pattern [file join $dir $fif(findFilter)]
	# set pattern [list $fif(findFilter)]
	set result {}
	set findStrLen [string length $fif(findStr)]

	set files [glob -nocomplain -directory $dir -- $fif(findFilter)]
	if {$subfolder} {
		set dirs [glob -nocomplain -- [file join $dir "*"]]
		foreach directory $dirs {
			if {$directory eq $dir} {
				continue
			}
			if  {[file type $directory] eq "directory"} {
				lappend files $directory
			}
		}
	}
	if {$fif(rexpOn)} {
		catch {destroy .rexpWin}
		toplevel .rexpWin
		text .rexpWin.text
		wm withdraw .rexpWin
	}

	foreach file $files {
		switch -- [file type $file] {
			"file" {
				#process file
				set fileID [open $file "r"]

				if {$fif(rexpOn)} {
					set data [read $fileID]
					close $fileID
					.rexpWin.text delete 1.0 end
					.rexpWin.text insert end $data
					eval [list set rexp $fif(findStr)]
					if {$fif(caseOff)} {
						set index [.rexpWin.text search -nocase -regexp -- $rexp 1.0 end]
					} else {
						set index [.rexpWin.text search -regexp -- $rexp 1.0 end]
					}
					while {$index ne ""} {
						set lineStr [.rexpWin.text get $index "$index lineend"]
						lappend result [list $file $index $lineStr]
						if {$fif(caseOff)} {
							set index [.rexpWin.text search -nocase -regexp -- $rexp "$index+1c" end]
						} else {
							set index [.rexpWin.text search -regexp -- $rexp "$index+1c" end]
						}
						if {[info exists fif(resultWin)]} {
							set lineText "$file --> $lineStr"
							$fif(resultWin) insert end $lineText
							$fif(resultWin) see end
						}
					}
				} else {
					set lineNum 1
					while {[gets $fileID line] != -1} {
						set startIndex 0
						set lineStr [string trim $line]

						if {$fif(caseOff)} {
							set fif(findStr) [string tolower $fif(findStr)]
							set line  [string tolower $line]
						}
						while {[string first $fif(findStr) $line] != -1} {
							set index [string first $fif(findStr) $line]

							# set string after found string
							set line [string range $line [expr {$index + $findStrLen}] end]

							#append to result
							lappend result [list $file "$lineNum.[expr {$startIndex + $index}]" $lineStr]

							if {[info exists fif(resultWin)]} {
								set lineText "$file --> $lineStr"
								$fif(resultWin) insert end $lineText
								$fif(resultWin) see end
							}
							# set string after found string
							set startIndex [expr {$startIndex + $index + $findStrLen}]
							set line [string range $line [expr {$index + $findStrLen}] end]
						}
						incr lineNum
					}
					close $fileID
				}
			}

			"directory" {
				if {$subfolder} {
					#process directory
					set fileResult [grep $file 1]
					#append into the list
					foreach i $fileResult {
						lappend result $i
					}
				}
			}

			"link" {
				# nothing to do. For now, we skip links
			}
			default {}
		}
		update
		if {$fif(command) eq "stop"} {
			break
		}
	}
	catch {destroy .rexpWin}
	return $result
}

proc fif::openFifDialog {{wDir {}} {fStr ""} {win {}}} {
    global images
	variable fif
	variable fifDialog
	variable searchResults
	variable resultframe

	if {![winfo exists $win.fifdlg]} {
		catch {destroy $fif(mainWin)}
		eval [list initFifDialog $wDir $fStr]
		set fifDialog [toplevel $win.fifdlg]
	        wm title $fifDialog [tr "Search in files"]
	        wm transient $fifDialog [winfo toplevel [winfo parent $fifDialog]]
		wm withdraw $fifDialog
		# init main frames
		set dialogFrame [ttk::frame $fifDialog.dialogFrame]
		pack $dialogFrame -fill both
		set resultFrame [ttk::frame $fifDialog.resultFrame]
		pack $resultFrame -fill both -expand yes
		# init subframes
		set searchFrame [ttk::frame $dialogFrame.searchFrame]
		pack $searchFrame -fill both -expand yes
		set optionFrame [ttk::frame $dialogFrame.options]
		pack $optionFrame -fill both

		set labelFrame [ttk::frame $searchFrame.labels]
		pack $labelFrame -side left -fill both -expand yes
		set entryFrame [ttk::frame $searchFrame.entry]
		pack $entryFrame -side left -fill both -expand yes
		set buttonFrame [ttk::frame $searchFrame.buttons]
		pack $buttonFrame -side left -fill both -expand yes

		# init labels
		pack [ttk::label $labelFrame.text -text [tr "Searchstring"] -width 13 -anchor w] -fill y -expand yes
		pack [ttk::label $labelFrame.dir -text [tr "Directory"] -width 13 -anchor w] -fill y -expand yes
		pack [ttk::label $labelFrame.filter -text [tr "File filter"] -width 13 -anchor w] -fill y -expand yes
		# init entries
                set fif(findStrEntry) [ttk::entry $entryFrame.findStr -textvar ::fif::fif(findStr)]
		bind $fif(findStrEntry) <Return> {$::fif::fif(searchButton) invoke}
		pack $fif(findStrEntry) -fill both -expand yes -padx 5 -pady 5
		set dirFrame [ttk::frame $entryFrame.dir]
		pack $dirFrame -fill both -expand yes
                set dirEntry [ttk::entry $dirFrame.entry -textvar ::fif::fif(findDir)]
		pack $dirEntry -side left -fill both -expand yes -padx 5 -pady 5
		# tk_chooseDirectory is not on all platforms and versions available
		set dirButton [ttk::button $dirFrame.button \
				-image $images(folder) \
				-command {if {[catch {set ::fif::fif(findDir) [tk_chooseDirectory \
							-mustexist 1 \
							-parent $::fif::fifDialog \
							-initialdir $::fif::fif(workingDir)]
						}]} {
						tk_messageBox -message [tr "Not supported on this platform"] -title [tr "Info"] -parent $::fif::fifDialog
					}
					focus -force $::fif::fifDialog
				}]
		pack $dirButton -side left -padx 5 -pady 5
		set filterEntry [ttk::entry $entryFrame.filter -textvar ::fif::fif(findFilter)]
		pack $filterEntry -fill both -expand yes -padx 5 -pady 5
		# init buttons
		set fif(searchButton) [ttk::button $buttonFrame.search -text [tr "Search"] -command "fif::startSearch"]
		pack $fif(searchButton) -fill both -expand yes -padx 5 -pady 5
		set fif(stopButton) [ttk::button $buttonFrame.stop -text [tr "Stop"] -command "fif::stopSearch"]
		pack $fif(stopButton) -fill both -expand yes -padx 5 -pady 5
		set fif(cancelButton) [ttk::button $buttonFrame.cancel -text [tr "Cancel"] -command "fif::cancelSearch"]
		pack $fif(cancelButton) -fill both -expand yes -padx 5 -pady 5
		# init checkbuttons
		set checkButtonFrame [TitleFrame $optionFrame.options -text [tr "Options"]  -bd 2 -relief groove]
		pack $checkButtonFrame -fill both -expand yes -ipadx 2 -ipady 2 -padx 10 -pady 10
		set subframe  [$checkButtonFrame getframe]
		set caseButton [ttk::checkbutton $subframe.case -text [tr "ignore case"] -variable ::fif::fif(caseOff)]
		pack $caseButton -side left -fill x -expand yes -padx 2 -pady 2
		set rexpButton [ttk::checkbutton $subframe.rexp -text [tr "regexp style"] -variable ::fif::fif(rexpOn)]
		pack $rexpButton -side left -fill x -expand yes -padx 2 -pady 2
		set subfolderButton [ttk::checkbutton $subframe.subfolder -text [tr "include subfolder"] -variable ::fif::fif(subfolderOn)]
		pack $subfolderButton -side left -fill x -expand yes -padx 2 -pady 2
		# init result window
		set resultframe [TitleFrame $resultFrame.labelframe -text [tr "Results"] -bd 2 -relief groove]
		pack $resultframe -fill both -expand yes -padx 10 -pady 10
		set subframe  [$resultframe getframe]
		set sw [ScrolledWindow::create $subframe.sw -auto both]
		pack $sw -fill both -expand yes
		set resultWindow [listbox $sw.listbox -width 60 -bg white]
		$resultWindow configure -exportselection false
		### pack $resultWindow -fill both -expand yes
		ScrolledWindow::setwidget $sw $resultWindow
		set fif(resultWin) $resultWindow

		bind $resultWindow <Button-1> {
			$::fif::fif(resultWin) selection clear 0 end
			$::fif::fif(resultWin) selection set @%x,%y
			set index [$::fif::fif(resultWin) curselection]
			if {$index ne {}} {
				set result [$::fif::fif(resultWin) get $index]
				set result $::fif::searchResults($result)
				# openFile filename nocomplain=1 if file already opened
				Editor::openFile [lindex $result 0] 1
				set index [lindex $result 1]
				if {[info exists editorWindows::TxtWidget]} {
					$editorWindows::TxtWidget mark set insert $index
					$editorWindows::TxtWidget see insert
					editorWindows::flashLine
					Editor::selectObject 0
				}
			}
		}

		bind $fifDialog <Escape> {$::fif::fif(cancelButton) invoke}

		set fif(resultWin) $resultWindow
		wm deiconify $fifDialog
		set fif(mainWin) $fifDialog
		focus -force $fif(findStrEntry)
	} else {
		focus -force $fif(findStrEntry)
	}
}



proc fif::startSearch {} {
	variable fif
	variable searchResults
	variable resultframe

	if {$fif(command) eq "search"} {
		return
	}
	set fif(command) "search"
	# unset indexlist
	foreach entry [array names searchResults] {
		unset searchResults($entry)
	}
	#clear window
	$fif(resultWin) delete 0 end

	$resultframe configure -text [tr "Searching ..."]

	set cursor [$fif(mainWin) cget -cursor]
	$fif(mainWin) configure -cursor watch
	set resultList [fif::grep $fif(findDir) $fif(subfolderOn)]
	$fif(mainWin) configure -cursor $cursor

	if {$resultList eq {}} {
		tk_messageBox -message [tr "Nothing found"] -title [tr "Search Result"] -parent $fif(mainWin)
		set fif(command) ""
		return
	}

	#clear window
	$fif(resultWin) delete 0 end

	# insert results
	foreach entry $resultList {
		set line "[lindex $entry 0] --> \"[lindex $entry 2]\""
		set searchResults($line) $entry
		$fif(resultWin) insert end $line
	}
	$fif(resultWin) see end
	$resultframe configure -text [tr "Done!   Click Entry to edit!"]
	set fif(command) ""
}

proc fif::stopSearch {} {
	variable fif

	set fif(command) "stop"
}

proc fif::cancelSearch {} {
	variable fif
	destroy $fif(mainWin)
}

proc fif::initFifDialog {{wDir {}} {fStr ""}} {
	variable fif

	set fif(findFilter) "*.tcl"
	set fif(caseOff) 1
	set fif(rexpOn) 0
	set fif(subfolderOn) 0
	set fif(command) ""
	if {$wDir ne {}} {
		set fif(workingDir) $wDir
	} else {
		set fif(workingDir) [pwd]
	}
	set fif(findDir) $fif(workingDir)
	eval [list set fif(findStr) $fStr]
}

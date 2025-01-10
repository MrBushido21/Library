# -------------------------------------------------------------------------
# helpviewer_search.tcl
# -------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] googlemail.com
#     www.johann-oberdorfer.eu
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# 
# Credits:
#  This software related on the the helpviewer application originally
#  created by Ramon Ribó (RAMSAN) ramsan@cimne.upc.es.
#  (http://gid.cimne.upc.es/ramsan) for his version of the 
#  Thank you.
#
# -------------------------------------------------------------------------


namespace eval HelpViewer {}

proc HelpViewer::IsWordGood { word otherwords } {
	variable Index
	variable IndexFilesTitles
	
	if { $otherwords == "" } { return 1 }
	
	if { ![info exists Index($word)] } { return 0 }
	
	foreach i $Index($word) {
		set file [lindex [lindex $IndexFilesTitles $i] 0]
		if { [HasFileTheWord $file $otherwords] } { return 1 }
	}
	return 0
}

proc HelpViewer::HasFileTheWord { fname otherwords } {
	variable HelpBaseDir
	variable Index
	variable IndexFilesTitles
	variable FindWordInFileCache
	
	set fullfile [file join $HelpBaseDir $fname]
	
	foreach word $otherwords {
		if { [info exists FindWordInFileCache($fname,$word)] } {

			if { !$FindWordInFileCache($fname,$word) } {
				return 0
			}
			continue
		}

		set fp [open $fullfile "r"]
		set aa [read $fp]
		close $fp

		if { [string match -nocase *$word* $aa] } {
			set FindWordInFileCache($fname,$word) 1
		} else {
			set FindWordInFileCache($fname,$word) 0
			return 0
		}
	}
	return 1
}


proc HelpViewer::GiveManHelpNames { word } {
	
	if { [auto_execok man2html] == "" } { return "" }
	
	set err [catch { exec man -aw $word } file]
	if { $err } { return "" }
	
	set words ""
	foreach i [split $file \n] {
		set ext [string trimleft [file ext $i] .]
		if { $ext == "gz" } { set ext [string trimleft [file ext [file root $i]] .] }
		if { [lsearch $words "$word (man $ext)"] == -1 } {
			lappend words "$word (man $ext)"
		}
	}
	return $words
}

proc HelpViewer::WaitState { what } {
	variable tree
	variable hwidget

	# set parent [winfo parent $hwidget]
	
	switch $what {
		1 {
			$tree configure -cursor watch
			# $parent configure -cursor watch
		}
		0 {
			$tree configure -cursor ""
			# $parent configure -cursor ""
		}
	}
	update
}


proc HelpViewer::CreateIndex {} {
	variable HelpBaseDir
	variable Index
	variable IndexFilesTitles
	variable progressbar
	variable progressbarStop
	variable hwidget
	
	if { [array exists Index] } {
		return
	}
	
	if { [file exists [file join $HelpBaseDir wordindex]] } {
		set fin [open [file join $HelpBaseDir wordindex] r]
		foreach "IndexFilesTitles aa" [read $fin] break
		array set Index $aa
		close $fin
		return
	}
	
	WaitState 1
	
	ProgressDlg $hwidget.prdg -textvariable HelpViewer::progressbarT -variable \
			HelpViewer::progressbar -title "Creating search index" \
			-troughcolor \#48c96f -stop Stop -command "set HelpViewer::progressbarStop 1"
	
	set progressbar 0
	set progressbarStop 0
	
	catch { unset Index }
	
	set files [::fileutil::findByPattern $HelpBaseDir "*.htm *.html"]
	
	set len [llength [file split $HelpBaseDir]]
	set ipos 0
	set numfiles [llength $files]
	
	set IndexFilesTitles ""
	
	foreach i $files {
		set HelpViewer::progressbar [expr int($ipos*50/$numfiles)]
		set HelpViewer::progressbarT $HelpViewer::progressbar%
		if { $HelpViewer::progressbarStop } {
			destroy .prdg
			return
		}
		
		set fin [open $i r]
		set aa [read $fin]
		
		set file [eval file join [lrange [file split $i] $len end]]
		set title ""
		regexp {(?i)<title>(.*?)</title>} $aa {} title
		if { $title == "" } {
			regexp {(?i)<h([1234])>(.*?)</h\1>} $aa {} {} title
		}
		lappend IndexFilesTitles [list $file $title]
		set IndexPos [expr [llength $IndexFilesTitles]-1]
		
		foreach j [regexp -inline -all -- {-?\w{3,}} $aa] {
			if { [string is integer $j] || [string length $j] > 25 || [regexp {_[0-9]+$} $j] } {
				continue
			}
			lappend Index([string tolower $j]) $IndexPos
		}
		close $fin
		incr ipos
	}
	
	proc IndexesSortCommand { e1 e2 } {
		upvar freqs freqsL
		if { $freqsL($e1) > $freqsL($e2) } { return -1 }
		if { $freqsL($e1) < $freqsL($e2) } { return 1 }
		return 0
	}
	
	set names [array names Index]
	set len [llength $names]
	set ipos 0
	foreach i $names {
		set HelpViewer::progressbar [expr 50+int($ipos*50/$len)]
		set HelpViewer::progressbarT $HelpViewer::progressbar%
		if { $HelpViewer::progressbarStop } {
			destroy .prdg
			return
		}
		foreach j $Index($i) {
			set title [lindex [lindex $IndexFilesTitles $j] 1]
			if { [string match -nocase *$i* $title] } {
				set icr 10
			} else { set icr 1 }
			if { ![info exists freqs($j)] } {
				set freqs($j) $icr
			} else { incr freqs($j) $icr }
		}
		#          if { $i == "variable" } {
		#              puts "-----variable-----"
		#              foreach j $Index($i) {
		#                  puts [lindex $IndexFilesTitles $j]-----$j
		#              }
		#              parray freqs
		#          }
		set Index($i) [lrange [lsort -command HelpViewer::IndexesSortCommand [array names freqs]] \
				0 4]
		
		#          if { $i == "variable" } {
		#              puts "-----variable-----"
		#              foreach j [lsort -command HelpViewer::IndexesSortCommand [array names freqs]] {
		#                  puts [lindex $IndexFilesTitles $j]-----$j
		#              }
		#          }
		unset freqs
		incr ipos
	}
	
	set HelpViewer::progressbar 100
	set HelpViewer::progressbarT $HelpViewer::progressbar%
	destroy $hwidget.prdg
	set fout [open [file join $HelpBaseDir wordindex] w]
	puts -nonewline $fout [list $IndexFilesTitles [array get Index]]
	close $fout
	WaitState 0
}


proc HelpViewer::SearchInAllHelp {} {
	variable Index
	variable searchlistbox1
	
	set word [string tolower $HelpViewer::searchstring]
	CreateIndex
	
	set HelpViewer::SearchFound ""
	set HelpViewer::SearchFound2 ""
	
	if { [string trim $word] == "" } { return }
	
	set words [regexp -all -inline {\S+} $word]
	if { [llength $words] > 1 } {
		set word [lindex $words 0]
		set otherwords [lrange $words 1 end]
	} else { set otherwords "" }
	
	set ipos 0
	set iposgood -1
	foreach i [array names Index *$word*] {
		if { ![IsWordGood $i $otherwords] } { continue }
		
		lappend HelpViewer::SearchFound $i
		if { [string equal $word [lindex $i 0]] } { set iposgood $ipos }
		incr ipos
	}
	if { $iposgood == -1 && [llength [GiveManHelpNames $HelpViewer::searchstring]] > 0 } {
		lappend HelpViewer::SearchFound $HelpViewer::searchstring
		set iposgood $ipos
	}
	
	if { $iposgood >= 0 } {
		$searchlistbox1 selection clear 0 end
		$searchlistbox1 selection set $iposgood
		$searchlistbox1 see $iposgood
		SearchInAllHelpL1
	}
}

proc HelpViewer::SearchInAllHelpL1 {} {
	variable Index
	variable IndexFilesTitles
	variable SearchFound2
	variable SearchFound2data
	variable searchlistbox1
	variable searchlistbox2
	
	set SearchFound2 ""
	set SearchFound2data ""
	
	set sels [$searchlistbox1 curselection]
	if { $sels == "" } {
		return
	}
	
	set words [regexp -all -inline {\S+} $HelpViewer::searchstring]
	if { [llength $words] > 1 } {
		set otherwords [lrange $words 1 end]
	} else {
		set otherwords ""
	}
	
	set ipos 0
	set iposgood -1
	set iposgoodW -1

	foreach i $sels {
		set word [$searchlistbox1 get $i]
		if { [info exists Index($word)] } {
			foreach i $Index($word) {
				foreach "file title" [lindex $IndexFilesTitles $i] break
				
				if { ![HasFileTheWord $file $otherwords] } { continue }
				
				if { [lsearch $HelpViewer::SearchFound2 $title] != -1 } { continue }
				
				lappend SearchFound2 $title
				lappend SearchFound2data $i
				if { [string match -nocase *$word* $title] } {
					set W 1
					foreach i $otherwords {
						if { [string match -nocase *$i* $title] } { incr W }
					}
					if { [string match -nocase *$HelpViewer::searchstring* $title] } { incr W }
					if { [string equal -nocase $HelpViewer::searchstring $title] } { incr W }
					
					if { $W > $iposgoodW } {
						set iposgood $ipos
						set iposgoodW $W
					}
				}
				incr ipos
			}
		}
		foreach i [GiveManHelpNames $word] {
			lappend SearchFound2 $i
			if { $iposgood == -1 } {
				set iposgood $ipos
			} else {
				set iposgood -2
			}
			incr ipos
		}
	}
	if { $iposgood < 0 && $ipos > 0 } { set iposgood 0 }
	if { $iposgood >= 0 } {
		focus $searchlistbox2
		$searchlistbox2 selection clear 0 end
		$searchlistbox2 selection set $iposgood
		$searchlistbox2 see $iposgood
		SearchInAllHelpL2
	}
}

proc HelpViewer::SearchInAllHelpL2 {} {
	variable HelpBaseDir
	variable SearchFound2data
	variable IndexFilesTitles
	variable SearchFound2
	variable hwidget
	variable searchlistbox2
	
	set sels [$searchlistbox2 curselection]
	if { [llength $sels] != 1 } {
		# bell
		return
	}
	if { [regexp {(.*)\(man (.*)\)} [lindex $SearchFound2 $sels]] } {
		# -removed- SearchManHelpFor $hwidget [lindex $SearchFound2 $sels]
	} else {
		set i [lindex $SearchFound2data $sels]
		set file [file join $HelpBaseDir [lindex [lindex $IndexFilesTitles $i] 0]]

		LoadFile $hwidget $file 1
		$hwidget showSearchWidget
		
		# without delay, html widget 'll potentially crash!
		after idle "$hwidget setsearchstring $HelpViewer::searchstring"
	}
}


proc HelpViewer::Search {} {
	variable hwidget
	
	if { ![info exists ::HelpViewer::searchstring] } {
	
		set msg "Before using 'Continue search', use 'Search'"
		append msg [winfo toplevel $hwidget]

		tk_messageBox \
			-icon warning -message $msg \
			-type ok
		return
	}
	if { $HelpViewer::searchstring == "" } {
		return
	}

	$hwidget showSearchWidget

	# handing over the search command to the
	# html3widget (which has a build in search capability)
	# note: without delay, html widget 'll potentially crash!
	after idle "$hwidget setsearchstring $HelpViewer::searchstring"
	
}


proc HelpViewer::SearchCmd {} {
	#
	# perform search as well on the html viewer widget content
	# search up to the 1st occurance of the search string
	# so that the string item is highlighted and immediately shown
	# on the screen...
	#
	variable searchstring
	
	if {$searchstring == ""} {
		return
	}

	# html widget needs some time to establish screen...
	# catch maybe not really required, just in case...
	after 400 "catch {[namespace current]::Search}"
}


proc HelpViewer::SearchWindow {} {
	variable hwidget
	$hwidget showSearchWidget
}
# -----------------------------------------------------------------------------
# selectionmanager
#
#     This type encapsulates the code that manages selecting text
#     in the html widget with the mouse.
#
# -----------------------------------------------------------------------------

package provide selectionmanager 0.1

oo::class create selectionmanager {
	
	constructor {hwidget} {
		my variable O
		
		# Variable myMode may take one of the following values:
		#
		#     "char"           -> Currently text selecting by character.
		#     "word"           -> Currently text selecting by word.
		#     "block"          -> Currently text selecting by block.
		#
		set O(myState) false             ;# True when left-button is held down
		set O(myMode) char
		
		set O(myHtml) $hwidget
		
		set O(myFromNode) ""
		set O(myFromIdx) ""

		set O(myToNode) ""
		set O(myToIdx) ""
		set O(myIgnoreMotion) 0
				
		# (?) selection handle $hwidget "[namespace code {my get_selection}]"
		
		bind $hwidget <Motion>          "+[namespace code {my MotionCmd}] {} %x %y"
		bind $hwidget <ButtonPress-1>   "+[namespace code {my PressCmd}] {} %x %y"
		bind $hwidget <ButtonRelease-1> "+[namespace code {my ReleaseCmd}] %x %y"

		bind $hwidget <Double-ButtonPress-1> "+[namespace code {my DoublepressCmd}] %x %y"
		bind $hwidget <Triple-ButtonPress-1> "+[namespace code {my TriplepressCmd}] %x %y"
		
		bind all <Control-c> "[namespace code {my CopySelection2Clipboard}]"
	}
	
	# Clear the selection.
	#
	method ClearSelection {} {
		my variable O

		set O(myFromNode) ""
		set O(myToNode) ""
		
		$O(myHtml) tag delete selection
		$O(myHtml) tag configure selection -foreground white -background darkgrey
	}
	
	method PressCmd {N x y} {
		my variable O
		
		# Single click -> Select by character.
		my ClearSelection
		set O(myState) true
		set O(myMode) char
		my MotionCmd $N $x $y
	}
	
	# Given a node-handle/index pair identifying a character in the
	# current document, return the index values for the start and end
	# of the word containing the character.
	#
	method ToWord {node idx} {
		set t [$node text]
		set cidx [::tkhtml::charoffset $t $idx]
		set cidx1 [string wordstart $t $cidx]
		set cidx2 [string wordend $t $cidx]
		set idx1 [::tkhtml::byteoffset $t $cidx1]
		set idx2 [::tkhtml::byteoffset $t $cidx2]
		return [list $idx1 $idx2]
	}
	
	# Add the widget tag "selection" to the word containing the character
	# identified by the supplied node-handle/index pair.
	#
	method TagWord {node idx} {
		my variable O
		
		foreach {i1 i2} [my ToWord $node $idx] {}
		$O(myHtml) tag add selection $node $i1 $node $i2
	}
	
	# Remove the widget tag "selection" to the word containing the character
	# identified by the supplied node-handle/index pair.
	#
	method UntagWord {node idx} {
		my variable O
		
		foreach {i1 i2} [my ToWord $node $idx] {}
		$O(myHtml) tag remove selection $node $i1 $node $i2
	}
	
	method ToBlock {node idx} {
		my variable O
		set t [$O(myHtml) text text]
		set offset [$O(myHtml) text offset $node $idx]
		
		set start [string last "\n" $t $offset]
		if {$start < 0} {set start 0}
		set end   [string first "\n" $t $offset]
		if {$end < 0} {set end [string length $t]}
		
		set start_idx [$O(myHtml) text index $start]
		set end_idx   [$O(myHtml) text index $end]
		
		return [concat $start_idx $end_idx]
	}
	
	# method TagBlock {node idx} {
	#	my variable O
	#	
	#	foreach {n1 i1 n2 i2} [my ToBlock $node $idx] {}
	#	$O(myHtml) tag add selection $n1 $i1 $n2 $i2
	#}
	#method UntagBlock {node idx} {
	#	my variable O
	#	
	#	foreach {n1 i1 n2 i2} [my ToBlock $node $idx] {}
	#	catch {$O(myHtml) tag remove selection $n1 $i1 $n2 $i2}
	#}
	
	method DoublepressCmd {x y} {
		my variable O
		
		# Double click -> Select by word.
		my ClearSelection
		set O(myMode) word
		set O(myState) true
		my MotionCmd "" $x $y
	}
	
	method TriplepressCmd {x y} {
		my variable O
		
		# Triple click -> Select by block.
		my ClearSelection
		set O(myMode) block
		set O(myState) true
		my MotionCmd "" $x $y
	}
	
	method ReleaseCmd {x y} {
		my variable O

		set O(myState) false
	}
		
	method MotionCmd {N x y} {
		my variable O

		if {!$O(myState) || $O(myIgnoreMotion)} return
		
		set to [$O(myHtml) node -index $x $y]
		foreach {toNode toIdx} $to {}

		# $N containst the node-handle for the node that the cursor is
		# currently hovering over (according to the mousemanager component).
		# If $N is in a different stacking-context to the closest text,
		# do not update the highlighted region in this event.
		#
		if {$N ne "" && [info exists toNode]} {
			if {[$N stacking] ne [$toNode stacking]} {
				set to ""
			}
		}
		
		if {[llength $to] > 0} {
			
			if {$O(myFromNode) eq ""} {
				set O(myFromNode) $toNode
				set O(myFromIdx) $toIdx
			}
			
			# This block is where the "selection" tag is added to the HTML
			# widget (so that the selected text is highlighted). If some
			# javascript has been messing with the tree, then either or
			# both of $myFromNode and $myToNode may be orphaned or deleted.
			# If so, catch the exception and clear the selection.
			#
			set rc [catch {
				if {$O(myToNode) ne $toNode || $toIdx != $O(myToIdx)} {
					switch -- $O(myMode) {
						char {
							if {$O(myToNode) ne ""} {
								$O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
							}
							$O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
							if {$O(myFromNode) ne $toNode || $O(myFromIdx) != $toIdx} {
								selection own $O(myHtml)
							}
						}
						
						word {

							if {$O(myToNode) ne ""} {
								$O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
								my UntagWord $O(myToNode) $O(myToIdx)
							}
							
							$O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
							# my TagWord $toNode $toIdx
							my TagWord $O(myFromNode) $O(myFromIdx)
							selection own $O(myHtml)
						}
						
						block {
							set to_block2  [my ToBlock $toNode $toIdx]
							set from_block [my ToBlock $O(myFromNode) $O(myFromIdx)]
							
							if {$O(myToNode) ne ""} {
								set to_block [my ToBlock $O(myToNode) $O(myToIdx)]
								$O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
								eval $O(myHtml) tag remove selection $to_block
							}
							
							$O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
							eval $O(myHtml) tag add selection $to_block2
							eval $O(myHtml) tag add selection $from_block
							selection own $O(myHtml)
						}
					}
					
					set O(myToNode) $toNode
					set O(myToIdx) $toIdx
				}
			} msg]
			
			if {$rc && [regexp {[^ ]+ is an orphan} $msg]} {
				my ClearSelection
			}
		}
		
		set motioncmd ""
		set win $O(myHtml)
		if {$y > [winfo height $win]} {
			set motioncmd [list yview scroll 1 units]
		} elseif {$y < 0} {
			set motioncmd [list yview scroll -1 units]
		} elseif {$x > [winfo width $win]} {
			set motioncmd [list xview scroll 1 units]
		} elseif {$x < 0} {
			set motioncmd [list xview scroll -1 units]
		}
		
		if {$motioncmd ne ""} {
			set O(myIgnoreMotion) 1
			eval $O(myHtml) $motioncmd
			after 20 "[namespace code {my ContinueMotion}]"
		}
	}
	
	method ContinueMotion {} {
		my variable O
		
		set win $O(myHtml)
		set O(myIgnoreMotion) 0
		set x [expr [winfo pointerx $win] - [winfo rootx $win]]
		set y [expr [winfo pointery $win] - [winfo rooty $win]]
		set N [lindex [$O(myHtml) node $x $y] 0]
		my MotionCmd $N $x $y
	}

	method CopySelection2Clipboard {} {
		clipboard clear
		clipboard append [my selected]
	}
	
	# get_selection OFFSET MAXCHARS
	#
	#     This command is invoked whenever the current selection is selected
	#     while it is owned by the html widget. The text of the selected
	#     region is returned.
	#
	method get_selection {offset maxChars} {
		my variable O
		
		set t [$O(myHtml) text text]
		
		set n1 $O(myFromNode)
		set i1 $O(myFromIdx)
		set n2 $O(myToNode)
		set i2 $O(myToIdx)
		
		set stridx_a [$O(myHtml) text offset $O(myFromNode) $O(myFromIdx)]
		set stridx_b [$O(myHtml) text offset $O(myToNode) $O(myToIdx)]
		if {$stridx_a > $stridx_b} {
			foreach {stridx_a stridx_b} [list $stridx_b $stridx_a] {}
		}
		
		if {$O(myMode) eq "word"} {
			set stridx_a [string wordstart $t $stridx_a]
			set stridx_b [string wordend $t $stridx_b]
		}
		if {$O(myMode) eq "block"} {
			set stridx_a [string last "\n" $t $stridx_a]
			if {$stridx_a < 0} {set stridx_a 0}
			set stridx_b [string first "\n" $t $stridx_b]
			if {$stridx_b < 0} {set stridx_b [string length $t]}
		}
		
		set T [string range $t $stridx_a [expr $stridx_b - 1]]
		set T [string range $T $offset [expr $offset + $maxChars]]
		
		return $T
	}
	
	method selected {} {
		my variable O
		
		if {$O(myFromNode) eq ""} {return ""}
		return [my get_selection 0 10000000]
	}
	
	method destroy {} {
	}
}

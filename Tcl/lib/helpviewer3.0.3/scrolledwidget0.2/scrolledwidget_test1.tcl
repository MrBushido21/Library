##############################
# DEMO for Scrodget (with text)
##############################

# touch 'auto_path', so that package can be found even
#  it has not been installed in 'standard' directories.
set dir [file normalize [file dirname [info script]]]
lappend auto_path [file dirname $dir]

source scrolledwidget.tcl

package require scrolledwidget

set sc .sc
set c  .txt

# create a scrolledwidget, a text, and associate it
scrolledwidget::scrolledwidget $sc

pack $sc -side top -fill both -expand 1 -padx 2 -pady 2

text $c -wrap none \
        -relief sunken -borderwidth 2 \
        -bg green \
        -bd 5

$sc associate $c

## some decoration ###

$c insert end {

    This text widget
    has been associated to a scrolledwidget widget
    
    Type some text and observe scrollbars' behaviour
    
    ....
}

# both vertical scrollbars
$sc configure -scrollsides se -autohide true

puts "xxx [$sc cget -scrollsides] xxx"
puts "xxx [$sc cget -autohide] xxx"



# set the "container" frame border
# $sc frame configure -bd 5 -relief groove

# configure the scrollbar
# $sc eastScroll configure -width 20
# $sc westScroll configure -width 20


# ----------------------------------------------------------------------
# extra stuff ... just for control
# ----------------------------------------------------------------------

set ctrlW  .control
toplevel $ctrlW
wm title $ctrlW "Control-Panel for [info script]"
wm resizable $ctrlW 0 0
$ctrlW configure -padx 2 -pady 2 -borderwidth 2 -relief groove

set scrollside [$sc cget -scrollsides]
set autohide [$sc cget -autohide]

# scrollSide control
proc  updateScrollSide { w } {
    global scrollside
    
    set oldSS [$w cget -scrollsides]
    if { [catch {$w configure -scrollsides "$scrollside" } errMsg] } {
        tk_messageBox -icon error -message $errMsg
        set scrollside $oldSS
    }
}

label $ctrlW.lbl -textvariable ::POSITION -relief sunken -bd 2

set sFrame [labelframe $ctrlW.sides -text "scrollbar-sides" -padx 2 -pady 2]
entry $sFrame.e -textvariable scrollside
button $sFrame.b -text "Update" -command "updateScrollSide $sc"
pack $sFrame.e $sFrame.b -side left -fill x -expand 1 -padx 1m -pady 1m

labelframe $ctrlW.auto -text "Automatically hide scrollbars (if needed)"
foreach {lbl val} {
    none false
    horizontal horizontal
    vertical vertical
    both true
} {
    set w [radiobutton $ctrlW.auto.b$lbl -text "$lbl" -variable autohide \
            -relief flat -value $val\
            -command "$sc configure -autohide \$autohide" ]
    pack $w  -side left -padx 2
}


pack $ctrlW.sides $ctrlW.auto -fill x
pack $ctrlW.lbl -fill x  -padx 2 -pady 2


#  provide a feedback
bind $c <Motion> {
    set ::POSITION "Mouse at  X:%x  Y:%y"
}

# place it x-centered on the screen, ay y=0
tkwait visibility $ctrlW
wm geometry $ctrlW \
        +[expr ([winfo screenwidth $ctrlW]-[winfo width $ctrlW])/2]+0







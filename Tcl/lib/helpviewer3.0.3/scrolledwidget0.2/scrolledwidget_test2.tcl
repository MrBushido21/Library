
set dir [file normalize [file dirname [info script]]]
lappend auto_path [file dirname $dir]


# demo code...
    
package require scrolledwidget 0.2
namespace import scrolledwidget::*


# create a scrolledwidget, a text, and associate it
set sc [scrolledwidget .sc -autohide true]
pack $sc -side top -fill both -expand 1 -padx 2 -pady 2

set txt [text .txt -wrap none \
            -relief sunken -borderwidth 2 \
            -bd 5]

$sc associate $txt
# $sc configure -scrollsides se -autohide true


$txt insert end \
{

    This text widget
    has been associated to a scrolledwidget widget(-object).
    
    Resize the window or type some text to observe behaviour of the scrollbars
    ....
}


# puts "xxx [$sc cget -scrollsides] xxx"
# puts "xxx [$sc cget -autohide] xxx"

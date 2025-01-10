#
#
# "testcolors" Tk theme.
#
# Implements Tk's traditional Motif-like look and feel.
#

namespace eval ttk::theme::testcolors {

#cambiado frame activebg troughbg selectbg disabledfg
# 	-frame		"#0000ff" 
# 	-window		"#ffffff"
# 	-selectbg	"#33cda7"
# 	-selectfg	"#000000"
# 	-disabledfg	"#aaaa33"
#	-activebg	"#3333ee"

    package provide ttk::theme::testcolors 0.1

    variable colors; array set colors {
	-troughbg	"#33cda7"
	-indicator	"#b03060"

 	-frame  	"#6699cc"
 	-lighter	"#bcd2e8"
 	-window	 	"#e6f3ff"
 	-selectbg	"#ffff33"
 	-selectfg	"#000000"
 	-disabledfg	"#666666"
	-activebg	"#bcd2e8"
    }

    ttk::style theme create testcolors -settings {
	ttk::style configure "." \
	    -font		TkDefaultFont \
	    -background		$colors(-frame) \
	    -foreground		black \
	    -selectbackground	$colors(-selectbg) \
	    -selectforeground	$colors(-selectfg) \
	    -troughcolor	$colors(-troughbg) \
	    -indicatorcolor	$colors(-frame) \
	    -highlightcolor	$colors(-frame) \
	    -highlightthickness	1 \
	    -selectborderwidth	1 \
	    -insertwidth	2 \
					-background #00ff00 \
				    -selectbackground #0fff00 \
				    -fieldbackground #00ff0f \
				    -foreground #0f0fff \
				    -selectforeground #30ffff \
				    -font TkDefaultFont \
				    -troughcolor #00ff30 \
				    -borderwidth 0 \
				    -selectborderwidth 0 \
				    -focusthickness 0 \
				    -focuscolor #30ff30 \
				    -highlightthickness 0 \
				    -highlightcolor #3fff00 \
				    -indicatorcolor #00ff3f  \
				    -insertwidth 2 \
				
	    ;

	proc LoadImages {imgdir} {
        variable I
		set lst_gifs {}
		set err [ catch {
			set lst_gifs [ glob -directory $imgdir *.gif]
		}]
		if { $err} {
			WarnWinDirect "Error looking for *.gif into '$imgdir'"
			puts "Error looking for *.gif into '$imgdir'"
		}
        foreach file [glob -directory $imgdir *.gif] {
            set img [file tail [file rootname $file]]
            set I($img) [image create photo -file $file -format gif89]
        }
    }

    LoadImages [file join [file dirname [info script]] testcolors]

	# To match pre-Xft X11 appearance, use:
	#	ttk::style configure . -font {Helvetica 12 bold}

	ttk::style map "." -background \
	    [list disabled $colors(-frame) active $colors(-activebg)]
	ttk::style map "." -foreground \
	    [list disabled $colors(-disabledfg)]

	ttk::style map "." -highlightcolor [list focus black]


	ttk::style layout IconButton {
		iconbutton.button -children {
    		Toolbutton.focus -children {
				Toolbutton.padding -children {
					Toolbutton.label -side left -expand true		
				}
			}
		}
	}
	ttk::style layout Horizontal.IconButton {
		horizontaliconbutton.button -children {
    		Toolbutton.focus -children {
				Toolbutton.padding -children {
					Toolbutton.label -side left -expand true		
				}
			}
		}
	}
	ttk::style layout Vertical.IconButton {
		verticaliconbutton.button -children {
    		Toolbutton.focus -children {
				Toolbutton.padding -children {
					Toolbutton.label -side left -expand true		
				}
			}
		}
	}
	ttk::style element create iconbutton.button image [list $ttk::theme::testcolors::I(iconbutton-n) \
    pressed	$ttk::theme::testcolors::I(iconbutton-p) \
    active	$ttk::theme::testcolors::I(iconbutton-h) \
	] -border {2 23 2 5} -padding {0 1} -sticky ewns -height 30 -width 30
	ttk::style element create horizontaliconbutton.button image [list $ttk::theme::testcolors::I(iconbutton-n) \
    pressed	$ttk::theme::testcolors::I(iconbutton-p) \
    active	$ttk::theme::testcolors::I(iconbutton-h) \
	] -border {2 23 2 5} -padding 5 -sticky ewns -height 30 -width 30
	ttk::style element create verticaliconbutton.button image [list $ttk::theme::testcolors::I(iconbutton-n) \
    pressed	$ttk::theme::testcolors::I(iconbutton-p) \
    active	$ttk::theme::testcolors::I(iconbutton-h) \
	] -border {2 23 2 5} -padding 5 -sticky ewns -height 30 -width 30
	


	ttk::style configure TButton \
	    -anchor center -padding "12 4" -relief raised -shiftrelief 1
	ttk::style map TButton -relief [list {!disabled pressed} sunken]

	ttk::style configure TCheckbutton -indicatorrelief raised
	ttk::style map TCheckbutton \
	    -indicatorcolor [list \
		pressed $colors(-frame)  selected $colors(-indicator)] \
	    -indicatorrelief {selected sunken  pressed sunken} \
	    ;

	ttk::style configure TRadiobutton -indicatorrelief raised
	ttk::style map TRadiobutton \
	    -indicatorcolor [list \
		pressed $colors(-frame)  selected $colors(-indicator)] \
	    -indicatorrelief {selected sunken  pressed sunken} \
	    ;

	ttk::style configure TMenubutton -relief raised -padding "12 4"

	ttk::style configure TEntry -relief sunken -padding 1 -font TkTextFont
	ttk::style map TEntry -fieldbackground \
		[list readonly $colors(-frame) disabled $colors(-frame)]
	ttk::style configure TCombobox -padding 1
	ttk::style map TCombobox -fieldbackground \
		[list readonly $colors(-frame) disabled $colors(-frame)]

	ttk::style configure TLabelframe -borderwidth 2 -relief groove

	ttk::style configure TScrollbar -relief raised
	ttk::style map TScrollbar -relief {{pressed !disabled} sunken}

	ttk::style configure TScale -sliderrelief raised
	ttk::style map TScale -sliderrelief {{pressed !disabled} sunken}

	ttk::style configure TProgressbar -background SteelBlue
	ttk::style configure TNotebook.Tab \
	    -padding {12 4} \
	    -background $colors(-troughbg)
	ttk::style map TNotebook.Tab -background [list selected $colors(-frame)]

	# Treeview:
	ttk::style configure Heading -font TkHeadingFont -relief raised
	ttk::style configure Row -background $colors(-window)
	ttk::style configure Cell -background $colors(-window)
	ttk::style map Row \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;
	ttk::style map Cell \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;

	#
	# Toolbar buttons:
	#
	ttk::style configure Toolbutton -padding 2 -relief flat -shiftrelief 2
	ttk::style map Toolbutton -relief \
	    {disabled flat selected sunken pressed sunken active raised}
	ttk::style map Toolbutton -background \
	    [list pressed $colors(-troughbg)  active $colors(-activebg)]
    }
}

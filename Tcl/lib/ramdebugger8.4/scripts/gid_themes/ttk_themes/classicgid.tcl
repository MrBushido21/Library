# classicgid.tcl - Copyright (C) 2004 Googie
#
# A sample pixmap theme for the tile package.
#
#  Copyright (c) 2004 Googie
#  Copyright (c) 2005 Pat Thoyts <patthoyts@users.sourceforge.net>
#

package require Tk 8.4
#package require tile 0.8.0

namespace eval ttk::theme::classicgid {    
    variable version 0.1.0
    package provide ttk::theme::classicgid $version

    variable colors
    array set colors {
        -toolbars_bg "#dfdfdf"
        -frame_bg	"#f0f0f0"
        -text_bg    "#a4a4a4"
		-text_fg    "#000000"
        -colortext_fg "#000000"
        -select_fg	"#000000"
        -disabled_fg "#5d5d5d"
        -highlight  "#3399ff"
    }
  
    variable fonts
    array set fonts {
	-default TkDefaultFont
	-text TkTextFont
	-fixed TkFixedFont
	-menu TkMenuFont
	-heading TkHeadingFont
	-caption TkCaptionFont
	-smallcaption TkSmallCaptionFont
	-icon TkIconFont
	-tooltip TkTooltipFont
    }	
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
    
    LoadImages [file join [file dirname [info script]] classicgid]
    
    ttk::style theme create classicgid -parent default -settings {
	
	#ttk::style configure . \
    #	-background $colors(-frame_bg) \
	#	-selectbackground $colors(-frame_bg) \
	#	-fieldbackground $colors(-text_bg) \
	#	-foreground $colors(-colortext_fg)\
	#	-selectforeground $colors(-select_fg) \
	#	-font $fonts(-default) \
	#	-troughcolor $colors(-frame_bg) \
	#	-borderwidth 0 \
	#	-selectborderwidth 0 \
	#	-focusthickness 0\
	#	-focuscolor $colors(-frame_bg)\
	#	-highlightthickness 0\
	#	-highlightcolor $colors(-frame_bg) \
	#	-indicatorcolor $colors(-frame_bg)  \
	#	-insertwidth 2
	#;	
	#-focuscolor $colors(-highlight)\
	#-highlightcolor $colors(-highlight) \
	#-indicatorcolor $colors(-highlight)  \
	#-font TkDefaultFont
	#As some parts we use the system elements without defining one
	#We must be sure that options of this elements are defined
	#As exemple the element Button.focus on Linux have this two options: focuscolor, focusthickness	 

	#ttk::style map "." -background \
	#    [list disabled $colors(-frame_bg) active $colors(-frame_bg)]
	    	    
    #ttk::style map "." -foreground [list disabled $colors(-disabled_fg)]	

	#ttk::style map "." -highlightcolor [list focus $colors(-select_fg)]

	ttk::style element create iconbutton.button image \
	    [list $ttk::theme::classicgid::I(iconbutton-n) \
		 pressed        $ttk::theme::classicgid::I(iconbutton-p) \
		 active        $ttk::theme::classicgid::I(iconbutton-h) \
		] -border 0 -padding {0 0 1 1} -sticky ewns
	# -height 24 -width 28
	
	ttk::style element create horizontaliconbutton.button image \
	    [list $ttk::theme::classicgid::I(horizontaliconbutton-n) \
		 pressed        $ttk::theme::classicgid::I(horizontaliconbutton-p) \
		 active        $ttk::theme::classicgid::I(horizontaliconbutton-h) \
		] -border {0 11} -padding {0 0 1 1} -sticky ewns -height 24
	# -width 28
	
	ttk::style element create verticaliconbutton.button image \
	    [list $ttk::theme::classicgid::I(verticaliconbutton-n) \
		 pressed        $ttk::theme::classicgid::I(verticaliconbutton-p) \
		 active        $ttk::theme::classicgid::I(verticaliconbutton-h) \
		] -border {11 0} -padding {0 0 1 1} -sticky ewns -width 28
	# -height 24
	
	ttk::style element create iconbuttonwithmenu.button image \
	    [list $ttk::theme::classicgid::I(tmenubutton-n) \
		 pressed        $ttk::theme::classicgid::I(tmenubutton-p) \
		 active        $ttk::theme::classicgid::I(tmenubutton-h) \
		] -border {0 0 8 8} -padding {0 0 1 1} -sticky ewns
	# -height 24 -width 28
	
	ttk::style element create horizontaliconbuttonwithmenu.button image \
	    [list $ttk::theme::classicgid::I(horizontaltmenubutton-n) \
		 pressed        $ttk::theme::classicgid::I(horizontaltmenubutton-p) \
		 active        $ttk::theme::classicgid::I(horizontaltmenubutton-h) \
		] -border {0 11 8 11} -padding {0 0 1 1} -sticky ewns -height 24
	# -width 28
	
	ttk::style element create verticaliconbuttonwithmenu.button image \
	    [list $ttk::theme::classicgid::I(verticaltmenubutton-n) \
		 pressed        $ttk::theme::classicgid::I(verticaltmenubutton-p) \
		 active        $ttk::theme::classicgid::I(verticaltmenubutton-h) \
		] -border {11 0 11 8} -padding {0 0 1 1} -sticky ewns -width 28
	# -height 24
	
	
	ttk::style element create FrameIconButton.border image \
	    $ttk::theme::classicgid::I(iconbutton-n) \
	    -border 0 -padding 0 -sticky ewns
        #-height 24 -width 28
	ttk::style element create HorizontalFrameIconButton.border image \
	    $ttk::theme::classicgid::I(horizontaliconbutton-n) \
	    -border {0 11} -padding 0 -sticky ewns -height 24
        #-height 24 -width 28
	ttk::style element create VerticalFrameIconButton.border image \
	    $ttk::theme::classicgid::I(verticaliconbutton-n) \
	    -border {11 0} -padding 0 -sticky ewns -width 28
        #-height 24 -width 28
	
	
	#
	# Layouts:
	#
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

	ttk::style layout IconButtonWithMenu {
	    iconbuttonwithmenu.button -children {
    		Toolbutton.focus -children {
		    Toolbutton.padding -children {
			Toolbutton.label -side left -expand true		
		    }
		}
	    }
	}
	ttk::style layout Horizontal.IconButtonWithMenu {
	    horizontaliconbuttonwithmenu.button -children {
    		Toolbutton.focus -children {
		    Toolbutton.padding -children {
			Toolbutton.label -side left -expand true		
		    }
		}
	    }
	}
	ttk::style layout Vertical.IconButtonWithMenu {
	    verticaliconbuttonwithmenu.button -children {
    		Toolbutton.focus -children {
		    Toolbutton.padding -children {
			Toolbutton.label -side left -expand true		
		    }
		}
	    }
	}

	#
	# Settings:
	# following setting don't take effect, must put inside gid_themes.tcl
	ttk::style configure TLabelframe -labelanchor nw	
    ttk::style configure IconButton -anchor center
    ttk::style configure Horizontal.IconButton -anchor center
    ttk::style configure Vertical.IconButton -anchor center
    ttk::style configure IconButtonWithMenu -anchor center
    ttk::style configure Horizontal.IconButtonWithMenu -anchor center
    ttk::style configure Vertical.IconButtonWithMenu -anchor center
    ttk::style configure SeparatorToolbar.TFrame -background "#cfc5c3"   
    }
}

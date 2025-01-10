#
# "Clam mod" theme.
#
# Inspired by the XFCE family of Gnome themes.
#

#{left up right down}

if { $::tcl_platform(os) == "Darwin"} {
    # it seems that Mac OS X reads the image somewhat lighter than in windows and linux
    set ::clammod_gamma_value 0.87
} else {
    # this is the default gamma value
    set ::clammod_gamma_value 1.0
}

namespace eval ttk::theme::clammod {
    variable version 0.1.0
    package provide ttk::theme::clammod $version
    variable colors
    variable fonts
    variable padding
    if { ![info exists colors ] } {        
        array set colors {
            -toolbars_bg "#292929"
            -frame_bg "#b1b4b9"
            -text_bg "#c2c5ca"
            -text_fg "#ffffff"
            -colortext_fg "#000000"
            -select_fg "#000000"
            -disabled_fg "#7f8082"
            -highlight "#63a5b5"
            -complementary "#D3863A"
            -button_bg "#878a8e"            
            -buttonborder "#4b4a4d"
            -arrowcolor "#ffffff"
        }  
        #-toolbars_bg "#292929"        
        #-disabled_fg "#5d5d5d"
        #-labelframeborder "#0a0f1b"
    }
    if { ![info exists fonts ] } {
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
    }
    if { ![info exists padding ] } {
        set padding [::gid_themes::GetPaddingWidgets]
    }
    
    font create BoldDefault {*}[dict replace [font actual TkDefaultFont] -weight bold]
    font create NormalDefault {*}[dict replace [font actual TkDefaultFont] -weight normal]
    
    #---
    variable hover hover
    if { [package vsatisfies [package present Ttk] 8-8.5.9] ||   [package vsatisfies [package present Ttk] 8.6-8.6b1] } {
        # The hover state is not supported prior to 8.6b1 or 8.5.9
        set hover active
    }
    proc AverageColor { color1 color2 {porcentage 50}} {
        #porcentage 0 give color2 , 100 give color2
        scan $color1 "#%2x%2x%2x" r1 g1 b1
        scan $color2 "#%2x%2x%2x" r2 g2 b2        
        set r [expr int(((100-$porcentage)/100.0)*$r1+(($porcentage)/100.0)*$r2)]
        set g [expr int(((100-$porcentage)/100.0)*$g1+(($porcentage)/100.0)*$g2)]
        set b [expr int(((100-$porcentage)/100.0)*$b1+(($porcentage)/100.0)*$b2)]
        set rgb [format "#%02x%02x%02x" $r $g $b]
        return $rgb
    }
    proc DarkerColor { color porcentage } {
        #porcentage 0 do nothing , 100 completally black
        scan $color "#%2x%2x%2x" r g b            
        set r [expr int($r*((100-$porcentage)/100.0))]
        set g [expr int($g*((100-$porcentage)/100.0))]
        set b [expr int($b*((100-$porcentage)/100.0))]
        set rgb [format "#%02x%02x%02x" $r $g $b]
        return $rgb
    } 
    proc LighterColor { color porcentage } {
        #porcentage 0 do nothing , 100 completally white
        scan $color "#%2x%2x%2x" r g b            
        set r [expr int(255-((255-$r)*((100-$porcentage)/100.0))]
        set g [expr int(255-((255-$g)*((100-$porcentage)/100.0))]
        set b [expr int(255-((255-$b)*((100-$porcentage)/100.0))]
        set rgb [format "#%02x%02x%02x" $r $g $b]
        return $rgb
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
	    # if we change the format of the images to png, we should add -format "png -gamma $::clammod_gamma_value"
            set I($img) [image create photo -file $file -format gif89 -gamma $::clammod_gamma_value]
        }
    }
    
    LoadImages [file join [file dirname [info script]] clammod]
    
    #---
    ttk::style theme create clammod -parent clam -settings {

	ttk::style configure "." \
            -darkcolor $colors(-buttonborder) \
            -lightcolor $colors(-buttonborder) \
            -font TkDefaultFont \
            -background $colors(-frame_bg) \
            -selectbackground $colors(-highlight) \
            -fieldbackground $colors(-text_bg) \
            -foreground $colors(-colortext_fg)\
            -selectforeground $colors(-select_fg) \
            -font $fonts(-default) \
            -troughcolor $colors(-frame_bg) \
            -bordercolor $colors(-buttonborder) \
            -selectborderwidth 0 \
            -focusthickness $padding\
            -focuscolor $colors(-frame_bg)\
            -arrowcolor $colors(-arrowcolor)\
            -highlightthickness 0\
            -highlightcolor $colors(-frame_bg) \
            -indicatorcolor $colors(-frame_bg)  \
            -insertwidth $padding
        ;        
        #-focuscolor $colors(-highlight)\
        #-highlightcolor $colors(-highlight) \
        #-indicatorcolor $colors(-highlight)  \
        #-font TkDefaultFont
        #As some parts we use the system elements without defining one
        #We must be sure that options of this elements are defined
        #As exemple the element Button.focus on Linux have this two options: focuscolor, focusthickness         
        
        ttk::style map "." \
            -bordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-highlight) alternate $colors(-highlight) selected $colors(-highlight)] \
            -background [list disabled $colors(-frame_bg) active $colors(-frame_bg)] \
            -foreground [list disabled $colors(-disabled_fg)] \
            -highlightcolor [list focus $colors(-select_fg)] \
            -fieldbackground [list disabled $colors(-frame_bg) readonly $colors(-frame_bg)]
     
    
	
    
        ttk::style layout TButton {
            Button.focus -sticky nwes -children {
                Button.field -sticky nswe -border 0 -children {
                    Button.padding -sticky nswe -children {
                        Button.label -sticky nswe
                    }
                }
            }
        }
       
        
        ttk::style layout TMenubutton {
            Menubutton.focus -sticky nswe -children {
                Menubutton.field -sticky nswe -border 0 -children {
                    Menubutton.indicator -side right -sticky {} 
                    Menubutton.padding -side left -expand 1 -sticky we -children {
                        Menubutton.label -side left -sticky {}
                    }
                }
            }
        }
        ttk::style layout TCheckbutton {
            Checkbutton.focus -sticky nwes -children {
                Checkbutton.padding -sticky nswe -children {
                    Checkbutton.indicator -side left -sticky {} 
                    null -side left -sticky w -children {
                        Checkbutton.label -sticky nswe
                    }
                }
            }
        }
        ttk::style layout TRadiobutton {
            Radiobutton.focus -sticky nwes -children {
                Radiobutton.padding -sticky nswe -children {Radiobutton.indicator -side left -sticky {} null -side left -sticky {} -children {Radiobutton.label -sticky nswe}}
            }
        }
        ttk::style layout TEntry {
            Entry.focus -sticky nwes -children {
                Entry.field -sticky nswe -border 1 -children {Entry.padding -sticky nswe -children {Entry.textarea -sticky nswe}}
            }
        }
        
        ttk::style layout TCombobox {
            Combobox.focus -sticky nwes -children {
                Combobox.downarrow -side right -sticky ns 
                Combobox.field -side left -expand 1 -sticky nswe -children {
                    Combobox.padding -sticky nswe -children {
                        Combobox.textarea -sticky nswe
                    }
                }
            }
        }
        ttk::style layout TLabel {            
            Label.focus -sticky nwes -children { 
                Label.border -sticky nswe -border 1 -children {Label.padding -sticky nswe -border 1 -children {Label.label -sticky nswe}}
            }
        }
        ttk::style layout TLabelframe {
            Labelframe.focus -sticky nwes -children { 
                Labelframe.border -sticky nswe
            }
        }
        ttk::style layout TSpinbox {
            Spinbox.focus -sticky nwes -children {
                Spinbox.field -side left -expand 1 -sticky we -children {
                    Spinbox.padding -sticky nswe -children {
                        Spinbox.textarea -sticky nswe
                    }
                }
                Spinbox.buttons -side right -sticky ns -children {
                    Spinbox.uparrow -sticky en
                    Spinbox.downarrow -sticky es                            
                }
            }
        }
        
        
        #ttk::style element create spacer image $ttk::theme::clammod::I(blank) -padding 2 -sticky news
   
    #---  
        ttk::style layout Toolbutton {            
            Toolbutton.focus -sticky nwes -children {
                Toolbutton.field -sticky nswe -border 0 -children {
                    Toolbutton.padding -sticky nswe -children {
                        Toolbutton.label -sticky nswe
                    }
                }
            }
        } 
            # Toolbutton.border -sticky nswe -children {
                # Toolbutton.padding -sticky nswe -children {
                    # Toolbutton.label -sticky nswe
                # }
            # }        
        ttk::style layout IconButton {            
            IconButton.border -sticky nswe -children {
                IconButton.padding -sticky nswe -children {
                    IconButton.label -sticky nswe
                }
            }      
        }        
        ttk::style layout Horizontal.IconButton {            
            Horizontal.IconButton.border -sticky nswe -children {
                IconButton.padding -sticky nswe -children {
                    IconButton.label -sticky nswe
                }
            }            
        }       
        ttk::style layout Vertical.IconButton {            
            Vertical.IconButton.border -sticky nswe -children {
                IconButton.padding -sticky nswe -children {
                    IconButton.label -sticky nswe
                }
            }           
        }
       
        ttk::style layout IconButtonWithMenu {            
            IconButtonWithMenu.border -sticky nswe -children {
                IconButtonWithMenu.padding -sticky nswe -children {
                    IconButtonWithMenu.label -sticky nswe
                }
            }      
        }        
        ttk::style layout Horizontal.IconButtonWithMenu {            
            Horizontal.IconButtonWithMenu.border -sticky nswe -children {
                IconButtonWithMenu.padding -sticky nswe -children {
                    IconButtonWithMenu.label -sticky nswe
                }
            }            
        }       
        ttk::style layout Vertical.IconButtonWithMenu {            
            Vertical.IconButtonWithMenu.border -sticky nswe -children {
                IconButtonWithMenu.padding -sticky nswe -children {
                    IconButtonWithMenu.label -sticky nswe
                }
            }           
        }
       
        
        ttk::style layout Vertical.TScrollbar {
            Scrollbar.trough -sticky ns -children {
                Vertical.Scrollbar.uparrow -side top -sticky ew
                Vertical.Scrollbar.downarrow -side bottom -sticky ew                                
                Vertical.Scrollbar.thumb -expand 1 -unit 1 -children {
                    Vertical.Scrollbar.grip -sticky {}
                }
            }
        }
        
        ttk::style layout Horizontal.TScrollbar {
            Scrollbar.trough -sticky ew -children {
                Horizontal.Scrollbar.leftarrow -side left -sticky ns
                Horizontal.Scrollbar.rightarrow -side right -sticky ns                        
                Horizontal.Scrollbar.thumb -expand 1 -unit 1 -children {
                    Horizontal.Scrollbar.grip -sticky {}
                }
            }
        }
       
  
        ttk::style element create IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding [expr $padding*$padding+1] -sticky ews 
            #left, top, right, and bottom
            #-height 30 -width 30
        ttk::style element create Horizontal.IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding [expr $padding*$padding+1] -sticky ews
            # -height 30 -width 30
         ttk::style element create Vertical.IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding [expr $padding*$padding+1] -sticky ews
        # ttk::style element create Vertical.IconButton.border image [list $ttk::theme::clammod::I(verticaliconbutton-n) \
            # {active !pressed}        $ttk::theme::clammod::I(verticaliconbutton-h) \
            # ] -border {0 2 0 2} -padding [expr $padding*$padding+1] -sticky ens
            # -height 30 -width 30
    
        ttk::style element create IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding [expr $padding*$padding+1] -sticky ews 
            #-height 30 -width 30
        ttk::style element create Horizontal.IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding [expr $padding*$padding+1] -sticky ews
            # -height 30 -width 30
        ttk::style element create Vertical.IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding [expr $padding*$padding+1] -sticky ews
        # ttk::style element create Vertical.IconButtonWithMenu.border image [list $ttk::theme::clammod::I(verticaltmenubutton-n) \
            # {active !pressed}        $ttk::theme::clammod::I(verticaltmenubutton-h) \
            # ] -border {0 2 0 9} -padding [expr $padding*$padding+1] -sticky ens
            # -height 30 -width 30
    
       
        ttk::style element create Horizontal.Scrollbar.thumb image $ttk::theme::clammod::I(hsb-n) \
            -border 3 -sticky ew
        
        ttk::style element create Vertical.Scrollbar.thumb image $ttk::theme::clammod::I(vsb-n) \
            -border 3 -sticky ns
            
    #ttk::style element create FrameIconButton.border image \
	#    $ttk::theme::clammod::I(iconbutton-n) \
	#    -border {5 9 5 9} -padding [expr $padding*2+1] -sticky ewns
	#ttk::style element create HorizontalFrameIconButton.border image \
	#    $ttk::theme::clammod::I(horizontaliconbutton-n) \
	#    -border {5 9 5 9} -padding [expr $padding*2+1] -sticky ewns
	#ttk::style element create VerticalFrameIconButton.border image \
	#    $ttk::theme::clammod::I(verticaliconbutton-n) \
	#     -border {5 9 5 9} -padding [expr $padding*2+1] -sticky ewns
        
    
    ttk::style configure IconButton -anchor center -takefocus 0 -background $colors(-toolbars_bg) -focuscolor  $colors(-toolbars_bg) -foreground $colors(-text_bg)  
    ttk::style map IconButton -background [list pressed $colors(-highlight) active $colors(-toolbars_bg) selected $colors(-highlight) {} $colors(-toolbars_bg)] -foreground [list {} $colors(-text_bg)]
    
    ttk::style configure IconButtonWithMenu -anchor center -takefocus 0 -background $colors(-toolbars_bg) -focuscolor  $colors(-toolbars_bg) -foreground $colors(-text_bg)  
    ttk::style map IconButtonWithMenu -background [list pressed $colors(-highlight) active $colors(-toolbars_bg) selected $colors(-highlight) {} $colors(-toolbars_bg)] -foreground [list {} $colors(-text_bg)]
    
    
    #---    
    
    ttk::style configure TButton \
	    -anchor center -width -11 -padding [expr $padding+3] -relief solid \
        -fieldbackground $colors(-button_bg) \
        -background $colors(-frame_bg) -lightcolor $colors(-buttonborder) -darkcolor $colors(-buttonborder)
        # -bordercolor $colors(-buttonborder)
	ttk::style map TButton \
        -fieldbackground [list disabled $colors(-frame_bg) pressed $colors(-highlight) active $colors(-button_bg) selected $colors(-highlight)] \
        -lightcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)] \
        -darkcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)]
        #-bordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-buttonborder) alternate $colors(-buttonborder)]
    ttk::style configure TMenubutton \
	    -anchor center -width -11 -padding [expr $padding+2] -relief solid \
        -fieldbackground $colors(-button_bg) -indicatorsize [expr $padding+12] \
        -background $colors(-frame_bg) -lightcolor $colors(-buttonborder) -darkcolor $colors(-buttonborder)
        #-padding [expr $padding+3] changed because arrow image change padding
        # -bordercolor $colors(-buttonborder)
	ttk::style map TMenubutton \
        -fieldbackground [list disabled $colors(-frame_bg) pressed $colors(-highlight) active $colors(-button_bg) selected $colors(-highlight)] \
        -lightcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)] \
        -darkcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)]
	 

    
	# ttk::style configure Toolbutton \
	    # -anchor center -padding 2 -relief flat
	# ttk::style map Toolbutton \
	    # -relief [list \
		    # disabled flat \
		    # selected sunken \
		    # pressed sunken \
		    # active raised] \
	    # -background [list \
		    # disabled $colors(-frame_bg) \
		    # pressed $colors(-highlight) \
		    # active $colors(-button_bg)] \
	    # -lightcolor [list pressed $colors(-button_bg)] \
	    # -darkcolor [list pressed $colors(-button_bg)] \
	    # ;

    ttk::style configure Toolbutton \
	    -anchor center -width -11 -padding 1 -relief solid \
        -fieldbackground $colors(-button_bg) \
        -background $colors(-frame_bg) -lightcolor $colors(-buttonborder) -darkcolor $colors(-buttonborder)
        # -bordercolor $colors(-buttonborder)
	ttk::style map Toolbutton \
        -fieldbackground [list disabled $colors(-frame_bg) pressed $colors(-highlight) active $colors(-button_bg) selected $colors(-highlight)] \
        -lightcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)] \
        -darkcolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) selected $colors(-highlight)]
	 
        
        
	ttk::style configure TCheckbutton \
        -borderwidth 10 \
        -indicatorbackground $colors(-button_bg) \
        -indicatorforeground $colors(-colortext_fg) \
        -upperbordercolor $colors(-buttonborder) \
        -lowerbordercolor $colors(-buttonborder) \
        -indicatormargin {1 1 4 1} -indicatorsize [expr $padding+12]\
	    -padding [expr $padding+2]
    
    ttk::style map TCheckbutton \
        -indicatorbackground [list disabled $colors(-frame_bg) pressed $colors(-highlight)] \
        -indicatorforeground [list disabled $colors(-disabled_fg)] \
        -upperbordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) active $colors(-buttonborder)] \
        -lowerbordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) active $colors(-buttonborder)] \
        -foreground [list {disabled invalid} "#ff5d5d" disabled $colors(-disabled_fg) invalid #ff0000]
        
	ttk::style configure TRadiobutton \
	    -indicatorbackground $colors(-button_bg) \
        -indicatorforeground $colors(-colortext_fg) \
        -upperbordercolor $colors(-buttonborder) \
        -lowerbordercolor $colors(-buttonborder) \
        -indicatormargin {1 1 4 1} -indicatorsize [expr $padding+12]\
	    -padding [expr $padding+2]
        
    ttk::style map TRadiobutton \
        -indicatorbackground [list disabled $colors(-frame_bg) pressed $colors(-highlight)] \
        -indicatorforeground [list disabled $colors(-disabled_fg)] \
        -upperbordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) active $colors(-buttonborder)] \
        -lowerbordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) active $colors(-buttonborder)] \
        -foreground [list {disabled invalid} "#ff5d5d" disabled $colors(-disabled_fg) invalid #ff0000]
        
	ttk::style configure TEntry -padding [list $padding [expr $padding+1] $padding [expr $padding+1]] -insertwidth 1 \
        -lightcolor $colors(-frame_bg) -darkcolor $colors(-frame_bg)
	ttk::style map TEntry \
        -lightcolor [list disabled $colors(-frame_bg) hover $colors(-highlight) pressed $colors(-buttonborder) alternate $colors(-buttonborder) focus $colors(-complementary)] \
        -darkcolor [list disabled $colors(-frame_bg) hover $colors(-highlight) pressed $colors(-buttonborder) alternate $colors(-buttonborder) focus $colors(-complementary)]
	    ;
        #-bordercolor [list  focus $colors(-selectbg)]

	ttk::style configure TCombobox -padding [list $padding [expr $padding+1] $padding [expr $padding+1]] -arrowsize [expr $padding+12] -insertwidth 1 \
        -fieldbackground $colors(-text_bg) -backgroundactive "#00ff00" -activebackground "#0000ff"\
        -lightcolor $colors(-frame_bg) -darkcolor $colors(-frame_bg)
    #-bordercolor $colors(-buttonborder)
	ttk::style map TCombobox \
	    -background [list disabled $colors(-frame_bg) {active pressed} $colors(-highlight) active $colors(-button_bg)] \
	    -fieldbackground [list disabled $colors(-frame_bg)] \
        -lightcolor [list disabled $colors(-frame_bg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-highlight)] \
        -darkcolor [list disabled $colors(-frame_bg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-highlight)] \
        -arrowcolor [list disabled $colors(-disabled_fg)]
        #-bordercolor [list disabled $colors(-disabled_fg)  hover $colors(-highlight) focus $colors(-complementary) active $colors(-buttonborder)]
	    
	ttk::style configure ComboboxPopdownFrame \
	    -relief solid -borderwidth 1

	ttk::style configure TSpinbox -arrowsize [expr $padding+12] -padding [list $padding [expr $padding+1] [expr $padding+8] [expr $padding+1]] \
        -lightcolor $colors(-frame_bg) -darkcolor $colors(-frame_bg)
	ttk::style map TSpinbox \
        -lightcolor [list disabled $colors(-frame_bg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-buttonborder) alternate $colors(-buttonborder)] \
        -darkcolor [list disabled $colors(-frame_bg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-buttonborder) alternate $colors(-buttonborder)] \
        -background [list disabled $colors(-frame_bg) {active pressed} $colors(-highlight) active $colors(-button_bg)] \
        -arrowcolor [list disabled $colors(-disabled_fg)]

    ttk::style configure TNotebook \
        -padding [list [expr $padding*3] 0 [expr $padding*3] $padding] -borderwidth $padding -bordercolor $colors(-buttonborder) -lightcolor $colors(-buttonborder) -darkcolor  $colors(-buttonborder) -tabmargins {0 2 0 0} -relief solid
    ttk::style map TNotebook \
        -bordercolor [list active $colors(-highlight)] \
        -lightcolor [list active $colors(-highlight)] \
        -darkcolor  [list active $colors(-highlight)]
	ttk::style configure TNotebook.Tab -padding {2 2 2 2} -expand {0 0 2} \
        -bordercolor $colors(-disabled_fg) -lightcolor  $colors(-disabled_fg) -darkcolor  "#0000ff"
	ttk::style map TNotebook.Tab \
	    -padding [list selected {6 4 6 2}] -expand [list selected {1 2 4 2}]\
        -background [list {active pressed} $colors(-highlight) active $colors(-button_bg)] \
        -bordercolor [list  hover $colors(-highlight) focus $colors(-complementary) active $colors(-highlight) selected $colors(-buttonborder)] \
        -lightcolor [list  hover $colors(-highlight) focus $colors(-complementary) active $colors(-highlight) selected $colors(-buttonborder)] \
        -darkcolor [list  hover $colors(-highlight) focus $colors(-complementary) active $colors(-highlight) selected $colors(-buttonborder)]
	# Treeview:
	ttk::style configure Heading \
	    -font TkHeadingFont -relief raised -padding {3}
	ttk::style configure Treeview -background $colors(-text_bg)
	#ttk::style map Treeview -background [list selected $colors(-selectbg)] -foreground [list selected $colors(-selectfg)] ;

    ttk::style configure TLabel -takefocus 0 
    
    #ttk::style configure TLabelframe \
	#    -labeloutside false -labelmargins {10 5 10 5} \
	#    -borderwidth 2 -relief solid -padding [list [expr $padding*2+2] 0 [expr $padding*2+2] $padding] \
    #    -bordercolor $colors(-buttonborder)
    ttk::style configure TLabelframe \
	    -labeloutside false -labelmargins {10 5 10 5} \
	    -borderwidth 2 -relief solid -padding [list [expr $padding*2+2] 0 [expr $padding*2+2] $padding] \
        -bordercolor [AverageColor $colors(-highlight) $colors(-buttonborder) 70]
    ttk::style map TLabelframe \
        -bordercolor [list disabled $colors(-disabled_fg)]
    ttk::style configure TFrame \
	    -borderwidth 0 -relief flat -padding {1 1 1 1} \
        -bordercolor $colors(-buttonborder) -lightcolor $colors(-frame_bg) -darkcolor $colors(-frame_bg)
    ttk::style map TFrame \
        -bordercolor [list disabled $colors(-disabled_fg)]
    ttk::style configure TLabel \
        -borderwidth 0 -relief flat \
        -bordercolor $colors(-buttonborder)
    ttk::style map TLabel \
        -bordercolor [list disabled $colors(-disabled_fg)] -foreground [list {disabled invalid} "#ff5d5d" disabled $colors(-disabled_fg) invalid #ff0000]
    
    ttk::style configure TLabelframe.Label \
        -borderwidth 0 -relief flat \
        -bordercolor $colors(-buttonborder)
    ttk::style map TLabelframe.Label \
        -bordercolor [list disabled $colors(-disabled_fg)] -foreground [list {disabled invalid} "#ff5d5d" disabled $colors(-disabled_fg) invalid #ff0000]
    
    
     
	ttk::style configure TProgressbar -background $colors(-highlight)
    ttk::style map TProgressbar -bordercolor {}

	ttk::style configure Sash -sashthickness 6 -gripcount 10
    
    ttk::style configure TScrollbar \
        -background $colors(-frame_bg)\
        -arrowsize [expr $padding+12] \
        -lightcolor $colors(-frame_bg) \
        -darkcolor $colors(-frame_bg) \
        -bordercolor $colors(-frame_bg) \
        -troughcolor $colors(-frame_bg)
    ttk::style map TScrollbar \
        -bordercolor [list disabled $colors(-frame_bg)  hover $colors(-highlight) focus $colors(-complementary) pressed $colors(-highlight) alternate $colors(-highlight)] \
        -background [list disabled $colors(-frame_bg) {active pressed} $colors(-highlight) active $colors(-button_bg)] \
        -lightcolor [list disabled $colors(-frame_bg) {active pressed} $colors(-highlight) active $colors(-button_bg)] \
        -darkcolor [list disabled $colors(-frame_bg) {active pressed} $colors(-highlight) active $colors(-button_bg)]
    
    ttk::style configure SeparatorToolbar.TFrame -background "#1a5b6b" 
    
    
    #style padding 0   
    ttk::style configure Padding0.TButton -padding 3 -focusthickness 0
    ttk::style configure Padding0.TMenubutton -padding 2 -focusthickness 0
    ttk::style configure Padding0.TCheckbutton -padding 2 -focusthickness 0
    ttk::style configure Padding0.TRadiobutton -padding 2 -focusthickness 0
    ttk::style configure Padding0.TEntry -padding [list 0 1 0 1] -focusthickness 0
    ttk::style configure Padding0.TCombobox -padding [list 0 1 0 1] -focusthickness 0
    ttk::style configure Padding0.TSpinbox -padding [list 0 1 8 1] -focusthickness 0

    
    
    
     # ttk::style configure TScrollbar \
        # -background $colors(-button_bg)\
        # -arrowsize 14 \
        # -lightcolor $colors(-buttonborder) \
        # -darkcolor $colors(-buttonborder) \
        # -bordercolor $colors(-frame_bg) \
        # -troughcolor $colors(-frame_bg)
        
        # -gripcount 1000 \
        # -sliderlength 1 \
        # -relief solid \
        
        # #-background
        # #-bordercolor
        # #-troughcolor
        # #-lightcolor
        # #-darkcolor
        # #-arrowcolor
        # #-arrowsize
        # #-gripcount
        # #-sliderlength
    
    # }
}

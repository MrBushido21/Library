#
# "Clam mod" theme.
#
# Inspired by the XFCE family of Gnome themes.
#

#{left up right down}

if { $::tcl_platform(os) == "Darwin"} {
    # it seems that Mac OS X reads the image somewhat lighter than in windows and linux
    set ::clammod_light_2_gamma_value 0.87
} else {
    # this is the default gamma value
    set ::clammod_light_2_gamma_value 1.0
}

uplevel #0 [
    namespace eval ttk::theme::clammod {        
        variable colors 
        array set colors {
            -toolbars_bg "#f0f0f0"
            -frame_bg "#f0f0f0"
            -text_bg "#ffffff"
            -text_fg "#000000"
            -colortext_fg "#000000"
            -select_fg "#00343d"
            -disabled_fg "#807f7d"
            -highlight "#5ac9da"
            -complementary "#00343d"
            -button_bg "#e0e0e0"
            -buttonborder "#d0d0d0"
            -arrowcolor "#000000"
        }  
        #-button_bg "#d8d8d8"            
        #-buttonborder "#b4b5b2"
        #-highlight "#009db7"        
        #-labelframeborder "#000708"
        # -toolbars_bg "#d7d7d6"  
        #-colortext_fg "#00343d"      
        
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
        variable padding
        set padding [::gid_themes::GetPaddingWidgets]
    }
    list source [file join $::GIDDEFAULT scripts gid_themes ttk_themes clammod.tcl] 
]

namespace eval ttk::theme::clammod_light_2 {
    variable version 0.1.0
    package provide ttk::theme::clammod_light_2 $version

    variable colors 
    array set colors [array get ttk::theme::clammod::colors]
    variable fonts
    array set fonts [array get ttk::theme::clammod::fonts] 
    variable padding
    set padding [::gid_themes::GetPaddingWidgets]
    
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
            set I($img) [image create photo -file $file -format gif89 -gamma $::clammod_light_2_gamma_value]
        }
    }
    
    # LoadImages [file join [file dirname [info script]] clammod_light_2]
    # we use same images as 'clammod_light' instead of using our own ...
    LoadImages [file join [file dirname [info script]] clammod_light]
    
    ttk::style theme create clammod_light_2 -parent clammod -settings {
        foreach type { "." TButton TMenubutton TCheckbutton TRadiobutton TEntry TCombobox TSpinbox \
			   Toolbutton IconButton Horizontal.IconButton Vertical.IconButton \
			   IconButtonWithMenu Horizontal.IconButtonWithMenu Vertical.IconButtonWithMenu \
			   Vertical.TScrollbar Horizontal.TScrollbar ComboboxPopdownFrame \
			   TNotebook TNotebook.Tab Heading Treeview TProgressbar Sash TScrollbar TFrame TLabel TLabelframe TLabelframe.Label \
               Padding0.TButton Padding0.TMenubutton Padding0.TCheckbutton Padding0.TRadiobutton Padding0.TEntry Padding0.TCombobox Padding0.TSpinbox} {
            ttk::style configure $type {*}[ttk::style theme settings clammod [list ttk::style configure $type ]]
            ttk::style map $type {*}[ttk::style theme settings clammod [list ttk::style map $type ]]
        }
	ttk::style configure "." -focusthickness 1
	set my_padding [expr $padding+1]

        ttk::style element create IconButton.border image [list $ttk::theme::clammod_light_2::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding $my_padding -sticky ews 
            #left, top, right, and bottom
            #-height 30 -width 30
        ttk::style element create Horizontal.IconButton.border image [list $ttk::theme::clammod_light_2::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding $my_padding -sticky ews
            # -height 30 -width 30
         ttk::style element create Vertical.IconButton.border image [list $ttk::theme::clammod_light_2::I(iconbutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(iconbutton-h) \
            ] -border {2 0 2 0} -padding $my_padding -sticky ews
        # ttk::style element create Vertical.IconButton.border image [list $ttk::theme::clammod_light_2::I(verticaliconbutton-n) \
            # {active !pressed}        $ttk::theme::clammod_light_2::I(verticaliconbutton-h) \
            # ] -border {0 2 0 2} -padding $my_padding -sticky ens
            # -height 30 -width 30
    
        ttk::style element create IconButtonWithMenu.border image [list $ttk::theme::clammod_light_2::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding $my_padding -sticky ews 
            #-height 30 -width 30
        ttk::style element create Horizontal.IconButtonWithMenu.border image [list $ttk::theme::clammod_light_2::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding $my_padding -sticky ews
            # -height 30 -width 30
        ttk::style element create Vertical.IconButtonWithMenu.border image [list $ttk::theme::clammod_light_2::I(tmenubutton-n) \
            {active !pressed}        $ttk::theme::clammod_light_2::I(tmenubutton-h) \
            ] -border {2 0 9 0} -padding $my_padding -sticky ews            
        # ttk::style element create Vertical.IconButtonWithMenu.border image [list $ttk::theme::clammod_light_2::I(verticaltmenubutton-n) \
            # {active !pressed}        $ttk::theme::clammod_light_2::I(verticaltmenubutton-h) \
            # ] -border {0 2 0 9} -padding $my_padding -sticky ens
            # -height 30 -width 30
    
        
       
        ttk::style element create Horizontal.Scrollbar.thumb image $ttk::theme::clammod_light_2::I(hsb-n) \
            -border 3 -sticky ew
        
        ttk::style element create Vertical.Scrollbar.thumb image $ttk::theme::clammod_light_2::I(vsb-n) \
            -border 3 -sticky ns
        
        
    
        ttk::style configure IconButton -foreground $colors(-colortext_fg) 
        ttk::style map IconButton -foreground [list {} $colors(-colortext_fg)]
    
        ttk::style configure IconButtonWithMenu -foreground $colors(-colortext_fg)
        ttk::style map IconButtonWithMenu -foreground [list {} $colors(-colortext_fg)]
    
	# more modified paddings:
	set pad_left [ expr $padding + 2]
	set pad_right [ expr $padding + 2]
	set pad_top 0
	set pad_bottom 0
	set pad_1_less [ expr $padding-1]
	if { $pad_1_less < 0} {
	    set pad_1_less 0
	}
	ttk::style configure TButton -padding $padding
	ttk::style configure TMenubutton -padding $pad_1_less
	ttk::style configure TCheckbutton \
	    -indicatorsize [expr $padding+10] \
	    -padding 0
	ttk::style configure TRadiobutton \
	    -indicatorsize [expr $padding+10] \
	    -padding 0
	ttk::style configure TEntry \
	    -padding [list  $pad_left $pad_top $pad_right $pad_bottom]
	ttk::style configure TCombobox \
	    -arrowsize [expr $padding+10] \
	    -padding [list  $pad_left $pad_top $pad_right $pad_bottom]
	ttk::style configure TSpinbox \
	    -arrowsize [expr $padding+10] \
	    -padding [list  $pad_left $pad_top [ expr $padding+6] $pad_bottom]
	ttk::style configure TNotebook \
	    -padding [list  $pad_left $pad_top $pad_right $pad_bottom] \
	    -borderwidth $padding \
	    -tabmargins {0 2 0 0} -relief solid
	#ttk::style configure TLabelframe \
	    #    -labeloutside false -labelmargins {10 5 10 5} \
	    #    -borderwidth 2 -relief solid -padding [list [expr $padding*2+2] 0 [expr $padding*2+2] $padding] \
	    #    -bordercolor $colors(-buttonborder)
	ttk::style configure TLabelframe \
	    -borderwidth 2 \
	    -padding [list [expr $padding+1] 0 [expr $padding+1] $padding]

	ttk::style configure Padding0.TButton -padding $padding -focusthickness 0
	ttk::style configure Padding0.TMenubutton -padding $pad_1_less -focusthickness 0
	ttk::style configure Padding0.TCheckbutton -padding 0 -focusthickness 0
	ttk::style configure Padding0.TRadiobutton -padding 0 -focusthickness 0
	ttk::style configure Padding0.TEntry -padding [list 0 1 0 1] -focusthickness 0
	ttk::style configure Padding0.TCombobox -padding [list 0 1 0 1] -focusthickness 0
	ttk::style configure Padding0.TSpinbox -padding [list 0 1 8 1] -focusthickness 0

        ttk::style configure TScrollbar -style flat.TFrame

        # ttk::style configure  SeparatorToolbar.TFrame -background "#cfc5c3"
        # ttk::style configure  SeparatorToolbar.TFrame -background "#f5f6f7"
        ttk::style configure SeparatorToolbar.TFrame -background "#e5e5e5"
        # for label frame use same border color as frames, which are the same as buttons
        ttk::style configure TLabelframe -bordercolor $colors(-buttonborder)
    }

}

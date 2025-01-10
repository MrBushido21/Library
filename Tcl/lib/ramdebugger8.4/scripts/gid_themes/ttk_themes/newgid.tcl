# newgid.tcl - Copyright (C) 2004 Googie
#
# A sample pixmap theme for the tile package.
#
#  Copyright (c) 2004 Googie
#  Copyright (c) 2005 Pat Thoyts <patthoyts@users.sourceforge.net>
#

package require Tk
#package require Tk 8.4
#package require tile 0.8.0

namespace eval ttk::theme::newgid {
    
    variable version 0.1.0
    package provide ttk::theme::newgid $version
    
    variable colors
    array set colors {
        -toolbars_bg "#282829"
        -frame_bg "#b1b4b9"
        -text_bg "#c2c5ca"
        -text_fg "#ffffff"
        -colortext_fg "#000000"
        -select_fg "#000000"
        -disabled_fg "#5d5d5d"
        -highlight "#63a5b5"
    }    
    #color blavos-frame #9ca4ac
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
    #array set fonts {
        #        -default TkDefaultFont #This font is the default for all GUI items not otherwise specified. 
        #        -text TkTextFont #This font should be used for user text in entry widgets, listboxes etc. 
        #        -fixed TkFixedFont #This font is the standard fixed-width font. 
        #        -menu TkMenuFont #This font is used for menu items. 
        #        -heading TkHeadingFont #This font should be used for column headings in lists and tables. 
        #        -caption TkCaptionFont #This font should be used for window and dialog caption bars. 
        #        -smallcaption TkSmallCaptionFont #This font should be used for captions on contained windows or tool dialogs. 
        #        -icon TkIconFont #This font should be used for icon captions. 
        #        -tooltip TkTooltipFont #This font should be used for tooltip windows (transient information windows). 
        #}
    
    
    variable hover hover
    if { [package vsatisfies [package present Ttk] 8-8.5.9] ||   [package vsatisfies [package present Ttk] 8.6-8.6b1] } {
        # The hover state is not supported prior to 8.6b1 or 8.5.9
        set hover active
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
    
    LoadImages [file join [file dirname [info script]] newgid]
    
    ttk::style theme create newgid -parent default -settings {
        
        ttk::style configure . \
            -background $colors(-frame_bg) \
            -selectbackground $colors(-highlight) \
            -fieldbackground $colors(-text_bg) \
            -foreground $colors(-colortext_fg)\
            -selectforeground $colors(-select_fg) \
            -font $fonts(-default) \
            -troughcolor $colors(-frame_bg) \
            -borderwidth 0 \
            -selectborderwidth 0 \
            -focusthickness 0\
            -focuscolor $colors(-frame_bg)\
            -highlightthickness 0\
            -highlightcolor $colors(-frame_bg) \
            -indicatorcolor $colors(-frame_bg)  \
            -insertwidth 2
        ;        
        #-focuscolor $colors(-highlight)\
        #-highlightcolor $colors(-highlight) \
        #-indicatorcolor $colors(-highlight)  \
        #-font TkDefaultFont
        #As some parts we use the system elements without defining one
        #We must be sure that options of this elements are defined
        #As exemple the element Button.focus on Linux have this two options: focuscolor, focusthickness         
        
        ttk::style map "." -background [list disabled $colors(-frame_bg) active $colors(-frame_bg)]
                
        ttk::style map "." -foreground [list disabled $colors(-disabled_fg)]
        
        ttk::style map "." -highlightcolor [list focus $colors(-select_fg)]
        
        #
        # Layouts:
        #
        ttk::style layout Vertical.TScrollbar {
            Scrollbar.trough -sticky ns -children {
                Vertical.Scrollbar.uparrow -side top -sticky {}
                Vertical.Scrollbar.downarrow -side bottom -sticky {}                                
                Vertical.Scrollbar.thumb -expand 1 -unit 1 -children {
                    Vertical.Scrollbar.grip -sticky {}
                }
            }
        }
        
        ttk::style layout Horizontal.TScrollbar {
            Scrollbar.trough -sticky ew -children {
                Horizontal.Scrollbar.leftarrow -side left -sticky {}
                Horizontal.Scrollbar.rightarrow -side right -sticky {}                        
                Horizontal.Scrollbar.thumb -expand 1 -unit 1 -children {
                    Horizontal.Scrollbar.grip -sticky {}
                }
            }
        }
        
        ttk::style layout TButton {
            spacer -sticky nwes -children {
                Button.focus -children {
                    newgid.button -children {                                
                        Button.padding -children {
                            Button.label -side left -expand true
                        }
                    }
                }
            }
        }
        
        ttk::style layout IconButton {
            Toolbutton.focus -children {
                iconbutton.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        ttk::style layout Horizontal.IconButton {
            Toolbutton.focus -children {
                horizontaliconbutton.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        ttk::style layout Vertical.IconButton {
            Toolbutton.focus -children {
                verticaliconbutton.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        
        ttk::style layout IconButtonWithMenu {
            Toolbutton.focus -children {
                iconbuttonwithmenu.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        ttk::style layout Horizontal.IconButtonWithMenu {
            Toolbutton.focus -children {
                horizontaliconbuttonwithmenu.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        ttk::style layout Vertical.IconButtonWithMenu {
            Toolbutton.focus -children {
                verticaliconbuttonwithmenu.button -children {                    
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
        }
        
        ttk::style layout Toolbutton {
            Toolbutton.border -children {
                Toolbutton.button -children {
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true
                    }
                }
            }
        }
        
        ttk::style layout TMenubutton {
            spacer -sticky nwes -children {
                Menubutton.button -children {
                    Menubutton.indicator -side right
                    Menubutton.focus -children {
                        Menubutton.padding -children {
                            Menubutton.label -side left -expand true
                        }
                    }
                }
            }
        }
        ttk::style layout TCheckbutton {
            spacer -sticky nwes -children {
                Checkbutton.padding -sticky nswe -children {
                    Checkbutton.indicator -side left -sticky {} 
                    Checkbutton.focus -side left -sticky w -children {
                        Checkbutton.label -sticky nswe
                    }
                }
            }
        }
        ttk::style layout TRadiobutton {
            spacer -sticky nwes -children {
                Radiobutton.padding -sticky nswe -children {
                    Radiobutton.indicator -side left -sticky {} 
                    Radiobutton.focus -side left -sticky {} -children {
                        Radiobutton.label -sticky nswe
                    }
                }
            }
        }

        ttk::style layout TEntry {
            spacer -sticky nwes -children {
                Entry.field -sticky nswe -border 1 -children {
                    Entry.padding -sticky nswe -children {
                        Entry.textarea -sticky nswe
                    }
                }
            }
        }
        ttk::style layout TLabelframe {
            Labelframe.border -sticky nswe
        }
        ttk::style layout TCombobox {
            spacer -sticky nwes -children {
                Combobox.field -sticky nswe -children {
                    Combobox.downarrow -side right -sticky ns 
                    Combobox.padding -expand 1 -sticky nswe -children {
                        Combobox.textarea -sticky nswe
                    }
                }
            }
        }
        ttk::style layout TLabel {            
            spacer -sticky nwes -children {                
                Label.border -sticky nswe -border 1 -children {                    
                    Label.padding -sticky nswe -border 1 -children {
                        Label.label -sticky nswe
                    }
                }
            }
        }
        
        ttk::style layout TablelistHeader.TLabel {
            newgid.label -sticky nswe -children {                                
                Label.padding -sticky nswe -border 1 -children {
                    Label.label -sticky nswe
                }                
            }
        }
        
        
        
        ttk::style element create FrameIconButton.border image \
	    $ttk::theme::newgid::I(iconbutton-n) \
	    -border 0 -padding 0 -sticky news
	    # -height 24 -width 28
	ttk::style element create HorizontalFrameIconButton.border image \
	    $ttk::theme::newgid::I(horizontaliconbutton-n) \
	    -border 2 -padding 2 -sticky news 
	    #-height 24 -width 28
	ttk::style element create VerticalFrameIconButton.border image \
	    $ttk::theme::newgid::I(verticaliconbutton-n) \
	    -border 2 -padding 2 -sticky news 
	    #-height 24 -width 28
        
        
        
        
        #
        # Elements:
        #
        ttk::style element create newgid.label image [list $ttk::theme::newgid::I(TablelistHeader-n) \
                pressed        $ttk::theme::newgid::I(TablelistHeader-p) \
                active        $ttk::theme::newgid::I(TablelistHeader-h) \
                ] -border {0 8 1 9} -padding {0} -sticky ewns 
        
        ttk::style element create newgid.button image [list $ttk::theme::newgid::I(button-n) \
                pressed        $ttk::theme::newgid::I(button-p) \
                active         $ttk::theme::newgid::I(button-h) \
                disabled       $ttk::theme::newgid::I(button-d) \
                ] -border {2 2 2 21} -padding {5 2} -sticky ewns 
        
        ttk::style element create iconbutton.button image [list $ttk::theme::newgid::I(iconbutton-n) \
        pressed        $ttk::theme::newgid::I(iconbutton-p) \
            active        $ttk::theme::newgid::I(iconbutton-h) \
            ] -border {2 12 2 2} -padding 5 -sticky ewns 
            #-height 30 -width 30
    ttk::style element create horizontaliconbutton.button image [list $ttk::theme::newgid::I(horizontaliconbutton-n) \
            pressed        $ttk::theme::newgid::I(iconbutton-p) \
            active        $ttk::theme::newgid::I(iconbutton-h) \
            ] -border {2 11 2 3} -padding 5 -sticky ewns 
            #-height 30 -width 30
    ttk::style element create verticaliconbutton.button image [list $ttk::theme::newgid::I(verticaliconbutton-n) \
            pressed        $ttk::theme::newgid::I(iconbutton-p) \
            active        $ttk::theme::newgid::I(iconbutton-h) \
            ] -border {2 11 2 3} -padding 5 -sticky ewns
            # -height 30 -width 30
    
    ttk::style element create iconbuttonwithmenu.button image [list $ttk::theme::newgid::I(tmenubutton-n) \
            pressed        $ttk::theme::newgid::I(tmenubutton-p) \
            active        $ttk::theme::newgid::I(tmenubutton-h) \
            ] -border {2 20 9 9} -padding 5 -sticky ewns 
            #-height 30 -width 30
    ttk::style element create horizontaliconbuttonwithmenu.button image [list $ttk::theme::newgid::I(horizontaltmenubutton-n) \
            pressed        $ttk::theme::newgid::I(tmenubutton-p) \
            active        $ttk::theme::newgid::I(tmenubutton-h) \
            ] -border {2 20 9 9} -padding 5 -sticky ewns
            # -height 30 -width 30
    ttk::style element create verticaliconbuttonwithmenu.button image [list $ttk::theme::newgid::I(verticaltmenubutton-n) \
            pressed        $ttk::theme::newgid::I(tmenubutton-p) \
            active        $ttk::theme::newgid::I(tmenubutton-h) \
            ] -border {2 20 9 9} -padding 5 -sticky ewns
            # -height 30 -width 30
    
    ttk::style element create Toolbutton.button image [list $ttk::theme::newgid::I(tbutton-n) \
        {active !disabled}        $ttk::theme::newgid::I(tbutton-h) \
        selected                  $ttk::theme::newgid::I(tbutton-p) \
        pressed                   $ttk::theme::newgid::I(tbutton-p) \
        disabled                  $ttk::theme::newgid::I(tbutton-d) \
        ] -border {2 12 2 11} -padding 5 -sticky news
    
    ttk::style element create Checkbutton.indicator image [list $ttk::theme::newgid::I(check-nu) \
        {active selected}        $ttk::theme::newgid::I(check-hc) \
        {pressed selected}       $ttk::theme::newgid::I(check-nc) \
        {disabled selected}      $ttk::theme::newgid::I(check-dc) \
        active                   $ttk::theme::newgid::I(check-hu) \
        disabled                 $ttk::theme::newgid::I(check-du) \
        selected                 $ttk::theme::newgid::I(check-nc) \
        ] -sticky {}
        
        ttk::style element create Radiobutton.indicator image [list $ttk::theme::newgid::I(radio-nu) \
                {active selected}        $ttk::theme::newgid::I(radio-hc) \
                {pressed selected}       $ttk::theme::newgid::I(radio-nc) \
                {disabled selected}      $ttk::theme::newgid::I(radio-dc) \
                active                   $ttk::theme::newgid::I(radio-hu) \
                disabled                 $ttk::theme::newgid::I(radio-du) \
                selected                 $ttk::theme::newgid::I(radio-nc) \
                ] -sticky {}
        
        #ttk::style element create Horizontal.Scrollbar.trough -background #ff0000
        ttk::style element create Horizontal.Scrollbar.thumb image $ttk::theme::newgid::I(hsb-n) \
            -border 3 -sticky ew
        #ttk::style element create Horizontal.Scrollbar.grip image $ttk::theme::newgid::I(hsb-g)
        ttk::style element create Horizontal.Scrollbar.trough image $ttk::theme::newgid::I(hsb-t)
        ttk::style element create Vertical.Scrollbar.thumb image $ttk::theme::newgid::I(vsb-n) \
            -border 3 -sticky ns
        #ttk::style element create Vertical.Scrollbar.grip image $ttk::theme::newgid::I(vsb-g)
        ttk::style element create Vertical.Scrollbar.trough image $ttk::theme::newgid::I(vsb-t)
        ttk::style element create Scrollbar.uparrow image \
            [list $ttk::theme::newgid::I(arrowup-n) pressed $ttk::theme::newgid::I(arrowup-p)] -sticky {}
        ttk::style element create Scrollbar.downarrow \
            image [list $ttk::theme::newgid::I(arrowdown-n) pressed $ttk::theme::newgid::I(arrowdown-p)] -sticky {}
        ttk::style element create Scrollbar.leftarrow \
            image [list $ttk::theme::newgid::I(arrowleft-n) pressed $ttk::theme::newgid::I(arrowleft-p)] -sticky {}
        ttk::style element create Scrollbar.rightarrow \
            image [list $ttk::theme::newgid::I(arrowright-n) pressed $ttk::theme::newgid::I(arrowright-p)] -sticky {}
        
        ttk::style element create Horizontal.Scale.slider image [list $ttk::theme::newgid::I(hslider-n) \
             pressed $ttk::theme::newgid::I(hslider-p)] -sticky {}
        ttk::style element create Horizontal.Scale.trough image $ttk::theme::newgid::I(hslider-t) \
            -border 1 -padding 0
        ttk::style element create Vertical.Scale.slider image [list $ttk::theme::newgid::I(vslider-n) \
            pressed $ttk::theme::newgid::I(vslider-p)] -sticky {}
        ttk::style element create Vertical.Scale.trough image $ttk::theme::newgid::I(vslider-t) \
            -border 1 -padding 0
        
        ttk::style element create Entry.field \
            image [list $ttk::theme::newgid::I(entry-n) focus $ttk::theme::newgid::I(entry-f)] \
            -border 2 -padding {3 4} -sticky news
        
        ttk::style element create Labelframe.border image $ttk::theme::newgid::I(border) \
            -border 4 -padding 4 -sticky news
        
        ttk::style element create Menubutton.button \
            image [list $ttk::theme::newgid::I(combo-r) active $ttk::theme::newgid::I(combo-ra)] \
            -sticky news -border {4 6 24 15} -padding {4 4 5}
        ttk::style element create Menubutton.indicator \
            image [list $ttk::theme::newgid::I(arrow-n) disabled $ttk::theme::newgid::I(arrow-d)] \
            -sticky e -border {15 0 0 0}
        
        ttk::style element create spacer image $ttk::theme::newgid::I(blank) -padding 2 -sticky news
        
        ttk::style element create Combobox.field \
            image [list $ttk::theme::newgid::I(combo-n) \
                [list readonly $hover !disabled]        $ttk::theme::newgid::I(combo-ra) \
                [list focus $hover !disabled]        $ttk::theme::newgid::I(combo-fa) \
                [list $hover !disabled]                $ttk::theme::newgid::I(combo-a) \
                [list !readonly focus !disabled]        $ttk::theme::newgid::I(combo-f) \
                [list !readonly disabled]                $ttk::theme::newgid::I(combo-d) \
                readonly                                $ttk::theme::newgid::I(combo-r) \
                ] -border {4 6 24 15} -padding {4 4 5} -sticky news
        ttk::style element create Combobox.downarrow \
            image [list $ttk::theme::newgid::I(arrow-n) disabled $ttk::theme::newgid::I(arrow-d)] \
            -sticky e -border {15 0 0 0}
        
        ttk::style element create Notebook.client image $ttk::theme::newgid::I(notebook-c) -border 4
        ttk::style element create Notebook.tab image [list $ttk::theme::newgid::I(notebook-tn) \
                selected        $ttk::theme::newgid::I(notebook-ts) \
                active        $ttk::theme::newgid::I(notebook-ta) \
                ] -padding {0 2 0 0} -border {4 10 4 10}
        
        ttk::style element create Horizontal.Progressbar.trough \
            image $ttk::theme::newgid::I(hprogress-t) -border 2
        ttk::style element create Vertical.Progressbar.trough \
            image $ttk::theme::newgid::I(vprogress-t) -border 2
        ttk::style element create Horizontal.Progressbar.pbar \
            image $ttk::theme::newgid::I(hprogress-b) -border {2 2 2 16}
        ttk::style element create Vertical.Progressbar.pbar \
            image $ttk::theme::newgid::I(vprogress-b) -border {16 2 2 2}
        
        ttk::style element create Treeheading.cell \
            image [list $ttk::theme::newgid::I(tree-n) pressed $ttk::theme::newgid::I(tree-p)] \
            -border {4 10} -padding 4 -sticky ewns
        
        # Use the treeview item indicator from the alt theme, as that looks better
        ttk::style element create Treeitem.indicator from alt
        
        #
        # Settings:
        #
        #ttk::style configure TFrame -padding {6 2 6 2}
	# ttk::style configure TFrame -background $colors(-frame_bg) -foreground $colors(-text_bg)  
        ttk::style configure TLabelframe -padding {6 2 6 6} -font $fonts(-heading) -labelanchor nw
        ttk::style configure TButton -anchor center -takefocus 0
        ttk::style configure IconButton -anchor center -takefocus 0 -background $colors(-toolbars_bg) -foreground $colors(-text_bg)  
        ttk::style configure Horizontal.IconButton -anchor center -takefocus 0 -background $colors(-toolbars_bg)
        ttk::style configure Vertical.IconButton -anchor center -takefocus 0 -background $colors(-toolbars_bg)
        ttk::style configure IconButtonWithMenu -anchor center -takefocus 0 -background $colors(-toolbars_bg) -foreground $colors(-text_bg)  
        ttk::style configure Horizontal.IconButtonWithMenu -anchor center -takefocus 0 -background $colors(-toolbars_bg)
        ttk::style configure Vertical.IconButtonWithMenu -anchor center -takefocus 0 -background $colors(-toolbars_bg)
        ttk::style configure Toolbutton -anchor center -takefocus 0
        ttk::style configure TEntry -selectbackground $colors(-highlight)
        ttk::style configure TMenubutton -selectbackground $colors(-highlight)
        ttk::style configure TCombobox -selectbackground $colors(-highlight)
               
        ttk::style configure TNotebook -tabmargins {0 2 0 0}
        ttk::style configure TNotebook.Tab -padding {6 2 6 2} -expand {0 0 2}
        ttk::style map TNotebook.Tab -expand [list selected {1 2 4 2}]
        ttk::style configure ComboboxPopdownFrame -relief solid -borderwidth 1
        #ttk::style configure TScrollbar -background #ff0000 -troughcolor #ff0000
        
        # Spinbox (only available since 8.6b1 or 8.5.9)
        
        ttk::style layout TSpinbox {
            spacer -sticky nwes -children {
                Spinbox.field -side top -sticky we -children {
                    Spinbox.buttons -side right -sticky ns -border 1 -children {
                        null -side right -sticky ns -children {
                            Spinbox.uparrow -side top -sticky ens
                            Spinbox.downarrow -side bottom -sticky ens
                        }
                    }
                    Spinbox.padding -sticky nswe -children {
                        Spinbox.textarea -sticky nswe
                    }
                }
            }
        }
        ttk::style element create Spinbox.field \
            image [list $ttk::theme::newgid::I(spinbox-n) focus $ttk::theme::newgid::I(spinbox-f)] \
            -border {2 2 19 2} -padding {3 0 0} -sticky news
        ttk::style element create Spinbox.buttons \
            image [list $ttk::theme::newgid::I(spinbut-n)] \
            -border {5 3 3} -padding {0 1 0 1} -sticky news
            #[list $hover !disabled] $ttk::theme::newgid::I(spinbut-a)
        ttk::style element create Spinbox.uparrow image [list $ttk::theme::newgid::I(spinup-n) \
                disabled        $ttk::theme::newgid::I(spinup-d) \
                pressed        $ttk::theme::newgid::I(spinup-p) \
                active        $ttk::theme::newgid::I(spinup-h) \
                ] -border {2 2 2 7} -padding {0}
    ttk::style element create Spinbox.downarrow image [list $ttk::theme::newgid::I(spindown-n) \
        disabled        $ttk::theme::newgid::I(spindown-d) \
            pressed        $ttk::theme::newgid::I(spindown-p) \
            active        $ttk::theme::newgid::I(spindown-h) \
            ] -border {2 7 2 2} -padding {0}
    ttk::style element create Spinbox.padding image $ttk::theme::newgid::I(spinbut-n) \
        -border {0 3}
        #not working font on TEntry, Combobox and TSpinbox, seams they take font from tk::entry
        # Treeview (since 8.6b1 or 8.5.9)
        ttk::style configure Treeview -background $colors(-text_bg)
        ttk::style map Treeview \
            -background [list selected $colors(-text_bg)] \
            -foreground [list selected $colors(-select_fg)]
        
        # Treeview (older version)
        ttk::style configure Row -background $colors(-text_bg)
        ttk::style configure Cell -background $colors(-text_bg)
        ttk::style map Row \
            -background [list selected $colors(-highlight)] \
            -foreground [list selected $colors(-select_fg)]
        ttk::style map Cell \
            -background [list selected $colors(-highlight)] \
            -foreground [list selected $colors(-select_fg)]
        ttk::style map Item \
            -background [list selected $colors(-highlight)] \
            -foreground [list selected $colors(-select_fg)]          
    }    
}

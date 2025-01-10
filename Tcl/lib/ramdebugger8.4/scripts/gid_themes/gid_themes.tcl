# set ::gid_themes_get_image_mode "debug" ;#raise errors including stack trace
set ::gid_themes_get_image_mode "release" ;#not raise error messages

# moved to pkgIndex.tcl as it is needed in both no_gid_theme and gid_theme
# if { $::tcl_platform(os) == "Darwin"} {
#     # it seems that Mac OS X reads the image somewhat lighter than in windows and linux
#     set ::gamma_value 0.87
# } else {
#     # this is the default gamma value
#     set ::gamma_value 1.0
# }

# Some MACs doesn't suport transparency so beter disabled
proc SetBackgroundToAlphaPixels { img background } {
    if { $img == ""} {
        return
    }
    if { [ lsearch [ image names ] $img ] == -1} {
        return
    }
    image create photo imgtoreturn
    imgtoreturn put [ $img data -background $background ]
    for {set x 0} {$x < [image width $img]} {incr x 1} { 
        for {set y 0} {$y < [image height $img]} {incr y 1} {
            imgtoreturn transparency set $x $y [$img transparency get $x $y]
        }
    }
    $img copy imgtoreturn  
    image delete imgtoreturn
}

namespace eval gid_themes {
    variable IconCategories {"generic" "small_icons" "large_icons" "menu" "toolbar"}
    variable Themes
    variable DefaultFontValues
}

proc gid_themes::ImageCreatePhoto { filename} {
    set extra_opts ""
    if { [string tolower [file extension $filename]] == ".png" } {
        set extra_opts [list -format "png -gamma $::gamma_value"]
    }
    set img [image create photo -file $filename -gamma $::gamma_value {*}$extra_opts]
    return $img
}

proc gid_themes::GetImageNoImage {} {
    # themes/GiD_classic/images/small_size(16andmore)/erase-cross.png
    set return_img [image create photo erase-cross-16x16.png -data {
            iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAB3RJTUUH2woaDBkBJCSJ/AAAAAlw
            SFlzAAAewQAAHsEBw2lUUwAAAARnQU1BAACxjwv8YQUAAALNSURBVHjapVJLaFNBFD3vzfskjaZJ
            TNOkxvijfhIVNV0UvygVvytxpwtFXAgKimKlIiKC4kJEECld6UJEUHTlp+KiLly1UFxIVdpo1ZCa
            NDF9L3n/GV9q46eoGwdmGIZzzz33nAH+c3Gs8/QNtDTvZxy8rDjxgY7mDgjZzEvuyRNjOvj93r0x
            ygsdYii8lfk9m/SqpgtIRA5hdoPAVapAIDiXm+m9axBc70+nL7UNDFi1QpZOix9bU3ukxuBh37xE
            u9ggiLRSKpYc446AsewoPP4F0E1wmglCxCYk4+dTPJcsxmKnLOINFYOBC03z5+2SiQjn3VtNnfja
            O5wrnWzr6x0S8LlwDLx5GX55EWyLQFFBaBloCexxTCshNfgiciyykLz/BHt8vFI0tTOayt1yi79O
            ejApcd22JiyedQp+aR+8JArDBiru9oUAnQJDb1Gt6BlFkk9EXzx78JuJ9QtLJiUsXdjqKOUrhGpb
            UFJ5aDUiCxWlgryq77hpKk/PA/SfsajhcLe9faPJliYYmxNlLBxhlj/Ahol8ux8IT8fzPxQAsub1
            HfWuXXaQ10siDAOuBzalNhNcoRFB3O0FOfJXAlvy7pTWrT7L22WBy+dBbQfVCfW2qVQfUodiBsd7
            wrzQ9RhY/SsBmeo+h1+z8hEXEcP4nHXZKMwv6ktV1Y9XqH1PslkLT8gKn3toDl2wAfT5fUCZVOAW
            B7Gk9SpS0RC+5FxbOVDXuGrZ7GoGhmcDhdfM7FRNow+MIS4K6+Pgt/4cQW5Mo33RZnwaQQ0Ay6HG
            hNETgt1XB6WB7Ahjx0qWPhiQRI+fcCfOTY3PozkUxHguWA/VUY0RWta7p5u1CtZgFqzToBRxWUzF
            gcXfCXKFVyiU+2GxWuZlJ1O+6LOswT9FvBxO75hp9vhlQgVgR+1N4EzlDctIhxGQOpCvDsmW9fBf
            /2TMsa75LGFtPcFvO84/23ouD+IAAAAASUVORK5CYII=
        }]
    return $return_img
}

proc gid_themes::GetScreenDPI {} {
    set retDPI 75
    set max_dpi 75
    if { $::tcl_platform(os) == "Linux"} {
        # using xrandr or xdpyinfo
        set err_tool [catch { exec xrandr } tool_output]
        if { $err_tool} {
            # don't complain too much about a warnings, just issue a warning in stdout ...
            puts "Found problems with xrandr:\n$tool_output\nTrying xdpyinfo (less acurate screen dpi info)."
            # Using xdpyinfo instead ...
            set err_tool [catch { exec xdpyinfo } tool_output]
            if { $err_tool} {
                # don't complain too much about a warnings, just issue a warning in stdout ...
                puts "Found problems with xdpyinfo:\n$tool_output"
            }
        }
        
        if { !$err_tool} {
            # process output
            set lines [ split $tool_output \n]
            # if we have several monitors connected, we get the highest dpi
            foreach ln $lines {
                # first try xrandr output
                if { [regexp {.+ connected.+ ([0-9]+)x([0-9]+)[+-][0-9]+[+-][0-9]+ .+ ([0-9]+)mm x ([0-9]+)mm.*$} $ln all pix_w pix_h pix_w_mm pix_h_mm] == 1} {
                    set my_dpi 75
                    if { $pix_w_mm != 0} {
                        set my_dpi [expr ( 25.4 * $pix_w) / $pix_w_mm]
                    }
                    if { $my_dpi > $max_dpi} { set max_dpi $my_dpi}
                    
                    # try xdpyinfo output
                } elseif { [regexp {.+resolution: +([0-9]+)x([0-9]+) .+} $ln all dpi_w dpi_h] == 1} {
                    if { $dpi_w > $max_dpi} { 
                        set max_dpi $dpi_w
                    }
                }
            }
        }
        set retDPI $max_dpi
    }
    if { $::tcl_platform(os) == "Darwin" } {
        # using https://stackoverflow.com/questions/20099333/terminal-command-to-show-connected-displays-monitors-resolutions
        # system_profiler SPDisplaysDataType
        # defaults read /Library/Preferences/com.apple.windowserver.plist
        set err_tool [ catch { exec defaults read /Library/Preferences/com.apple.windowserver.plist } tool_output]
        if { $err_tool} {
            # don't complain too much about a warnings, just issue a warning in stdout ...
            puts "Found problems with 'defaults read /Library/Preferences/com.apple.windowserver.plist':\n$tool_output"
        }
        
        if { !$err_tool} {
            # process output
            set lines [ split $tool_output \n]
            # if we have several monitors connected, we get the highest dpi
            foreach ln $lines {
                # first try xrandr output
                if { [regexp {.+ kCGDisplayHorizontalResolution = ([0-9]+);} $ln all my_dpi] == 1} {
                    if { $my_dpi > $max_dpi} { 
                        set max_dpi $my_dpi
                    }
                }
            }
        }
        set retDPI $max_dpi
    }
    return $retDPI
}

proc gid_themes::GetDefaultHighResolutionScaleFactor {} {
    set my_dpi [gid_themes::GetScreenDPI]
    # GiD is still readable at a FullHD 14" laptop: 1920x1080 on 309mm x 174mm = 158dpi
    set still_readable_dpi 160
    # set factor [expr round( $my_dpi / $still_readable_dpi)]
    set factor [expr int(($my_dpi+$still_readable_dpi-1.0)/$still_readable_dpi)]
    if { $factor > 3} { 
        set factor 3
    } elseif { $factor < 1} { 
        set factor 1
    }
    return $factor
}

proc gid_themes::HighResolutionSize { size } {
    set factor [GiD_Set Theme(HighResolutionScaleFactor)]
    return [expr $size*$factor]
}

#clasic=true, new=false, test=false
proc gid_themes::GetOnlyDefineColorsOnMainGiDFrame { } {
    variable Themes
    return $Themes([gid_themes::GetCurrentTheme],OnlyDefineColorsOnMainGiDFrame)                
}

#clasic=clammod_light clasic(orig)=cassicgid, black=clammod
proc gid_themes::GetTtkTheme { } {
    variable Themes
    return $Themes([gid_themes::GetCurrentTheme],TtkTheme)                
}

#clasic=false, new=true, test=true
proc gid_themes::GetTkFromTheme { } {
    variable Themes
    return $Themes([gid_themes::GetCurrentTheme],TkFromTheme)                
}

proc gid_themes::GetTypeMenu { } {        
    if { $::tcl_platform(platform) == "windows" || $::tcl_platform(os) == "Darwin" } {
        variable Themes
        return $Themes([gid_themes::GetCurrentTheme],TypeMenu)                
    } else {
        #only generic it's possible
        return "generic"
    }
}

proc gid_themes::GetPaddingWidgets { } {
    variable Themes
    return $Themes([gid_themes::GetCurrentTheme],PaddingWidgets)
}

#valid variable names:
# BackgroundColor BackColorType BackColorTop BackColorBottom BackColorSense
# ColorPoints ColorNodes ColorLines ColorPolyLines ColorSurfaces ColorSurfsIsoparametric ColorVolumes ColorElements
proc gid_themes::GetVariableDefault { variable_name } {
    variable Themes
    return $Themes([gid_themes::GetCurrentTheme],$variable_name)
}

proc gid_themes::ConfigureHeaders { T } {
    set style header5    
    upvar ::ttk::theme::[GetTtkTheme]::colors colors
    upvar ::ttk::theme::[GetTtkTheme]::fonts fonts        
    $T element create header.text text -statedomain header -lines 1 -fill black -font $fonts(-default)    
    $T element create header.sort image -statedomain header \
        -image [list [gid_themes::GetImage ArrowDown.png small_icons] down [gid_themes::GetImage ArrowUp.png small_icons] up]    
    $T gradient create Gnormal -orient vertical \
        -stops [list [list 0.0 $colors(-text_bg)] [list 0.5 $colors(-frame_bg)] [list 1.0 $colors(-toolbars_bg)]] \
        -steps 6    
    $T gradient create Gactive -orient vertical \
        -stops [list [list 0.0 $colors(-text_bg)] [list 0.5 $colors(-highlight)] [list 1.0 $colors(-toolbars_bg)]] \
        -steps 6    
    $T gradient create Gpressed -orient vertical \
        -stops [list [list 0.0 $colors(-toolbars_bg)] [list 0.5 $colors(-frame_bg)] [list 1.0 $colors(-text_bg)]] \
        -steps 6        
    $T gradient create Gsorted -orient vertical \
        -stops [list [list 0.0 $colors(-text_bg)] [list 0.5 $colors(-frame_bg)] [list 1.0 $colors(-toolbars_bg)]] \
        -steps 6    
    $T gradient create Gactive_sorted -orient vertical \
        -stops [list [list 0.0 $colors(-text_bg)] [list 0.5 $colors(-highlight)] [list 1.0 $colors(-toolbars_bg)]] \
        -steps 6    
    $T gradient create Gpressed_sorted -orient vertical \
        -stops [list [list 0.0 $colors(-toolbars_bg)] [list 0.5 $colors(-frame_bg)] [list 1.0 $colors(-text_bg)]] \
        -steps 6    
    $T element create header.rect5 rect -statedomain header \
        -fill [list \
            Gactive_sorted {active up} \
            Gpressed_sorted {pressed up} \
            Gactive_sorted {active down} \
            Gpressed_sorted {pressed down} \
            Gsorted up \
            Gsorted down \
            Gactive active \
            Gpressed pressed \
            Gnormal {} ] \
        -outline [list \
            $colors(-highlight) up \
            $colors(-highlight) down \
            $colors(-frame_bg) {} ] \
        -outlinewidth 1 -open { nw !pressed }    
    set S [$T style create $style -orient horizontal -statedomain header]
    $T style elements $S {header.rect5 header.text header.sort}
    $T style layout $S header.rect5 -detach yes -iexpand xy
    $T style layout $S header.text -center xy -padx 6 -pady 2 -squeeze x
    $T style layout $S header.sort -expand nws -padx {0 6} -visible {no {!down !up}}    
    set textColor $colors(-colortext_fg)
    $T element configure header.text -fill $textColor
}

proc gid_themes::ApplyHeadersConfig { T } {        
    set style header5        
    foreach H [$T header id !header4] {
        $T header style set $H all $style
        $T header configure all all -textpadx 6
        foreach C [$T column list] {
            $T header text $H $C [$T header cget $H $C -text]
        }        
    }
}

proc gid_themes::GetAvailableSystemDefaultFont { lst_desired_fonts} {
    # Tk fonts use system fonts and not the ones installed within GiD
    set fnt_lst [font families]
    # if not found return first one
    set ret_fnt [lindex $fnt_lst 0]
    foreach ff $lst_desired_fonts {
        if { [lsearch $fnt_lst $ff] != -1} {
            set ret_fnt $ff
            break
        }
    }
    return $ret_fnt
}

proc gid_themes::GetDefaultFontValue { name option} {
    variable DefaultFontValues
    return $DefaultFontValues($name,$option)
}

proc gid_themes::SetFontsDefault { disp_height } {
    variable DefaultFontValues
    global tcl_platform        
    #change for panoramic screens: 768 --> 800
    if { $disp_height > 1024} {
        set fontsize 10
        set bigfontsize 14
        set smallfontsize 8
    } elseif { $disp_height >= 800 && $disp_height <= 1024 } {
        set fontsize 9
        set bigfontsize 12
        set smallfontsize 8
    } elseif { $disp_height >= 600 && $disp_height < 800 } {
        # for linux (before it was 8)
        set fontsize 8
        set bigfontsize 10
        set smallfontsize 6
    } elseif { $disp_height >= 480 && $disp_height < 600 } {
        set fontsize 8
        set bigfontsize 10
        set smallfontsize 6
    } else {
        set fontsize 6
        set bigfontsize 10
        set smallfontsize 5
    }    
    if { $::tcl_platform(os) == "IRIX" } {
        font create NormalFont -family helvetica -size 10 -slant roman
        option add *font -*-helvetica-medium-r-*-*-17-*-*-*-*-*-*-*
        font create BoldFont -weight bold -size $fontsize -family helvetica
        font create FixedFont -size $fontsize -family Courier
    } elseif { $::tcl_platform(platform) == "windows"} {
        set fontsize 8
        set def_fnt [ gid_themes::GetAvailableSystemDefaultFont [ list "Segoe UI" "MS Reference Sans Serif" "MS Sans Serif"]]
        catch {
            #too big font
            #set size [expr [ GiD_Info menuheight]-4]
            set size [expr [ GiD_Info menuheight]-6]
            font create NormalFont -family $def_fnt -size -$size
            set fontsize [font actual NormalFont -size]
            font delete NormalFont
        }
        set bigfontsize [ expr $fontsize + 4]
        set smallfontsize [ expr $fontsize - 2]
        font create NormalFont -family $def_fnt -size $fontsize
        font create BoldFont -size $fontsize -family "MS Sans Serif" -weight bold
        set def_fnt [ gid_themes::GetAvailableSystemDefaultFont [ list "Lucida Console" "Courier New" "Courier" "FixedSys"]]
        font create FixedFont -size $fontsize -family $def_fnt
        option add *font NormalFont
    } elseif { $::tcl_platform(os) == "Darwin"} {
        set fontsize 12
        catch {
            font create NormalFont -family "Geneva" -size -$fontsize
            set fontsize [font actual NormalFont -size]
            font delete NormalFont
        }
        set bigfontsize [ expr $fontsize + 4]
        set smallfontsize [ expr $fontsize - 2]
        font create NormalFont -family "Geneva" -size $fontsize
        font create BoldFont -size $fontsize -family "Geneva" -weight bold
        font create FixedFont -size $fontsize -family Courier
        option add *font NormalFont
    } else {
        # porque hay un menos en el tamanno?
        #font create NormalFont -family Helvetica -size [expr -$fontsize]
        # Helvetica is there no more .... (snif, snif)
        # font create NormalFont -family Helvetica -size [expr $fontsize]
        # font create BoldFont -weight bold -size $fontsize -family helvetica
        # looking for a font
        set def_fnt [ gid_themes::GetAvailableSystemDefaultFont [ list FreeSans "Open Sans" "Liberation Sans" "Nimbus Sans L" "DejaVu Sans" Roboto]]
        set fxd_fnt [ gid_themes::GetAvailableSystemDefaultFont \
                [ list FreeMono "Open Sans Mono" "Liberation Mono" "Nimbus Mono L" "DejaVuSans Mono" "Roboto Mono" Courier]]
        font create NormalFont -family $def_fnt -size [expr $fontsize]
        font create BoldFont -weight bold -size $fontsize -family $def_fnt
        font create FixedFont -size $fontsize -family $fxd_fnt
        option add *font NormalFont
    }
    
    set family [font conf NormalFont -family]
    font create BigFont -family $family -size $bigfontsize
    font create SmallFont -family $family -size $smallfontsize
    font configure TkDefaultFont -family $family    
    option add *font TkDefaultFont    
    # TkDefaultFont is used in CustomLib to get the size & co. for the tree
    # in linux it's default size is '12' which is too big in comparison to GiD fonts
    if { $::tcl_platform(platform) != "windows"} {
        catch {
            font configure TkDefaultFont -size [ font configure NormalFont -size]
        }
    }    
    # Store values for 'default preferences'
    foreach fnt [ list NormalFont TkDefaultFont SmallFont BigFont FixedFont] {
        foreach opt [ list family size weight slant] {
            set DefaultFontValues($fnt,$opt) [ font actual $fnt -$opt]
        }
    }    
    # [expr int($fontsize*1.5)]
    return 0
}

proc gid_themes::SetOptions { } {                
    global tcl_platform GidPriv        
    #other gidpriv variables done down
    uplevel #0 [list source [file join $::GIDDEFAULT scripts gid_themes ttk_themes [gid_themes::GetTtkTheme].tcl]]
    
    
    option add *Entry*BorderWidth 1
    option add *Button*relief "raised"
    option add *Menubutton*relief "raised"        
    
    if { $::tcl_platform(platform) != "windows" } {
        option add *Scrollbar*Width 10            
        option add *Scrollbar*BorderWidth 1
        option add *Button*BorderWidth 1            
        #option add *Menu*BorderWidth 1
        #option add *Menu*activeBorderWidth 0
        #option add *Menu*Relief flat            
    }
    option add *Menu*TearOff 0
    
    # if { [ tk windowingsystem] == "x11"} {
    #     ttk::style theme use clam
    # }
        
    GiD_Set Theme(MenuType) [gid_themes::GetTypeMenu]        
        
    if { [gid_themes::GetTkFromTheme] } {
        upvar ::ttk::theme::[GetTtkTheme]::colors colors
        upvar ::ttk::theme::[GetTtkTheme]::fonts fonts                    
        #option add *TopLevel.background $colors(-frame_bg)
        #option add *Frame.background $colors(-frame_bg)                                    
        option add *background $colors(-frame_bg)
        option add *selectBackground $colors(-highlight)
        option add *activeBackground $colors(-highlight) 
        option add *highlightBackground $colors(-frame_bg) 
        option add *insertBackground $colors(-highlight)                        
        option add *foreground $colors(-colortext_fg)
        option add *activeForeground $colors(-colortext_fg)
        option add *selectForeground $colors(-select_fg)
        option add *disabledForeground $colors(-disabled_fg)                        
        option add *font $fonts(-default)            
        option add *troughColor $colors(-text_bg)
        
        #CAUTION DON'T UNCOMMNENT
        # styles configured with borderwidth, become wrong, example ComboboxPopdownFrame
        # option add *borderWidth 0
        # option add *relief flat 
        
        option add *selectBorderWidth 0
        option add *activeBorderWidth 0    
        option add *insertBorderWidth 0            
        option add *highlightThickness 0
        option add *highlightColor $colors(-highlight)            
        option add *insertWidth 2                        
        
        #??exist??
        option add *fieldBackground $colors(-text_bg)
        option add *focusthickness 0
        option add *focuscolor $colors(-highlight) 
        option add *indicatorcolor $colors(-frame_bg)   
        
        #other possible: anchor compound insertOffTime insertOnTime justify orient padX padY relief repeatDelay repeatInterval
        # setGrid takeFocus underline wrapLength
        
        #specific for some widgets differ from general
        option add *Button*borderWidth 2
        #-background $GidPriv(Color,ToolbarBg) -borderwidth 1 -relief raised -activeborderwidth 0
        option add *Menu*background $colors(-frame_bg)            
        option add *Menu*borderWidth 1
        option add *Menu*disabledForeground $colors(-disabled_fg)
        option add *Menu*activeBorderWidth 0
        option add *Menu*activeForeground $colors(-colortext_fg)
        option add *Menu*relief solid                
        
        option add *Entry*background $colors(-text_bg)            
        option add *Listbox*background $colors(-text_bg)            
        option add *Text*background $colors(-text_bg)
        option add *TreeCtrl*background $colors(-text_bg)
        option add *Fulltktree*background $colors(-text_bg)
        
        
        option add *Tablelist*background $colors(-text_bg)            
        option add *Tablelist*labelRelief flat
        option add *Tablelist*labelBackground $colors(-frame_bg)
        option add *Tablelist*labelActiveBackground $colors(-highlight) 
                
        #foreground font borderwidth highlightthickness  highlightcolor headerfont headerforeground 
        set ::GidPriv(Color,ToolbarBg) $colors(-toolbars_bg)
        set ::GidPriv(Color,CommandLineBg) $colors(-text_bg)
        set ::GidPriv(ToolbarBg) $::GidPriv(Color,ToolbarBg) ;#defined only for back compatibility (GiD-CEM3.0,etc)
        
        set ::GidPriv(Color,BackgroundListbox) $colors(-text_bg)
        set ::GidPriv(Color,DisabledBackgroundEntry) $colors(-text_bg)
        set ::GidPriv(Color,DisabledForegroundEntry) $colors(-disabled_fg)
        set ::GidPriv(Color,DisabledForegroundMenu) $colors(-disabled_fg)
        set ::GidPriv(Color,BackgroundFileDialog) $colors(-text_bg)
        set ::GidPriv(ToolbarBg) $::GidPriv(Color,ToolbarBg) ;#defined only for back compatibility (GiD-CEM3.0,etc)
        
        set ::GidPriv(Color,BotonActivo) $colors(-highlight)
        set ::GidPriv(Color,BotonMarcoActivo) $colors(-highlight)           
        
        set ::GidPriv(Original,Color,Background) $colors(-toolbars_bg)
        #set GidPriv(Original,Color,Foreground) [ .gid cget -foreground]
        
        set ::GidPriv(CustomColor,ToolbarBg) $::GidPriv(Color,ToolbarBg)
        
        #foreach col_idx {BotonActivo BotonMarcoActivo DisabledBackgroundEntry DisabledForegroundEntry BackgroundListbox DisabledForegroundMenu CommandLineBg ToolbarBg BackgroundFileDialog} {
        #    set GidPriv(Original,Color,$col_idx) $GidPriv(Color,$col_idx)
        #}        
        
        DynamicHelp::configure -background $colors(-frame_bg)
        DynamicHelp::configure -borderwidth 1
        #DynamicHelp -border color forced to be black
        
        package require Plotchart
        ::Plotchart::plotstyle configure default xyplot margin bottom 40    
        ::Plotchart::plotstyle configure default xyplot leftaxis   color      #00a3c5
        ::Plotchart::plotstyle configure default xyplot leftaxis   textcolor  #00a3c5
        ::Plotchart::plotstyle configure default xyplot bottomaxis color      #00a3c5
        ::Plotchart::plotstyle configure default xyplot bottomaxis textcolor  #00a3c5
        ::Plotchart::plotstyle configure default xyplot background outercolor $colors(-toolbars_bg)
        ::Plotchart::plotstyle configure default xyplot background innercolor $colors(-toolbars_bg) ;#not implemented yet
        ::Plotchart::plotstyle configure default xyplot title      background $colors(-toolbars_bg)
        ::Plotchart::plotstyle configure default xyplot title      textcolor  $colors(-text_fg)
        
        ::Plotchart::plotstyle load default
        
        
    } else {
        DynamicHelp::configure -background #f0f0f0
        DynamicHelp::configure -borderwidth 1
        #DynamicHelp -border color forced to be black
        
        #package require Plotchart
        #::Plotchart::plotstyle configure default xyplot margin bottom 40    
        #::Plotchart::plotstyle configure default xyplot leftaxis   color      green
        #::Plotchart::plotstyle configure default xyplot leftaxis   textcolor  green
        #::Plotchart::plotstyle configure default xyplot bottomaxis color      green
        #::Plotchart::plotstyle configure default xyplot bottomaxis textcolor  green
        #::Plotchart::plotstyle configure default xyplot background outercolor white
        #::Plotchart::plotstyle configure default xyplot background innercolor white ;#not implemented yet
        #::Plotchart::plotstyle configure default xyplot title      background white
        #::Plotchart::plotstyle configure default xyplot title      textcolor  black        
        #::Plotchart::plotstyle load default
                
        option add *activeBackground [ CCColorActivo orange 129]            
        option add *activeForeground Black         
        
        set ::GidPriv(Color,BotonActivo) [ CCColorActivo orange 129]            
        set ::GidPriv(Color,BotonMarcoActivo) [ CCColorActivo orange 193]                            
        set ::GidPriv(Color,ToolbarBg) [ CCGetRGB . [ . cget -background]]                 
        set ::GidPriv(Color,CommandLineBg) #FFFFFF            
        set ::GidPriv(ToolbarBg) $::GidPriv(Color,ToolbarBg) ;#defined only for back compatibility (GiD-CEM3.0,etc)            
        set ::GidPriv(Original,Color,Background) [ . cget -background]
        set GidPriv(Original,Color,Foreground) [ . cget -foreground]
#         foreach col_idx {BotonActivo BotonMarcoActivo DisabledBackgroundEntry DisabledForegroundEntry BackgroundListbox \
#             DisabledForegroundMenu CommandLineBg ToolbarBg BackgroundFileDialog} {
#             set GidPriv(Original,Color,$col_idx) $GidPriv(Color,$col_idx)
#         }
        if { $::GidPriv(Configuration) == "debug" || $::tcl_platform(platform) != "windows" } {
            set ::GidPriv(CustomColor,ToolbarBg) \#e9d0d0
        } else {
            set ::GidPriv(CustomColor,ToolbarBg) $::GidPriv(Color,ToolbarBg)
        }        
        set ::GidPriv(Color,BackgroundListbox) #f5f5f5
        set ::GidPriv(Color,DisabledBackgroundEntry) #f5f5f5
        set ::GidPriv(Color,DisabledForegroundEntry) #000000
        set ::GidPriv(Color,DisabledForegroundMenu) #999999
        set ::GidPriv(Color,BackgroundFileDialog) #ffffff                                  
    }
    
    
    ########################
    #change from old look to new look
    ###############################
    #set newlook ![gid_themes::GetOnlyDefineColorsOnMainGiDFrame]        
    
    set BottomFrameInRed 0
    #set testcolors 1
    #testcolors == 1 => ttk::style theme use classicblue
    
    if { [gid_themes::GetOnlyDefineColorsOnMainGiDFrame] } {
        if { "clam" in [ttk::style theme names] } {
            ttk::style theme settings clam {
                ttk::style configure TButton -padding 1
                ttk::style configure TMenubutton -padding 1
                # ttk::style map Toolbutton -background "focus grey [ttk::style map Toolbutton -background]"
            }
        }
        
#         if { "xpnative" in [ttk::style theme names] } {
#             ttk::style theme settings xpnative {
#                 ttk::style map TMenubutton -background "focus grey [ttk::style map Toolbutton -background]"
#             }
#         }
        
    } else {
        ttk::style theme use [gid_themes::GetTtkTheme]
    }        
    set optionscolors [ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure IconButton]]    
    set forceddefinitions {{Vertical.ForcedScrollbar Vertical.TScrollbar} {Horizontal.ForcedScrollbar Horizontal.TScrollbar}
        {ForcedFrame TFrame} {ForcedSeparator TSeparator}
        {ForcedCombobox TCombobox} {ForcedLabel TLabel} {ForcedEntry TEntry}}    
    if { [gid_themes::GetTtkTheme] == "classicgid" } {
        set forceddefinitions {{Vertical.ForcedScrollbar Vertical.TScrollbar} {Horizontal.ForcedScrollbar Horizontal.TScrollbar}
            {ForcedFrame IconButton} {Horizontal.ForcedFrame Horizontal.IconButton} {Vertical.ForcedFrame Vertical.IconButton} {ForcedSeparator TSeparator}
            {ForcedCombobox TCombobox} {ForcedLabel IconButton} {Horizontal.ForcedLabel Horizontal.IconButton} {Vertical.ForcedLabel Vertical.IconButton} {ForcedEntry TEntry}}    
    }    
    set themetocopy [gid_themes::GetTtkTheme]        
    foreach th [ttk::style theme names] { 
        ttk::style theme settings $th {
            foreach pairforced $forceddefinitions {
                set forcedwidget [lindex $pairforced 0]
                set origwidget [lindex $pairforced 1]
                ttk::style layout $forcedwidget [ttk::style theme settings $themetocopy [list ttk::style layout $origwidget ]]
                set optionsorigwidget [ttk::style theme settings $themetocopy [list ttk::style configure $origwidget ]]
                foreach key [dict keys $optionscolors] { 
                    if { $key == "-foreground" && ($forcedwidget == "ForcedCombobox" || $forcedwidget == "ForcedEntry") } {
                        continue
                    }
                    dict set optionsorigwidget $key [dict get $optionscolors $key] 
                }
                ttk::style configure $forcedwidget {*}$optionsorigwidget 
                ttk::style map $forcedwidget {*}[ttk::style theme settings $themetocopy [list ttk::style map $origwidget ]]
            }
        }
    }
    if { [ttk::style theme use] != [gid_themes::GetTtkTheme] } {
        #for use a ttk theme form the system
        if {[gid_themes::GetTtkTheme] == "classicgid"} {
            ttk::style element create newgid.button from [gid_themes::GetTtkTheme]     
            ttk::style element create iconbutton.button from [gid_themes::GetTtkTheme]
            ttk::style element create horizontaliconbutton.button from [gid_themes::GetTtkTheme]
            ttk::style element create verticaliconbutton.button from [gid_themes::GetTtkTheme]
            ttk::style element create iconbuttonwithmenu.button from [gid_themes::GetTtkTheme]
            ttk::style element create horizontaliconbuttonwithmenu.button from [gid_themes::GetTtkTheme]
            ttk::style element create verticaliconbuttonwithmenu.button from [gid_themes::GetTtkTheme]
        } else {
            #clammod clmamodlight
            ttk::style element create IconButton.border from [gid_themes::GetTtkTheme]
            ttk::style element create Horizontal.IconButton.border from [gid_themes::GetTtkTheme]
            ttk::style element create Vertical.IconButton.border from [gid_themes::GetTtkTheme] 
            ttk::style element create IconButtonWithMenu.border from [gid_themes::GetTtkTheme] 
            ttk::style element create Horizontal.IconButtonWithMenu.border from [gid_themes::GetTtkTheme] 
            ttk::style element create Vertical.IconButtonWithMenu.border from [gid_themes::GetTtkTheme]    
        }
        foreach type { IconButton Horizontal.IconButton Vertical.IconButton 
            IconButtonWithMenu Horizontal.IconButtonWithMenu Vertical.IconButtonWithMenu } {
            ttk::style layout $type [ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style layout $type ]]
            ttk::style configure $type {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure $type ]] 
            ttk::style map $type {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style map $type ]]
        }
        ttk::style configure SeparatorToolbar.TFrame {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure SeparatorToolbar.TFrame ]]             
        if { [gid_themes::GetTtkTheme] == "classicgid" } {
            ttk::style element create FrameIconButton.border from [gid_themes::GetTtkTheme]
            ttk::style element create HorizontalFrameIconButton.border from [gid_themes::GetTtkTheme]
            ttk::style element create VerticalFrameIconButton.border from [gid_themes::GetTtkTheme]            
            ttk::style layout ForcedFrame { 
                FrameIconButton.border -sticky nswe
            }
            ttk::style configure ForcedFrame {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure IconButton ]]             
            ttk::style layout Horizontal.ForcedFrame { 
                HorizontalFrameIconButton.border -sticky nswe
            }
            ttk::style configure Horizontal.ForcedFrame {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure Horizontal.IconButton ]]             
            ttk::style layout Vertical.ForcedFrame { 
                VerticalFrameIconButton.border -sticky nswe
            }
            ttk::style configure Vertical.ForcedFrame {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure Vertical.IconButton ]] 
            
            ttk::style layout ForcedLabel {
                FrameIconButton.border -children {
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
            ttk::style configure ForcedLabel {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure IconButton ]]             
            ttk::style layout Horizontal.ForcedLabel {
                HorizontalFrameIconButton.border -children {
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
            ttk::style configure Horizontal.ForcedLabel {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure Horizontal.IconButton ]]             
            ttk::style layout Vertical.ForcedLabel {
                VerticalFrameIconButton.border -children {
                    Toolbutton.padding -children {
                        Toolbutton.label -side left -expand true                
                    }
                }
            }
            ttk::style configure Vertical.ForcedLabel {*}[ttk::style theme settings [gid_themes::GetTtkTheme] [list ttk::style configure Vertical.IconButton ]] 
            
        }  else {
            #clammod clmamodlight            
        }
        
    }        
    ttk::style configure TopMenu.IconButton -font TkDefaultFont -padding {6 0}
    ttk::style configure TopMenu.Horizontal.IconButton -font TkDefaultFont -padding {6 0}
    ttk::style configure TopMenu.Vertical.IconButton -font TkDefaultFont -padding {0 6}
    ttk::style configure RightButtons.IconButton -anchor w -padding {4 2}    
    #nicer color depending on theme its calculated on 
    #tclfile-opengl.tcl :  bind . <<ThemeChanged>>
    #caution don't change following value 
    set framebuttoncolor #fdfae9    
    set buttonoptions "-font TkDefaultFont -padding {4 2} -background $framebuttoncolor -focuscolor $framebuttoncolor"    
    if { "$::tcl_platform(os)" != "Darwin"} {
        # separate style of buttone between window ( upper part) and bottomFrame ( apply, close, ...)
        ttk::style configure Window.TButton {*}$buttonoptions -width -6
        ttk::style configure BottomFrame.TButton {*}$buttonoptions -width -10
        ttk::style configure BottomFrame.TFrame -background $framebuttoncolor -padding {8 12}
    } else { 
        # separate style of buttone between window ( upper part) and bottomFrame ( apply, close, ...)
        ttk::style configure WindowFrame.TButton {*}$buttonoptions -width -3
        ttk::style configure BottomFrame.TButton {*}$buttonoptions -width -5
        ttk::style configure BottomFrame.TFrame -background $framebuttoncolor -padding {12 24}
    }
    ttk::style configure "BottomFrame.TLabel" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TEntry" -background $framebuttoncolor 
    ttk::style configure "BottomFrame.TCheckbutton" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TCombobox" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TLabelframe" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TMenubutton" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TNotebook" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TPanedwindow" -background $framebuttoncolor
    ttk::style configure "BottomFrame.Horizontal.TProgressbar" -background $framebuttoncolor
    ttk::style configure "BottomFrame.Vertical.TProgressbar" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TRadiobutton" -background $framebuttoncolor
    ttk::style configure "BottomFrame.Horizontal.TScrollbar" -background $framebuttoncolor
    ttk::style configure "BottomFrame.Vertical.TScrollbar" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TSeparator" -background $framebuttoncolor
    ttk::style configure "BottomFrame.TSizegrip" -background $framebuttoncolor
    ttk::style configure "BottomFrame.Treeview" -background $framebuttoncolor
    
    #don't work well :ttk::style configure "BigFont.TLabel" -font BigFont
    # use instate -font BigFont
    
    ttk::style configure TLabelframe -labelanchor nw            
    ttk::style configure "flat.TFrame" -relief flat -borderwidth 0
    ttk::style configure "groove.TFrame" -relief groove -borderwidth 2 
    ttk::style configure "raised.TFrame" -relief raised -borderwidth 2 
    ttk::style configure "ridge.TFrame" -relief ridge -borderwidth 2 
    ttk::style configure "solid.TFrame" -relief solid -borderwidth 2
    ttk::style configure "sunken.TFrame" -relief sunken -borderwidth 2                                         
    
    
    #USEFUL THINKS
    #web resources:
    #        http://www.tkdocs.com/tutorial/styles.html
    #        http://tktable.sourceforge.net/tile/doc/converting.txt
    
    #ttk::style layout TButton
    #ttk::style layout TCheckbutton
    #ttk::style layout TCombobox
    #ttk::style layout TEntry
    #ttk::style layout TFrame
    #ttk::style layout TLabel
    #ttk::style layout TLabelframe
    #ttk::style layout TMenubutton
    #ttk::style layout TNotebook
    #ttk::style layout TPanedwindow
    #ttk::style layout Horizontal.TProgressbar
    #ttk::style layout Vertical.TProgressbar
    #ttk::style layout TRadiobutton
    #ttk::style layout Horizontal.TScrollbar
    #ttk::style layout Vertical.TScrollbar
    #ttk::style layout TSeparator
    #ttk::style layout TSizegrip
    #ttk::style layout Treeview
    #to inspect elements inside layout
    
    #ttk::style layout TButton
    #result in windows: Button.button -sticky nswe -children {Button.focus -sticky nswe -children {Button.padding -sticky nswe -children {Button.label -sticky nswe}}}
    #ttk::style element options Button.label
    #result:-compound -space -text -font -foreground -underline -width -anchor -justify -wraplength -embossed -image -stipple -background
    #ttk::style element options Button.padding
    #result:-padding -relief -shiftrelief
    #ttk::style element options Button.button
    #result: none
    #ttk::style element options Button.focus
    #result: none
    #in each theme the layout could be diferent and each element have diferent options
    #also in some themes some options could not have effect
    
    #STATES: active disabled focus pressed selected background readonly alternate invalid hover
    #-border padding: padding is a list of up to four integers, specifying the left, top, right, and bottom borders, respectively. See IMAGE STRETCHING, below. 
    #-height height: Specifies a minimum height for the element. If less than zero, the base image's height is used as a default. 
    #-padding padding: Specifies the element's interior padding. Defaults to -border if not specified. 
    #-sticky spec: Specifies how the image is placed within the final parcel. spec contains zero or more characters �n�, �s�, �w�, or �e�. 
    #-width width: Specifies a minimum width for the element. If less than zero, the base image's width is used as a default. 
    
    #    End configurating look
}


#read themes information from themes folders
proc gid_themes::ReadThemes { } {
    variable Themes
    if {  [GidUtils::IsTkDisabled] } {
        return
    }
    
    package require tdom
    
    array unset Themes
    set dir_themes [file join $::GIDDEFAULT themes]
    foreach dir_theme [glob -directory $dir_themes -types d *] {
        set xmlfile [file join $dir_theme configuration.xml]
        if { ![file exists $xmlfile] } {
            continue
        }
        set xml [tDOM::xmlReadFile $xmlfile]
        set document [dom parse $xml]
        set root [$document documentElement]
        
        if { [$root nodeName] != "GID_THEME" } {
            $document delete
            continue
        }
        set name [$root getAttribute name]
        lappend Themes(names) $name
        
        set Themes($name,folder) [file tail $dir_theme]
        foreach key {label version alternative_theme OnlyDefineColorsOnMainGiDFrame TtkTheme TkFromTheme TypeMenu PaddingWidgets
            BackgroundColor BackColorType BackColorTop BackColorBottom BackColorSense ColorPoints
            ColorNodes ColorLines ColorPolyLines ColorSurfaces ColorSurfsIsoparametric ColorVolumes
            ColorElements} {
            set domNode [$root selectNodes $key]
            if { $domNode != "" } {
                set Themes($name,$key) [$domNode text]
            }
        }
        
        set domGroupNodes [$root selectNodes SizeDefinitions]
        if {$domGroupNodes != ""} {
            foreach childNode [$domGroupNodes childNodes] {
                set SizeDefinition [$childNode getAttribute name]
                foreach key {label folder alternative_folder font} {
                    set domNode [$childNode selectNodes $key]
                    if { $domNode != "" } {
                        set Themes($name,SizeDefinition,$SizeDefinition,$key) [$domNode text]           
                    }                
                }
                
            }
        }
        set domGroupNodes [$root selectNodes ThemeSizes]
        set Themes($name,ThemeSizes) ""
        if {$domGroupNodes != ""} {           
            foreach childNode [$domGroupNodes childNodes] {
                set ThemeSize [$childNode getAttribute size]
                if { [string index $ThemeSize 0] == "+" } {
                    #avoid consider the + that prevent to store as integer and compare as string
                    set ThemeSize [string range $ThemeSize 1 end]
                }
                lappend Themes($name,ThemeSizes) $ThemeSize
                foreach childchildNode [$childNode childNodes] {
                    set Themes($name,IconCategories,$ThemeSize,[$childchildNode getAttribute name]) [$childchildNode text] 
                }
                foreach IconCategory {small_icons large_icons menu toolbar generic} {
                    if { ![info exists Themes($name,IconCategories,$ThemeSize,$IconCategory)] } {
                        set Themes($name,IconCategories,$ThemeSize,$IconCategory) ""
                    }
                }                    
            }
        }
        $document delete
    }        
}       

#read themes information from module themes folders
proc gid_themes::ReadModuleThemes { ModuleDir } {
    variable Themes
    variable IconCategories
    
    if {  [GidUtils::IsTkDisabled] } {
        return
    }
    array unset ::ModulePriv
    array unset ::ModulePrivImages
    
    set ::ModulePriv(path) $ModuleDir
    
    if { $ModuleDir != "" } {
        set ::ModulePriv(valid) 1
        
        set aux_module_themes(names) ""
        set dir_themes [file join $ModuleDir themes]
        
        if { [file exists $dir_themes] } {
            package require tdom
            foreach dir_theme [glob -directory $dir_themes -types d *] {
                set xmlfile [file join $dir_theme configuration.xml]
                if { ![file exists $xmlfile] } {
                    continue
                }
                set xml [tDOM::xmlReadFile $xmlfile]
                set document [dom parse $xml]
                set root [$document documentElement]
                
                if { !( [$root nodeName] == "GID_THEME" || [$root nodeName] == "MODULE_THEME" ) } {
                    $document delete
                    continue
                }
                set name [$root getAttribute name]
                lappend aux_module_themes(names) $name
                
                set aux_module_themes($name,folder) [file tail $dir_theme]
                foreach key {label version alternative_theme} {
                    set domNode [$root selectNodes $key]
                    if { $domNode != "" } {
                        set aux_module_themes($name,$key) [$domNode text]
                    }
                }
                
                set domGroupNodes [$root selectNodes SizeDefinitions]
                if {$domGroupNodes != ""} {
                    foreach childNode [$domGroupNodes childNodes] {
                        set SizeDefinition [$childNode getAttribute name]
                        foreach key {label folder alternative_folder font} {
                            set domNode [$childNode selectNodes $key]
                            if { $domNode != "" } {
                                set aux_module_themes($name,SizeDefinition,$SizeDefinition,$key) [$domNode text]           
                            }                
                        }
                        
                    }
                }
                set domGroupNodes [$root selectNodes ThemeSizes]
                set aux_module_themes($name,ThemeSizes) ""
                if {$domGroupNodes != ""} {
                    foreach childNode [$domGroupNodes childNodes] {
                        set ThemeSize [$childNode getAttribute size]
                        if { [string index $ThemeSize 0] == "+" } {
                            #avoid consider the + that prevent to store as integer and compare as string
                            set ThemeSize [string range $ThemeSize 1 end]
                        }
                        lappend aux_module_themes($name,ThemeSizes) $ThemeSize
                        foreach childchildNode [$childNode childNodes] {
                            set aux_module_themes($name,IconCategories,$ThemeSize,[$childchildNode getAttribute name]) [$childchildNode text] 
                        }
                        foreach IconCategory {small_icons large_icons menu toolbar generic} {
                            if { ![info exists aux_module_themes($name,IconCategories,$ThemeSize,$IconCategory)] } {
                                set aux_module_themes($name,IconCategories,$ThemeSize,$IconCategory) ""
                            }
                        }
                    }
                }                    
                $document delete        
            }
        }
        foreach name $Themes(names) {
            if { [lsearch $aux_module_themes(names) $name] != -1 } {
                set ::ModulePriv($name,valid) 1
                set theme_folder $aux_module_themes($name,folder)    
                foreach IconCategory $IconCategories {
                    foreach ThemeSize $aux_module_themes($name,ThemeSizes) {
                        set SizeDefinition $aux_module_themes($name,IconCategories,$ThemeSize,$IconCategory)
                        set size_folder [file join $theme_folder images]
                        if { [info exists aux_module_themes($name,SizeDefinition,$SizeDefinition,folder)] } {           
                            set size_folder [file join $theme_folder images $aux_module_themes($name,SizeDefinition,$SizeDefinition,folder)]
                        }                        
                        set ::ModulePriv($name,path,$ThemeSize,$IconCategory) [file join $ModuleDir themes $size_folder]                                                
                        set size_folder_alternative ""
                        if { [info exists aux_module_themes($name,alternative_theme)] } {
                            set size_folder_alternative [file join $aux_module_themes($name,alternative_theme) images]
                        }
                        if { [info exists aux_module_themes($name,SizeDefinition,$SizeDefinition,alternative_folder)] } {
                            set size_folder_alternative $aux_module_themes($name,SizeDefinition,$SizeDefinition,alternative_folder)            
                        }
                        if { $size_folder_alternative != "" } {
                            set ::ModulesPriv($name,path_alternative,$ThemeSize,$IconCategory) [file join $ModuleDir themes $size_folder_alternative]
                        }
                    }
                }
            } else {
                set ::ModulePriv($name,valid) 0
            }
        }
    } else {
        foreach name $Themes(names) {
            set ::ModulePriv($name,valid) 0 
        }
    }
    return 0
}

proc gid_themes::GetThemes { } {
    variable Themes
    if { ![info exists Themes(names)] } {
        return ""
    }
    return $Themes(names)
}

proc gid_themes::GetThemesAndLabels { } {
    variable Themes
    if { ![info exists Themes(names)] } {
        return ""
    }
    set returnlist ""
    foreach theme $Themes(names) {
        lappend returnlist $theme [set Themes($theme,label)]
    }
    return $returnlist
}

proc gid_themes::SetNextRestartTheme { name } {
    if { $name == [gid_themes::GetCurrentTheme] } {
        if { [info exists ::GidPriv(NextRestartTheme)] } {
            unset ::GidPriv(NextRestartTheme)                
        }
    }
    set ::GidPriv(NextRestartTheme) $name        
}

proc gid_themes::GetNextRestartTheme { } {
    if { ![info exists ::GidPriv(NextRestartTheme)] } {
        return [gid_themes::GetCurrentTheme]
    }
    return $::GidPriv(NextRestartTheme)    
}

proc gid_themes::GetDefaultTheme { } {
    set possible_themes [gid_themes::GetThemes]
    if { [lsearch $possible_themes GiD_black] != -1 } {
        set default_theme GiD_black
    } else {
        #take into account the possibility that our themes are removed to be replaced by others
        set default_theme [lindex $possible_themes 0]            
    }
    return $default_theme
}

proc gid_themes::GetCurrentTheme { } {
    if { ![info exists ::GidPriv(CurrentTheme)] } {
        return ""
    }
    return $::GidPriv(CurrentTheme)
}

#set ::GidPriv(CurrentTheme) name, and path and possible path_alternative for each icon category
proc gid_themes::SetCurrentTheme { name } {
    variable IconCategories
    variable Themes
    
    global GidPriv        
    if { [gid_themes::GetCurrentTheme] == $name } {
        return 0
    }
    
    if { [lsearch [gid_themes::GetThemes] $name] == -1 } {            
        return 1
    }                
    
    set ::GidPriv(CurrentTheme) $name
    set theme_folder $Themes($name,folder)    
    
    foreach IconCategory $IconCategories {
        foreach ThemeSize $Themes($name,ThemeSizes) {
            set SizeDefinition $Themes($name,IconCategories,$ThemeSize,$IconCategory)
            set size_folder [file join $theme_folder images]
            if { [info exists Themes($name,SizeDefinition,$SizeDefinition,folder)] } {           
                set size_folder [file join $theme_folder images $Themes($name,SizeDefinition,$SizeDefinition,folder)]
            }
            set ::GidPriv(CurrentTheme,path,$ThemeSize,$IconCategory) [file join $::GIDDEFAULT themes $size_folder]        
            
            set size_folder_alternative ""
            if { [info exists Themes($name,alternative_theme)] } {
                set size_folder_alternative [file join $Themes($name,alternative_theme) images]
            }
            if { [info exists Themes($name,SizeDefinition,$SizeDefinition,alternative_folder)] } {
                set size_folder_alternative $Themes($name,SizeDefinition,$SizeDefinition,alternative_folder)            
            }
            if { $size_folder_alternative != "" } {
                set ::GidPriv(CurrentTheme,path_alternative,$ThemeSize,$IconCategory) [file join $::GIDDEFAULT themes $size_folder_alternative]
            }                
        }
    }        
        
    if { [lsearch $Themes($name,ThemeSizes) [GiD_Set Theme(Size)]] == -1 } {
        GiD_Set Theme(Size) [lindex $Themes($name,ThemeSizes) [expr [llength $Themes($name,ThemeSizes)] / 2]]
    }
    GUI_UpdateImages
    return 0
}

proc gid_themes::SetCurrentThemeColors { name } {             
    variable Themes
    #the same is done in tclfileP when NextRestartTheme is set
    foreach key {BackgroundColor BackColorType BackColorTop BackColorBottom BackColorSense ColorPoints
        ColorNodes ColorLines ColorPolyLines ColorSurfaces ColorSurfsIsoparametric ColorVolumes ColorElements} {
        GiD_Set $key [set Themes($name,$key)]
    }
}

#Things to check for correct working
# DONE:
#  The image its in all looks
#  If it ask for a size, it have to be in booth sizes
# NOT DONE:
#  Inside a size folder all images have the same size at least the same width or the same height
#  All images .png
#  If in root look folder there is a image the same size as in size folder, its almost sure an error    
proc gid_themes::CheckThemes {} {        
    package require BWidget
    variable Themes
    
    proc openfile { dir } { 
        package require gid_cross_platform   
        gid_cross_platform::open_by_extension $dir                       
    }
    
    proc howmanydifferences { listdir } {
        set allimagesfull ""
        foreach imgdir $listdir {
            if { [catch {append allimagesfull " [glob -directory $imgdir *.*]"} err] } {
                WarnWinText "Error reading $imgdir ($err)"
            }
        }
        set allimages ""
        foreach file $allimagesfull {
            lappend allimages [file tail $file]
        }
        set allimagesfull ""
        set allimages [lsort -dictionary $allimages]
        #all images must be the same number of times as number of listdir
        
        set previmg ""
        set counterror 0
        set numdir [llength $listdir]
        set numberoftime $numdir
        foreach img $allimages {
            if { $img != $previmg } {
                if {$numberoftime != $numdir } {
                    set counterror [expr $counterror+1]
                }
                set previmg $img
                set numberoftime 1
            } else {
                set numberoftime [expr $numberoftime+1]
            }
        }
        return $counterror                                        
    }
    
    proc compareimages { listdir } {
        set i 0
        while { [winfo exists .infoimages$i] } { incr i } 
        
        toplevel .infoimages$i                        
        set sw [ScrolledWindow .infoimages$i.sw]
        
        pack $sw -fill both -expand true
        
        set sf [ScrollableFrame $sw.sf]
        
        $sw setwidget $sf
        
        set uf [$sf getframe]
        
        #sorting list
        set allimagesfull ""
        foreach imgdir $listdir {
            append allimagesfull " [glob -directory $imgdir *.*]"
        }
        set allimages ""
        foreach file $allimagesfull {
            lappend allimages [file tail $file]
        }
        set allimagesfull ""
        set allimages [lsort -dictionary $allimages]
        #titles of columns
        set numcolumn 1
        foreach imgdir $listdir {
            set nm [format "%s.b_%s_%s" $uf $numcolumn "Title"]
            
            set splitimgdir [file split $imgdir]
            set theme [lindex $splitimgdir [expr [lsearch $splitimgdir themes]+1]]
            set folder [file tail [file rootname $imgdir]]
            
            set b [label $nm -text "theme:$theme\nfolder:$folder" -font BigFont ]
            grid $b -row 1 -column $numcolumn
            
            if {$theme=="GiD_black"} {
                set background($numcolumn) #292929
                set foreground($numcolumn) #c2c5ca
            } else {
                set background($numcolumn) #f0f0f0
                set foreground($numcolumn) #000000
            }                
            set numcolumn [expr $numcolumn+1]
        }
        #images
        set previmg ""
        set numrow 2
        
        foreach img $allimages {
            if { $img != $previmg } {
                set previmg $img
                set numcolumn 1
                foreach imgdir $listdir {
                    set file [file join $imgdir $img]
                    regsub -all {\.} $img {_} imgname
                    
                    set nm [format "%s.b_%s_%s" $uf $numcolumn [string tolower $imgname]]
                    
                    if { [catch {set I($imgname) [ gid_themes::ImageCreatePhoto $file]}] } {
                        set b [label $nm -text $img -background #ff0000]
                    } else {                                                
                        set b [tk::button $nm -image $I($imgname) -text $img -compound left \
                                -command {} -background $background($numcolumn) \
                                -foreground $foreground($numcolumn) -borderwidth 4 -relief flat]
                    }
                    
                    grid $b -row $numrow -column $numcolumn -sticky nwes
                    
                    set numcolumn [expr $numcolumn+1]
                }
                set numrow [expr $numrow+1]
            }
        }
        return 0 
    }
    
    
    toplevel .askwhattocompare -takefocus 1
    set possiblethemes [gid_themes::GetThemes]
    foreach name $possiblethemes {
        lappend basefolderfiles [file join $::GIDDEFAULT themes $Themes($name,folder) images]
        lappend smallfolderfiles [file join $::GIDDEFAULT themes $Themes($name,folder) images $Themes($name,SizeDefinition,$Themes($name,IconCategories,0,small_icons),folder)]
        lappend largefolderfiles [file join $::GIDDEFAULT themes $Themes($name,folder) images $Themes($name,SizeDefinition,$Themes($name,IconCategories,0,large_icons),folder)]
        
        set allsizesfiles ""
        foreach sizedef [ array names Themes $name,SizeDefinition,* ] {
            if { [regexp ",folder" $sizedef] } {
                lappend allsizesfiles [file join $::GIDDEFAULT themes $Themes($name,folder) images $Themes($sizedef)]
            }
        }
            button .askwhattocompare.sizesintheme$name \
            -text "Compare Sizes in theme $name (Number of errors [howmanydifferences $allsizesfiles])" -command "gid_themes::compareimages [list $allsizesfiles]"
            grid .askwhattocompare.sizesintheme$name -columnspan 3
    }        
    label .askwhattocompare.label -text "Between themes:"        
    button .askwhattocompare.basediffthemes \
        -text "Compare base dir (Number of errors [howmanydifferences $basefolderfiles])" -command "gid_themes::compareimages [list $basefolderfiles]"
    
    button .askwhattocompare.smalldiffthemes \
        -text "Compare small_icons dir (Number of errors [howmanydifferences $smallfolderfiles])" -command "gid_themes::compareimages [list $smallfolderfiles]"
    
    button .askwhattocompare.largediffthemes \
        -text "Compare large_icons dir (Number of errors [howmanydifferences $largefolderfiles])" -command "gid_themes::compareimages [list $largefolderfiles]"
    
    grid .askwhattocompare.label -columnspan 3 
    grid .askwhattocompare.basediffthemes .askwhattocompare.smalldiffthemes .askwhattocompare.largediffthemes                
}


#relative images are expected to be inside the GiD images folder, else must provide a full path
#Look decision its defined outside
#Empty class implies images inside root look folder
#To select sizes there are 4 options, forced small: small_icons, forced large: large_icons, menu and toolbar => Automatic size decision

#Things to check for correct working
#  Not accept full path or partial path pointing to GiD image folder 
proc gid_themes::LoadImage { filename {IconCategory "generic"}} {
    variable IconCategories
    
    set return_img ""
    set fullname ""
    set msg_alternative ""
    
    if { [llength [file split $filename]] == 1 } {
        set auxthemesize [GiD_Set Theme(Size)]
        if { [info exists ::GidPriv(CurrentTheme,path,$auxthemesize,$IconCategory)] } { 
            set fullname [file join $::GidPriv(CurrentTheme,path,$auxthemesize,$IconCategory) $filename]
        } else {
            set fullname $filename
        }
    } elseif { [file pathtype $filename] == "absolute" } {
        set fullname $filename
    } else {
        #relative to GiD working directory        
        set fullname [file join $::GIDDEFAULT $filename]           
    }        
    #Inteligence gid_themes::GetImage: Search the image asked for, if not search alternative if not, find inside bitmaps else return the imagenotfound.png"
    
    set fail 0
    if { [catch {set return_img [ gid_themes::ImageCreatePhoto $fullname]} msg] } {
        set auxthemesize [GiD_Set Theme(Size)]
        if { [info exists ::GidPriv(CurrentTheme,path_alternative,$auxthemesize,$IconCategory)] } {          
            set alternativefullname [file join $::GidPriv(CurrentTheme,path_alternative,$auxthemesize,$IconCategory) $filename]     
            if { [catch {set return_img [ gid_themes::ImageCreatePhoto $alternativefullname]} msg2] } {
                set fail 1
                set alternativefullname2 [file join $::GIDDEFAULT bitmaps $filename]
                if { [catch {set return_img [ gid_themes::ImageCreatePhoto $alternativefullname2]} msg3] } {
                    #try finding in other categories
                    set found_other_category 0
                    foreach category $IconCategories {
                        if { $category != $IconCategory } {
                            set alternativefullname3 [file join $::GidPriv(CurrentTheme,path,$auxthemesize,$category) $filename]
                            if { ![catch {set return_img [ gid_themes::ImageCreatePhoto $alternativefullname3]} msg4] } {
                                set msg_alternative "bad categoy $IconCategory, used $category. $alternativefullname3 instead."
                                set found_other_category 1
                                break
                            }                                
                        }                            
                    }
                    if { !$found_other_category } {
                        ## set return_img [gid_themes::GetImage erase-cross.png small_icons]
                        ## set msg_alternative  "'erase-cross.png' used instead."
                        set return_img [ gid_themes::GetImageNoImage]
                        set msg_alternative  "internal 'NoImage' used instead."
                    }
                    
                } else {      
                    set msg_alternative "'$alternativefullname2' used instead."
                }
            } else {
                set msg_alternative "'$alternativefullname' used instead."
            }
        } else {
            set msg_alternative "may be gid_themes package has not been initialized ?"
            set fail 1
        }
    }
    # elseif { $::tcl_platform(os) == "Darwin" && $IconCategory!="generic" }
    if { $::tcl_platform(os) == "Darwin" } {
        if {  $IconCategory!="generic" } {
            #Some MACs suport transparency so beter disabled
            #Mac do not support parcial tranparency, not optimal solution, but better than nothing
            SetBackgroundToAlphaPixels $return_img [set ::ttk::theme::[::gid_themes::GetTtkTheme]::colors(-toolbars_bg)]
        }
    }
    if { $fail } {
        if { $::gid_themes_get_image_mode == "debug" } {            
            WarnWinText "Could not find image $filename ('$fullname') (IconCategory=$IconCategory), $msg_alternative"                        
            for { set i [info level]} { $i >0 } { incr i -1 } {
                WarnWinText [info level $i]
            }
            WarnWinText "( To check themes correctness \"-np- gid_themes::CheckThemes\" )"
        } else {
        }
    }
    
    if { $return_img == ""} {
        catch {
            set return_img [ gid_themes::GetImageNoImage]
        } msg5
    }
    return $return_img
}

proc gid_themes::GetImage { filename {IconCategory "generic"} {Owner "gid"}} {
    variable IconCategories
    
    if { $Owner != "gid" } {
        return [gid_themes::GetImageModule $filename $IconCategory]
    }
    
    if { $::gid_themes_get_image_mode == "debug" } {                        
        if { [lsearch $IconCategories $IconCategory] == -1 } {
            WarnWinText [_ "Error, IconCategory %s not found. Valid names are %s" $IconCategory $IconCategories]
            set IconCategory "generic"
        }
    }   
    
    if { ![info exists ::GidPrivImages($IconCategory,$filename)] } {
        set ::GidPrivImages($IconCategory,$filename) [ gid_themes::LoadImage $filename $IconCategory]
    }
    return [ gid_themes::HighResolutionImage $::GidPrivImages($IconCategory,$filename)]
}

proc gid_themes::GetImageModule { filename {IconCategory "generic"} } {        
    variable IconCategories
    
    if { ![info exists ::ModulePrivImages($IconCategory,$filename)] } {    
        if { $::ModulePriv($::GidPriv(CurrentTheme),valid) } {            
            if { [llength [file split $filename]] == 1 } {
                set fullname [file join $::ModulePriv($::GidPriv(CurrentTheme),path,$IconCategory) $filename]
            } elseif { [file pathtype $filename] == "absolute" } {
                set fullname $filename
            } else {
                #relative to GiD working directory        
                set fullname [file join $::ModulePriv(path) $filename]           
            }
            #Inteligence gid_themes::GetImageModule: Search the image asked for, using ModulePrivImages and ModulePriv variables
            #if not found inside module it uses gid_themes::GetImage instate.
            set fail 0
            if { [catch {set ::ModulePrivImages($IconCategory,$filename) [ gid_themes::ImageCreatePhoto $fullname]} msg] } {
                if { [info exists ::ModulePriv($::GidPriv(CurrentTheme),path_alternative,$IconCategory)] } {          
                    set alternativefullname [file join $::ModulePriv($::GidPriv(CurrentTheme),path_alternative,$IconCategory) $filename]     
                    if { [catch {set ::ModulePrivImages($IconCategory,$filename) [ gid_themes::ImageCreatePhoto $alternativefullname]} msg2] } {
                        set fail 1
                        set found_other_category 0
                        foreach category $IconCategories {
                            if { $category != $IconCategory } {
                                set alternativefullname3 [file join $::ModulePriv($::GidPriv(CurrentTheme),path,$category) $filename]
                                if { ![catch {set ::ModulePrivImages($IconCategory,$filename) [ gid_themes::ImageCreatePhoto $alternativefullname3]} msg3] } {                                    
                                    set msg_alternative "bad categoy $IconCategory, used $category. $alternativefullname3"
                                    set found_other_category 1
                                    break
                                }                                
                            }                            
                        }
                        if { !$found_other_category } {
                            set ::ModulePrivImages($IconCategory,$filename) [gid_themes::GetImage $filename $IconCategory ]
                            set msg_alternative  "used [gid_themes::GetImage $filename $IconCategory ] instate"
                        }                        
                    } else {                        
                        set msg_alternative $alternativefullname
                    }
                } else {
                    set ::ModulePrivImages($IconCategory,$filename) [gid_themes::GetImage $filename $IconCategory ]
                }
            }
        } else {
            set ::ModulePrivImages($IconCategory,$filename) [gid_themes::GetImage $filename $IconCategory ]
        }
    }
    # return [gid_themes::HighResolutionImageModule $::ModulePrivImages($IconCategory,$filename)]
    # image already scaled by gid_themes::GetImage
    return $::ModulePrivImages($IconCategory,$filename)
}

proc gid_themes::ResizeImage { img factor } {
    set width [expr [image width $img]*$factor]
    set height [expr [image height $img]*$factor]
    set new_img [GidUtils::ResizeImage $img $width $height]
    return $new_img
}

#test, worst image quality than GidUtils::ResizeImage algorithm (that use img_zoom with Lanczos3)
proc gid_themes::ResizeImage2 { img factor } {
    set new_img [image create photo]
    $new_img copy $img -zoom $factor
    return $new_img
}

proc gid_themes::HighResolutionImage { img } {
    set factor [GiD_Set Theme(HighResolutionScaleFactor)]
    # factor must be an integer
    if { $factor == 1} {
        return $img
    }        
    if { [info exists ::GidPrivImages(HiRes,$factor,$img)]} {
        set new_img $::GidPrivImages(HiRes,$factor,$img)
    } else {
        set new_img [gid_themes::ResizeImage $img $factor]   
        set ::GidPrivImages(HiRes,$factor,$img) $new_img
    }
    return $new_img
}

proc gid_themes::HighResolutionImageModule { img } {
    set factor [GiD_Set Theme(HighResolutionScaleFactor)]    
    # factor must be an integer
    if { $factor == 1} {
        return $img
    }        
    if { [info exists ::ModulePrivImages(HiRes,$factor,$img)]} {
        set new_img $::ModulePrivImages(HiRes,$factor,$img)
    } else {
        set new_img [gid_themes::ResizeImage $img $factor]   
        set ::ModulePrivImages(HiRes,$factor,$img) $new_img
    }
    return $new_img
}

proc gid_themes::GetImageSize { IconCategory  } {         
    if { [lsearch {"small_icons" "large_icons" "menu" "toolbar"} $IconCategory] == -1 } {
        return 0
    }
    set img [gid_themes::GetImage blank_horizontal.png $IconCategory]
    return [image width $img]
}

#to force to rebuild the image
proc gid_themes::ResetCacheImage { filename {IconCategory "generic"} } {        
    if { [info exists ::GidPrivImages($IconCategory,$filename)] } {
        image delete $::GidPrivImages($IconCategory,$filename)
        array unset ::GidPrivImages($IconCategory,$filename)        
    }
}

#------------------------------------------------------------------------------
# tablelist::newgidTheme
# declare this procedure here instead to do it inside the tablelist package
# to easily update this third part package without need to modify the standard package
# with this feature that has only sense for themed GiD
#------------------------------------------------------------------------------
namespace eval tablelist {}
proc tablelist::newgidTheme {} {
    variable themeDefaults
    
    array set colors {
        -toolbars_bg "#282829"
        -frame_bg "#b1b4b9"        
        -text_bg "#c2c5ca"
        -text_fg "#000000"
        -colortext_fg "#000000"
        -select_fg "#000000"
        -disabled_fg "#5d5d5d"
        -highlight "#63a5b5"
    }
    
    array set themeDefaults [list \
            -background              $colors(-text_bg) \
            -foreground              $colors(-colortext_fg) \
            -disabledforeground      $colors(-disabled_fg) \
            -stripebackground        "" \
            -selectbackground        $colors(-highlight) \
            -selectforeground        $colors(-select_fg) \
            -selectborderwidth       0 \
            -font                    TkTextFont \
            -labelbackground         $colors(-frame_bg) \
            -labeldisabledBg         $colors(-frame_bg) \
            -labelactiveBg           $colors(-highlight) \
            -labelpressedBg          $colors(-highlight) \
            -labelforeground         $colors(-colortext_fg) \
            -labeldisabledFg         $colors(-disabled_fg) \
            -labelactiveFg           $colors(-colortext_fg) \
            -labelpressedFg          $colors(-colortext_fg) \
            -labelfont               TkDefaultFont \
            -labelborderwidth        0 \
            -labelpady               1 \
            -arrowcolor              "" \
            -arrowstyle              flat8x5 \
            -treestyle               winnative \
            ]
}


#--------- back compatibility
#for back compatibility define also GetImage
proc GetImage { filename } {
    return [gid_themes::GetImage $filename]
}

#for back compatibility (ramseries 5.9.5) define also imagefrom
proc imagefrom { filename } {
    return [gid_themes::GetImage $filename]
}
#--------- end back compatibility



#--------- test

# proc calculate_color { r g b tolerance_abs tolerance_rel invertafter} {
#     set colorini {0 157 183}
#     #orig
#     #set colorfin {0 157 183}
#     
#     #invert (orange)
#     #set colorfin {255 98 72}
#     
#     #green click2cast 
#     #set colorfin {106 232 0}
#     #green click2cast web
#     #set colorfin {83 224 0}
#     
#     #pink
#     set colorfin {255 0 132}
#     
#     #dark red
#     #set colorfin {192 6 6}
#     #red
#     #set colorfin {255 0 0}
#     
#     set rgb [format "#%02x%02x%02x" $r $g $b]
#     
#     set rini [lindex $colorini 0]
#     set gini [lindex $colorini 1]
#     set bini [lindex $colorini 2]
#     
#     set rfin [lindex $colorfin 0]
#     set gfin [lindex $colorfin 1]
#     set bfin [lindex $colorfin 2]
#     
#     #if k goes from -1 to 1 we cover from black to white conversion
#     
#     if { [expr abs(255- $r) ] < $tolerance_abs } {
#         set rmultwhite 0
#     } else {
#         set rmultwhite [expr ($r-256)*1.0/($rini- 256)*1.0 ]
#     }
#     if { [expr abs(255- $g) ] < $tolerance_abs } {
#         set gmultwhite 0
#     } else {
#         set gmultwhite [expr ($g-256)*1.0/($gini- 256)*1.0 ]
#     }
#     if { [expr abs(255- $b) ] < $tolerance_abs } {
#         set bmultwhite 0
#     } else {
#         set bmultwhite [expr ($b-256)*1.0/($bini- 256)*1.0 ]
#     }
#     
#     set multwhite [expr ($rmultwhite+$bmultwhite+$gmultwhite) / 3.0 ]
#     if { $multwhite == 0 } {
#         set multwhite [expr ([expr ($r-256)*1.0/($rini- 256)*1.0 ]+[expr ($g-256)*1.0/($gini- 256)*1.0 ]+[expr ($b-256)*1.0/($bini- 256)*1.0 ])/3.0]
#     }
#     
#     if { [expr abs(0- $r) ] < $tolerance_abs } {
#         set rmultblack 0
#     } else {
#         set rmultblack [expr ($r+1)*1.0/($rini+1)*1.0 ]
#     }
#     if { [expr abs(0- $g) ] < $tolerance_abs } {
#         set gmultblack 0
#     } else {
#         set gmultblack [expr ($g+1)*1.0/($gini+1)*1.0 ]
#     }
#     if { [expr abs(0- $b) ] < $tolerance_abs } {
#         set bmultblack 0
#     } else {
#         set bmultblack [expr ($b+1)*1.0/($bini+1)*1.0 ]
#     }
#     
#     set multblack [expr ($rmultblack+$bmultblack+$gmultblack) / 3.0 ]
#     if { $multblack == 0 } {
#         set multblack  [expr ([expr ($r+1)*1.0/($rini+1)*1.0 ]+[expr ($g+1)*1.0/($gini+1)*1.0 ]+[expr ($b+1)*1.0/($bini+1)*1.0 ]) / 3.0]
#     }
#     
#     set maxdistwhite 0
#     
#     set dist [expr abs($multwhite-$rmultwhite)]
#     if { $dist > $maxdistwhite } {
#         set maxdistwhite $dist
#     }
#     
#     set dist [expr abs($multwhite-$gmultwhite)]
#     if { $dist > $maxdistwhite } {
#         set maxdistwhite $dist
#     }
#     
#     set dist [expr abs($multwhite-$bmultwhite)]
#     if { $dist > $maxdistwhite } {
#         set maxdistwhite $dist
#     }
#     
#     set maxdistblack 0
#     
#     set dist [expr abs($multblack-$rmultblack)]
#     if { $dist > $maxdistblack } {
#         set maxdistblack $dist
#     }
#     
#     set dist [expr abs($multblack-$gmultblack)]
#     if { $dist > $maxdistblack } {
#         set maxdistblack $dist
#     }
#     
#     set dist [expr abs($multblack-$bmultblack)]
#     if { $dist > $maxdistblack } {
#         set maxdistblack $dist
#     }
#     
#     if { $maxdistwhite < $maxdistblack } {
#         if { $maxdistwhite < $tolerance_rel } {
#             set r [expr int(( $multwhite)*$rfin + (1.0 - $multwhite)*256)]
#             if { $r < 0 } { set r 0 }
#             if { $r > 255 } { set r 255 }
#             set g [expr int(( $multwhite)*$gfin + ( 1.0 - $multwhite)*256)]
#             if { $g < 0 } { set g 0 }
#             if { $g > 255 } { set g 255 }
#             
#             set b [expr int((  $multwhite)*$bfin + (1.0 - $multwhite)*256)]
#             if { $b < 0 } { set b 0 }
#             if { $b > 255 } { set b 255 }
#             
#             
#             set rgb [format "#%02x%02x%02x" $r $g $b]
#         } elseif {$invertafter == 1} {
#             set rgb [invert_color $r $g $b]
#         }
#     } else {        
#         if { $maxdistblack < $tolerance_rel } {
#             set r [expr int(( $multblack)*$rfin + (1.0 - $multblack)*(-1))]
#             if { $r < 0 } { set r 0 }
#             if { $r > 255 } { set r 255 }
#             set g [expr int(( $multblack)*$gfin + ( 1.0 - $multblack)*(-1))]
#             if { $g < 0 } { set g 0 }
#             if { $g > 255 } { set g 255 }
#             
#             set b [expr int((  $multblack)*$bfin + (1.0 - $multblack)*(-1))]
#             if { $b < 0 } { set b 0 }
#             if { $b > 255 } { set b 255 }
#             
#             
#             set rgb [format "#%02x%02x%02x" $r $g $b]
#             
#         } elseif {$invertafter == 1} {
#             set rgb [invert_color $r $g $b]
#         } 
#     }   
#     return $rgb
# }
# 
# proc invert_color { r g b } {
#     set r [expr 255-$r]
#     set g [expr 255-$g]
#     set b [expr 255-$b]
#     set rgb [format "#%02x%02x%02x" $r $g $b]
#     return $rgb
# }
# 
# proc change_color { img } {       
#     for {set x 0} {$x < [image width $img]} {incr x 1} { 
#         for {set y 0} {$y < [image height $img]} {incr y 1} { 
#             set color [$img get $x $y]
#             set string [$img data -from $x $y [expr $x+1] [expr $y+1] -background #292929 ]
#             scan [lindex $string 0] "#%2x%2x%2x" r g b
#             
#             set tolerance_abs 20
#             set tolerance_rel 0.5
#             set invertafter 0
#             set rgb [calculate_color $r $g $b $tolerance_abs $tolerance_rel $invertafter]
#             
#             set alpha [$img transparency get $x $y]
#             $img put $rgb -to $x $y  
#             $img transparency set $x $y $alpha
#         }
#     }
# }


# proc Time_changeBorder {} {
#     set ::countexecutions 0
#     proc do_max_min_window { { times 1} } {
#         for { set i 0} { $i < $times} { incr i} {
#             wm attributes .gid -fullscreen 1
#             update
#             wm attributes .gid -fullscreen 0
#             update   
#         }
#     }
#     proc changeborder { border } {
#         namespace eval ttk::theme::clammod {} 
#         set padding 2
#         
#         
#         ttk::style element create ${::countexecutions}IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
#                 pressed        $ttk::theme::clammod::I(iconbutton-p) \
#                 active        $ttk::theme::clammod::I(iconbutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ews 
#         #left, top, right, and bottom
#         ttk::style element create Horizontal.${::countexecutions}IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
#                 pressed        $ttk::theme::clammod::I(iconbutton-p) \
#                 active        $ttk::theme::clammod::I(iconbutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ews
#         ttk::style element create Vertical.${::countexecutions}IconButton.border image [list $ttk::theme::clammod::I(iconbutton-n) \
#                 pressed        $ttk::theme::clammod::I(iconbutton-p) \
#                 active        $ttk::theme::clammod::I(iconbutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ens
#         
#         ttk::style element create ${::countexecutions}IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
#                 pressed        $ttk::theme::clammod::I(tmenubutton-p) \
#                 active        $ttk::theme::clammod::I(tmenubutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ews 
#         ttk::style element create Horizontal.${::countexecutions}IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
#                 pressed        $ttk::theme::clammod::I(tmenubutton-p) \
#                 active        $ttk::theme::clammod::I(tmenubutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ews
#         ttk::style element create Vertical.${::countexecutions}IconButtonWithMenu.border image [list $ttk::theme::clammod::I(tmenubutton-n) \
#                 pressed        $ttk::theme::clammod::I(tmenubutton-p) \
#                 active        $ttk::theme::clammod::I(tmenubutton-h) \
#                 ] -border $border -padding [expr $padding*2+1] -sticky ens
#         
#         eval [subst {ttk::style layout IconButton {            
#                     ${::countexecutions}IconButton.border -sticky nswe -children {
#                         IconButton.padding -sticky nswe -children {
#                             IconButton.label -sticky nswe
#                         }
#                     }      
#                 } } ]       
#         eval [subst {ttk::style layout Horizontal.IconButton {            
#                     Horizontal.${::countexecutions}IconButton.border -sticky nswe -children {
#                         IconButton.padding -sticky nswe -children {
#                             IconButton.label -sticky nswe
#                         }
#                     }            
#                 } } ]      
#         eval [subst {ttk::style layout Vertical.IconButton {            
#                     Vertical.${::countexecutions}IconButton.border -sticky nswe -children {
#                         IconButton.padding -sticky nswe -children {
#                             IconButton.label -sticky nswe
#                         }
#                     }           
#                 } } ]      
#         
#         eval [subst {ttk::style layout IconButtonWithMenu {            
#                     ${::countexecutions}IconButtonWithMenu.border -sticky nswe -children {
#                         IconButtonWithMenu.padding -sticky nswe -children {
#                             IconButtonWithMenu.label -sticky nswe
#                         }
#                     }      
#                 }  } ]             
#         eval [subst {ttk::style layout Horizontal.IconButtonWithMenu {            
#                     Horizontal.${::countexecutions}IconButtonWithMenu.border -sticky nswe -children {
#                         IconButtonWithMenu.padding -sticky nswe -children {
#                             IconButtonWithMenu.label -sticky nswe
#                         }
#                     }            
#                 } } ]             
#         eval [subst {ttk::style layout Vertical.IconButtonWithMenu {            
#                     Vertical.${::countexecutions}IconButtonWithMenu.border -sticky nswe -children {
#                         IconButtonWithMenu.padding -sticky nswe -children {
#                             IconButtonWithMenu.label -sticky nswe
#                         }
#                     }           
#                 } } ]      
#         
#         update  
#         incr ::countexecutions
#     }
#     set num_iter 10
#     
#     
#     for {set i 0} {$i<=7} {incr i} {
#         for {set j 0} {$j<=9} {incr j} {
#             set border [list $i $j]
#             changeborder $border
#             after 2000
#             
#             set total [ lindex [ time "do_max_min_window $num_iter"] 0]
#             
#             set time_per_max_min [ expr $total * 1e-6 / double( $num_iter)]
#             
#             WarnWinText "border:$border time:$time_per_max_min"
#         }
#     }
# }


#--------- end test

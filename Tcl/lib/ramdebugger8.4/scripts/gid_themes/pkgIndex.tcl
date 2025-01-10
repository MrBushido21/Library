
# needed ::gamma_value in both no_gid_theme and gid_theme

if { $::tcl_platform(os) == "Darwin"} {
    # it seems that Mac OS X reads the image somewhat lighter than in windows and linux
    set ::gamma_value 0.87
} else {
    # this is the default gamma value
    set ::gamma_value 1.0
}

proc LoadLibrary_gid_themes { dir basename } {
    if { ![ info exists ::GIDDEFAULT ] || ( [ info exists ::DO_NOT_USE_GID_THEMES ] && $::DO_NOT_USE_GID_THEMES) } {
        # defined in gid_themes.tcl:
        #    variable IconCategories {"generic" "small_icons" "large_icons" "menu" "toolbar"}
        set lst_categories [ list "generic" "small_icons" "large_icons" "menu" "toolbar" ]
        set lst_folders [ list images images/small_size(16andmore) images/size_32 images/small_size(16andmore) images/large_size(24andmore) ]
        foreach IconCategory $lst_categories img_dir $lst_folders {
            if { ![ info exists ::GidPriv(no_gid_theme,$IconCategory) ]} {
                # define one by default
                set ::GidPriv(no_gid_theme,$IconCategory) [ file join $dir .. .. themes GiD_classic $img_dir ]
            }
        }
        source [ file join $dir do_not_use_gid_themes.tcl ]
    } else {
        source [ file join $dir gid_themes.tcl ]
    }
    package provide gid_themes 1.1
}

package ifneeded gid_themes 1.1 [ list LoadLibrary_gid_themes $dir gid_themes ]

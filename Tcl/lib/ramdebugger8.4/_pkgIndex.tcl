
set Version 8.4

proc LoadRamDebugger { dir version } {
    if { [info exists ::GIDDEFAULT] } {
        GidUtils::WaitState
    }
    set argv_local ""
    if { [interp exists ramdebugger] } {
        if { [ramdebugger eval info exists ::argv] } {
            set argv_local [ramdebugger eval set ::argv]
        }
        interp delete ramdebugger
    }
    #     interp create ramdebugger
    if { ![interp exists ramdebugger] } {
        interp create ramdebugger
    }
    interp alias ramdebugger master "" eval
    if { [info exists ::GIDDEFAULT] } {
        #loaded inside GiD
        foreach i { _  } {
            interp alias ramdebugger $i "" $i
        }
    }
    
    ramdebugger eval [list load {} Tk]
    ramdebugger eval package require Tk
    if { ![ramdebugger eval info exists ::argv] } {
        set argc_local [llength $argv_local]
        ramdebugger eval [list set ::argc $argc_local]
        ramdebugger eval [list set ::argv $argv_local]
    }
    ramdebugger eval [list set ::is_package 1]
    ramdebugger eval [list set ::auto_path $::auto_path]
    ramdebugger eval [list set ::argv0 [file join $dir RamDebugger.tcl]]

    # pass gid fonts to Ramdebugger
    # NormalFont in Ramdebugger is used for menus and windows
    ramdebugger eval [list font create NormalFont {*}[ font configure TkDefaultFont]]
    ramdebugger eval [list font create FixedFont {*}[ font configure TkFixedFont]]

    # define path to current theme images
    # defined in gid_themes.tcl:
    #    variable IconCategories {"generic" "small_icons" "large_icons" "menu" "toolbar"}
    set lst_categories [ list "generic" "small_icons" "large_icons" "menu" "toolbar" ]
    set lst_folders [ list images images/small_size(16andmore) images/size_32 images/small_size(16andmore) images/large_size(24andmore) ]
    set auxthemesize [GiD_Set Theme(Size)]
    foreach IconCategory $lst_categories img_dir $lst_folders {
        if { [ info exists ::GidPriv(CurrentTheme,path,$auxthemesize,$IconCategory)] } {
            set img_dir $::GidPriv(CurrentTheme,path,$auxthemesize,$IconCategory)
        } else {
            # define one by default
            set img_dir [ file join $::GIDDEFAULT themes GiD_classic $img_dir ]
        }
        ramdebugger eval [ list set ::GidPriv(no_gid_theme,$IconCategory) $img_dir ]
    }

    catch { ramdebugger hide exit }
    ramdebugger alias exit EndLoadRamDebugger
    ramdebugger eval [list source [file join $dir RamDebugger.tcl]]
    package provide RamDebugger $version
    update idletasks
    if { [info exists ::GIDDEFAULT] } {
        GidUtils::EndWaitState
    }
}

proc EndLoadRamDebugger {} {
    interp delete ramdebugger
    package forget RamDebugger
    #some important procs were redefined starting and stopping ramdebugger, must restore then
    #rename ::info ::RDC::infoproc
    #rename ::source ::RDC::sourceproc
    #rename ::exit ::exit_final
    #rename ::bgerror ::RDC::bgerror_base
    #rename ::puts ::RDC::puts_base
    
    if { [info procs ::RDC::bgerror_base] != "" } {
        rename ::bgerror {}
        rename ::RDC::bgerror_base ::bgerror
    }    
    if { [info procs ::RDC::sourceproc] != "" } {
        rename ::source {}
        rename ::RDC::sourceproc ::source
    }
}

if {![package vsatisfies [package provide Tcl] 8.4]} {return}
package ifneeded RamDebugger $Version [list LoadRamDebugger $dir $Version]

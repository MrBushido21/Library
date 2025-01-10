
package require Tk 
package require BWidget
package require fileutil
package require htmlparse
package require struct::stack
package require gid_themes
set ::tkhtml_version [package require Tkhtml]

package require no_gid

namespace eval GiDHistory {
    variable list
    variable pos
    variable menu
    
    proc Init { w menu } {
        variable list
        variable pos
        variable menu
        
        set list($w) ""
        set pos($w) -1
        set menu($w) $menu
    }
    
    proc Add { w name } {
        variable list
        variable pos
        variable menu
        
        lappend list($w) $name
        set pos($w) [expr [llength $list($w)]-1]
        if { $pos($w) == 0 } {
            if { [info exists menu($w)] && [winfo exists $menu($w)] } {
                $menu($w) entryconf Backward -state disabled
            }
        } else {
            if { [info exists menu($w)] && [winfo exists $menu($w)] } {
                $menu($w) entryconf Backward -state normal
            }
        }
        if { [info exists menu($w)] && [winfo exists $menu($w)] } {
            $menu($w) entryconf Forward -state disabled
        }
    }
    proc GoHome { w } {
        variable list
        variable pos
        variable menu
        
        set pos($w) 0
        if { [info exists menu($w)] && [winfo exists $menu($w)] } {
            $menu($w) entryconf Backward -state disabled
        }
        if { [info exists menu($w)] && [winfo exists $menu($w)] } {
            $menu($w) entryconf Forward -state normal
        }
        GiDHelpViewer::LoadRef $w [lindex $list($w) $pos($w)] 0
    }
    proc GoBackward { w } {
        variable list
        variable pos
        variable menu
        
        incr pos($w) -1
        if { $pos($w) == 0 } {
            if { [info exists menu($w)] && [winfo exists $menu($w)] } {
                $menu($w) entryconf Backward -state disabled
            }
        }
        if { [info exists menu($w)] && [winfo exists $menu($w)] } {
            $menu($w) entryconf Forward -state normal
        }
        GiDHelpViewer::LoadRef $w [lindex $list($w) $pos($w)] 0
    }
    proc GoForward { w } {
        variable list
        variable pos
        variable menu
        
        if { $pos($w) >= [expr [llength $list($w)]-1] } {
            bell
            return
        }
        incr pos($w) 1
        if { $pos($w) == [expr [llength $list($w)]-1] } {
            if { [info exists menu($w)] && [winfo exists $menu($w)] } {
                $menu($w) entryconf Forward -state disabled
            }
        }
        if { [info exists menu($w)] && [winfo exists $menu($w)] } {
            $menu($w) entryconf Backward -state normal
        }
        GiDHelpViewer::LoadRef $w [lindex $list($w) $pos($w)] 0
    }
}

namespace eval GiDHelpViewer {    
    variable HelpBaseDir
    variable LastFileList
    variable images
    variable waiting
    variable html
    variable local_images_dir
    set local_images_dir [file join [file dirname [info script]] images]
}

proc GiDHelpViewer::xml { args } {
    set map [list > "&gt;" < "&lt;" & "&amp;" \" "&quot;" ' "&apos;"]
    return [string map $map [join $args ""]]
}

proc GiDHelpViewer::xml_inv { args } {
    set map [list "&gt;" > "&lt;" < "&amp;" & "&quot;" \" "&apos;" ']
    return [string map $map [join $args ""]]
}

proc GiDHelpViewer::double_quote_to_simple_quote { text } {
    return [string map {\" '} $text]
}

proc GiDHelpViewer::conf_cursor {w c} {
    if { $::tkhtml_version >= 3 && [winfo class $w] == "Html"} {
        [winfo parent [winfo parent $w]] configure -cursor $c    
    } else {
        $w configure -cursor $c
    }
}

proc GiDHelpViewer::Init { w } {
    # variables de tipo array
    variable LastFileList
    variable Index
    variable FindWordInFileCache
    variable TitleCache
    variable IndexInfo
    # variables de tipo list
    variable indexlist1
    variable indexlist2
    variable indexstring
    variable searchstring
    variable IndexFilesTitles
    variable SearchFound
    variable SearchFound2
    variable SearchFound2data
    # otros tipos
    variable waiting
    variable searchmode
    variable searchcase
    variable searchFromBegin
    variable SearchType
    variable data
    variable html           
    
    foreach varr {LastFileList Index IndexInfo FindWordInFileCache TitleCache} {
        array unset $varr ${w},*
    }
    set IndexInfo($w,pages) ""
    foreach vlarr {indexlist1 indexlist2 indexstring searchstring \
        IndexFilesTitles SearchFound SearchFound2 \
        SearchFound2data} {
        set ${vlarr}($w) ""
    }
    set waiting($w) 0
    set searchmode($w) -exact
    set searchcase($w) 0
    set searchFromBegin($w) 0
    set SearchType($w) -forwards
    set data($w,sync) 0
    set hmtl(style_count) 0
}

proc GiDHelpViewer::GetImage { filename {IconCategory "generic"} } {
    if { ![info exists ::GIDDEFAULT] || ( [info exists ::DO_NOT_USE_GID_THEMES] && $::DO_NOT_USE_GID_THEMES)} {
        variable PrivImages
        if { [info exists PrivImages($IconCategory,$filename)] } {
            set img $PrivImages($IconCategory,$filename)
        } else {
            if { [info exists ::gamma_value] } {
               set gamma $::gamma_value
            } else {
                if { $::tcl_platform(os) == "Darwin"} {
                    # it seems that Mac OS X reads the image somewhat lighter than in windows and linux
                    set gamma 0.87
                } else {
                    # this is the default gamma value
                    set gamma 1.0
                }
            }                       
            variable local_images_dir
            set fullname [file join $local_images_dir $filename]          
	    set extra_opts ""
	    if { [ string tolower [ file extension $filename]] == ".png" } {
		set extra_opts [ list -format "png -gamma $gamma"]
	    }
            set err_img [catch {set PrivImages($IconCategory,$filename) [ image create photo -file $fullname -gamma $gamma {*}$extra_opts] } err]
            if { $err_img } {              
                set img [gid_themes::GetImageNoImage]
            } else {
                set img $PrivImages($IconCategory,$filename)
            }
        }        
    } else {         
        set img [gid_themes::GetImage $filename $IconCategory]
    }
    return $img
}

proc GiDHelpViewer::GiveLastFile { w } {
    variable LastFileList
    set retval ""
    catch {
        set w [winfo toplevel $w]
        set retval $LastFileList($w)
    }
    return $retval
}

proc GiDHelpViewer::EnterLastFile { w file } {
    variable LastFileList
    set w [winfo toplevel $w]
    set LastFileList($w) $file
}

#A font chooser routine.
#  $base.h.h config -fontcommand PickFont2
proc GiDHelpViewer::PickFont2 {size attrs} {
    global tcl_platform
    
    if { [lsearch [font names] HelpFont] != -1 } {
        set family [font configure HelpFont -family]
        set fsize [font configure HelpFont -size]
    } else {
        set family Helvetica
        switch $::tcl_platform(platform) {
            windows { set fsize 11 }
            default { set fsize 15 }
        }
    }
    
    set a [expr {-1<[lsearch $attrs fixed]?{Courier}:"$family"}]    
    set b [expr {-1<[lsearch $attrs italic]?{italic}:{roman}}]
    set c [expr {-1<[lsearch $attrs bold]?{bold}:{normal}}]
    set d [expr int($fsize*pow(1.2,$size-4))]    
    list $a $d $b $c
}

# This routine is called for each form element
proc GiDHelpViewer::FormCmd2 {n cmd args} {
    switch $cmd {
        select -
        textarea -
        input {
            set w [lindex $args 0]
            ttk::label $w -image nogifsm
        }
    }
}

#command for tkhtml 2.x
proc GiDHelpViewer::ImageCmd2 { args } {   
    lassign $args full_filename width
    set name_splitted [file split $full_filename]
    if { [lindex $name_splitted 0] == "." } {
        set name_splitted [lrange $name_splitted 1 end]
    }
    set full_filename [file join {*}$name_splitted]
    if { [file dirname $full_filename] == "." } {
        set full_filename [file tail $full_filename]
    }
    return [GiDHelpViewer::GetHtmlImage $full_filename $width]
}

proc GiDHelpViewer::GetHtmlImage { full_filename width } {
    global Images
    if {[info exists Images($full_filename)]} {
        return $Images($full_filename)
    }
    if {[catch {image create photo -file $full_filename} img]} {
        set img [gid_themes::GetImageNoImage]
    } else {
        if { [info commands img_zoom] != "" } {
            if { [string is integer -strict $width] && $width != [image width $img] } {          
                set height [expr {int([image height $img]*$width/[image width $img])}]
                set img_old $img
                set img [image create photo -width $width -height $height]
                img_zoom $img $img_old Lanczos3
                image delete $img_old
            }
        }
    }
    set Images($full_filename) $img
    return $img
}

proc GiDHelpViewer::SelectionClear { w } {   
    variable html
    if { $::tkhtml_version >= 3 } {       
        $html($w) tag delete selection
        $html($w) tag configure selection -background #4091fd -foreground white
        set html($w,selection_fromNode) ""
        set html($w,selection_toNode) "" 
        #GiDHelpViewer::SearchInPageClear $w
        if { $::tkhtml_version >= 3 } {     
            catch {$html($w) tag delete searchcurrent}
        }
    } else {
        $html($w) selection clear
    }  
}

proc GiDHelpViewer::SearchInPageClear { w } { 
    variable html  
    variable SearchPos    
    if { $::tkhtml_version >= 3 } {     
        catch {$html($w) tag delete searchcurrent}
        catch {$html($w) tag delete search}
    }
    set SearchPos($w) ""   
}

#command for tkhtml 3.x
proc GiDHelpViewer::ImageCmd3 { w relative_name } {   
    variable LastFileList    
    set dir_name [file dirname $LastFileList($w)]
    set full_filename [file join $dir_name $relative_name] 
    return [GiDHelpViewer::GetHtmlImage $full_filename ""]   
}

proc GiDHelpViewer::StyleScriptHandler3 { w attributes script } {
    variable html    
#     array set attributes $attributes
#     if {[info exists attributes(media)]} {
#         if {0 == [regexp all|screen $attributes(media)]} {
#             return ""
#         }
#     }
# 
     set id author.[format %.4d [incr html(style_count)]]
#     set importcmd [list $w Requeststyle $id]
#     set urlcmd [list $w resolve_uri]
     append id ".9999.<style>"
#     $html($w)) style -id $id -importcmd $importcmd -urlcmd $urlcmd -errorvar parse_errors $script
    $html($w) style -id $id $script    
    return ""
}

proc GiDHelpViewer::ImgHandler3 { w html_nodes } { 
    variable LastFileList    
    set dir_name [file dirname $LastFileList($w)]
    foreach html_node $html_nodes {
        set relative_name [$html_node attribute src]
        set width [$html_node attribute -default "" width]        
        #to create cached images with possible information of its final size to resize them
        set full_filename [file join $dir_name $relative_name] 
        GiDHelpViewer::GetHtmlImage $full_filename $width
    }       
    return ""
}

proc GiDHelpViewer::HrefHandler3 { w html_nodes } {  
    foreach html_node $html_nodes {
        set href [$html_node attribute -default "" href]
        W "href=$href"
    }       
    return ""
}

# This routine is called for every <SCRIPT> markup
#
proc GiDHelpViewer::ScriptCmd2 {args} {
    # puts "ScriptCmd: $args"
}

# This routine is called for every <APPLET> markup
#
proc GiDHelpViewer::AppletCmd2 {w arglist} {
    # puts "AppletCmd: w=$w arglist=$arglist"
}

# This procedure is called when the user clicks on a hyperlink.
# See the "bind $base.h.h.x" below for the binding that invokes this
# procedure
#
proc GiDHelpViewer::HrefBinding2 {w x y} {    
    variable html    
    #focus $html($w)
    set new [$html($w) href $x $y]
    if { $new == "" } {
        return
    }
    catch {
        if { [llength $new] == 1 } {
            set new [lindex $new 0]
            if { [llength $new] == 1 } {
                set new [lindex $new 0]
            }
        }
    }
    LoadRef $w $new
}

proc GiDHelpViewer::HrefBinding3 {w x y} {    
    variable html
    variable FillInfo
    set node [lindex [$html($w) node $x $y] end]
    if { $node == "" } {
        return
    }
    set parent_node [$node parent]
    if { $parent_node == "" } {
        return
    }
    if { [$parent_node tag] == "a"} {   
        set href [$parent_node attribute -default "" href]
        if { $href != "" } {
            set full_filename [file join $FillInfo($w,dir) $href]
            LoadRef $w $full_filename
        }
    }   
}

proc GiDHelpViewer::LoadRef { w new { enterinhistory 1 } } {
    global tcl_platform
    variable html
    
    GiDHelpViewer::WaitState $w 1
    
    #must continue doing this trick if { $::tkhtml_version >= 3 } ??
    if { $new != "" && [regexp {([a-zA-Z]+[a-zA-Z]:.*$)} $new url] } {
        #regexp {[^/\\]*:.*} $new url
        if { [regexp {:/[^/]} $url] } {
            regsub {:/} $url {://} url
        }
        #more dark tricks for GiD html's
        if { [string range $url end-10 end] == "\}\} \{_blank\}" } {
            set url [string range $url 0 end-11]
        }
        
        package require gid_cross_platform   
        gid_cross_platform::open_by_extension $url

        GiDHelpViewer::WaitState $w 0
        return
    }
    
    if {$new!=""} {
        set LastFile [GiDHelpViewer::GiveLastFile $w]
        if { [string match \#* [file tail $new]] } {
            set new $LastFile[file tail $new]
        }
        set pattern $LastFile#
        set len [string length $pattern]
        incr len -1
        if {[string range $new 0 $len]==$pattern} {
            incr len
            set tag [string range $new $len end]
            GiDHelpViewer::YViewTag $w $tag
            if { $enterinhistory } {
                GiDHistory::Add $w $new
            }
        } elseif { [regexp {(.*)\#(.*)} $new {} file tag] } {
            GiDHelpViewer::LoadFile $w $file $enterinhistory $tag
        } else {
            GiDHelpViewer::LoadFile $w $new $enterinhistory
        }
    }
    GiDHelpViewer::WaitState $w 0
}

proc GiDHelpViewer::Load { w } {
    global lastDir
    set f [MessageBoxGetFilename file read [_ "Load html"] \
            "" [[list [_ "Html file"] ".html .htm"] [list [_ "All files"] ".*"]] .htm 0]
    
    
    if { $f != "" } {
        GiDHelpViewer::LoadFile $w $f
        set lastDir [file dirname $f]
    }
}

# Clear the screen.
#
# Clear the screen.
#
proc GiDHelpViewer::Clear { w } {
    variable html
    global Images hotkey
    
    if { $::tkhtml_version >= 3 } {
        $html($w) reset
        if { 0 } {
            set id agent.[format %.4d [incr html(style_count)]].9999.<style>
            set style {
                p { text-align:justify; }
                body { font-family: Verdana, Arial, Helvetica, Geneva; font-size 8px; }
                a { text-decoration:underline; }
                pre { font-family:Courier New, Courier, Mono; }
                h1 { font-family:Arial; font-size: 28; font-weight: bold; color:DarkBlue; }
                h2 { font-family:Arial; font-size: 24; font-weight: bold; color:DarkBlue; }
                h3 { font-family:Arial; font-size: 22; font-weight: bold; color:DarkBlue; }
                h4 { font-family:Arial; font-size: 18; font-weight: bold; color:DarkBlue; }
                h4 { font-family:Arial; font-size: 18; font-weight: bold; color:DarkBlue; }
                h4 { font-family:Arial; font-size: 18; font-weight: bold; color:DarkBlue; }
                P { text-align:justify; font-family:Arial, Helvetica, sans-serif; font-size: 17; }
                code { font-family:Courier New, Courier, Mono; font-size: 16; }
                li { text-align:justify; font-family:Arial, Helvetica, sans-serif; font-size: 17; margin-top: 7px; }
                ol { text-align:justify; font-family:Arial, Helvetica, sans-serif; font-size: 17; margin-top: 7px; }
                ul { text-align:justify; font-family:Arial, Helvetica, sans-serif; font-size: 17; margin-top: 7px; }
            }
            $html($w) style -id $id $style
        }            
    } else {
        $html($w) clear
    }
    catch {unset hotkey}   
    #it is necessary to delete explicitly images??
    array unset Images
}


# Read a file
#
proc GiDHelpViewer::ReadFile {name} {
    if { [file dirname $name] == "." } {
        set name [file tail $name]
    }
    if {[catch {set fp [open $name r]} msg]} {
        WarnWin $msg
        return {}
    } else {
        #fconfigure $fp -translation binary
        set r [read $fp]
        close $fp
        if { [regexp {(?i)<meta\s+[^>]*charset=utf-8[^>]*>} $r] } {
            set fp [open $name r]
            fconfigure $fp -encoding utf-8
            set r [read $fp]
            close $fp
        }
        #some libTkHtml.dll (like the current with 220Kb) show incorrecty this letter,
        #and other dll's like ActiveState 8.4.9.0 or 8.5.0.0 crash
        regsub -all {\u00E9} $r {\&eacute;} r
        return $r
    }
}

proc GiDHelpViewer::YViewTag { w tag } {
    variable html
    if { $tag != "" } {
        update idletasks
        if { $::tkhtml_version >= 3 } {
            #GiDHelpViewer::double_quote_to_simple_quote to avoid crash with a selector like
            #a[name="INTRODUCTION "hola mundo""]
            #replace it by
            #a[name="INTRODUCTION 'hola mundo'"]
            set selector [format {a[name="%s"]} [GiDHelpViewer::double_quote_to_simple_quote [GiDHelpViewer::xml_inv $tag]]]
            set goto_node [lindex [$html($w) search $selector] 0]
            if { $goto_node ne "" } {
                #this show a wrong position in some cases (with other <a href="xx"> nodes on the same page)
                $html($w) yview $goto_node                                                
            }
        } else {
            $html($w) yview [GiDHelpViewer::double_quote_to_simple_quote [GiDHelpViewer::xml_inv $tag]]
        }
    }
    return 0
}

# Load a file into the HTML widget
#
proc GiDHelpViewer::LoadFile {w name { enterinhistory 1 } { tag "" } } {
    global HelpPriv
    variable html
    variable data
    
    if { $name == "" } { 
        return 
    }
    
    GiDHelpViewer::WaitState $w 1
    
    if { [file isdirectory $name] } {
        set files [glob -dir $name *]
        set ipos [lsearch -regexp $files {(?i)(index|contents|_toc)\.(htm|html)}]
        if { $ipos != -1 } {
            set name [lindex $files $ipos]
        } else {
            GiDHelpViewer::WaitState $w 0
            return
        }
    }
    
    if {[GiDHelpViewer::GiveLastFile $w] eq $name} {
        if { $enterinhistory } {
            if { $tag == "" } {
                GiDHistory::Add $w $name
            } else {
                GiDHistory::Add $w $name#$tag
                GiDHelpViewer::YViewTag $w $tag
            }
        }
    } else {
        # it is a unreaded file
        set htmlcont [GiDHelpViewer::ReadFile $name]
        if { $htmlcont=="" } {
            GiDHelpViewer::WaitState $w 0
            return
        }
        GiDHelpViewer::Clear $w
        GiDHelpViewer::EnterLastFile $w $name
        
        if { $::tkhtml_version >= 3 } {

        } else {
            $html($w) configure -base $name            
        }
        if { $enterinhistory } {
            if { $tag == "" } {
                GiDHistory::Add $w $name
            } else {
                GiDHistory::Add $w $name#$tag
            }
        }
        GiDHelpViewer::SelectionClear $w    
        if { $::tkhtml_version >= 3 } {
            $html($w) parse -final $htmlcont                       
            update idletasks ;#update needed after parse, else using Search (e.g. GiD_Mesh) the showed page is not updated
        } else {
            $html($w) parse $htmlcont
        }
        GiDHelpViewer::YViewTag $w $tag
        if {$data($w,sync)} {
            #GiDHelpViewer::TryToSelect $w $name
            GiDHelpViewer::SyncContents $w $name
            set data($w,sync) 0
        }
    }
    GiDHelpViewer::SearchInPageClear $w       

    GiDHelpViewer::WaitState $w 0
}

proc GiDHelpViewer::GiveManHelpNames { word } {
    
    return ""
    
    if { [auto_execok man2html] == "" } { return "" }
    
    set err [catch { exec man -aw $word } file]
    if { $err } { return "" }
    
    set words ""
    foreach i [split $file \n] {
        set ext [string trimleft [file ext $i] .]
        if { $ext == "gz" } { set ext [string trimleft [file ext [file root $i]] .] }
        if { [lsearch $words "$word (man $ext)"] == -1 } {
            lappend words "$word (man $ext)"
        }
    }
    return $words
}

proc GiDHelpViewer::SearchManHelpFor { w word { mansection "" } } {
    variable html
    
    if { $mansection == "" } {
        regexp {(\S*)\s+\(man\s+(.*)\)} $word {} word mansection
    }
    
    set err [catch { exec man -aw $word } file]
    if { $err } { return }
    
    set files [split $file \n]
    
    if { [llength $files] > 1 } {
        set found 0
        foreach i $files {
            set ext [string trimleft [file ext $i] .]
            if { $ext == "gz" } { set ext [string trimleft [file ext [file root $i]] .] }
            if { $mansection == $ext } {
                set found 1
                set file $i
                break
            }
        }
        if { !$found } { 
            set file [lindex $files 0] 
        }
    } else { 
        set file [lindex $files 0]
    }
    
    if { [file ext $file] == ".gz" } {
        set comm [list exec gunzip -c $file | man2html]
    } else { 
        set comm [list exec man2html $file] 
    }
    
    set err [catch { eval $comm } htmlcont]
    
    GiDHelpViewer::Clear $w    
    GiDHelpViewer::SelectionClear $w

    $html($w) parse $htmlcont
    GiDHelpViewer::SearchInPageClear $w
}

# Refresh the current file.
#
proc GiDHelpViewer::Refresh {w args} {
    set LastFile [GiDHelpViewer::GiveLastFile $w]
    if {![info exists LastFile] || ![winfo exists $w] } return
    GiDHelpViewer::LoadFile $w $LastFile 0
}

proc GiDHelpViewer::ResolveUri2 { args } {
    return [file join [file dirname [lindex $args 0]] [lindex $args 1]]
}

proc GiDHelpViewer::BindPrior2 { w } {
    $w yview scroll -1 pages
}

proc GiDHelpViewer::BindNext2 { w } {
    $w yview scroll 1 pages    
}

proc GiDHelpViewer::BindUp2 { w } {
    $w yview scroll -1 units
}

proc GiDHelpViewer::BindDown2 { w } {
    $w yview scroll 1 units
}

proc GiDHelpViewer::BindHome2 { w } {
    $w yview moveto 0.0   
}

proc GiDHelpViewer::BindEnd2 { w } {
    $w yview moveto 1.0
}

proc GiDHelpViewer::MouseWheel { w d x y } {
    set parent [winfo parent $w]
    if {(([winfo class $w] == "Canvas") && ([winfo class $parent] == "Tree")) ||
        (([winfo class $w] == "HtmlClip" || [winfo class $w] == "") && ([winfo class $parent] == "Html")) } {
        $parent yview scroll $d units
    } elseif { [winfo class $w] == "Html" } {
        $w yview scroll $d units
    }
}

proc GiDHelpViewer::ManageSel2 { w W x y type } {
    global HelpPriv tcl_platform
    variable html    
    if { ![winfo exists $W] } { 
        return 
    }
    if { [winfo parent $W] != $html($w) } { 
        return 
    }    
    if { [info exists HelpPriv(lastafter)] } {
        after cancel $HelpPriv(lastafter)
    }
    
    switch -glob $type {
        press {
            update idletasks
            GiDHelpViewer::SelectionClear $w
            set idx [$html($w) index @$x,$y]
            if { $idx == "" } { return }
            $html($w) insert $idx
            $html($w) selection set $idx $idx
        }
        motion* {
            if { $type == "motion" } {
                set ini [$html($w) index insert]
                if { $ini == "" } {
                    GiDHelpViewer::SelectionClear $w
                } else {
                    set idx [$html($w) index @$x,$y]
                    if { $idx <= $ini } {
                        $html($w) selection set $idx $ini
                    } else {
                        $html($w) selection set $ini $idx
                    }
                }
            }
            set isout 0
            if { $x > [winfo width $html($w)] } {
                $html($w) xview scroll 1 units
                set isout 1
            } elseif { $x <0 } {
                $html($w) xview scroll -1 units
                set isout 1
            }
            if { $y > [winfo height $html($w)] } {
                $html($w) yview scroll 1 units
                set isout 1
            } elseif { $y <0 } {
                $html($w) yview scroll -1 units
                set isout 1
            }
            if { $isout } {
                set HelpPriv(lastafter) [after 100 GiDHelpViewer::ManageSel2 $w $W $x $y motionout]
            }
        }
        release {
            #set ini [$htmlw index sel.first]
            set ini [$html($w) index insert]
            if { $ini == "" } {
                GiDHelpViewer::SelectionClear $w
                return
            }
            set idx [$html($w) index @$x,$y]
            if { $idx == $ini } {
                GiDHelpViewer::SelectionClear $w              
            } else {
                if { $idx <= $ini } {
                    $html($w) selection set $idx $ini
                } else {
                    $html($w) selection set $ini $idx
                }                
            }
            if { $::tcl_platform(platform) != "windows"} {
                selection own -command [list GiDHelpViewer::LooseSelection $w] $html($w)
            }
        }
    }
}

#select the word with double-click
proc GiDHelpViewer::DoublePress { w x y } {
    variable html
    if { ![winfo exists $html($w)] } { 
        return 
    }    
    set html($w,selection_mode) word
    GiDHelpViewer::SelectionClear $w
    lassign [$html($w) node -index $x $y] node idx
    set t [$node text]
    set cidx [::tkhtml::charoffset $t $idx]
    set cidx1 [string wordstart $t $cidx]
    set cidx2 [string wordend $t $cidx]
    set idx1 [::tkhtml::byteoffset $t $cidx1]
    set idx2 [::tkhtml::byteoffset $t $cidx2]
    set html($w,selection_fromNode) [list $node $idx1]
    set html($w,selection_toNode) [list $node $idx2]
    $html($w) tag add selection $node $idx1 $node $idx2
}

proc GiDHelpViewer::ManageSel3 { w x y type } {
    global HelpPriv tcl_platform
    variable html    
    if { ![winfo exists $html($w)] } {
        return 
    }    
    focus $html($w)
    if { [info exists HelpPriv(lastafter)] } {
        after cancel $HelpPriv(lastafter)
    }
    
    switch -glob $type {
        press {          
            update idletasks
            GiDHelpViewer::SelectionClear $w
            set idx [$html($w) node -index $x $y]
            if { $idx != "" } {
                set html($w,selection_fromNode) $idx
                set html($w,selection_toNode) $idx
                $html($w) tag add selection {*}$idx {*}$idx
            }
        }
        motion* {
            if { $type == "motion" } {
                set ini $html($w,selection_fromNode)
                if { $ini == "" } {
                    GiDHelpViewer::SelectionClear $w                    
                } else {
                    set idx [$html($w) node -index $x $y]
                    if { $idx != "" } {                    
                        set html($w,selection_toNode) $idx
                        $html($w) tag delete selection
                        $html($w) tag configure selection -background #4091fd -foreground white
                        $html($w) tag add selection {*}$ini {*}$idx
                    } else {
                    }
                }
            }
            set isout 0
            if { $x > [winfo width $html($w)] } {
                $html($w) xview scroll 1 units
                set isout 1
            } elseif { $x <0 } {
                $html($w) xview scroll -1 units
                set isout 1
            }
            if { $y > [winfo height $html($w)] } {
                $html($w) yview scroll 1 units
                set isout 1
            } elseif { $y <0 } {
                $html($w) yview scroll -1 units
                set isout 1
            }
            if { $isout } {
                set HelpPriv(lastafter) [after 100 GiDHelpViewer::ManageSel3 $w $x $y motionout]
            }
        }
        release {
            if { $html($w,selection_mode) == "word" } {
                set html($w,selection_mode) ""                
            } else {
                set ini $html($w,selection_fromNode)
                if { $ini == "" } {
                    GiDHelpViewer::SelectionClear $w
                } else {
                    set idx [$html($w) node -index $x $y]
                    if { $idx != "" } {  
                        if { $idx == $ini } {
                            GiDHelpViewer::SelectionClear $w              
                        } else {
                            set html($w,selection_toNode) $idx
                            $html($w) tag add selection {*}$ini {*}$idx
                        }           
                    } else {
                    }
                }
            }
        }
    }
}

proc GiDHelpViewer::HtmlMotion2 { W x y } {        
    set parent [winfo parent $W]
    set url [$parent href $x $y]
    if {[string length $url] > 0} {
        $parent configure -cursor hand2
    } else {
        $parent configure -cursor {}
    }
}

proc GiDHelpViewer::HtmlMotion3 { W x y } {
    set node [lindex [$W node $x $y] end]
    if { $node == "" } {
        return
    }
    set parent_node [$node parent]
    if { $parent_node == "" } {
        return
    }
    if { [$parent_node tag] == "a"} {
        set href [$parent_node attribute -default "" href]
    } else {
        set href ""
    }
    if { $href != "" } {
        [winfo toplevel $W] configure -cursor hand2
    } else {
        [winfo toplevel $W] configure -cursor {}
    }
}

proc GiDHelpViewer::LooseSelection { w } {
    GiDHelpViewer::SelectionClear $w
}

proc GiDHelpViewer::CopySelected { w { offset 0 } { maxBytes 0} } {
    global tcl_platform
    variable html
    
    if { $::tkhtml_version >= 3 } {
        set ini $html($w,selection_fromNode)
        set end $html($w,selection_toNode)
        if { $ini == "" || $end == "" } { 
            return 
        }
        set ini_offset [$html($w) text offset {*}$ini]
        set end_offset [$html($w) text offset {*}$end]
        if { $ini_offset > $end_offset } {
            set tmp $ini_offset
            set ini_offset $end_offset
            set end_offset $tmp
        }
        set contents [$html($w) text text]
        set rettext [string range $contents $ini_offset $end_offset-1]
        #it seems that the html widget is replacing each single \n by two \n\n, at least in code, invert it
        set rettext [string map {\n\n \n} $rettext]
        
        if { $::tcl_platform(platform) == "windows"} {
            clipboard clear
            clipboard append $rettext
        } else {
            return $rettext
        }
    } else {
        set ini [$html($w) index sel.first]
        set end [$html($w) index sel.last]    
        if { $ini == "" || $end == "" } { 
            return 
        }
        
        regexp {([0-9]+)[.]([0-9]+)} $ini {} initoc inipos
        regexp {([0-9]+)[.]([0-9]+)} $end {} endtoc endpos
        #puts [$w token list $initoc $endtoc]
        set rettext ""
        set iposlast [expr $endtoc-$initoc]
        set ipos 0
        
        foreach i [$html($w) token list $initoc $endtoc] {
            set type [lindex $i 1]
            set contents [join [lrange $i 2 end]]
            switch -- $type {
                Text {
                    set inichar 0
                    set endchar [string length $contents]
                    if { $ipos == 0 } {
                        set inichar $inipos
                    }
                    if { $ipos == $iposlast } {
                        set endchar [expr $endpos-1]
                    }
                    append rettext [string range $contents $inichar $endchar]
                }
                Space {
                    if { [lindex $contents 1] == 0 } {
                        append rettext " "
                    } else {
                        append rettext "\n"
                    }
                }
            }
            incr ipos
        }
        if { $::tcl_platform(platform) == "windows"} {
            clipboard clear -displayof $html($w)
            clipboard append -displayof $html($w) $rettext
        } else {
            return [string range $rettext $offset [expr $offset+$maxBytes-1]]
        }
    }
}

# what can be: HTML or Word or CSV
proc GiDHelpViewer::SaveHTMLAs { w what } {
    
    set fromfile [GiDHelpViewer::GiveLastFile $w]
    switch $what {
        HTML {
            set types [list \
                    [list [_ "Html file"] [list .htm .html]] \
                    [list [_ "All files"] .*]]
            set ext ".htm"
            set initial [file tail $fromfile]
        }
        Word {
            set types [list \
                    [list [_ "Word file"] [list .doc]] \
                    [list [_ "All files"] .*]]
            set ext ".doc"
            set initial [file root [file tail $fromfile]].doc
        }
        CSV {
            set types [list \
                    [list [_ "CSV file"] [list .csv .txt]] \
                    [list [_ "All files"] .*]]
            set ext ".csv"
            set initial [file root [file tail $fromfile]].csv
        }
        default {
            WarnWin [_ "Unknown file type for file '%s'" $what]
            return
        }
    }
    if { [file exists ConcretePrefs::reportexportdir] && \
        [file isdirectory $ConcretePrefs::reportexportdir] } {
        set defaultdir $ConcretePrefs::reportexportdir
    } else { set defaultdir "" }
    
    
    set tofile [MessageBoxGetFilename file write [_ "Save Results"] \
            $initial $types $ext 0]
    
    if { $tofile == "" } { return }
    
    catch {
        set ConcretePrefs::reportexportdir [file dirname $filename]
    }
    
    if { [file ext $tofile] == ".html" || [file ext $tofile] == ".htm" } {
        set reportexportdir [file dirname $tofile]
        set imgdir [file join $reportexportdir timages]
        if { [file exists $imgdir] } {
            set retval [MessageBoxOptionsButtons [_ "Warning"] \
                    [_ "Are you sure to delete directory '%s' and all its contents?" $imgdir]\
                    {0 1} [list [_ "OK"] [_ "Cancel"]] warning ""]
            if { $retval == 1 } { return }
            if { [catch {
                    file delete -force $imgdir
                } err] } {
                WarnWin [_ "error: Could not delete directory '%s' (%s)" $imgdir $err]
                return
            }
        }
        
        if { [catch {
                set fromimgdir [file join [file dirname $fromfile] timages]
                if { [file exists $fromimgdir] } {
                    file copy -force $fromimgdir $imgdir
                }
                file copy -force $fromfile $tofile
            } err] } {
            WarnWin [_ "Problems exporting report to '%s' (%s). Check write permissions and disk space" \
                    $tofile $err]
            return
        }
    } elseif { [file ext $tofile] == ".doc" || [file ext $tofile] == ".rtf" } {
        rtf:HTML2RTF $fromfile $tofile "Help viewer"
    } elseif { [file ext $tofile] == ".csv" || [file ext $tofile] == ".txt" } {
        rtf:HTML2CSV $fromfile $tofile "Help viewer"
    } else {
        WarnWin [_ "Unknown extension for file '%s'" $tofile]
        return
    }
    set comm [FindApplicationForOpening $tofile]
    # do not visualize
    set comm ""
    if { $comm == "" } {
        WarnWin [_ "Report exported OK to file '%s'" $tofile]
    } else {
        set text [_ "Report exported OK to file '%s' Do you want to visualize it?" $tofile]
        set retval [tk_messageBox -default no -icon question -message $text \
                -parent $w -title [_ "Report exported"] -type yesno]
        if { $retval == "yes" } {
            exec {*}$comm $tofile &
        }
    }
}

proc GiDHelpViewer::HTMLToClipBoardCSV { w } {
    set fromfile [GiDHelpViewer::GiveLastFile $w]
    rtf:HTML2CSV $fromfile "" "Help viewer"
    WarnWin Done
}

proc GiDHelpViewer::FindApplicationForOpening { file } {
    if { $::tcl_platform(platform) == "windows" } {
        return [auto_execok start]
    } else {
        set comm ""
        switch [string tolower [file extension $file]] {
            ".htm" - ".html" {
                set comm [auto_execok konqueror]
                if { $comm == "" } {
                    set comm [auto_execok netscape]
                }
            }
            ".csv" - ".txt" {
                set comm [auto_execok kspread]
            }
        }
    }
    return $comm
}

proc GiDHelpViewer::OpenCurrentPageInBrowser { w } {
    variable LastFileList    
    set url $LastFileList($w)
    if { $url != "" } {
        package require gid_cross_platform   
        gid_cross_platform::open_by_extension $url
    }
}

proc GiDHelpViewer::SetInitialTab { w tab try } {
    variable notebook
    variable HelpBaseDir
    variable tree
    
    if {[lsearch "tree index search" $tab] == -1} {
        set tab tree
    }
    $notebook($w) raise $tab
    if {$tab eq "tree"} {
        if {$try eq ""} {
            set node_data [$tree($w) itemcget [lindex [$tree($w) nodes root] 0] -data]
            set link [lindex $node_data 1]
        } else {
            set link [file join $HelpBaseDir($w) $try]
        }
        GiDHelpViewer::JumpToLink $w $link
    }
}

proc GiDHelpViewer::ContextualMenu { T x y } {        
    set w $T.contextual_menu
    if { [winfo exists $w] } {
        destroy $w
    }
    menu $w    
    set base [winfo toplevel $T]
    $w add command -label [_ "Clipboard copy"] -command [list GiDHelpViewer::CopySelected $base]        
    set x [expr [winfo rootx $T]+$x+2]
    set y [expr [winfo rooty $T]+$y]
    tk_popup $w $x $y
}

proc GiDHelpViewer::Show {file args} {
    set proc_and_arguments  [info level 0]    
    variable HelpBaseDir
    variable html
    variable tree
    variable searchlistbox1
    variable searchlistbox2
    variable notebook
    variable indexlistbox1
    variable indexlistbox2
    variable indexlist1
    variable indexlist2
    variable indexstring
    variable IndexInfo
    variable TitleCache
    variable waiting
    
    array set options [list -title [_ "Help"] -try "" -report 0 -base .help -tab tree]
    array set options $args
    if {$options(-base) eq ""} {
        if { $options(-report)} {
            set options(-base) .gidreport
            set GeometryName GiDReportWindowGeom
        } else {
            set options(-base) .gid.helpref     
            set GeometryName GiDHelpWindowGeom
        }
    } else {
        set GeometryName PrePostCustomHelpWindowGeom
    }
    
    set file [file normalize $file]
    if { [file isdirectory $file] } {
        set _HelpBaseDir $file
    } else {
        set _HelpBaseDir [file dirname $file]
    }
    
    set base $options(-base)
    set title $options(-title)
    
    if {[winfo exists $base] && [info exists HelpBaseDir($base)] && !$options(-report) && ($_HelpBaseDir eq $HelpBaseDir($base))} {
        # is the same window
        raise $base
        GiDHelpViewer::SetInitialTab $base $options(-tab) $options(-try)        
        #GiDHelpViewer::JumpToLink $base [file join $HelpBaseDir($base) $options(-try)]
        return $html($base)
    }
    # reinit the state
    GiDHelpViewer::Init $base
    set HelpBaseDir($base) $_HelpBaseDir
            
    global lastDir tcl_platform argv0
       
    if { $::tcl_platform(platform) != "windows" } {
        option add *Scrollbar*Width 10
        option add *Scrollbar*BorderWidth 1
        option add *Button*BorderWidth 1
    }
    option add *Menu*TearOff 0
    
    if { $title == "" } { set title Help }
    
    if { [info commands InitWindow] != "" } {
        InitWindow $base $title $GeometryName $proc_and_arguments "" 0 0
        if { ![winfo exists $base] } return ;# windows disabled || UseMoreWindows == 0
        bind $base <Escape> "" ;#I don't want thas escape close the help (e.g esc it is used to finish search and will close help!!)
        bind $base <Alt-c> "" ;#I don't want thas escape close the help (e.g esc it is used to finish search and will close help!!)
        if { $::tcl_platform(platform) == "windows" } {    
            #in particular in this window avoid to be a toolwindow to appear minimized in the bar and allow select it to show if hidden by GiD
            wm attributes $base -toolwindow 0
        }
        set w $base
    } else {
        if { $base == "." } {
            if { [winfo exists $base] } {
                #it is the .toplevel, use it
            } else {
                toplevel $base
            }            
            set w ""
        } else {
            if { [winfo exists $base] } {
                destroy $base 
            }
            toplevel $base            
            set w $base
        }
        
        if { $::tcl_platform(platform) == "windows" } {     
            #in particular in this window avoid to be a toolwindow to appear minimized in the bar and allow select it to show if hidden by GiD       
            wm attributes $base -toolwindow 0
        }
        wm title $base $title        
    }
    
    wm state $base withdrawn
    
    ################################################################################
    # the HTML viewer
    ################################################################################
    
    if {$options(-report)} {
        set sw [ScrolledWindow $w.lf -relief sunken -borderwidth 0]
    } else {
        set pw [PanedWindow $w.pw -side top -pad 0 -weights available -activator line]
        
        if { [catch {
                foreach "weight1 weight2" [RamDebugger::ManagePanes $pw h "2 6"] break
            }]} {
            set weight1 2
            set weight2 6
        }
        set pane1 [$pw add -weight $weight1]
        
        $pane1 configure -background \#c2c5ca
        NoteBook $pane1.nb -homogeneous 1 -borderwidth 1 -internalborderwidth 3 -background \#c2c5ca \
            -activebackground \#c2c5ca  -disabledforeground \#c2c5ca
        
        set notebook($base) $pane1.nb
        
        set f1 [$pane1.nb insert end tree -text [_ "Contents"]]
        
        set sw [ScrolledWindow $f1.lf -relief sunken -borderwidth 1]
        set tree($base) [Tree $sw.tree -background white\
                -relief flat -borderwidth 2 -width 10 -highlightthickness 0\
                -redraw 1 -deltay 18 -background #c2c5ca \
                -showlines no \
                -opencmd [list GiDHelpViewer::TreeOpenOrClose $base 1] \
                -closecmd  [list GiDHelpViewer::TreeOpenOrClose $base 0] \
                ]
        
        $sw setwidget $tree($base)
        
        set font [option get $tree($base) font Font]
        
        if { $font != "" } {
            if {[set fm_ls [expr [font metrics $font -linespace]]]>18} {
                $tree($base) configure -deltay $fm_ls
            }
        }
        
        if { $::tcl_platform(platform) != "windows" } {
            $tree($base) configure -selectbackground \#48c96f -selectforeground white
        }
        $pane1.nb itemconfigure tree -raisecmd "focus $tree($base)"
        
        grid $f1.lf -sticky nsew
        grid columnconfigure $f1 0 -weight 1
        grid rowconfigure $f1 0  -weight 1
        
        set f3 [$pane1.nb insert 1 index -text [_ "Index"]]
        label $f3.l1 -text S: -background #c2c5ca
        ttk::entry $f3.e1 -textvariable GiDHelpViewer::indexstring($base)
        bind $f3.e1 <Return> "focus $f3.sw1.lb; GiDHelpViewer::ShowItemIndex $base $f3.e1"
        trace add variable indexstring($base) write [list GiDHelpViewer::FollowItemIndex $base]
        ScrolledWindow $f3.sw1 -relief sunken -borderwidth 1
        listbox $f3.sw1.lb -listvar GiDHelpViewer::indexlist1($base) -background white -exportselection 0
        ScrolledWindow $f3.sw2 -relief sunken -borderwidth 1
        listbox $f3.sw2.lb -listvar GiDHelpViewer::indexlist2($base) -background white -exportselection 0
        $pane1.nb itemconfigure index -raisecmd "GiDHelpViewer::CreateIndexTab $base; focus $f3.e1"
        set indexlistbox1($base) $f3.sw1.lb
        set indexlistbox2($base) $f3.sw2.lb
        $f3.sw1 setwidget $f3.sw1.lb
        $f3.sw2 setwidget $f3.sw2.lb
        
        grid $f3.l1 $f3.e1
        grid configure $f3.e1 -pady 3 -sticky ew
        grid $f3.sw1 -columnspan 2 -sticky ewns     
        grid $f3.sw2 -columnspan 2 -sticky ewns
        grid columnconfigure $f3 1 -weight 1
        grid rowconfigure $f3 {1 2}  -weight 1
        
        bind $f3.sw1.lb <Button-1> +[list focus $f3.sw1.lb]
        bind $f3.sw1.lb <FocusIn> "if { \[%W curselection] == {} } { %W selection set 0 }"
        bind $f3.sw1.lb <Double-1> "focus $f3.sw1.lb; GiDHelpViewer::ShowItemIndex $base $f3.e1"
        bind $f3.sw1.lb <Return> "focus $f3.sw1.lb; GiDHelpViewer::ShowItemIndex $base $f3.e1"
        bind $f3.sw1.lb <<ListboxSelect>> [list GiDHelpViewer::UpdateIndexTitles $base]
        bind $f3.sw2.lb <Button-1> +[list focus $f3.sw2.lb]
        bind $f3.sw2.lb <FocusIn> "if { \[%W curselection] == {} } { %W selection set 0 }"
        bind $f3.sw2.lb <Double-1> "focus $f3.sw2.lb; GiDHelpViewer::ShowItemIndex $base $f3.e1"
        bind $f3.sw2.lb <Return> "focus $f3.sw2.lb; GiDHelpViewer::ShowItemIndex $base $f3.e1"
        
        set f2 [$pane1.nb insert end search -text [_ "Search"]]        
        label $f2.l1 -text S: -background #c2c5ca
        ttk::entry $f2.e1 -textvariable GiDHelpViewer::searchstring($base)        
        $pane1.nb itemconfigure search -raisecmd "focus $f2.e1"
        bind $f2.e1 <Return> "focus $f2.lf1.lb; GiDHelpViewer::SearchInAllHelp $base"                
        ScrolledWindow $f2.lf1 -relief sunken -borderwidth 1
        set searchlistbox1($base) [listbox $f2.lf1.lb -listvar GiDHelpViewer::SearchFound($base) -background white \
                -exportselection 0]
        $f2.lf1 setwidget $f2.lf1.lb        
        ScrolledWindow $f2.lf2 -relief sunken -borderwidth 1
        set searchlistbox2($base) [listbox $f2.lf2.lb -listvar GiDHelpViewer::SearchFound2($base) \
                -background white -exportselection 0]
        $f2.lf2 setwidget $f2.lf2.lb
        
        grid $f2.l1 $f2.e1 
        grid configure $f2.e1 -pady 3 -sticky ew
        grid $f2.lf1 -columnspan 2 -sticky nsew
        grid $f2.lf2 -columnspan 2 -sticky nsew
        grid columnconfigure $f2 1 -weight 1
        grid rowconfigure $f2 {1 2}  -weight 1     
        
        bind $f2.lf1.lb <FocusIn> "if { \[%W curselection] == {} } { %W selection set 0 }"
        bind $f2.lf1.lb <Double-1> "focus $f2.lf2.lb; GiDHelpViewer::SearchInAllHelpL1 $base"
        bind $f2.lf1.lb <Return> "focus $f2.lf2.lb; GiDHelpViewer::SearchInAllHelpL1 $base"
        bind $f2.lf2.lb <FocusIn> "if { \[%W curselection] == {} } { %W selection set 0 }"
        bind $f2.lf2.lb <Double-1> "GiDHelpViewer::SearchInAllHelpL2 $base"
        bind $f2.lf2.lb <Return> "GiDHelpViewer::SearchInAllHelpL2 $base"
        
        set GiDHelpViewer::SearchFound($base) ""
        set GiDHelpViewer::SearchFound2($base) ""
        
        $pane1.nb compute_size
        #$pane1.nb raise tree
        
        set pane2 [$pw add -weight $weight2]
        
        set sw [ScrolledWindow $pane2.lf -relief sunken -borderwidth 0]
    }
        
    if { $::tkhtml_version >=3 } {    
        set html($base,selection_mode) ""        
        set html($base) [html $sw.h -width 800 -height 600]               
        $html($base) configure -imagecmd [list GiDHelpViewer::ImageCmd3 $base]        
        $html($base) handler script style [list GiDHelpViewer::StyleScriptHandler3 $base]
        $html($base) handler node img [list GiDHelpViewer::ImgHandler3 $base]
        #$html($base) handler node a [list GiDHelpViewer::HrefHandler3 $base]
        $html($base) tag configure selection -background #4091fd -foreground white
        GiDHelpViewer::Clear $base        
    } else {
        set html($base) [html $sw.h \
                -formcommand GiDHelpViewer::FormCmd2 \
                -imagecommand GiDHelpViewer::ImageCmd2 \
                -scriptcommand GiDHelpViewer::ScriptCmd2 \
                -appletcommand GiDHelpViewer::AppletCmd2 \
                -underlinehyperlinks 0 \
                -background white -tablerelief raised \
                -resolvercommand GiDHelpViewer::ResolveUri2 \
                -exportselection 1 \
                -takefocus 1 \
                -fontcommand GiDHelpViewer::PickFont2 \
                -width 800 \
                -height 600 \
                -selectioncolor skyblue \
                -unvisitedcolor blue1 \
                -visitedcolor blue3]
    }
    
    
    $sw setwidget $html($base)
            
    ttk::frame $w.buts -style BottomFrame.TFrame     
    
    if {$options(-report)} {
        ttk::button $w.buts.b1 -image [GiDHelpViewer::GetImage arrow_left.png generic] -command [list GiDHistory::GoBackward $base]
        ttk::button $w.buts.b2 -image [GiDHelpViewer::GetImage arrow_right.png generic] -command [list GiDHistory::GoForward $base]
        ttk::menubutton $w.buts.b3 -text [_ "More"]... -menu $w.buts.b3.m
    } else {
        ttk::button $w.buts.b1 -image [GiDHelpViewer::GetImage arrow_left.png generic] -command [list GiDHistory::GoBackward $base]
        ttk::button $w.buts.b2 -image [GiDHelpViewer::GetImage arrow_right.png generic] -command [list GiDHistory::GoForward $base]
        ttk::menubutton $w.buts.b3 -text [_ "More"]... -menu $w.buts.b3.m
    }
    
    menu $w.buts.b3.m
    $w.buts.b3.m add command -label [_ "Home"] -acc "" -command [list GiDHistory::GoHome $base]
    $w.buts.b3.m add separator
    $w.buts.b3.m add command -label [_ "Search in page"]... -acc "Ctrl+F" -command [list GiDHelpViewer::SearchWindow $base]
    if { $::tkhtml_version >= 3 } {
        $w.buts.b3.m add command -label [_ "Search more"] -acc "F3" -command [list GiDHelpViewer::Search3 $base]
    } else {
        $w.buts.b3.m add command -label [_ "Search more"] -acc "F3" -command [list GiDHelpViewer::Search2 $base]
    }
    $w.buts.b3.m add command -label [_ "Open current in browser"] -acc "" -command [list GiDHelpViewer::OpenCurrentPageInBrowser $base]
            
    if {$options(-report)} {
        grid $w.buts.b1 $w.buts.b2 $w.buts.b3 -sticky w
        grid configure $w.buts.b3 -sticky e
        grid columnconfigure $w.buts 2 -weight 1
        grid $sw -sticky "snew"
        grid $w.buts -sticky "ew"
        grid columnconfigure $base 0 -weight 1
        grid rowconfigure $base 0 -weight 1
    } else {        
        grid $w.buts.b1 $w.buts.b2 $w.buts.b3 -sticky e
        grid configure $w.buts.b2 -sticky w
        grid rowconfigure $w.buts 1 -weight 1
        grid columnconfigure $w.buts {0 1} -weight 1
        
        grid $w.pw -sticky nsew
        grid $w.buts -sticky sew
        grid rowconfigure $base 0 -weight 1
        grid columnconfigure $base 0 -weight 1        
        
        grid $pane1.nb -pady 3 -sticky ewns
        grid rowconfigure $pane1 0  -weight 1
        grid columnconfigure $pane1 0 -weight 1
        
        grid $pane2.lf -pady 3 -columnspan 2 -sticky ewns
        grid rowconfigure $pane2 0  -weight 1
        grid columnconfigure $pane2 {0 1} -weight 1        
    }
    
    if {!$options(-report)} {
        grid columnconfigure $w.buts "0 1" -weight 1
        grid columnconfigure $w.buts "2 3 4 " -weight 0
    }
    
    
    # This procedure is called when the user selects the File/Open
    # menu option.
    #
    set lastDir [pwd]       
    
    # This binding changes the cursor when the mouse move over
    # top of a hyperlink.
    #
    if { $::tkhtml_version >= 3 } {
        bind Html <Motion> [list GiDHelpViewer::HtmlMotion3 %W %x %y]
    } else {
        bind HtmlClip <Motion> [list GiDHelpViewer::HtmlMotion2 %W %x %y]
    }
    
    bind $html($base) <Key-Prior> [list GiDHelpViewer::BindPrior2 %W]
    bind $html($base) <Key-Next> [list GiDHelpViewer::BindNext2 %W]       
    bind $html($base) <Key-Up> [list GiDHelpViewer::BindUp2 %W]    
    bind $html($base) <Key-Down> [list GiDHelpViewer::BindDown2 %W]
    bind $html($base) <Key-Home> [list GiDHelpViewer::BindHome2 %W]
    bind $html($base) <Key-End> [list GiDHelpViewer::BindEnd2 %W]
    
    if { $::tcl_platform(platform) == "unix" } {
        foreach {but units} {4 -1 5 1} {
            set comm [string map "%d $units" {GiDHelpViewer::MouseWheel %W %d %x %y}]
            bind $base <$but> $comm
        }
    } else {
        if { $::tkhtml_version >= 3 } {
            bind $base <MouseWheel> {GiDHelpViewer::MouseWheel %W [expr int(-1*%D/36)] %x %y}
        } else {
            bind $html($base) <MouseWheel> {GiDHelpViewer::MouseWheel %W [expr int(-1*%D/36)] %x %y}
        }
    }
   
    if { $::tkhtml_version >= 3 } {
        bind $html($base) <Button-1> [list GiDHelpViewer::HrefBinding3 $base %x %y]
        bind $html($base) <Button-1> +[list GiDHelpViewer::ManageSel3 $base %x %y press]
        bind $html($base) <B1-Motion> [list GiDHelpViewer::ManageSel3 $base %x %y motion]
        bind $html($base) <ButtonRelease-1> [list GiDHelpViewer::ManageSel3 $base %x %y release]
        bind $html($base) <Double-ButtonPress-1> +[list GiDHelpViewer::DoublePress $base %x %y]
    } else {
        bind $html($base).x <Button-1> [list GiDHelpViewer::HrefBinding2 $base %x %y]
        bind $base <Button-1> [list GiDHelpViewer::ManageSel2 $base %W %x %y press]
        bind $base <B1-Motion> [list GiDHelpViewer::ManageSel2 $base %W %x %y motion]
        bind $base <ButtonRelease-1> [list GiDHelpViewer::ManageSel2 $base %W %x %y release]
    }
    
    bind $base <${::acceleratorKey}-c> [list GiDHelpViewer::CopySelected $base]
    if { $::tcl_platform(platform) == "windows"} {
        bind $base <Button-3> "[list GiDHelpViewer::ContextualMenu %W %x %y] ; break"
    }
    
    if { $::tcl_platform(platform) != "windows"} {
        selection handle $html($base) [list GiDHelpViewer::CopySelected $base]
    }
    
    if {!$options(-report)} {
        $tree($base) bindText <ButtonPress-1> [list GiDHelpViewer::Select $base 1]
        $tree($base) bindText <Double-ButtonPress-1> [list GiDHelpViewer::Select $base 2]
        $tree($base) bindImage <ButtonPress-1> [list GiDHelpViewer::Select $base 1]
        $tree($base) bindImage <Double-ButtonPress-1> [list GiDHelpViewer::Select $base 2]
        $tree($base) bindText <${::acceleratorKey}-ButtonPress-1> [list GiDHelpViewer::Select $base 3]
        $tree($base) bindImage <${::acceleratorKey}-ButtonPress-1> [list GiDHelpViewer::Select $base 3]
        $tree($base) bindText <Shift-ButtonPress-1> [list GiDHelpViewer::Select $base 4]
        $tree($base) bindImage <Shift-ButtonPress-1> [list GiDHelpViewer::Select $base 4]
        if { 0 } {
            # dirty trick
            foreach i [bind $tree($base).c] {
                bind $tree($base).c $i "+ [list after idle [list GiDHelpViewer::Select $base 0 {}]]"
            }
        }
        bind $tree($base).c <Return> [list GiDHelpViewer::Select $base 1 {}]
        bind $tree($base).c <KeyPress> "if \[string is wordchar -strict {%A}] {GiDHelpViewer::KeyPress $base %A}"
        bind $tree($base).c <Alt-KeyPress-Left> ""
        bind $tree($base).c <Alt-KeyPress-Right> ""
        bind $tree($base).c <Alt-KeyPress> { break }
        GiDHelpViewer::FillDir $base root
    }
    
    bind [winfo toplevel $html($base)] <Alt-Left> "GiDHistory::GoBackward $base; break"
    bind [winfo toplevel $html($base)] <Alt-Right> "GiDHistory::GoForward $base; break"
    
    
    bind $base <${::acceleratorKey}-f> [list GiDHelpViewer::SearchWindow $base]
    if { $::tkhtml_version >= 3 } {
        bind $base <F3> [list GiDHelpViewer::Search3 $base]
    } else {
        bind $base <F3> [list GiDHelpViewer::Search2 $base]
    }    
    bind $w <Destroy> [list +GiDHelpViewer::OnDestroyGiDHelpViewer %W $base] ;# + to add to previous script
    
    GiDHelpViewer::EnterLastFile $base ""
    if {$options(-report)} {
        # If an argument was specified, read it into the HTML widget.
        if { [file isdirectory $file] } {
            set file2 [file join $file $options(-try)]
            if { [file isfile $file2] } {
                set file $file2                
            }
        }
        GiDHelpViewer::LoadFile $base $file
    } else {
        GiDHelpViewer::SetInitialTab $base $options(-tab) $options(-try)
    }
       
    if { [winfo width $base] < 300 } { 
        #avoid too small initial size
        wm geometry $base 1024x768
    }
    wm state $base normal
    focus $html($base)
    return $html($base)
}

proc GiDHelpViewer::OnDestroyGiDHelpViewer { W base } {
    if { $W != $base } return
    #reenter multiple times, one by toplevel child, only interest w
    variable indexstring
    variable HelpBaseDir
    trace remove variable indexstring($base) write [list GiDHelpViewer::FollowItemIndex $base]
    array unset HelpBaseDir $base
}

proc GiDHelpViewer::HelpSearchWord { w word } {
    variable notebook    
    set GiDHelpViewer::searchstring($w) $word
    $notebook($w) raise search
    GiDHelpViewer::SearchInAllHelp $w
}

proc GiDHelpViewer::HelpDirs { args } {
    variable FillInfo
    GiDHelpViewer::wHelpDirs $FillInfo(toplevel) {*}$args
}

#to avoid problems for BWidget Tree (and also for lists avoid space and ;)
proc GiDHelpViewer::GetValidNodeName { node } {
    set map { & _ | _ ^ _ ! _ :: _ { } _ ; _}
    return [string map $map $node]
}

proc GiDHelpViewer::wHelpDirs { w args } {
    variable FillInfo
    variable tree
    variable tmp
    
    set idxfolder 0
    set parent $FillInfo($w,node)
    
    foreach dinfo $args {
        set dir [lindex $dinfo 0]
        set fullpath [file join $FillInfo($w,dir) $dir]
        if {[set ldinfo [llength $dinfo]] == 1} {
            # try to set the name as the title of the possible
            # table of contents defined in $fullpath/help.conf
            set name [GiDHelpViewer::FigureOutNodeName $w $fullpath]
        } else {
            set name [lindex $dinfo 1]
        }
        if {$ldinfo < 3} {
            if {$ldinfo == 2} {
                # this will find out a possible tocpage
                GiDHelpViewer::FigureOutNodeName $w $fullpath
            }
            set intro_page $tmp(tocpage)
        } else {
            set intro_page [lindex $dinfo 2]
        }
        if { [file isdirectory $fullpath] } {
            #regsub -all {\s} $fullpath _ item
            set item [GiDHelpViewer::GetValidNodeName $fullpath]
            $tree($w) insert $idxfolder $parent $item -image [GiDHelpViewer::GetImage ArrowRight.png small_icons] -text $name \
                -data [list folder $fullpath $intro_page] -drawcross allways
            incr idxfolder
        }
    }
}

proc GiDHelpViewer::GetHREFValue {param} {
    # esta lsearch quizas con -regexp con la expresion que aparece debajo!!!
    set idx [lsearch -glob [string toupper $param] HREF=*]
    if {$idx == -1} {
        set link ""
    } else  {
        #         if {![regexp -nocase -- {HREF(?:\s*)=(?:\s*)"(.*)"} [lindex $param $idx] {} link]} {
            #             WarnWinText "fallo en '$param'"
            #         }
        #ramsan
        if {![regexp -nocase -- {HREF(?:\s*)=(?:\s*)"(.*)"} $param {} link]} {
            WarnWinText "error in '$param'"
        }
    }
    set link
}

proc GiDHelpViewer::GetTITLE { w file } {
    variable TitleCache
    
    if {[info exists TitleCache($w,$file)]} {
        return $TitleCache($w,$file)
    }
    set content [::fileutil::cat $file]
    if {![regexp -nocase <title>(.+)</title> $content {} title]} {
        set title [concat [file tail $file] " " [_ "(No TITLE)"]]
    }
    set TitleCache($w,$file) $title
}

proc  GiDHelpViewer::ProcessIndexUL {w tag slash param text} {
    variable IndexInfo
    variable indexlist1
    
    set tag [string toupper $tag]
    switch $tag {
        UL {
            if {$slash eq ""} {
                set IndexInfo($w,TAGState) "INDEXOPEN"
            } else {
                set IndexInfo($w,TAGState) "INDEXCLOSE"
            }
        }
        LI {
            # ignore </li>
            if {$slash eq "" && $IndexInfo($w,TAGState) eq "INDEXOPEN"} {
                set IndexInfo($w,TAGState) "LI"
                set IndexInfo($w,LI,text) [string trim [::htmlparse::mapEscapes $text]]
            }
        }
        A {
            IndexOnA $w $tag $slash $param $text
        }
        default {
            if {$IndexInfo($w,TAGState) eq "LI"} {
                append IndexInfo($w,INATAG,text) "[::htmlparse::mapEscapes $text]"
            }
        }
    }
}

proc GiDHelpViewer::IndexOnA {w tag slash param text} {
    variable IndexInfo
    variable indexlist1
    
    if {$IndexInfo($w,TAGState) eq "LI"} {
        if {$slash eq ""} {
            set IndexInfo($w,INATAG) 1
            set IndexInfo($w,INATAG,link) [GetHREFValue $param]
            set IndexInfo($w,INATAG,text) $text
        } else {
            set IndexInfo($w,INATAG) 0
            if {![regexp {(.*)\#(.*)} $IndexInfo($w,INATAG,link) {} file tag]} {
                set file $IndexInfo($w,INATAG,link)
                set tag ""
            }
            # find the Title of page
            set file [file join $IndexInfo($w,BaseDir) $file]
            set TITLE [GetTITLE $w $file]
            foreach txt [list $IndexInfo($w,LI,text) $IndexInfo($w,INATAG,text)] {
                if {$txt eq ""} continue
                if {[lsearch $indexlist1($w) $txt]==-1} {
                    lappend indexlist1($w) $txt
                }
                if {![info exists IndexInfo($w,$txt)] ||
                    [lsearch -regexp $IndexInfo($w,$txt) $TITLE]==-1} {
                    lappend IndexInfo($w,$txt) [list $TITLE $file $tag]
                }
            }
            set IndexInfo($w,TAGState) "INDEXOPEN"
        }
    }
}

proc  GiDHelpViewer::ProcessIndexDIR {w tag slash param text} {
    variable IndexInfo
    variable indexlist1
    
    set tag [string toupper $tag]
    switch $tag {
        DIR {
            if {$slash eq ""} {
                set IndexInfo($w,TAGState) "INDEXOPEN"
            } else {
                set IndexInfo($w,TAGState) "INDEXCLOSE"
            }
        }
        LI {
            # ignore </li>
            if {$slash eq "" && $IndexInfo($w,TAGState) eq "INDEXOPEN"} {
                set IndexInfo($w,TAGState) "LI"
                set IndexInfo($w,LI,text) [string trim [::htmlparse::mapEscapes $text]]
            }
        }
        A {
            IndexOnA $w $tag $slash $param $text
        }
        default {
            if {$IndexInfo($w,TAGState) eq "LI"} {
                append IndexInfo($w,INATAG,text) "[::htmlparse::mapEscapes $text]"
            }
        }
    }
}

proc GiDHelpViewer::IndexPage { args } {
    variable FillInfo    
    GiDHelpViewer::wIndexPage $FillInfo(toplevel) {*}$args
}

proc GiDHelpViewer::wIndexPage { w args } {
    variable IndexInfo
    variable FillInfo
    variable indexstring
    
    foreach arg $args {
        set page [lindex $arg 0]
        set type DIR
        if {[llength $arg] > 1} {
            set type [lindex $arg 1]
        }
        set fullpath [file join $FillInfo($w,dir) $page]
        lappend IndexInfo($w,pages) [list $fullpath $type]
        set IndexInfo($w,$fullpath,created) 0
    }
}

proc GiDHelpViewer::CreateIndexTab { w } {
    variable HelpBaseDir
    variable IndexInfo
    variable indexlist1
    
    if {![llength $indexlist1($w)]} {
        GiDHelpViewer::WaitState $w 1
        foreach indexpage $IndexInfo($w,pages) {
            set IndexInfo($w,TAGState) ""
            set page [lindex $indexpage 0]
            if {!$IndexInfo($w,$page,created)} {
                set type [lindex $indexpage 1]
                set IndexInfo($w,BaseDir) [file dir $page]
                htmlparse::parse -cmd [list GiDHelpViewer::ProcessIndex$type $w] [fileutil::cat $page]
                set IndexInfo($w,$page,created) 1
            }
        }
        set indexlist1($w) [lsort $indexlist1($w)]
        GiDHelpViewer::FollowItemIndex $w
        GiDHelpViewer::WaitState $w 0
    }
}

proc GiDHelpViewer::FollowItemIndex { w args } {
    variable indexstring
    variable indexlist1
    variable indexlistbox1
    variable indexlistbox2
    
    set idx [lsearch -glob $indexlist1($w) $indexstring($w)*]
    $indexlistbox1($w) selection clear 0 end    
    if { $idx != -1} {
        $indexlistbox1($w) see $idx
        $indexlistbox1($w) selection set $idx
        $indexlistbox1($w) selection anchor $idx
    }
    GiDHelpViewer::UpdateIndexTitles $w
}

# -------------------------------------------------------------------------------
# GiDHelpViewer::UpdateIndexTitles --
#
# -------------------------------------------------------------------------------

proc GiDHelpViewer::UpdateIndexTitles { w } {
    variable indexlistbox1
    variable indexlistbox2
    variable indexlist1
    variable IndexInfo
    variable indexlist2
    
    set cursel [$indexlistbox1($w) curselection]
    set indexlist2($w) ""
    set IndexInfo($w,titles) ""
    if {$cursel ne ""} {
        foreach idxinfo $IndexInfo($w,[lindex $indexlist1($w) $cursel]) {
            lappend indexlist2($w) [lindex $idxinfo 0]
        }
        $indexlistbox2($w) selection set 0
    }
}

proc GiDHelpViewer::ShowItemIndex { w eindex } {
    variable html
    variable indexlistbox1
    variable indexlistbox2
    variable indexlist1
    variable IndexInfo
    variable data
    
    set idxttl [$indexlistbox2($w) curselection]
    if {$idxttl eq ""} {
        focus $eindex
    } else {
        # Asumo que si idxttl != "" es porque $indexlistbox1 curselection != ""
        set idxinfo [lindex $IndexInfo($w,[lindex $indexlist1($w) [$indexlistbox1($w) curselection]]) $idxttl]
        #puts " GiDHelpViewer::LoadFile $html [lindex $idxinfo 1] 1 [lindex $idxinfo 2]"
        set data($w,sync) 1
        GiDHelpViewer::LoadFile $w [lindex $idxinfo 1] 1 [lindex $idxinfo 2]
    }
}

proc GiDHelpViewer::FindContentsStructure {w tag slash param text} {
    variable FillInfo
    
    if {$FillInfo($w,STOPPED)} {
        return
    }
    if {$slash eq "" && [string equal -nocase $tag "div"]} {
        if {[regexp -nocase -- {class(?:\s*)=(?:\s*)\"(.+)\"} $param => class]} {
            if {[string equal -nocase $class "contents"]} {
                # found "<div class="contents">
                set FillInfo($w,STOPPED) 1
                set FillInfo($w,contents,class) [string toupper $class]
            } elseif {[string equal -nocase $class "shortcontents"]} {
                # found "<div class="shortcontents">
                set FillInfo($w,contents,class) [string toupper $class]
                # but not stop looking for
            }
        }
    }
}


proc GiDHelpViewer::ContentsOnA {w tag slash param text} {
    variable FillInfo
    variable tree
    
    if {$slash eq ""} {
        set FillInfo($w,INATAG) 1
        set FillInfo($w,INATAG,link) [GetHREFValue $param]
        set FillInfo($w,INATAG,text) [::htmlparse::mapEscapes $text]
    } else {
        set FillInfo($w,INATAG) 0
        set fullpath [file join $FillInfo($w,dir) $FillInfo($w,INATAG,link)]
        #regsub -all {\s} $fullpath _ item
        set item [GiDHelpViewer::GetValidNodeName $fullpath]
        while {[$tree($w) exists $item]} {
            append item 1
        }
        set FillInfo($w,LastNode) [$tree($w) insert end $FillInfo($w,parent) \
                $item -image [GiDHelpViewer::GetImage file.png small_icons] \
                -text [string trim $FillInfo($w,INATAG,text)] \
                -data [list file $fullpath]]
    }
}

proc GiDHelpViewer::ProcessTOCUL {w tag slash param text} {
    variable FillInfo
    variable tree
    
    if {$FillInfo($w,STOPPED)} {
        return
    }
    set tag [string toupper $tag]
    switch $tag {
        TITLE {
            if {$slash eq ""} {
                set FillInfo($w,contents,title) [::htmlparse::mapEscapes $text]
            }
        }
        DIV {
            if {$slash eq ""} {
                if {[regexp -nocase -- {class(?:\s*)=(?:\s*)\"(.+)\"} $param => class]} {
                    if {[string equal -nocase $class $FillInfo($w,contents,class)]} {
                        set FillInfo($w,contents,class) "inside"
                    }
                }
            } else {
                if {$FillInfo($w,contents,class) eq "inside"} {
                    set FillInfo($w,contents,class) "outside"
                    set FillInfo($w,STOPPED) 1
                }
            }
        }
        UL {
            if {$FillInfo($w,contents,class) eq "inside"} {
                if {$slash eq "" } {
                    $FillInfo($w,stack) push $FillInfo($w,parent)
                    if {$FillInfo($w,LastNode) ne ""} {
                        set FillInfo($w,parent) $FillInfo($w,LastNode)
                    }
                } else {
                    # si el ultimo parent tiene ahora hijos entonces le pongo
                    # la imagen de book.
                    if {$FillInfo($w,parent) ne "root" && [llength [$tree($w) nodes $FillInfo($w,parent)]]} {
                        set data_node [$tree($w) itemcget $FillInfo($w,parent) -data]
                        $tree($w) itemconfigure $FillInfo($w,parent) -image [GiDHelpViewer::GetImage ArrowRight.png small_icons] \
                            -data [lreplace $data_node 0 0 folder]
                    }
                    
                    if {[$FillInfo($w,stack) size]} {
                        set FillInfo($w,parent) [$FillInfo($w,stack) pop]
                    }
                    set FillInfo($w,STOPPED) [expr ![$FillInfo($w,stack) size]]
                }
            }
        }
        LI {
            # ignore </li>
            if {$slash eq "" && $FillInfo($w,contents,class) eq "inside"} {
                set FillInfo($w,TAGState) "LI"
            }
        }
        A {
            if {$FillInfo($w,TAGState) eq "LI"} {
                GiDHelpViewer::ContentsOnA $w $tag $slash $param  $text
                if {$slash ne ""} {
                    set FillInfo($w,TAGState) ""
                }
            }
        }
        default {
            if {$FillInfo($w,INATAG)} {
                append FillInfo($w,INATAG,text) "[::htmlparse::mapEscapes $text]"
            }
        }
    }
}

proc GiDHelpViewer::ProcessTOCDL {w tag slash param text} {
    variable FillInfo
    variable tree
    
    set tag [string toupper $tag]
    switch $tag {
        TITLE {
            if {$slash eq ""} {
                set FillInfo($w,contents,title) [::htmlparse::mapEscapes $text]
            }
        }
        DL {
            if {$slash eq ""} {
                set FillInfo($w,TAGState) DLOPEN
            } else {
                set FillInfo($w,TAGState) DLCLOSE
            }
        }
        DD {
            if {$FillInfo($w,TAGState) eq "DLOPEN"} {
                #puts "   $text"
            }
        }
        A {
            if {$FillInfo($w,TAGState) eq "DLOPEN"} {
                GiDHelpViewer::ContentsOnA $w $tag $slash $param $text
            }
        }
        default {
            if {$FillInfo($w,INATAG)} {
                append FillInfo($w,INATAG,text) [::htmlparse::mapEscapes $text]
            }
        }
    }
}

proc GiDHelpViewer::FigureOutNodeName { w path } {
    variable tmp
    
    foreach cmd {TocPage IndexPage HelpDirs} {
        rename $cmd ${cmd}Saved
    }
    proc ::TocPage {page {type UL}} {
        set ::GiDHelpViewer::tmp(tocpage) $page
        set page [file normalize [file join $::GiDHelpViewer::tmp(path) $page]]
        set ::GiDHelpViewer::tmp(title) [GiDHelpViewer::GetTITLE $::GiDHelpViewer::FillInfo(toplevel) $page]
    }
    proc ::IndexPage {args} {
    }
    proc ::HelpDirs {args} {
    }
    set tmp(title) ""
    set tmp(tocpage) ""
    set tmp(path) $path
    set helpconf [file join $path help.conf]
    if {[file exists $helpconf]} {
        set comm [fileutil::cat $helpconf]
        eval $comm ;#warning: expected that help.conf file content is directly evaluable commands
    }
    if {[set tmp(title) [string trim $tmp(title)]] eq ""} {
        set tmp(title) [concat [_ "UNNAMED"] " - " $path]
    }
    # restore the original commands
    foreach cmd {TocPage IndexPage HelpDirs} {
        rename ${cmd}Saved $cmd
    }
    set tmp(title)
}

proc GiDHelpViewer::TocPage { page {type UL}} {
    variable FillInfo    
    GiDHelpViewer::wTocPage $FillInfo(toplevel) $page $type
}

proc GiDHelpViewer::wTocPage { w page {type UL}} {
    variable FillInfo
    # aqui lleno a partir de FillInfo(node)
    
    set FillInfo($w,TAGState) ""
    set FillInfo($w,parent) $FillInfo($w,node)
    set FillInfo($w,LastNode) ""
    set FillInfo($w,stack) [::struct::stack]
    set FillInfo($w,STOPPED) 0
    set FillInfo($w,INATAG) 0
    set FillInfo($w,contents,class) "inside"
    # look for the contents structure, could be in this order of priority:
    #   contents
    #   shortconstents
    #   unstructured
    set toc_file [fileutil::cat [file join $FillInfo($w,dir) $page]]
    htmlparse::parse -cmd [list GiDHelpViewer::FindContentsStructure $w] $toc_file
    set FillInfo($w,STOPPED) 0
    # now fill the structure
    set save_dir $FillInfo($w,dir)
    set FillInfo($w,dir) [file normalize [file join $FillInfo($w,dir) [file dirname $page]]]
    htmlparse::parse -cmd [list GiDHelpViewer::ProcessTOC$type $w] $toc_file
    set FillInfo($w,dir) $save_dir
    $FillInfo($w,stack) destroy
}

proc GiDHelpViewer::FillDir { w node } {
    variable HelpBaseDir
    variable FillInfo
    variable tree
    
    if { $node == "root" } {
        set dir $HelpBaseDir($w)
    } else {
        set dir [lindex [$tree($w) itemcget $node -data] 1]
    }
    
    set idxfolder 0
    set files ""
    
    set FillInfo(toplevel) $w
    
    set FillInfo($w,node) $node
    set FillInfo($w,dir) $dir
    set FillInfo($w,contents,title) ""
    
    # check for hlpdir.conf file
    set hlpconf [file join $dir "help.conf"]
    if {[file exists $hlpconf]} {
        set comm [fileutil::cat $hlpconf]
        eval $comm ;#warning: expected that help.conf file content is directly evaluable commands
        if {$node ne "root"} {
            if {[regexp -- ^UNNAMED [$tree($w) itemcget $node -text]] && $FillInfo($w,contents,title) ne ""} {
                $tree($w) itemconfigure $node -text $FillInfo($w,contents,title)
            }
        }
    } else {
        set parent $node
        foreach i [glob -nocomplain -dir $dir *] {
            lappend files [file tail $i]
        }
        
        foreach i [lsort -dictionary $files] {
            set fullpath [file join $dir $i]
            regsub {^[0-9]+} $i {} name
            #regsub -all {\s} $fullpath _ item
            set item [GiDHelpViewer::GetValidNodeName $fullpath]
            if { [file isdirectory $fullpath] } {
                if { $i == "images" } { continue }
                $tree($w) insert $idxfolder $parent $item -image [GiDHelpViewer::GetImage ArrowRight.png small_icons] -text $name \
                    -data [list folder $fullpath] -drawcross allways
                incr idxfolder
            } elseif { [string match .htm* [file ext $i]] } {
                set name [file root $i]
                $tree($w) insert end $parent $item -image [GiDHelpViewer::GetImage file.png small_icons] -text $name \
                    -data [list file $fullpath]
            }
        }
    }
}

proc GiDHelpViewer::TreeOpenOrClose { w open node } {
    variable HelpBaseDir
    variable tree
    if { $open && [$tree($w) itemcget $node -drawcross] == "allways" } {
        GiDHelpViewer::FillDir $w $node        
        $tree($w) itemconfigure $node -drawcross "auto"
        if { [llength [$tree($w) nodes $node]] } {
            set image ArrowDown.png
        } else {
            set image ArrowRight.png
        }
        $tree($w) itemconfigure $node -image [GiDHelpViewer::GetImage $image small_icons]
    } else {
        if { [lindex [$tree($w) itemcget $node -data] 0] == "folder" } {
            if { $open } {
                set image ArrowDown.png
            } else {
                set image ArrowRight.png
            }
            $tree($w) itemconfigure $node -image [GiDHelpViewer::GetImage $image small_icons] 
        }
    }
}

proc GiDHelpViewer::KeyPress { w a } {
    variable tree
    variable searchstring
    
    set node [$tree($w) selection get]
    if { [llength $node] != 1 } { return }
    
    append searchstring($w) $a
    after 300 [list set GiDHelpViewer::searchstring($w) ""]
    
    if { [$tree($w) itemcget $node -open] == 1 && [llength [$tree($w) nodes $node]] > 0 } {
        set parent $node
        set after 1
    } else {
        set parent [$tree($w) parent $node]
        set after 0
    }
    
    foreach i [$tree($w) nodes $parent] {
        if { !$after } {
            if { $i == $node } {
                if { [string length $GiDHelpViewer::searchstring($w)] > 1 } {
                    set after 2
                } else {
                    set after 1
                }
            }
        }
        if { $after == 2 && [string match -nocase $GiDHelpViewer::searchstring($w)* \
            [$tree($w) itemcget $i -text]] } {
            $tree($w) selection clear
            $tree($w) selection set $i
            $tree($w) see $i            
            return
        }
        if { $after == 1 } { set after 2 }
    }
    foreach i [$tree($w) nodes [$tree($w) parent $node]] {
        if { $i == $node } { return }
        if { [string match -nocase $GiDHelpViewer::searchstring($w)* [$tree($w) itemcget $i -text]] } {
            $tree($w) selection clear
            $tree($w) selection set $i
            $tree($w) see $i            
            return
        }
    }
}

proc GiDHelpViewer::FindTopicNode { w node {from root}} {
    variable tree
    
    foreach n [$tree($w) nodes $from] {
        if {$node eq [string range $n 0 [expr [string length $node]-1]]} {
            if {[$tree($w) itemcget $n -drawcross] == "allways"} {
                #node wait to be filled
                GiDHelpViewer::FillDir $w $n
                $tree($w) itemconfigure $n -drawcross "auto"
            }
            return [list $n]
        }
        if {[$tree($w) itemcget $n -drawcross] == "allways"} {
            #node wait to be filled
            GiDHelpViewer::FillDir $w $n
            $tree($w) itemconfigure $n -drawcross "auto"
        }
        # now we can try inside $n
        set node_path [GiDHelpViewer::FindTopicNode $w $node $n]
        if {[llength $node_path]} {
            return [linsert $node_path 0 $n]
        }
    }
    return [list]
}

proc  GiDHelpViewer::FindTopicNodeForPage { w page } {
    regsub -all {\s} $page _ nodeid
    set node_path [GiDHelpViewer::FindTopicNode $w $nodeid]
}

proc GiDHelpViewer::OpenNodePath { w node_path } {
    variable tree
    
    if {[llength $node_path]} {
        foreach parent $node_path {
            $tree($w) itemconfigure $parent -open 1
            if {[$tree($w) itemcget $parent -image] ne [GiDHelpViewer::GetImage file.png small_icons]} {
                $tree($w) itemconfigure $parent -image [GiDHelpViewer::GetImage ArrowDown.png small_icons]
            }
        }
        set nodeid [lindex $node_path end]
        $tree($w) selection set $nodeid
        $tree($w) see $nodeid
        $tree($w) xview moveto 0
    }
}

proc GiDHelpViewer::SyncContents { w page } {
    GiDHelpViewer::OpenNodePath $w [GiDHelpViewer::FindTopicNodeForPage $w $page]
}

proc GiDHelpViewer::JumpToLink { w link } {
    variable tree
    variable html
    variable notebook
    # extract tag
    
    GiDHelpViewer::WaitState $w 1
    $notebook($w) raise tree
    if {![regexp {(.*)\#(.*)} $link {} file tag]} {
        set file $link
        set tag ""
    }
    
    regsub -all {\s} $link _ nodeid
    
    set node_path [GiDHelpViewer::FindTopicNode $w $nodeid]
    if {[llength $node_path]} {
        GiDHelpViewer::OpenNodePath $w $node_path
        set data [$tree($w) itemcget $nodeid -data]
        if {[llength $data] > 2} {
            set file [file join [lindex $data 1] [lindex $data 2]]
        }
    }
    if {$tag eq ""} {
        GiDHelpViewer::LoadFile $w $file
    } else {        
        update idletasks ;#unneeded?
        GiDHelpViewer::LoadFile $w $file 1 $tag
    }
    GiDHelpViewer::WaitState $w 0
}

proc GiDHelpViewer::Select { w num node } {
    variable tree
    variable dblclick
    variable html
    
    #focus $tree($w)
    
    if { $node == "" } {
        set node [$tree($w) selection get]
        if { [llength $node] != 1 } { 
            return 
        }
    } elseif { ![$tree($w) exists $node] } {
        return
    }
    set dblclick 1
    
    GiDHelpViewer::WaitState $w 1
    
    if { $num >= 1 } {
        if { [$tree($w) itemcget $node -open] == 0 } {
            set open 1
        } else {
            set open 0
        }
        $tree($w) itemconfigure $node -open $open
        GiDHelpViewer::TreeOpenOrClose $w $open $node
        if {[$tree($w) itemcget $node -drawcross] eq "auto" && ![llength [$tree($w) nodes $node]]} {
            set isleaf 1
        } else {
            set isleaf 0
        }
        if { $num == 1 && $open == 0 && !$isleaf} {
            GiDHelpViewer::WaitState $w 0
            return
        }
        $tree($w) selection set $node
        if { [llength [$tree($w) selection get]] == 1 } {
            # no se por que no se sigue trabajando con $node
            # trabaje con node y no con selection get
            # set data [$tree($w) itemcget [$tree($w) selection get] -data]
            set data [$tree($w) itemcget $node -data]
            if { $num >= 1 && $num <= 2 } {
                if {[llength $data] == 2} {
                    set fref [lindex $data 1]
                } else {
                    set fref [file join [lindex $data 1] [lindex $data 2]]
                }
                if {[regexp {(.*)\#(.*)} $fref {} file tag]} {
                    GiDHelpViewer::LoadFile $w $file 1 $tag
                } else {
                    GiDHelpViewer::LoadFile $w $fref
                }
            }
        }
        GiDHelpViewer::WaitState $w 0
        return
    }
    GiDHelpViewer::WaitState $w 0
}

proc GiDHelpViewer::TryToSelect { w name {num 3}} {
    variable HelpBaseDir
    variable tree
    
    set nameL [file split $name]
    
    set level [llength [file split $HelpBaseDir($w)]]
    set node root
    while 1 {
        set found 0
        foreach i [$tree($w) nodes $node] {
            if { [lindex [$tree($w) itemcget $i -data] 1] == [file join {*}[lrange $nameL 0 $level]] } {
                set found 1
                break
            }
        }
        if { !$found } { return }
        if { [lindex [$tree($w) itemcget $i -data] 0] == "folder" } {
            set open 1
            if { [$tree($w) itemcget $i -open] == 0 } {
                $tree($w) itemconfigure $i -open $open
            }
            GiDHelpViewer::TreeOpenOrClose $w $open $i
        }
        
        if { $level == [llength $nameL]-1 } {
            GiDHelpViewer::Select $w $num $i
            return
        }
        set node $i
        incr level
    }
}

proc GiDHelpViewer::Search2 { w } {
    variable html   
    focus $html($w)
    if { ![info exists ::GiDHelpViewer::searchstring($w)] } {
        WarnWin [_ "Before using 'Continue search', use 'Search'"] $w
        return
    }
    if { ![winfo exists $html($w)] } return
    if { $GiDHelpViewer::searchstring($w) != "" } {
        
        set comm [list $html($w) text find $GiDHelpViewer::searchstring($w)]
        if { $::GiDHelpViewer::searchcase($w) == 0 } {
            lappend comm nocase
        }
        
        if { $GiDHelpViewer::SearchType($w) == "-forwards" } {
            if { $GiDHelpViewer::SearchPos($w) != "" } {
                lappend comm after $GiDHelpViewer::SearchPos($w)
            } else {
                lappend comm after 1.0
            }
        } else {
            if { $GiDHelpViewer::SearchPos($w) != "" } {
                lappend comm before $GiDHelpViewer::SearchPos($w)
            } else {
                lappend comm before end
            }
        }
        set idx1 ""
        lassign [eval $comm] idx1 idx2
        
        if { $idx1 == "" } {
            bell
        } else {
            scan $idx2 "%d.%d" line char
            set idx2 $line.[expr $char+1]
            $html($w) selection set $idx1 [$html($w) index $idx2]
            update idletasks
            set y [lindex [$html($w) coords $idx1] 1]
            if { $y == "" } { set y 0 }
            set height [lindex [$html($w) coords end] end]
            lassign [$html($w) yview] f1 f2
            set ys [expr $y/double($height)-($f2-$f1)/2.0]
            if { $ys < 0 } { set ys 0 }
            $html($w) yview moveto $ys
            set GiDHelpViewer::SearchPos($w) $idx1
        }
    }
}

proc GiDHelpViewer::LazyMoveTo {w n1 i1 n2 i2} {
    variable html
    set node_bbox [$html($w) text bbox $n1 $i1 $n2 $i2]
    lassign $node_bbox node_left node_top node_right node_bottom
    set document_bbox [$html($w) bbox]
    set document_height [lindex $document_bbox 3]
    set node_top_relative [expr double($node_top)/$document_height]
    set node_bottom_relative [expr double($node_bottom)/$document_height] 
    lassign [$html($w) yview] widget_top_relative widget_bottom_relative
    if {$node_top_relative < $widget_top_relative || $node_bottom_relative > $widget_bottom_relative } {
        #center the box of the text in the widget
        set widget_height_relative [expr ($widget_bottom_relative-$widget_top_relative)]
        set node_height_relative [expr ($node_bottom_relative-$node_top_relative)]
        $html($w) yview moveto [expr $node_top_relative-0.5*($widget_height_relative-$node_height_relative)]
    }
}

proc GiDHelpViewer::Search3 { w } {
    variable html    
    if { ![info exists ::GiDHelpViewer::searchstring($w)] } {
        WarnWin [_ "Before using 'Continue search', use 'Search'"] $w
        return
    }
    if { ![winfo exists $html($w)] } {
        return
    }
    if { $GiDHelpViewer::searchstring($w) != "" } {
        set searchtext $GiDHelpViewer::searchstring($w)
        set doctext [$html($w) text text]        
        if { $::GiDHelpViewer::searchcase($w) == 0 } {
            set searchtext [string tolower $searchtext]
            set doctext [string tolower $doctext]
        }
                
        if { $GiDHelpViewer::SearchType($w) == "-forwards" } {
            if { $GiDHelpViewer::SearchPos($w) != "" && !$GiDHelpViewer::searchFromBegin($w)} {
                set offset_find $GiDHelpViewer::SearchPos($w)
            } else {
                set offset_find 0
            }
            set offset1 [string first $searchtext $doctext $offset_find]
            if { $offset1 == -1 } {
                if { $offset_find != 0 } {
                    set offset_find 0
                    set offset1 [string first $searchtext $doctext $offset_find]
                }
            }
        } else {
            if { $GiDHelpViewer::SearchPos($w) != "" && !$GiDHelpViewer::searchFromBegin($w)} {
                set offset_find $GiDHelpViewer::SearchPos($w)
            } else {
                set offset_find end
            }
            set offset1 [string last $searchtext $doctext $offset_find]
            if { $offset1 == -1 } {
                if { $offset_find != "end" } {
                    set offset_find end
                    set offset1 [string last $searchtext $doctext $offset_find]
                }
            }
        }
                        
        if { $offset1 == -1 } {
            bell
        } else {
            set offset2 [expr $offset1+[string length $searchtext]]
            set idx1 [$html($w) text index $offset1]
            set idx2 [$html($w) text index $offset2]                       
            $html($w) tag add search {*}$idx1 {*}$idx2
            $html($w) tag configure search -bg yellow -fg black
            catch {$html($w) tag delete searchcurrent}
            $html($w) tag add searchcurrent {*}$idx1 {*}$idx2
            $html($w) tag configure searchcurrent -bg orange -fg black
            update idletasks
            GiDHelpViewer::LazyMoveTo $w {*}$idx1 {*}$idx2     
            if { $GiDHelpViewer::SearchType($w) == "-forwards" } {     
                set GiDHelpViewer::SearchPos($w) $offset2
            } else {
                set GiDHelpViewer::SearchPos($w) $offset1
            }
        }
    }
}

proc GiDHelpViewer::OnOk { top w } {
    variable searchstring
    if { $::GiDHelpViewer::searchstring($w) == "" } {            
        GiDHelpViewer::SearchInPageClear $w                
    } else {
        if { $::tkhtml_version >= 3 } {
            GiDHelpViewer::Search3 $w
        } else {
            GiDHelpViewer::Search2 $w
        }
    }
}

proc GiDHelpViewer::OnCancel { top w } {
    GiDHelpViewer::SearchInPageClear $w
    destroy $top
}

proc GiDHelpViewer::SearchWindow { w } {
    variable html
    #focus $html($w)
    
    if { $w == "." } {
        set top .search
    } else {
        set top $w.search
    }
    if { [winfo exists $top] } {
        destroy $top
    }
    toplevel $top
    if { $::tcl_platform(platform) == "windows" } {
        wm attributes $top -toolwindow 1
    }
    wm title $top [_ "Search"]
    set f [frame $top.f]
    
    ttk::label $f.l1 -text [_ "Text"]:
    ttk::entry $f.e1 -textvariable ::GiDHelpViewer::searchstring($w)
    
    set f25 [ttk::frame $f.f25 -borderwidth 1 -style ridge.TFrame]    
    ttk::radiobutton $f25.r1 -text [_ "Forward"] -variable ::GiDHelpViewer::SearchType($w) -value -forwards
    ttk::radiobutton $f25.r2 -text [_ "Backward"] -variable ::GiDHelpViewer::SearchType($w) -value -backwards
    
    set f3 [ttk::frame $f.f3]
    
    if { ![info exists ::GiDHelpViewer::searchcase($w)] } { 
        set ::GiDHelpViewer::searchcase($w) 0 
    }
    ttk::checkbutton $f3.cb1 -text [_ "Consider case"] -variable ::GiDHelpViewer::searchcase($w)
    if { ![info exists ::GiDHelpViewer::searchFromBegin($w)] } {
        set ::GiDHelpViewer::searchFromBegin($w) 0 
    }
    ttk::checkbutton $f3.cb2 -text [_ "From beginning"] -variable ::GiDHelpViewer::searchFromBegin($w)
    
    grid $f.l1 $f.e1
    grid configure $f.e1 -padx 3 -pady 3 -sticky ew
    grid $f25.r1 -sticky w
    grid $f25.r2 -sticky w
    grid $f.f25 -columnspan 2 -padx 3 -sticky w
    grid $f3.cb1  $f3.cb2
    grid $f.f3 -columnspan 2 -padx 3 -sticky w
    grid columnconfigure $f 1 -weight 1

    ttk::frame $top.buts -style BottomFrame.TFrame
    ttk::button $top.buts.ok -text [_ "Ok"] -command [list GiDHelpViewer::OnOk $top $w] -style BottomFrame.TButton
    ttk::button $top.buts.cancel -text [_ "Cancel"] -command [list GiDHelpViewer::OnCancel $top $w] -style BottomFrame.TButton

    grid $top.buts.ok $top.buts.cancel -padx 3 -pady 3
    grid $top.f -sticky ewns -padx 2 -pady 2
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    
    grid $top.buts -sticky ew
    grid anchor $top.buts center    

    if { ![info exists ::GiDHelpViewer::searchstring($w)] } {
        set ::GiDHelpViewer::searchstring($w) ""
    }
    
    #     set ::GiDHelpViewer::searchmode($w) -exact
    #     set ::GiDHelpViewer::searchcase($w) 0
    #     set ::GiDHelpViewer::searchFromBegin($w) 0
    #     set ::GiDHelpViewer::SearchType($w) -forwards
    
    focus $f.e1
    bind $top <Return> [list $top.buts.ok invoke]
    bind  $top <Escape> [list $top.buts.cancel invoke]
}

proc GiDHelpViewer::CreateIndex { w } {
    variable HelpBaseDir
    variable Index
    variable IndexFilesTitles
    variable progressbar
    variable progressbarStop
    variable html
    
    if {[llength [array names Index $w,*]]} { return }
    if { [file exists [file join $HelpBaseDir($w) wordindex]] } {
        set fin [open [file join $HelpBaseDir($w) wordindex] r]
        fconfigure $fin -encoding utf-8
        foreach "IndexFilesTitles($w) aa" [read $fin] break
        #array set Index $aa
        foreach "idx value" $aa {
            set Index($w,$idx) $value
        }
        close $fin
        return
    }
    
    GiDHelpViewer::WaitState $w 1
    
    ProgressDlg $html($w).prdg -textvariable GiDHelpViewer::progressbarT($w) -variable \
        GiDHelpViewer::progressbar($w) -title [_ "Creating search index"] \
        -troughcolor \#48c96f -stop Stop -command "set GiDHelpViewer::progressbarStop($w) 1"
    
    set progressbar($w) 0
    set progressbarStop($w) 0
    
    array unset Index $w,*
    
    set files [::fileutil::findByPattern $HelpBaseDir($w) "*.htm *.html"]
    
    set len [llength [file split $HelpBaseDir($w)]]
    set ipos 0
    set numfiles [llength $files]
    
    set IndexFilesTitles($w) ""
    
    foreach i $files {
        set GiDHelpViewer::progressbar($w) [expr int($ipos*50/$numfiles)]
        set GiDHelpViewer::progressbarT($w) $GiDHelpViewer::progressbar($w)%
        if { $GiDHelpViewer::progressbarStop($w) } {
            destroy $html($w).prdg
            return
        }
        
        set fin [open $i r]
        set aa [read $fin]
        
        set file [file join {*}[lrange [file split $i] $len end]]
        set title ""
        regexp {(?i)<title>(.*?)</title>} $aa {} title
        if { $title == "" } {
            regexp {(?i)<h([1234])>(.*?)</h\1>} $aa {} {} title
        }
        lappend IndexFilesTitles($w) [list $file $title]
        set IndexPos [expr [llength $IndexFilesTitles($w)]-1]
        
        foreach j [regexp -inline -all -- {-?\w{3,}} $aa] {
            if { [string is integer $j] || [string length $j] > 25 || [regexp {_[0-9]+$} $j] } {
                continue
            }
            lappend Index($w,[string tolower $j]) $IndexPos
        }
        close $fin
        incr ipos
    }
    
    proc IndexesSortCommand { e1 e2 } {
        upvar freqs freqsL
        if { $freqsL($e1) > $freqsL($e2) } { return -1 }
        if { $freqsL($e1) < $freqsL($e2) } { return 1 }
        return 0
    }
    
    set names [array names Index]
    set len [llength $names]
    set ipos 0
    foreach i $names {
        set GiDHelpViewer::progressbar($w) [expr 50+int($ipos*50/$len)]
        set GiDHelpViewer::progressbarT($w) $GiDHelpViewer::progressbar($w)%
        if { $GiDHelpViewer::progressbarStop($w) } {
            destroy $html($w).prdg
            return
        }
        foreach j $Index($i) {
            set title [lindex [lindex $IndexFilesTitles($w) $j] 1]
            if { [string match -nocase *$i* $title] } {
                set icr 10
            } else { set icr 1 }
            if { ![info exists freqs($j)] } {
                set freqs($j) $icr
            } else { incr freqs($j) $icr }
        }
        #           if { $i == "variable" } {
            #               puts "-----variable-----"
            #               foreach j $Index($i) {
                #                   puts [lindex $IndexFilesTitles $j]-----$j
                #               }
            #               parray freqs
            #           }
        set Index($i) [lrange [lsort -command GiDHelpViewer::IndexesSortCommand [array names freqs]] \
                0 4]
        
        #           if { $i == "variable" } {
            #               puts "-----variable-----"
            #               foreach j [lsort -command GiDHelpViewer::IndexesSortCommand [array names freqs]] {
                #                   puts [lindex $IndexFilesTitles $j]-----$j
                #               }
            #           }
        unset freqs
        incr ipos
    }
    
    set GiDHelpViewer::progressbar($w) 100
    set GiDHelpViewer::progressbarT($w) $GiDHelpViewer::progressbar($w)%
    destroy $html($w).prdg
    set fout [open [file join $HelpBaseDir($w) wordindex] w]
    fconfigure $fout -encoding utf-8
    # aqui tengo que eliminar el nombre de la ventana $w del get
    set pairs [list]
    set starti [expr [string length $w]+1]
    foreach {idx value} [array get Index $w,*] {
        set i [string range $idx $starti end]
        lappend pairs $i $value
    }
    #    puts -nonewline $fout [list $IndexFilesTitles($w) [array get Index $w,*]]
    puts -nonewline $fout [list $IndexFilesTitles($w) $pairs]
    close $fout
    GiDHelpViewer::WaitState $w 0
}

proc GiDHelpViewer::IsWordGood { w word otherwords } {
    variable Index
    variable IndexFilesTitles
    
    if { $otherwords == "" } { return 1 }
    
    if { ![info exists Index($w,$word)] } { return 0 }
    
    foreach i $Index($w,$word) {
        set file [lindex [lindex $IndexFilesTitles($w) $i] 0]
        if { [HasFileTheWord $w $file $otherwords] } { return 1 }
    }
    return 0
}

proc GiDHelpViewer::HasFileTheWord { w file otherwords } {
    variable HelpBaseDir
    variable Index
    variable IndexFilesTitles
    variable FindWordInFileCache
    
    set fullfile [file join $HelpBaseDir($w) $file]
    
    foreach word $otherwords {
        if { [info exists FindWordInFileCache($w,$file,$word)] } {
            if { !$FindWordInFileCache($w,$file,$word) } { return 0 }
            continue
        }
        set fin [open $fullfile r]
        set aa [read $fin]
        close $fin
        if { [string match -nocase *$word* $aa] } {
            set FindWordInFileCache($w,$file,$word) 1
        } else {
            set FindWordInFileCache($w,$file,$word) 0
            return 0
        }
    }
    return 1
}

proc GiDHelpViewer::SearchInAllHelp { w } {
    variable HelpBaseDir
    variable Index
    variable searchlistbox1
    
    set word [string tolower $GiDHelpViewer::searchstring($w)]
    GiDHelpViewer::CreateIndex $w
    
    set GiDHelpViewer::SearchFound($w) ""
    set GiDHelpViewer::SearchFound2($w) ""
    
    if { [string trim $word] == "" } { return }
    
    set words [regexp -all -inline {\S+} $word]
    if { [llength $words] > 1 } {
        set word [lindex $words 0]
        set otherwords [lrange $words 1 end]
    } else { set otherwords "" }
    
    set ipos 0
    set iposgood -1
    set starti [expr [string length $w]+1]
    foreach idx [array names Index $w,*$word*] {
        set i [string range $idx $starti end]
        if { ![IsWordGood $w $i $otherwords] } { continue }
        
        lappend GiDHelpViewer::SearchFound($w) $i
        if { [string equal $word [lindex $i 0]] } { set iposgood $ipos }
        incr ipos
    }
    if { $iposgood == -1 && [llength [GiDHelpViewer::GiveManHelpNames $GiDHelpViewer::searchstring($w)]] > 0 } {
        lappend GiDHelpViewer::SearchFound($w) $GiDHelpViewer::searchstring($w)
        set iposgood $ipos
    }
    
    if { $iposgood >= 0 } {
        $searchlistbox1($w) selection clear 0 end
        $searchlistbox1($w) selection set $iposgood
        $searchlistbox1($w) see $iposgood        
        GiDHelpViewer::SearchInAllHelpL1 $w
    }
}

proc GiDHelpViewer::SearchInAllHelpL1 { w } {
    variable Index
    variable IndexFilesTitles
    variable SearchFound2
    variable SearchFound2data
    variable searchlistbox1
    variable searchlistbox2
    
    set SearchFound2($w) ""
    set SearchFound2data($w) ""
    
    set sels [$searchlistbox1($w) curselection]
    if { $sels == "" } {
        bell
        return
    }
    
    set words [regexp -all -inline {\S+} $GiDHelpViewer::searchstring($w)]
    if { [llength $words] > 1 } {
        set otherwords [lrange $words 1 end]
    } else { set otherwords "" }
    
    set ipos 0
    set iposgood -1
    set iposgoodW -1
    foreach i $sels {
        set word [$searchlistbox1($w) get $i]
        if { [info exists Index($w,$word)] } {
            foreach i $Index($w,$word) {
                foreach "file title" [lindex $IndexFilesTitles($w) $i] break
                
                if { ![HasFileTheWord $w $file $otherwords] } { continue }
                
                if { [lsearch $GiDHelpViewer::SearchFound2($w) $title] != -1 } { continue }
                
                lappend SearchFound2($w) $title
                lappend SearchFound2data($w) $i
                if { [string match -nocase *$word* $title] } {
                    set W 1
                    foreach i $otherwords {
                        if { [string match -nocase *$i* $title] } { incr W }
                    }
                    if { [string match -nocase *$GiDHelpViewer::searchstring($w)* $title] } { incr W }
                    if { [string equal -nocase $GiDHelpViewer::searchstring($w) $title] } { incr W }
                    
                    if { $W > $iposgoodW } {
                        set iposgood $ipos
                        set iposgoodW $W
                    }
                }
                incr ipos
            }
        }
        foreach i [GiDHelpViewer::GiveManHelpNames $word] {
            lappend SearchFound2($w) $i
            if { $iposgood == -1 } {
                set iposgood $ipos
            } else { set iposgood -2 }
            incr ipos
        }
    }
    if { $iposgood < 0 && $ipos > 0 } { set iposgood 0 }
    if { $iposgood >= 0 } {
        focus $searchlistbox2($w)
        $searchlistbox2($w) selection clear 0 end
        $searchlistbox2($w) selection set $iposgood
        $searchlistbox2($w) see $iposgood        
        GiDHelpViewer::SearchInAllHelpL2 $w
    }
}

proc GiDHelpViewer::SearchInAllHelpL2 { w } {
    variable HelpBaseDir
    variable SearchFound2data
    variable IndexFilesTitles
    variable SearchFound
    variable SearchFound2
    variable html
    variable searchlistbox1
    variable searchlistbox2
    variable searchstring
    variable data
    
    set sels [$searchlistbox2($w) curselection]
    if { [llength $sels] != 1 } {
        bell
        return
    }
    if { [regexp {(.*)\(man (.*)\)} [lindex $SearchFound2($w) $sels]] } {
        SearchManHelpFor $w [lindex $SearchFound2($w) $sels]
    } else {
        set i [lindex $SearchFound2data($w) $sels]
        set file [file join $HelpBaseDir($w) [lindex [lindex $IndexFilesTitles($w) $i] 0]]
        
        set word [lindex $SearchFound($w) [lindex [$searchlistbox1($w) cursel] 0]]
        # deshabilito el draw del html
        #$html($w) draw disabled
        # esto es para que load lo deje deshabilitado
        #set data($w,draw) disabled
        # para sincronizar con el arbol
        set data($w,sync) 1
        GiDHelpViewer::LoadFile $w $file 1
        set searchstring($w) $word
        if { $::tkhtml_version >= 3 } {
            GiDHelpViewer::Search3 $w
        } else {
            GiDHelpViewer::Search2 $w
        }
        #set data($w,draw) enabled
        #$html($w) draw enabled
    }
}

proc GiDHelpViewer::WaitState { w what } {
    variable tree
    variable html
    variable indexlistbox1
    variable indexlistbox2
    variable waiting
    
    if {$what && $waiting($w)} return
    
    if {$what} {
        set cursor watch
    } else {
        set cursor ""
    }
    foreach _w [list $w $html($w)] {
        conf_cursor $_w $cursor
    }
    catch {
        foreach _w [list $tree($w) $indexlistbox1($w) $indexlistbox2($w)] {
            $_w configure -cursor $cursor
        }
    }
    set waiting($w) $what
}

package provide gid_helpviewer 1.1

############################### ped.tcl ######################################
#
# PED: the Tcl runtime proc editor
#
# This tool implements a GUI that allows the user to edit
# any proc in the currently running program.
#
# Usage: ::ped::create
#
# The author hereby disclaims copyright to this source code.
#

# Everything in a namespace
#
namespace eval ped {

# proc:   ::ped::create
# title:  Create a proc editor
#
# This routine creates a new top-level window which implements
# a tree widget containing the proc, namespace, and variable
# hierarchy of the currently running program.
#
# Both array and scalar variables are supported.  Array variables
# appear as tree nodes and have leaf nodes representing the array elements.
#
# When the user selects a node representing a proc,
# a text widget is filled with the proc name, args, and body.
# If the proc represents a variable (scalar or array element), then
# the value of the variable is displayed.
#
# The user can edit the proc or variable and save the results, causing the
# current program to be changed immediately.  Or, for a proc, the user
# can save the new proc body to a file.
#
proc create {} {
  set w .ped
  if {[winfo exists $w]} {
    wm deiconify $w
    update
    raise $w
    focus $w
    return
  }
  toplevel $w
  wm title $w {PED: Tcl in-Process EDitor}
  wm iconname $w PED

  # option add *foreground "Black"
  # option add *background "Grey" ;# widgetDefault
  set TREE_BG "#edf3fe"

  ttk::frame $w.bb
  pack $w.bb -side bottom
 
  ttk::button $w.bb.save -text "Save to Program" \
      -command ::ped::_save -state disabled
  ttk::button $w.bb.saveas -text "Save As..." -command ::ped::_saveas \
      -state disabled
  ttk::button $w.bb.dis -text Dismiss -command "destroy $w"

  wm protocol $w WM_DELETE_WINDOW "$w.bb.dis invoke"
  pack $w.bb.save $w.bb.saveas $w.bb.dis -padx 2 -pady 2 -side left -fill y

  canvas $w.tree -width 200 -height 350 -yscrollcommand "$w.sb1 set" \
     -highlightthickness 0 -bg white -bd 0 \
	 -background $TREE_BG

  $w.tree bind close_icon <1> ::ped::_open_branch
  $w.tree bind open_icon <1> ::ped::_close_branch
  $w.tree bind icon <1> ::ped::_select_branch
  $w.tree bind txt <1> ::ped::_select_branch
  pack $w.tree -side left -fill y
  scrollbar $w.sb1 -orient vertical -command "$w.tree yview"
  pack $w.sb1 -side left -fill y
  text $w.info -width 80 -height 24 -yscrollcommand "$w.sb2 set" \
     -highlightthickness 0 -bg white -fg "Black" -bd 0
  $w.info tag config err -foreground red
  proc _save_off {w} {
    if {[winfo exists $w]} {$w config -state disabled}
  }
  proc _save_on {w} {
    if {[winfo exists $w]} {$w config -state normal}
  }
  bind $w.info <KeyPress> [list ::ped::_save_on $w.bb.save]
  bind $w <Destroy> ::ped::_cleanup
  scrollbar $w.sb2 -orient vertical -command "$w.info yview"
  pack $w.sb2 -side right -fill y
  pack $w.info -side left -fill both -expand 1
  _rebuild_tree
}



###############################################################################
# The public interface to this module is above this line.  Everything that
# follows is private to this module and should not be accessed or modified
# by outside code.
#

# This proc is called exactly once at the start of the program
#
proc _init {} {

  # A single directory in the tree which is in the viewer.
  #
  variable focus [list [list meta {}] meta {}]

  # All directories that have been expanded in the viewer
  #
  array set open {}

  # Images used for drawing.
  #
  image create photo ::ped::iproc -data {
      R0lGODlhDQANAPIEAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACH5BAEAAAQA
      LAAAAAANAA0AAANkGBERgRFBREgxM4MzMxFIFDODMzMjOEExgjMzMygAEIMz
      AAMIMwKBMzMzODMjgDEDAAgAM4IQMzM4MzODAjEDCAAAgyMQMzgzM4MzAjE4
      MzODMyMQKCIigiIiAggAAIAAAAAICQA7
  }
  image create photo ::ped::var -data {
      R0lGODlhDQANAPIEAAAAAHh4eDLNMri4uP///wAAAAAAAAAAACH5BAEAAAQA
      LAAAAAANAA0AAANkGBERgRFBREghIoIiIhFIFCKCIiIyKEEhgyIiIjgAEIIi
      AAIIIgOBIiIiKCIygCECAAgAIoMQIiIoIiKCAyECCAAAgjIQIigiIoIiAyEo
      IiKCIjIQODMzgzMzAwgAAIAAAAAICQA7
  }
  image create photo ::ped::nsopen -data {
      R0lGODlhEAANAPIAAPgAAICAgPj8+MDAwPj8AAAAAAAAAAAAACH5BAEAAAAALAAAAAAQAA0A
      AAM8CBrM+hAEQWmIbw6yh2jNInCkV32FJHRlGRRgDBLvdN7vUK8tC78qlrCWmvRKsJTquHkp
      ZbKCEiCtWq0JADv/
  }
  image create photo ::ped::nsclosed -data {
      R0lGODlhDwANAPIAAPgAAICAgMDAwPj8APj8+AAAAAAAAAAAACH5BAEAAAAALAAAAAAPAA0A
      AAMzCBDM+jCIMUWAT9JtmwtEKI5hUIBcOplgpVIs8bqxa8OnfNP5zsWzDctD9BQAhaRyuUwA
      ADv/
  }
  image create photo ::ped::aaopen -data {
      R0lGODlhEAANAPIFAAAAADLNMoCAgMDAwPj8+P///wAAAAAAACH5BAEAAAUA
      LAAAAAAQAA0AAAN6WFUigiJVVVhVVYVCREQoVVWFVSU0GBNDgiIiUlhCMYET
      Q0RIJFCCNDExGBMTgwIiIigiIoIiEgIoRESEREQkCCMghBMTEzgxAYICJTQY
      ExODMQICWEIxgRMTEzggUIVCMTEYExOCAFUiKCIigiIiAFhVAIAAAAAIAJAA
      Ow==
  }
  image create photo ::ped::aaclosed -data {
      R0lGODlhDwANAPIFAAAAADLNMoCAgMDAwPj8+P///wAAAAAAACH5BAEAAAUA
      LAAAAAAPAA0AAANzWCUiglJVVVhVJYMxMVJYVVWFMjExGCMigiIlREhERIRE
      RAIoFBODMTExGAJCgzExMRgTI4BCMTEYExODISA0GBMTgzExAigUE4MxMTEY
      AkKDMTExGBMjgEIxMRgTE4MhICIoIiKCIiICWAAAgAAAAAgACQA7
  }

  #
  # Bitmaps used to show which parts of the tree can be opened.
  #
  set maskdata "#define solid_width 9\n#define solid_height 9"
  append maskdata {
    static unsigned char solid_bits[] = {
     0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01,
     0xff, 0x01, 0xff, 0x01, 0xff, 0x01
    };
  }
  set data "#define open_width 9\n#define open_height 9"
  append data {
    static unsigned char open_bits[] = {
     0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7d, 0x01, 0x01, 0x01,
     0x01, 0x01, 0x01, 0x01, 0xff, 0x01
    };
  }
  image create bitmap ::ped::openbm -data $data -maskdata $maskdata \
    -foreground black -background white -foreground "Black"
  set data "#define closed_width 9\n#define closed_height 9"
  append data {
    static unsigned char closed_bits[] = {
     0xff, 0x01, 0x01, 0x01, 0x11, 0x01, 0x11, 0x01, 0x7d, 0x01, 0x11, 0x01,
     0x11, 0x01, 0x01, 0x01, 0xff, 0x01
    };
  }
  image create bitmap ::ped::closedbm -data $data -maskdata $maskdata \
    -foreground black -background white -foreground "Black"
}
if {![info exists ::ped::focus]} _init


# Rebuild one level of the display
# $desc describes the element at the current level.  It's a list with
# 2 values:  the element's root type, and its name.
# $ptype is the type of the element (possible values: ns, procs, vars,
#  widget, binding)
#
proc _rebuild_one_level {desc ptype indent yvar} {
  variable id2info
  variable id2txt
  variable id2icon
  variable focus
  variable focus_id
  variable open
  upvar 1 $yvar y
  foreach {roottype path} $desc break
  if {$ptype=="ns" && ![_has_children $path]} return
  if {$ptype=="vars" && [array size $path]==0} return
  if {$ptype=="widgets" && [winfo children $path]==""} return
  set can .ped.tree
  set i4 [expr {$indent+4}]
  set i9 [expr {$indent+9}]
  set i12 [expr {$indent+12}]
  set i14 [expr {$indent+14}]
  set i30 [expr {$indent+30}]
  set prevy $y
  set dirs {}
  set leaves {}

  switch -- $roottype {
    meta {
      if {$path==""} {
        set alist [list meta {{Procs & Vars} Widgets}]
      } elseif {[string match {Procs*} $path]} {
        set roottype procs
        if {[catch {
          set ns    [lsort -dictionary [namespace children ::]]
        }]} {set ns {}}
        set procs [lsort -dictionary [info proc ::*]]
        set vars  [lsort -dictionary [info var  ::*]]
        set alist [list ns $ns procs $procs vars $vars]
      } elseif {$path=="Widgets"} {
        set roottype widgets
        set alist [list widgets .]
      } else return
    }
    procs {
      if {[catch {
        set ns    [lsort -dictionary [namespace children $path]]
      }]} {set ns {}}
      set procs [lsort -dictionary [info proc ${path}::*]]
      set vars  [lsort -dictionary [info var  ${path}::*]]
      set aents [lsort -dictionary [array names $path]]
      set alist [list ns $ns procs $procs vars $vars aents $aents]
    }
    widgets {
      if {[catch {
        set widgets [lsort -dictionary [winfo children $path]]
      }]} {set widgets {}}
      set alist [list widgets $widgets]
    }
  }
  foreach {rtype list} $alist {
    foreach full $list {
      if {$rtype=="aents"} {
        set name $full
        set full ${path}($name)
        set type vars
      } elseif {$rtype=="widgets"} {
        if {$full!="."} {set name [winfo name $full]} {set name .}
        set type widgets
      } elseif {$rtype=="meta"} {
        set name $full
        set type meta
      } else {
        set type $rtype
        set name [namespace tail $full]
      }
      set y16 [expr {$y+16}]
      $can lower [$can create line $i4 $prevy $i4 $y16 -fill gray]
      $can create line $i4 $y16 $i12 $y16 -fill gray
      set id [$can create text $i30 $y16 -text $name -anchor w -tags txt]
      set txtid $id
      set id2info($id) [list [list $roottype $full] $type]
      set id2txt($id) $txtid
      set focus_desc [lindex $focus 0]
      switch $type {
        ns {
          if {$full==[lindex $focus_desc 1]} {
            foreach {x1 y1 x2 y2} [$can bbox $id] break
            set id2 [$can create rectangle $x1 $y1 $x2 $y2 -fill skyblue]
            set focus_id $id2
            $can lower $id2
            set icon ::ped::nsopen
          } else {
            set icon ::ped::nsclosed
          }
        }
        procs {
          set icon ::ped::iproc
        }
        vars -
        aents {
          if {[array exists $full]} {
            if {$full==[lindex $focus_desc 1]} {
              foreach {x1 y1 x2 y2} [$can bbox $id] break
              set id2 [$can create rectangle $x1 $y1 $x2 $y2 -fill skyblue]
              set focus_id $id2
              $can lower $id2
              set icon ::ped::aaopen
            } else {
              set icon ::ped::aaclosed
            }
          } else {
            set icon ::ped::var
          }
        }
        widgets {
          if {[winfo children $full]!=""} {
            if {$full==[lindex $focus_desc 1]} {
              foreach {x1 y1 x2 y2} [$can bbox $id] break
              set id2 [$can create rectangle $x1 $y1 $x2 $y2 -fill skyblue]
              set focus_id $id2
              $can lower $id2
              set icon ::ped::nsopen
            } else {
              set icon ::ped::nsclosed
            }
          } else {
            set icon ::ped::iproc
          }
        }
        meta {
          if {$full==[lindex $focus_desc 1]} {
            foreach {x1 y1 x2 y2} [$can bbox $id] break
            set id2 [$can create rectangle $x1 $y1 $x2 $y2 -fill skyblue]
            set focus_id $id2
            $can lower $id2
            set icon ::ped::nsopen
          } else {
            set icon ::ped::nsclosed
          }
        }
      }
      set id [$can create image $i12 $y16 -image $icon -anchor w -tags icon]
      set iconid $id
      set id2info($id) [list [list $roottype $full] $type]
      set id2txt($id) $txtid
      set id2icon($id) $iconid
      set id2icon($txtid) $iconid
      set prevy $y
      set y $y16
      if {[info exists open([list [list $roottype $full] $type])]} {
        set id [$can create image $indent $y -image ::ped::openbm \
                    -anchor w -tags open_icon]
        set id2info($id) [list [list $roottype $full] $type]
        set id2txt($id) $txtid
        set id2icon($id) $iconid
        _rebuild_one_level [list $roottype $full] $type $i12 y
      } elseif {($type=="ns" && [_has_children $full]) ||
                ($type=="vars" && [array size $full]>0) ||
                ($type=="widgets" && [winfo children $full]!="") ||
                $type=="meta"} {
        set id [$can create image $indent $y -image ::ped::closedbm \
                -anchor w -tags close_icon]
        set id2info($id) [list [list $roottype $full] $type]
        set id2txt($id) $txtid
        set id2icon($id) $iconid
      }
    }
  }
}

# Return TRUE if the given namespace contains child namespaces, procs, or vars.
# Return FALSE if it does not.
#
proc _has_children {path} {
  return [expr {[_has_subdir $path] || [info proc ${path}::*]!="" ||
      [info var ${path}::*]!=""}]
}

# Return TRUE if $path has a child namespace
#
proc _has_subdir {path} {
  set rc 0
  catch {
    if {[namespace children $path]!=""} {set rc 1}
  }
  return $rc
}

# Rebuild the whole tree display
#
proc _rebuild_tree {} {
  set y 0
  set w .ped
  $w.tree delete all
  set ::ped::focus_id nil
  catch {unset ::ped::id2info}
  catch {unset ::ped::id2txt}
  catch {unset ::ped::id2icon}
  foreach entry [array names ::ped::open] {
    foreach {desc type} $entry break
    if {$type!="ns" && $type!="vars" && $type!="meta" && $type!="widgets"} {
      unset ::ped::open($entry)
    }
  }
  set type [lindex $::ped::focus 1]
  if {$type!="ns" && $type!="vars" && $type!="meta" && $type!="widgets"} {
    set ::ped::focus [list [list meta {}] meta {}]
  }
  _rebuild_one_level [list meta {}] meta 0 y
  set bbox [$w.tree bbox all]
  if {$bbox==""} return
  $w.tree config -scrollregion $bbox
  set x2 [lindex $bbox 2]
  incr x2 3
  set oldx2 [$w.tree cget -width]
  if {$x2<$oldx2} {set x2 $oldx2}
  $w.tree config -width $x2
  _edit_proc
}

# This procedure runs when the user clicks on an icon to
# open up a branch of the tree.
#
proc _open_branch {} {
  set id [.ped.tree find withtag current]
  if {$id==""} return
  if {![info exists ::ped::id2info($id)]} return
  foreach {desc type} $::ped::id2info($id) break
  set ::ped::open([list $desc $type]) 1
  set ::ped::focus [list $desc $type $id]
  _rebuild_tree
}

# This procedure runs runs when the user clicks on an icon 
# to close down a branch of the tree.
#
proc _close_branch {} {
  set id [.ped.tree find withtag current]
  if {$id==""} return
  if {![info exists ::ped::id2info($id)]} return
  foreach {desc type} $::ped::id2info($id) break
  catch {unset ::ped::open([list $desc $type])}
  _rebuild_tree
}

# This procedure runs when the user clicks on an icon or name of
# a directory.  It sets the selected directory to the directory chosen.
#
proc _select_branch {} {
  if {[winfo exists .ped.bb.save]} {
    if {[.ped.bb.save cget -state]=="normal"} {
      set r [tk_messageBox -icon question -type yesnocancel -parent .ped \
          -message "You have unsaved changes.  Save them now?" \
          -title "Unsaved changes"]
      if {$r=="cancel"} return
      if {$r=="yes"} {
        _save -silent
      }
    }
  }
  set tw .ped.info
  $tw delete 1.0 end
  set id [.ped.tree find withtag current]
  if {$id==""} return
  if {![info exists ::ped::id2info($id)]} return
  foreach {desc type} $::ped::id2info($id) break
  foreach {root path} $desc break
  foreach {odesc otype oid} $::ped::focus break
  foreach {oroot old} $odesc break
  variable id2icon
  if {[info exists id2icon($oid)]} {
    if {$otype=="ns" || $otype=="meta"} {
      .ped.tree itemconfig $id2icon($oid) -image ::ped::nsclosed
    } elseif {$otype=="vars" && [array exists $old]} {
      .ped.tree itemconfig $id2icon($oid) -image ::ped::aaclosed
    } elseif {$otype=="widgets" && [winfo children $old]!=""} {
      .ped.tree itemconfig $id2icon($oid) -image ::ped::nsclosed
    }
  }
  catch {.ped.tree delete $::ped::focus_id}
  set ::ped::focus [list $desc $type $id]
  if {[info exists id2icon($id)]} {
    if {$type=="ns" || $type=="meta"} {
      .ped.tree itemconfig $id2icon($id) -image ::ped::nsopen
    } elseif {$type=="vars" && [array exists $path]} {
      .ped.tree itemconfig $id2icon($id) -image ::ped::aaopen
    } elseif {$type=="widgets" && [winfo children $path]!=""} {
      .ped.tree itemconfig $id2icon($id) -image ::ped::nsopen
    }
  }
  if {[info exists ::ped::id2txt($id)]} {
    set n $::ped::id2txt($id)
    foreach {x1 y1 x2 y2} [.ped.tree bbox $n] break
    set ::ped::focus_id \
       [.ped.tree create rectangle $x1 $y1 $x2 $y2 -fill skyblue]
    .ped.tree lower $::ped::focus_id
  }
  if {[info exists ::ped::_trace]} {
    trace vdelete $::ped::_trace w ::ped::_changed
    unset ::ped::_trace
  }
  if {$type=="procs"} {
    _edit_proc
  } elseif {$type=="vars"} {
    _edit_var
  } elseif {$type=="widgets"} {
    _edit_widget
  }
}

# Display an editor for the proc of the currently displayed node
#
proc _edit_proc {} {
  foreach {desc type id} $::ped::focus break
  set path [lindex $desc 1]
  if {$type=="ns" || [info proc $path]==""} return

  _save_off .ped.bb.save
  set arglist {}
  foreach arg [info args $path] {
    if {[info default $path $arg dflt]} {
      lappend arglist [list $arg $dflt]
    } else {
      lappend arglist $arg
    }
  }
  set tw .ped.info
  $tw delete 1.0 end
  $tw ins end "proc $path \{$arglist\} \{"
  $tw ins end [info body $path]
  $tw ins end "\}"
  .ped.bb.saveas config -state normal
}

# Display an editor for the variable of the currently displayed node
#
proc _edit_var {} {
  catch {unset ::ped::_edit}
  foreach {desc type id} $::ped::focus break
  set path [lindex $desc 1]
  if {$type!="vars" || [info exists $path]==""} return
  if {[array exists $path]} return

  _save_off .ped.bb.save
  .ped.bb.saveas config -state disabled
  set tw .ped.info
  $tw delete 1.0 end
  if {![info exists $path]} {
    $tw ins end "$path does not exist" err
  } elseif {[catch {set value [set $path]} msg]} {
    $tw ins end "Couldn't get value: $msg" err
  } else {
    $tw ins end $value
  }
  set ::ped::_trace $path
  trace variable $::ped::_trace w ::ped::_changed
  trace variable $::ped::_trace u ::ped::_changed
}

# Display the attributes of the selected widget
#
proc _edit_widget {} {
  foreach {desc type id} $::ped::focus break
  set path [lindex $desc 1]
  set tw .ped.info
  $tw delete 1.0 end
  if {[catch {$path configure} config]} {
    tk_messageBox -icon error -message "Could not find widget $path"
    return
  }
  set opts {}
  set max 0
  lappend title [list Widget: {} {} {} $path]
  lappend title [list ------- {} {} {} ----------]
  set preconf {}
  foreach {name info} {
    Class              class 
    {Colormap Cells}   cells
    Depth              depth
    Geometry           geometry
    Height             height
    ID                 id
    Mapped             ismapped
    {Geometry Manager} manager
    {Requested Height} reqheight
    {Requested Width}  reqwidth
    Viewable           viewable
    Visual             visual
    Width              width
  } {
    lappend preconf [list $name {} {} {} [winfo $info $path]]
  }
  lappend preconf [list {Binding Tags} {} {} {} [bindtags $path]]
  set preconf [lsort -dictionary -index 0 $preconf]
  set sep [list {} {} {} {} {}]
  foreach entry [concat $title $preconf [list $sep] $config] {
    if {[llength $entry]==5} {
      set opt [lindex $entry 0]
      lappend opts $opt [lindex $entry 4]
      set len [string length $opt]
      if {$len>$max} {set max $len}
    }
  }
  incr max 2
  foreach {opt val} $opts {
    regsub -all "\n" $val {\n} val
    $tw ins end [format "%${max}s  %s" $opt $val]\n
  }
}

# This proc is called when the variable named by $::ped:_trace changes
#
proc _changed {args} {
  if {![info exists ::ped::_edit]} {
    set ::ped::_edit [after idle ::ped::_edit_var]
  }
}

# This proc will save the changes for the currently edited proc
#
proc _save {{silent {}}} {
  set tw .ped.info
  foreach {desc type id} $::ped::focus break
  set path [lindex $desc 1]
  set newvalue [$tw get 1.0 end]
  if {$type=="procs"} {
    set pname [lindex $newvalue 1]
    set obody [info body $pname]
    if {[catch {eval $newvalue} msg]} {
      tk_messageBox -icon error -message "Could not save proc: $msg" \
          -parent .ped
    } elseif {$silent!="-silent"} {
      set nbody [info body $pname]
      if {$obody!=$nbody} {
        tk_messageBox -icon info -parent .ped -title Saved \
            -message "Changes to \"$pname\" were saved to your running program."
        _save_off .ped.bb.save
      }
    }
  } elseif {$type=="vars"} {
    set ovalue {}
    catch {set ovalue [set $path]}
    if {[info exists ::ped::_trace]} {
      trace vdelete $::ped::_trace w ::ped::_changed
      unset ::ped::_trace
    }
    if {[catch {
      set $path $newvalue
    } msg]} {
      tk_messageBox -icon error -message "Could not save value: $msg" \
          -parent .ped
    } elseif {$silent!="-silent"} {
      if {$ovalue!=$newvalue} {
        tk_messageBox -icon info -parent .ped -title Saved \
            -message "New value for \"$path\" was saved to\
                      your running program."
        _save_off .ped.bb.save
      }
    }
    set ::ped::_trace $path
    trace variable $::ped::_trace w ::ped::_changed
  }
}

# This proc will pop up a dialog that allows the user to save the
# data in the edit window to an arbitrary file
#
proc _saveas {} {
  set tw .ped.info
  set newproc [$tw get 1.0 end]
  set pname [lindex $newproc 1]
  set types {
    {{Tcl Files}  {.tcl}}
    {{All Files}  *}
  }
  set fn [tk_getSaveFile -filetypes $types -defaultextension .tcl \
      -initialfile *.tcl -parent .ped -title "Save Proc \"$pname\" As"]
  if {$fn!=""} {
     if {[catch {open $fn w} f]} {
        tk_messageBox -icon error -message $f -type ok -parent .ped
        return
     }
     puts $f [$tw get 1.0 end]
     close $f
  }
}

proc _cleanup {} {
  catch {unset ::ped::id2info}
  catch {unset ::ped::id2txt}
  catch {unset ::ped::id2icon}
  set ::ped::focus [list [list meta {}] meta {}]
  set ::ped::focus_id {}
  array unset ::ped::open
}

} ;# End of the ::ped namespace

::ped::create

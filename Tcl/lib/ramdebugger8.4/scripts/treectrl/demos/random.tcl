
set ::RandomN 30
set ::RandomDepth 5

proc PostTreeCheckPath { lst_folders} {
    global PostTree
    set cur_path [ join $lst_folders //]
    set ret ""
    if { [ info exists PostTree(tree_items,$cur_path)]} {
	set ret $PostTree(tree_items,$cur_path)
    }
    return $ret
}

proc PostTreeSavePath { lst_folders item} {
    global PostTree
    set cur_path [ join $lst_folders //]
    set PostTree(tree_items,$cur_path) $item
}

proc GetActualItemBackground { T item colid} {
    set def_bg [ $T cget -background]
    set lst_bg [ $T column cget $colid -itembackground]
    set n [ llength $lst_bg]
    set ret $def_bg
    if { $n >= 1} {
	set idx [ expr $item % $n]
	set ret [ lindex $lst_bg $idx]
	if { $ret == ""} {
	    set ret $def_bg
	}
    }
    return $ret
}

proc PostTreeCreatePath { T path} {
    global PostTree
    set lst_folders [GidUtils::Split $path //]
    set last_parent root
    set state_img(0) on
    set state_img(1) off
    set state_img2(0) post-on
    set state_img2(1) post-off
    set lst_colors [ list red green yellow orange cyan grey blue black orange]
    set n_colors [ llength $lst_colors]
    set n_folders [ llength $lst_folders]
    set i_folder 0
    set cur_path {}
    set idx 0
    set idx_c 0
    foreach folder $lst_folders {

	# create dict info
	lappend cur_path $folder
	
	set item [ PostTreeCheckPath $cur_path]
	incr i_folder
	if { $item == ""} {
	    set item [ $T item create -open no -button auto]
	    set bg [ $T cget -background]
	    
	    # parent
	    $T item lastchild $last_parent $item
	    
	    # configuration
	    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
	    set idx_c [ expr int( 0.5 + rand() * 1317 + $idx_c) % $n_colors]
	    set col [ lindex $lst_colors $idx_c]
	    if { $i_folder < $n_folders} {
		$T item style set $item colItem styFolder 
		$T item element configure $item \
		    colItem elemTxtName -text "$folder" + elemTxtCount -text "(-1-)"
	    } else {
		set f [ frame $T.f$item -borderwidth 0 -width 16 -height 16 \
			    -border 1 -relief flat -background $bg]
		button $f.bColor -image post-blank-color-button-14 -borderwidth 0 \
		    -background $col \
		    -relief flat -command [ list WarnWinDirect SelectColor]
		grid $f.bColor -row 0 -column $idx -padx 0 -pady 0
		$T item style set $item colItem styOnOffColor
		$T item element configure $item \
		    colItem elemImgOnOff -image $state_img2($idx) + \
		        elemFrame -window $f + elemTxtName -text "$folder"
	    }
	    PostTreeSavePath $cur_path $item
	} else {
	    if { $i_folder == $n_folders} {
		# WarnWinDirect "Path '$path' already exists: $item"
		set last_parent ""
		break
	    }
	}
	set last_parent $item
    }
    return $last_parent
}

proc PostTreeToogleOnOff { T item} {
    set act [ $T item element cget $item colItem elemImgOnOff -image]
    set new post-on
    if { $act == "post-on"} {
	set new post-off
    }
    $T item element configure $item colItem elemImgOnOff -image $new
}

proc PostTreeCreateInfoLeaf { T parent txt} {
    set item [ $T item create -open no]
    $T item lastchild $parent $item
    
    $T item style set $item colItem styInfo
    $T item element configure $item \
	colItem elemTxtName -text "$txt"
    return $item
}

proc PostTreeCreateTextLeaf { T parent txt} {
    set item [ $T item create -open no]
    $T item lastchild $parent $item
    
    $T item style set $item colItem styAny
    $T item element configure $item \
	colItem elemTxtAny -text "$txt"
    return $item
}

proc PostTreeCreateStyleLeaf { T parent txt} {
    set item [ $T item create -open no]
    $T item lastchild $parent $item

    $T item style set $item colItem styClosedActionFrame
    set bg [ $T cget -background]
    set f [ frame $T.f$item -borderwidth 0 -background $bg]
    set idx 0
    foreach img [ list bodylines transparent interior cullfrontfaces send_to_back] {
	button $f.b$img -image post-style-$img -borderwidth 0 \
	    -relief flat -background $bg \
	    -width 16 -height 16 -command [ list WarnWinDirect $img]
	grid $f.b$img -row 0 -column $idx -padx 2
	incr idx
    }

    $T item element configure $item colItem elemFrame -window $f
#	$T item element configure $item \
#	    colItem elemTxtName -text "$txt"
    return $item
}

proc PostTreeCreateEdgeWidthLeaf { T parent} {
    set item [ $T item create -open no]
    $T item lastchild $parent $item

    $T item style set $item colItem styClosedActionFrame
    set bg [ $T cget -background]
    set f [ frame $T.f$item -borderwidth 0 -background $bg]

    set ::pp($item,ew) 3
    label $f.lEdgeWidth -text "Edge width:" -background $bg
    entry $f.eEdgeWidth -textvariable ::pp($item,ew) -width 5 -relief sunken -borderwidth 1 \
	-background [ CCColorSombra $bg]
    grid $f.lEdgeWidth $f.eEdgeWidth -padx 2
    $T item element configure $item colItem elemFrame -window $f
    return $item
}

proc PostTreeCreateLeafs { T parent lst_leafs} {
    set last_parent $parent
    set state_img(0) on
    set state_img(1) off
    set idx 0
    PostTreeCreateStyleLeaf $T $last_parent "Define style & co."
    PostTreeCreateEdgeWidthLeaf $T $last_parent

    if { [ llength $lst_leafs] > 1} {
	set num_elems [ expr int( 1.5 + rand() * 100000)]
	set last_parent [ PostTreeCreateInfoLeaf $T $last_parent "Elements $num_elems"]
	foreach leaf $lst_leafs {
	    # set item [ $T item create -open no]
	    # 
	    # # parent
	    # $T item lastchild $last_parent $item
	    # set last_parent $item
	    
	    # configuration
	    # set idx_on_off [ expr $idx % 2]
	    # incr idx
	    # $T item style set $item colItem styFile colParent styAny colDepth styAny colOnOff styAny
	    # $T item element configure $item \
	    #     colItem elemTxtName -text "$leaf" , \
	    #     colParent elemTxtAny -text "[$T item parent $item]" , \
	    #     colDepth elemTxtAny -text "[$T depth $item]"
	    # , \	# 
	    #	#     colOnOff elemImgAny -image $state_img($idx_on_off)
	    # 
	    # # create two leafs: 
	    # # 1. frame with icons for displaystyle transparency interior ...
	    # # 2. info of number of elements...
	    set num_elems [ expr int( 1.5 + rand() * 100000)]
	    set dimension [ expr int( 1.5 + rand() * 100)]
	    set txt "${leaf}: ${num_elems}, dimension = ${dimension}"
	    PostTreeCreateTextLeaf $T $last_parent $txt
	}
    } else {
	set num_elems [ expr int( 1.5 + rand() * 100000)]
	set dimension [ expr int( 1.5 + rand() * 100)]
	set leaf [ lindex $lst_leafs 0]
	set txt "${leaf}: ${num_elems}, dimension = ${dimension}"
	PostTreeCreateInfoLeaf $T $last_parent $txt
    }
}

proc PostTreeCreatePreprocessSubtree { T parent } {
    set last_parent $parent

    set state_img2(0) post-on
    set state_img2(1) post-off
    set idx 0
    
    set item [ $T item create -open no -button yes]    
    # parent
    $T item lastchild $last_parent $item
    $T item style set $item colItem styFolder
    $T item element configure $item colItem elemTxtName -text "Preprocess"

    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    set last_parent $item
    set item [ $T item create -open no -button no]    
    $T item lastchild $last_parent $item
    $T item style set $item colItem styOnOff
    $T item element configure $item colItem elemImgOnOff -image $state_img2($idx) + \
	elemTxtName -text "Geometry"

    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    set item [ $T item create -open no -button no]    
    $T item lastchild $last_parent $item
    $T item style set $item colItem styOnOff
    $T item element configure $item colItem elemImgOnOff -image $state_img2($idx) + \
	elemTxtName -text "Mesh"

    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    set item [ $T item create -open no -button yes]    
    $T item lastchild $last_parent $item
    $T item style set $item colItem styActionFolder
    $T item element configure $item colItem elemTxtName -text "Conditions"

    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    set cond_parent $item
    set item [ $T item create -open no -button no]    
    $T item lastchild $cond_parent $item
    $T item style set $item colItem styOnOff
    $T item element configure $item colItem elemImgOnOff -image $state_img2($idx) + \
	elemTxtName -text "on Geometry"

    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    set item [ $T item create -open no -button no]    
    $T item lastchild $cond_parent $item
    $T item style set $item colItem styOnOff
    $T item element configure $item colItem elemImgOnOff -image $state_img2($idx) + \
	elemTxtName -text "on Mesh"

    # try one: tk button
    set item [ $T item create -open no -button no]    
    $T item lastchild $last_parent $item
    $T item style set $item colItem styClosedActionFrame

    set bg [ $T cget -background]
    set f [ frame $T.f$item -borderwidth 0 -background grey30]
    # ttk::button $f.bColor -text "Layers window" \
    # 	-command [ list WarnWinDirect "Open layers window"]
    button $f.bColor -text "Layers window" \
	-command [ list WarnWinDirect "Open layers window"] \
	-pady 0 -borderwidth 0
    grid $f.bColor -row 0 -column 0 -padx 1 -pady 1
    $T item element configure $item colItem elemFrame -window $f

    # try two: ttk button
    set item [ $T item create -open no -button no]    
    $T item lastchild $last_parent $item
    $T item style set $item colItem styClosedActionFrame
    set bg [ $T cget -background]
    set f [ frame $T.f$item -borderwidth 0 -background $bg]
    ttk::button $f.bColor -text "Layers window" \
    	-command [ list WarnWinDirect "Open layers window"]
    grid $f.bColor -row 0 -column 0 -padx 0 -pady 0
    $T item element configure $item colItem elemFrame -window $f


    set item [ $T item create -open no -button no]
    set idx [ expr int( 0.5 + rand() * 1317 + $idx) % 2]
    $T item lastchild $last_parent $item
    $T item style set $item colItem styOnOff
    $T item element configure $item colItem elemImgOnOff -image $state_img2($idx) + \
	elemTxtName -text "Geometry"

}
# -np- source $::GIDDEFAULTTCL/treectrl/demos/demo.tcl


#
# Demo: random N items
#
proc DemoRandom {} {

    set T [DemoList]

    InitPics folder-* on off on-off post-*

    set height [font metrics [$T cget -font] -linespace]
    if {$height < 18} {
	set height 18
    }
	# set height 24
    WarnWinText "Height for rows = $height"

    #
    # Configure the treectrl widget
    #

#	-showroot yes -showrootbutton yes -showbuttons yes 
# -itemheight $height
    $T configure  -selectmode extended \
	-showroot yes -showrootbutton no -showbuttons yes \
	-showlines [ShouldShowLines $T] -linestyle solid \
	-scrollmargin 16 -xscrolldelay "500 50" -yscrolldelay "500 50"

    #
    # Create columns
    #

    $T column create -expand yes -weight 4 -text Item -itembackground {#e0e8f0 {}} \
	-tags colItem
    $T column create -text Parent -justify center -itembackground {gray90 {}} \
	-uniform a -expand yes -tags colParent
    $T column create -text Depth -justify center -itembackground {linen {}} \
	-uniform a -expand yes -tags colDepth
    $T column create -text OnOff -justify center -itembackground {linen {}} \
	-uniform a -expand yes -tags colOnOff

    $T configure -treecolumn colItem

    #
    # Create elements
    #

    # $T element create elemImgFolder image -image {post-folder-open {open} post-folder-closed {}}
    $T element create elemImgFolder image -image {folder-open {open} folder-closed {}}
    $T element create elemImgFile image -image post-small-file
    $T element create elemImgInfo image -image post-info
    $T element create elemImgAction image -image {post-action-open {open} post-action-closed {}} 
    $T element create elemImgClosedAction image -image post-action-closed
    $T element create elemTxtName text -wrap none \
	    -fill [list $::SystemHighlightText {selected focus}]
    $T element create elemTxtCount text -fill blue
    $T element create elemTxtAny text
    $T element create elemRectSel rect -showfocus yes \
	-fill [list $::SystemHighlight {selected focus} gray {selected !focus}]
    $T element create elemImgAny image
    $T element create elemFrame window
    $T element create elemImgOnOff image -image {post-on {} post-off {}}

    #
    # Create styles using the elements
    #

    set S [$T style create styFolder]
    # $T style elements $S {elemRectSel elemImgFolder elemTxtName elemTxtCount}
    $T style elements $S {elemRectSel elemTxtName elemTxtCount}
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemTxtCount -padx {0 6} -expand ns -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2
    # $T style layout $S elemImgFolder -padx {0 4} -expand ns

    set S [$T style create styFile]
    $T style elements $S {elemRectSel elemImgFile elemTxtName elemFrame}
    $T style layout $S elemImgFile -padx {0 4} -expand ns
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2
    $T style layout $S elemFrame -padx {0 4} -expand ns -height $height

    set S [$T style create styOnOffColor]
    # $T style elements $S {elemRectSel elemImgAction elemImgOnOff elemTxtName elemFrame}
    $T style elements $S {elemRectSel elemImgOnOff elemFrame elemTxtName}
    # $T style layout $S elemImgAction -padx {0 4} -expand ns
    $T style layout $S elemImgOnOff -padx {4 0} -expand ns
    $T style layout $S elemFrame -padx {2 2} -expand ns -height $height
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2

    set S [$T style create styActionFolder]
    $T style elements $S {elemRectSel elemImgAction elemTxtName}
    $T style layout $S elemImgAction -padx {0 4} -expand ns
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2

    set S [$T style create styActionOnOffFolder]
    $T style elements $S {elemRectSel elemImgAction elemImgOnOff elemTxtName}
    $T style layout $S elemImgAction -padx {0 4} -expand ns
    $T style layout $S elemImgOnOff -padx {4 0} -expand ns
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2

    set S [$T style create styInfo]
    $T style elements $S {elemRectSel elemImgInfo elemTxtName}
    $T style layout $S elemImgInfo -padx {0 4} -expand ns
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2

    set S [$T style create styOnOff]
    $T style elements $S {elemRectSel elemImgOnOff elemTxtName}
    $T style layout $S elemImgOnOff -padx {0 4} -expand ns
    $T style layout $S elemTxtName -minwidth 12 -padx {0 4} -expand ns -squeeze x -height $height
    $T style layout $S elemRectSel -union [list elemTxtName] -iexpand ns -ipadx 2

    set S [$T style create styAny]
    $T style elements $S {elemTxtAny elemImgAny}
    $T style layout $S elemTxtAny -padx 6 -expand ns -height $height
    $T style layout $S elemImgAny -padx {0 4} -expand ns

    set S [$T style create styClosedActionFrame]
    # $T style elements $S {eRectBottom eWindow}
    # $T style layout $S eRectBottom -detach yes -indent no -iexpand xy
    # $T style layout $S eWindow -iexpand x -squeeze x -padx {0 2} -pady {0 8}
    # $T style elements $S {elemImgAction elemFrame}
    # $T style layout $S elemImgAction -padx {0 4} -expand ns
    $T style elements $S {elemImgClosedAction elemFrame}
    $T style layout $S elemImgClosedAction -padx {0 4} -expand ns
    $T style layout $S elemFrame -padx {0 4} -expand ns 
#-minheight 24
# -iexpand x -squeeze x -padx {0 2} -pady {0 8}
    # $T style layout $S elemFrame -iexpand x -squeeze x -padx {0 2} -pady {0 8}

    TreeCtrl::SetSensitive $T {
	{colItem styFolder elemRectSel elemImgFolder elemTxtName}
	{colItem styFile elemRectSel elemImgFile elemTxtName}
    }
    TreeCtrl::SetDragImage $T {
	{colItem styFolder elemImgFolder elemTxtName}
	{colItem styFile elemImgFile elemTxtName}
    }

    #
    # Create items and assign styles
    #

    TimerStart
    $T item configure root -button auto
    set items [$T item create -count [expr {$::RandomN - 1}] -button auto]
    set added root
    foreach itemi $items {
	set j [expr {int(rand() * [llength $added])}]
	set itemj [lindex $added $j]
	if {[$T depth $itemj] < $::RandomDepth - 1} {
	    lappend added $itemi
	}
	if {rand() * 2 > 1} {
	    $T item collapse $itemi
	}
	if {rand() * 2 > 1} {
	    $T item lastchild $itemj $itemi
	} else {
	    $T item firstchild $itemj $itemi
	}
    }
    WarnWinText "created $::RandomN-1 items in [TimerStop] seconds"

    TimerStart
    lappend items [$T item id root]
    foreach item $items {
	set numChildren [$T item numchildren $item]
	set is_on [ expr int( rand() + 0.5)]
	set state_img off
	if { $is_on} {
	    set state_img on
	}
	if {$numChildren} {
	    $T item style set $item colItem styFolder colParent styAny colDepth styAny colOnOff styAny
	    $T item element configure $item \
		colItem elemTxtName -text "Item $item" + elemTxtCount -text "($numChildren)" , \
		colParent elemTxtAny -text "[$T item parent $item]" , \
		colDepth elemTxtAny -text "[$T depth $item]" , \
		colOnOff elemImgAny -image on-off
	} else {
	    $T item style set $item colItem styFile colParent styAny colDepth styAny colOnOff styAny
	    $T item element configure $item \
		colItem elemTxtName -text "Item $item" , \
		colParent elemTxtAny -text "[$T item parent $item]" , \
		colDepth elemTxtAny -text "[$T depth $item]" , \
		colOnOff elemImgAny -image $state_img
	}
    }

    set path [ PostTreeCreatePath $T MyMesh]
    PostTreeCreateLeafs $T $path [ list Lines Triangles Tetrahedra]
    set path [ PostTreeCreatePath $T MyExample//Mesh]
    PostTreeCreateLeafs $T $path [ list Spheres Hexahedra Points]
    set path [ PostTreeCreatePath $T "MyExample//Mesh 2"]
    PostTreeCreateLeafs $T $path [ list Spheres Hexahedra Points]
    set path [ PostTreeCreatePath $T "MyExample//Mesh 2"]
    if { $path != ""} {
	PostTreeCreateLeafs $T $path [ list Spheres Hexahedra Points]
    }
    set path [ PostTreeCreatePath $T "Body 1"]
    PostTreeCreateLeafs $T $path [ list Tetrahedra]
    set path [ PostTreeCreatePath $T "Body 2"]
    PostTreeCreateLeafs $T $path [ list Tetrahedra]
    set path [ PostTreeCreatePath $T "Boundary"]
    PostTreeCreateLeafs $T $path [ list Triangles]
    set path [ PostTreeCreatePath $T "Shell"]
    PostTreeCreateLeafs $T $path [ list Triangles]

    PostTreeCreatePreprocessSubtree $T root
    WarnWinText "configured $::RandomN items in [TimerStop] seconds"

    bind DemoRandom <Double-ButtonPress-1> {
	RandomDoubleButton1 %W %x %y
	# TreeCtrl::DoubleButton1 %W %x %y
	break
    }
    bind DemoRandom <Control-ButtonPress-1> {
	set TreeCtrl::Priv(selectMode) toggle
	RandomButton1 %W %x %y
	break
    }
    bind DemoRandom <Shift-ButtonPress-1> {
	set TreeCtrl::Priv(selectMode) add
	RandomButton1 %W %x %y
	break
    }
    bind DemoRandom <ButtonPress-1> {
	set TreeCtrl::Priv(selectMode) set
	RandomButton1 %W %x %y
	break
    }
    bind DemoRandom <Button1-Motion> {
	RandomMotion1 %W %x %y
	break
    }
    bind DemoRandom <ButtonRelease-1> {
	RandomRelease1 %W %x %y
	break
    }

    bindtags $T [list $T DemoRandom TreeCtrl [winfo toplevel $T] all]

    return
}

# -np- source $::GIDDEFAULTTCL/treectrl/demos/demo.tcl

proc RandomToogleCollapse { T item} {
    set is_open [ $T item isopen $item]
    set new_state expand
    if { $is_open} {
	set new_state collapse
    }
    $T item $new_state $item
}

proc RandomDoubleButton1 {T x y} {
    variable TreeCtrl::Priv
    focus $T
    set id [$T identify $x $y]
    set Priv(buttonMode) ""

    if {$id eq ""} {
	# $T selection clear
	TreeCtrl::DoubleButton1 $T $x $y

    # Click in header
    } elseif {[lindex $id 0] eq "header"} {
	# TreeCtrl::ButtonPress1 $T $x $y
	TreeCtrl::DoubleButton1 $T $x $y

    # Click in item
    } else {
	lassign $id where item arg1 arg2 arg3 arg4
	switch $arg1 {
	    button {
		TreeCtrl::DoubleButton1 $T $x $y
	    }
	    line {
		TreeCtrl::DoubleButton1 $T $x $y
	    }
	    column {
		# elemImgOnOff is used to turn mesh on or off
		# so do not confuse the user by open folder by double-click
		if { $arg4 != "elemImgOnOff"} {
		    if { $arg2 == "0"} {
			# column with name ...
			RandomToogleCollapse $T $item
		    } else {
			TreeCtrl::DoubleButton1 $T $x $y
		    }
		}
	    }
	}
    }

    # TreeCtrl::DoubleButton1 $T $x $y
}

proc RandomButton1 {T x y} {
    variable TreeCtrl::Priv
    focus $T
    set id [$T identify $x $y]
    set Priv(buttonMode) ""

WarnWinText "$T $x $y --> $id"

    # Click outside any item
    if {$id eq ""} {
	$T selection clear

    # Click in header
    } elseif {[lindex $id 0] eq "header"} {
	TreeCtrl::ButtonPress1 $T $x $y

    # Click in item
    } else {
	#           item   37 column 0   elem elemImgOnOff
	lassign $id where item arg1 arg2 arg3 arg4
	switch $arg1 {
	    button {
		TreeCtrl::ButtonPress1 $T $x $y
	    }
	    line {
		TreeCtrl::ButtonPress1 $T $x $y
	    }
	    column {
		# # may confuse the user because it disables the selection
		# if { ( $arg2 == "0") && ( [ $T item numchildren $item] != 0)} {
		#     # column with name ...
		#     RandomToogleCollapse $T $item
		# } else {

		    if { $arg4 == "elemImgOnOff"} {
			PostTreeToogleOnOff $T $item
		    }

		    if {![TreeCtrl::IsSensitive $T $x $y]} {
			$T selection clear
			return
		    }
		    
		    set Priv(drag,motion) 0
		    set Priv(drag,click,x) $x
		    set Priv(drag,click,y) $y
		    set Priv(drag,x) [$T canvasx $x]
		    set Priv(drag,y) [$T canvasy $y]
		    set Priv(drop) ""
		    
		    if {$Priv(selectMode) eq "add"} {
			TreeCtrl::BeginExtend $T $item
		    } elseif {$Priv(selectMode) eq "toggle"} {
			TreeCtrl::BeginToggle $T $item
		    } elseif {![$T selection includes $item]} {
			TreeCtrl::BeginSelect $T $item
		    }
		    $T activate $item
		    
		    if {[$T selection includes $item]} {
			set Priv(buttonMode) drag
		    }
		# }
	    }
	}
    }
    return
}

proc RandomMotion1 {T x y} {
    variable TreeCtrl::Priv
    if {![info exists Priv(buttonMode)]} return
    switch $Priv(buttonMode) {
	"drag" {
	    set Priv(autoscan,command,$T) {RandomMotion %T %x %y}
	    TreeCtrl::AutoScanCheck $T $x $y
	    RandomMotion $T $x $y
	}
	default {
	    TreeCtrl::Motion1 $T $x $y
	}
    }
    return
}

proc RandomMotion {T x y} {
    variable TreeCtrl::Priv
    switch $Priv(buttonMode) {
	"drag" {
	    if {!$Priv(drag,motion)} {
		# Detect initial mouse movement
		if {(abs($x - $Priv(drag,click,x)) <= 4) &&
		    (abs($y - $Priv(drag,click,y)) <= 4)} return

		set Priv(selection) [$T selection get]
		set Priv(drop) ""
		$T dragimage clear
		# For each selected item, add 2nd and 3rd elements of
		# column "item" to the dragimage
		foreach I $Priv(selection) {
		    foreach list $Priv(dragimage,$T) {
			set C [lindex $list 0]
			set S [lindex $list 1]
			if {[$T item style set $I $C] eq $S} {
			    eval $T dragimage add $I $C [lrange $list 2 end]
			}
		    }
		}
		set Priv(drag,motion) 1
	    }

	    # Find the item under the cursor
	    set cursor X_cursor
	    set drop ""
	    set id [$T identify $x $y]
	    if {[TreeCtrl::IsSensitive $T $x $y]} {
		set item [lindex $id 1]
		# If the item is not in the pre-drag selection
		# (i.e. not being dragged) see if we can drop on it
		if {[lsearch -exact $Priv(selection) $item] == -1} {
		    set drop $item
		    # We can drop if dragged item isn't an ancestor
		    foreach item2 $Priv(selection) {
			if {[$T item isancestor $item2 $item]} {
			    set drop ""
			    break
			}
		    }
		    if {$drop ne ""} {
			scan [$T item bbox $drop] "%d %d %d %d" x1 y1 x2 y2
			if {$y < $y1 + 3} {
			    set cursor top_side
			    set Priv(drop,pos) prevsibling
			} elseif {$y >= $y2 - 3} {
			    set cursor bottom_side
			    set Priv(drop,pos) nextsibling
			} else {
			    set cursor ""
			    set Priv(drop,pos) lastchild
			}
		    }
		}
	    }

	    if {[$T cget -cursor] ne $cursor} {
		$T configure -cursor $cursor
	    }

	    # Select the item under the cursor (if any) and deselect
	    # the previous drop-item (if any)
	    $T selection modify $drop $Priv(drop)
	    set Priv(drop) $drop

	    # Show the dragimage in its new position
	    set x [expr {[$T canvasx $x] - $Priv(drag,x)}]
	    set y [expr {[$T canvasy $y] - $Priv(drag,y)}]
	    $T dragimage offset $x $y
	    $T dragimage configure -visible yes
	}
	default {
	    TreeCtrl::Motion1 $T $x $y
	}
    }
    return
}

proc RandomRelease1 {T x y} {
    variable TreeCtrl::Priv
    if {![info exists Priv(buttonMode)]} return
    switch $Priv(buttonMode) {
	"drag" {
	    TreeCtrl::AutoScanCancel $T
	    $T dragimage configure -visible no
	    $T selection modify {} $Priv(drop)
	    $T configure -cursor ""
	    if {$Priv(drop) ne ""} {
		RandomDrop $T $Priv(drop) $Priv(selection) $Priv(drop,pos)
	    }
	    unset Priv(buttonMode)
	}
	default {
	    TreeCtrl::Release1 $T $x $y
	}
    }
    return
}

proc RandomDrop {T target source pos} {
    set parentList {}
    switch -- $pos {
	lastchild { set parent $target }
	prevsibling { set parent [$T item parent $target] }
	nextsibling { set parent [$T item parent $target] }
    }
    foreach item $source {

	# Ignore any item whose ancestor is also selected
	set ignore 0
	foreach ancestor [$T item ancestors $item] {
	    if {[lsearch -exact $source $ancestor] != -1} {
		set ignore 1
		break
	    }
	}
	if {$ignore} continue

	# Update the old parent of this moved item later
	if {[lsearch -exact $parentList $item] == -1} {
	    lappend parentList [$T item parent $item]
	}

	# Add to target
	$T item $pos $target $item

	# Update text: parent
	$T item element configure $item colParent elemTxtAny -text $parent

	# Update text: depth
	$T item element configure $item colDepth elemTxtAny -text [$T depth $item]

	# Recursively update text: depth
	foreach item [$T item descendants $item] {
	    $T item element configure $item colDepth elemTxtAny -text [$T depth $item]
	}
    }

    # Update items that lost some children
    foreach item $parentList {
	set numChildren [$T item numchildren $item]
	if {$numChildren == 0} {
	    $T item style map $item colItem styFile {elemTxtName elemTxtName}
	} else {
	    $T item element configure $item colItem elemTxtCount -text "($numChildren)"
	}
    }

    # Update the target that gained some children
    if {[$T item style set $parent colItem] ne "styFolder"} {
	$T item style map $parent colItem styFolder {elemTxtName elemTxtName}
    }
    set numChildren [$T item numchildren $parent]
    $T item element configure $parent colItem elemTxtCount -text "($numChildren)"
    return
}

#
# Demo: random N items, button images
#
proc DemoRandom2 {} {

    set T [DemoList]

    DemoRandom

    InitPics mac-*

    $T configure -buttonimage {mac-collapse open mac-expand {}} \
	-showlines no

    return
}


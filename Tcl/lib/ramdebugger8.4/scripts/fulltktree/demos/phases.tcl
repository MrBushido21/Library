
package require fulltktree
package require compass_utils

image create photo forward-16 -data {
R0lGODlhEAAQAPZjADpzBDp0BDp0BTt0BDt1BDt2BDx2BDx4BEB5CkJ6DkN6
EEZ8FE2EGE6aBk+cBlOLHlaJJlmMKl6PMF+PMVKgB1SkCFenCVqsC1uuC16z
DV+yDmG3DmK5DmS8D2S6EWa4F2a/EGy6H2y/HGipK2usL2qhNm6sM2+6JnGm
PnSvO3i2PX/LNIGrWoKrWoC+RIK+SYW5VIi7WIu7XYu8W4u9XIy+XITCSYjE
TYnDUIrCVY3GVYvBWIzDWI3CWo3BXJLTUo/BYZHBZJnEb5vKbZzDep3Ic57J
dpzSZ6PKfqTMfqDVbKXXc6bTe6fRf6jaeKTGhKrOiarVgavWgavXga/UjLHS
kbfUnLnXnLvZn73Zo8Dbp8LcqsPcq8Xdrcber8fesMvgtsvht87ju////8zM
zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAGQA
LAAAAAAQABAAAAedgGSCggQAg4eIggARAYaJiABhLY2PhwBiXE8KjoONAJ8F
YEJVVhMDnABaW11eX19BQEVYLAKOAFkwMTM0NT49OTxURAuGAFcpJiMkKi84
NzYuQ1AShUgN1xQWGBofISc6RhDV1w4VFxkcHSJHMgnFSPBJTVEbICtOKAWO
np8HUh4/ljwwwAnSFCU7EASopIhJCYIMFTHQF5FQQUSBAAA7
}

image create photo list-add-16 -data {
R0lGODlhEAAQAPQAAAAAADRlpH2m13+o14Oq2Iat2ZCz2pK02pS225W325++
4LTM5bXM5rbM5rbN5rfO5rvR57zR58DT6MzMzAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAABMALAAAAAAQABAAAAU94CSOZGme
qBisQToGz9O6EyzTdTyb7Kr3pIAEEonFHIzGrrZIIA6GAmEgUCx7gUIBi4Jt
cd5lVwdm4c7nEAA7
}


# width name justify type is_editable
set cols {
    { 6 state left text 1 }
    { 8 name  left text 1 }
    { 18 time left text 0 }
}

cu::init_tile_styles
set err [catch {  package require pixane }]
if { $err } {
    package require img::png
}

fulltktree .t -columns $cols -width 300 -showlines 0 -indent 0 -selectmode extended \
    -sensitive_cols all -showbuttons 0 \
    -contextualhandler_menu contextual
pack .t -fill both -expand 0

ttk::button .b -text Dump -command [list dump .t]
pack .b -pady 5

.t style layout window e_window -sticky w -iexpand "" -expand e -detach 1
#-iexpand xy -sticky nsew -squeeze xy -padx 0 -pady 1

set data {
    forward-16 name1 2008-01-01
    forward-16 name2 2008-01-01
    list-add-16 name3 2008-01-01
}

set idx 0
foreach "icon name date" $data {
    set item [.t insert end [list "" $name $date]]
    
    menubutton .t.m$idx -image $icon -menu .t.m$idx.m \
	-relief flat -bd 1 -highlightthickness 0 \
	-background white -foreground blue -activeforeground red \
	-width 16
    menu .t.m$idx.m -tearoff 0
    .t.m$idx.m add command -label forward-16 -command [list change .t $item forward-16]
    .t.m$idx.m add command -label list-add-16 -command [list change .t $item list-add-16]
    
    .t item style set $item 0 window
    .t item element configure $item 0 e_window -window .t.m$idx
    .t configure -itemheight 22
    incr idx
}

proc change { tree itemList icon } {
    foreach item $itemList {
	set mb [$tree item element cget $item 0 e_window -window]
	$mb configure -image $icon
    }
}

proc contextual { tree menu item selection } {

    foreach icon [list forward-16 list-add-16] {
	$menu add command -label $icon -command [list change $tree $selection $icon]
    }
}

proc dump { tree } {
    console show
    foreach item [$tree item children 0] {
	set mb [$tree item element cget $item 0 e_window -window]
	set icon [$mb cget -image]
	puts "$icon [$tree item text $item 1]"
    }
}


















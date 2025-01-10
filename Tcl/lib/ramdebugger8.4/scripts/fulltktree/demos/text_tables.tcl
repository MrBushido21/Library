
if 0 {
    set auto_path [linsert $auto_path 0 E:/GiD/scripts]
    package require -exact treectrl 1.1
}
package require fulltktree

catch { console show }

# width name justify type is_editable
set cols {
    { 15 item left item 1 }
    { 8 size right imagetext 1 }
    { 18 mdate left text 0 }
}

package require img::png

fulltktree .t -columns $cols -width 300
pack .t -fill both -expand 0

.t configure \
    -selecthandler "logdata select" \
    -selecthandler2 "logdata select2" \
    -editaccepthandler "logdata editaccept" \
    -deletehandler "logdata deletehandler" \
    -draghandler "logdata drag" \
    -compass_background 1 -showlines 0 \
    -showbuttons 0

proc logdata { args } {
    puts "logdata: $args"
}


set data {
    { pepet 1024 "2006-12-01 13:14:12" 0 }
    { cacat 1024 "2006-12-01 13:14:12" 0 }
    { cucut 1024 "2006-12-01 13:14:12" 0 }
    { hola 1024 "2006-12-01 13:14:12" 0 }
    { adeu 1024 "2006-12-01 13:14:12" 0 }
    { jaja 1024 "2006-12-01 13:14:12" 0 }
}
foreach i $data {
    foreach "name size mdate" [lrange $i 0 2] break
    set size [list appbook16 $size]
    .t insert end [list $name $size $mdate] [lindex $i 3]
}

text .t.text -height 4

set item [.t item create]
.t item style set $item 0 window
.t item element configure $item 0 e_window -window .t.text
.t item lastchild 0 $item


.t insert end [list a "appbook16 b" c] 0

















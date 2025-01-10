::set dos {
@set PATH=C:\Tcl\bin;%PATH%
@start wish86t.exe %0 %*
@exit
}

lappend auto_path {C:\Tcl\lib\inspector1.0}
source {C:\Tcl\lib\inspector1.0\inspector\inspector.tcl}
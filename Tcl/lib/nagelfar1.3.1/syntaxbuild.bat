::set dos {
@set PATH=C:\Tcl\bin;%PATH%
@tclsh86.exe %0 %*
@exit
}
::unset dos
source syntaxbuild.tcl 
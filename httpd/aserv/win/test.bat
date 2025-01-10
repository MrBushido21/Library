@echo off
set path=..\..\..\bin;%path%

if exist %0.out del %0.out
tclsh ..\test\all.tcl -verbose bpse -outfile %0.out %1 %2 %3 %4 %5 %6 %7 %8 %9  2> %0.err 
rem tee %0.log
rem type %0.out

package require gid_helpviewer
package provide helpviewer 1.4

#try to supply the commands used by ramdebugger of the package helpviewer with the package gid_helpviewer
namespace eval HelpViewer {
}

proc HelpViewer::HelpWindow { file { base .help} { geom "" } { title "" } { tocfile "" } } {	
    set w .help
    GiDHelpViewer::Show $file -title $title -try "" -report 0 -base $w -tab tree
}

proc HelpViewer::HelpSearchWord { word } {
    set w .help
    GiDHelpViewer::HelpSearchWord  $w $word
}

proc HelpViewer::EnterDirForIndex { dir } {
    #set w .help   
    #set ::GiDHelpViewer::HelpBaseDir($w) $dir
}

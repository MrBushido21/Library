#

namespace eval ::repository::sys {
    variable activestate {}
}

proc ::repository::sys::activestate {} {
    variable activestate
    return  $activestate
}

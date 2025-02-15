# This script is intended to be run in a Tcl interpreter to extract
# information for the Nagelfar syntax checker.
#
# This file contains hardcoded syntax info for many commands that it
# adds to the resulting syntax database, plus it tries to extract info
# from the interpreter about things like subcommands.

if 0 {
    # Example how to pick up other information
    lappend ::auto_path /usr/share/tcltk
    catch {package require uuid}
    set syntax(uuid::uuid) "s x*"
}

# Autoload stuff to have them available
catch {parray} ; catch {tk_dialog} ; catch {package require msgcat}
foreach gurkmeja [array names auto_index] {
    if {[info procs $gurkmeja] == ""} {
        catch {eval $auto_index($gurkmeja)}
    }
}
if {[info exists gurkmeja]} {
    unset gurkmeja
}
# Remove this that might leak in from package install
catch {rename tkpath::load_package {}}


# First get some data about the system

set ::kG [lsort [info globals]]
set ::kC [info commands]
set ::kP [list msgcat Tcl]

foreach pat {{tcl::[a-z]*}} {
    foreach p [info commands $pat] {
        if {[string match ::* $p]} {
            set p [string range $p 2 end]
        }
        lappend ::kC $p
    }
}

# Collect exported namespace commands
if 1 { # Not working yet?
    set todo [namespace children ::]
    while {[llength $todo] > 0} {
        set ns [lindex $todo 0]
        set todo [lrange $todo 1 end]
        # Do not recurse in these namespaces
        if {[lsearch {::oo} $ns] < 0} {
            eval lappend todo [namespace children $ns]
        }

        set exports [namespace eval $ns {namespace export}]
        if {[llength $exports] == 0} {
            # Assume lowercase-convention for public commands
            set exports [list {[a-z]*}]
        }
        if {[info exists ::syntaxbuild_allnamespace]} {
            set exports [list *]
        }
        foreach pat $exports {
            foreach p [info commands ${ns}::$pat] {
                # Do not include the first :: in the name
                if {[string match ::* $p]} {
                    set p [string range $p 2 end]
                }
                lappend ::kC $p
            }
        }
    }
}

# Function to get an option or subcommand list from an error message.
proc getSubCmds {args} {
    catch {uplevel 1 $args} err

    # Some commands show their available options in this message
    if {[regexp "wrong \# args:" $err]} {
        #puts "$args"
        #puts "  $err"
        set result {}
        foreach {_ x} [regexp -all -inline {\?(-\w+)} $err] {
            lappend result $x
        }
        #puts "  $result"
        return $result
    }        

    lappend regexps {option .* must be (.*)$}
    lappend regexps {option .* should be one of (.*)$}
    lappend regexps {bad .* must be (.*)$}
    lappend regexps {: must be (.*)$}
    lappend regexps {: should be (.*)$}

    foreach re $regexps {
	if {[regexp $re $err -> apa]} {
	    regsub -all {( or )|(, or )|(, )} $apa " " apa
	    return [lsort -dictionary [lrange $apa 0 end]]
	}
    }
    #puts "Error '$err' from '$args'"
    return {}
}

# Create a syntax description for a procedure
proc createSyntax {procName} {
    set args [info args $procName]

    set min 0
    set unlim 0

    if {[lindex $args end] == "args"} {
        set unlim 1
    }
    set i 1
    foreach a $args {
	if {$a != "args"} {
            if {![info default $procName $a dummy]} {
                set min $i
            }
        }
        incr i
    }
    if {$unlim} {
        set result "r $min"
    } elseif {$min == [llength $args]} {
        set result $min
    } else {
        set result [list r $min [llength $args]]
    }
    return $result
}

proc markCmdAsKnown {args} {
    foreach cmd $args {
        if {[lsearch $::kC $cmd] == -1} {
            lappend ::kC $cmd
        }
    }
}

# Build a syntax database and write it to a channel
proc buildDb {ch} {
    # Allow predefined info to be provided from outside
    array set syntax [array get ::syntax]
    array set getSubCmd [array get ::getSubCmd]

    set patch [info patchlevel]
    set ver   [package present Tcl]

    puts $ch "# Automatically generated syntax database."
    puts $ch ""

    set useTk [expr {![catch {package present Tk}]}]
    set dbstring "Tcl $patch $::tcl_platform(platform)"
    if {$useTk} {
        append dbstring ", Tk $::tk_patchLevel"
        if {![catch {tk windowingsystem}]} {
            append dbstring " [tk windowingsystem]"
        }
        lappend ::kP Tk
    }

    # Below is the hardcoded syntax for many core commands.
    # It is defined using the "language" below.
    # TODO: Add all core commands.

    # An entry should be a valid list of tokens as described below.

    # If the first token ends with : it means that there are different
    # syntax descriptions for different number of arguments.
    # Any token ending with : starts a syntax for the number of arguments
    # that the number preceding it says. A lone : starts the default syntax.
    # Example "1: x 2: n n : e x*"

    # If a token is an integer, just check the number of arguments against it.
    # r min ?max?  Specifies a range for number of arguments

    # The following token names are recognised. A token name is alphabetic
    # and may be mixed case. A token may cover and consume multiple arguments.
    # x   Any
    # o   Option, i.e anything starting with -.
    #     An option may consume a second arg if the option database says so.
    # p   Option+Any i.e. (o x) (p as in option Pair)
    # s   Subcommand
    # d*  Definitions. That arg defines a new command, as detailed below
    # di  Define inheritance
    # dc  Define with copy, if followed by =cmd, it copies syntax from cmd.
    # do  Define object, if followed by =cmd, it copies syntax from cmd.
    # dk  Define constructor (args+body)
    # dd  Define destructor (just body)
    # dp  Define procedure (name+args+body)
    # dm  Define method (name+args+body)
    # dmp Define metod/procedure (name+args+body)
    # div Define implicit variable
    # e   Expression
    # E   Expression that should be in braces
    # re  regexp
    # c   Code, checked in surrounding context
    #     If an integer is added to it, that number of arguments are added to
    #     the code to emulate a command prefix. (cg has this too)
    # cg  Code, checked in global context
    # cn  Code, checked in virtual namespace
    # cl  Code, checked in its own local context
    # cv  Code, checked in its own local context, preceded by variable list
    #     n, v and l all marks variable names. Those arguments will not be
    #     checked against known variables to detect missing $.
    # n   The variable does not have to exist, and is set by the command.
    # v   The variable must exist. It is not marked as set.
    # l   Does not have to exist. It will be marked as known, but not set.
    # nl  Like n, but a list of variable names

    # Modifiers that apply to some of the above
    # ? Zero or One
    # * Zero or more  (not supported by all tokens)
    # . One or nothing at all

    # If a token is followed by a parenthesis it denotes a type.
    # The local variable in the proc is marked with this type.
    # Any modifier goes after the parens.
    # E.g.   x(varName)   x(script)?
    
    # If a token is followed by a number it is token dependent.
    # Any modifier goes after the number.
    # E.g.   c2   cg4?

    # If a token is followed by =, it is a token dependent modifier.
    # E.g   do=_stdclass_oo

    # If a syntax for a subcommand is defined, it is used to check the rest
    # If a syntax for an option is defined, it is used to check the next arg.


    # Syntax for Tcl core commands

    set syntax(after)           "r 1"
    # FIXA: handle after's id/subcommand thing.
    set syntax(append)          "n x*"
    set syntax(array)           "s v x?"
    set syntax(array\ exists)   "l=array"
    set syntax(array\ names)    "v=array x? x?"
    set syntax(array\ set)      "n=array x"
    set syntax(array\ size)     "v=array"
    set syntax(array\ statistics) "v=array"
    set syntax(array\ unset)    "l x?"
    #set syntax(bgerror)          1
    set syntax(binary)          "s x*"
    set syntax(binary\ scan)    "x x n n*"
    set syntax(break)            0
    set syntax(case)            "x*"
    set syntax(catch)           "c n?"
    set syntax(cd)              "r 0 1"
    set syntax(clock)           "s x*"
    set syntax(clock\ clicks)   "o?"
    set syntax(clock\ format)   "x p*"
    set syntax(clock\ scan)     "x p*"
    set syntax(clock\ seconds)   0
    set syntax(close)            1
    set syntax(concat)          "r 0"
    set syntax(continue)         0
    set syntax(encoding)        "s x*"
    set syntax(encoding\ convertfrom) "r 1 2"
    set syntax(encoding\ convertto)   "r 1 2"
    set syntax(encoding\ names)  0
    set syntax(encoding\ system) "r 0 1"
    set syntax(eof)              1
    set syntax(error)           "r 1 3"
    set special(eval) 1
    set syntax(exec)            "o* x x*"
    set syntax(exit)            "r 0 1"
    set special(expr) 1
    set syntax(fblocked)         1
    set syntax(fconfigure)      "x o. x. p*"
    set syntax(fcopy)           "x x p*"
    set syntax(file)            "s x*"
    set syntax(file\ atime)      "x x?"
    set syntax(file\ attributes) "x o. x. p*"
    set syntax(file\ channels)   "x?"
    set syntax(file\ copy)       "o* x x x*"
    set syntax(file\ delete)     "o* x x*"
    set syntax(file\ dirname)    "x"
    set syntax(file\ executable) "x"
    set syntax(file\ exists)     "x"
    set syntax(file\ extension)  "x"
    set syntax(file\ isdirectory) "x"
    set syntax(file\ isfile)     "x"
    set syntax(file\ join)       "x x*"
    set syntax(file\ link)       "o? x x?"
    set syntax(file\ lstat)      "x n"
    set syntax(file\ mkdir)      "x x*"
    set syntax(file\ mtime)      "x x?"
    set syntax(file\ nativename) "x"
    set syntax(file\ normalize)  "x"
    set syntax(file\ owned)      "x"
    set syntax(file\ pathtype)   "x"
    set syntax(file\ readable)   "x"
    set syntax(file\ readlink)   "x"
    set syntax(file\ rename)     "o* x x x*"
    set syntax(file\ rootname)   "x"
    set syntax(file\ separator)  "x?"
    set syntax(file\ size)       "x"
    set syntax(file\ split)      "x"
    set syntax(file\ stat)       "x n"
    set syntax(file\ system)     "x"
    set syntax(file\ tail)       "x"
    set syntax(file\ type)       "x"
    set syntax(file\ volumes)    0
    set syntax(file\ writable)   "x"
    set syntax(fileevent)       "x x x?"
    set syntax(flush)            1
    set syntax(for)             "c E c c"
    set special(foreach) 1
    set syntax(format)          "r 1"
    set syntax(gets)            "x n?"
    set syntax(glob)            "o* x x*"
    set special(global) 1
    # "if" is handled specially, but is added here to not disturb header gen.
    set syntax(if)              "e c"
    set syntax(incr)            "v x?"
    set syntax(info)            "s x*"  ;# FIXA: All subcommands
    set syntax(info\ exists)    "l"
    set syntax(info\ default)   "x x n"
    # "interp" is handled specially
    set syntax(interp)          "s x*"
    set syntax(interp\ invokehidden) "x o* x x*"
    set syntax(join)            "r 1 2"
    set syntax(lappend)         "n x*"
    set syntax(lindex)          "r 1"
    set syntax(linsert)         "r 3"
    set syntax(list)            "r 0"
    set syntax(llength)          1
    set syntax(load)            "r 1 3"
    set syntax(lrange)           3
    set syntax(lreplace)        "r 3"
    set syntax(lsearch)         "o* x x"
    set syntax(lset)            "n x x x*"
    set syntax(lsort)           "o* x"
    # "namespace" is handled specially
    set syntax(namespace)       "s x*" ;# FIXA: All subcommands
    set syntax(namespace\ code) "c"
    set return(namespace\ code) "script"
    set syntax(namespace\ import) "o* x*"
    set syntax(namespace\ which) "o* x?"
    set option(namespace\ which) "-variable -command"
    set option(namespace\ which\ -variable) v
    set syntax(open)            "r 1 3"
    # "package" is handled specially
    set syntax(package)         "s x*" ;# FIXA: All subcommands
    set syntax(package\ require) "o* x x*"
    set option(package\ require) "-exact"
    set syntax(pid)             "r 0 1"
    set syntax(proc)            dp
    set syntax(puts)            "1: x : o? x x?"
    set syntax(pwd)              0
    set syntax(read)            "r 1 2"
    set syntax(regexp)          "o* re x n*"
    set syntax(regsub)          "o* re x x n?"
    set syntax(rename)           2   ;# Maybe treat rename specially?
    set syntax(return)          "p* x?"
    set syntax(scan)            "x x n*"
    set syntax(seek)            "r 2 3"
    # "set" is handled specially
    set syntax(set)             "1: v=scalar : n=scalar x"
    set syntax(socket)          "r 2"
    set syntax(source)           1
    set syntax(split)           "r 1 2"
    set syntax(string)          "s x x*"
    set syntax(string\ bytelength) 1
    set syntax(string\ compare) "o* x x"
    set syntax(string\ equal)   "o* x x"
    set syntax(string\ first)   "r 2 3"
    set syntax(string\ index)    2
    set syntax(string\ is)      "s o* x"
    set syntax(string\ last)    "r 2 3"
    set syntax(string\ length)   1
    set syntax(string\ map)     "o? x x"
    set syntax(string\ match)   "o? x x"
    set syntax(string\ range)    3
    set syntax(string\ repeat)   2
    set syntax(string\ replace) "r 3 4"
    set syntax(string\ tolower) "r 1 3"
    set syntax(string\ totitle) "r 1 3"
    set syntax(string\ toupper) "r 1 3"
    set syntax(string\ trim)    "r 1 2"
    set syntax(string\ trimleft) "r 1 2"
    set syntax(string\ trimright) "r 1 2"
    set syntax(string\ wordend)   2
    set syntax(string\ wordstart) 2
    set syntax(subst)           "o* x"
    # "switch" is handled specially, but is added here to not disturb header gen
    set special(switch) 1
    set syntax(switch)          "x*"
    set syntax(tell)             1
    set syntax(time)            "c x?"
    set syntax(trace)           "s x x*"
    set syntax(trace\ add)      "s x x x"
    set syntax(trace\ add\ command)   "x x c3"
    # FIXA: The second arg to trace add execution is not a sub command really,
    # since it allows a list of operations. How to handle this?
    set syntax(trace\ add\ execution) "x s c2"
    set syntax(trace\ add\ execution\ leave) "c4"
    set syntax(trace\ add\ execution\ leavestep) "c4"
    set syntax(trace\ add\ variable)  "v x c3"
    set syntax(trace\ remove)      "s x x x"
    set syntax(trace\ remove\ command)   "x x x"
    set syntax(trace\ remove\ execution) "x x x"
    set syntax(trace\ remove\ variable)  "v x x"
    set syntax(trace\ info)      "s x x x"
    set syntax(trace\ info\ command)   "x"
    set syntax(trace\ info\ execution) "x"
    set syntax(trace\ info\ variable)  "v"
    set syntax(trace\ variable) "n x x"
    set syntax(trace\ vinfo)    "l"
    set syntax(trace\ vdelete)  "v x x"
    set syntax(unset)           "o* l l*"
    set syntax(update)          "s."
    set special(uplevel) 1
    set special(upvar) 1
    set special(variable) 1
    set syntax(vwait)           "n"
    set syntax(while)           "E c"

    # Things added in 8.5
    if {[info commands dict] ne ""} {
        set syntax(catch)        "c n? n?" ;# FIXA make a test for this
        set syntax(dict)          "s x x*"
        set syntax(dict\ append)  "n x x*"
        set syntax(dict\ create)  "x&x*"
        set syntax(dict\ exists)  "x x x*"
        set syntax(dict\ for)     "nl x c"
        set syntax(dict\ incr)    "n x x*"
        set syntax(dict\ filter)  "x s x*"
        set syntax(dict\ filter\ key)    "x*"
        set syntax(dict\ filter\ script) "nl c"
        set syntax(dict\ filter\ value)  "x*"
        set syntax(dict\ info)    "x"
        set syntax(dict\ keys)    "x x?"
        set syntax(dict\ lappend) "n x x*"
        set syntax(dict\ map)     "nl x c"
        set syntax(dict\ remove)  "x x*"
        set syntax(dict\ replace) "x x*"
        set syntax(dict\ set)     "n x x x*"
        set syntax(dict\ size)    "x"
        set syntax(dict\ unset)   "n x x*"
        set syntax(dict\ values)  "x x?"
        set syntax(dict\ update)  "l x n x&n* c"
        set syntax(dict\ with)    "l x* c"
        
        # Initialising incr
        set syntax(incr)       "n x?"
        set syntax(lassign)    "x n n*"
        set syntax(lrepeat)    "r 2"
        set syntax(lreverse)   "1"
        set syntax(string\ reverse)   "1"
        set syntax(unload)     "o* x x*"
        set syntax(chan)       "s x*"
        set syntax(chan\ blocked) "x"
        set syntax(chan\ close) "x"
        set syntax(chan\ configure) "x o. x. p*"
        set syntax(chan\ copy) "x x p*"
        set syntax(chan\ create) "x x"
        set syntax(chan\ eof) "x"
        set syntax(chan\ event) "x x cg?"
        set syntax(chan\ flush) "x"
        set syntax(chan\ gets) "x n?"
        set syntax(chan\ names) "x?"
        set syntax(chan\ pending) "x x"
        set syntax(chan\ postevent) "x x"
        set syntax(chan\ puts) "1: x : o? x x?"
        set syntax(chan\ read) "x x?"
        set syntax(chan\ seek) $syntax(seek)
        set syntax(chan\ tell) $syntax(tell)
        set syntax(chan\ truncate) "x x?"
        set syntax(apply)      "x x*"
        set syntax(source)     "p* x"
        set option(interp\ invokehidden\ -namespace) 1
        set option(switch\ -matchvar) n
        set option(switch\ -indexvar) n
    }

    # Things added in 8.6
    if {[info commands try] ne ""} {
        # Changed commands
        set syntax(close)           "x x?"
        set syntax(chan\ close)     "x x?"
        set syntax(dict\ filter)    "x x x*"
        # Do nothing gracefully
        set syntax(file\ delete)     "o* x*"
        set syntax(file\ mkdir)      "x*"
        set syntax(glob)             "o* x*"
        set syntax(lassign)          "x n*"
        set syntax(linsert)          "r 2"
        set syntax(lrepeat)          "r 1"
        # New subcommands
        set syntax(binary\ decode)           "s x*"
        set syntax(binary\ decode\ base64)   "o* x"
        set syntax(binary\ decode\ hex)      "o* x"
        set syntax(binary\ decode\ uuencode) "o* x"
        set syntax(binary\ encode)           "s x*"
        set syntax(binary\ encode\ base64)   "p* x"
        set syntax(binary\ encode\ hex)      "x"
        set syntax(binary\ encode\ uuencode) "p* x"
        set syntax(chan\ pipe)               0
        set syntax(chan\ pop)                "x"
        set syntax(chan\ push)               "x c"
        set syntax(dict\ map)                "nl x c"
        set syntax(file\ tempfile)           "n? x?"
        set syntax(info\ coroutine)          0
        set syntax(interp\ cancel)           "o* x? x?"
        # New commands
        # "try" is handled specially, but is added here to not disturb header
        # gen, and to signal in to the engine that "try" is an allowed command.
        set syntax(try)          "c x*"
        set special(try) 1
        set syntax(throw)        "2"
        # TODO: Autimatically recognise the command generated by coroutine
        # This could be done using "dc", but that would warn in the common
        # case of non-constant coro names.
        set syntax(coroutine)    "x x x*"
        set special(tailcall) 1
        set special(next) 1
        set syntax(yield)        "x?"
        set syntax(yieldto)        "x x*"
        # lmap is handled specially, like foreach, but the presence of the
        # syntax string tells the internals that it is allowed
        set syntax(lmap) "n x c"
        set special(lmap) 1
        set syntax(zlib)             "s x*"
        set syntax(zlib\ adler32)    "x x?"
        set syntax(zlib\ compress)   "x x?"
        set syntax(zlib\ crc32)      "x x?"
        set syntax(zlib\ decompress) "x x?"
        set syntax(zlib\ deflate)    "x x?"
        set syntax(zlib\ gzip)       "x p*"
        set syntax(zlib\ gunzip)     "x p*"
        set syntax(zlib\ inflate)    "x x?"
        set syntax(zlib\ push)       "s x p*"
        set syntax(zlib\ stream)     "s x*"
        set syntax(zlib\ stream\ compress)   "p*"
        set syntax(zlib\ stream\ decompress) "p*"
        set syntax(zlib\ stream\ deflate)    "p*"
        set syntax(zlib\ stream\ gunzip)     "0" ;# No options for gunzip
        set syntax(zlib\ stream\ gzip)       "p*"
        set syntax(zlib\ stream\ inflate)    "p*"
        lappend ::kP zlib
        set syntax(tcl::prefix)  "s x*"
        set syntax(tcl::prefix\ all)  "x x"
        set syntax(tcl::prefix\ longest)  "x x"
        set syntax(tcl::prefix\ match)  "o* x x"
        set option(tcl::prefix\ match\ -message) x
        set option(tcl::prefix\ match\ -error) x

        set syntax(oo::class)    "s x*"
        set syntax(oo::class\ create) "do=_stdclass_oo cn?"
        set syntax(oo::class\ create::constructor) dk ;# Define constructor
        set syntax(oo::class\ create::superclass)  "o? di" ;# Define inheritance
        set syntax(oo::class\ create::method) "dm"    ;# Define method 
        set syntax(oo::class\ create::destructor) dd  ;# Define destructor
        set syntax(oo::class\ create::variable) "o? div*"
        set syntax(oo::class\ create::export) x
        set syntax(oo::class\ create::class) x
        set syntax(oo::class\ create::deletemethod) "x x*"
        set syntax(oo::class\ create::export) "x x*"
        set syntax(oo::class\ create::filter) "o? x*"
        set syntax(oo::class\ create::forward) "x x x*"
        set syntax(oo::class\ create::mixin) "o? di" ;# TBD, like inheritance?
        set syntax(oo::class\ create::renamemethod) "x x"
        set syntax(oo::class\ create::self) "x*"
        set syntax(oo::class\ create::unexport) "x x*"

        foreach s {filter mixin superclass variable} {
            set option(oo::class\ create::$s) "-append -clear -set"
        }

        set syntax(_stdclass_oo) "s x*"
        set subCmd(_stdclass_oo) "create new destroy variable varname"
        set syntax(_stdclass_oo\ create) "dc=_obj,_stdclass_oo x?"
        set return(_stdclass_oo\ create) _obj,_stdclass_oo
        set syntax(_stdclass_oo\ new) 0
        set return(_stdclass_oo\ new) _obj,_stdclass_oo
        set syntax(_stdclass_oo\ destroy) 0
        set syntax(_stdclass_oo\ variable) n*
        set syntax(_stdclass_oo\ varname) v
        set return(_stdclass_oo\ varname) varName
        set syntax(info\ object) "s x x*"
        set syntax(info\ class)  "s x x*"
        set syntax(oo::copy)     "x x?"
        lappend ::kP TclOO

        # oo::define has two formats, one for a "configure script" and one
        # for single subcommands. Thus each command needs to be defined
        # both as a command in the namespace, and as a subcommand.
        set syntax(oo::define)      "2: do cn : do s x x*"
        set syntax(oo::objdefine)   "2: do cn : do s x x*"
        # Copy from class create
        foreach item [array names syntax oo::class\ create::*] {
            set tail [namespace tail $item]
            set syntax(oo::define::$tail) $syntax($item)
            set syntax(oo::define\ $tail) $syntax($item)
            set syntax(oo::objdefine::$tail) $syntax($item)
            set syntax(oo::objdefine\ $tail) $syntax($item)
        }

        set syntax(oo::object)   "s x*" ;# FIXA?
        # Set up basic checking of self/my
        set syntax(my)           "s x*"
        set syntax(my\ variable) "n*"
        set syntax(self)         "s"
        lappend ::kC self my
        oo::class create miffo {
            constructor {} {
                upvar 1 subCmd subCmd
                set subCmd(self) [getSubCmds self gurkmeja]
            }
        }
        # Run constructor to get info about self
        [miffo new] destroy
        # New options
        set option(lsort\ -stride) 1
    }

    # Things added in 8.7
    if {[info commands lpop] ne ""} {
        set syntax(lpop) "v x*"
        set syntax(ledit) "v x x x*"
        set syntax(lseq)  "x x*"
        set syntax(timerate) "o* c x? x?"
        set option(timerate\ -overhead) 1

        set syntax(file\ home)        "x?"
        set syntax(file\ tildeexpand) "x"

        set syntax(zipfs) "s x*"
        set syntax(zipfs\ canonical) "r 1 3"
        set syntax(zipfs\ exists)  1
        set syntax(zipfs\ find)    1
        set syntax(zipfs\ info)    1
        set syntax(zipfs\ list) "o* x?"
        set option(zipfs\ list) "-glob -regexp"
        set syntax(zipfs\ lmkimg)  "r 2 4"
        set syntax(zipfs\ lmkzip)  "r 2 3"
        set syntax(zipfs\ mkimg)   "r 2 5"
        set syntax(zipfs\ mkkey)   1
        set syntax(zipfs\ mkzip)   "r 2 4"
        set syntax(zipfs\ mount)   "r 0 3"
        set syntax(zipfs\ root)    0
        set syntax(zipfs\ unmount) 1

        set syntax(tcl::process) "s x*"
        set syntax(tcl::process\ autoperge) "x?"
        set syntax(tcl::process\ list)      "0"
        set syntax(tcl::process\ purge)     "x?"
        set syntax(tcl::process\ status)    "o* x?"

        set syntax(array\ default) "s l x?"
        set syntax(array\ default\ exists) "l=array"
        set syntax(array\ default\ get)    "v=array"
        set syntax(array\ default\ set)    "v=array x"
        set syntax(array\ default\ unset)  "v=array"

        set syntax(array\ for) "nl v=array c"

        set syntax(info\ cmdtype) "x"

        set option(lsearch\ -stride) 1
        set option(regsub\ -command) 1
    }

    # Some special Tcl commands
    set syntax(dde)             "o? s x*"  ;# FIXA: is this correct?
    set syntax(history)         "s x*"
    set syntax(parray)          "v x?"

    # FIXA: Type checking is still experimental
    set return(linsert)         list
    set return(list)            list
    set return(llength)         int
    set return(lrange)          list
    set return(lreplace)        list
    set return(lsort)           list

    # Syntax for Tk commands

    if {$useTk} {
        set syntax(bell)     "o* x*"
        set syntax(bind)     "x x? cg?"
        set syntax(bindtags) "x x?"
        set syntax(clipboard) "s x*"
        # console is windows only, but keep it in the db on all platforms
        set syntax(console)  "r 1"
        set keep(console) 1
        set syntax(destroy)  "x*"
        set syntax(event)    "s x*"
        set syntax(focus)    "o? x?"
        set syntax(font)     "s x*"
        set syntax(image)    "s x*"
        set syntax(grab)     "x x*" ;# FIXA, how to check subcommands here?
        set syntax(grid)     "x x*" ;# FIXA, how to check subcommands here?
        set syntax(lower)    "x x?"
        set syntax(option)   "s x*"
        set syntax(pack)     "x x*"
        set syntax(place)    "x x*"
        set syntax(raise)    "x x?"
        set syntax(selection) "s x*"
        set syntax(send)     "o* x x x*"
        set syntax(tk)       "s x*"
        set syntax(tkwait)   "s x"
        set syntax(tkwait\ variable) "l" ;# Global variable?
	set syntax(winfo)    "s x x*"
        set syntax(wm)       "s x x*"

        set syntax(tk_chooseColor)     "p*"
        set syntax(tk_chooseDirectory) "p*"
        #set syntax(tk_dialog)          "r 6"
        set syntax(tk_getOpenFile)     "p*"
        set syntax(tk_getSaveFile)     "p*"
        set syntax(tk_messageBox)      "p*"
        set syntax(tk_popup)           "r 3 4"
        set syntax(.)                  "s x*"
        set syntax(.\ configure)       "o. x. p*"
        set syntax(.\ cget)            "o"

        # FIXA: Starting on better Tk support
        set classCmds {frame entry label button checkbutton radiobutton \
                listbox labelframe spinbox panedwindow toplevel menu message \
                scrollbar text canvas scale menubutton}
        # Handle tk::xxx usage
        foreach cmd $classCmds {
            if {[info commands tk::$cmd] ne ""} {
                lappend classCmds tk::$cmd
            }
        }
        if {[info commands ttk::frame] ne ""} {
            lappend classCmds ttk::scale ttk::label ttk::panedwindow
            lappend classCmds ttk::separator ttk::menubutton
            lappend classCmds ttk::entry ttk::radiobutton ttk::frame
            lappend classCmds ttk::labelframe ttk::button ttk::sizegrip
            lappend classCmds ttk::combobox ttk::notebook
            lappend classCmds ttk::progressbar ttk::checkbutton
            lappend classCmds ttk::treeview ttk::scrollbar
            set syntax(ttk::style) "s x*"
            set syntax(ttk::style\ configure) "x o. x. p*"
            set syntax(ttk::style\ map) "x p*"
            set syntax(ttk::style\ lookup) "r 2 4"
            set syntax(ttk::style\ layout) "x x?"
            set syntax(ttk::style\ element) "s x*"
            set syntax(ttk::style\ element\ create) "x x x*"
            set syntax(ttk::style\ element\ names) 0
            set syntax(ttk::style\ element\ options) x
            set syntax(ttk::style\ theme) "s x*"
            set syntax(ttk::style\ theme\ create) "x p*"
            set syntax(ttk::style\ theme\ settings) "x c"
            set syntax(ttk::style\ theme\ names) 0
            set syntax(ttk::style\ theme\ use) x
            set syntax(ttk::themes) x?
            set syntax(ttk::setTheme) x
            markCmdAsKnown ttk::style ttk::themes  ttk::setTheme
            lappend ::kP Ttk tile
        }
        foreach class $classCmds {
            destroy .w
            if {[catch {$class .w}]} continue
            markCmdAsKnown $class
            set syntax($class) "x p*"
            set return($class) _obj,$class
            set option($class) {}
            foreach opt [.w configure] {
                set opt [lindex $opt 0]
                lappend option($class) $opt
                if {[string match *variable $opt]} {
                    set option($class\ $opt) n
                    set option(_obj,$class\ configure\ $opt) n
                }
            }
            set syntax(_obj,$class) "s x*"
            set subCmd(_obj,$class) [getSubCmds .w gurkmeja]
            set syntax(_obj,$class\ configure) "o. x. p*"
            set option(_obj,$class\ configure) $option($class)
            set syntax(_obj,$class\ cget) "o"
            set option(_obj,$class\ cget) $option($class)
            # Widget details
            switch $class {
                listbox {
                    set syntax(_obj,$class\ selection) "s x x?"
                    set subCmd(_obj,$class\ selection) \
                            [getSubCmds .w selection gurkmeja 0]
                }
                text {
                    set syntax(_obj,$class\ bbox) "1"
                    set syntax(_obj,$class\ compare) "3"
                    set syntax(_obj,$class\ debug) "x?"
                    set syntax(_obj,$class\ delete) "r 1"
                    set syntax(_obj,$class\ dlineinfo) "1"
                    set syntax(_obj,$class\ index) "1"
                    set syntax(_obj,$class\ insert) "r 2"
                    set syntax(_obj,$class\ pendingsync) "0"
                    set syntax(_obj,$class\ replace) "r 3"
                    set syntax(_obj,$class\ see) "1"
                    set syntax(_obj,$class\ sync) "r 1 3"

                    set syntax(_obj,$class\ edit) "s x*"
                    set subCmd(_obj,$class\ edit) \
                            [getSubCmds .w edit gurkmeja]

                    set syntax(_obj,$class\ image) "s x*"
                    set subCmd(_obj,$class\ image) \
                            [getSubCmds .w image gurkmeja]

                    set syntax(_obj,$class\ mark) "s x*"
                    set subCmd(_obj,$class\ mark) \
                            [getSubCmds .w mark gurkmeja]

                    set syntax(_obj,$class\ peer) "s x*"
                    set subCmd(_obj,$class\ peer) \
                            [getSubCmds .w peer gurkmeja]

                    set syntax(_obj,$class\ scan) "s x x"
                    set subCmd(_obj,$class\ scan) \
                            [getSubCmds .w scan gurkmeja x x]

                    set syntax(_obj,$class\ tag) "s x*"
                    set subCmd(_obj,$class\ tag) \
                            [getSubCmds .w tag gurkmeja]

                    set syntax(_obj,$class\ window) "s x*"
                    set subCmd(_obj,$class\ window) \
                            [getSubCmds .w window gurkmeja]

                    set syntax(_obj,$class\ xview) "0: 0 : s x*"
                    set subCmd(_obj,$class\ xview) \
                            [getSubCmds .w xview gurkmeja]

                    # yview is a bit weird
                    set syntax(_obj,$class\ yview) "x*"

                    set syntax(_obj,$class\ count) "o* x x"
                    set option(_obj,$class\ count) \
                            [getSubCmds .w count -gurkmeja x x]

                    set syntax(_obj,$class\ dump) "o* x x?"
                    set option(_obj,$class\ dump) \
                            [getSubCmds .w dump -gurkmeja x]
                    set option(_obj,$class\ dump\ -command) x

                    set syntax(_obj,$class\ get) "o* x x*"
                    set option(_obj,$class\ get) \
                            [getSubCmds .w get -gurkmeja x x]

                    set syntax(_obj,$class\ search) "o* x x x?"
                    set option(_obj,$class\ search) \
                            [getSubCmds .w search -gurkmeja x x]
                    set option(_obj,$class\ search\ -count) n
                }
            }
        }
        set option(.\ configure)       $option(toplevel)
        set option(.\ cget)            $option(toplevel)
    }

    # Build a database of options and subcommands

    # subCmd(cmd) contains a list of all allowed subcommands

    # Get subcommands for commands that can't use the standard below
    set getSubCmd(wm) "wm gurkmeja ."

    # Get subcommands for any commands defining "s"
    foreach cmd [array names syntax] {
        if {[info exists subCmd($cmd)]} continue
        set syn $syntax($cmd)
        set oi [lsearch -glob $syn "s*"]
        if {$oi >= 0} {
            set syn [lreplace $syn $oi $oi gurkmeja]
            # If the subcmd is after a :, handle it
            set ci [lsearch -exact $syn ":"]
            if {$ci >= 0 && $ci < $oi} {
                set syn [lrange $syn [expr {$ci + 1}] end]
            }
            # Remove anything optional
            set syn [lsearch -all -inline -not -regexp $syn {\*$}]

            if {[info exists getSubCmd($cmd)]} {
                set cmdToTry $getSubCmd($cmd)
            } else {
                set cmdToTry "$cmd $syn"
            }
            set opts [eval getSubCmds $cmdToTry]
            if {[llength $opts] > 0} {
                set subCmd($cmd) $opts
                #puts "AutoSub: $cmd $subCmd($cmd)"
            } else {
                #puts "Failed AutoSub: $cmd $syn"
            }
        }
    }

    # option(cmd) contains a list of all allowed options
    # option(cmd subcmd) defines options for subcommands

    # Get options for commands that can't use the standard loop below.
    set option(switch)     [getSubCmds switch -gurkmeja x x]
    set option(fconfigure) [getSubCmds fconfigure stdin -gurkmeja]
    set option(fcopy)      [getSubCmds fcopy stdin stdout -gurkmeja x]
    set option(unset)      [list -nocomplain --]
    set option(clock\ format) [getSubCmds clock format 1 -gurkmeja x]

    set option(zlib\ push) [getSubCmds zlib push compress stdout -gurkmeja x]

    # Add additonal fconfigure, known for serial channels
    lappend option(fconfigure) -mode -handshake -queue -timeout -ttycontrol -ttystatus -xchar -pollinterval -sysbuffer -lasterror
    # For socket channels
    lappend option(fconfigure) -error -peername -sockname
    set option(fconfigure) [lsort -uniq -dictionary $option(fconfigure)]

    # Get options for any commands defining "o" or "p"
    foreach cmd [array names syntax] {
        if {[info exists option($cmd)]} continue
        set syn $syntax($cmd)
        if {[set i [lsearch -exact $syn ":"]] >= 0} {
            # Handle a syn like "1: x : o? x x?"
            # Just do the it the simple way of ignoring all but the last
            set syn [lrange $syn [expr {$i + 1}] end]
        }
        set oi [lsearch -glob $syn "o*"]
        if {$oi >= 0} {
            set syn [lreplace $syn $oi $oi -gurkmeja]
        }
        set pi [lsearch -glob $syn "p*"]
        if {$pi >= 0} {
            set syn [lreplace $syn $pi $pi -gurkmeja apa]
        }
        if {$oi >= 0 || $pi >= 0} {
            set opts [eval getSubCmds $cmd $syn]
            if {[llength $opts] > 0} {
                set option($cmd) $opts
                #puts "Autoopt: $cmd $option($cmd)"
            } else {
                #puts "Failed Autoopt: $cmd"
            }
        }
    }

    # Send cannot return info in some versions
    if {![info exists option(send)]} {
        set option(send) "-- -async -displayof"
    }

    # The default for options is not to take a value unless 'p' is
    # used in the syntax definition.
    # If option(cmd opt) is set, the option is followed by a value.
    # The value of option(cmd opt) may also be any of the syntax chars
    # c/n/v/l and will be used to check the option.
    set option(lsort\ -index)   1
    set option(lsort\ -command) 1
    set option(lsearch\ -index) 1
    set option(lsearch\ -start) 1
    set option(string\ is\ -failindex)   n
    set option(string\ compare\ -length) 1
    set option(string\ equal\ -length)   1
    set option(regexp\ -start)   1
    set option(regsub\ -start)   1
    set option(glob\ -directory) 1
    set option(glob\ -path)      1
    set option(glob\ -types)     1
    set option(send\ -displayof) 1

    # Clean up unused options
    foreach item [array names option] {
        if {[string match "-*" [lindex $item end]]} {
            set opt [lindex $item end]
            set cmd [lrange $item 0 end-1]
            if {![info exists option($cmd)] || [lsearch -exact $option($cmd) $opt] < 0} {
                #puts "Deleting option($item)"
                unset option($item)
            }
        }
    }

    # Build syntax info for procs
    foreach apa $::kC {
        if {![info exists syntax($apa)]} {
            # Is it a proc?
            if {[info procs $apa] != ""} {
                set syntax($apa) [createSyntax $apa]
            } elseif {![info exists special($apa)]} {
                # Debug helper
                #puts "No syntax defined for cmd '$apa'"
            }
        }
    }

    # Special handling of tcl::math*
    foreach ns {mathop mathfunc} {
        foreach fun [info commands tcl::${ns}::*] {
            # Remove ::
            set fun [string range $fun 2 end]
            #if {[info exists syntax($fun)]} continue
            # Try to figure it out
            set minArg 0
            set maxArg 1000
            set e0 [catch {$fun}]
            set e1 [catch {$fun 1}]
            set e2 [catch {$fun 1 2}]
            set e5 [catch {$fun 1 2 1 2 1}]
            set spec ""
            switch $e0$e1$e2$e5 {
                0111 {set spec 0 }
                1011 {set spec 1 }
                1101 {set spec 2 }
                0000 {set spec "r 0"}
                1000 {set spec "r 1"}
                default {
                    puts "$fun $e0 $e1 $e2 $e5"
                }
            }
            if {$spec ne ""} {
                set syntax($fun) $spec
            }
        }
    }

    # Output the data
    puts $ch [list lappend ::dbInfo $dbstring]
    puts $ch [list set ::dbTclVersion $::tcl_version]
    puts $ch [list set ::knownGlobals [lsort $::kG]]
    puts $ch [list set ::knownCommands \n[join [lsort $::kC] \n]\n]
    puts $ch [list set ::knownPackages [lsort $::kP]]

    foreach a {syntax return subCmd option} {
        foreach i [lsort [array names $a]] {
            set v [set ${a}($i)]
            if {[llength $v] != 0} {
                set first [lindex [split $i] 0]
                if {![string match _* $first] && \
                        ![string match *::* $first] && \
                        [lsearch $::kC $first] == -1 && \
                        ![info exists keep($first)]} {
                    puts stderr "Skipping ${a}($i) since $i is not known."
                } else {
                    puts $ch [list set ::${a}($i) $v]
                }
            }
        }
        puts $ch ""
    }
}

# Build a syntax database and write it to a file
proc buildFile {filename} {
    set ch [open $filename w]
    buildDb $ch
    close $ch
}

# This file can be sourced into an interactive interpreter.
# source syntaxbuild.tcl
# buildFile <filename>

if {[info exists tcl_interactive] && !$tcl_interactive} {
    if {$argc == 0 && $tcl_platform(platform) == "windows"} {
	set argc 1
	set argv [list syntaxdb.tcl]
    }
    if {$argc == 0} {
	buildDb stdout
    } else {
        buildFile [lindex $argv 0]
    }
    exit
}

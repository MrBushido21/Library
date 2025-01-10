# Automatically generated syntax database.

lappend ::dbInfo {Tcl 8.6.10 windows}
set ::dbTclVersion 8.6
set ::knownGlobals {argc argv argv0 auto_index auto_path env errorCode errorInfo tcl_interactive tcl_library tcl_nonwordchars tcl_patchLevel tcl_platform tcl_rcFileName tcl_version tcl_wordchars}
set ::knownCommands {
after
append
apply
array
auto_execok
auto_import
auto_load
auto_load_index
auto_mkindex
auto_mkindex_old
auto_mkindex_parser::cleanup
auto_mkindex_parser::command
auto_mkindex_parser::commandInit
auto_mkindex_parser::fullname
auto_mkindex_parser::hook
auto_mkindex_parser::indexEntry
auto_mkindex_parser::init
auto_mkindex_parser::mkindex
auto_mkindex_parser::slavehook
auto_qualify
auto_reset
binary
break
case
catch
cd
chan
checkmem
clock
close
concat
continue
coroutine
dict
encoding
eof
error
eval
exec
exit
expr
fblocked
fconfigure
fcopy
file
fileevent
flush
for
foreach
format
gets
glob
global
history
if
incr
info
interp
join
lappend
lassign
lindex
linsert
list
llength
lmap
load
lrange
lrepeat
lreplace
lreverse
lsearch
lset
lsort
memory
msgcat::mc
msgcat::mcexists
msgcat::mcflmset
msgcat::mcflset
msgcat::mcforgetpackage
msgcat::mcload
msgcat::mcloadedlocales
msgcat::mclocale
msgcat::mcmax
msgcat::mcmset
msgcat::mcpackageconfig
msgcat::mcpackagelocale
msgcat::mcpreferences
msgcat::mcset
msgcat::mcunknown
my
namespace
oo::class
oo::copy
oo::define
oo::objdefine
oo::object
open
package
parray
pid
pkg::create
pkg_mkIndex
proc
puts
pwd
read
regexp
registry
regsub
rename
return
safe::interpAddToAccessPath
safe::interpConfigure
safe::interpCreate
safe::interpDelete
safe::interpFindInAccessPath
safe::interpInit
safe::setLogCmd
scan
seek
self
set
socket
source
split
string
subst
switch
tailcall
tcl::Lassign
tcl::Lempty
tcl::Lget
tcl::Lvarincr
tcl::Lvarpop
tcl::Lvarpop1
tcl::Lvarset
tcl::OptKeyDelete
tcl::OptKeyError
tcl::OptKeyParse
tcl::OptKeyRegister
tcl::OptParse
tcl::OptProc
tcl::OptProcArgGiven
tcl::SetMax
tcl::SetMin
tcl::array::anymore
tcl::array::donesearch
tcl::array::exists
tcl::array::get
tcl::array::names
tcl::array::nextelement
tcl::array::set
tcl::array::size
tcl::array::startsearch
tcl::array::statistics
tcl::array::unset
tcl::binary::decode
tcl::binary::decode::base64
tcl::binary::decode::hex
tcl::binary::decode::uuencode
tcl::binary::encode
tcl::binary::encode::base64
tcl::binary::encode::hex
tcl::binary::encode::uuencode
tcl::binary::format
tcl::binary::scan
tcl::chan::blocked
tcl::chan::close
tcl::chan::copy
tcl::chan::create
tcl::chan::eof
tcl::chan::event
tcl::chan::flush
tcl::chan::gets
tcl::chan::names
tcl::chan::pending
tcl::chan::pipe
tcl::chan::pop
tcl::chan::postevent
tcl::chan::push
tcl::chan::puts
tcl::chan::read
tcl::chan::seek
tcl::chan::tell
tcl::chan::truncate
tcl::clock::add
tcl::clock::clicks
tcl::clock::format
tcl::clock::getenv
tcl::clock::microseconds
tcl::clock::milliseconds
tcl::clock::scan
tcl::clock::seconds
tcl::dict::append
tcl::dict::create
tcl::dict::exists
tcl::dict::filter
tcl::dict::for
tcl::dict::get
tcl::dict::incr
tcl::dict::info
tcl::dict::keys
tcl::dict::lappend
tcl::dict::map
tcl::dict::merge
tcl::dict::remove
tcl::dict::replace
tcl::dict::set
tcl::dict::size
tcl::dict::unset
tcl::dict::update
tcl::dict::values
tcl::dict::with
tcl::encoding::convertfrom
tcl::encoding::convertto
tcl::encoding::dirs
tcl::encoding::names
tcl::encoding::system
tcl::file::atime
tcl::file::attributes
tcl::file::channels
tcl::file::copy
tcl::file::delete
tcl::file::dirname
tcl::file::executable
tcl::file::exists
tcl::file::extension
tcl::file::isdirectory
tcl::file::isfile
tcl::file::join
tcl::file::link
tcl::file::lstat
tcl::file::mkdir
tcl::file::mtime
tcl::file::nativename
tcl::file::normalize
tcl::file::owned
tcl::file::pathtype
tcl::file::readable
tcl::file::readlink
tcl::file::rename
tcl::file::rootname
tcl::file::separator
tcl::file::size
tcl::file::split
tcl::file::stat
tcl::file::system
tcl::file::tail
tcl::file::tempfile
tcl::file::type
tcl::file::volumes
tcl::file::writable
tcl::history
tcl::info::args
tcl::info::body
tcl::info::cmdcount
tcl::info::commands
tcl::info::complete
tcl::info::coroutine
tcl::info::default
tcl::info::errorstack
tcl::info::exists
tcl::info::frame
tcl::info::functions
tcl::info::globals
tcl::info::hostname
tcl::info::level
tcl::info::library
tcl::info::loaded
tcl::info::locals
tcl::info::nameofexecutable
tcl::info::patchlevel
tcl::info::procs
tcl::info::script
tcl::info::sharedlibextension
tcl::info::tclversion
tcl::info::vars
tcl::mathfunc::abs
tcl::mathfunc::acos
tcl::mathfunc::asin
tcl::mathfunc::atan
tcl::mathfunc::atan2
tcl::mathfunc::bool
tcl::mathfunc::ceil
tcl::mathfunc::cos
tcl::mathfunc::cosh
tcl::mathfunc::double
tcl::mathfunc::entier
tcl::mathfunc::exp
tcl::mathfunc::floor
tcl::mathfunc::fmod
tcl::mathfunc::hypot
tcl::mathfunc::int
tcl::mathfunc::isqrt
tcl::mathfunc::log
tcl::mathfunc::log10
tcl::mathfunc::max
tcl::mathfunc::min
tcl::mathfunc::pow
tcl::mathfunc::rand
tcl::mathfunc::round
tcl::mathfunc::sin
tcl::mathfunc::sinh
tcl::mathfunc::sqrt
tcl::mathfunc::srand
tcl::mathfunc::tan
tcl::mathfunc::tanh
tcl::mathfunc::wide
tcl::mathop::!
tcl::mathop::!=
tcl::mathop::%
tcl::mathop::&
tcl::mathop::*
tcl::mathop::**
tcl::mathop::+
tcl::mathop::-
tcl::mathop::/
tcl::mathop::<
tcl::mathop::<<
tcl::mathop::<=
tcl::mathop::==
tcl::mathop::>
tcl::mathop::>=
tcl::mathop::>>
tcl::mathop::^
tcl::mathop::eq
tcl::mathop::in
tcl::mathop::ne
tcl::mathop::ni
tcl::mathop::|
tcl::mathop::~
tcl::namespace::children
tcl::namespace::code
tcl::namespace::current
tcl::namespace::delete
tcl::namespace::ensemble
tcl::namespace::eval
tcl::namespace::exists
tcl::namespace::export
tcl::namespace::forget
tcl::namespace::import
tcl::namespace::inscope
tcl::namespace::origin
tcl::namespace::parent
tcl::namespace::path
tcl::namespace::qualifiers
tcl::namespace::tail
tcl::namespace::unknown
tcl::namespace::upvar
tcl::namespace::which
tcl::pkgconfig
tcl::pkgindex
tcl::prefix
tcl::prefix
tcl::prefix::all
tcl::prefix::longest
tcl::prefix::match
tcl::string::bytelength
tcl::string::cat
tcl::string::compare
tcl::string::equal
tcl::string::first
tcl::string::index
tcl::string::is
tcl::string::last
tcl::string::length
tcl::string::map
tcl::string::match
tcl::string::range
tcl::string::repeat
tcl::string::replace
tcl::string::reverse
tcl::string::tolower
tcl::string::totitle
tcl::string::toupper
tcl::string::trim
tcl::string::trimleft
tcl::string::trimright
tcl::string::wordend
tcl::string::wordstart
tcl::tm::path
tcl::unsupported::assemble
tcl::unsupported::corotype
tcl::unsupported::disassemble
tcl::unsupported::getbytecode
tcl::unsupported::inject
tcl::unsupported::representation
tcl::unsupported::timerate
tclLog
tclPkgSetup
tclPkgUnknown
tcl_endOfWord
tcl_findLibrary
tcl_startOfNextWord
tcl_startOfPreviousWord
tcl_wordBreakAfter
tcl_wordBreakBefore
tell
throw
time
timerate
trace
try
unknown
unload
unset
update
uplevel
upvar
variable
vwait
while
yield
yieldto
zlib
zlib::pkgconfig
}
set ::knownPackages {Tcl TclOO msgcat zlib}
set ::syntax(_stdclass_oo) {s x*}
set {::syntax(_stdclass_oo create)} {dc=_obj,_stdclass_oo x?}
set {::syntax(_stdclass_oo destroy)} 0
set {::syntax(_stdclass_oo new)} 0
set {::syntax(_stdclass_oo variable)} n*
set {::syntax(_stdclass_oo varname)} v
set ::syntax(after) {r 1}
set ::syntax(append) {n x*}
set ::syntax(apply) {x x*}
set ::syntax(array) {s v x?}
set {::syntax(array exists)} l=array
set {::syntax(array names)} {v=array x? x?}
set {::syntax(array set)} {n=array x}
set {::syntax(array size)} v=array
set {::syntax(array statistics)} v=array
set {::syntax(array unset)} {l x?}
set ::syntax(auto_execok) 1
set ::syntax(auto_import) 1
set ::syntax(auto_load) {r 1 2}
set ::syntax(auto_load_index) 0
set ::syntax(auto_mkindex) {r 1}
set ::syntax(auto_mkindex_old) {r 1}
set ::syntax(auto_mkindex_parser::cleanup) 0
set ::syntax(auto_mkindex_parser::command) 3
set ::syntax(auto_mkindex_parser::commandInit) 3
set ::syntax(auto_mkindex_parser::fullname) 1
set ::syntax(auto_mkindex_parser::hook) 1
set ::syntax(auto_mkindex_parser::indexEntry) 1
set ::syntax(auto_mkindex_parser::init) 0
set ::syntax(auto_mkindex_parser::mkindex) 1
set ::syntax(auto_mkindex_parser::slavehook) 1
set ::syntax(auto_qualify) 2
set ::syntax(auto_reset) 0
set ::syntax(binary) {s x*}
set {::syntax(binary decode)} {s x*}
set {::syntax(binary decode base64)} {o* x}
set {::syntax(binary decode hex)} {o* x}
set {::syntax(binary decode uuencode)} {o* x}
set {::syntax(binary encode)} {s x*}
set {::syntax(binary encode base64)} {p* x}
set {::syntax(binary encode hex)} x
set {::syntax(binary encode uuencode)} {p* x}
set {::syntax(binary scan)} {x x n n*}
set ::syntax(break) 0
set ::syntax(case) x*
set ::syntax(catch) {c n? n?}
set ::syntax(cd) {r 0 1}
set ::syntax(chan) {s x*}
set {::syntax(chan blocked)} x
set {::syntax(chan close)} {x x?}
set {::syntax(chan configure)} {x o. x. p*}
set {::syntax(chan copy)} {x x p*}
set {::syntax(chan create)} {x x}
set {::syntax(chan eof)} x
set {::syntax(chan event)} {x x cg?}
set {::syntax(chan flush)} x
set {::syntax(chan gets)} {x n?}
set {::syntax(chan names)} x?
set {::syntax(chan pending)} {x x}
set {::syntax(chan pipe)} 0
set {::syntax(chan pop)} x
set {::syntax(chan postevent)} {x x}
set {::syntax(chan push)} {x c}
set {::syntax(chan puts)} {1: x : o? x x?}
set {::syntax(chan read)} {x x?}
set {::syntax(chan seek)} {r 2 3}
set {::syntax(chan tell)} 1
set {::syntax(chan truncate)} {x x?}
set ::syntax(clock) {s x*}
set {::syntax(clock clicks)} o?
set {::syntax(clock format)} {x p*}
set {::syntax(clock scan)} {x p*}
set {::syntax(clock seconds)} 0
set ::syntax(close) {x x?}
set ::syntax(concat) {r 0}
set ::syntax(continue) 0
set ::syntax(coroutine) {x x x*}
set ::syntax(dict) {s x x*}
set {::syntax(dict append)} {n x x*}
set {::syntax(dict create)} x&x*
set {::syntax(dict exists)} {x x x*}
set {::syntax(dict filter)} {x x x*}
set {::syntax(dict filter key)} x*
set {::syntax(dict filter script)} {nl c}
set {::syntax(dict filter value)} x*
set {::syntax(dict for)} {nl x c}
set {::syntax(dict incr)} {n x x*}
set {::syntax(dict info)} x
set {::syntax(dict keys)} {x x?}
set {::syntax(dict lappend)} {n x x*}
set {::syntax(dict map)} {nl x c}
set {::syntax(dict remove)} {x x*}
set {::syntax(dict replace)} {x x*}
set {::syntax(dict set)} {n x x x*}
set {::syntax(dict size)} x
set {::syntax(dict unset)} {n x x*}
set {::syntax(dict update)} {l x n x&n* c}
set {::syntax(dict values)} {x x?}
set {::syntax(dict with)} {l x* c}
set ::syntax(encoding) {s x*}
set {::syntax(encoding convertfrom)} {r 1 2}
set {::syntax(encoding convertto)} {r 1 2}
set {::syntax(encoding names)} 0
set {::syntax(encoding system)} {r 0 1}
set ::syntax(eof) 1
set ::syntax(error) {r 1 3}
set ::syntax(exec) {o* x x*}
set ::syntax(exit) {r 0 1}
set ::syntax(fblocked) 1
set ::syntax(fconfigure) {x o. x. p*}
set ::syntax(fcopy) {x x p*}
set ::syntax(file) {s x*}
set {::syntax(file atime)} {x x?}
set {::syntax(file attributes)} {x o. x. p*}
set {::syntax(file channels)} x?
set {::syntax(file copy)} {o* x x x*}
set {::syntax(file delete)} {o* x*}
set {::syntax(file dirname)} x
set {::syntax(file executable)} x
set {::syntax(file exists)} x
set {::syntax(file extension)} x
set {::syntax(file isdirectory)} x
set {::syntax(file isfile)} x
set {::syntax(file join)} {x x*}
set {::syntax(file link)} {o? x x?}
set {::syntax(file lstat)} {x n}
set {::syntax(file mkdir)} x*
set {::syntax(file mtime)} {x x?}
set {::syntax(file nativename)} x
set {::syntax(file normalize)} x
set {::syntax(file owned)} x
set {::syntax(file pathtype)} x
set {::syntax(file readable)} x
set {::syntax(file readlink)} x
set {::syntax(file rename)} {o* x x x*}
set {::syntax(file rootname)} x
set {::syntax(file separator)} x?
set {::syntax(file size)} x
set {::syntax(file split)} x
set {::syntax(file stat)} {x n}
set {::syntax(file system)} x
set {::syntax(file tail)} x
set {::syntax(file tempfile)} {n? x?}
set {::syntax(file type)} x
set {::syntax(file volumes)} 0
set {::syntax(file writable)} x
set ::syntax(fileevent) {x x x?}
set ::syntax(flush) 1
set ::syntax(for) {c E c c}
set ::syntax(format) {r 1}
set ::syntax(gets) {x n?}
set ::syntax(glob) {o* x*}
set ::syntax(history) {s x*}
set ::syntax(if) {e c}
set ::syntax(incr) {n x?}
set ::syntax(info) {s x*}
set {::syntax(info class)} {s x x*}
set {::syntax(info coroutine)} 0
set {::syntax(info default)} {x x n}
set {::syntax(info exists)} l
set {::syntax(info object)} {s x x*}
set ::syntax(interp) {s x*}
set {::syntax(interp cancel)} {o* x? x?}
set {::syntax(interp invokehidden)} {x o* x x*}
set ::syntax(join) {r 1 2}
set ::syntax(lappend) {n x*}
set ::syntax(lassign) {x n*}
set ::syntax(lindex) {r 1}
set ::syntax(linsert) {r 2}
set ::syntax(list) {r 0}
set ::syntax(llength) 1
set ::syntax(lmap) {n x c}
set ::syntax(load) {r 1 3}
set ::syntax(lrange) 3
set ::syntax(lrepeat) {r 1}
set ::syntax(lreplace) {r 3}
set ::syntax(lreverse) 1
set ::syntax(lsearch) {o* x x}
set ::syntax(lset) {n x x x*}
set ::syntax(lsort) {o* x}
set ::syntax(msgcat::mc) {r 1}
set ::syntax(msgcat::mcexists) {r 0}
set ::syntax(msgcat::mcflmset) 1
set ::syntax(msgcat::mcflset) {r 1 2}
set ::syntax(msgcat::mcforgetpackage) 0
set ::syntax(msgcat::mcload) 1
set ::syntax(msgcat::mcloadedlocales) 1
set ::syntax(msgcat::mclocale) {r 0}
set ::syntax(msgcat::mcmax) {r 0}
set ::syntax(msgcat::mcmset) 2
set ::syntax(msgcat::mcpackageconfig) {r 2 3}
set ::syntax(msgcat::mcpackagelocale) {r 1 2}
set ::syntax(msgcat::mcpreferences) 0
set ::syntax(msgcat::mcset) {r 2 3}
set ::syntax(msgcat::mcunknown) {r 0}
set ::syntax(my) {s x*}
set {::syntax(my variable)} n*
set ::syntax(namespace) {s x*}
set {::syntax(namespace code)} c
set {::syntax(namespace import)} {o* x*}
set {::syntax(namespace which)} {o* x?}
set ::syntax(oo::class) {s x*}
set {::syntax(oo::class create)} {do=_stdclass_oo cn?}
set {::syntax(oo::class create::class)} x
set {::syntax(oo::class create::constructor)} dk
set {::syntax(oo::class create::deletemethod)} {x x*}
set {::syntax(oo::class create::destructor)} dd
set {::syntax(oo::class create::export)} {x x*}
set {::syntax(oo::class create::filter)} {o? x*}
set {::syntax(oo::class create::forward)} {x x x*}
set {::syntax(oo::class create::method)} dm
set {::syntax(oo::class create::mixin)} {o? x*}
set {::syntax(oo::class create::renamemethod)} {x x}
set {::syntax(oo::class create::self)} x*
set {::syntax(oo::class create::superclass)} di
set {::syntax(oo::class create::unexport)} {x x*}
set {::syntax(oo::class create::variable)} div*
set ::syntax(oo::copy) {x x?}
set ::syntax(oo::define) {2: do cn : do s x x*}
set {::syntax(oo::define class)} x
set {::syntax(oo::define constructor)} dk
set {::syntax(oo::define deletemethod)} {x x*}
set {::syntax(oo::define destructor)} dd
set {::syntax(oo::define export)} {x x*}
set {::syntax(oo::define filter)} {o? x*}
set {::syntax(oo::define forward)} {x x x*}
set {::syntax(oo::define method)} dm
set {::syntax(oo::define mixin)} {o? x*}
set {::syntax(oo::define renamemethod)} {x x}
set {::syntax(oo::define self)} x*
set {::syntax(oo::define superclass)} di
set {::syntax(oo::define unexport)} {x x*}
set {::syntax(oo::define variable)} div*
set ::syntax(oo::define::class) x
set ::syntax(oo::define::constructor) dk
set ::syntax(oo::define::deletemethod) {x x*}
set ::syntax(oo::define::destructor) dd
set ::syntax(oo::define::export) {x x*}
set ::syntax(oo::define::filter) {o? x*}
set ::syntax(oo::define::forward) {x x x*}
set ::syntax(oo::define::method) dm
set ::syntax(oo::define::mixin) {o? x*}
set ::syntax(oo::define::renamemethod) {x x}
set ::syntax(oo::define::self) x*
set ::syntax(oo::define::superclass) di
set ::syntax(oo::define::unexport) {x x*}
set ::syntax(oo::define::variable) div*
set ::syntax(oo::objdefine) {2: do cn : do s x x*}
set {::syntax(oo::objdefine class)} x
set {::syntax(oo::objdefine constructor)} dk
set {::syntax(oo::objdefine deletemethod)} {x x*}
set {::syntax(oo::objdefine destructor)} dd
set {::syntax(oo::objdefine export)} {x x*}
set {::syntax(oo::objdefine filter)} {o? x*}
set {::syntax(oo::objdefine forward)} {x x x*}
set {::syntax(oo::objdefine method)} dm
set {::syntax(oo::objdefine mixin)} {o? x*}
set {::syntax(oo::objdefine renamemethod)} {x x}
set {::syntax(oo::objdefine self)} x*
set {::syntax(oo::objdefine superclass)} di
set {::syntax(oo::objdefine unexport)} {x x*}
set {::syntax(oo::objdefine variable)} div*
set ::syntax(oo::objdefine::class) x
set ::syntax(oo::objdefine::constructor) dk
set ::syntax(oo::objdefine::deletemethod) {x x*}
set ::syntax(oo::objdefine::destructor) dd
set ::syntax(oo::objdefine::export) {x x*}
set ::syntax(oo::objdefine::filter) {o? x*}
set ::syntax(oo::objdefine::forward) {x x x*}
set ::syntax(oo::objdefine::method) dm
set ::syntax(oo::objdefine::mixin) {o? x*}
set ::syntax(oo::objdefine::renamemethod) {x x}
set ::syntax(oo::objdefine::self) x*
set ::syntax(oo::objdefine::superclass) di
set ::syntax(oo::objdefine::unexport) {x x*}
set ::syntax(oo::objdefine::variable) div*
set ::syntax(oo::object) {s x*}
set ::syntax(open) {r 1 3}
set ::syntax(package) {s x*}
set {::syntax(package require)} {o* x x*}
set ::syntax(parray) {v x?}
set ::syntax(pid) {r 0 1}
set ::syntax(pkg_mkIndex) {r 0}
set ::syntax(proc) dp
set ::syntax(puts) {1: x : o? x x?}
set ::syntax(pwd) 0
set ::syntax(read) {r 1 2}
set ::syntax(regexp) {o* re x n*}
set ::syntax(regsub) {o* re x x n?}
set ::syntax(rename) 2
set ::syntax(return) {p* x?}
set ::syntax(safe::interpAddToAccessPath) 2
set ::syntax(safe::interpConfigure) {r 0}
set ::syntax(safe::interpCreate) {r 0}
set ::syntax(safe::interpDelete) 1
set ::syntax(safe::interpFindInAccessPath) 2
set ::syntax(safe::interpInit) {r 0}
set ::syntax(safe::setLogCmd) {r 0}
set ::syntax(scan) {x x n*}
set ::syntax(seek) {r 2 3}
set ::syntax(self) s
set ::syntax(set) {1: v=scalar : n=scalar x}
set ::syntax(socket) {r 2}
set ::syntax(source) {p* x}
set ::syntax(split) {r 1 2}
set ::syntax(string) {s x x*}
set {::syntax(string bytelength)} 1
set {::syntax(string compare)} {o* x x}
set {::syntax(string equal)} {o* x x}
set {::syntax(string first)} {r 2 3}
set {::syntax(string index)} 2
set {::syntax(string is)} {s o* x}
set {::syntax(string last)} {r 2 3}
set {::syntax(string length)} 1
set {::syntax(string map)} {o? x x}
set {::syntax(string match)} {o? x x}
set {::syntax(string range)} 3
set {::syntax(string repeat)} 2
set {::syntax(string replace)} {r 3 4}
set {::syntax(string reverse)} 1
set {::syntax(string tolower)} {r 1 3}
set {::syntax(string totitle)} {r 1 3}
set {::syntax(string toupper)} {r 1 3}
set {::syntax(string trim)} {r 1 2}
set {::syntax(string trimleft)} {r 1 2}
set {::syntax(string trimright)} {r 1 2}
set {::syntax(string wordend)} 2
set {::syntax(string wordstart)} 2
set ::syntax(subst) {o* x}
set ::syntax(switch) x*
set ::syntax(tcl::Lassign) {r 1}
set ::syntax(tcl::Lempty) 1
set ::syntax(tcl::Lget) 2
set ::syntax(tcl::Lvarincr) {r 2 3}
set ::syntax(tcl::Lvarpop) 1
set ::syntax(tcl::Lvarpop1) 1
set ::syntax(tcl::Lvarset) 3
set ::syntax(tcl::OptKeyDelete) 1
set ::syntax(tcl::OptKeyError) {r 2 3}
set ::syntax(tcl::OptKeyParse) 2
set ::syntax(tcl::OptKeyRegister) {r 1 2}
set ::syntax(tcl::OptParse) 2
set ::syntax(tcl::OptProc) 3
set ::syntax(tcl::OptProcArgGiven) 1
set ::syntax(tcl::SetMax) 2
set ::syntax(tcl::SetMin) 2
set ::syntax(tcl::clock::add) {r 1}
set ::syntax(tcl::clock::format) {r 0}
set ::syntax(tcl::clock::scan) {r 0}
set ::syntax(tcl::mathfunc::abs) 1
set ::syntax(tcl::mathfunc::acos) 1
set ::syntax(tcl::mathfunc::asin) 1
set ::syntax(tcl::mathfunc::atan) 1
set ::syntax(tcl::mathfunc::atan2) 2
set ::syntax(tcl::mathfunc::bool) 1
set ::syntax(tcl::mathfunc::ceil) 1
set ::syntax(tcl::mathfunc::cos) 1
set ::syntax(tcl::mathfunc::cosh) 1
set ::syntax(tcl::mathfunc::double) 1
set ::syntax(tcl::mathfunc::entier) 1
set ::syntax(tcl::mathfunc::exp) 1
set ::syntax(tcl::mathfunc::floor) 1
set ::syntax(tcl::mathfunc::fmod) 2
set ::syntax(tcl::mathfunc::hypot) 2
set ::syntax(tcl::mathfunc::int) 1
set ::syntax(tcl::mathfunc::isqrt) 1
set ::syntax(tcl::mathfunc::log) 1
set ::syntax(tcl::mathfunc::log10) 1
set ::syntax(tcl::mathfunc::max) {r 1}
set ::syntax(tcl::mathfunc::min) {r 1}
set ::syntax(tcl::mathfunc::pow) 2
set ::syntax(tcl::mathfunc::rand) 0
set ::syntax(tcl::mathfunc::round) 1
set ::syntax(tcl::mathfunc::sin) 1
set ::syntax(tcl::mathfunc::sinh) 1
set ::syntax(tcl::mathfunc::sqrt) 1
set ::syntax(tcl::mathfunc::srand) 1
set ::syntax(tcl::mathfunc::tan) 1
set ::syntax(tcl::mathfunc::tanh) 1
set ::syntax(tcl::mathfunc::wide) 1
set ::syntax(tcl::mathop::!) 1
set ::syntax(tcl::mathop::!=) 2
set ::syntax(tcl::mathop::%) 2
set ::syntax(tcl::mathop::&) {r 0}
set ::syntax(tcl::mathop::*) {r 0}
set ::syntax(tcl::mathop::**) {r 0}
set ::syntax(tcl::mathop::+) {r 0}
set ::syntax(tcl::mathop::-) {r 1}
set ::syntax(tcl::mathop::/) {r 1}
set ::syntax(tcl::mathop::<) {r 0}
set ::syntax(tcl::mathop::<<) 2
set ::syntax(tcl::mathop::<=) {r 0}
set ::syntax(tcl::mathop::==) {r 0}
set ::syntax(tcl::mathop::>) {r 0}
set ::syntax(tcl::mathop::>=) {r 0}
set ::syntax(tcl::mathop::>>) 2
set ::syntax(tcl::mathop::^) {r 0}
set ::syntax(tcl::mathop::eq) {r 0}
set ::syntax(tcl::mathop::in) 2
set ::syntax(tcl::mathop::ne) 2
set ::syntax(tcl::mathop::ni) 2
set ::syntax(tcl::mathop::|) {r 0}
set ::syntax(tcl::mathop::~) 1
set ::syntax(tcl::pkgindex) 4
set ::syntax(tcl::prefix) {s x*}
set {::syntax(tcl::prefix all)} {x x}
set {::syntax(tcl::prefix longest)} {x x}
set {::syntax(tcl::prefix match)} {o* x x}
set ::syntax(tclLog) 1
set ::syntax(tclPkgSetup) 4
set ::syntax(tclPkgUnknown) {r 1}
set ::syntax(tcl_endOfWord) 2
set ::syntax(tcl_findLibrary) 6
set ::syntax(tcl_startOfNextWord) 2
set ::syntax(tcl_startOfPreviousWord) 2
set ::syntax(tcl_wordBreakAfter) 2
set ::syntax(tcl_wordBreakBefore) 2
set ::syntax(tell) 1
set ::syntax(throw) 2
set ::syntax(time) {c x?}
set ::syntax(trace) {s x x*}
set {::syntax(trace add)} {s x x x}
set {::syntax(trace add command)} {x x c3}
set {::syntax(trace add execution)} {x s c2}
set {::syntax(trace add execution leave)} c4
set {::syntax(trace add execution leavestep)} c4
set {::syntax(trace add variable)} {v x c3}
set {::syntax(trace info)} {s x x x}
set {::syntax(trace info command)} x
set {::syntax(trace info execution)} x
set {::syntax(trace info variable)} v
set {::syntax(trace remove)} {s x x x}
set {::syntax(trace remove command)} {x x x}
set {::syntax(trace remove execution)} {x x x}
set {::syntax(trace remove variable)} {v x x}
set {::syntax(trace variable)} {n x x}
set {::syntax(trace vdelete)} {v x x}
set {::syntax(trace vinfo)} l
set ::syntax(try) {c x*}
set ::syntax(unknown) {r 0}
set ::syntax(unload) {o* x x*}
set ::syntax(unset) {o* l l*}
set ::syntax(update) s.
set ::syntax(vwait) n
set ::syntax(while) {E c}
set ::syntax(yield) x?
set ::syntax(yieldto) {x x*}
set ::syntax(zlib) {s x*}
set {::syntax(zlib adler32)} {x x?}
set {::syntax(zlib compress)} {x x?}
set {::syntax(zlib crc32)} {x x?}
set {::syntax(zlib decompress)} {x x?}
set {::syntax(zlib deflate)} {x x?}
set {::syntax(zlib gunzip)} {x p*}
set {::syntax(zlib gzip)} {x p*}
set {::syntax(zlib inflate)} {x x?}
set {::syntax(zlib push)} {s x p*}
set {::syntax(zlib stream)} {s x*}
set {::syntax(zlib stream compress)} p*
set {::syntax(zlib stream decompress)} p*
set {::syntax(zlib stream deflate)} p*
set {::syntax(zlib stream gunzip)} 0
set {::syntax(zlib stream gzip)} p*
set {::syntax(zlib stream inflate)} p*

set {::return(_stdclass_oo create)} _obj,_stdclass_oo
set {::return(_stdclass_oo new)} _obj,_stdclass_oo
set {::return(_stdclass_oo varname)} varName
set ::return(linsert) list
set ::return(list) list
set ::return(llength) int
set ::return(lrange) list
set ::return(lreplace) list
set ::return(lsort) list
set {::return(namespace code)} script

set ::subCmd(_stdclass_oo) {create new destroy variable varname}
set ::subCmd(array) {anymore donesearch exists get names nextelement set size startsearch statistics unset}
set ::subCmd(binary) {decode encode format scan}
set {::subCmd(binary decode)} {base64 hex uuencode}
set {::subCmd(binary encode)} {base64 hex uuencode}
set ::subCmd(chan) {blocked close configure copy create eof event flush gets names pending pipe pop postevent push puts read seek tell truncate}
set ::subCmd(clock) {add clicks format microseconds milliseconds scan seconds}
set ::subCmd(dict) {append create exists filter for get incr info keys lappend map merge remove replace set size unset update values with}
set ::subCmd(encoding) {convertfrom convertto dirs names system}
set ::subCmd(file) {atime attributes channels copy delete dirname executable exists extension isdirectory isfile join link lstat mkdir mtime nativename normalize owned pathtype readable readlink rename rootname separator size split stat system tail tempfile type volumes writable}
set ::subCmd(history) {add change clear event info keep nextid redo}
set ::subCmd(info) {args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharedlibextension tclversion vars}
set {::subCmd(info class)} {call constructor definition destructor filters forward instances methods methodtype mixins subclasses superclasses variables}
set {::subCmd(info object)} {call class definition filters forward isa methods methodtype mixins namespace variables vars}
set ::subCmd(interp) {alias aliases bgerror cancel children create debug delete eval exists expose hidden hide invokehidden issafe limit marktrusted recursionlimit share slaves target transfer}
set ::subCmd(namespace) {children code current delete ensemble eval exists export forget import inscope origin parent path qualifiers tail unknown upvar which}
set ::subCmd(oo::class) {create destroy}
set ::subCmd(oo::object) {create destroy new}
set ::subCmd(package) {forget ifneeded names prefer present provide require unknown vcompare versions vsatisfies}
set ::subCmd(self) {call caller class filter method namespace next object target}
set ::subCmd(string) {bytelength cat compare equal first index is last length map match range repeat replace reverse tolower totitle toupper trim trimleft trimright wordend wordstart}
set {::subCmd(string is)} {alnum alpha ascii boolean control digit double entier false graph integer list lower print punct space true upper wideinteger wordchar xdigit}
set ::subCmd(tcl::prefix) {all longest match}
set ::subCmd(trace) {add info remove variable vdelete vinfo}
set {::subCmd(trace add)} {command execution variable}
set {::subCmd(trace add execution)} {enter enterstep leave leavestep}
set {::subCmd(trace info)} {command execution variable}
set {::subCmd(trace remove)} {command execution variable}
set ::subCmd(update) idletasks
set ::subCmd(zlib) {adler32 compress crc32 decompress deflate gunzip gzip inflate push stream}
set {::subCmd(zlib push)} {compress decompress deflate gunzip gzip inflate}
set {::subCmd(zlib stream)} {compress decompress deflate gunzip gzip inflate}

set {::option(binary decode base64)} -strict
set {::option(binary decode hex)} -strict
set {::option(binary decode uuencode)} -strict
set {::option(binary encode base64)} {-maxlen -wrapchar}
set {::option(binary encode uuencode)} {-maxlen -wrapchar}
set {::option(chan puts)} -nonewline
set {::option(clock clicks)} {-microseconds -milliseconds}
set {::option(clock format)} {-format -gmt -locale -timezone}
set {::option(clock scan)} {-base -format -gmt -locale -timezone}
set ::option(exec) {-- -ignorestderr -keepnewline}
set ::option(fconfigure) {-blocking -buffering -buffersize -encoding -eofchar -error -handshake -lasterror -mode -peername -pollinterval -queue -sockname -sysbuffer -timeout -translation -ttycontrol -ttystatus -xchar}
set ::option(fcopy) {-command -size}
set {::option(file attributes)} {-archive -hidden -longname -readonly -shortname -system}
set {::option(file copy)} {-- -force}
set {::option(file delete)} {-- -force}
set {::option(file link)} {-hard -symbolic}
set {::option(file rename)} {-- -force}
set ::option(glob) {-- -directory -join -nocomplain -path -tails -types}
set {::option(glob -directory)} 1
set {::option(glob -path)} 1
set {::option(glob -types)} 1
set {::option(interp cancel)} {-- -unwind}
set {::option(interp invokehidden)} {-- -global -namespace}
set {::option(interp invokehidden -namespace)} 1
set ::option(lsearch) {-all -ascii -bisect -decreasing -dictionary -exact -glob -increasing -index -inline -integer -nocase -not -real -regexp -sorted -start -subindices}
set {::option(lsearch -index)} 1
set {::option(lsearch -start)} 1
set ::option(lsort) {-ascii -command -decreasing -dictionary -increasing -index -indices -integer -nocase -real -stride -unique}
set {::option(lsort -command)} 1
set {::option(lsort -index)} 1
set {::option(lsort -stride)} 1
set {::option(namespace which)} {-variable -command}
set {::option(namespace which -variable)} v
set {::option(oo::class create::filter)} {create destroy}
set {::option(oo::class create::mixin)} {create destroy}
set ::option(oo::define::filter) {-append -clear -set}
set ::option(oo::define::mixin) {-append -clear -set}
set ::option(oo::objdefine::filter) {-append -clear -set}
set ::option(oo::objdefine::mixin) {-append -clear -set}
set {::option(package require)} -exact
set ::option(puts) -nonewline
set ::option(regexp) {-- -about -all -expanded -indices -inline -line -lineanchor -linestop -nocase -start}
set {::option(regexp -start)} 1
set ::option(regsub) {-- -all -expanded -line -lineanchor -linestop -nocase -start}
set {::option(regsub -start)} 1
set ::option(source) -encoding
set {::option(string compare)} {-length -nocase}
set {::option(string compare -length)} 1
set {::option(string equal)} {-length -nocase}
set {::option(string equal -length)} 1
set {::option(string is)} {-failindex -strict}
set {::option(string is -failindex)} n
set {::option(string map)} -nocase
set {::option(string match)} -nocase
set ::option(subst) {-nobackslashes -nocommands -novariables}
set ::option(switch) {-- -exact -glob -indexvar -matchvar -nocase -regexp}
set {::option(switch -indexvar)} n
set {::option(switch -matchvar)} n
set {::option(tcl::prefix match)} {-error -exact -message}
set {::option(tcl::prefix match -error)} x
set {::option(tcl::prefix match -message)} x
set ::option(unload) {-- -keeplibrary -nocomplain}
set ::option(unset) {-nocomplain --}
set {::option(zlib gunzip)} {-buffersize -headerVar}
set {::option(zlib gzip)} {-header -level}
set {::option(zlib push)} {-dictionary -header -level}
set {::option(zlib stream compress)} {-dictionary -level}
set {::option(zlib stream decompress)} -dictionary
set {::option(zlib stream deflate)} {-dictionary -level}
set {::option(zlib stream gzip)} {-header -level}
set {::option(zlib stream inflate)} -dictionary


# -----------------------------------------------------------------------------
# savedefault_test.tcl ---
# -----------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------
# Purpose:
#  Package to store & retrieve user settings.
#
# -----------------------------------------------------------------------------
# TclOO naming conventions:
# public methods  - starts with lower case declaration names, whereas
# private methods - starts with uppercase naming, so we are going to use CamelCase ...
# -----------------------------------------------------------------------------

# where to find required tcllib packages:
set dir [file dirname [info script]]

lappend auto_path [file join $dir "."]
lappend auto_path [file join $dir "../tcllib"]

package require fileutil
package require inifile
package require savedefault


# test starts here ...

package require Tk
catch {console show}


# initializing default settings
		
set ini_defaults {
	{"geometry" "950x570+140+170"}
	{"fontsize" 10}
	{"paneorient" "vertical"}
	{"test" ""}
	{"test1" ""}
	{"test2" ""}
}


::savedefault::savedefault \
	"SaveDefault_Test.ini" \
	$ini_defaults

# overwrite existing array names (if any)
#    - with the values retrieved from the configuration file
#    - otherwise use the given default values (ini_defaults)

array set this_array {}

::savedefault::readsettings this_array
parray this_array


puts "------------------------"

set ini_list {}
lappend ini_list [list "geometry" "800x500"]
lappend ini_list [list "fontsize" 12]
lappend ini_list [list "paneorient" horizontal]
lappend ini_list [list "test" test]
lappend ini_list [list "test1" 123]
lappend ini_list [list "test2" XYZ]

::savedefault::savesettings $ini_list


::savedefault::readsettings this_array
parray this_array

#==============================================================================
# Scrollutil and Scrollutil_tile package index file.
#
# Copyright (c) 2019-2024  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Regular packages:
#
package ifneeded scrollutil         2.3.1 \
	[list source [file join $dir scrollutil.tcl]]
package ifneeded scrollutil_tile    2.3.1 \
	[list source [file join $dir scrollutil_tile.tcl]]

#
# Aliases:
#
package ifneeded Scrollutil         2.3.1 \
	[list package require -exact scrollutil      2.3.1]
package ifneeded Scrollutil_tile    2.3.1 \
	[list package require -exact scrollutil_tile 2.3.1]

#
# Code common to all packages:
#
package ifneeded scrollutil::common 2.3.1 \
	[list source [file join $dir scrollutilCommon.tcl]]

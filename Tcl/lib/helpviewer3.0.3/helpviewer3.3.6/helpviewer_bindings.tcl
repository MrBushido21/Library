

bind all <MouseWheel> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		catch {
			set ycomm [$w cget -yscrollcommand]
			if { $ycomm != "" } {
				$w yview scroll [expr int(-1*%D/36)] units
				break
			}
		}
		set w [winfo parent $w]
	}
}

source httpd.tcl

proc filecontents {fn} {set f [open $fn]; set d [read $f]; close $f; return $d}; # simple utility

proc webhandler {op sock} {
	if {$op=="handle"} {
		httpd loadrequest $sock data query
		if {![info exists data(url)]} {return}
		regsub {(^http://[^/]+)?} $data(url) {} url
		puts stderr "URL: $url"
		set url [string trimleft $url /]
		switch -glob -- $url {
			""             {httpd return $sock [filecontents index.html]}
			"*.js"         {httpd return $sock [filecontents $url] -mimetype "text/javascript"}
			"*.gif"        {httpd returnfile $sock $url $url  "image/gif" [clock seconds] 1 -static }
			"*.png"        {httpd returnfile $sock $url $url  "image/png" [clock seconds] 1 -static }
			"*.jpg"        {httpd returnfile $sock $url $url  "image/jpeg" [clock seconds] 1 -static }
			"*.ico"        {httpd returnfile $sock $url $url  "image/x-icon" [clock seconds] 1 -static }
			"*.css"        {httpd return $sock [filecontents $url] -mimetype "text/css"}
                        "*.html"       {httpd return $sock [filecontents $url] -mimetype "text/html"}
			default        {puts stderr "BAD URL $url"; httpd returnerror 404}
		}
	}
}

httpd listen 9001 webhandler
puts stdout "Started on port 9001"
vwait forever

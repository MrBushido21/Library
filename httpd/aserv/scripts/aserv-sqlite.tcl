# $Id$

namespace eval ::aserv::source::sqlite {

    variable type        "sqlite"
    variable datafile    [file join $aserv::library data sqlite.db]

    variable xml_indent 0

    proc init {args} {
        package require sqlite 3
        variable datafile
        if {[llength $args] > 0} {
            set datafile [lindex $args 0]
        }
        sqlite db $datafile
        return true
    } 

    proc done {} {
        rename db {}
    } 

    proc log {level args} {
        uplevel eval ::aserv::log $level $args
    }

    proc fail {code text {info {}}} {
	[dom createDocument error doc] documentElement error

	$error setAttribute code $code
	$error appendChild [$doc createTextNode $text]
	if {[info exists ::debug] && $::debug > 0 && $info != ""} {
	    $error appendChild [$doc createElement errorinfo errorinfo]
	    $errorinfo appendChild [$doc createTextNode $info]
	}
	return [$error asXML -indent 0]
    }

    proc get {proc args} {
	log 1 $proc $args
	set start [clock seconds]
        set getproc ::aserv::source::sqlite::get-$proc

	if {[info procs $getproc] != "$getproc"} {
	    log 0 invalid query '$proc'
	    set result [fail 404 "Bad query" "$proc $args"]
	} elseif {[catch {eval $getproc $args} result]} {
	    log 0 error in '$proc' : '$result'
	    set result [fail 500 "Server error" "\n$::errorInfo\n"]
	}

	log 2 $proc: [expr {[clock seconds] - $start}] seconds
	return $result 
    }

    proc list {} {
        string map {::aserv::source::sqlite::get- {}} [info proc ::[namespace current]::get-*]
    }

    proc setup-mnc {docvar mncvar} {
	upvar $docvar doc
	upvar $mncvar mnc

	dom createDocument mnc doc
	$doc documentElement mnc
	$mnc setAttribute version "1.0"
	$mnc setAttribute stamp \
	    [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        $mnc appendChild [$doc createTextNode {}]
    }

    proc get-ping {} {
	setup-mnc doc mnc

        $mnc appendChild [$doc createTextNode "pong"]
        return [$mnc asXML]
    }

    proc get-towns { {since {}}} {
	setup-mnc doc mnc

	db eval "select townid,title from atown order by 1" a {
	    $mnc appendChild [$doc createElement town town]
	    $town setAttribute town-id $a(townid)
	    $town appendChild [$doc createTextNode $a(title)]
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-services {{townid {}} {since {}}} {
	setup-mnc doc mnc

	db eval "select serviceid,title from aservice" a {
	    $mnc appendChild [$doc createElement service service]
	    $service setAttribute service-id $a(serviceid)
	    $service appendChild [$doc createTextNode $a(title)]
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-banks {{since {}}} {
	setup-mnc doc mnc

	db eval "select mfo,title,status from abank" a {
	    $mnc appendChild [$doc createElement bank bank]
	    $bank setAttribute mfo $a(mfo)
	    $bank setAttribute status $a(status)
	    $bank appendChild [$doc createTextNode $a(title)]
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-bankaccounts {{since {}}} {
	setup-mnc doc mnc

	db eval "select mfo,bankaccount,okpo,title,status from abankaccount" a {
	    $mnc appendChild [$doc createElement bankaccount bankaccount]
	    $bankaccount setAttribute mfo $a(mfo)
	    $bankaccount setAttribute account $a(bankaccount)
	    $bankaccount setAttribute status $a(status)
	    $bankaccount appendChild [$doc createElement organization organization]
	    $organization setAttribute okpo $a(okpo)
	    $organization appendChild [$doc createTextNode $a(title)]
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-scripts {{since {}}} {
	setup-mnc doc mnc

	db eval "select object,script,text from ascript order by object,script" a {
	    $mnc appendChild [$doc createElement script script]
	    $script setAttribute title $a(script)
	    $script appendChild [$doc createElement parameters parameters]
	    $parameters setAttribute object $a(object)
	    $script appendChild [$doc createElement text text]
	    $text appendChild [$doc createTextNode \n$a(text)\n]
	}

	return [$mnc asXML -indent 0]
    }

    proc get-reports {{since {}}} {
	setup-mnc doc mnc

	db eval "select object,report,scope,title,text from areport order by object,report" a {
	    $mnc appendChild [$doc createElement report report]
	    $report setAttribute title $a(report)
	    $report appendChild [$doc createTextNode $a(title)]
	    $report appendChild [$doc createElement parameters parameters]
	    $parameters setAttribute object $a(object)
	    $parameters setAttribute scope $a(scope)
	    $report appendChild [$doc createElement template template]
	    $template appendChild [$doc createTextNode \n$a(text)\n]
	}

	return [$mnc asXML -indent 0]
    }

    proc get-agreements {{since {}}} {
	setup-mnc doc mnc

	set q "
select agreementid, code, title, symbol3, symbol4, reports, params
  from aagreementitem
 order by agreementid, code
"
	array set item {}
	db eval $q a {
	    lappend item($a(agreementid)) \
		[list $a(code) $a(title) $a(symbol3) $a(symbol4) $a(reports) $a(params)]
	}
	catch {unset a}
	unset q

	set q "
select agreementid, 
       title,
       okpo,
       mfo,
       bankaccount,
       serviceid,
       symbol1,
       symbol2,
       reports,
       params,
       destination,
       group1,
       group2
  from aagreement
 order by agreementid
"
	db eval $q a {
	    $mnc appendChild [$doc createElement agreement agreement]
	    $agreement setAttribute agreement-id $a(agreementid)
	    $agreement setAttribute service-id $a(serviceid)
	    $agreement appendChild [$doc createTextNode $a(title)]
	    $agreement appendChild [$doc createElement bankaccount bankaccount]
	    $bankaccount setAttribute mfo $a(mfo)
	    $bankaccount setAttribute account $a(bankaccount)
	    $bankaccount appendChild [$doc createElement organization organization]
	    $organization setAttribute okpo $a(okpo)
	    $agreement appendChild [$doc createElement destination destination]
	    $destination appendChild [$doc createTextNode $a(destination)]
	    $agreement appendChild [$doc createElement parameters parameters]
	    set s ""
	    append s symbol1=\"$a(symbol1)\"\;
	    append s symbol2=\"$a(symbol2)\"\;
	    append s group1=\"$a(group1)\"\;
	    append s group2=\"$a(group2)\"\;
	    append s reports=\"$a(reports)\"\;
	    append s params=\"$a(params)\"\;
	    $parameters appendChild [$doc createTextNode $s]
	    if {[info exists item($a(agreementid))]} {
		foreach i $item($a(agreementid)) {
		    $agreement appendChild [$doc createElement item item]
		    $item setAttribute item-id [lindex $i 0]
		    $item appendChild [$doc createTextNode [lindex $i 1]]
		    $item appendChild [$doc createElement parameters parameters]
		    set s ""
		    append s symbol3=\"[lindex $i 2]"\;
                append s symbol4=\"[lindex $i 3]"\;
		    append s reports=\"[lindex $i 4]"\;
                append s params=\"[lindex $i 5]"\;
		    $parameters appendChild [$doc createTextNode $s]
		}
	    }
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-streets {{townid {}} {since {}}} {
	setup-mnc doc mnc

	db eval "select streetid,street_type,title from astreet" a {
	    $mnc appendChild [$doc createElement street street]
	    $street setAttribute street-id $a(streetid)
	    $street appendChild [$doc createTextNode $a(title)]
	    $street appendChild [$doc createElement type type]
	    $type appendChild [$doc createTextNode $a(street_type)]
	}

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc load-accounts {flat townid streetid buildid flatid} {
	set q "
select a.serviceid serviceid,
       a.title account,
       a.lastdate lastdate,
       a.lastrest lastrest,
       r.title service,
       a.fullname fullname,
       a.comments comments
  from aaccount a,
       astreet s,
       aservice r
 where a.townid = s.townid 
   and a.streetid = s.streetid 
   and a.serviceid = r.serviceid
   and a.townid = '$townid'
   and a.streetid = '$streetid'
   and a.build = '$buildid'
   and a.flat = '$flatid'
 order by r.title, a.title, a.lastdate desc
"
	set doc [$flat ownerDocument]
	db eval $q a {
	    $flat appendChild [$doc createElement account account]
	    $account setAttribute service-id $a(serviceid) 
	    $account setAttribute account-id $a(account)
	    $account appendChild [$doc createElement rem rem]
	    $rem appendChild [$doc createTextNode $a(service)]	
	    $account appendChild [$doc createElement rem rem]
	    $rem appendChild [$doc createTextNode $a(fullname)]
	    $account appendChild [$doc createElement rem rem]
	    $rem appendChild [$doc createTextNode $a(comments)]
	    $account appendChild [$doc createElement rest rest]
	    $rest setAttribute date $a(lastdate)
	    $rest appendChild [$doc createTextNode $a(lastrest)]
	}
    }

    proc get-flat-accounts {townid streetid buildid flatid} {
	if {$townid == ""} {
	    set townid $::aserv::default_townid
	}
	set q "
select distinct t.title town, s.street_type || ' ' || s.title street
  from astreet s, atown t
 where s.townid = t.townid 
   and s.townid = '$townid' 
   and s.streetid = '$streetid'
 order by t.title, s.street_type, s.title
"
	setup-mnc doc mnc

	$mnc appendChild [$doc createElement flat flat]
	$flat setAttribute town-id $townid
	$flat setAttribute street-id $streetid
	$flat setAttribute build-id $buildid
	$flat setAttribute flat-id $flatid
	$flat appendChild [$doc createElement rem rem]
	db eval $q a {
	    set s ""
	    if {$townid != $::aserv::default_townid} {
		append s $a(town) " "
	    }
	    append s $a(street) " " $buildid
	    if {$flatid != "0"} {
		append s " " $flatid
	    }
	    $rem appendChild [$doc createTextNode $s]
	    break
	}

	load-accounts $flat $townid $streetid $buildid $flatid

	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    proc get-account-accounts {townid serviceid accountid} {
	if {$townid == ""} {
	    set townid $::aserv::default_townid
	}
	set q "
select distinct t.title town, 
       s.street_type || ' ' || s.title street,
       a.streetid streetid,
       a.build buildid, 
       a.flat flatid
  from aaccount a, astreet s, atown t
 where a.townid = t.townid 
   and a.townid = s.townid 
   and a.streetid = s.streetid 
   and a.townid = '$townid'
   and a.serviceid = '$serviceid'
   and a.title = '$accountid'
 order by t.title, s.street_type, s.title, a.build, a.flat
"
	setup-mnc doc mnc

	$mnc appendChild [$doc createElement flat flat]
	db eval $q a {
	    $flat setAttribute town-id $townid
	    $flat setAttribute street-id $a(streetid)
	    $flat setAttribute build-id $a(buildid)
	    $flat setAttribute flat-id $a(flatid)
	    $flat appendChild [$doc createElement rem rem]
	    set s ""
	    if {$townid != $::aserv::default_townid} {
		append s $a(town) " "
	    }
	    append s $a(street) " " $a(buildid)
	    if {$a(flatid) != "0"} {
		append s " " $a(flatid)
	    }
	    $rem appendChild [$doc createTextNode $s]
	    break
	}

	if {[info exists a]} {
	    load-accounts $flat $townid $a(streetid) $a(buildid) $a(flatid)
	} else {
            # flat not found
	}
	
	return [$mnc asXML -indent $::aserv::source::sqlite::xml_indent]
    }

    namespace export init done get get-*

} ;# namespace ::aserv::source::sqlite

package require Tclx
snit::type shutter {
    option -strobeoffset
    option -commands
    option -logger
    variable strobeSpeed

    method parse_strobe { _i _lines } {
	upvar $_i      i
	upvar $_lines  lines
	
	set linecnt [llength $lines]
	for {incr i} { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]
	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue

	    } elseif { [regexp {CHANNELTYPE[[:blank:]]+RANGE[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
	    } elseif { [regexp {OPEN[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
		lappend options(-commands) [list open_shutter $from $to]
	    } elseif { [regexp {([0-9]*\.?[0-9]*)[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)} $line p speed dmxvalue] } {
		lappend strobeSpeed [list $speed $dmxvalue]
	    } else {
		incr i -1
		break
	    }
	}
	
	foreach {sp1 sp2} $strobeSpeed {
	    lassign $sp1 speed1 dmxvalue1
	    lassign $sp2 speed2 dmxvalue2
	    if { $dmxvalue1 < $dmxvalue2 } {
		lappend options(-commands) [list strobe $dmxvalue1 $dmxvalue2 $speed1 $speed2]
	    } else {
		lappend options(-commands) [list strobe $dmxvalue2 $dmxvalue1 $speed2 $speed1]
	    }
	}
    }
}

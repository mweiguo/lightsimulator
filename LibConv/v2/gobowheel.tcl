snit::type gobowheel {
    option -offset
    option -gobotable
    option -commands
    option -logger

    method parse { _i _lines } {
	upvar $_i     i
	upvar $_lines lines
	set linecnt [llength $lines]
	for {incr i} { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]

	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue
	    } elseif {[regexp {(\".*\")[[:blank:]]*(\".*\")} $line p name bmp]} {
		lappend options(-gobotable) [list $name $bmp]
		set slotid [llength options(-gobotable)]
		
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {STATIC[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
			lappend options(-commands) [list gobowheel_slot $from $to $slotid ]
		    } else {
			incr i -1
			break
		    }
		}
	    } elseif { [regexp {OPEN[[:blank:]]+FIXED} $line] } {
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {STATIC[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
			lappend options(-commands) [list gobowheel_slot $from $to 0 ]
		    } else {
			incr i -1
			break
		    }
		}		
	    } else {
		incr i -1
		break
	    }
	}
    }
}

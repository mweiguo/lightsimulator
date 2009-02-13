snit::type effectwheel {
    option -offset
    option -effecttable
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
		lappend options(-effecttable) [list $name $bmp]
		#		set slotid [llength options(-gobotable)]
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {ROTATING[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
			#			lappend options(-commands) [list gobowheel_slot $from $to $slotid ]
		    } else {
			incr i -1
			break
		    }
		}
	    } elseif { [regexp {EFFECT_ROTATION[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p rotate_offset] } {
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {(\-?[0-9]+\.?[0-9]*)[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p degree from to] } {
		    } elseif {[regexp {(\-?[0-9]+\.?[0-9]*)[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)} $line p degree dmxvalue]} {
		    } else {
			incr i -1
			set breakeffectrotate 1
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

snit::type Mirror {
    option -panoffset
    option -tiltoffset
    option -width
    option -height
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
	    } elseif {[regexp {GAP[[:blank:]]+WIDTH[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p width unit]} {
		set options(-width) $width
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif {[regexp {HEIGHT[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p height unit]} {
			set options(-height) $height
		    } else {
			incr i -1
			break
		    }
		}		
	    } elseif {[regexp {PAN[[:blank:]]+INVERTABLE[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p offset]} {
		set options(-panoffset) $offset
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif {[regexp {(\-?[0-9]+\.?[0-9]*)[[:blank:]]+DEGREES[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)} $line p degree dmxvalue]} {
			lappend panvalues [list $degree $dmxvalue]
		    } else {
			incr i -1
			break
		    }
		}		
	    } elseif {[regexp {TILT[[:blank:]]+INVERTABLE[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p offset]} {
		set options(-tiltoffset) $offset
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif {[regexp {(\-?[0-9]+\.?[0-9]*)[[:blank:]]+DEGREES[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)} $line p degree dmxvalue]} {
			lappend tiltvalues [list $degree $dmxvalue]
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

	foreach {pan1 pan2} $panvalues {
	    lassign $pan1 degree1 dmx1
	    lassign $pan2 degree2 dmx2
	    if { $degree1 < $degree2 } {
		lappend options(-commands) [list pan $dmx1 $dmx2 $degree1 $degree2]
	    } else {
		lappend options(-commands) [list pan $dmx2 $dmx1 $degree2 $degree1]
	    }
	}

	foreach {tilt1 tilt2} $panvalues {
	    lassign $tilt1 degree1 dmx1
	    lassign $tilt2 degree2 dmx2
	    if { $degree1 < $degree2 } {
		lappend options(-commands) [list tilt $dmx1 $dmx2 $degree1 $degree2]
	    } else {
		lappend options(-commands) [list tilt $dmx2 $dmx1 $degree2 $degree1]
	    }
	}
    }
}

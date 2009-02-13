snit::type colorwheel {
    option -offset
    option -colortable
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
	    } elseif {[regexp {SCROLLING} $line]} {
		set breakscrolling 0
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {CW} $line] } {
			for {incr i} { $i < $linecnt } { incr i } {
			    set line [lindex $lines $i]
			    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
				continue
			    }
			    if { [regexp {FAST[[:blank:]]+AT[[:blank:]]+([[:digit:]])} $line p fast] } {
			    } elseif { [regexp {SLOW[[:blank:]]+AT[[:blank:]]+([[:digit:]])} $line p slow] } {
			    } else { 
				incr i -1
				set breakscrolling 1
				break
			    }
			}
			lappend options(-commands) [list scroll_colorwheel_cw $slow $fast]
			if { $breakscrolling } break
		    } elseif { [regexp {CCW} $line] } {
			for {incr i} { $i < $linecnt } { incr i } {
			    set line [lindex $lines $i]
			    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
				continue
			    }
			    if { [regexp {FAST[[:blank:]]+AT[[:blank:]]+([[:digit:]])} $line p fast] } {
			    } elseif { [regexp {SLOW[[:blank:]]+AT[[:blank:]]+([[:digit:]])} $line p slow] } {
			    } else { 
				incr i -1
				set breakscrolling 1
				break
			    }
			}
			lappend options(-commands) [list scroll_colorwheel_ccw $slow $fast]
			if { $breakscrolling } break
		    } else {
			break
		    }
		}
	    } elseif {[regexp {OPEN[[:blank:]]FIXED} $line]} {
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {SCROLLING[[:blank:]]+FROM[[:blank:]]+([[:digit:]])[[:blank:]]+TO[[:blank:]]+([[:digit:]])} $line p from to] } {
		    } else { 
			incr i -1
			break
		    }
		}		
		lappend options(-commands) [list scroll_colorwheel $from $to end 0]
	    } elseif {[regexp {(\".*\")[[:blank:]]+RGB[[:blank:]]+([[:digit:]]+)[[:blank:]]+([[:digit:]]+)[[:blank:]]+([[:digit:]]+)} $line p name r g b]} {
		lappend options(-colortable) [list $name $r $g $b]
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]   
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {SCROLLING[[:blank:]]+FROM[[:blank:]]+([[:digit:]]+)[[:blank:]]+TO[[:blank:]]+([[:digit:]]+)} $line p from to] } {
		    } else {
			incr i -1
			break
		    }
		}
		set slotid [llength options(-colortable)]
		lappend options(-commands) [list scroll_colorwheel $from $to [expr $slotid - 1] $slotid]
	    } else {
		incr i -1
		break
	    }
	}
    }

}

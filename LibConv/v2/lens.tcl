
snit::type Lens {
    option -logger -default ""

    method parse { _i _lines } {
	upvar $_i      i
	upvar $_lines  lines

	set linecnt [llength $lines]
	for {} { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]

	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue
	    } elseif { [regexp {LENS[[:blank:]]+DIAMETER[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p d unit] } {
		incr i;		set line [lindex $lines $i]
		if { [regexp {OFFSET[[:blank:]]+VERTICAL[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p d unit] } {
		}	
		incr i;		set line [lindex $lines $i]
		if { [regexp {HORIZONTAL[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p d unit] } {
		}	
	    } elseif { [regexp {CURVE[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)[[:blank:]]+DEGREES} $line p degree] } {
		$self add_angle $degree
		$self parse_curve i lines
	    } elseif { [regexp {GRID[[:blank:]]+AT[[:blank:]]+([[:digit:]]+\.?[[:digit:]]+)[[:blank:]]+DEGREES} $line p degree] } {
 		$self parse_grid i lines
	    } else {
		incr i -1
		break
	    }
	}
    }

    method add_para { degree lux } {
    }

    method add_angle { degree } {
    }

    method parse_curve { _i _lines } {
	upvar $_i      i
	upvar $_lines  lines

	set linecnt [llength $lines]
	for {incr i} { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]
	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue
	    } elseif { [regexp {([[:digit:]]+\.[[:digit:]]+)[[:blank:]]+AT[[:blank:]]+([[:digit:]]+\.?[[:digit:]]+)} $line p lux degree] } {
		$self add_para $degree $lux
	    } else {
		incr i -1
		break
	    }
		    
	}
    }

    method parse_grid { _i _lines } {
	upvar $_i      i
	upvar $_lines  lines

	set linecnt [llength $lines]
	for {} { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]
	
	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue
	    } elseif { [regexp {HORIZONTAL[[:blank:]]+DEGREES} $line] } {
		for { incr i } { $i < $linecnt } { incr i } {
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif {} {
		    } else {
			incr i -1
			break
		    }
		}
	    } else {
		break
	    }
	}
    }
}

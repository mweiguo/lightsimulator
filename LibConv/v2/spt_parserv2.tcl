package require snit

snit::type Logger {
    option -enable       -default 1
    option -destination  -default stdout
    method log { value } {
	if { $options(-enable) } {
	    puts $options(-destination) $value
	}
    }
}

snit::type Fixture {
    option -enablelog
    option -colorwheels
    option -gobowheels
    option -effectwheels
    option -shutter
    option -wattage
    option -lenses
    option -mirror
    variable logger
    
    constructor { args } {
	$self configurelist $args
	# logger
	set logger [Logger logger -enable 1]
	# lenses
	lappend options(-lenses) [Lens lens -logger $logger]
    }
    
    method output {} {
	$logger log "colorwheel information"
	foreach colorwheel $options(-colorwheels) {
	    foreach slot [$colorwheel cget -colortable] {
		$logger log "\t$slot"
	    }
	    foreach command [$colorwheel cget -commands] {
		$logger log "\t$command"
	    }
	}

	$logger log "gobowheel information"
	foreach gobowheel $options(-gobowheels) {
	    foreach slot [$gobowheel cget -gobotable] {
		$logger log "\t$slot"
	    }
	    foreach command [$gobowheel cget -commands] {
		$logger log "\t$command"
	    }
	}

	$logger log "effectwheel information"
	foreach effectwheel $options(-effectwheels) {
	    foreach slot [$effectwheel cget -effecttable] {
		$logger log "\t$slot"
	    }
	    foreach command [$effectwheel cget -commands] {
		$logger log "\t$command"
	    }
	}

	$logger log "shutter information"
	foreach command [$options(-shutter) cget -commands] {
	    $logger log "\t$command"
	}
	
    }
    
    method parse { filename } {
	set f [open $filename]
	set data [read $f]
	close $f

	set lines [split $data "\n"]
	set linecnt [llength $lines]
	for { set i 0 } { $i < $linecnt } { incr i } {
	    set line [lindex $lines $i]
	    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
		continue
	    } elseif { [regexp {WATTAGE[[:blank:]]+([[:digit:]]+)} $line p options(-wattage)] } {
		logger log "WATTAGE options(-wattage)"
	    } elseif { [regexp {CURVE[[:blank:]]+AT[[:blank:]]+([[:digit:]]+)[[:blank:]]+DEGREES} $line p degree] } {
		set lens [lindex $options(-lenses) 0]
		$lens add_angle $degree
		$lens parse_curve i lines
	    } elseif { [regexp {YOKE[[:blank:]]+HEIGHT[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p height unit] } {
		for {incr i} { $i < $linecnt } { incr i } {
		    set line [lindex $lines $i]
		    if { [regexp {^[[:blank:]]*$} $line] || [regexp "\#msdversion" $line] || [regexp "\#mendversion" $line] } {
			continue
		    } elseif { [regexp {WIDTH[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p width unit] } {
		    } elseif { [regexp {DEPTH[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p depth unit] } {
		    } elseif { [regexp {THICKNESS[[:blank:]]+VERTICAL[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p vertical unit] } {
		    } elseif { [regexp {horizontal[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p horizontal unit] } {
		    } elseif { [regexp {CONNECTION[[:blank:]]+OFFSET[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p connection unit] } {
		    } else {
			break
		    }
		}
	    } elseif { [regexp {COLOR_WHEEL[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p off] } {
		colorwheel cwheel -offset $off -logger $logger
		cwheel parse i lines
		lappend options(-colorwheels) cwheel
	    } elseif { [regexp {GOBO_WHEEL[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p off] } {
		gobowheel gwheel -offset $off -logger $logger
		gwheel parse i lines
		lappend options(-gobowheels) gwheel
	    } elseif { [regexp {STROBE[[:blank:]]+OFFSET[[:blank:]]+([[:digit:]]+)} $line p off] } {
		shutter sh -strobeoffset $off -logger $logger
		sh parse_strobe i lines
		set options(-shutter) sh
	    } elseif { [regexp {MIRROR[[:blank:]]+SWAPABLE[[:blank:]]+DISTANCE[[:blank:]]+(\-?[0-9]+\.?[0-9]*)[[:blank:]]+([a-zA-Z])} $line p distance unit] } {
		Mirror mirror
		mirror parse i lines
	    } else {
		continue
	    }
	}
    }
}

if { 1 } {
    source lens.tcl
    source colorwheel.tcl
    source gobowheel.tcl
    source shutter.tcl

    Fixture f
    f parse {W:\VirtualTheater\svn\cp\tools\fixtureLibs\Spots\Abstract\Abstract XP3 Spin.spt}
    f output
}
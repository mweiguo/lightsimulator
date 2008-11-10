package require snit

# if this element exist, the fixture should be scanner

namespace eval SptParser {
    snit::type EMirror {

	typevariable KeyWord1 {GAP PAN TILT SPEED }
        typevariable Cmd -array { pan "pan" tilt "tilt"}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
	    #            puts "in $type"
            set line [SptParser::remove_comments [lindex $data $i]]

	    if { ![SptParser::parse_line "mirror swapable distance num unit" $line "0 1 2"] } {
		if { ![SptParser::parse_line "mirror distance num unit" $line "0 1"] } {
		    SptParser::PutsVars i line
		}
	    }

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [lsearch $SptParser::KeyWords $key] != -1  } {
                    return [expr $i - 1 ]
                }

                if { $key == "GAP"} {
                    if { ![SptParser::parse_line "gap width num unit" $line "0 1"] } { SptParser::PutsVars i line }
                    set i [$type parse_gap $i $data]
                } elseif { $key == "PAN" } {
		    if { [regexp -nocase {pan[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)} $line p offtilt] ||
			 [regexp -nocase {pan[ \t]+offset[ \t]+([0-9]+)} $line p offtilt] } {

			lappend fixture(CHANNELS) $offtilt
			lappend fixture($offtilt,COMMAND) $Cmd(tilt)
			set i [$type parse_tilt fixture $i $data $offtilt]
		    } else {
			SptParser::PutsVars i line
		    }
                } elseif { $key == "TILT" } {
		    if { [regexp -nocase {tilt[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)} $line p offpan] ||
			 [regexp -nocase {tilt[ \t]+offset[ \t]+([0-9]+)} $line p offpan] } {
			lappend fixture(CHANNELS) $offpan
			lappend fixture($offpan,COMMAND) $Cmd(pan)
			set i [$type parse_pan fixture $i $data $offpan]
                    } else {
			SptParser::PutsVars i line
		    }
                } elseif { $key == "SPEED" } {
                    if { ![SptParser::parse_line "speed fixed at num" $line "0 1 2"] } {
			if { ![SptParser::parse_line "speed invertable offset num" $line "0 1 2"] } {
			    if { ![SptParser::parse_line "speed VARIABLE offset num" $line "0 1 2"] } {
				SptParser::PutsVars i line
			    }
			}
			set i [$type parse_speed $i $data]
		    }
                }

            }

	    #            puts "out $type"
	    return [expr $i - 1]
    	}

	typemethod parse_gap { i data } {
	    incr i
	    set line [lindex $data $i]
	    if { ![SptParser::parse_line "height num unit" $line 0] } {
		SptParser::PutsVars i line
	    }
	    return $i
	}

	typemethod parse_pan {fix i data channel} {
            upvar $fix     fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [regexp -nocase {([0-9.-]+)[ \t]+degrees[ \t]+at[ \t]+([0-9]+)} $line p degree off] } {
		    if { ![info exists mindeg ] } {
			set mindeg $degree
		    } else {
			if { $mindeg > $degree } {
			    set tmp $mindeg
			    set mindeg $degree
			    set maxdeg $tmp
			} else {
			    set maxdeg $degree
			}
			lappend fixture($channel,$Cmd(pan)) [list 0 255 STEP $maxdeg $mindeg]
		    }
                } else {
                    break
                }
            }

            return [expr $i-1]
	}

	typemethod parse_tilt {fix i data channel} {
            upvar $fix     fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [regexp -nocase {([0-9.-]+)[ \t]+degrees[ \t]+at[ \t]+([0-9]+)} $line p degree off] } {
		    if { ![info exists mindeg ] } {
			set mindeg $degree
		    } else {
			if { $mindeg > $degree } {
			    set tmp $mindeg
			    set mindeg $degree
			    set maxdeg $tmp
			} else {
			    set maxdeg $degree
			}
			# to do this because VTV have different directions with real fixture
			lappend fixture($channel,$Cmd(tilt)) [list 0 255 STEP [expr $maxdeg - 90] [expr $mindeg - 90]]
		    }
                } else {
                    break
                }
            }

            return [expr $i-1]
	}

	typemethod parse_speed { i data } {

	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } {	return [expr $i - 1 ] }
		if { [lsearch $KeyWord1 $key] != -1  } { return [expr $i - 1 ] }

		if { ![SptParser::parse_line "num at num" $line 1] } {
		    if { ![SptParser::parse_line "num from num to num" $line "1 3"] } {
			SptParser::PutsVars i line
		    }
		}
	    }
	    return [expr $i - 1]
	}


    }
}


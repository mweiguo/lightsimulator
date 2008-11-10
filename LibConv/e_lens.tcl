package require snit

namespace eval SptParser {

    snit::type ELens {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

	    if { [regexp -nocase {(^[ \t]*LENS)([ \t]+)(DIAMETER)} $line p a1 a2 a3] } {

                if { ![SptParser::parse_line "keyword diameter num unit" $line 1] } {
		    SptParser::PutsVars i line
		}
                return [$type parse_dimension $i $data]

            } elseif { [regexp -nocase {(lens)([ \t]+)(".+")([ \t]*)(\#msdversion)([ \t]*)([<>=]+)([ \t]*)([0-9\-\.]+)} $line p key a1 name a2 macro a3 operator a4 version] } {
                if { [info exists macro]==1 && $macro=="msdversion" } {
                    set rtn [SptParser::parse_define $i $data "$macro $operator $version"]
                    incr rtn
                    set line [SptParser::remove_comments [lindex $data $i]]
                }
		return [$type parse_attributes $i $data $name fixture]
	    } elseif {[regexp -nocase {(lens)([ \t]+)(".+")} $line p key a1 name]} {
		return [$type parse_attributes $i $data $name fixture]
            }
	    return [expr $i-1]
    	}

    	typemethod parse_dimension {i data} {
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }

		switch $key {
                    OFFSET {
			if { ![SptParser::parse_line "offset vertical num unit" $line "0 1"] } {
			    SptParser::PutsVars i line
			}
		    }
		    HORIZONTAL {
			if { ![SptParser::parse_line "horizontal num unit" $line "0"] } {
			    SptParser::PutsVars i line
			}
		    }
		    default {
			SptParser::PutsVars i line
		    }
		}
	    }
	    return [expr $i - 1 ]
    	}

    	typemethod parse_attributes {i data name fix} {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [regexp -nocase {(curve)([ \t]+)(at)([ \t]+)([0-9\.\-]+)([ \t]+)(degrees)} $line p key1 s1 key2 s2 degree s3 key3] } {
		    if { [regexp -nocase {(standard)} $name p] } {
			if {![info exists fixture(MAXOPENING)]} {
			    set fixture(MAXOPENING) $degree
			} elseif { $fixture(MAXOPENING) < $degree } {
			    set fixture(MINOPENING) $fixture(MAXOPENING)
			    set fixture(MAXOPENING) $degree
			} elseif { $fixture(MAXOPENING) >= $degree } {
			    set fixture(MINOPENING) $degree
			}
		    } else {
			if {![info exists fixture(SEMIMAXOPENING)]} {
			    set fixture(SEMIMAXOPENING) $degree
			} elseif { $fixture(SEMIMAXOPENING) < $degree } {
			    set fixture(SEMIMINOPENING) $fixture(SEMIMAXOPENING)
			    set fixture(SEMIMAXOPENING) $degree
			} elseif { $fixture(SEMIMINOPENING) >= $degree } {
			    set fixture(SEMIMINOPENING) $degree
			}
		    }
		    set i [$type parse_curve $i $data]
		} elseif { [regexp -nocase {(grid)([ \t]+)(at)([ \t]+)([0-9\.\-]+)([ \t]+)(degrees)} $line p key1 s1 key2 s2 degree s3 key3] } {
		    set i [$type parse_grid $i $data]
		} else {
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			if {![info exists fixture(MAXOPENING)]} {
			    if { [info exists fixture(SEMIMINOPENING)]} {
				set fixture(MINOPENING) $fixture(SEMIMINOPENING)
			    }
			    if { [info exists fixture(SEMIMAXOPENING)]} {
				set fixture(MAXOPENING) $fixture(SEMIMAXOPENING)
			    }
			}
			return [expr $i-1 ]
		    }
		    SptParser::PutsVars i line
		    break
		}
	    }
	    if {![info exists fixture(MAXOPENING)]} {	
		if { [info exists fixture(SEMIMINOPENING)]} {
		    set fixture(MINOPENING) $fixture(SEMIMINOPENING)
		}
		if { [info exists fixture(SEMIMAXOPENING)]} {
		    set fixture(MAXOPENING) $fixture(SEMIMAXOPENING)
		}
	    }

	    return [expr $i - 1 ]
    	}

    	typemethod parse_curve {i data} {
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } {	return [expr $i - 1 ] }

		if { [regexp -nocase {([0-9\.\-]+)([ \t]+)(at)([ \t]+)([0-9\.\-])} $line p num1 s1 key s2 num2] } {
		} else {
		    SptParser::PutsVars i line
		    break
		}
	    }
	    return [expr $i - 1 ]
    	}

    	typemethod parse_grid { i data} {
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } {	return [expr $i - 1 ] }

                if { $key == "HORIZONTAL" } {
                    if { ![SptParser::parse_line "horizontal degrees" $line "0 1"] } { SptParser::PutsVars i line }
                } elseif { $key == "AT" } {
                    if { ![SptParser::parse_line "at num vertical" $line "0 2"] } { SptParser::PutsVars i line }
                } else {
		    #                    puts "these are data:  $i : $line"
                }
	    }
	    return [expr $i - 1 ]
    	}
    }
}
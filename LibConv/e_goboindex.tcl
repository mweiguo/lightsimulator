package require snit
namespace eval SptParser {

    snit::type EGobo_index {

        typemethod parse { xmlRoot fix i data } {
            upvar $xmlRoot root
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "gobo_index offset num" $line "0 1"] } {
				SptParser::PutsVars i line
			}

    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

  				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [SptParser::parse_channeltype $line] } {
                    continue
				} elseif { [SptParser::parse_line "num at num" $line 1] } {
                    continue
                } elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
                    continue
				} else {
                    set key [lindex $line 0]
                    set key1 [lindex $line 1]
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {	return [expr $i - 1 ] }
					SptParser::PutsVars i line
				}
			}

			return [expr $i - 1]
    	}
    }
}


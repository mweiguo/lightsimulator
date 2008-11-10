package require snit
namespace eval SptParser {

    snit::type EEffect_index {

        typemethod parse { xmlRoot fix i data } {
            upvar $xmlRoot root
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "effect_index offset num" $line "0 1"] } {
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
				} else {
					lassign $line key key1 key2
					if { [lsearch $SptParser::KeyWords $key] != -1  } {
#						puts "out [lindex [info level 0] 0]"
						return [expr $i - 1 ]
					}
					SptParser::PutsVars i line
				}
			}
#   		puts "out effectindex: $line : $i"
			return [expr $i - 1]
    	}
    }
}


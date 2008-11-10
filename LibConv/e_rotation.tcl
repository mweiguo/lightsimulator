package require snit
namespace eval SptParser {

    snit::type ERotation {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "rotation offset vertical num unit" $line "0 1 2"] } {
				SptParser::PutsVars i line
			}

			incr i
    		set line [lindex $data $i]
			if { ![SptParser::parse_line "horizontal num unit" $line 0] } {
				SptParser::PutsVars i line
			}

			return $i
    	}
    }
}

package require snit
namespace eval SptParser {

    snit::type EShape {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "shape cylinder" $line "0 1"] } {
				if { ![SptParser::parse_line "shape cube" $line "0 1"] } {
					SptParser::PutsVars i line
				}
			}

			return $i
    	}
    }
}


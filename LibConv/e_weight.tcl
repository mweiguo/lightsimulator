package require snit
namespace eval SptParser {

    snit::type EWeight {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "weight num unit" $line 0] } {
				SptParser::PutsVars i line
			}
			return $i
    	}
    }
}


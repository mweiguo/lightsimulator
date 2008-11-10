package require snit
namespace eval SptParser {

    snit::type EHeight {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

	    if { ![SptParser::parse_line "height num unit" $line 0] } {
		SptParser::PutsVars i line
	    }
	    return $i
    	}
    }
}

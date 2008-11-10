package require snit
namespace eval SptParser {

    snit::type ESpot {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line {spot "manufactor"} $line 0] } {
				SptParser::PutsVars i line
			}
#            puts "out $type"
			return $i
    	}
    }
}
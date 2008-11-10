package require snit
namespace eval SptParser {

    snit::type EProperty {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line {property "file" = "filename"} $line "0 2"] } {
				SptParser::PutsVars i line
			}
			return $i
    	}
    }
}

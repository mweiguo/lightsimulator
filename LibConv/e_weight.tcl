package require snit
namespace eval SptParser {

    snit::type EWeight {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

	    if { [regexp -nocase {weight[ \t]+([0-9]+[\.0-9]+)[ \t]+kg} $line p weight] } {
		set fixture(WEIGHT) $weight
	    }
	    return $i
    	}
    }
}


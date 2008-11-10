package require snit
namespace eval SptParser {

    snit::type EWattage {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

	    if { [regexp -nocase {wattage[ \t]+([0-9\.]+)} $line p wat] } {
		set fixture(WATTAGE) $wat
	    }
	    return $i
    	}
    }
}

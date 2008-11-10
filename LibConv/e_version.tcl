package require snit
namespace eval SptParser {

    snit::type EVersion {

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

            if { [regexp {^[ \t]*version[ \t]*=[ \t]*[^ \t]+[ \t]*} $line] } {
				SptParser::PutsVars i line
			}
			return $i
    	}
    }
}


#puts [regexp {^[ \t]*version[ \t]*=[ \t]*[^ \t]+[ \t]*} { version = 2 }]

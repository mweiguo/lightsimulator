package require snit
namespace eval SptParser {

    snit::type ECurve {
	#       typevariable Cmd -array { pan "pan" tilt "tilt" movespeed "set_movespeed"}
        typemethod parse { ct fix i data } {
            upvar $ct channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

            for {} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [regexp -nocase {curve[ \t]+at[ \t]+([0-9\.]+)[ \t]+degrees} $line p degree] } {
		    if { ![info exists fixture(MINOPENING)] } {
			set fixture(MINOPENING) $degree
			set fixture(MAXOPENING) $degree
		    } else {
			if { $fixture(MINOPENING) > $degree } { 
			    set fixture(MINOPENING) $degree 
			} elseif { $fixture(MAXOPENING) < $degree } {	            
			    set fixture(MAXOPENING) $degree
			}
		    }

                    set i [$type parse_para $i $data fixture]
# 		    lappend fixture(OPENNING) $degree
# 		    lsort $fixture(OPENNING)
# 		    switch -glob -- [llength $fixture(OPENNING)] {
# 			0           {}
# 			1           { set fixture(MINOPENING) 0;                set fixture(MAXOPENING) [lindex $fixture(OPENNING) 0] }
# 			default     { set fixture(MINOPENING) [lindex $fixture(OPENNING) 0]; set fixture(MAXOPENING) [lindex $fixture(OPENNING) end] }
# 		    }
                    continue

                } else {
                    regexp -nocase {[ \t]*([^ \t]*)[ \t]*} $line p s1 key s2
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			return [expr $i - 1 ]
		    }
                    SptParser::PutsVars i line
		    break
                }
            }
            return [expr $i-1]
    	}

        typemethod parse_para { i data fix } {
	    upvar $fix fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}


                if { [regexp -nocase {([0-9\.\-]+)([ \t]+)(at)([ \t]+)([0-9\.]+)} $line p num1 s1 key s2 num2] } {
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
                    SptParser::PutsVars i line
                    break
                }
            }

            return [expr $i-1]
        }
    }
}

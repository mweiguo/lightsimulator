package require snit
namespace eval SptParser {

    snit::type ENat {
		typevariable KeyWord1 {HEAD}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

            if { [SptParser::parse_line "nat swapable distance num unit" $line "0 1 2"] } {
            } else {
                SptParser::PutsVars i line
            }

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [SptParser::parse_line "head width num unit" $line "0 1"] } {
                    set i [$type parse_head $i $data]
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

        typemethod parse_head { i data } {

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}


                if { [SptParser::parse_line "height num unit" $line 0] } {
                    continue
                } elseif { [SptParser::parse_line "depth num unit" $line 0] } {
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } { return [expr $i - 1 ] }
                    if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
                    SptParser::PutsVars i line
                    break
                }
            }

            return [expr $i-1]
        }
    }
}


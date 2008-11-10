package require snit
namespace eval SptParser {

    snit::type EEffect_rotation {
        typevariable channel
        typevariable Cmd -array { open "effectwheel_openslot" scroll "scroll_effect" rotate "rotate_effect" }

        typemethod parse { xmlRoot fix i data } {
            upvar $xmlRoot root
            upvar $fix     fixture

            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "effect_rotation offset num" $line "0 1"] } {
				SptParser::PutsVars i line
			} else {
				set channel [lindex $line 2]
			}

#			set lines {}
			set min {};   set max {}
    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

 				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [SptParser::parse_channeltype $line] } {
					continue
				} elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
					set min [lindex $line 2];		set max [lindex $line 4]
#					lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(rotate)\t\t0"
					continue
				} elseif { [SptParser::parse_line "num at num" $line 1] } {
					continue
				} else {
					set key [lindex $line 0]
					if { [lsearch $SptParser::KeyWords $key] != -1  } {
#						foreach line $lines {
#							puts $file $line
#						}
						return [expr $i - 1 ]
					}
					SptParser::PutsVars i line
				}
			}

#			foreach line $lines {
#				puts $file $line
#			}
			return [expr $i - 1]
    	}
    }
}


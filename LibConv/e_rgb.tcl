package require snit
namespace eval SptParser {

    snit::type ERgb {

        typevariable KeyWord1 {RED GREEN BLUE }
        typevariable Cmd -array { red "set_cyan" green "set_magenta" blue "set_yellow"}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]
            if { ![SptParser::parse_line "RGB" $line 0] } {
                SptParser::PutsVars i line
            }


    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}


                if { [regexp -nocase {(^[ \t]*red)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 offset] } {
                    set channeltype($offset)  COLOR
					lappend fixture(CHANNELS) $offset
					lappend fixture($offset,COMMAND) $Cmd(red)
                    set i [$type parse_red $i $data fixture $offset]
					continue
				} elseif { [regexp -nocase {(^[ \t]*green)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 offset] } {
                    set channeltype($offset)  COLOR
					lappend fixture(CHANNELS) $offset
					lappend fixture($offset,COMMAND) $Cmd(green)
                    set i [$type parse_green $i $data fixture $offset]
					continue
				} elseif { [regexp -nocase {(^[ \t]*blue)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 offset] } {
                    set channeltype($offset)  COLOR
					lappend fixture(CHANNELS) $offset
					lappend fixture($offset,COMMAND) $Cmd(blue)
                    set i [$type parse_blue $i $data fixture $offset]
                    continue
				} else {
					regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
					if { [lsearch $SptParser::KeyWords $key] != -1  } {
#                        puts "out111 [lindex [info level 0] 0]"
						return [expr $i - 1 ]
					}
					SptParser::PutsVars i line
				}
			}
            return [expr $i - 1 ]
        }

        typemethod parse_red { i data fix channel} {
			upvar $fix fixture

    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [SptParser::parse_channeltype $line] } {
					continue
				} elseif { [regexp -nocase {(^[ \t]*open)([ \t]+)([0-9]+)} $line p a1 a2 max] } {
					if { [info exists min] } {
						lappend fixture($channel,$Cmd(red)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
				} elseif { [regexp -nocase {(^[ \t]*closed)([ \t]+)([0-9]+)} $line p a1 a2 min] } {
					if { [info exists max] } {
						lappend fixture($channel,$Cmd(red)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
				} else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } {
#                        puts "out111 [lindex [info level 0] 0]"
                        return [expr $i - 1 ]
                    }
                    break
				}
			}
            return [expr $i - 1 ]
        }

        typemethod parse_green { i data fix channel} {
			upvar $fix fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [SptParser::parse_channeltype $line] } {
                    continue
				} elseif { [regexp -nocase {(^[ \t]*open)([ \t]+)([0-9]+)} $line p a1 a2 max] } {
					if { [info exists min] } {
						lappend fixture($channel,$Cmd(green)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
				} elseif { [regexp -nocase {(^[ \t]*closed)([ \t]+)([0-9]+)} $line p a1 a2 min] } {
					if { [info exists max] } {
						lappend fixture($channel,$Cmd(green)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } {
#                        puts "out111 [lindex [info level 0] 0]"
                        return [expr $i - 1 ]
                    }
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_blue { i data fix channel} {
			upvar $fix fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [SptParser::parse_channeltype $line] } {
                    continue
				} elseif { [regexp -nocase {(^[ \t]*open)([ \t]+)([0-9]+)} $line p a1 a2 max] } {
					if { [info exists min] } {
						lappend fixture($channel,$Cmd(blue)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
				} elseif { [regexp -nocase {(^[ \t]*closed)([ \t]+)([0-9]+)} $line p a1 a2 min] } {
					if { [info exists max] } {
						lappend fixture($channel,$Cmd(blue)) [list [expr 255*$min/100.0] [expr 255*$max/100.0] STEP 0 1]
					}
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } {
#                        puts "out111 [lindex [info level 0] 0]"
                        return [expr $i - 1 ]
                    }
                    break
                }
            }
            return [expr $i - 1 ]
        }

    }
}


package require snit
namespace eval SptParser {

    snit::type EColor_wheel {

        typevariable KeyWord1 {CHANNELTYPE SCROLLING OPEN }
        typevariable KeyWord2 {RGB }
        typevariable channel
        typevariable Cmd -array { open "colorwheel_slot" scroll "scroll_colorwheel" ccw "scroll_colorwheel_continue_ccw" cw "scroll_colorwheel_continue_cw"}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture

            set line [SptParser::remove_comments [lindex $data $i]]

            if { [regexp -nocase {(color_wheel)([ \t]+)(additive)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 channel] } {
    		} elseif { [regexp -nocase {(color_wheel)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
            } elseif { [regexp -nocase {(color_wheel)([ \t]+)(nooffset)} $line p key1 s1 key2] } {
               return $i
            } else {
                set $line
                SptParser::PutsVars i line
            }

    		set channeltype($channel) COLORWHEEL
            set wheel_id 0
            if { [info exists fixture(COLORWHEELS)] } {
                set wheel_id [llength $fixture(COLORWHEELS)]
            }
            lappend fixture(COLORWHEELS) $wheel_id

            set slotid 1
            for {incr i} { $i<[llength $data] } {incr i } {

                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_channeltype $line] } {
                    continue
                } elseif { [SptParser::parse_line "scrolling" $line 0] } {
                    set i [$type parse_scrolling $i $data fixture $wheel_id]
                    continue
                } elseif { [SptParser::parse_line "open" $line 0] } {
                    set i [$type parse_open $i $data fixture $wheel_id 0]
                    continue
				} elseif { [regexp {(".*")([ \t]*)(RGB)([ \t]*)([0-9]+)([ \t]*)([0-9]+)([ \t]*)([0-9]+)} $line pattern name s1 key s2 r s3 g s4 b] } {
					if { $r==255 && $g==255 && $b==255 } continue
					if { $r==0 && $g==0 && $b==0 } continue
                    set name [SptParser::replace_string $name " " ""]
                    set i [$type parse_rgb $i $data fixture $name $wheel_id $slotid]
                    lappend fixture(COLORWHEEL,$wheel_id) [list $slotid $name $r $g $b]
                    incr slotid
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    set key1 [lindex $line 1]
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
                        return [expr $i - 1 ]
                    }
                    SptParser::PutsVars i line
                }
            }

            return [expr $i+1]
        }

        typemethod parse_scrolling {i data fix wheel_id } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "ccw" $line 0] } {
                    set i [$type parse_ccw $i $data fixture $wheel_id]
                    continue
                } elseif { [SptParser::parse_line "cw" $line 0] } {
                    set i [$type parse_cw $i $data fixture $wheel_id]
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1]
        }

        typemethod parse_ccw {i data fix wheel_id} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "fast at num" $line "0 1"] } {
                    set fast [lindex $line 2]
                    if { [info exists slow] } {
                        #                       lappend lines "$channel\t\t$slow\t\t$fast\t\tfalse\t\t$Cmd(ccw)\t\t0\t\tCHANGESLOT"
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(ccw)
                        lappend fixture($channel,$Cmd(ccw)) [list $slow $fast COLORWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } elseif { [SptParser::parse_line "slow at num" $line "0 1"] } {
                    set slow [lindex $line 2]
                    if { [info exists fast] } {
                        #                       lappend lines "$channel\t\t$slow\t\t$fast\t\tfalse\t\t$Cmd(ccw)\t\t0\t\tCHANGESLOT"
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(ccw)
                        lappend fixture($channel,$Cmd(ccw)) [list $slow $fast COLORWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_cw {i data fix wheel_id} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "fast at num" $line "0 1"] } {
                    set fast [lindex $line 2]
                    if { [info exists slow] } {
                        #                       lappend lines "$channel\t\t$slow\t\t$fast\t\tfalse\t\t$Cmd(cw)\t\t0\t\tCHANGESLOT"
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(cw)
                        lappend fixture($channel,$Cmd(cw)) [list $slow $fast COLORWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } elseif { [SptParser::parse_line "slow at num" $line "0 1"] } {
                    set slow [lindex $line 2]
                    if { [info exists fast] } {
                        #                       lappend lines "$channel\t\t$slow\t\t$fast\t\tfalse\t\t$Cmd(cw)\t\t0\t\tCHANGESLOT"
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(cw)
                        lappend fixture($channel,$Cmd(cw)) [list $slow $fast COLORWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_open {i data fix wheelid slotid} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
                    regexp {(SCROLLING)([ \t]+)(FROM)([ \t]+)([^ ]+)([ \t]+)(TO)([ \t]+)([^ ]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9
                    #                   lappend lines "$channel\t\t$a5\t\t$a9\t\tfalse\t\t$Cmd(scroll)\t\t0\t\tCHANGESLOT"
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(scroll)
                    lappend fixture($channel,$Cmd(scroll)) [list $a5 $a9 COLORWHEEL_TRANSITION $wheelid $slotid $slotid]
                    continue
                } elseif { [SptParser::parse_line "static from num to num" $line "0 1 3"] } {
                    regexp {(STATIC)([ \t]+)(FROM)([ \t]+)([^ ]+)([ \t]+)(TO)([ \t]+)([^ ]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9
                    #                   lappend lines "$channel\t\t$a5\t\t$a9\t\tfalse\t\t$Cmd(open)\t\t0\t\tINDEX_SELECT"
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $a5 $a9 COLORWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [SptParser::parse_line "static at num" $line "0 1"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_rgb {i data fix name wheelid slotid} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
                    regexp {(SCROLLING)([ \t]+)(FROM)([ \t]+)([^ ]+)([ \t]+)(TO)([ \t]+)([^ ]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9
                    #                    lappend lines "$channel\t\t$a5\t\t$a9\t\tfalse\t\t$Cmd(scroll)\t\t$name\t\tCHANGESLOT"
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(scroll)
                    set fromslot [expr $slotid -1]
                    if { $fromslot < 0 } {
                        set fromslot 0
                    }
                    lappend fixture($channel,$Cmd(scroll)) [list $a5 $a9 COLORWHEEL_TRANSITION $wheelid $slotid $fromslot]
                    continue
                } elseif { [SptParser::parse_line "static from num to num" $line "0 1 3"] } {
                    regexp {(STATIC)([ \t]+)(FROM)([ \t]+)([^ ]+)([ \t]+)(TO)([ \t]+)([^ ]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9
                    #                    lappend lines "$channel\t\t$a5\t\t$a9\t\tfalse\t\t$Cmd(open)\t\t$name\t\tINDEX_SELECT"
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $a5 $a9 COLORWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [SptParser::parse_line "static at num" $line "0 1"] } {
                    continue
                } elseif { [SptParser::parse_line "indexed from num to num" $line "0 1 3"] } {
                    continue
                } else {
                    break
                }
            }

            return [expr $i - 1 ]
        }
    }
}

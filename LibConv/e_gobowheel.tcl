package require snit
namespace eval SptParser {

    snit::type EGobo_wheel {
        typevariable KeyWord1 {CHANNELTYPE SCROLLING OPEN }
        typevariable channel
        typevariable Cmd -array { open "gobowheel_slot" ccw "scroll_gobowheel_continue_ccw" cw "scroll_gobowheel_continue_cw" scroll "scroll_gobowheel" shake "gobo_shake" rotate_cw "rotate_gobo_cw" rotate_ccw "rotate_gobo_ccw" rotate "rotate_gobo"}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture

            set line [SptParser::remove_comments [lindex $data $i]]

            if { ![regexp -nocase {(gobo_wheel)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
                set $line
                SptParser::PutsVars i line
            }

            set channeltype($channel) GOBOWHEEL
            set wheel_id 0
            if { [info exists fixture(GOBOWHEELS)] } {
                set wheel_id [llength $fixture(GOBOWHEELS)]
            }
            lappend fixture(GOBOWHEELS) $wheel_id

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
                } elseif { [regexp {"(.*)"[ \t]*"(.*)"} $line pat name path] } {
                    set name [SptParser::replace_string $name " " ""]
                    lappend fixture(EFFECTS) $name
#                    set path [SptParser::replace_string $path " " ""]
                    set i [$type parse_gobo $i $data fixture $path $wheel_id $slotid]
                    lappend fixture(GOBOWHEEL,$wheel_id) [list $slotid $name $path]
                    incr slotid
                    continue
                } elseif { [regexp {(GOBO_ROTATION)([ \t]+)(OFFSET)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5] } {
                    set channeltype($a5) GOBOWHEEL
                    set i [$type parse_rotation $i $data fixture $wheel_id $a5]
                    continue
                } elseif { [regexp {(GOBO_INDEX)([ \t]+)(OFFSET)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5] } {
                    set channeltype($a5) GOBOWHEEL
                    set i [$type parse_index $i $data fixture $wheel_id $a5]
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
                        return [expr $i - 1 ]
                    }
                    SptParser::PutsVars i line
                }
            }

            return [expr $i+1]
        }

        typemethod parse_scrolling {i data fix wheel_id} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "cw" $line 0] } {
                    set i [$type parse_cw $i $data fixture $wheel_id]
                    continue
                } elseif { [SptParser::parse_line "ccw" $line 0] } {
                    set i [$type parse_ccw $i $data fixture $wheel_id]
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

                if { [regexp -nocase {(fast)([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 fast] } {
                    if { [info exists slow] } {
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(ccw)
                        lappend fixture($channel,$Cmd(ccw)) [list $slow $fast GOBOWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } elseif { [regexp -nocase {(slow)([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 slow] } {
                    if { [info exists fast] } {
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(ccw)
                        lappend fixture($channel,$Cmd(ccw)) [list $slow $fast GOBOWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_cw {i data fix wheel_id } {
            upvar $fix fixture
            #           set fast {};    set slow {}
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [regexp -nocase {(fast)([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 fast] } {
                    if { [info exists slow] } {
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(cw)
                        lappend fixture($channel,$Cmd(cw)) [list $slow $fast GOBOWHEEL_CONTINUE $wheel_id 0 360]
                        unset fast;   unset slow
                    }
                    continue
                } elseif { [regexp -nocase {(slow)([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 slow] } {
                    if { [info exists fast] } {
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(cw)
                        lappend fixture($channel,$Cmd(cw)) [list $slow $fast GOBOWHEEL_CONTINUE $wheel_id 0 360]
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
            set min {};         set max {}
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_line "rotating from num to num" $line "0 1 3"] } {
                    set min [lindex $line 2]
                    set max [lindex $line 4]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*STATIC)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $a5 $a9 GOBOWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
                    set min [lindex $line 2];       set max [lindex $line 4]
                    #                   lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(scroll)\t\t0\t\tGOBOWHEEL"
                    continue
                } elseif { [SptParser::parse_line "indexed from num to num" $line "0 1 3"] } {
                    set min [lindex $line 2];       set max [lindex $line 4]
                    continue
                } elseif { [SptParser::parse_line "static at num" $line "0 1"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_gobo {i data fix name wheelid slotid} {
            upvar $fix fixture
            set times 0
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [regexp -nocase {(^[ \t]*ROTATING)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(scroll)
                    lappend fixture($channel,$Cmd(scroll)) [list $a5 $a9 GOBOWHEEL_TRANSITION $wheelid $slotid [expr $slotid-1]]
                    continue
                } elseif { [SptParser::parse_line "rotating at num" $line "0 1"] } {
                    continue
                } elseif { [regexp -nocase {(^[ \t]*ROTATING)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(rotate_cw)
                    lappend fixture($channel,$Cmd(rotate_cw)) [list $a5 $a9 GOBOWHEEL_CONTINUE $wheelid 0 400];#[expr $slotid-1] $slotid]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*static)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key s1 key1 s2 from s3 key2 s4 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $from $to GOBOWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue 
                } elseif { [regexp -nocase {(^[ \t]*static)([ \t]+)(at)([ \t]+)([0-9]+)} $line p key s1 key1 s2 num] } {
                    if { $times == 0 } {
                        set from $num
                        incr times
                    } else {
                        set to $num
                        set times 0
                        lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(open)
                        lappend fixture($channel,$Cmd(open)) [list $from $to GOBOWHEEL_INDEX_SELECT $wheelid $slotid]
                    }
                    continue
                } elseif { [regexp -nocase {(^[ \t]*INDEXED)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line pattern a1 a2 a3 a4 a5 a6 a7 a8 a9] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $a5 $a9 GOBOWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [regexp -nocase {(shaking)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key s1 key1 s2 from s3 key2 s4 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(shake)
                    lappend fixture($channel,$Cmd(shake)) [list $from $to GOBOWHEEL_CONTINUE $wheelid $slotid]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*shaking)([ \t]+)(and)([ \t]+)(indexed)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 key4 s4 from s5 key5 s6 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $from $to GOBOWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*shaking)([ \t]+)(and)([ \t]+)(rotating)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 key4 s4 from s5 key5 s6 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(scroll)
                    lappend fixture($channel,$Cmd(scroll)) [list $from $to GOBOWHEEL_TRANSITION $wheelid $slotid [expr $slotid-1]]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*rotating)([ \t]+)(and)([ \t]+)(indexed)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 key4 s4 from s5 key5 s6 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(scroll)
                    lappend fixture($channel,$Cmd(scroll)) [list $from $to GOBOWHEEL_TRANSITION $wheelid $slotid [expr $slotid-1]]
                    continue
                } elseif { [SptParser::parse_line "keyword and keyword from num to num" $line "1 3 5"] } {
                    continue
                } elseif { [SptParser::parse_line "keyword and" $line 1] } {
                    incr i
                    set line [SptParser::remove_comments [lindex $data $i]]
                    if { [SptParser::parse_line "keyword from num to num" $line "1 3"] } {
                        continue
                    }
                    break
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_rotation {i data fix wheelid ch} {
            upvar $fix fixture
            lappend fixture(CHANNELS) $ch

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_channeltype $line] } {
                    continue
                } elseif { [regexp {([0-9\.\-]+)([ \t]+)(AT)([ \t]+)([0-9]+)} $line p speed s1 key s2 offset] } {
                    if { [info exists lastspeed] && [info exists lastoffset] } {
                        if { $speed >= 0 } {
                            lappend fixture($ch,COMMAND) $Cmd(rotate_cw)
                            lappend fixture($ch,$Cmd(rotate_cw)) [list $lastoffset $offset GOBOWHEEL_TRANSITION $wheelid $lastspeed $speed]
                        } else {
                            lappend fixture($ch,COMMAND) $Cmd(rotate_ccw)
                            lappend fixture($ch,$Cmd(rotate_ccw)) [list $lastoffset $offset GOBOWHEEL_TRANSITION $wheelid [expr -1 * $lastspeed] [expr -1 * $speed]]
                        }
                    }
                    set lastspeed $speed
                    set lastoffset $offset
                    continue
                } elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_index {i data fix wheelid ch} {
            upvar $fix fixture

            set idx 0
            set fromAngle ""
            set toAngle ""
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

                if { [SptParser::parse_channeltype $line] } {
                    continue
                } elseif { [regexp {([0-9\.\-]+)([ \t]+)(AT)([ \t]+)([0-9]+)} $line p angle s1 key s2 offset] } {
                    if { $fromAngle == "" } {
                        set fromAngle $angle
                        set fromOffset $offset
                    } elseif {$toAngle == ""} {
                        set toAngle $angle
                        set toOffset $offset
                        lappend fixture($ch,COMMAND) $Cmd(rotate)
                        lappend fixture($ch,$Cmd(rotate)) [list $fromOffset $toOffset STEP $fromAngle $toAngle]
                        set fromAngle ""
                        set toAngle ""
                    }
                    continue
                } elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

    }
}

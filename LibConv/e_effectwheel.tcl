package require snit
namespace eval SptParser {

    snit::type EEffect_wheel {

        typevariable KeyWord1 {CHANNELTYPE EFFECT BEAM OPEN }
        typevariable KeyWord2 {EFFECT APERTURE INDE3XED ROTATING}
        typevariable KeyWord3 {EFFECT COLOR GOBO}
        typevariable channel
        typevariable Cmd -array { open "effectwheel_slot"  rotate "rotate_effectslot" animation "animation"}

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture

            set line [SptParser::remove_comments [lindex $data $i]]

            if { [regexp -nocase {(effect_wheel)([ \t]+)(additive)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 channel] } {
            } elseif { [regexp -nocase {(effect_wheel)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
            } elseif { [regexp -nocase {(effect_wheel)([ \t]+)(nooffset)} $line p key1 s1 key2] } {
                return $i
            } else {
                set $line
                SptParser::PutsVars i line
            }

	    set animation_wheelid 0
            set channeltype($channel) EFFECTWHEEL
            set wheel_id 0
            if { [info exists fixture(EFFECTWHEELS)] } {
                set wheel_id [llength $fixture(EFFECTWHEELS)]
            }
            lappend fixture(EFFECTWHEELS) $wheel_id
	    
            set slotid 1
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [SptParser::parse_channeltype $line] } {
                    continue
                } elseif { [SptParser::parse_line "effect modifier name path" $line "0 1"] } {
                    continue
                } elseif { [regexp -nocase {(effect)([ \t]+)(animation)([ \t]*)"(.*)"([ \t]*)"(.*)"} $line p key1 s1 key2 s2 name s3 path] } {
                    set name [SptParser::replace_string $name " " ""]
                    lappend fixture(EFFECTS) $name
                    set i [$type parse_animation $i $data]
                    lappend fixture(EFFECTWHEEL,$wheel_id) [list $slotid $name $path]
                    incr slotid
                    continue
                } elseif { [SptParser::parse_line "beam" $line 0] } {
                    continue
                } elseif { [regexp -nocase {^[ \t]*open} $line p] } {
                    set i [$type parse_open $i $data fixture $wheel_id 0]
                    continue
                } elseif { [regexp -nocase {"(.*)"[ \t]*effect[ \t]*"(.*)"} $line p name path] } {
                    set name [SptParser::replace_string $name " " ""]
                    lappend fixture(EFFECTS) $name
                    set i [$type parse_effect $i $data fixture $wheel_id $slotid]
                    lappend fixture(EFFECTWHEEL,$wheel_id) [list $slotid $name $path]
                    incr slotid
                    continue
                } elseif { [regexp -nocase {"(.*)"[ \t]*color[ \t]*"(.*)"} $line p name path] } {
                    set name [SptParser::replace_string $name " " ""]
                    lappend fixture(EFFECTS) $name
                    set i [$type parse_color $i $data fixture $wheel_id $slotid]
                    incr slotid
                    continue
                } elseif { [regexp -nocase {"(.*)"[ \t]*gobo[ \t]*"(.*)"} $line p name path] } {
		    lappend fixture(ANIMATIONWHEELS) $animation_wheelid
                    set fixture(ANIMATIONWHEEL,$animation_wheelid) [list $animation_wheelid $name $path]
                    set i [$type parse_gobo $i $data fixture $animation_wheelid]
		    incr animation_wheelid
                    continue
                } elseif { [regexp -nocase {^[ \t]*effect_index[ \t]+offset[ \t]+([0-9]+)} $line p ch] } {
                    set channeltype($ch) EFFECTWHEEL
                    set i [$type parse_rotation $i $data fixture]
#                    set i [$type parse_index $i $data fixture $wheel_id $ch]
                    continue
                } elseif { [regexp -nocase {^[ \t]*effect_rotation[ \t]+offset[ \t]+([0-9]+)} $line p off] } {
                    set channeltype($off) EFFECTWHEEL
                    set i [$type parse_rotation $i $data fixture]
                    continue
                } else {
                    regexp -nocase {[ \t]*([^ \t]*)[ \t]*} $line p key
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
#                       puts "out [lindex [info level 0] 0]"
                        return [expr $i - 1 ]
                    }
                    SptParser::PutsVars i line
                }
            }
#                   puts "out [lindex [info level 0] 0]"
            return [expr $i+1]
        }

        typemethod parse_animation {i data} {
#           puts "in [lindex [info level 0] 0]"
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [SptParser::parse_line "effect diameter num unit" $line "0 1"] } {
                    continue
                } elseif { [SptParser::parse_line "aperture diameter num unit" $line "0 1"] } {
                    continue
                } elseif { [SptParser::parse_line "indexed" $line 0] } {
                    set i [$type parse_effect_index $i $data]
                    continue
                } elseif { [SptParser::parse_line "rotating" $line 0] } {
                    set i [$type parse_effect_rotating $i $data]
                    continue
                } else {
                    break
                }
            }
#           puts "out [lindex [info level 0] 0]"
            return [expr $i - 1 ]
        }

        typemethod parse_effect_index {i data} {
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [SptParser::parse_line "num unit, num unit at num" $line 4] } {
                    continue
                } elseif { [SptParser::parse_line "num unit, num unit from num to num" $line "4 6"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1]
        }

        typemethod parse_effect_rotating {i data} {
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [SptParser::parse_line "unm unit, num unit at num" $line 4] } {
                    continue
                } elseif { [SptParser::parse_line "num unit, num unit from num to num" $line "4 6"] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1]
        }

        typemethod parse_open {i data fix wheelid slotid} {
            upvar $fix fixture
            #                   upvar $lns lines
            #                   set min {};                     set max {}
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [regexp -nocase {(^[ \t]*STATIC)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 from s3 key3 s4 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $from $to EFFECTWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [SptParser::parse_line "static at num" $line "0 1"] } {
                    continue
                } elseif { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
                    #                                   set min [lindex $line 2];               set max [lindex $line 4]
                    #                                   lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(scroll)\t\t0\t\tEFFECTWHEEL"
                    continue
                } elseif { [SptParser::parse_line "rotating from num to num" $line "0 1 3"] } {
                    #                                   set min [lindex $line 2];               set max [lindex $line 4]
                    #                                   lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(rotate)\t\t0\t\tEFFECTWHEEL"
                    continue
                } elseif { [SptParser::parse_line "indexed from num to num" $line "0 1 3"] } {
                    continue
                } else {
                    break
                }
            }
            #                   puts "lines are : $lines"
            #            puts "out [lindex [info level 0] 0]"
            return [expr $i - 1 ]
        }

        typemethod parse_effect {i data fix wheelid slotid} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [regexp -nocase {(indexed|rotating)[ \t]*and[ \t]+(rotating|indexed)[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p k1 k2 from to] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(rotate)
		    lappend fixture(EFFECT_ROTATING) [list $channel $wheelid $slotid $from $to]
                    continue 
		} elseif {  [regexp -nocase {rotating[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to]  } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(rotate)
		    lappend fixture(EFFECT_ROTATING) [list $channel $wheelid $slotid $from $to]
                    continue
                } elseif { [regexp -nocase {static[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(open)
                    lappend fixture($channel,$Cmd(open)) [list $from $to EFFECTWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [regexp -nocase {indexed[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(rotate)
		    lappend fixture(EFFECT_ROTATING) [list $channel $wheelid $slotid $from $to]
                    continue
		} elseif { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
                    #                                   set min [lindex $line 2];               set max [lindex $line 4]
                    #                                   lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(scroll)\t\t$name\t\tEFFECTWHEEL"
                    continue
                } elseif { [SptParser::parse_line "keyword and keyword from num to num" $line "1 3 5"] } {
                    continue
                } else {
                    break
                }
            }
            #            puts "out [lindex [info level 0] 0]"
            return [expr $i - 1 ]
        }

        typemethod parse_color {i data fix wheelid slotid} {
            upvar $fix fixture
            #                   upvar $lns lines
            #                   set min {};                     set max {}
            #            puts "in [lindex [info level 0] 0]"
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [SptParser::parse_line "rotating from num to num" $line "0 1 3"] } {
                    #                                   set min [lindex $line 2];               set max [lindex $line 4]
                    #                                   lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(rotate)\t\t$name\t\tCOLOREFFECT"
                    continue
                } elseif { [SptParser::parse_line "static from num to num" $line "0 1 3"] } {
                    continue
                } elseif { [SptParser::parse_line "indexed from num to num" $line "0 1 3"] } {
                    continue
                } else {
                    break
                }
            }
            #            puts "out [lindex [info level 0] 0]"
            return [expr $i - 1 ]
        }

        typemethod parse_gobo   {i data fix wheelid } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue       }

                if { [regexp -nocase {(indexed|rotating)[ \t]*and[ \t]+(rotating|indexed)[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p k1 k2 from to] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(animation)
		    lappend fixture(ANIMATION_ROTATING) [list $channel $wheelid $from $to]
                    continue 
		} elseif {  [regexp -nocase {rotating[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to]  } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(animation)
		    lappend fixture(ANIMATION_ROTATING) [list $channel $wheelid $from $to]
                    continue
                } elseif { [regexp -nocase {static[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to] } {
#                     lappend fixture(CHANNELS) $channel
#                     lappend fixture($channel,COMMAND) $Cmd(open)
#                     lappend fixture($channel,$Cmd(open)) [list $from $to EFFECTWHEEL_INDEX_SELECT $wheelid $slotid]
                    continue
                } elseif { [regexp -nocase {indexed[ \t]*from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to] } {
#                     lappend fixture(CHANNELS) $channel
#                     lappend fixture($channel,COMMAND) $Cmd(rotate)
#                     lappend fixture($channel,$Cmd(rotate)) [list $from $to GOBOWHEEL_TRANSITION $wheelid $slotid [expr $slotid-1]]
                    continue
		} elseif { [SptParser::parse_line "scrolling from num to num" $line "0 1 3"] } {
#                     set min [lindex $line 2];               set max [lindex $line 4]
#                     lappend lines "$channel\t\t$min\t\t$max\t\tfalse\t\t$Cmd(scroll)\t\t$name\t\tEFFECTWHEEL"
                    continue
                } elseif { [SptParser::parse_line "keyword and keyword from num to num" $line "1 3 5"] } {
                    continue
                } else {
                    break
                }
            }
            #            puts "out [lindex [info level 0] 0]"
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
		} elseif { [regexp {([0-9\.\-]+)[ \t]+AT[ \t]+([0-9]+)} $line p angle offset] } {
		    if { $fromAngle == "" } {
			set fromAngle $angle
			set fromOffset $offset
		    } elseif {$toAngle == ""} {
			set toAngle $angle
			set toOffset $offset
			lappend fixture($ch,COMMAND) $Cmd(rotate)
			lappend fixture($ch,$Cmd(rotate)) [list $fromOffset $toOffset STEP $wheelid $fromAngle $toAngle]
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

        typemethod parse_rotation {i data fix} {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue }

                if { [SptParser::parse_channeltype $line] } {
                    continue
                } elseif { [regexp -nocase {([0-9\-\.]+)[ \t]+at[ \t]+([0-9]+)} $line p speed dmxVal] } {
		    lappend temp [list $speed $dmxVal]
                    continue
                } elseif { [regexp -nocase {([0-9\.\-]+)[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p speed dmxValF dmxValT] } {
		    lappend temp [list $speed $dmxValF]
		    lappend temp [list $speed $dmxValT]
                    continue
                } else {
		    if { [info exists fixture(EFFECT_ROTATING)] || [info exists fixture(ANIMATION_ROTATING)] } {
			foreach item $temp {
			    if { ![info exists lastItem] } { 
				set lastItem $item
				continue
			    }
			    lassign $lastItem speedF dmxValF
			    lassign $item     speedT dmxValT
			    if { [info exists fixture(EFFECT_ROTATING)] } {
				foreach cmditem $fixture(EFFECT_ROTATING) {
				    lassign $cmditem ch wheelid slotid dmxFinalF dmxFinalT
				    if { $dmxValF >= $dmxFinalF && $dmxValF <= $dmxFinalT && $dmxValT >= $dmxFinalT } {
					lappend fixture($ch,$Cmd(rotate)) [list $dmxValF $dmxFinalT GOBOWHEEL_TRANSITION $wheelid $slotid $speedF $speedT ]
				    } elseif { $dmxValF <= $dmxFinalF && $dmxValT >= $dmxFinalF && $dmxValT <= $dmxFinalT } {
					lappend fixture($ch,$Cmd(rotate)) [list $dmxFinalF $dmxValT GOBOWHEEL_TRANSITION $wheelid $slotid $speedF $speedT ]
				    } elseif { $dmxValF >= $dmxFinalF && $dmxValT <= $dmxFinalT } {
					lappend fixture($ch,$Cmd(rotate)) [list $dmxValF $dmxValT GOBOWHEEL_TRANSITION $wheelid $slotid $speedF $speedT ]
				    } elseif { $dmxValF <= $dmxFinalF && $dmxValT >= $dmxFinalT } {
					lappend fixture($ch,$Cmd(rotate)) [list $dmxFinalF $dmxFinalT GOBOWHEEL_TRANSITION $wheelid $slotid $speedF $speedT ]
				    }
				}			    
			    }

			    if { [info exists fixture(ANIMATION_ROTATING)] } {
				foreach cmditem $fixture(ANIMATION_ROTATING) {
				    lassign $cmditem ch wheelid dmxFinalF dmxFinalT
#				    puts "lassign $cmditem ch wheelid dmxFinalF dmxFinalT"
				    if { $dmxValF >= $dmxFinalF && $dmxValF <= $dmxFinalT && $dmxValT >= $dmxFinalT } {
					lappend fixture($ch,$Cmd(animation)) [list $dmxValF $dmxFinalT GOBOWHEEL_TRANSITION $wheelid $speedF $speedT ]
				    } elseif { $dmxValF <= $dmxFinalF && $dmxValT >= $dmxFinalF && $dmxValT <= $dmxFinalT } {
					lappend fixture($ch,$Cmd(animation)) [list $dmxFinalF $dmxValT GOBOWHEEL_TRANSITION $wheelid $speedF $speedT ]
				    } elseif { $dmxValF >= $dmxFinalF && $dmxValT <= $dmxFinalT } {
					lappend fixture($ch,$Cmd(animation)) [list $dmxValF $dmxValT GOBOWHEEL_TRANSITION $wheelid $speedF $speedT ]
				    } elseif { $dmxValF <= $dmxFinalF && $dmxValT >= $dmxFinalT } {
					lappend fixture($ch,$Cmd(animation)) [list $dmxFinalF $dmxFinalT GOBOWHEEL_TRANSITION $wheelid $speedF $speedT ]
				    }
				}	
				puts "-"

			    }
			    set lastItem $item
			    
			}
			break
		    }
		}
	    }
	    return [expr $i - 1 ]
	}
    }
}
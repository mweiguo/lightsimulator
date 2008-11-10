package require snit
#package require dom
package require tdom

# private data structure
# fixture(MOVESPEED)
# fixture(CHANNELS)
# fixture(channel,COMMAND) cmdName1 cmdName2 ...
# fixture(channel,commandName) {from to type para1 para2 para3} {from to type parar1 para2 para3} ...
# special use: fixture(channel,value) para

# fixture(COLORWHEELS)                  wheel_id1, wheel_id2 ...
# fixture(COLORWHEEL,wheel_id)          {slot_id name r g b} {slot_id name r g b} ...
# fixture(GOBOWHEELS)                   wheel_id1, wheel_id2 ...
# fixture(GOBOWHEEL,wheel_id)           {slot_id name r g b} {slot_id name r g b} ...

# fixture(channel,offset) value
# this variable is used in other section
# channeltype(channel) channelType; (EFFECTWHEEL | GOBOWHEEL | COLORWHEEL | COLOR | CONTROL | MOVESPEED | MOVE | INTENSITY | IRIS | FRAMING_ROTATE | FRAMING_INOUT)
# fixture(EFFECTS) effect_name .....

namespace eval SptParser {
    snit::type Parser {
	option -path
	option -keywords

	typevariable MapTable -array {}
	typemethod build_map { mapFile } {
	    if { ![file exists $mapFile] } {
		return false
	    }
	    set f [open $mapFile]
	    set data [read $f]
	    close $f

	    set doc      [dom parse $data]
	    set root     [$doc documentElement]
	    foreach fix [$root childNodes] {
		set sptFile [$fix getAttribute SptFile ""]
		set channum [$fix getAttribute ChannelNumber ""]
		if { $channum == "" } continue
		set MapTable($sptFile) $channum
		foreach ch [$fix childNodes] {
		    set id [$ch getAttribute ID ""]
		    set name [$ch getAttribute Name ""]
		    set MapTable($sptFile,CHANNELNAME,$id) $name
		}
	    }
	    $doc delete
	}

	method update_keyword {} {
	    variable mElements
	    foreach keyword $options(-keywords) {
		set mElements($keyword) "SptParser::E[string totitle $keyword]"
	    }
        }

	method parse {} {
            variable mElements
	    set f [open $options(-path)]
	    set data [read $f]
	    close $f

	    # get fixture name here
	    if { [regexp -nocase {.+/([^/]+)/([^/]+).spt} $options(-path) p manufactor fixturename] } {
#		puts $options(-path)
	    } elseif { [regexp -nocase {.+\([^\]+)\([^\]+).spt} $options(-path) p manufactor fixturename] } {
#		puts $options(-path)
	    } else {
#		puts $options(-path)
		return
	    }

            # reset fixture structure, xmlDocument & xmlRoot
	    set doc [dom createDocument doc]
	    set root [$doc createElement ROOT]

            array set fixture {}
	    array set channeltype {}

	    if { [info exists MapTable($fixturename.spt)] } {
		set fixture(CHANNELNUM) $MapTable($fixturename.spt)
		set channelnum $MapTable($fixturename.spt)
		for { set i 0} { $i < $channelnum } {incr i} {
		    set fixture(CHANNELNAME,$i) $MapTable($fixturename.spt,CHANNELNAME,$i)
		}
	    }

	    # add model link file
	    set fixture(MODELFILE)  mod$fixturename.xml

	    # add channel number
	    set fixture(SEMIMINOPENING) 0
	    set fixture(MINOPENING) 0
	    set lines [split $data \n]

            # iterate each line and add information to xml node
	    for { set i 0 } { $i < [llength $lines] } { incr i } {
                set line [SptParser::remove_comments [lindex $lines $i]]
		if { [string trim $line ]== "" } continue                              ; # skip space line
		if { [SptParser::parse_comment $line] } continue                       ; # skip comment
		set rtn [SptParser::parse_define $i $lines]                            ; # choose define block
		if { $rtn > 0 } { set i $rtn } elseif { $rtn != -1 } { continue	}

		set found 0
                # iterate each keyword
		foreach keyword [array name mElements] {
		    if { [regexp -nocase "(^\[ \t\]*)(${keyword})" $line] } {
			set i [eval [list $mElements($keyword) parse channeltype fixture $i $lines]]
			set found 1
			break
		    }
		}
		if { $found == 0 } {
#                    puts "rtn is $rtn line $i :\t\t$line"
		}
	    }

	    if { [regexp {(.*)\.spt} $options(-path) pattern fixturename] } {
		SptParser::genxml doc root fixture
		set f [open $fixturename.xml w+]
		puts $f [$root asXML]
		close $f
	    }
	    $doc delete
	}
    }
    

    set keywords { CURVE OTHER EFFECT_WHEEL LENS COLOR_WHEEL SPOT PROPERTY VERSION TUBE SOURCE WATTAGE WEIGHT LENGTH HEIGHT WIDTH ROTATION YOKE SHAPE MIRROR RGB FADER STROBE EFFECT_INDEX EFFECT_ROTATION GOBO_WHEEL FRAMING NAT ZOOM IRIS}
    variable KeyWords $keywords
}

if { ![info exist main_running] } {
    source other_symbol.tcl
    source e_lens.tcl
    source e_colorwheel.tcl
    source e_spot.tcl
    source e_property.tcl
    source e_version.tcl
    source e_tube.tcl
    source e_source.tcl
    source e_wattage.tcl
    source e_weight.tcl
    source e_length.tcl
    source e_height.tcl
    source e_width.tcl
    source e_rotation.tcl
    source e_yoke.tcl
    source e_shape.tcl
    source e_mirror.tcl
    source e_rgb.tcl
    source e_zoom.tcl
    source e_fader.tcl
    source e_strobe.tcl
    source e_effectwheel.tcl
    source e_effectindex.tcl
    source e_effectrotation.tcl
    source e_gobowheel.tcl
    source e_other.tcl
    source e_iris.tcl
    source e_framing.tcl
    source e_nat.tcl
    source e_curve.tcl

    set mapPath {./ttt.xml}
    SptParser::Parser build_map $mapPath
    SptParser::Parser p

    set dirs [glob -nocomplain -type d {W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots/SGM.v1*} ]
    set dirs [glob -nocomplain -type d {W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots/ClayPaky.v1*} ]
    set dirs [glob -nocomplain -type d {W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots/*} ]

    foreach dir $dirs {
        set files [glob -nocomplain "$dir/ETC S4 Revolution (31 chan. Rotating).spt"]
        set files [glob -nocomplain "$dir/SGM Galileo IV.spt"]
        set files [glob -nocomplain "$dir/*.spt"]
        foreach filename $files {
            puts $filename-----------------------------------------------------------------------------------------------------------
            p configure -path $filename -keywords $SptParser::KeyWords
            p update_keyword
            p parse
        }
    }
    puts "ok"
}


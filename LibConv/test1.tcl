proc fun { s } {
#	regexp {(OPEN)([ \t]+)(FROM)([ \t]+)([^ ]+)([ \t]+)(TO)([ \t]+)([^ ]+)} $s pattern a1 a2 a3 a4 a5 a6 a7 a8 a9
	regexp {(".*")([ \t]+)(RGB)([ \t]+)([^ ]+)([ \t]+)([^ ]+)([ \t]+)([^ ]+)} $s pattern name a2 a3 a4 a5 a6 a7 a8 a9
	puts $name
	puts $a3
	puts $a5
	puts $a7
	puts $a9
}

set s {"light blue"   RGB   1  20   49}
fun $s


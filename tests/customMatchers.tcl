package require tcltest

tcltest::customMatch array arrayMatcher
proc arrayMatcher {expected actual} {
	array set e $expected
	array set a $actual

	set ekeys [lsort [array names e]]
	set akeys [lsort [array names a]]

	if { $ekeys != $akeys } {
		puts stderr "Keys don't match."
		return 0
	}

	foreach key $ekeys {
		if { $e($key) != $a($key) } {
			puts stderr "Value for $key doesn't match: $e($key) vs. $a($key)"
			return 0
		}
	}

	return 1
}

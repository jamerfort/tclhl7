namespace eval HL7 {
	# This file contains code for spliting a message into a list-of-lists-of-lists.
	namespace eval Message {
		################################################################################
		# Public methods
		################################################################################
			proc parse {msgdata {segment_separator \r}} {
				# This proc splits a message into a list-of-lists-of-lists...
				# and returns the resulting message data structure.
				
				# get the separators
				set separators [get_separators $msgdata $segment_separator]
	
				# split the message into segments
				set segments [split_segments $msgdata $separators]
	
				return [list $segments $separators]
			}
	
		################################################################################
		# Private methods (not meant to be used externally)
		################################################################################
			proc get_separators {msgdata {segment_separator \r}} {
				# This proc returns an array with all of the separators of
				# an HL7 message.
				#
				# The following keys to the array are returned:
				# 	SEGMENT: segment separator
				# 	FIELD: field separator
				# 	REPETITION: repetition separator
				# 	COMPONENT: component separator
				# 	SUBCOMPONENT: subcomponent separator
				# 	ESCAPE: escape character
	
				array set separators {}
	
				set separators(SEGMENT) $segment_separator
				set separators(FIELD) [string index $msgdata 3]
				set separators(REPETITION) [string index $msgdata 5]
				set separators(COMPONENT) [string index $msgdata 4]
				set separators(SUBCOMPONENT) [string index $msgdata 7]
				set separators(ESCAPE) [string index $msgdata 6]
	
				return [array get separators]
			}
	
			########################################################################	
			# Split procs
			########################################################################	
				proc split_segments {msgdata separators} {
					# This proc splits a message into a list of parsed segments
	
					array set seps $separators
					set segments {}
	
					foreach segment [split $msgdata $seps(SEGMENT)] {
						lappend segments [split_fields $segment $separators]
					}
	
					return $segments
				}
	
				proc split_fields {segment separators} {
					# This proc splits a segment into a list of parsed fields
	
					array set seps $separators
					set fields {}
	
					foreach field [split $segment $seps(FIELD)] {
						lappend fields [split_repetitions $field $separators]
					}
	
					return $fields
				}
	
				proc split_repetitions {field separators} {
					# This proc splits a field into a list of parsed repetitions
	
					array set seps $separators
					set repetitions {}
	
					foreach repetition [split $field $seps(REPETITION)] {
						lappend repetitions [split_components $repetition $separators]
					}
	
					return $repetitions
				}
	
				proc split_components {repetition separators} {
					# This proc splits a repetition into a list of parsed components
	
					array set seps $separators
					set components {}
	
					foreach component [split $repetition $seps(COMPONENT)] {
						lappend components [split_subcomponents $component $separators]
					}
	
					return $components
				}
	
				proc split_subcomponents {component separators} {
					# This proc splits a component into a list of parsed subcomponents
	
					array set seps $separators
	
					return [split $component $seps(COMPONENT)]
				}
	}
	
}


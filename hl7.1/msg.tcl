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

			return [list $segments $separators "PARSED_MESSAGE"]
		}

		proc has_been_parsed {msg} {
			set parsed_message [lindex $msg 2]

			return [expr {$parsed_message == "PARSED_MESSAGE"}]
		}

		proc data {msg} {
			# This proc builds the HL7 message from a parsed message.
			
			# verify that this is really a parsed message
			if { ![has_been_parsed $msg] } {
				error "This is not a parsed message."
			}

			set segments [lindex $msg 0]
			set separators [lindex $msg 1]

			return [build_message $segments $separators]
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
					# should we handle the MSH segment separately?
					if { [regexp {^MSH} $segment] } {
						lappend segments [split_msh_fields $segment $separators]
					} else {
						lappend segments [split_fields $segment $separators]
					}
				}

				return $segments
			}

			proc split_msh_fields {segment separators} {
				# This proc splits an MSH segment into a list of parsed fields

				array set seps $separators

				# initialize the resulting list of fields
				set final_fields [list "MSH" $seps(FIELD)]

				# split the fields
				set fields [split $segment $seps(FIELD)]
			
				# add the separator characters as the next field
				lappend final_fields [lindex $fields 1]

				# process the other fields
				foreach field [lrange $fields 2 end] {
					lappend final_fields [split_repetitions $field $separators]
				}

				return $final_fields
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

				return [split $component $seps(SUBCOMPONENT)]
			}
		########################################################################	
		# Rebuild procs
		########################################################################	
			proc build_message {segments separators} {
				array set seps $separators

				set rslts {}

				foreach segment $segments {
					if { [lindex $segment 0 0 0 0] == "MSH" } {
						lappend rslts [build_msh_segment $segment $separators]
					} else {
						lappend rslts [build_segment $segment $separators]
					}
				}

				return [join $rslts $seps(SEGMENT)]
			}

			proc build_msh_segment {fields separators} {
				array set seps $separators


				# build the separator string that will go in the message
				set sep_string [join [list $seps(COMPONENT) $seps(REPETITION) $seps(ESCAPE) $seps(SUBCOMPONENT) ] ""]

				# take the "sep_string" from a subcomponent to a field
				set msh_2 [list [list [list $sep_string]]]

				# Replace MSH.1 and the current value of MSH.2 with this
				# new value calculated off of the separators in the parsed
				# message.  We replace both MSH.1 and MSH.2 so that buid_segment
				# can correctly rebuild the MSH segment, since the HL7 standard
				# numbers the MSH segment differently from every other segment.
				set fields [lreplace $fields 1 2 $msh_2]

				return [build_segment $fields $separators]
			}

			proc build_segment {fields separators} {
				array set seps $separators

				set rslts {}

				foreach field $fields {
					lappend rslts [build_field $field $separators]
				}

				return [join $rslts $seps(FIELD)]
			}

			proc build_field {repetitions separators} {
				array set seps $separators

				set rslts {}

				foreach repetition $repetitions {
					lappend rslts [build_repetition $repetition $separators]
				}

				return [join $rslts $seps(REPETITION)]
			}

			proc build_repetition {components separators} {
				array set seps $separators

				set rslts {}

				foreach component $components {
					lappend rslts [build_component $component $separators]
				}

				return [join $rslts $seps(COMPONENT)]
			}

			proc build_component {subcomponents separators} {
				array set seps $separators
				return [join $subcomponents $seps(SUBCOMPONENT)]
			}
}

# This file contains procs for getting data from and modifying HL7 messages.
namespace eval GetSet {
	################################################################################
	# Public Methods
	################################################################################
		proc get {msg query {reverse 0} {expand 0}} {
			# This proc pulls the values from the parsed message that match
			# the given query.
			#
			# The results are a list of "value-address" pairs.  Thus, for
			# the following message:
			# 	MSH|....|
			# 	PID|||123456~abcdef
			# and the query "PID.3.*", you get the following results:
			# 	{ {123456 1.3.0} {abcdef 1.3.1} }
			#
			# The address returned is a "static address" that can be
			# used to address a given field, repetition, component, etc.
			# specifically.
			# 
			# You would usually use this proc in the following manner:
			# 	set msg [hl7 parse $msgdata \r]
			# 	
			# 	foreach rslt [hl7 get $msg PID.3.*.0.0] {
			#		set value [lindex $rslt 0]
			#		set address [lindex $rslt 1]
			#
			#		# do something
			#		puts "$address ==> $value"
			# 	}


			# is this a blank query, which means get the list of segments
			if { $query == "" } {
				set value [lindex $msg 0]
				set address ""
				set value_address_pair [list $value $address]
				return [list $value_address_pair]
			}

			set results {}

			foreach address [HL7::Query::query $msg $query $expand $reverse] {
				set value [eval {lindex $msg 0} [split $address "."]]
				lappend results [list $value $address]
			}

			return $results
		}

		proc get_reverse {msg query {expand 0}} {
			# get the reversed list of the results returned by "get"
			return [get $msg $query 1 $expand]
		}

		proc get_values {msg query {reverse 0} {expand 0}} {
			# return just the values, not value-address pairs of the
			# results returned by "get"
			set values {}

			foreach rslt [get $msg $query $reverse $expand] {
				lappend values [lindex $rslt 0]
			}

			return $values
		}

		proc _set {msg query value {expand 1}} {
			# This proc sets the value of a segment, field, etc.
			
			# handle the special case of a blank query, thus indicating setting the segments
			if { $query == "" } {
				set msg [lreplace $msg 0 0 $value]
				return $msg
			}

			# get the segments in the message
			set segments [lindex $msg 0]

			foreach address [HL7::Query::query $msg $query $expand] {
				set indexes [split $address "."]
				set segments [lexpand $segments $indexes]
				lset segments $indexes $value
			}

			# add the segments back into the message
			set msg [lreplace $msg 0 0 $segments]

			return $msg
		}

		proc clear {msg query} {
			# Clear out the given query
			return [_set $msg $query ""]
		}

		proc delete {msg query} {
			# delete the addresses matching the given query
			
			# get the segments in the message
			set segments [lindex $msg 0]

			# run a reverse query of the items to be deleted
			foreach address [HL7::Query::query $msg $query 0 1] {
				# split the address
				set indexes [split $address "."]

				# remove the item
				set segments [ldelete $segments $indexes]
			}

			# add the segments back into the message
			set msg [lreplace $msg 0 0 $segments]

			return $msg

		}

		proc add {msg query value {expand 1}} {
			# get the depth of the query
			set query_depth [llength [split $query "."]]

			# don't allow this to run on segments or subcomponents
			if { $query_depth == 1 || $query_depth == 5 } {
				error "ERROR: hl7 add should not be run on segments or subcomponents."
			}

			foreach rslt [get_reverse $msg $query $expand] {
				set rslt_value [lindex $rslt 0]
				set address [lindex $rslt 1]

				# add to the rslt_value
				lappend rslt_value $value

				# set the new value
				set msg [_set $msg $address $rslt_value]
			}

			return $msg
		}

		proc insert_with_offset {msg query value {offset 0}} {
			# get the depth of the query
			set query_depth [llength [split $query "."]]

			# don't allow this to run on fields
			if { $query_depth == 2 } {
				error "ERROR: hl7 insert should not be run on fields."
			}

			foreach address [HL7::Query::query $msg $query 1 1] {
				set address_parts [split $address "."]
				set parent_address [join [lrange $address_parts 0 end-1] "."]
				set index [expr {[lindex $address_parts end] + $offset}]

				# get the parent part of the message
				set parent [lindex [get_values $msg $parent_address 0 1] 0]

				# insert the value at the specified index in the parent
				if { [llength $parent] < $index } {
					set parent [lexpand $parent [expr {$index - 1}]]
				}

				set parent [linsert $parent $index $value]
				set msg [_set $msg $parent_address $parent]
			}

			return $msg
		}

		proc insert {msg query value} {
			return [insert_with_offset $msg $query $value 0]
		}

		proc insert_before {msg query value} {
			return [insert_with_offset $msg $query $value 0]
		}

		proc insert_after {msg query value} {
			return [insert_with_offset $msg $query $value 1]
		}

		proc each {vars msg query args} {
			if { [llength $args] == 0 } {
				error "ERROR: A body must be provided to 'each'"
			}

			# pull the body out of the args
			set body [lindex $args end]
			set args [lrange $args 0 end-1]
	
			set value_var [lindex $vars 0]
			set address_var [lindex $vars 1]

			upvar 1 $value_var value
			upvar 1 $address_var address

			foreach rslt [eval {get $msg $query} $args] {
				set value [lindex $rslt 0]
				set address [lindex $rslt 1]
				uplevel 1 $body		
			}
		}

	################################################################################
	# Private Methods (not meant to be used externally)
	################################################################################
		proc lexpand {l indexes} {
			# short-circuit if we don't have any indexes to expand to.
			if { [llength $indexes] <= 0} {
				return $l
			}

			# pop off the next index
			set i [lindex $indexes 0]
			set indexes [lrange $indexes 1 end]

			# get the length of the current list
			set len [llength $l]

			# do we need to add more at this level?
			if { $i >= $len } {
				# yes...add more
				
				set count [expr {$i + 1 - $len}]
				while { $count > 0 } {
					lappend l {}
					incr count -1
				}
			}

			# do we need to process deeper?
			if { [llength $indexes] > 0 } {
				# yes
				set l [lreplace $l $i $i [lexpand [lindex $l $i] $indexes]]
			}

			return $l
		}

		proc ldelete {l indexes} {
			# nested delete

			set parent_indexes [lrange $indexes 0 end-1]
			set i [lindex $indexes end]

			# get the parent list
			set parent [lindex $l $parent_indexes]

			# remove the desired item
			set parent [lreplace $parent $i $i]

			# replace the parent in the original list with the new value
			lset l $parent_indexes $parent

			return $l
		}
}

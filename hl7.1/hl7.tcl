#!/usr/bin/env tclsh

################################################################################
# README contents
################################################################################
#
# <!-- <style>
# 	pre {
# 		overflow: auto;
# 		border: 1px solid #888;
# 		padding: 20px;
# 		margin: 0 20px;
# 	}
# </style> -->
# 
# TclHL7 - HL7 Addressing Library for TCL
# =======================================
# TCL is a great language for processing [HL7 messages](http://en.wikipedia.org/wiki/Health_Level_7).
# Unfortunately, you usually have to manually parse the message and rebuild it if you made modifications.
# The intentions of this library is to provide an addressing scheme for HL7 messages that will allow data
# to be pulled from an HL7 message and allow a message to be manipulated in a concise manner.
# 
# HL7 Message Structure
# ---------------------
# An HL7 message has the following structure:
# 
# - A message contains a list of segments.
# 	- Typically separated by `\r`
# - A segment is made up of a list of fields.
# 	- Typically separated by `|`
# - A field is made up of a list of field repetitions.
# 	- Typically separated by `~`
# - A field repetition is made up of a list of components.
# 	- Typically separated by `^`
# - A component is made up of a list of subcomponents.
# 	- Typically separated by `&`
# 
# Example HL7 Message
# -------------------
# Below is an example HL7 message.  Note that each segment has been placed on it's own line, thus newlines (`\n`) can be considered the segment separator in this example.  Typically, a carriage return (`\r`) is used as the segment separator.
# 
# 	MSH|^~\&|GHH LAB|ELAB-3|GHH OE|BLDG4|200202150930||ORU^R01|CNTRL-3456|P|2.4
# 	PID|||555-44-4444~1234567||EVERYWOMAN^EVE^E^^^^L|JONES|19620320|F|||153 FERNWOOD DR.^^STATESVILLE^OH^35292||(206)3345232|(206)752-121||||AC555444444||67-A4335^OH^20030520
# 	OBR|1|845439^GHH OE|1045813^GHH LAB|15545^GLUCOSE|||200202150730|||||||||555-55-5555^PRIMARY^PATRICIA P^^^^MD^^|||||||||F||||||444-44-4444^HIPPOCRATES^HOWARD H^^^^MD
# 	OBX|1|SN|1554-5^GLUCOSE^POST 12H CFST:MCNC:PT:SER/PLAS:QN||^182|mg/dl|70_105|H|||F
# 
# Typical Parsing in TCL
# ----------------------
# Typically, when parsing an HL7 message in TCL, you have to break the message apart based on the given separators.  When modifying the message, you not only have to split the message to pull data out, but you also have to rebuild the message afterwards.
# 
# This parsing and rebuilding is well suited for TCL, but unfortunately, the parsing/rebuilding logic takes away from the actual problem that you are actually trying to solve.  That's where this library can help.
# 
# HL7 Addressing Scheme
# ---------------------
# By creating an addressing scheme for HL7 fields, components, etc., we are able to abstract away the parsing and rebuilding logic behind a TCL library.
# 
# The addressing scheme that TclHL7 uses is closely related to the structure of an HL7 message (see above).
# 
# An address is made up of five parts, each separated by a ".":
# 
# 1. segment address part
# 2. field address part
# 3. repetition address part
# 4. component address part
# 5. subcomponent address part
# 
# Thus, an address that addresses the first subcomponent of the second ID in PID.3 of the above example can be addressed as:
# 	
# 	PID.3.1.0.0
# 
# where:
# 
# - `PID` is the segment address part
# - `3` is the field address part
# - `1` is the repetition address part
# - `0` is the component address part
# - `0` is the subcomponent address part
# 
# Wildcards can also be used to address more than one item in a message.  To address the first subcomponent of each ID in PID.3, the following query address can be used:
# 
# 	PID.3.*.0.0
# 
# This is the same as the previous example, except that the `*` now matches **all** repetitions in PID.3.
# 
# The segment address part can match in the following ways:
# 
# 1. segment type: `MSH`, `PID`, etc.
# 2. single index: For example, MSH segments would correspond to index `0`.
# 3. `*`: all segments
# 4. any glob pattern that works with TCL's `string match` command: For example `Z*`.
# 
# The field, repetition, component, and subcomponent address parts match in the following ways:
# 
# 1. single index: `0`, `10`, etc.
# 2. `*`: all present values at the given level
# 3. range: all indexes in the given range (i.e `1-3`)
# 4. index to end: from the given index to the last index at the given level (i.e. `2-end`)
# 
# ### Static Addresses
# 
# The addressing scheme mentioned above describes what I like to call **query addresses**.  They are capable of matching more than one item in an HL7 message.  While this is helpful, you also need a canonical way to address a given item.
# 
# The canonical address of an item in an HL7 message is called a **static address**.  A static address is made up of five parts joined by periods (just like the query addresses).  Where query address parts can contain wildcards, static address parts can only contain a single index.  This being said, a static address can also be used as a query address.
# 
# Using the example HL7 message above, the query address `PID.3.*.0.0` expands to the following static addresses:
# 
# - `1.3.0.0.0`
# - `1.3.1.0.0`
# 
# Installing/Using the Library
# ----------------------
# To use the library, source the `build/hl7.tcl` file into your TCL scripts.  The full library is contained in the `hl7.tcl` file, thus you can source it directly in your code or you can add it to you `auto_path`.
# 
# 	#!/usr/bin/env tclsh
# 
# 	# source the TclHL7 library
# 	source hl7.tcl
# 
# 	# ...
# 
# 	# Use the TclHL7 library!
# 	set msg [hl7 parse $msgdata]
# 
# 
# HL7 Commands
# ------------
# Below are the commands provided by TclHL7.
# 
# ### `parse`
# 
# Before an HL7 message can be manipulated by TclHL7, it must be parsed and split into segments, fields, etc.  The `parse` command is how you take an HL7 message and prepare it for the other commands provided by TclHL7.
# 
# Usage:
# 
# 	hl7 parse <msgdata> [<segment_separator>]
# 
# 	Arguments:
# 		msgdata: The raw HL7 message being parsed.
# 		segment_separator (optional):
# 			- Default: \r
# 			- This argument determines what is used as the separator between the segments.
# 
# Example Usage:
# 
# 	# Assume that the raw HL7 message is in the 'msgdata' variable.
# 	set msg [hl7 parse $msgdata]
# 
# 	# Now use the 'msg' variable with other TclHL7 commands
# 	set values [hl7 get values $msg PID.3.*.0.0]
# 
# ### `data`
# 
# After a message has been parsed with `hl7 parse`, to get it back into its raw-data form, you use the `data` command.
# 
# Usage:
# 
# 	hl7 data <msg>
# 
# 	Arguments:
# 		msg: The parsed HL7 message that is being converted to raw data.
# 
# Example Usage:
# 
# 	# Parse the message
# 	set msg [hl7 parse $msgdata]
# 
# 	# Modify the message
# 	set msg [hl7 set $msg MSH.3.0.0.0 "SENDAPP"]
# 
# 	# Get the data of the message
# 	set msgdata [hl7 data $msg]
# 
# ### `query`
# 
# This proc takes a parsed message and a query address, and it returns a list of all matching static addresses.  See **Static Addresses** above.
# 
# Usage:
# 
# 	hl7 query <msg> <query> [<expand>] [<reverse>]
# 
# 	Arguments:
# 		msg: This is the parsed message being queried against.
# 		query: This is the query being run against the given message.
# 		expand (optional):
# 			- Default: 0
# 			- Set this argument to `1` to return addresses that match repetitions, components, or subcomponents that do not exist.
# 			- For example, if a field only has one repetition, by default, a query addressing the third repetition would not be returned.  By setting `expand` to `1`, the "invisible" repetition's address would be returned.
# 			- This argument does not affect segments or fields.  Segments are never expanded, fields are always expanded.
# 		reverse (optional):
# 			- Default: 0
# 			- By default, the `query` command returns a sorted list of static addresses, with the addresses in the order that you would find them as you move from the start of the message to the end.  By settting this to `1`, you will get a reverse-sorted list of addresses.
# 			- This is useful for when you are performing destructive actions on a message (such as removing segments, repetitions, etc.).  If you perform an action that changes another item's static address/index, then the items need to be processed from the back of the message to the front.  Otherwise, you may invalidate any previously queried addresses.
# 
# Example Usage:
# 	
# 	# Assume that 'msg' contains a parsed HL7 message
# 
# 	set addresses [hl7 query $msg "PID.3.*.0.0"]
# 
# 	# reverse the results
# 	set reversed_addresses [hl7 query $msg "PID.3.*.0.0" 0 1]
# 
# 	# expand to the 3rd repetition, even if it's not present
# 	set expanded_addresses [hl7 query $msg "PID.3.2.0.0" 1]
# 
# 	# both expand and reverse the results
# 	set expanded_reversed_addresses [hl7 query $msg "PID.3.*.4.0" 1 1]
# 
# ### `get`
# 
# This proc is used to actually pull data out of an HL7 message.  It always returns a **list** of matches.
# 
# By default, this proc returns a list of value-address pairs.  The value is the value of the matched item, and the address is the static address of the matched item.  This allows you analyze the value and then issue subsequent modification commands using the item's static address.  There is a form of the `get` command that returns a list of matched values, not a list of matched value-address pairs.  If you need just the matched addresses, you can use the `query` command.
# 
# Usage:
# 
# 	# standard usage
# 	hl7 get <msg> <query> [<reverse>] [<expand>]
# 
# 	Arguments:
# 		msg: The message being queried against.
# 		query: The query indicating the items to be matched.
# 		reverse (optional):
# 			- Default: 0
# 			- If set to `1`, the command reverses the results.
# 			- See the comments on reversing for the `query` command.
# 		expand (optional):
# 			- Default: 0
# 			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
# 			- See the comments on expanding for the `query` command.
# 
# 	# reverse the results
# 	hl7 get reversed <msg> <query> [<expand>]
# 		msg: The message being queried against.
# 		query: The query indicating the items to be matched.
# 		expand (optional):
# 			- Default: 0
# 			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
# 			- See the comments on expanding for the `query` command.
# 
# 	# return only matching values
# 	hl7 get values <msg> <query> [<reverse>] [<expand>]
# 		msg: The message being queried against.
# 		query: The query indicating the items to be matched.
# 		reverse (optional):
# 			- Default: 0
# 			- If set to `1`, the command reverses the results.
# 			- See the comments on reversing for the `query` command.
# 		expand (optional):
# 			- Default: 0
# 			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
# 			- See the comments on expanding for the `query` command.
# 	
# Example Usage:
# 
# 	# Usually, you would loop through the results.
# 	# Most loops can be handled by `hl7 each`.
# 	foreach result [hl7 get $msg PID.3.*.0.0] {
# 		set value [lindex $result 0]
# 		set address [lindex $result 1]
# 
# 		# do something with the value and address
# 		puts "$address) $value"
# 	}
# 
# 	# Occasionally, you'd only want the values
# 	set values [hl7 get values $msg PID.3.*.0.0]
# 
# 	# If you're doing something destructive, reverse the results.
# 	foreach result [hl7 get reversed $msg *.0.0.0.0] {
# 		# remove Z segments
# 		set segment_type [lindex $result 0]
# 
# 		if { [regexp {^Z} $segment_type] } {
# 			# remove the Z segment
# 
# 			# get the address of the result
# 			set address [lindex $result 1]
# 
# 			# get the segment address (the first part)
# 			set segment_address [lindex [split $address "."] 0]
# 
# 			# remove the segment
# 			set msg [hl7 delete $msg $segment_address]
# 		}
# 	}
# 
# ### `set`
# 
# This proc is used to set the value of the items that match the given query address.  It makes the modifications and returns the resulting parsed-message.
# 
# Usage:
# 
# 	hl7 set <msg> <query> <value> [<expand>]
# 	
# 	Arguments:
# 		msg: The message being modified.
# 		query: The query indicating the items to be modified.
# 		value: The new value of the matched items.
# 		expand (optional):
# 			- Default: 0
# 			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the message is expanded to include the indicated item and its value is set to the given value.
# 			- See the comments on expanding for the `query` command.
# 
# Example Usage:
# 
# 	# set the sending and receiving facilities to '01'
# 	set msg [hl7 set $msg MSH.4,6.0.0.0 "01"]
# 
# ### `clear`
# 
# This proc clears out the contents of the items that match the given query.  The modified parsed-message is returned.
# 
# Usage:
# 
# 	hl7 clear <msg> <query>
# 	
# 	Arguments:
# 		msg: The message being modified.
# 		query: The query indicating the items to be cleared.
# 
# Example Usage:
# 
# 	# clear out the identifiers in PID.2
# 	set msg [hl7 clear $msg PID.2]
# 
# ### `delete`
# 
# This proc removes the items that match the given query from the message.  The modified parsed-message is returned.
# 
# Usage:
# 
# 	hl7 delete <msg> <query>
# 
# 	Arguments:
# 		msg: The message being modified.
# 		query: The query indicating the items to be removed.
# 
# Example Usage:
# 
# 	# remove the 2nd identifier in PID.3
# 	set msg [hl7 delete $msg PID.3.1]
# 
# ### `add`
# 
# This proc appends the given value to the end of the items indicated by the query.  The modified parsed-message is returned.
# 
# Note that this can't be run on segments or subcomponents.  You can't run it on segments because appending a field to the end of a segment is usually not needed (usually, the field index has meaning).  You can bypass this by using `set`.  You can't run this on subcomponents because there are not items at a level lower than subcomponents.
# 
# Usage:
# 
# 	hl7 add <msg> <query> <value> [<expand>]
# 
# 	Arguments:
# 		msg: The message being modified.
# 		query: The query indicating the items being appended to.
# 		value: The value being appended.
# 		expand (optional):
# 			- Default: 1
# 			- Typically, you would want the message to expand to include the item that you are appending to.
# 			- See the comments on expanding for the `query` command.
# 
# Example Usage:
# 
# 	# add an identifier repetition to PID.3
# 	set msg [hl7 add $msg PID.3 $id]
# 
# ### `insert`
# 
# This proc inserts the given value(s) either at the address indicated in the query or after the address.  All items at the inserted index (and after) are shifted.
# 
# Usage:
# 
# There are three forms of the `insert` command, two of which perform the same operation:
# 
# 1. `insert <msg> <query> <value1> [<value2> ... <valueN>]`: This form inserts the value(s) at the address indicated by `query`.
# 2. `insert before <msg> <query> <value> [<value2> ... <valueN>]`: This form acts just like the first form.
# 3. `insert after <msg> <query> <value> [<value2> ... <valueN>]`: This form inserts the value(s) after the address indicated by `query`.
# 
# Example Usage:
# 	
# 	# insert the id as the first repetition in PID.3
# 	set msg [hl7 insert $msg PID.3.0 $id]
# 
# 	# do the same thing, using `insert before`
# 	set msg [hl7 insert before $msg PID.3.0 $id]
# 
# 	# insert the id as the second repetition in PID.3
# 	set msg [hl7 insert after $msg PID.3.0 $id]
# 
# 	# insert three ids (each as a separate repetition)
# 	# to the front of PID.3
# 	set msg [hl7 insert $msg PID.3.0 $id1 $id2 $id3]
# 
# ### `each`
# 
# A common idiom that you will see with this library is looping through the results of an `hl7 get` call.  The way to do this with TCL's `foreach` command can be seen below:
# 
# 	# loop through each item
# 	foreach result [hl7 get $msg PID.3.*.0.0] {
# 		set value [lindex $result 0]
# 		set address [lindex $result 1]
# 
# 		# do something with the value and address
# 		puts "$address) $value"
# 	}
# 
# Notice that with this example, you have to manually pull out each result's value and address using `lindex`.  Since this was such a common idiom, `hl7 each` was created to simplify this scenario.
# 
# For example, the above becomes the following when using `hl7 each`:
# 
# 	# loop through each item
# 	hl7 each {value address} $msg PID.3.*.0.0 {
# 		# do something with the value and address
# 		puts "$address) $value"
# 	}
# 
# 	# The variables can be named whatever you like.
# 	# This is the same as the above example.
# 	hl7 each {v a} $msg PID.3.*.0.0 {
# 		# do something with the value and address
# 		puts "$a) $v"
# 	}
# 
# You can also loop over just the values, if you have no need for the addresses:
# 
# 	# loop through each value
# 	hl7 each value $msg PID.3.*.0.0 {
# 		# do something with the value
# 		puts "$value"
# 	}
# 	
# The first argument passed to `hl7 each` determines the names of the variables set in the body.  The body of this `hl7 each` loop is the last argument passed to the command.  The rest of the arguments (between the variable names and the body) get passed to the `get` command, so you can also reverse and expand the query as needed.
# 
# For example:
# 
# 	# loop through each item, in reverse order
# 	hl7 each {v a} $msg PID.3.*.0.0 1 {
# 		# do something with the value
# 		puts "$a) $v"
# 	}
# 
# Usage:
# 
# 	hl7 each <vars> <msg> <query> [<reverse>] [<expand>] <body>
# 
# 	Arguments:
# 		vars: This argument determines the names of the variables that will get set for each iteration of the results.
# 			- If this argument has one item, only the value of each iteration is set.
# 			- If this arguemnt has more than two items, the first name given will get set to the value of the current iteration's result.  The second name given will get set to the address of the current iteration's result.
# 		msg: The message being queried against.
# 		query: The query indicating the items to be matched.
# 		body: This is the body that will be run for each item in the results.
# 		reverse (optional):
# 			- Default: 0
# 			- If set to `1`, the command reverses the results.
# 			- See the comments on reversing for the `query` command.
# 		expand (optional):
# 			- Default: 0
# 			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
# 			- See the comments on expanding for the `query` command.
# 
#
################################################################################
# END README contents
################################################################################

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
	
	
	# This file contains code for turning an HL7 query address into a static address.
	namespace eval Query {
	
		################################################################################
		# Public methods
		################################################################################
			proc query {msg query {expand 0} {reverse 0}} {
				# This proc turns an HL7 query address into a list
				# of all matching static addresses.
				#
				# A query address has the following formats:
				# 	- SEGMENT.FIELD.REPETITION.COMPONENT.SUBCOMPONENT
				# 		- returns subcomponent
				# 	- SEGMENT.FIELD.REPETITION.COMPONENT
				# 		- returns component (list of subcomponents)
				# 	- SEGMENT.FIELD.REPETITION
				# 		- returns repetition (list of components)
				# 	- SEGMENT.FIELD
				# 		- returns field (list of repetitions)
				# 	- SEGMENT
				# 		- returns segment (list of fields)
	
				# verify that the "msg" has been parsed
				if { ![HL7::Message::has_been_parsed $msg] } {
					error "The message must be parsed."
				}
	
				# split the query into each part
				set query_parts [split $query "."]
				set num_parts [llength $query_parts]
	
				# verify that the query parts are of the right length
				if { $num_parts > 5 } {
					error "Too many query parts. Between 1 and 5 parts allowed."
				} elseif { $num_parts < 0 } {
					error "Not enough query parts. Between 1 and 5 parts allowed."
				}
	
	
				set results [query_segments $msg $query_parts $expand]
				
				if { $reverse } {
					return [lsort -command query_sort -decreasing $results]
				} else {
					return [lsort -command query_sort $results]
				}
				
			}
		################################################################################
		# Private methods (not intended for external use)
		################################################################################
		
			proc query_sort {address1 address2} {
				if { $address1 == "" && $address2 != "" } {
					return -1
				} elseif { $address1 != "" && $address2 == "" } {
					return 1
				} elseif { $address1 == "" && $address2 == "" } {
					return 0
				}
	
				set parts1 [split $address1 "."]
				set parts2 [split $address2 "."]
				set i1 [lindex $parts1 0]
				set i2 [lindex $parts2 0]
	
				if { $i1 == $i2 } {
					set rest1 [join [lrange $parts1 1 end] "."]
					set rest2 [join [lrange $parts2 1 end] "."]
	
					return [query_sort $rest1 $rest2]
				} else {
					return [expr $i1 - $i2]
				}
			}
		
			########################################################################
			# Query procs
			########################################################################
				proc query_segments {msg query_parts expand} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the segment and field parts of the query
					set seg_part [lindex $query_parts 0]
					set field_part [lindex $query_parts 1]
	
					# get the list of segments in the message
					set segments [lindex $msg 0]
					set num_segments [llength $segments]
	
					for {set i 0} {$i < $num_segments} {incr i} {
						# does this one match?
						if { [match_segment $segments $i $seg_part] } {
							# yes, it matches, thus we process it
	
							if { $field_part != "" } {
								foreach address [query_fields [lindex $segments $i] $query_parts $expand] {
									lappend addresses "$i.$address"
								}
							} else {
								lappend addresses $i
							}
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
				}
	
				proc query_fields {segment query_parts expand} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the field and repetition parts of the query
					set field_part [lindex $query_parts 1]
					set rep_part [lindex $query_parts 2]
	
					# get the list of fields in the segment
					set num_fields [llength $segment]
	
					foreach i [query_indexes $num_fields $field_part 1] {
						if { $rep_part != "" } {
							set field [lindex $segment $i]
							foreach address [query_repetitions $field $query_parts $expand] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_repetitions {field query_parts expand} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the repetition and component parts of the query
					set rep_part [lindex $query_parts 2]
					set comp_part [lindex $query_parts 3]
	
					# get the list of repetitions in the field
					set num_repetitions [llength $field]
	
					foreach i [query_indexes $num_repetitions $rep_part $expand] {
						if { $comp_part != "" } {
							set repetition [lindex $field $i]
							foreach address [query_components $repetition $query_parts $expand] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_components {repetition query_parts expand} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the component and subcomponent parts of the query
					set comp_part [lindex $query_parts 3]
					set subcomp_part [lindex $query_parts 4]
	
					# get the list of components in the repetition
					set num_components [llength $repetition]
	
					foreach i [query_indexes $num_components $comp_part $expand] {
						if { $subcomp_part != "" } {
							set component [lindex $repetition $i]
							foreach address [query_subcomponents $component $query_parts $expand] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_subcomponents {component query_parts expand} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the subcomponent parts of the query
					set subcomp_part [lindex $query_parts 4]
	
					# get the list of subcomponents in the component
					set num_subcomponents [llength $component]
	
					foreach i [query_indexes $num_subcomponents $subcomp_part $expand] {
						lappend addresses $i
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
	
				proc query_indexes {count query_part expand} {
					array set addresses {}
	
					foreach query [split $query_part ","] {
						switch -regexp -- $query {
							{^[0-9]+$} {
								if { $expand || $query < $count } {
									set addresses($query) 1
								}
							}
				
							{^\*$} {
								foreach address [range 0 $count 0] {
									set addresses($address) 1
								}
							}
	
							{^[0-9]+-[0-9]+$} {
								regexp {^([0-9]+)-([0-9]+)$} $query {} min max
								foreach address [range $min $max] {
									if { $expand || $address < $count } {
										set addresses($address) 1
									}
								}
							}
	
							{^[0-9]+-end$} {
								regexp {^([0-9]+)-end$} $query {} min
								set max [expr {$count - 1}]
	
								puts "END: $min - $max"
	
								foreach address [query_indexes $count "${min}-${max}" $expand] {
									set addresses($address) 1
								}
							}
	
							
						}
					}
	
					return [lsort -integer [array names addresses]]
				}
	
				proc range {start end {inclusive 1}} {
					set rslts {}
	
					if { $inclusive } {
						incr end
					}
	
					for {set i $start} {$i < $end} {incr i} {
						lappend rslts $i
					}
					
					return $rslts
				}
		
			########################################################################
			# Match procs
			########################################################################
				proc match_segment {segments index seg_query} {
					# This proc returns 1 if the segment at the given
					# index matches the given query
	
					# get the segment type
					set seg_type [lindex $segments $index 0 0 0 0]
	
					# split the query
					foreach query [split $seg_query ","] {
						# check on segment type and index
						if { [string match $query $seg_type] || $index == $query } {
							return 1
						}
					}
	
					return 0
				}
	
				proc match_field {fields index field_query} {
					# This proc returns 1 if the field at the given
					# index matches the given query
	
					# split the query
					foreach query [split $field_query ","] {
						# check index
						if { $index == $query } {
							return 1
						}
					}
	
					return 0
	
				}
	
			
	}
	

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
	
			proc insert_with_offset {msg query values {offset 0}} {
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
	
					set parent [eval {linsert $parent $index} $values]
					set msg [_set $msg $parent_address $parent]
				}
	
				return $msg
			}
	
			proc insert {msg query value args} {
				set values [concat [list $value] $args]
				return [insert_with_offset $msg $query $values 0]
			}
	
			proc insert_before {msg query value args} {
				set values [concat [list $value] $args]
				return [insert_with_offset $msg $query $values 0]
			}
	
			proc insert_after {msg query value args} {
				set values [concat [list $value] $args]
				return [insert_with_offset $msg $query $values 1]
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
	
}

proc hl7 {cmd args} {
	switch -exact -- $cmd {
		parse { return [eval {HL7::Message::parse} $args] }
		data { return [eval {HL7::Message::data} $args] }

		query { return [eval {HL7::Query::query} $args] }

		get {
			switch -regexp -- [lindex $args 0] {
				{^reversed?$} {
					# get reverse
					# get reversed
					return [eval {HL7::GetSet::get_reverse} [lrange $args 1 end]]
				}

				{^values?$} {
					# get value
					# get values
					return [eval {HL7::GetSet::get_values} [lrange $args 1 end]]
				}

				default {
					# get
					return [eval {HL7::GetSet::get} $args]
				}
			}
		}
		set { return [eval {HL7::GetSet::_set} $args] }
		clear { return [eval {HL7::GetSet::clear} $args] }
		delete { return [eval {HL7::GetSet::delete} $args] }
		add { return [eval {HL7::GetSet::add} $args] }
		insert {
			switch -exact -- [lindex $args 0] {
				before {
					# insert before
					return [eval {HL7::GetSet::insert_before} [lrange $args 1 end]]
				}

				after {
					# insert after
					return [eval {HL7::GetSet::insert_after} [lrange $args 1 end]]
				}

				default {
					# insert
					return [eval {HL7::GetSet::insert} $args]
				}
			}
		}
		insert_before { return [eval {HL7::GetSet::insert_before} $args] }
		insert_after { return [eval {HL7::GetSet::insert_after} $args] }

		each {
			set body [concat {HL7::GetSet::each} $args]
			uplevel 1 $body
		}

		default {
			error "Unknown command: $cmd"
		}
	}
}


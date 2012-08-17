<!-- <style>
	pre {
		overflow: auto;
		border: 1px solid #888;
		padding: 20px;
		margin: 0 20px;
	}
</style> -->

TclHL7 - HL7 Addressing Library for TCL
=======================================
TCL is a great language for processing [HL7 messages](http://en.wikipedia.org/wiki/Health_Level_7).
Unfortunately, you usually have to manually parse the message and rebuild it if you made modifications.
The intentions of this library is to provide an addressing scheme for HL7 messages that will allow data
to be pulled from an HL7 message and allow a message to be manipulated in a concise manner.

HL7 Message Structure
---------------------
An HL7 message has the following structure:

- A message contains a list of segments.
	- Typically separated by `\r`
- A segment is made up of a list of fields.
	- Typically separated by `|`
- A field is made up of a list of field repetitions.
	- Typically separated by `~`
- A field repetition is made up of a list of components.
	- Typically separated by `^`
- A component is made up of a list of subcomponents.
	- Typically separated by `&`

Example HL7 Message
-------------------
Below is an example HL7 message.  Note that each segment has been placed on it's own line, thus newlines (`\n`) can be considered the segment separator in this example.  Typically, a carriage return (`\r`) is used as the segment separator.

	MSH|^~\&|GHH LAB|ELAB-3|GHH OE|BLDG4|200202150930||ORU^R01|CNTRL-3456|P|2.4
	PID|||555-44-4444~1234567||EVERYWOMAN^EVE^E^^^^L|JONES|19620320|F|||153 FERNWOOD DR.^^STATESVILLE^OH^35292||(206)3345232|(206)752-121||||AC555444444||67-A4335^OH^20030520
	OBR|1|845439^GHH OE|1045813^GHH LAB|15545^GLUCOSE|||200202150730|||||||||555-55-5555^PRIMARY^PATRICIA P^^^^MD^^|||||||||F||||||444-44-4444^HIPPOCRATES^HOWARD H^^^^MD
	OBX|1|SN|1554-5^GLUCOSE^POST 12H CFST:MCNC:PT:SER/PLAS:QN||^182|mg/dl|70_105|H|||F

Typical Parsing in TCL
----------------------
Typically, when parsing an HL7 message in TCL, you have to break the message apart based on the given separators.  When modifying the message, you not only have to split the message to pull data out, but you also have to rebuild the message afterwards.

This parsing and rebuilding is well suited for TCL, but unfortunately, the parsing/rebuilding logic takes away from the actual problem that you are actually trying to solve.  That's where this library can help.

HL7 Addressing Scheme
---------------------
By creating an addressing scheme for HL7 fields, components, etc., we are able to abstract away the parsing and rebuilding logic behind a TCL library.

The addressing scheme that TclHL7 uses is closely related to the structure of an HL7 message (see above).

An address is made up of five parts, each separated by a ".":

1. segment address part
2. field address part
3. repetition address part
4. component address part
5. subcomponent address part

Thus, an address that addresses the first subcomponent of the second ID in PID.3 of the above example can be addressed as:
	
	PID.3.1.0.0

where:

- `PID` is the segment address part
- `3` is the field address part
- `1` is the repetition address part
- `0` is the component address part
- `0` is the subcomponent address part

Wildcards can also be used to address more than one item in a message.  To address the first subcomponent of each ID in PID.3, the following query address can be used:

	PID.3.*.0.0

This is the same as the previous example, except that the `*` now matches **all** repetitions in PID.3.

The segment address part can match in the following ways:

1. segment type: `MSH`, `PID`, etc.
2. single index: For example, MSH segments would correspond to index `0`.
3. `*`: all segments
4. any glob pattern that works with TCL's `string match` command: For example `Z*`.

The field, repetition, component, and subcomponent address parts match in the following ways:

1. single index: `0`, `10`, etc.
2. `*`: all present values at the given level
3. range: all indexes in the given range (i.e `1-3`)
4. index to end: from the given index to the last index at the given level (i.e. `2-end`)

### Static Addresses

The addressing scheme mentioned above describes what I like to call **query addresses**.  They are capable of matching more than one item in an HL7 message.  While this is helpful, you also need a canonical way to address a given item.

The canonical address of an item in an HL7 message is called a **static address**.  A static address is made up of five parts joined by periods (just like the query addresses).  Where query address parts can contain wildcards, static address parts can only contain a single index.  This being said, a static address can also be used as a query address.

Using the example HL7 message above, the query address `PID.3.*.0.0` expands to the following static addresses:

- `1.3.0.0.0`
- `1.3.1.0.0`

Installing/Using the Library
----------------------
To use the library, source the `build/hl7.tcl` file into your TCL scripts.  The full library is contained in the `hl7.tcl` file, thus you can source it directly in your code or you can add it to you `auto_path`.

	#!/usr/bin/env tclsh

	# source the TclHL7 library
	source hl7.tcl

	# ...

	# Use the TclHL7 library!
	set msg [hl7 parse $msgdata]


HL7 Commands
------------
Below are the commands provided by TclHL7.

### `parse`

Before an HL7 message can be manipulated by TclHL7, it must be parsed and split into segments, fields, etc.  The `parse` command is how you take an HL7 message and prepare it for the other commands provided by TclHL7.

Usage:

	hl7 parse <msgdata> [<segment_separator>]

	Arguments:
		msgdata: The raw HL7 message being parsed.
		segment_separator (optional):
			- Default: \r
			- This argument determines what is used as the separator between the segments.

Example Usage:

	# Assume that the raw HL7 message is in the 'msgdata' variable.
	set msg [hl7 parse $msgdata]

	# Now use the 'msg' variable with other TclHL7 commands
	set values [hl7 get values $msg PID.3.*.0.0]

### `data`

After a message has been parsed with `hl7 parse`, to get it back into its raw-data form, you use the `data` command.

Usage:

	hl7 data <msg>

	Arguments:
		msg: The parsed HL7 message that is being converted to raw data.

Example Usage:

	# Parse the message
	set msg [hl7 parse $msgdata]

	# Modify the message
	set msg [hl7 set $msg MSH.3.0.0.0 "SENDAPP"]

	# Get the data of the message
	set msgdata [hl7 data $msg]

### `query`

This proc takes a parsed message and a query address, and it returns a list of all matching static addresses.  See **Static Addresses** above.

Usage:

	hl7 query <msg> <query> [<expand>] [<reverse>]

	Arguments:
		msg: This is the parsed message being queried against.
		query: This is the query being run against the given message.
		expand (optional):
			- Default: 0
			- Set this argument to `1` to return addresses that match repetitions, components, or subcomponents that do not exist.
			- For example, if a field only has one repetition, by default, a query addressing the third repetition would not be returned.  By setting `expand` to `1`, the "invisible" repetition's address would be returned.
			- This argument does not affect segments or fields.  Segments are never expanded, fields are always expanded.
		reverse (optional):
			- Default: 0
			- By default, the `query` command returns a sorted list of static addresses, with the addresses in the order that you would find them as you move from the start of the message to the end.  By settting this to `1`, you will get a reverse-sorted list of addresses.
			- This is useful for when you are performing destructive actions on a message (such as removing segments, repetitions, etc.).  If you perform an action that changes another item's static address/index, then the items need to be processed from the back of the message to the front.  Otherwise, you may invalidate any previously queried addresses.

Example Usage:
	
	# Assume that 'msg' contains a parsed HL7 message

	set addresses [hl7 query $msg "PID.3.*.0.0"]

	# reverse the results
	set reversed_addresses [hl7 query $msg "PID.3.*.0.0" 0 1]

	# expand to the 3rd repetition, even if it's not present
	set expanded_addresses [hl7 query $msg "PID.3.2.0.0" 1]

	# both expand and reverse the results
	set expanded_reversed_addresses [hl7 query $msg "PID.3.*.4.0" 1 1]

### `get`

This proc is used to actually pull data out of an HL7 message.  It always returns a **list** of matches.

By default, this proc returns a list of value-address pairs.  The value is the value of the matched item, and the address is the static address of the matched item.  This allows you analyze the value and then issue subsequent modification commands using the item's static address.  There is a form of the `get` command that returns a list of matched values, not a list of matched value-address pairs.  If you need just the matched addresses, you can use the `query` command.

Usage:

	# standard usage
	hl7 get <msg> <query> [<reverse>] [<expand>]

	Arguments:
		msg: The message being queried against.
		query: The query indicating the items to be matched.
		reverse (optional):
			- Default: 0
			- If set to `1`, the command reverses the results.
			- See the comments on reversing for the `query` command.
		expand (optional):
			- Default: 0
			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
			- See the comments on expanding for the `query` command.

	# reverse the results
	hl7 get reversed <msg> <query> [<expand>]
		msg: The message being queried against.
		query: The query indicating the items to be matched.
		expand (optional):
			- Default: 0
			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
			- See the comments on expanding for the `query` command.

	# return only matching values
	hl7 get values <msg> <query> [<reverse>] [<expand>]
		msg: The message being queried against.
		query: The query indicating the items to be matched.
		reverse (optional):
			- Default: 0
			- If set to `1`, the command reverses the results.
			- See the comments on reversing for the `query` command.
		expand (optional):
			- Default: 0
			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
			- See the comments on expanding for the `query` command.
	
Example Usage:

	# Usually, you would loop through the results.
	# Most loops can be handled by `hl7 each`.
	foreach result [hl7 get $msg PID.3.*.0.0] {
		set value [lindex $result 0]
		set address [lindex $result 1]

		# do something with the value and address
		puts "$address) $value"
	}

	# Occasionally, you'd only want the values
	set values [hl7 get values $msg PID.3.*.0.0]

	# If you're doing something destructive, reverse the results.
	foreach result [hl7 get reversed $msg *.0.0.0.0] {
		# remove Z segments
		set segment_type [lindex $result 0]

		if { [regexp {^Z} $segment_type] } {
			# remove the Z segment

			# get the address of the result
			set address [lindex $result 1]

			# get the segment address (the first part)
			set segment_address [lindex [split $address "."] 0]

			# remove the segment
			set msg [hl7 delete $msg $segment_address]
		}
	}

### `set`

This proc is used to set the value of the items that match the given query address.  It makes the modifications and returns the resulting parsed-message.

Usage:

	hl7 set <msg> <query> <value> [<expand>]
	
	Arguments:
		msg: The message being modified.
		query: The query indicating the items to be modified.
		value: The new value of the matched items.
		expand (optional):
			- Default: 0
			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the message is expanded to include the indicated item and its value is set to the given value.
			- See the comments on expanding for the `query` command.

Example Usage:

	# set the sending and receiving facilities to '01'
	set msg [hl7 set $msg MSH.4,6.0.0.0 "01"]

### `clear`

This proc clears out the contents of the items that match the given query.  The modified parsed-message is returned.

Usage:

	hl7 clear <msg> <query>
	
	Arguments:
		msg: The message being modified.
		query: The query indicating the items to be cleared.

Example Usage:

	# clear out the identifiers in PID.2
	set msg [hl7 clear $msg PID.2]

### `delete`

This proc removes the items that match the given query from the message.  The modified parsed-message is returned.

Usage:

	hl7 delete <msg> <query>

	Arguments:
		msg: The message being modified.
		query: The query indicating the items to be removed.

Example Usage:

	# remove the 2nd identifier in PID.3
	set msg [hl7 delete $msg PID.3.1]

### `add`

This proc appends the given value to the end of the items indicated by the query.  The modified parsed-message is returned.

Note that this can't be run on segments or subcomponents.  You can't run it on segments because appending a field to the end of a segment is usually not needed (usually, the field index has meaning).  You can bypass this by using `set`.  You can't run this on subcomponents because there are not items at a level lower than subcomponents.

Usage:

	hl7 add <msg> <query> <value> [<expand>]

	Arguments:
		msg: The message being modified.
		query: The query indicating the items being appended to.
		value: The value being appended.
		expand (optional):
			- Default: 1
			- Typically, you would want the message to expand to include the item that you are appending to.
			- See the comments on expanding for the `query` command.

Example Usage:

	# add an identifier repetition to PID.3
	set msg [hl7 add $msg PID.3 $id]

### `insert`

This proc inserts the given value either at the address indicated in the query or after the address.  All items at the inserted index (and after) are shifted.

Usage:

There are three forms of the `insert` command, two of which perform the same operation:

1. `insert <msg> <query> <value>`: This form inserts the value at the address indicated by `query`.
2. `insert before <msg> <query> <value>`: This form acts just like the first form.
3. `insert after <msg> <query> <value>`: This form inserts the value after the address indicated by `query`.

Example Usage:
	
	# insert the id as the first repetition in PID.3
	set msg [hl7 insert $msg PID.3.0 $id]

	# do the same thing, using `insert before`
	set msg [hl7 insert before $msg PID.3.0 $id]

	# insert the id as the second repetition in PID.3
	set msg [hl7 insert after $msg PID.3.0 $id]

### `each`

A common idiom that you will see with this library is looping through the results of an `hl7 get` call.  The way to do this with TCL's `foreach` command can be seen below:

	# loop through each item
	foreach result [hl7 get $msg PID.3.*.0.0] {
		set value [lindex $result 0]
		set address [lindex $result 1]

		# do something with the value and address
		puts "$address) $value"
	}

Notice that with this example, you have to manually pull out each result's value and address using `lindex`.  Since this was such a common idiom, `hl7 each` was created to simplify this scenario.

For example, the above becomes the following when using `hl7 each`:

	# loop through each item
	hl7 each {value address} $msg PID.3.*.0.0 {
		# do something with the value and address
		puts "$address) $value"
	}

	# The variables can be named whatever you like.
	# This is the same as the above example.
	hl7 each {v a} $msg PID.3.*.0.0 {
		# do something with the value and address
		puts "$a) $v"
	}

You can also loop over just the values, if you have no need for the addresses:

	# loop through each value
	hl7 each value $msg PID.3.*.0.0 {
		# do something with the value
		puts "$value"
	}
	
The first argument passed to `hl7 each` determines the names of the variables set in the body.  The body of this `hl7 each` loop is the last argument passed to the command.  The rest of the arguments (between the variable names and the body) get passed to the `get` command, so you can also reverse and expand the query as needed.

For example:

	# loop through each item, in reverse order
	hl7 each {v a} $msg PID.3.*.0.0 1 {
		# do something with the value
		puts "$a) $v"
	}

Usage:

	hl7 each <vars> <msg> <query> [<reverse>] [<expand>] <body>

	Arguments:
		vars: This argument determines the names of the variables that will get set for each iteration of the results.
			- If this argument has one item, only the value of each iteration is set.
			- If this arguemnt has more than two items, the first name given will get set to the value of the current iteration's result.  The second name given will get set to the address of the current iteration's result.
		msg: The message being queried against.
		query: The query indicating the items to be matched.
		body: This is the body that will be run for each item in the results.
		reverse (optional):
			- Default: 0
			- If set to `1`, the command reverses the results.
			- See the comments on reversing for the `query` command.
		expand (optional):
			- Default: 0
			- This is passed to the `query` command.  If a queried item does not exist and the `query` call returns an address for the missing item, the value is set to a blank string ("").
			- See the comments on expanding for the `query` command.

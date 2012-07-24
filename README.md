TclHl7 - HL7 Addressing Library for TCL
=======================================
TCL is a great language for processing [HL7 messages](http://en.wikipedia.org/wiki/Health_Level_7).
Unfortunately, you usually have to manually parse the message and rebuild it if you made modifications.
The intentions of this library is to provide an addressing scheme for HL7 messages that will allow data
to be pulled from an HL7 message and allow a message to be manipulated in a concise manner.

HL7 Message Structure
---------------------
An HL7 message has the following structure:

- A message contains a list of segments.
	- Typically separated by \r
- A segment is made up of a list of fields.
	- Typically separated by |
- A field is made up of a list of field repetitions.
	- Typically separated by ~
- A field repetition is made up of a list of components.
	- Typically separated by ^
- A component is made up of a list of subcomponents.
	- Typically separated by &



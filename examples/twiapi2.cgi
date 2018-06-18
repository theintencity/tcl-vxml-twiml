#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

set client [Client::create "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "your_auth_token"]
set calls [$client GET Calls?StartTimeAfter=2009-07-06T00%3A00%3A00Z&Status=completed]
puts "\[[$calls set /TwilioResponse/Calls/@start]-[$calls set /TwilioResponse/Calls/@end]\] [$calls set /TwilioResponse/Calls/Call/Sid]"
$client delete


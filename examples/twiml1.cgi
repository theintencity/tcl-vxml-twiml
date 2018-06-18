#!/usr/bin/env tclsh

lappend auto_path .
package require twiml
package require cgi

cgi_input

if [catch {cgi_import state}] { set state {}}

if {$state == ""} {
	Response {
		Say "Hello there!"
		Gather method=GET action=?state=one {
			Say "Please press 1 or say sales for sales. Press 2 or say support for support."
		}
		Say "Let me connect you to a sales person"
		Pause length=10 {}
		Dial timeout=10 record=true {
			Number "+14151234567"
		}
	}
} else {
	if [catch {import Digits}] { set Digits {}}
	
	Response {
		if {$Digits == 1} {
			Say "Let me connect you to a sales person"
			Dial timeout=10 record=true {
				Number "+14151234567"
			}
		} else {
			Say "Let me connect you to customer support"
			Dial timeout=10 record=true {
				Number "+14151234000"
			}
		}
	}
}

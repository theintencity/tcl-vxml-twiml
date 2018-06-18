#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

set client [Client::create "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "your_auth_token"]
if {[catch {$client GET Calls/CAXXXXX} errMsg]} {
    puts $errMsg
}
$client delete


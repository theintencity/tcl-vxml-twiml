#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

set client [Client::create "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "your_auth_token"]
$client POST Messages Body "Hello There" From "+14156501988" To "+19176216392"
$client delete


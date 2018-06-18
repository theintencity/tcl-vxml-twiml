#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

Response {
  Dial {
    Number sendDigits=wwww1928 415-123-4567
  }
}

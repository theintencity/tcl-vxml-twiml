#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

Response {
  Dial action=/handleDialCallStatus method=GET {
    puts 415-123-4567
  }
  Say Goodbye
}

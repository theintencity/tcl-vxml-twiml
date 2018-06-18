#!/usr/bin/env tclsh

lappend auto_path .
package require twiml

Response {
  Gather input=speech\ dtmf timeout=3 numDigits=1 {
    Say "Please press 1 or say sales for sales."
  }
}

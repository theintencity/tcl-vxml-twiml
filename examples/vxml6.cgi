#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

set authenticated false

if {!$authenticated} {
  set next_script "after-pin.cgi"
  set prompt "Please enter your four digit PIN"
  voicexml {
    form {
      field name=pin {
        prompt {
          puts $prompt
        }
      }
      block {
        submit next=$next_script namelist=pin
      }
    }
  }
}

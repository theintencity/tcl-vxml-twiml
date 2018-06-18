##################################################
#
# vxml.tcl - Scripting VoiceXML scripts in Tcl
# Author: Kundan Singh <theintencity@gmail.com> 2018
#
####### MIT LICENSE ##############################
# Copyright 2018, Kundan Singh <kundan10@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
##################################################

set _vxml(tags) {
  assign audio block catch choice clear disconnect else elseif 
  enumerate error exit field filled form goto grammar help if
  initial link log menu meta metadata noinput nomatch object option param
  prompt property record reprompt return script subdialog
  submit throw transfer value var vxml ?xml
}


proc unknown {command args} {
  global _vxml

  if {![info exists _vxml(indent)]} {
    set _vxml(indent) 0
  } else {
    incr _vxml(indent)
  }

  if {[regexp "^vxml_(.*)" $command dummy c]} {
    set command $c
  }

  if {[lsearch -exact $_vxml(tags) $command] < 0} {
    error "No such VoiceXML tag \"$command\" defined."
  }
  
  puts -nonewline "[format %${_vxml(indent)}s ""]<$command"
  if {[llength $args] <= 0} {
    if {[regexp {^\?} $command]} {
      puts "?>"
    } else {
      puts "/>"
    }
  } else {
    set attr ""
    set str ""
    foreach a [lrange $args 0 [expr [llength $args]-2]] {
        if {[regexp "^(\[a-zA-Z0-9_\-]*)=(.*)" $a dummy attr str]} {
            puts -nonewline " $attr=\"$str\""
        } else {
            puts -nonewline " $a"
        }
        set attr ""
        set str ""
    }
    set a [lindex $args end]
    set attr ""
    set str ""

    if {[regexp "^(\[a-zA-Z0-9_\-]*)=(.*)" $a dummy attr str]} {
        puts -nonewline " $attr=\"$str\""
        if {[regexp {^\?} $command]} {
            puts "?>"
        } else {
            puts " />"
        }
    } else {
        puts ">"
        if {[catch {uplevel 1 [lindex $args end]} err]} {
            append _vxml(errmsg) $err
            append _vxml(errmsg) "\n"
            append _vxml(errmsg) "This is for $command tag."
        }
        puts "[format %${_vxml(indent)}s ""]</$command>"
    }
  }

  set _vxml(indent) [expr $_vxml(indent) - 1]
}

proc voicexml {cmd} {
  global _vxml env

  if {[info exists env(REQUEST_METHOD)]} {
    puts "Content-Type: text/plain\n"
  }

  vxml_?xml version=1.0

  rename puts puts_old
  set _vxml(buffer) ""

  proc puts args {
    if {[lindex $args 0] == "-nonewline" && [llength $args] == 2 
       || [lindex $args 0] != "-nonewline" && [llength $args] == 1} {
      global _vxml
      append _vxml(buffer) [lindex $args end]
      if {[llength $args] == 1} {
          append _vxml(buffer) "\n"
      }
    } else {
      if {[llength $args] <= 2} {
        puts_old [lindex $args 0] [lindex $args 1]
      } else {
        puts_old [lindex $args 0] [lindex $args 1] [lindex $args 2]
      }
    }
  }

  set xmlns {xmlns=http://www.w3.org/2001/vxml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.w3.org/2001/vxml http://www.w3.org/TR/voicexml20/vxml.xsd"}
  
  uplevel 1 "vxml_vxml ${xmlns} version=2.0 { $cmd }"
  
  rename puts ""
  rename puts_old puts

  if {[info exists _vxml(errmsg)]} {
    vxml_vxml version=1.0 {
      vxml_form {
        vxml_block {
          vxml_prompt {
            puts "There was an error in generating the page."
            puts "$_vxml(errmsg) ."
          }
        }
      }
    }
  } else {
    puts "$_vxml(buffer)"
  }
}

package provide vxml 2.0

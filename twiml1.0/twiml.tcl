##################################################
#
# twiml.tcl - Scripting TwiML (and similar) scripts in Tcl.
#             Invoking Twilio REST API from Tcl programs.
#
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

package require base64
package require http
package require tls


set _twiml(tags) {
    Client Conference Dial Gather Number Queue Sim SIP Enqueue Hangup
    Leave Pause Play Record Redirect Reject Response Say
}

set _twiml(tags1) { Dial Gather Response }

set _twiml(attr) "^(\[a-zA-Z0-9_\-]*)=(.*)"

set _twiml(started) 0

rename unknown _original_unknown

proc unknown {cmd args} {
    global _twiml
    
    if {$_twiml(started) == 0 && $cmd == "Response"} {
        uplevel 1 [list TwiML [list $cmd {*}$args]]
        return
    }

    if {[lsearch -exact $_twiml(tags) $cmd] >= 0} {
        puts -nonewline "<$cmd"
        if {[llength $args]} {
            foreach a [lrange $args 0 [expr {[llength $args]-2}]] {
               if {[regexp $_twiml(attr) $a dummy attr str]} {
                    puts -nonewline " $attr=\"$str\""
                } else {
                    puts -nonewline " $a"
                }
            }
        }
        set last [lindex $args end]
        if {"$last" == ""} {
            puts -nonewline "/>"
        } else {
            puts -nonewline ">"
            if {[lsearch -exact $_twiml(tags1) $cmd] >= 0} {
                if {[catch {uplevel 1 $last} err]} {
                    append _twiml(errmsg) $err
                    append _twiml(errmsg) "\n"
                    append _twiml(errmsg) "This is for $cmd tag."
                }
            } else {
                puts -nonewline $last
            }
            puts -nonewline "</$cmd>"
        }
    } else {
        uplevel 1 [list _original_unknown {*}$args]
    }
}

set _twiml(xml) "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

proc TwiML {cmd} {
    global _twiml env
    
    set _twiml(started) 1

    if {[info exists env(REQUEST_METHOD)]} {
        puts "Content-Type: text/xml\n"
    }

    puts $_twiml(xml)

    rename puts puts_old
    set _twiml(buffer) ""

    proc puts args {
        if {[lindex $args 0] == "-nonewline" && [llength $args] == 2 
            || [lindex $args 0] != "-nonewline" && [llength $args] == 1} {
            global _twiml
            append _twiml(buffer) [lindex $args end]
            if {[llength $args] == 1} {
                append _twiml(buffer) "\n"
            }
        } else {
            if {[llength $args] <= 2} {
                puts_old [lindex $args 0] [lindex $args 1]
            } else {
                puts_old [lindex $args 0] [lindex $args 1] [lindex $args 2]
            }
        }
    }

    set _twiml(body) $cmd
    
    uplevel 1 {
        if {1==[catch $_twiml(body) errMsg]} {
            set _twiml(errorInfo) $errorInfo
            
            if {![info exists env(REQUEST_METHOD)]} {
                puts stderr $_twiml(errorInfo)
                return
            }
        }
    }
  
    rename puts ""
    rename puts_old puts
    
    if {[info exists _twiml(errmsg)]} {
        Response {
            Say "There was an error in generating the page."
            Say "$_twiml(errmsg) ."
        }
    }
    
    # puts -nonewline [xmlpretty "$_twiml(buffer)"]
    puts "$_twiml(buffer)"
    
    set _twiml(started) 0
}


# see http://wiki.tcl.tk/3100
proc xmlpretty xml {
    [[dom parse $xml doc] documentElement] asXML
}


# see http://wiki.tcl.tk/10300

namespace eval Client {
    variable n 0
}

proc Client::create {account token} {
    variable n
    namespace eval [incr n] [list variable account $account token $token]
    set self [namespace current]
    interp alias {} ${self}::$n {} ${self}::dispatch $n
    return ${self}::$n
}

proc Client::dispatch {this cmd args} {
    eval $cmd $this $args
}

proc Client::delete this {
    # close [set ${this}::fp] ;# specific
    namespace delete $this
    interp alias {} [namespace current]::$this {}
}

set _twiml(twilioapi) "https://api.twilio.com/2010-04-01"

http::register https 443 [list ::tls::socket -tls1 1]

proc Client::_http {this method path args} {
    global _twiml
    set account [set ${this}::account]
    set token [set ${this}::token]
    set theurl "$_twiml(twilioapi)/Accounts/${account}/$path"
    dict set hdr Authorization "Basic [base64::encode $account:$token]"
    if {[llength $args] > 0} {
        set body [http::formatQuery {*}$args]
        set response [http::geturl $theurl -method $method -headers $hdr -query $body]
    } else {
        set response [http::geturl $theurl -method $method -headers $hdr]
    }
    set responseBody [http::data $response]
    http::cleanup $response
    
    set result [xmlstruct::create $responseBody]
    if {[$result set /TwilioResponse/RestException] != ""} {
        return -level 2 -code error [$result set /TwilioResponse/RestException/Message]
    }
    return $result
}

proc Client::GET {this path} {
    uplevel 1 _http $this GET $path {}
}

proc Client::POST {this path args} {
    uplevel 1 _http $this POST $path $args
}

proc Client::DELETE {this path} {
    uplevel 1 _http $this DELETE $path {}
}

proc Client::PUT {this path args} {
    uplevel 1 _http $this PUT $path $args
}


 # see http://wiki.tcl.tk/4193
 #
 # TODO: return the value when setting a value and return a list of values when multiple values are set
 #
 package require tdom
 # By placing these procs in the ::dom::domNode namespace, they automatically 
 # become add-on domNode methods
 proc ::dom::domNode::unset {node query} {
        ::set resultNodes [$node selectNodes $query type]
        switch $type {
                attrnodes {xmlstruct::unsetattrs $node $query}
        nodes {xmlstruct::unsetnodes $resultNodes}
        empty {error "No results found for '$query'"}
                default {error "$type is an unsupported query result type"}
    }
 }
 proc ::dom::domNode::set {node query args} {
        switch [llength $args] {
                0 {return [xmlstruct::getvalue $node $query]}
                1 {return [xmlstruct::setvalue $node $query [lindex $args 0]]}
                default {error "wrong # args: should be \"set xpathQuery ?newValue?\""}
    }
 }
 proc ::dom::domNode::lappend {node query args} {
    foreach arg $args {
        xmlstruct::setnew $node $query $arg
    }
 }
 namespace eval xmlstruct {}

 # Convenience function for creating an xml doc and returning the root
 proc xmlstruct::create {xml} {
        ::set doc [dom parse $xml]
        return [$doc documentElement] 
 }

 # For '$node set query' calls
 proc xmlstruct::getvalue {node query} {
        ::set resultNodes [$node selectNodes $query type]
        switch $type {
                attrnodes {
                        ::set retVal {}
                        foreach attrVal $resultNodes {
                                lappend retVal [lindex $attrVal 1]
            }
                        return $retVal
        }
                nodes {
                        ::set retVal {}
                        foreach node $resultNodes {
                ::set xml ""
                foreach child [$node childNodes] {
                    append xml [$child asXML]
                }
                                lappend retVal $xml 
            }
            # This is so the curly braces are not there due to the above lappend
            if {[llength $resultNodes] == 1} {::set retVal [lindex $retVal 0]}
                        return $retVal
        }
        empty {return ""}
                default {error "$type is an unsupported query result type"}
    }
 }

 # For '$node set query value' calls
 proc xmlstruct::setvalue {node query value} {
        ::set targetNodes [$node selectNodes $query type]
        switch $type {
                nodes {xmlstruct::setnodes $targetNodes $query $value}
                attrnodes {xmlstruct::setattrs $node $query $value}
                empty {xmlstruct::setnew $node $query $value}
                default {error "$type is an unsupported query result type"}
    }
 }

 # Creates a new attribute/element for an xpath query in which all
 # the elements of the query up to the last exist
 proc xmlstruct::setnew {node query value} {
    set possibleMatch [split $query /]
    set unmatched [lindex $possibleMatch end]
    set possibleMatch [lreplace $possibleMatch end end]
    if {[llength $possibleMatch] == 0} {
        set possibleMatch .
    }
    
    set nodes [$node selectNodes [join $possibleMatch /] type]
    switch $type {
        nodes {
            if {[string index $unmatched 0] == "@"} {
                foreach node $nodes {
                    $node setAttribute [string range $unmatched 1 end] $value
                }
            } else {
                foreach node $nodes {
                    $node appendXML "<$unmatched/>"
                    set newNode [$node lastChild]
                    $newNode set . $value
                }
            }
        }
        attrnodes {error "Can't add children to attributes ($possibleMatch)"}
        empty {error "Create elements matching $possibleMatch first"}
    }
 }

 # For i.e. '$node unset {/employees/employee[1]/@age}' calls
 proc xmlstruct::unsetattrs {node query} {
    ::set nodeQuery [join [lrange [split $query /] 0 end-1] /]
    ::set attribute [string range [lindex [split $query /] end] 1 end]
    foreach matchingNode [$node selectNodes $nodeQuery] {
        $matchingNode removeAttribute $attribute
    }
 }

 # For i.e. '$node set {/employees/employee[1]/@age} 25' calls
 proc xmlstruct::setattrs {node query value} {
    ::set nodeQuery [join [lrange [split $query /] 0 end-1] /]
    ::set attribute [string range [lindex [split $query /] end] 1 end]
    foreach matchingNode [$node selectNodes $nodeQuery] {
        $matchingNode setAttribute $attribute $value
    }
    return $value
 }
 # For i.e. '$node unset {/employees/employee[1]}' calls
 proc xmlstruct::unsetnodes {nodes} {
    # This probably breaks if some nodes are descendents of each other and
    # they don't get deleted in the right order
    foreach node $nodes {
        $node delete
    }
 }

 # Determines if the given string is intended to be valid xml
 proc xmlstruct::isXml {string} {
        ::set string [string trim $string]
        if {([string index $string 0] == "<") && [string index $string end] == ">"} {
                return 1
    } else {
                return 0
    }
 }

 # For i.e. '$node set {/employees/employee[1]} value' calls
 proc xmlstruct::setnodes {targetNodes query value} {
        if {[xmlstruct::isXml $value]} {
                foreach target $targetNodes {xmlstruct::setxml $target $value}
        } else {
                foreach target $targetNodes {xmlstruct::settext $target $value} 
    }
 }
 # TODO: don't allow this to be called for the documentElement node
 # (i.e. $obj set / "some text"  should not be allowed)
 # For i.e. '$node set {/employees/employee/name} Bill' calls
 proc xmlstruct::settext {node text} {
    ::set doc [$node ownerDocument]
    foreach child [$node childNodes] {$child delete}
    if {[string length $text] > 0} {
        ::set textNode [$doc createTextNode $text]
        $node appendChild $textNode
    }
    return $text
 }
 # For i.e. '$node set {/employees/employee} <name>Bill</name>' calls
 proc xmlstruct::setxml {node xml} {
        foreach child [$node childNodes] {$child delete}
        $node appendXML $xml
    return $xml
 }

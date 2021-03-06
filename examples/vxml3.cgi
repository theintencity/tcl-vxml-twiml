#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

# <?xml version="1.0" encoding="UTF-8"?>
# <vxml xmlns="http://www.w3.org/2001/vxml"
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
#   xsi:schemaLocation="http://www.w3.org/2001/vxml 
#    http://www.w3.org/TR/voicexml20/vxml.xsd"
#    version="2.0">
#  <var name="bye" expr="'Ciao'"/>
#  <link next="operator_xfer.vxml">
#    <grammar type="application/srgs+xml" root="root" version="1.0">
#      <rule id="root" scope="public">operator</rule>
#   </grammar>
#  </link>
# </vxml>

voicexml {
  var name=bye expr='Ciao'
  link next=operator_xfer.vxml {
    grammar type=application/srgs+xml root=root version=1.0 {
      puts {<rule id="root" scope="public">operator</rule>}
    }
  }
}
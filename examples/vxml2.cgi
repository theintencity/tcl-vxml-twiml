#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

# <?xml version="1.0" encoding="UTF-8"?>
# <vxml xmlns="http://www.w3.org/2001/vxml" 
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
#   xsi:schemaLocation="http://www.w3.org/2001/vxml http://www.w3.org/TR/voicexml20/vxml.xsd"
#   version="2.0">
#  <meta name="author" content="John Doe"/>
#  <meta name="maintainer" content="hello-support@hi.example.com"/>
#  <var name="hi" expr="'Hello World!'"/>
#  <form>
#   <block>
#      <value expr="hi"/>
#      <goto next="# say_goodbye"/>
#   </block>
#  </form>
#  <form id="say_goodbye">
#   <block>
#      Goodbye!
#   </block>
#  </form>
# </vxml>

voicexml {
  form {
    field name=drink {
      meta name=author content=John\ Doe
      meta name=maintainer content=hello-support@hi.example.com
      var name=hi expr='Hello\ World!'
      form {
        block {
          value expr=hi
          goto next=#say_goodbye
        }
      }
      form id=say_goodbye {
        block {
          puts "Goodbye!"
        }
      }
    }
  }
}
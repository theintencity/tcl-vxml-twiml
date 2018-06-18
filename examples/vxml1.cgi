#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

# <?xml version="1.0" encoding="UTF-8"?>
# <vxml xmlns="http://www.w3.org/2001/vxml"
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#   xsi:schemaLocation="http://www.w3.org/2001/vxml http://www.w3.org/TR/voicexml20/vxml.xsd"
#   version="2.0">
#   <form>
#     <field name="drink">
#       <prompt>
# Would you like coffee, tea, milk, or nothing?
#       </prompt>
#       <grammar src="drink.grxml" type="application/srgs+xml" />
#     </field>
#     <block>
#       <submit next="http://www.drink.example.com/drink2.asp" />
#     </block>
#   </form>
# </vxml>

voicexml {
  form {
    field name=drink {
      prompt {
        puts "Would you like coffee, tea, milk or nothing ?"
      }
      grammar src=drink.grxml type=application/srgs+xml
    }
    block {
      submit next=http://www.drink.example.com/drink2.asp
    }
  }
}

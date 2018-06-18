#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

# <?xml version="1.0" encoding="UTF-8"?>
# <vxml xmlns="http://www.w3.org/2001/vxml" 
#    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
#    xsi:schemaLocation="http://www.w3.org/2001/vxml 
#    http://www.w3.org/TR/voicexml20/vxml.xsd"
#    version="2.0" application="app-root.vxml">
#  <form id="say_goodbye">
#   <field name="answer">
#      <grammar type="application/srgs+xml" src="/grammars/boolean.grxml"/>
#      <prompt>Shall we say <value expr="application.bye"/>?</prompt>
#      <filled>
#        <if cond="answer">
#         <exit/>
#        </if>
#        <clear namelist="answer"/>
#      </filled>
#   </field>
#  </form>
# </vxml>

voicexml {
  form id=say_goodbye {
    field name=answer {
      grammar type=application/srgs+xml src=/grammars/boolean.grxml
      prompt {
        puts "Shall we say "
        value expr=application.bye
        puts "?"
      }
      filled {
        vxml_if cond=answer {
          vxml_exit
        }
        clear namelist=answer
      }
    }
  }
}

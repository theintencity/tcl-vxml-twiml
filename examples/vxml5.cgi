#!/usr/bin/env tclsh

lappend auto_path .
package require vxml

# <?xml version="1.0" encoding="UTF-8"?> 
# <vxml version="2.0" xmlns="http://www.w3.org/2001/vxml" 
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
#   xsi:schemaLocation="http://www.w3.org/2001/vxml 
#    http://www.w3.org/TR/voicexml20/vxml.xsd">
# <form id="get_card_info">
#  <block>We now need your credit card type, number,
#     and expiration date.</block>

voicexml {
  form id=get_card_info {
    block {
      puts "We now need your credit card type, number, and expiration date."
    }

#  <field name="card_type">
#   <prompt count="1">What kind of credit card
#     do you have?</prompt>
#   <prompt count="2">Type of card?</prompt>

    field name=card_type {
      prompt count=1 {
        puts "What kind of credit card do you have?"
      }
      prompt count=2 {
        puts "Type of card?"
      }
      
#   <!-- This is an inline grammar. -->
#   <grammar type="application/srgs+xml" root="r2" version="1.0">
#     <rule id="r2" scope="public">
#        <one-of>
#        <item>visa</item>
#        <item>master <item repeat="0-1">card</item></item>
#        <item>amex</item>
#        <item>american express</item>
#        </one-of>
#     </rule>
#   </grammar>
#   <help> Please say Visa, MasterCard, or American Express.</help>
#  </field>

      grammar type=application/srgs+xml root=r2 version=1.0 {
        puts {
     <rule id="r2" scope="public">
        <one-of>
        <item>visa</item>
        <item>master <item repeat="0-1">card</item></item>
        <item>amex</item>
        <item>american express</item>
        </one-of>
     </rule>
        }
      }
      help {
        puts "Please say Visa, MasterCard, or American Express"
      }
    }

# 
#  <field name="card_num">
#   <grammar type="application/srgs+xml" src="/grammars/digits.grxml"/>
#   <prompt count="1">What is your card number?</prompt>
#   <prompt count="2">Card number?</prompt>
#   <catch event="help">
#   <if cond="card_type =='amex' || card_type =='american express'">
#        Please say or key in your 15 digit card number.
#      <else/>
#        Please say or key in your 16 digit card number.
#      </if>
#   </catch>

    field name=card_num {
      grammar type=application/srgs+xml src=/grammars/digits.grxml
      prompt count=1 {
        puts "What is your card number?"
      }
      prompt count=2 {
        puts "Card number?"
      }
      vxml_catch event=help {
        vxml_if {cond=card_type == 'amex' || card_type == 'american_express'} {
          puts "Please say or key in your 15 digit card number."
          vxml_else
          puts "Please say or key in your 16 digit card number."
        }
      }
#   <filled>
#      <if cond="(card_type == 'amex' || card_type =='american express') 
#           &amp;&amp; card_num.length != 15">
#        American Express card numbers must have 15 digits.
#        <clear namelist="card_num"/>
#        <throw event="nomatch"/>
#      <elseif cond="card_type != 'amex'
#                 &amp;&amp; card_type !='american express'
#                 &amp;&amp; card_num.length != 16"/>
#        MasterCard and Visa card numbers have 16 digits.
#        <clear namelist="card_num"/>
#        <throw event="nomatch"/>
#      </if>
#   </filled>
#  </field>

      filled {
        vxml_if {cond=(card_type == 'amex' || card_type =='american express') &amp;&amp; card_num.length != 15} {
          puts "America Express card numbers must have 15 digits."
          clear namelist=card_num
          vxml_throw event=nomatch
          vxml_elseif {cond=card_type != 'amex' &amp;&amp; card_type !='american express' &amp;&amp; card_num.length != 16}
          puts "MasterCard and Visa card numbers have 16 digits."
          clear namelist=card_num
          vxml_throw event=nomatch
        }
      }
    }

# 
#  <field name="expiry_date">
#    <grammar type="application/srgs+xml" src="/grammars/digits.grxml"/>
#    <prompt count="1">What is your card's expiration date?</prompt>
#    <prompt count="2">Expiration date?</prompt>
#   <help>
#      Say or key in the expiration date, for example one two oh one.
#   </help>
#   <filled>
#      <!-- validate the mmyy -->
#      <var name="mm"/>
#      <var name="i" expr="expiry_date.length"/>
#      <if cond="i == 3">
#        <assign name="mm" expr="expiry_date.substring(0,1)"/>
#      <elseif cond="i == 4"/>
#        <assign name="mm" expr="expiry_date.substring(0,2)"/>
#      </if>
#      <if cond="mm == '' || mm &lt; 1 || mm &gt; 12">
#        <clear namelist="expiry_date"/>
#        <throw event="nomatch"/>
#      </if>
#   </filled>
#  </field>

    field name=expiry_date {
      grammar type=application/srgs+xml src=/grammars/digits.grxml
      prompt count=1 {
        puts "What is your card's expiration date?"
      }
      prompt count=2 {
        puts "Expiration date?"
      }
      help {
        puts "Say or key in the expiration date, for example one two oh one."
      }
      filled {
        var name=mm
        var name=i expr=expiry_date.length
        vxml_if {cond=i == 3} {
          assign name=mm expr=expiry_date.substrting(0,1)
          vxml_elseif {cond=i == 4}
          assign name=mm expr=expiry_date.substring(0,2)
        }
        vxml_if {cond=mm == '' || mm &lt; 1 || mm &gt; 12} {
          clear namelist=expiry_date
          vxml_throw event=nomatch
        }
      }
    }

# 
#  <field name="confirm">
#   <grammar type="application/srgs+xml" src="/grammars/boolean.grxml"/>
#   <prompt>
#       I have <value expr="card_type"/> number
#       <value expr="card_num"/>, expiring on
#       <value expr="expiry_date"/>.
#       Is this correct?
#   </prompt>
#   <filled>
#     <if cond="confirm">
#       <submit next="place_order.asp"
#         namelist="card_type card_num expiry_date"/>
#     </if>
#     <clear namelist="card_type card_num expiry_date confirm"/>
#   </filled>
#  </field>
# </form>
# </vxml>

    field name=confirm {
      grammar type=application/srgs+xml src=/grammars/boolean.grxml
      prompt {
        puts "I have "
        value expr=card_type
        puts " number "
        value expr=card_num
        puts ", expiring on "
        value expr=expiry_date
        puts ". Is this correct?"
      }
      filled {
        vxml_if cond=confirm {
          submit next=place_order.asp namelist=card_type\ card_num\ expiry_date
        }
        clear namelist=card_type\ card_num\ expiry_date\ confirm
      }
    }
  }
}

# Scripting VoiceXML and TwiML using Tcl

This article describes how to write XML-based programmable scripts such as for
W3C's VoiceXML or Twilio's TwiML using Tcl, the Tool Command Language.
Since many readers may not be familiar with Tcl, and the motivation to
create this project, I recommend reading my
[blog article](http://blog.kundansingh.com/2018/06/scripting-voicexml-and-twiml-using-tcl.html)
before using this project.

### XML-based documents

XML documents are structured text with hierarchical structure, such as
```XML
<?xml version="1.0"?>
<people>
  <person id="1234">
     <name>Kundan Singh</name>
     <url>http://kundansingh.com</url>
  </person>
  <person>
     <name>John Smith</name>
  </person>
</people>
```

Although XML is popular for machine-to-machine communication, many existing
programming languages treat XML text as second class citizens. Thus, manipulating
or parsing XML is clumsy, or requires external library that may change the way you
have to write XML related code compared to the rest of the code. This is particularly
relevant if XML is used to describe control commands such as for VoiceXML or TwiML,
instead of just storing structured data.

The following VoiceXML-based code instructs an IVR (Interactive Voice Response) system to
play a voice prompt, collect digits, and invoke another program with the collected digits.
```XML
<vxml>
  <form>
    <field name="pin">
      <prompt>Please enter your four digit PIN</prompt>
    </field>
    <block>
      <submit next="after-pin.cgi" namelist="pin" />
    </filled>
  </form>
</vxml>
```

Typically, such XML code is generated by web applications or server side scripts,
and are executed or interpreted by the IVR system. The server side script will
typically look like below. This may be because the script generates XML
on certain condition, e.g., whether the caller is authenticated, and has to
substitute some parts with values obtained from external sources, e.g., the path of the
next script and prompt text to play based on caller's spoken language.
```C:
if (!authenticated) {
    next_script = "after-pin.cgi"; // ... file name obtained from external source
    prompt = "Please enter your four digit PIN"; // ... prompt text from external
    println("<vxml>");
    println("  <form>");
    println("    <field name=\"pin\">");
    println("      <prompt>" + prompt + "</prompt>");
    println("    </field>");
    println("    <block>");
    println("      <submit next=\"" + next_script + "\" namelist=\"pin\" />");
    println("    </filled>");
    println("  </form>");
    println("</vxml>");
}
```

To reduce the ugliness of the code, the programmer ends up writing supporting libraries with
classes and methods to easily create such XML code, e.g.,
```C++
if (!authenticated) {
    next_script = "after-pin.cgi";
    prompt = "Please enter your four digit PIN";
    response = new voicexml();
    form = response.form();
    field = form.field(name="pin");
    field.prompt(prompt);
    block = form.block();
    block.submit(next=next_script, namelist="pin");
    print(response);
}
```
This reduces the opportunities to make mistakes, unlike writing the XML code by hand.
Unfortunately, this does not really remove the ugliness from the code.
Also, the programmer now has to not only understand the XML document but
also the library that provides these new objects and methods.

Wouldn't it be nice if the XML elements became objects and operations in your
code on demand? And the original hierarchical structure is preserved?
Consider the following code as an example.
```Tcl
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
```
That is actually a piece of valid Tcl code. And I will describe *how to do this*
shortly in this article.

Another example is as follows, with Twilio's TwiML for IVR-style processing.
The first XML code is desired, and second Python script code can generate that XML, using
Twilio's Python SDK that defines those new classes and methods.
The third Tcl script resembles closely with the XML, and can also generate that XML,
using the ideas and code mentioned in this article.

XML
```XML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Dial>
    <Number sendDigits="wwww1928">
      415-123-4567
    </Number>
  </Dial>
</Response>
```
Python
```Python
from twilio.twiml.voice_response import Dial, VoiceResponse

response = VoiceResponse()
dial = Dial()
dial.number('415-123-4567', send_digits='wwww1928')
response.append(dial)

print(response)
```
Tcl
```Tcl
package require twiml
Response {
  Dial {
    Number sendDigits=wwww1928 {
      415-123-4567
    }
  }
}
```

To get started with using the included Tcl packages,
the first step is to get comfortable with the basics of Tcl, if not already familiar.
Certain syntax and semantics are quite different from other popular scripting languages,
e.g., use of "quotes" or {curly braces}.

Next, download the `vxml` and `twiml` packages in this repository. Use the
`examples` directory to check out various examples, such as,
```Shell
$ tclsh examples/vxml1.cgi
```
These examples are intended to be CGI scripts, but can be reused in other Tcl
scripts. You may also rename the file extensions from `.cgi` to `.tcl` if you like.
These example files include both the desired XML output as well as the Tcl script
code to generate that output.

### VoiceXML

Consider the following desired XML.
```XML
<?xml version="1.0" encoding="UTF-8"?>
<vxml xmlns="http://www.w3.org/2001/vxml" ... version="2.0">
  <form>
    <field name="drink">
      <prompt>
         Would you like coffee, tea, milk, or nothing?
      </prompt>
      <grammar src="drink.grxml" type="application/srgs+xml" />
    </field>
    <block>
      <submit next="http://www.drink.example.com/drink2.asp" />
    </block>
  </form>
</vxml>
```

For the script code, first include the required package. If the package is
not available in standard Tcl library path, you may need to update the search
path too.
```Tcl
lappend auto_path .
package require vxml
```

This package defines all the VoiceXML elements (or tags) as commands. Thus,
`vxml`, `form`, `field`, etc., are be assumed to be Tcl commands. (Actually,
it uses the catch-all `unknown` handler behind the scenes to dynamically
define code for these XML tags.)

Additionally, the package includes a `voicexml` command to wrap the output in
CGI compatible format, e.g., with `Content-Type` header when needed. This command
also includes the default namespaces and attributes for the top-level `vxml` tag,
and inserts the initial `xml` declaration.

Thus, the previous XML can roughly map to the following hierarchical Tcl commands.
```Tcl
voicexml {
  form {
    field {
      prompt {
        ...
      }
      grammar
    }
    block {
      submit
    }
  }
}
```

Every command that represents the XML tag, can also take zero or more attributes.
Passing the attribute as arguments to the command can be done as `name=value` or `name="value"`.
Thus, the `field`, `grammar` and `submit` commands are changed as follows.
```Tcl
voicexml {
  form {
    field name=drink {
      prompt {
        ...
      }
      grammar src=drink.grxml type=application/srgs+xml
    }
    block {
      submit next=http://www.drink.example.com/drink2.asp
    }
  }
}
```
Children elements of a tag are specified as the last argument, if applicable. This
is executed as a set of commands, allowing nested heirarchical structure. If the
child element is just a text node, then built-in `puts` command can be used to
print that, as shown below.
```Tcl
      ...
      prompt {
        puts "Would you like coffee, tea, milk or nothing ?"
      }
```

If the child element has both inline text and elements, such as,
```XML
   <prompt>
     I have <value expr="card_type"/> card.
   </prompt>
```
then the corresponding Tcl script should include both text output as well as
nested Tcl commands, as follows. The three statements are put on the same
line to match the corresponding line in the XML document, but can be spread
across three lines for readability.
```Tcl
   prompt {
     puts "I have "; value expr=card_type; puts " card."
   }
```
Alternatively, you can modify the `vxml` library to also define commands that
return the XML representation, instead of printing out. For example, if
`value_` is defined as command to return a string representing this `value`
element, then the Tcl code could become:
```Tcl
   prompt {
     puts "I have [value_ expr=card_type] card."
   }
```

A VoiceXML document can refer to other XML-based content, such as for specifying
the `grammar` rules. The XML elements used by such content are not included in the
`vxml` package. Consider the following XML from `examples/vxml3.cgi`.

```XML
<?xml version="1.0" encoding="UTF-8"?>
<vxml xmlns="http://www.w3.org/2001/vxml" ... version="2.0">
 <link next="operator_xfer.vxml">
   <grammar type="application/srgs+xml" root="root" version="1.0">
     <rule id="root" scope="public">operator</rule>
  </grammar>
 </link>
</vxml>
```
The corresponding Tcl script is as follows. Note that the children elements of the
`grammar` tag are written as is, without using Tcl commands, e.g., for `rule`.
```Tcl
voicexml {
  link next=operator_xfer.vxml {
    grammar type=application/srgs+xml root=root version=1.0 {
      puts {<rule id="root" scope="public">operator</rule>}
    }
  }
}
```
However, if you are interested, you can implement similar concept for such embedded
external XML content in your package.

Since VoiceXML allows element names such as `if`, `else`, `elseif`, or `throw`
that are also Tcl commands,
you can use the prefix `vxml_` to invoke such VoiceXML commands from the Tcl program.
Consider the following XML snippet.
```XML
  <if cond="card_type =='amex' || card_type =='american express'">
     Please say or key in your 15 digit card number.
  <else/>
     Please say or key in your 16 digit card number.
  </if>
```
The corresponding Tcl script is as follows. Note that 
`vxml_if` and `vxml_else` are used instead of `if` and `else`.
```Tcl
  vxml_if {cond=card_type == 'amex' || card_type == 'american_express'} {
    puts "Please say or key in your 15 digit card number."
    vxml_else
    puts "Please say or key in your 16 digit card number."
  }
```
In fact, all the `vxml` commands, including `form`, `field`, `block`, etc.,
can be called with `vxml_` prefix, to avoid name collision with other potential
packages you may use. Alternatively, you can use Tcl namespace and modify the `vxml`
package.

Checkout other `vxml` examples in the repository.

#### TwiML

Using the `twiml` package is similar to using the `vxml` package with some crucial
differences: the set of XML tags and hence the commands are different; since the
XML tag names start with upper case letters, there is no prefixed named commands, as
collision with built-in Tcl commands is unlikely; the generated XML is
pretty'fied in `vxml` but not in `twiml`; and the `twiml` package includes the
ability to also invoke Twilio REST APIs.

Furthermore, many TwiML tags do not including
nested tags, hence the semantics of the last argument of the corresponding command is
changed to reflect that. In particular, only the `Response`, `Dial` and `Gather`
commands require the last argument to be executable commands to generate the
children elements, whereas all other
commands assume the last argument to be a string for the child text node in XML.

Let us start with a simple XML example.
```XML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Dial action="/handleDialCallStatus" method="GET">
    415-123-4567
  </Dial>
  <Say>Goodbye</Say>
</Response>
```

First, include the necessary package.
```
package require twiml
```
Then use the similar Tcl command hierarchy as the nested XML structure.
```Tcl
Response {
  Dial action=/handleDialCallStatus method=GET {
    puts 415-123-4567
  }
  Say Goodbye
}
```
In comparision, the corresponding Python script is as follows.
```Python
from twilio.twiml.voice_response import Dial, VoiceResponse, Say

response = VoiceResponse()
response.dial('415-123-4567', action='/handleDialCallStatus', method='GET')
response.say('Goodbye')

print(response)
```

Another example follows.
```XML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Gather input="speech dtmf" timeout="3" numDigits="1">
        <Say>Please press 1 or say sales for sales.</Say>
    </Gather>
</Response>
```
And the corresponding Tcl script as follows.
```Tcl
Response {
  Gather input=speech\ dtmf timeout=3 numDigits=1 {
    Say "Please press 1 or say sales for sales."
  }
}
```
Note that the space in the attribute value needs to be escaped.
Alternatively, you could use quoted value, or use curly braces around the
entire first argument.

The corresponding Python code follows:
```Python
response = VoiceResponse()
gather = Gather(input='speech dtmf', timeout=3, num_digits=1)
gather.say('Please press 1 or say sales for sales.')
response.append(gather)

print(response)
```

Compared to VoiceXML, a TwiML script is usually smaller, because TwiML lacks many control
structures and telephony control commands available in VoiceXML. Instead, TwiML
relies on the server side script to perform those functions.

Suppose the first TwiML to the caller is as follows.
```XML
<Response>
  <Say>Hello there!</Say>
  <Gather method="GET" action="?state=one">
    <Say>Please press 1 for sales or 2 for support.</Say>
  </Gather>
</Response>    
```
Once the user enters a digit, say 1, suppose the second TwiML is as follows.
```XML
<Response>
  <Say>Let me connect you to a sales person</Say>
  <Dial timeout="10" record="true">
    <Number>+14151234567</Number>
  </Dial>
</Response>
```
And similarly, a different TwiML if the user enters 2.

To implement this logic in the same Tcl script, running as CGI script,
first import the necessary libraries. 
```Tcl
lappend auto_path .
package require twiml
```
You can use the `cgi.tcl` library for help in writing CGI Tcl scripts.
Its `cgi_input` command captures the supplied CGI input, e.g., `?state=...`.
Its `cgi_import` command exposes the captured input as a Tcl variable.
Note that TwiML receives the `Digits` input when the user enters some digits on
telephone keypad.
```Tcl
package require cgi
cgi_input
if [catch {cgi_import state}] { set state {}}
if [catch {import Digits}] { set Digits {}}
```
Based on the supplied input, you can now call the `twiml` commands
as appropriate. The following example illustrtates.
```Tcl
Response {
    if {$state == ""} {
		Say "Hello there!"
		Gather method=GET action=?state=one {
			Say "Please press 1 for sales or 2 for support."
		}
    } else {
		if {$Digits == 1} {
			Say "Let me connect you to a sales person"
			Dial timeout=10 record=true {
				Number "+14151234567"
			}
		} else {
			Say "Let me connect you to customer support"
			Dial timeout=10 record=true {
				Number "+14151234000"
			}
		}
	}
}
```

Note that you may move the `Response` command inside the `if` and `else`
blocks, to keep them closer to the nested `twiml` commands.

Both the `vxml` and `twiml` packages allow error handling in the script.
Thus if your script has some errors, the top-level `voicexml` or `Response`
commands will capture the error, throw away any partial XML generated so far,
and then generate only a simple XML to speak out the error. This keeps the
generated XML valid, instead of breaking the user dialog abruptly. You can
modify the included packages to send an email or log the error too.

The `twiml` package additionally includes an optional `TwiML` command to
wrap the error handling code. Thus, if you wish to move the `Response` command
closer to the nested commands, and still be able to handle script errors,
you can wrap all the relevant code inside `TwiML` as follows.
```Tcl
TwiML {
  if {$state == ""} {
    Response {
      ...
    }
  } else {
    ...
  }
}
```

Check out other `twiml` examples in the repository.

### Twilio REST API

The `twiml` package also includes necessary code to use Twilio REST APIs. The `Client`
namespace is used to encapsulate the code for this.

Consider the following `curl` command to a text message.
```Shell
curl -X POST https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages \
   --data-urlencode "Body=What's up?" \
   --data-urlencode "From=+14151234567" \
   --data-urlencode "To=+12121234567" \
   -u ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:your_auth_token
```
The corresponding Python code using the Twilio's Python SDK is as follows.
```Python
from twilio.rest import Client
client = Client('ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'your_auth_token')
client.messages.create(body="What's up?", from_='+14151234567', to='+12121234567')
```
The corresponding Tcl code using our `twiml` package is as follows.
```Tcl
package require twiml
set client [Client::create "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "your_auth_token"]
$client POST Messages Body "Hello There" From "+14151234567" To "+12121234567"
```
Note the differences between the raw `curl` API and the Python or Tcl code. The
path and parameter names of the `curl` command transparently map to the corresponding
Tcl code elements, but only after some changes to the Python code element, e.g.,
`From` becomes `from_`.

The `client` object encapsulates the account and token information, and exposes GET, POST,
PUT and DELETE
methods. These methods take the relative URL path and a list of name-values for the parameters
in the request body. On the other hand, any URL parameters must be supplied as part of the
URL path.
These methods return the received XML response as a DOM node. The `twiml` package includes
Xpath style element and attribute extraction from the XML node, as shown in the following example.

Following is another example.
```Shell
curl -X GET 'https://.../Calls.json?StartTimeAfter=2009-07-06T00%3A00%3A00Z&Status=completed' \
  -u ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:your_auth_token
```
The response is in the following format.
```XML
<TwilioResponse>
  <Calls start="0" end="49" pagesize="50" ...>
    <Call>
      <Sid>...</Sid>
      ...
    </Call>
    <Call>
      ...
    </Call>
    ...
  </Calls>
</TwilioResponse>
```
The corresponding Python code is as follows:
```Python
from datetime import datetime
from twilio.rest import Client
client = Client('ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'your_auth_token')
calls = client.calls.list(start_time_after=datetime(2009, 7, 6, 0, 0), status='completed')
for record in calls:
    print(record.sid)
```
And the corresponding Tcl code is shown below. Note the Xpath style XML attribute and element
extraction from the response. You can again see that this matches closely
with the `curl` example, compared to the Python code.
```Tcl
set client [Client::create "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "your_auth_token"]
set calls [$client GET Calls?StartTimeAfter=2009-07-06T00%3A00%3A00Z&Status=completed]
puts "\[[$calls set /TwilioResponse/Calls/@start]-[$calls set /TwilioResponse/Calls/@end]\] \
     [$calls set /TwilioResponse/Calls/Call/Sid]"
$client delete
```

In case of any error in the API response, the `client`'s method throws an exception.
For example, the following may return error, if call ID is not valid.
```Shell
curl -X GET 'https://.../Calls/CAXXXXXX' -u '...'
```
```XML
<TwilioResponse>
  <RestException>
    <Message>The requested resource... was not found</Message>
    ...
  </RestException>
</TwilioResponse>
```

The corresponding Tcl code fragment to capture and print the error message is
shown below.
```Tcl
if {[catch {$client GET Calls/CAXXXXX} errMsg]} {
    puts $errMsg
}
```


### Closing words

The Tcl code for the `twiml` and `vxml` packages are pretty small, about 100-200 lines
each. Tcl allows defining a catch-all command that is triggered if that named
command is not already defined in the code. This feature is used to dynamically
intercept an undefined command, and if it matches a desired XML tag name, then
print out the corresponding XML code. All the attribute arguments of the command are captured
to form the XML tag's attributes. The last argument, if not in attribute form,
can optionally be interpreted to print the XML tag's child elements, recursively.

A wrapper command such as `TwiML` or `voicexml` is defined explicitly to capture the
generated XML in a buffer, by replacing the built-in `puts` command with a custom one
that writes to the buffer. This allows capturing the error, and generating a
sane XML that indicates the error, instead of terminating the script abruptly.

The above mentioned concepts can be seen in the `twiml.tcl` and `vxml.tcl` files
available in the included packages. Most of that code can be reused in your own
XML-based document library written in Tcl.

### Resources
 1. What is Tcl? https://en.wikipedia.org/wiki/Tcl
 2. Learn Tcl https://learnxinyminutes.com/docs/tcl/
 3. Writing CGI in Tcl http://expect.sourceforge.net/cgi.tcl/ref.txt
 4. Motivation and description http://blog.kundansingh.com/2018/06/scripting-voicexml-and-twiml-using-tcl.html

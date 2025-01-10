# tkhtml

<!-- IMAGETABLE imagedir:./images columns:3 -->

----

## Name

<div class="alert alert-info">
	tkhtml - Widget to render html documents.
</div>


## Synopsis

html pathName ?options?

Standard Options

	-exportselection
	-height
	-width
	-xscrollcommand   
	-xscrollincrement
	-yscrollcommand   
	-yscrollincrement

## Widget-Specific Options

*	**Command-Line Name:** -defaultstyle
*	**Database Name:** defaultstyle
*	**Database Class:** Defaultstyle

	This option is used to set the default style-sheet for the widget. The option value should be the 
entire text of the default style-sheet, or an empty string, in which case a built-in default 
stylesheet (for HTML) is used.

	TODO: Describe the role of the default stylesheet.

+	**Command-Line Name:** -imagecmd
+	**Database Name:** imagecmd
+	**Database Class:** Imagecmd

	Specify a Tcl command to be run when an image URI is encountered by the widget. The URI is 
appended to the value of this option and the resulting list evaluated. The value returned should 
be the name of a Tk image, or an empty string if an error occurs.

	See section "IMAGE LOADING" for more detail.

+	**Command-Line Name:** -logcmd
+	**Database Name:** logcmd
+	**Database Class:** Logcmd

	This option is only used for internally debugging the widget.

## Description

The **[html]** command creates a new window (given by the pathName argument) and makes it into an 
html widget. The html command returns its pathName argument. At the time this command is invoked, 
there must not exist a window named pathName, but pathName's parent must exist.

## Widget Command

The `[html]` command creates a new Tcl command whose name is pathName. This command may be used to 
invoke various operations on the widget as follows:

+	**pathName cget option**

	Returns the current value of the configuration option given by option. Option may have any of the 
values accepted by the `[html]` command.

+	**pathName configure option value**

	Query or modify the configuration options of the widget. If no option is specified, returns a 
list describing all of the available options for pathName (see Tk_ConfigureInfo for information 
on the format of this list). If option is specified with no value, then the command returns a 
list describing the one named option (this list will be identical to the corresponding sublist of 
the value returned if no option is specified). If one or more option-value pairs are specified, 
then the command modifies the given widget option(s) to have the given value(s); in this case the 
command returns an empty string. Option may have any of the values accepted by the `[html]` command.

+	**pathName handler type tag script**

	This command is used to define "handler" scripts - Tcl callback scripts that are invoked by the 
widget when document elements of specified types are encountered. The widget supports two types 
of handler scripts: "node" and "script". The type parameter to this command must take one of 
these two values.

	For a "node" handler script, whenever a document element having the specified tag type (e.g. "p" 
or "link") is encountered during parsing, then the node handle for the node is appended to script 
and the resulting list evaluated as a Tcl command. See the section "NODE COMMAND" for details of 
how a node handle may be used to query and manipulate a document node.

	If the handler script is a "script" handler, whenever a document node of type tag is parsed, then 
the text that appears between the start and end tags of the node is appended to script and the 
resulting list evaluated as a Tcl command.

	Handler callbacks are always made from within `[pathName parse]` commands. The callback for a given 
node is made as soon as the node is completely parsed. This can happen because an implicit or 
explicit closing tag is parsed, or because there is no more document data and the -final switch 
was passed to the `[pathName parse]` command.

+	**pathName image**

	This command returns the name of a new Tk image containing the rendered document. Where Tk 
widgets would be mapped in a live display, the image contains blank space.

	The returned image should be deleted when the script has finished with it, for example:

	```
	set img [.html image]
	# ... Use $img ...
	image delete $img
	```

	This command is included mainly for automated testing and should be used with care, as large 
documents can result in very large images that take a long time to create and use vast amounts of 
memory.


+	**pathName node ? ?-index? x y?**

	This command is used to retrieve a handle for a document node that is part of the currently 
parsed document. If the x and y parameters are omitted, then the handle returned is the root-node 
of the document, or an empty string if the document has no root-node (i.e. an empty document).

	If the x and y arguments are present, then the handle returned is for the node which generated 
the document content currently located at viewport coordinates (x, y). If no content is located 
at the specified coordinates or the widget window is not mapped, then an empty string is returned.

	If both the -index option is also specified, then instead of a node handle, a list of two 
elements is returned. The first element of the list is the node-handle. The second element is -1 
if the returned node is not a text node (would return other than an empty string for
`[nodeHandle tag]`). If the node is a text node, then the value returned is an index into the text obtainable 
by `[nodeHandle text]` for the character at coordinates (x, y). The index may be used with the 
`[pathName select]` commands.

	The document node can be queried and manipulated using the interface described in the "NODE 
COMMAND" section.


+	**pathName parse ?-final? html-text**

	Append extra text to the end of the (possibly empty) document currently stored by the widget.

	If the -final option is present, this indicates that the supplied text is the last of the 
document. Any subsequent call to `[pathName parse]` before a call to `[pathName reset]` will raise an 
error.


+	**pathName reset**


	This is used to clear the internal contents of the widget prior to parsing a new document. The 
widget is reset such that the document tree is empty (as if no calls to `[pathName parse]` had ever 
been made) and no stylesheets except the default stylesheet are loaded (as if no invocations of 
`[pathName style]` had occured).

+	**pathName select clear**
+	**pathName select from ?nodeHandle ?index? ?**
+	**pathName select to ?nodeHandle ?index? ?**

	The `[pathName select]` commands are used to query and manipulate the widget selection. If the 
widget -exportselection option is set to true, then these commands may also manipulate the 
X11-selection.

	TODO: Describe these commands.


+	**pathName style ?options? stylesheet-text**

	Add a stylesheet to the widgets internal configuration. The stylesheet-text argument should 
contain the text of a complete stylesheet. Incremental parsing of stylesheets is not supported, 
although of course multiple stylesheets may be added to a single widget.


	The following options are supported:

	```
	Option                   Default Value
	--------------------------------------
	-id <stylesheet-id>      "author"
	-importcmd <script>      ""
	-urlcmd    <script>      ""
	```


	The value of the -id option determines the priority taken by the style-sheet when assigning 
property values to document nodes (see chapter 6 of the CSS specification for more detail on this 
process). The first part of the style-sheet id must be one of the strings "agent", "user" or 
"author". Following this, a style-sheet id may contain any text.

	When comparing two style-ids to determine which stylesheet takes priority, the widget uses the 
following approach: If the initial strings of the two style-id values are not identical, then 
"user" takes precedence over "author", and "author" takes precedence over "agent". Otherwise, the 
lexographically largest style-id value takes precedence. For more detail on why this seemingly 
odd approach is taken, please refer to the "STYLESHEET LOADING" below.

	The -importcmd option is used to provide a handler script for @import directives encountered 
within the stylesheet text. Each time an @import directive is encountered, if the -importcmd 
option is set to other than an empty string, the URI to be imported is appended to the option 
value and the resulting list evaluated as a Tcl script. The return value of the script is 
ignored. If the script raises an error, then it is propagated up the call-chain to the
`[pathName style]` caller.

	The -urlcmd option is used to supply a script to translate "url(...)" CSS attribute values. If 
this option is not set to "", each time a url() value is encountered the URI is appended to the 
value of -urlcmd and the resulting script evaluated. The return value is stored as the URL in the 
parsed stylesheet.


+	**pathName xview ?options?**

	This command is used to query or adjust the horizontal position of the viewport relative to the 
document layout. It is identical to the `[pathName xview]` command implemented by the canvas and 
text widgets.


+	**pathName yview ?options?**

	This command is used to query or adjust the vertical position of the viewport relative to the 
document layout. It is identical to the `[pathName yview]` command implemented by the canvas and 
text widgets.


## Node Command

There are several interfaces by which a script can obtain a "node handle". Each node handle is a Tcl 
command that may be used to access the document node that it represents. A node handle is valid from 
the time it is obtained until the next call to `[pathName reset]`. The node handle may be used to query 
and manipulate the document node via the following subcommands:

+	**nodeHandle attr ?attribute?**

	If the attribute argument is present, then return the value of the named html attribute, or an 
empty string if the attribute specified does not exist. If it is not present, return a key-value 
list of the defined attributes of the form that can be passed to `[array set]`.

	```
	# Html code for node
	<p class="normal" id="second" style="color : red">

	# Value returned by [nodeHandle attr]
	{class normal id second style {color : red}}

	# Value returned by [nodeHandle attr class]
	normal

	```

+	**nodeHandle child index**

	Return the node handle for the index'th child of the node. Children are numbered from zero upward.

+	**nodeHandle nChild**

	Return the number of children the node has.

+	**nodeHandle parent**

	Return the node handle for the node's parent. If the node does not have a parent (i.e. it is the 
document root), then return an empty string.

	
+	**nodeHandle replace ? ?options? newValue?**

	This command is used to set and get the name of the replacement object for the node, if any. If 
the newValue 
argument is present, then this command sets the nodes replacement object name and returns the new 
value. If 
newValue is not present, then the current value is returned.

	A nodes replacement object may be set to the name of a Tk image, the name of a Tk window, or an 
empty string. If it is an empty string (the default and usual case), then the node is rendered 
normally. If it is set to the name of a Tk image, then the image is displayed in the widget in 
place of any other node content (for example to implement HTML <img\> tags). If the node 
replacement object is set to the name of a Tk window, then the Tk window is mapped into the 
widget in place of any other content (for example to implement form elements or plugins).

	The following options are supported:

	```

	Option                   Default Value
	--------------------------------------
	-deletecmd    <script>   See below
	-configurecmd <script>   ""

	```

	When a replacement object is no longer being used by the widget (e.g. because the node has been 
deleted or [pathName reset] is invoked), the value of the -deletecmd option is evaluated as Tcl 
script. The default -deletecmd script (used if no explicit -deletecmd option is provided) deletes 
the Tk image or window.

	If it is not set to an empty string (the default) each time the nodes CSS properties are 
recalculated, a serialized array is appended to the value of the -configurecmd option and the 
result evaluated as a Tcl command. The script should update the replacement objects appearance 
where appropriate to reflect the property values. The format of the appended argument is {p1 v1 
p2 v2 ... pN vN} where the pX values are property names (i.e. "background-color") and the vX 
values are property values (i.e. "#CCCCCC"). The CSS properties that currently may be present in 
the array are listed below. More may be added in the future.

	```
	background-color    color
	font                selected

	```

	The value of the "font" property, if present in the serialized array is not set to the value of 
the corresponding CSS property. Instead it is set to the name of a Tk font determined by 
combining the various font-related CSS properties. Unless they are set to "transparent", the two 
color values are guaranteed to parse as Tk colors. The "selected" property is either true or 
false, depending on whether or not the replaced object is part of the selection or not. Whether 
or not an object is part of the selection is governed by previous calls to the `[pathName select]` 
command.

	The -configurecmd callback is always executed at least once between the `[nodeHandle replace]` 
command and when the replaced object is mapped into the widget display.

+	**nodeHandle tag**

	Return the name of the Html tag that generated this document node (i.e. "p" or "link"), or an 
empty string if the node is a text node.

+	**nodeHandle text**

	If the node is a "text" node, return the string contained by the node. If the node is not a 
"text" node, return an empty string.

	TODO: Add the "write" part of the DOM compatible interface to this section.

	
## Replaced Objects

Replaced objects are html document nodes that are replaced by either a Tk image or a Tk window. For 
example <IMG\> or 
<INPUT\> tags. To implement replaced objects in Tkhtml the user supplies the widget with a Tcl script 
to create and 
return the name of the image or window, and the widget maps, manages and eventually destroys the 
image or window.

TODO: Finish this section.

## Image Loading

As well as for replaced objects, images are used in several other contexts in CSS formatted 
documents, for example as list markers or backgrounds. If the -imagecmd option is not set to an empty 
string (the default), then each time an image URI is encountered in the document, it is appended to 
the -imagecmd script and the resulting list evaluated.

The command should return either an empty string, the name of a Tk image, or a list of exactly two 
elements, the name of a Tk image and a script. If the result is an empty string, then no image can be 
displayed. If the result is a Tk image name, then the image is displayed in the widget. When the 
image is no longer required, it is deleted. If the result of the command is a list containing a Tk 
image name and a script, then instead of deleting the image when it is no longer required, the script 
is evaluated.

## Stylesheet Loading

Apart from the default stylesheet that is always loaded (see the description of the -defaultstyle 
option above), a script may configure the widget with extra style information in the form of CSS 
stylesheet documents. Complete stylesheet documents (it is not possible to incrementally parse 
stylesheets as it is HTML document files) are passed to the widget using the `[pathName style]` command.

As well as any stylesheets specified by the application, stylesheets may be included in HTML 
documents by document authors in several ways:

+	Embedded in the document itself, using a <style\> tag. To handle this case an application script 
must register a "script" type handler for <style\> tags using the `[pathName handler]` command. The 
handler command should call `[pathName style]` to configure the widget with the stylesheet text.
+	Linked from the document, using a <link\> tag. To handle this case the application script should 
register a "node" type handler for <link\> tags.
+	Linked from another stylesheet, using the @import directive. To handle this, an application needs 
to configure the widget -importcommand option.

```
# Implementations of application callbacks to load
# stylesheets from the various sources enumerated above.
# ".html" is the name of the applications tkhtml widget.
# The variable $document contains an entire HTML document.
# The pseudo-code <LOAD URI CONTENTS> is used to indicate
# code to load and return the content located at $URI.


proc script_handler {tagcontents} {
    incr ::stylecount
    set id "author.[format %.4d $::stylecount]"
    set handler "import_handler $id"
    .html style -id $id.9999 -importcmd $handler $tagcontents
}


proc link_handler {node} {
    if {[node attr rel] == "stylesheet"} {
        set URI [node attr href]
		set stylesheet [<LOAD URI CONTENTS>]

        incr ::stylecount
        set id "author.[format %.4d $::stylecount]"
        set handler "import_handler $id"
        .html style -id $id.9999 -importcmd $handler $stylesheet
    }
}


proc import_handler {parentid URI} {
    set stylesheet [<LOAD URI CONTENTS>]

    incr ::stylecount
    set id "$parentid.[format %.4d $::stylecount]"
    set handler "import_handler $id"
    .html style -id $id.9999 -importcmd $handler $stylesheet
}


.html handler script style script_handler
.html handler node link link_handler

set ::stylecount 0

.html parse -final $document

```

The complicated part of the example code above is the generation of stylesheet-ids, the values passed 
to the -id option of the `[.html style]` command. Stylesheet-ids are used to determine the precedence 
of each stylesheet passed to the widget, and the role it plays in the CSS cascade algorithm used to 
assign properties to document nodes. The first part of each stylesheet-id, which must be either 
"user", "author" or "agent", determines the role the stylesheet plays in the cascade algorithm. In 
general, author stylesheets take precedence over user stylesheets which take precedence over agent 
stylesheets. An author stylesheet is one supplied or linked by the author of the document. A user 
stylesheet is supplied by the user of the viewing application, possibly by configuring a preferences 
dialog or similar. An agent stylesheet is supplied by the viewing application, for example the 
default stylesheet configured using the -defaultstyle option.

The stylesheet id mechanism is designed so that the cascade can be correctly implemented even when 
the various stylesheets are passed to the widget asynchronously and out of order (as may be the case 
if they are being downloaded from a network server or servers).

```
#
# Contents of HTML document
#

<html><head>
    <link rel="stylesheet" href="A.css">
    <style>
        @import uri("B.css")
        @import uri("C.css")
        ... rules ...
    </style>
    <link rel="stylesheet" href="D.css">
... remainder of document ...

#
# Contents of B.css
#



@import "E.css"
... rules ...

```


In the example above, the stylesheet documents A.css, B.css, C.css, D.css, E.css and the stylesheet 
embedded in the <style\> tag are all author stylesheets. CSS states that the relative precedences of 
the stylesheets in this case is governed by the following rules:

+	Linked, embedded or imported stylesheets take precedence over stylesheets linked, embedded or 
imported earlier in the same document or stylesheet.
+	Rules specified in a stylesheet take precedence over rules specified in imported stylesheets.

Applying the above two rules to the example documents indicates that the order of the stylesheets 
from least to most important is: A.css, E.css, B.css, C.css, embedded <stylesheet\>, D.css. For the 
widget to implement the cascade correctly, the stylesheet-ids passed to the six `[pathName style]` 
commands must sort lexigraphically in the same order as the stylesheet precedence determined by the 
above two rules. The example code above shows one approach to this. Using the example code, 
stylesheets would be associated with stylesheet-ids as follows:

```
Stylesheet         Stylesheet-id
-------------------------------
A.css              author.0001.9999
<embedded style>   author.0002.9999
B.css              author.0002.0003.9999
E.css              author.0002.0003.0004.9999
C.css              author.0002.0005.9999
D.css              author.0006.9999
```

Entries are specified in the above table in the order in which the calls to `[html style]` would be 
made. Of course, the example code fails if 10000 or more individual stylesheet documents are loaded. 
More inventive solutions that avoid this kind of limitation are possible.

Other factors, namely rule specificity and the !IMPORTANT directive are involved in determining the 
precedence of individual stylesheet rules. These are completely encapsulated by the widget, so are 
not described here. For complete details of the CSS cascade algorithm, refer to [1].

## Incremental Document Loading

This section discusses the widget API in the context of loading a document incrementally, for example 
from a network server. We assume both remote stylesheets and image files are retrieved as well as the 
document.

Before a new document (html file) is loaded, any previous document should be purged from memory using 
the `[pathName reset]` command. The portion of the new document that is read is passed to the widget 
using the `[pathName parse]` command. As new chunks of the document are downloaded, they should also be 
passed to `[pathName parse]`. When the final chunk of the document file is passed to the
`[pathName parse]` command the -final option should be specified. This ensures node-handler callbacks (see the 
description of the `[pathName handler]` command above) are made for tags that are closed implicitly by 
the end of the document.

The widget display is updated in an idle callback scheduled after each invocation of the
`[pathName parse]` command.

## HTML Specific Processing

TODO: Detail implicit opening and closing tag rules here.

## References

[1] CSS2 specification.



### tkhtml (n) - Table Of Contents

Name
Synopsis
Standard Options
Widget-Specific Options
Description
Widget Command
Node Command
Replaced Objects
Image Loading
Stylesheet Loading
Incremental Document Loading
HTML Specific Processing
References
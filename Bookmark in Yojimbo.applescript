(*
	Bookmark in Yojimbo 1.2 by Jim DeVona
	http://anoved.net/bookmark_in_yojimbo.html
	http://anoved.net/2007/01/bookmark-in-yojimbo-11.html
	http://anoved.net/2007/05/bookmark-in-yojimbo-12.html
	1.0: 18 November 2006 (original version)
	1.1: 31 January 2007 (updated for Yojimbo 1.4 compatibility)
	1.2: 20 February 2007 (added redundant address check and tagging hack)
		 11 May 2007 (removed problematic tagging hack, wrote Firefox version)
	
	Bookmark the current Safari or Firefox page in Yojimbo. A simple dialog allows you
	to set the bookmark name, which defaults to the page title. In addition to simply
	filing the bookmark you can also "Bookmark & Edit," which displays the bookmark
	item window so that you can set additional properties such as tags or comments.
		
	Requirements:
		Version 1.2 tested with Yojimbo 1.4.2 (46) and Safari 2.0.4/Firefox 2.0.0.3
		on Mac OS X 10.4.9. Your mileage may vary with other configurations.
		
	Suggested installation location:
		~/Library/Scripts/Applications/Safari/ or
		~/Library/Scripts/Applications/Firefox/
	
	You can invoke this script with the standard Mac OS X Script Menu
	or you could use any one of many excellent third party utilities
	to invoke it with a keyboard shortcut - even to intercept your
	browser's default bookmark keyboard shortcut, such as Command-D.
	(I have tested it with both FastScripts and Keyboard Maestro.)
	
	Tools Cited:
		http://www.barebones.com/products/yojimbo/
		http://www.apple.com/applescript/scriptmenu/
		http://www.red-sweater.com/fastscripts/
		http://www.keyboardmaestro.com/main/
*)

-- tell application "Firefox"
tell application "Safari"
	
	-- identify the page to bookmark, if any	
	try
		set _page_url to the URL of document 1
		set _page_title to the name of document 1
		--set _page_url to «class curl» of window 1
		--set _page_title to «class pTit» of window 1
	on error
		return
	end try
	
	-- check for other bookmark items with identical locations
	-- this has the effect of requiring Yojimbo to open/be open before any interface appears to the user -
	-- used to be they could name the bookmark immediately, then go about their business as Yojimbo started (if necessary) and filed thigns away
	-- now Yojimbo has to start up first before anythign else to check whether the location already exists.
	tell application "Yojimbo" to set _conflicts to every bookmark item whose location is _page_url
	if _conflicts is not {} then
		set _dlog to display alert "A bookmark with this location already exists. Would you rather edit the existing bookmark?" message _page_url buttons {"Cancel", "No", "Yes"} default button 3 cancel button 1 as warning
		set _action to the button returned of _dlog
		if _action = "" or _action = "Cancel" then
			return
		else if _action = "Yes" then
			tell application "Yojimbo"
				activate
				repeat with _conflict in _conflicts
					open location "x-yojimbo-item://" & (get id of _conflict)
				end repeat
			end tell
			return
		end if
		-- if "No" to edit existing bookmark, proceed to create a new one anyway...
	end if
	
	-- ask the user to choose what to do and to approve the bookmark title
	set {text returned:_page_title, button returned:_action} to display dialog "Bookmark \"" & _page_url & "\" as:" default answer _page_title with title "Bookmark in Yojimbo" buttons {"Cancel", "Bookmark & Edit", "Bookmark"} default button 3 cancel button 1
	if _action = "" or _action = "Cancel" then
		return
	else if _action = "Bookmark" then
		set _reveal to false
	else
		set _reveal to true
	end if
	
end tell

tell application "Yojimbo"
	
	-- create the new bookmark
	set _db_item to make new bookmark item with properties {name:_page_title, location:_page_url}
	
	-- reveal item by opening it as a URI
	if _reveal then
		activate
		open location "x-yojimbo-item://" & (get id of _db_item)
	end if
	
end tell

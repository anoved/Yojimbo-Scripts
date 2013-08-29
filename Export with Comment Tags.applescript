(*
	Export with Comment Tags 1.1 by Jim DeVona
	http://anoved.net/2007/08/yojimbo-export-with-comment-tags.html
	Export Yojimbo items with tags as Spotlight comments:
	http://www.listsearch.com/Yojimbo/Message/index.lasso?3875
	1.0 2007/08/30: Initial
	1.1 2007/08/31: Better selection recognition
	1.2 2008/07/08: Fixed for compatibility with Leopard Finder
		and added comma to export delimiter, both thanks to Jim Correia.
		http://groups.google.com/group/yojimbo-talk/browse_thread/thread/6b2abe2884f91cbc
*)

property _delimiter : ", "

tell application "Yojimbo"
	
	set _items to selected items of browser window 1
	if _items is missing value then return
	set _itemc to count of (_items as list)
	activate
	
	-- select a destination and export items
	if _itemc is 1 then
		set _dst to choose file name with prompt "Export selected item as:" default name (get name of item 1 of _items)
	else
		set _dst to choose folder with prompt "Export selected items to:"
	end if
	set _files to export _items to _dst
	
	-- fess up when we don't know what to do
	set _filec to count of (_files as list)
	if _filec is not equal to _itemc then
		display alert "Export with Comment Tags error:" message "The number of exported files (" & _filec & ") does not match the number of selected items (" & _itemc & "). Comment tags cannot be applied." as critical
		return
	end if
	
	-- apply any tags from each item to each corresponding file
	set _tid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {_delimiter}
	repeat with _i from 1 to _itemc
		set _tags to name of tags of item _i of _items
		if (count of _tags) is greater than 0 then
			set _comments to _tags as string
			set _file to item _i of (_files as list)
			tell application "Finder" to set comment of (_file as alias) to _comments
		end if
	end repeat
	set AppleScript's text item delimiters to _tid
	
end tell
-- Yojimbo Tag List 1.1
-- 5 February 2007
-- Jim DeVona
-- http://anoved.net/2007/02/yojimbo-tag-list/

-- get list of known tags
set _tags to {}
tell application "Yojimbo"
	repeat with _tag in tags
		set end of _tags to name of _tag
	end repeat
end tell

-- show list to user
set _choice to choose from list _tags with title "Yojimbo Tags" with prompt "Select tags:" with multiple selections allowed without empty selection allowed
if _choice is equal to false then return

-- concatenate and copy chosen tags
set _dtid to text item delimiters
set text item delimiters to {","}
set the clipboard to ("" & _choice)
set text item delimiters to _dtid
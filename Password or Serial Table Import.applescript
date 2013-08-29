-- Example script to import passwords or serial numbers from tab delimited files into Yojimbo
-- See comments below for exported table format
-- Jim DeVona 8 March 2007

set _type to button returned of (display alert "Select what kind of data to import to Yojimbo:" buttons {"Cancel", "Serial Numbers", "Passwords"} cancel button 1)
if _type is "Cancel" or _type is "" then
	return
end if

-- read the file
set _file to choose file with prompt "Select a tab delimited file containing " & _type
open for access _file
set _data to read _file using delimiter {(ASCII character 13), (ASCII character 10)}
close access _file

-- import each line as a tab delimited record
-- per http://www.blankreb.com/studiosnips.php?ID=17
set _delim to AppleScript's text item delimiters
set AppleScript's text item delimiters to tab -- or {","}
repeat with _index from 1 to count of _data
	try
		set _line to the text items of item _index of _data
		if _type is "Passwords" then
			-- items are name, location, account, and password
			MakePassword(item 1 of _line, item 2 of _line, item 3 of _line, item 4 of _line)
		else if _type is "Serial Numbers" then
			-- items are product, owner, serial number, and comments
			MakeSerial(item 1 of _line, item 2 of _line, item 3 of _line, item 4 of _line)
		end if
	end try
end repeat
set AppleScript's text item delimiters to _delim

on MakePassword(_name, _location, _account, _password)
	tell application "Yojimbo"
		set _new to make new password item with properties {name:_name, location:_location, account:_account, password:_password}
	end tell
end MakePassword

on MakeSerial(_product, _owner, _number, _comments)
	tell application "Yojimbo"
		set _new to make new serial number item with properties {name:_product, owner name:_owner, serial number:_number, comments:_comments}
	end tell
end MakeSerial
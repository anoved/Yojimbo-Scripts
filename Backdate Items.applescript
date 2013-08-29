(*
	Backdate Yojimbo Items 1.2
	By Jim DeVona
	7 May 2007
	http://anoved.net/2007/05/backdate-yojimbo-items/
	
	This AppleScript allows you to alter the creation and modification dates
	of selected Yojimbo database items. It is intended to restore timestamps
	lost during import. The script uses the sqlite3 program distributed with
	Mac OS X to modify Yojimbo's database directly. This is naughty.
	
	Usage:
		
		1. Select one or more Yojimbo items.
		2. Invoke this script.
		3. Enter the desired date and time.
		4. Click "Creation" or "Creation & Modification" to reset the indicated timestamps.
		5. Changes are not visible until you restart Yojimbo. Modifying the items in
		   Yojimbo before you restart the program will abandon your timestamp changes.
	
	Warning:
	
		THIS SCRIPT IS A HACK.
		I AM NOT RESPONSIBLE FOR ANYTHING IT DOES OR FOR YOUR CHOICE TO USE IT.
		
		Specifically, this script modifies Yojimbo's database file. The format of this
		database is undocumented and fiddling with it is definitely unsupported. There is
		absolutely no guarantee that the database format will not change in the future
		or that this script will not corrupt it.
		
		Apple's Core Data overview notes that "While it is easy enough to look under the
		covers and see what is going on with the XML and SQLite data formats, you should
		never modify the data in these files yourself." That is what this script does.
		http://developer.apple.com/macosx/coredata.html
		
		If you do choose to run this script, please first make a backup of your Yojimbo
		database file. It works for me, but don't take any chances with your data.
	
	Changes:
	
		1.1: Added better error checking for format of timestamp string.
		1.2: Better selection recognition (31 August 2007)
*)

-- Origin date for Yojimbo's NSDate timestamps.
property _nsepoch : date "Monday, January 1, 2001 12:00:00 AM"

-- Location of the Yojimbo database.
property _dbpath : POSIX path of (path to home folder) & "Library/Application Support/Yojimbo/Database.sqlite"

(*
	ConvertToGMT
	parseDumpedDate
	
	These handlers were developed at http://bbs.applescript.net/viewtopic.php?id=21109
	from the example at http://bbs.applescript.net/viewtopic.php?id=20773. ConvertToGMT
	returns the GMT equivalent of a local timestamp, accounting for daylight savings, if
	appropriate, at the time of the timestamp.
*)
on parseDumpedDate(dateString)
	set a to date (text (word 4) thru (word -3) of dateString)
	set day of a to word 3 of dateString
	set month of a to ((offset of (word 2 of dateString) in "JanFebMarAprMayJunJulAugSepOctNovDec") + 2) div 3
	set year of a to word -2 of dateString
	return a
end parseDumpedDate
on ConvertToGMT(_inputDate)
	
	try
		-- Get a list of significant DST dates in _localDate's year.
		set _dstData to run script ("{" & text 1 thru -3 of Â
			(do shell script "/usr/sbin/zdump -v /etc/localtime | sed -E -e '/" & year of _inputDate & "/!d' -e 's|^[^ ]+ *|{_utcDate:\"|g' -e 's/ = /\", _localDate:\"/' -e 's/ isdst=1/\", _isDST:true},Â/' -e 's/ isdst=0/\", _isDST:false},Â/'") Â
				& "}")
	on error
		-- Use plain GMT offset if no local DST data is available.
		return _inputDate - (time to GMT)
	end try
	
	-- Initialize defaults.
	set _dstOffset to time to GMT
	set _stdOffset to time to GMT
	set _dstLocal to (current date)
	set _stdLocal to _dstLocal
	
	-- Inspect each DST data point.
	set _prevData to null
	repeat with _data in _dstData
		
		-- Any transition between DST and standard time is of interest.
		if (_prevData is not null and _prevData's _isDST is not _data's _isDST) then
			
			-- Convert the last data point's dates into AppleScript date objects.
			set _dataLocal to parseDumpedDate(_prevData's _localDate)
			set _dataUTC to parseDumpedDate(_prevData's _utcDate)
			
			-- Record the seasonal offset to GMT and the season endpoints.
			if (_data's _isDST) then
				-- We have entered DST; the dates are the last standard times.
				set _stdOffset to (_dataLocal - _dataUTC)
				set _dstLocal to _dataLocal
			else
				-- We have entered standard time; the dates are the last DST times.
				set _dstOffset to (_dataLocal - _dataUTC)
				set _stdLocal to _dataLocal
			end if
			
		end if
		
		set _prevData to _data
		
	end repeat
	
	-- Determine which GMT offset to use based on the sequence of _inputDate and the DST dates.
	if _dstLocal is less than _stdLocal then
		-- DST in middle of year (northern hemisphere)
		if (_inputDate is less than or equal to _dstLocal) or (_inputDate is greater than _stdLocal) then
			return _inputDate - _stdOffset
		else
			return _inputDate - _dstOffset
		end if
	else if _stdLocal is less than _dstLocal then
		-- Standard time in middle of year (southern hemisphere)
		if (_inputDate is less than or equal to _stdLocal) or (_inputDate is greater than _dstLocal) then
			return _inputDate - _dstOffset
		else
			return _inputDate - _stdOffset
		end if
	end if
	
	-- default return only if _dstLocal equals _stdLocal (only if no or incomplete _dstData)
	return _inputDate - (time to GMT)
	
end ConvertToGMT

(*** on run ***)
tell application "Yojimbo"
	
	-- Get the selected items.
	set _items to get selected items of browser window 1
	if _items is missing value then return
	
	-- Input the desired date and time.
	set {text returned:_datestr, button returned:_choice} to display dialog "Reset date and time of selected items to:" default answer ((current date) as string) with title "Backdate Items" buttons {"Cancel", "Creation", "Creation & Modification"} default button 3 cancel button 1
	
	-- Reset which timestamps?
	set _resetboth to true
	if _choice is "Creation" then
		set _resetboth to false
	end if
	
	-- Convert input timestamp text to seconds since epoch.
	tell me
		try
			set _parsedDate to date _datestr
		on error _errMsg
			-- If the input text can't be converted to a date, tell the user where to find how to format the date
			tell application "Yojimbo" to display alert _errMsg message "For supported timestamp formats, see:" & return & "http://developer.apple.com/documentation/AppleScript/Conceptual/AppleScriptLangGuide/AppleScript.2d.html#pgfId=3549" as critical
			return
		end try
		-- (date _datestr) - (time to GMT) is much simpler but is an hour off depending where date falls
		set _date to ConvertToGMT(_parsedDate)
		set _timestamp to _date - _nsepoch
	end tell
	
	-- Reset the timestamp for each selected items.
	repeat with _item in _items
		
		-- Get this item's identifier.
		set _id to (get id of _item)
		
		-- ZITEM is the item database; ZDATECREATED and ZDATEMODIFIED are the timestamp field names, and ZUUID is the item identifier field name.
		-- Note that it would be straightforward to edit just the modification date, too - but we can only show 3 buttons in the dialog. Eh.
		if _resetboth then
			set _sql to "UPDATE ZITEM SET ZDATECREATED = " & _timestamp & ", ZDATEMODIFIED = " & _timestamp & " WHERE ZUUID = \\\"" & _id & "\\\";"
		else
			set _sql to "UPDATE ZITEM SET ZDATECREATED = " & _timestamp & " WHERE ZUUID = \\\"" & _id & "\\\";"
		end if
		
		-- Execute the SQL command.
		do shell script "/usr/bin/sqlite3 " & quoted form of _dbpath & " \"" & _sql & "\""
		
	end repeat
	
	-- Ideally, cause Yojimbo to reload its database to display the changes.
	-- Poor man's solution: restart Yojimbo.
	
end tell
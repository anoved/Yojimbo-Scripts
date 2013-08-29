(*
	Backdate Import 1.0
	By Jim DeVona
	9 May 2007
	http://anoved.net/2007/05/backdate-yojimbo-import/
	
	This AppleScript allows you automatically backdate items imported into
	Yojimbo with the creation and modification dates of the original file.
	The script uses the sqlite3 program distributed with Mac OS X to modify
	Yojimbo's database directly. This is naughty.
	
	Script Usage:
		
		1. Invoke this script.
		2. Select files to import.
		3. Backdated timestamps are not visible until you restart Yojimbo.
		
	Droplet Usage:
	
		If this script is saved as a droplet application or application bundle:
		
		1. Drag files or folders to import onto the droplet icon.
		2. Backdated timestamps are not visible until you restart Yojimbo.
		
		Double-clicking the droplet is equivalent to invoking the script normally.
		
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
*)

property _nsepoch : date "Monday, January 1, 2001 12:00:00 AM"
property _dbpath : POSIX path of (path to home folder) & "Library/Application Support/Yojimbo/Database.sqlite"

(*
	on run
	
	Prompt user to select files to import. Invoked when the script invoked normally.
*)
on run
	tell application "Yojimbo"
		activate
		-- Simply change "choose file" to "choose folder" if you'd rather select entire folders to import.
		set _files to choose file with prompt "Select files to import:" with multiple selections allowed without invisibles
		tell me to open _files
	end tell
end run

(*
	on open
	
	Import files and backdate the imported items to match the original file timestamps.
	Invoked after selecting files to import in the run handler or when files are dropped
	on the script (if it is saved as an application droplet).
*)
on open (_inFiles)
	
	-- Replace any folders with the files they contain.
	set _files to {}
	repeat with _file in _inFiles
		set _info to info for _file
		if folder of the _info is true then
			set _files to _files & process_folder(_file)
		else if (alias of the _info is false) then
			set the end of _files to _file
		end if
	end repeat
	
	tell application "Yojimbo"
		
		-- Attempt to import the files.
		try
			-- "as list" is required for single items to be handled properly.
			set _items to (import _files) as list
		on error _errorMessage
			display alert "Import error:" message _errorMessage as critical
			return
		end try
		
		-- Backdate each imported item with the original file's timestamps.
		repeat with _index from 1 to count of _items
			tell application "Finder"
				set _created to creation date of (item _index of _files)
				set _modified to modification date of (item _index of _files)
			end tell
			tell me to Backdate(item _index of _items, _created, _modified)
		end repeat
		
	end tell
end open

(*
	process_folder
	
	Droplet helper handler derived from Apple examples.
*)
on process_folder(this_folder)
	set _contents to {}
	set these_items to list folder this_folder without invisibles
	repeat with i from 1 to the count of these_items
		set this_item to alias ((this_folder as text) & (item i of these_items))
		set the item_info to info for this_item
		if folder of the item_info is true then
			set _contents to _contents & process_folder(this_item)
		else if (alias of the item_info is false) then
			set the end of _contents to this_item
		end if
	end repeat
	return _contents
end process_folder

(*
	Backdate
	
	Changes the creation and modification timestamps of the specified item.
	Derived from my Backdate Items script: http://anoved.net/2007/05/backdate-yojimbo-items.html
*)
on Backdate(_item, _createdLocal, _modifiedLocal)
	tell application "Yojimbo"
		
		-- Convert timestamps to seconds since GMT epoch.
		tell me
			set _created to ConvertToGMT(_createdLocal) - _nsepoch
			set _modified to ConvertToGMT(_modifiedLocal) - _nsepoch
		end tell
		
		-- Create and execute the SQL command to apply these timestamps to the item.
		set _id to (get id of _item)
		set _sql to "UPDATE ZITEM SET ZDATECREATED = " & _created & ", ZDATEMODIFIED = " & _modified & " WHERE ZUUID = \\\"" & _id & "\\\";"
		do shell script "/usr/bin/sqlite3 " & quoted form of _dbpath & " \"" & _sql & "\""
		
	end tell
end Backdate

(*
	ConvertToGMT
	parseDumpedDate
	
	These handlers were developed at http://bbs.applescript.net/viewtopic.php?id=21109
	from the example at http://bbs.applescript.net/viewtopic.php?id=20773. ConvertToGMT
	returns the GMT equivalent of a local timestamp, accounting for daylight savings, if
	appropriate, at the time of the timestamp.
*)
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
on parseDumpedDate(dateString)
	set a to date (text (word 4) thru (word -3) of dateString)
	set day of a to word 3 of dateString
	set month of a to ((offset of (word 2 of dateString) in "JanFebMarAprMayJunJulAugSepOctNovDec") + 2) div 3
	set year of a to word -2 of dateString
	return a
end parseDumpedDate

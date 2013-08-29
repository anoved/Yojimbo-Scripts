-- Archive Bookmarks 1.1
-- Jim DeVona 15 July 2007
-- 1.1: Better selection recognition (31 August 2007)
-- http://anoved.net/2007/07/archive-yojimbo-bookmarks/

tell application "Yojimbo"
	
	-- get the selected items, if any
	set _items to selected items of browser window 1
	if _items is missing value then return
	
	-- archive all the selected bookmark items
	repeat with _item in _items
		if class of _item is bookmark item then
			
			-- bookmark properties the archive should inherit
			set _name to name of _item
			set _url to location of _item
			set _tags to tags of _item
			
			-- archive the bookmarked page
			try
				set _archive to make new web archive item with contents _url with properties {name:_name}
				add tags _tags to _archive
			end try
			
		end if
	end repeat
end tell
-- This script converts Yojimbo item comments to tags.
-- To use, first select all the items you'd like to process.
-- (IE, click the "Library" collection and press Command-A to select all.)
-- Then select "Copy Item Link" from the "Edit" menu.
-- Lastly, run this script.

tell application "Yojimbo"
	
	activate
	
	repeat with itemLink in paragraphs of (the clipboard)
		
		-- make sure this really is a yojimbo item link
		if itemLink begins with "x-yojimbo-item://" then
			
			-- strip off the x-yojimbo-item:// and you've got a database item id
			set itemKey to text from character 18 to end of itemLink
			set itemID to database item id itemKey
			
			-- create tags from comments (and clear comments)
			set itemComments to comments of itemID
			set commentWords to words in itemComments
			add tags commentWords to itemID
			set comments of itemID to ""
			
		end if
		
	end repeat
	
end tell

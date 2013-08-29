(*
	To ensure that every item tagged "leoben" is also tagged "cylon",
	I run this script, select "leoben" from the first list of tags
	that appears, and select "cylon" from the second list.
	Both tags must already exist in your library.
	
	http://anoved.net/2008/01/yojimbo-tag-companions/
*)
tell application "Yojimbo"
	
	activate
	set tagNames to (name of every tag)
	
	-- get target tag
	set tagName to (choose from list tagNames with title "Tag Companions" with prompt "Select a tag to accompany:" without multiple selections allowed and empty selection allowed)
	if tagName is false then return
	
	-- get list of tags to add
	set tagsToAdd to (choose from list tagNames with title "Tag Companions" with prompt "Select tags to add to items tagged '" & tagName & "':" with multiple selections allowed without empty selection allowed)
	if tagsToAdd is false then return
	
	-- add the tags
	set theTag to tag (item 1 of tagName)
	add tags tagsToAdd to (every database item whose tags contains theTag)
	
end tell
#!/usr/bin/env perl

# Main bug is it can't read this file - recursive YJNOTEHEREDOC confusion
# http://anoved.net/2009/12/yjnote/

# Needs:
# - Usage/"POD"

use warnings;
use strict;
use Getopt::Long;
use encoding 'utf8';
use utf8;
use Pod::Usage;

my $item_title = '';
my $item_comments = '';
my $item_label = '';
my $item_tags = '';
my $item_flag = 'false';
my $reveal = 0;

#Getopt::Long::Configure('pass_through');
GetOptions (
	"title=s"		=> \$item_title,
	"comments=s"	=> \$item_comments,
	"label=s"		=> \$item_label,
	"tags=s"		=> \$item_tags,
	"flagged"		=> sub {$item_flag = 'true'},
	"reveal"		=> \$reveal,
	"help|?"		=> sub {pod2usage(-verbose => 2);}
	) or pod2usage(2);

# if there are args passed through, slurp them as files, appending
# their contents to content. Otherwise, read from stdin.

my $content = '';
{
	local $/;
	if (@ARGV == 0) {
		$content = <>;
	} else {
		foreach (@ARGV) {
			open FILE, $_ or die "No such file: $_";
			$content .= <FILE>;
			close FILE;
		}
	}
}


$item_title = lame_escape($item_title);
$item_comments = lame_escape($item_comments);
$item_label = lame_escape($item_label);
$item_tags = lame_escape($item_tags);
$content = lame_escape($content);

# Check for valid item label and discard if invalid.
if ($item_label ne '') {
	my $valid = qx( osascript -e 'tell application "Yojimbo" to get label "$item_label" exists' );
	chop $valid;
	if( $valid eq 'false') {
		print STDERR "The label \"". $item_label . "\" will be ignored because it does not exist.\n";
		$item_label = '';
	}
}

# Quote comma delimited tag items.
my $tagstring = join ',', map {'"' . $_ . '"'} split /,/, $item_tags;

# Display the item if requested.
my $revealcode = '';
if ($reveal) {
	$revealcode = "reveal _note\n";
	#\tactivate\n
}

# Run the Yojimbo AppleScript
my $result = qx(osascript <<YJNOTEHEREDOC;
tell application "Yojimbo"
	set _note to make new note item with properties {name:"$item_title",comments:"$item_comments",flagged:$item_flag,label name:"$item_label",contents:"$content"}
	add tags {$tagstring} to _note
	$revealcode
end tell
YJNOTEHEREDOC
);

sub lame_escape {
	my $str = shift;
	$str =~ s/\\/\\\\\\\\/g;
	$str =~ s/"/\\"/g;
	$str =~ s/`/\\`/g;
	$str =~ s/\$/\\\$/g;
	return $str;
}


__END__

=head1 NAME

yjnote - Create Yojimbo notes from the command line.

=head1 SYNOPSIS

  yjnote [options] [FILE...]
 
=head1 DESCRIPTION

B<yjnote> creates a Yojimbo note by concatenating the contents of the given files (or by reading standard input, if no files are given).

=head1 OPTIONS

=over 4

=item B<-title> F<TEXT>

Sets the note item title.

=item B<-comments> F<TEXT>

Sets the note item comments.

=item B<-label> F<TEXT>

Sets the note item label. Ignored if the label does not exist.

=item B<-tags> F<TAG[,TAG,...]>

Sets the note item tags. Separate tags with commas.

=item B<-flagged>

Flags the note item.

=item B<-reveal>

Reveals the newly created note in Yojimbo. By default, the new note is not displayed.

=back

=cut

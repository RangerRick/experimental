#!/usr/bin/perl

$|++;

use lib '/home/ranger/cvs/fink/perlmod';
use lib '/home/ranger/cvs/rangerrick/scripts';

use utf8;
use strict;

use Data::Dumper;
use Digest::MD5;
use File::Basename;
use File::Find;
use IO::Handle;

use vars qw(
	$ID
	$PACKAGES_XML_OUTPUT
	$PACKAGELIST_TXT_OUTPUT
	$HANDLE
	$PACKAGE_FILE
	$TREE
	$TREE_FILES

	$REVISION
	$MAINTAINERS

	$FROM_FILES
	$TO_FILES
	$ALL_FILES
);

($REVISION) = q$Revision: 1134 $ =~ /(\d+)/;

$ID     = 1;
$HANDLE = IO::Handle->new();

$PACKAGES_XML_OUTPUT = IO::Handle->new();
$PACKAGELIST_TXT_OUTPUT = IO::Handle->new();

my $from = shift;
my $to   = shift;

if (not defined $from or not defined $to or not -d $from or not -d $to) {
	die "usage: $0 <from_tree> <to_tree>\n";
}

$from =~ s/^\~/$ENV{HOME}/;
$to   =~ s/^\~/$ENV{HOME}/;

sub find_files {
	return unless (-f $_);
	return unless (/\.(info|patch|diff)$/);
	my $name = $File::Find::name;
	$name =~ s/^${TREE}\/?//;

	open($HANDLE, $File::Find::name) or die "can't open $File::Find::name for reading: $!";
	binmode($HANDLE);
	$$TREE_FILES->{$name} = Digest::MD5->new->addfile($HANDLE)->hexdigest;
	close($HANDLE);
	# print $name, ": ", $TREE_FILES->{$name}, "\n";
	$ALL_FILES->{$name}++;
}

$TREE       = $from;
$TREE_FILES = \$FROM_FILES;
find({ wanted => \&find_files, follow => 1 }, $from );

$TREE       = $to;
$TREE_FILES = \$TO_FILES;
find({ wanted => \&find_files, follow => 1 }, $to );

#print Dumper($ALL_FILES, $FROM_FILES, $TO_FILES);

open ($PACKAGELIST_TXT_OUTPUT, '>/Users/ranger/rcs/scripts/buildfink/packagelist.txt');

new_package_file();

for my $file (sort keys %$ALL_FILES) {
	my @categories = qw(Packages);
	my $sortkey = ucfirst(basename($file));
	my $packagename = undef;

	my $type = "";
	if ($file =~ /\.info$/) {
		$type = 'Info Files';
		push(@categories, 'Info Files');
	} elsif ($file =~ /\.(patch|diff)$/) {
		$type = 'Patch Files';
		push(@categories, 'Patch Files');
	} else {
		$type = 'Unknown Files';
		push(@categories, 'Unknown Files');
	}

	my $maintainer;
	my $text = "";

	if (-r "$to/$file") {
		open($HANDLE, $to . '/' . $file) or die "couldn't read from $to/$file: $!";
		$text .= "== File in Pango/Cairo ==\n<pre><nowiki>";
		while (my $line = <$HANDLE>) {
			$text .= $line;
			if ($file =~ /\.info$/) {
				if ($line =~ /^\s*maintainer\s*:\s*\'?\"?([^\<]+?)\'?\"?\s*</i) {
					if (defined $1 and $1 !~ /^\s*$/) {
						$maintainer = $1;
						if (exists $MAINTAINERS->{lc($maintainer)}) {
							$maintainer = $MAINTAINERS->{lc($maintainer)};
						} else {
							$MAINTAINERS->{lc($maintainer)} = $maintainer;
						}
						push(@categories, "Maintained By $maintainer");
					}
				}
				if (not defined $packagename and $line =~ /^\s*package:\s*(\S+?)\s*$/i) {
					$packagename = $1;
					$packagename =~ s/\%type_pkg\[-altivec\]//;
					$packagename =~ s/\%type_pkg\[-atlas\]/-atlas/;
					$packagename =~ s/\%type_pkg\[bluefish\]/-gnome2/;
					$packagename =~ s/\%type_pkg\[gecko\]//;
					$packagename =~ s/\%type_pkg\[-gtk\]/-gtk/;
					$packagename =~ s/\%type_pkg\[-gtk2\]/-gtk2/;
					$packagename =~ s/\%type_pkg\[-gui\]/-gui/;
					$packagename =~ s/\%type_pkg\[-mpi\]/-mpi/;
					$packagename =~ s/\%type_pkg\[-noprint\]//;
					$packagename =~ s/\%type_pkg\[-nox\]//;
					$packagename =~ s/\%type_pkg\[perl\]/588/;
					$packagename =~ s/\%type_pkg\[postgresql\]/82/;
					$packagename =~ s/\%type_pkg\[python\]/25/;
					$packagename =~ s/\%type_pkg\[ruby\]/18/;
					$packagename =~ s/\%type_pkg\[ssl\]//;
					$packagename =~ s/\%type_pkg\[-svg\]/-svg/;
					$packagename =~ s/\%type_pkg\[uitype\]/-gtk/;
					$packagename =~ s/\%type_pkg\[-x11\]/-x11/;
					$packagename =~ s/\%type_pkg\[-xembed\]//;
				}
			}
		}
		close($HANDLE);
		$text .= "</nowiki></pre>\n";
	}

	if (not exists $TO_FILES->{$file}) {
		print "< $file: exists in $from, but not in $to\n";
		push(@categories, 'Removed In Pangocairo', 'Modified Packages', $type . ' Removed In Pangocairo');
	} elsif (not exists $FROM_FILES->{$file}) {
		print "> $file: exists in $to, but not in $from\n";
		push(@categories, 'Added In Pangocairo', 'Modified Packages', $type . ' Added In Pangocairo');
		print $PACKAGELIST_TXT_OUTPUT $packagename, "\n" if (defined $packagename);
	} elsif ($FROM_FILES->{$file} ne $TO_FILES->{$file}) {
		print "! $file: has changed\n";
		if ($file =~ /\.info$/) {
			my $diff = `diff -Nurd "$from/$file" "$to/$file"`;
			$text .= "== Diff vs. HEAD ==\n<pre><nowiki>$diff</nowiki></pre>\n";
		}
		push(@categories, 'Updated In Pangocairo', 'Modified Packages', $type . ' Updated In Pangocairo');
		print $PACKAGELIST_TXT_OUTPUT $packagename, "\n" if (defined $packagename);
	} else {
		print "  $file\n";
		push(@categories, 'Unchanged In Pangocairo', $type . ' Unchanged In Pangocairo');
	}

	$text .= "\n";
	for my $cat (@categories) {
		if ($cat =~ /\|/) {
			$text .= "[[Category:$cat]]\n";
		} else {
			$text .= "[[Category:$cat|$sortkey]]\n";
		}
	}

	$text = clean_up_text($text);

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	$mon += 1;
	$year += 1900;

	my $timestamp = sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ', $year, $mon, $mday, $hour, $min, $sec);

	$ID++;
	print $PACKAGES_XML_OUTPUT <<END;
  <page>
    <title>$file</title>
    <id>$ID</id>
    <revision>
      <id>$REVISION</id>
      <timestamp>$timestamp</timestamp>
      <contributor>
        <ip>24.225.84.3</ip>
      </contributor>
      <comment>Page: $file</comment>
      <text xml:space="preserve"><![CDATA[$text]]></text>
    </revision>
  </page>
END

}

print $PACKAGES_XML_OUTPUT "</mediawiki>\n";
close($PACKAGES_XML_OUTPUT);
close($PACKAGELIST_TXT_OUTPUT);

sub clean_up_text {
	my $text = shift;
	$text =~ s/[^[:ascii:]]/ /gs;
	$text =~ s/.//gs;
	$text =~ s/\r?\n/XXXCARRIAGERETURNXXX/gs;
	$text =~ s/[[:cntrl:]]/ /gs;
	$text =~ s/XXXCARRIAGERETURNXXX/\n/gs;
	return $text;
}

sub new_package_file() {
	close ($PACKAGES_XML_OUTPUT);

	$PACKAGE_FILE="/Users/ranger/tmp/packages-$ID.xml";
	open ($PACKAGES_XML_OUTPUT, ">$PACKAGE_FILE");
	print $PACKAGES_XML_OUTPUT <<END;
<mediawiki xmlns="http://www.mediawiki.org/xml/export-0.3/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.mediawiki.org/xml/export-0.3/ http://www.mediawiki.org/xml/export-0.3.xsd" version="0.3" xml:lang="en">
  <siteinfo>
    <sitename>PangoCairo</sitename>
    <base>http://ranger.befunk.com/pangocairo/index.php/Main_Page</base>
    <generator>MediaWiki 1.11.1</generator>
    <case>first-letter</case>
      <namespaces>
      <namespace key="-2">Media</namespace>
      <namespace key="-1">Special</namespace>
      <namespace key="0" />
      <namespace key="1">Talk</namespace>
      <namespace key="2">User</namespace>
      <namespace key="3">User talk</namespace>
      <namespace key="4">PangoCairo stats</namespace>
      <namespace key="5">PangoCairo stats talk</namespace>
      <namespace key="6">Image</namespace>
      <namespace key="7">Image talk</namespace>
      <namespace key="8">MediaWiki</namespace>
      <namespace key="9">MediaWiki talk</namespace>
      <namespace key="10">Template</namespace>
      <namespace key="11">Template talk</namespace>
      <namespace key="12">Help</namespace>
      <namespace key="13">Help talk</namespace>
      <namespace key="14">Category</namespace>
      <namespace key="15">Category talk</namespace>
    </namespaces>
  </siteinfo>
END
}

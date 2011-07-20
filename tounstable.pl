#!/usr/bin/env perl -w

use strict;
use Cwd qw(abs_path);
use File::Basename;
use File::Temp;
use IO::Handle;
use Getopt::Long;
use vars qw(
	$RANGERMIRROR
	$PREFIX
);

$PREFIX=&File::Basename::dirname(abs_path($0));
($PREFIX) = split(m#/fink/#, $PREFIX);

GetOptions(
	'prefix=s' => \$PREFIX,
);

{
	my $handle = IO::Handle->new();
	if (open($handle, 'rangermirror.txt'))
	{
		local $/ = undef;
		$RANGERMIRROR = <$handle>;
		close ($handle);
	}
	else
	{
		die "unable to read rangermirror.txt: $!\n";
	}
}

for my $file (@ARGV)
{
	$file =~ s/^\.\///;
	if ($file =~ /^\//)
	{
		warn "$file has an absolute path, skipping\n";
		next;
	}
	$file =~ s/^[^\/]+\///;

	if ($file =~ /\.(info|info\.in|patch)$/)
	{
		system('./generate-infofiles.pl', 'common/' . $file) == 0 or die "could not generate infofiles for 'common/$file'";
		for my $release ('10.4', '10.7')
		{
			my ($releasefile, $fromfile, $tofile);
			if ($file =~ s/\.info\.in$//)
			{
				$fromfile = "$release/" . $file;
				if ($release >= 10.7) {
					$tofile = "$PREFIX/fink/$release/stable/$file";
				} else {
					$tofile = "$PREFIX/fink/$release/unstable/$file";
				}
				for ("mac", "x11")
				{
					copy_file($fromfile . "-$_.info", $tofile . "-$_.info");
				}
			}
			else
			{
				$releasefile = "$release/" . $file;
				if (-f $releasefile)
				{
					$fromfile = $releasefile;
				}
				else
				{
					$fromfile = "common/" . $file;
					print "skipping $fromfile\n";
					next;
				}
				if ($release >= 10.7) {
					$tofile = "$PREFIX/fink/$release/stable/" . $file;
				} else {
					$tofile = "$PREFIX/fink/$release/unstable/" . $file;
				}
				copy_file($fromfile, $tofile);
			}
		}
	}
}

sub copy_file {
	my $fromfile = shift;
	my $tofile   = shift;

	print "$fromfile => $tofile\n";

	my $filein = IO::Handle->new();
	my $fileout = IO::Handle->new();

	if ($fromfile =~ /.info$/)
	{
		if (system("$PREFIX/bin/fink", 'validate', $fromfile) != 0)
		{
			die "$fromfile failed validation: $!\n";
		}
	}

	if (open ($filein, $fromfile))
	{
		if (open ($fileout, '>' . $tofile))
		{
			while (my $line = <$filein>)
			{
				if ($line =~ /^\s*CustomMirror\s*:\s*RangerMirror/i)
				{
					print $fileout $RANGERMIRROR;
				}
				else
				{
					print $fileout $line;
				}
			}
			close ($fileout);
		}
		else
		{
			warn "unable to write to $tofile: $!\n";
		}
		close ($filein);
	}
	else
	{
		warn "unable to read from $fromfile: $!\n";
	}
}

#!/usr/bin/perl

use File::Copy;

my $package = shift;
my $version = shift;

if (not @ARGV)
{
	print "usage: $0 <package> <version> [file0..n]\n";
	exit 1;
}

for my $file (@ARGV)
{
	if (open(FILEIN, $file))
	{
		if (open(FILEOUT, '>' . $file . '.tmp'))
		{

			my $in_heredoc = undef;
			while (my $line = <FILEIN>)
			{
				if ($line =~ /^\s*<<\s*$/ and $in_heredoc)
				{
					$in_heredoc .= $line;
					print FILEOUT process_section($in_heredoc);
					$in_heredoc = undef;
				}
				elsif ($in_heredoc)
				{
					$in_heredoc .= $line;
				}
				elsif ($line =~ /^(\s*)(BuildDepends|Depends)\s*:\s*(.*?)\s*$/)
				{
					if ($3 =~ /<</)
					{
						$in_heredoc = $line;
					}
					else
					{
						print FILEOUT process_section($line);
					}
				}
				else
				{
					print FILEOUT $line;
				}
			}

			close (FILEOUT);
		}
		else
		{
			warn "unable to write to $file.tmp: $!";
		}
		close (FILEIN);
	}
	else
	{
		warn "unable to open $file for reading: $!";
	}
	if (-s $file . '.tmp')
	{
		move($file . '.tmp', $file);
	}
}

sub process_section
{
	my @return;
	for my $arg (@_)
	{
		$arg =~ s/\(([^\)]+)\) \([^\)]+\)/\($1\)/gsi;
		$arg =~ s/\b(${package}(-shlibs|-dev|-doc|-bin|))(\s*,\s*|$)/$1 \(>= $version\)$3/gsi;
		$arg =~ s/\b(${package}(-shlibs|-dev|-doc|-bin|))(\s+)\(\>\=[^\)]+\)/$1$3\(\>\= $version\)/gsi;
		push(@return, $arg);
	}
	return @return;
}

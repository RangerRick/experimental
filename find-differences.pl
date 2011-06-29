#!/usr/bin/perl -w

use strict;

use Cwd 'abs_path';
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Path;
use Fink;
use Fink::PkgVersion;
use Fink::Services qw(&read_properties_var &pkglist2lol &lol2pkglist);

Fink->import;

my $name;
my $myversion;
my $unstableversion;

format STDOUT_TOP =
Package Name                                     My Version              Unstable Version
------------------------------------------------ ----------------------- -----------------------
.

format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<
$name,                                           $myversion,             $unstableversion
.

my $path = abs_path(dirname($0));
my $finkpath = `which fink`;
$finkpath = dirname(dirname(abs_path($finkpath))) . "/fink";

my $packages = {};

my @files = @ARGV;

if (not @files) {
	find(sub {
		push(@files, $File::Find::name) if ($File::Find::name =~ /\.info$/);
	}, $path, $finkpath);
}

FILELOOP: for my $file (@files) {
	my ($dir, $filename) = (dirname($file), basename($file));
	next if ($file =~ /\/\.(svn|git)\//);
	next if ($file =~ /rangerrick\/(common|disabled)/);
	next if ($file =~ /\/stable\/(crypto|main)\//);

	my $contents;
	if (open (FILEIN, $file)) {
		local $/ = undef;
		$contents = <FILEIN>;
		close (FILEIN);
	} else {
		warn "unable to read from $file: $!\n";
		next FILELOOP;
	}

	my $properties = info_hash_from_var($file, $contents, { case_sensitive => 1 });

	my $name     = $properties->{'package'};
	my $epoch    = $properties->{'epoch'} || 0;
	my $version  = $properties->{'version'};
	my $revision = $properties->{'revision'} || 0;

	next unless (defined $name and defined $version);

	$name =~ s/-?\%type_(raw|pkg)\[[^\]]*\]//g;
	my $fullversion = $epoch . ':' . $version . '-' . $revision;

	if (not exists $packages->{$name}) {
		$packages->{$name}->{'has_local'} = 0;
	}

	push(@{$packages->{$name}->{'versions'}->{$fullversion}}, $file);

	if ($file =~ /^${path}/) {
		$packages->{$name}->{'has_local'} = 1;
	}

#	print Dumper($properties);
}

for my $package (sort keys %$packages) {
	if ($packages->{$package}->{'has_local'}) {
		if (keys %{$packages->{$package}->{'versions'}} > 1) {
			$name = $package;
			for my $version (keys %{$packages->{$package}->{'versions'}}) {
				if (grep(/\/local\//, @{$packages->{$package}->{'versions'}->{$version}})) {
					$myversion = $version;
				} else {
					$unstableversion = $version;
				}
			}
			write;

			#print "$package has unmatching versions:\n";
			#print Dumper($packages->{$package}->{'versions'});
		}
	}
}

#print Dumper($packages);

sub info_hash_from_var {
	my $filename = shift;
	my $var      = shift;
	my $options  = shift;
	my $infolevel = 0;

	my $properties = read_properties_var(
		$filename,
		$var,
		$options,
	);
	($properties, $infolevel) = Fink::PkgVersion->handle_infon_block($properties, $filename);

	my $return;

	for my $key (keys %$properties) {
		my $newkey = prettify_field_name($key);
		if ($key =~ /^splitoff/i) {
			$return->{$newkey} = info_hash_from_var(
				$filename . ' (' . $key . ')',
				$properties->{$key},
				{ remove_space => 1, %$options },
			);
		} else {
			$return->{$newkey} = $properties->{$key};
		}
	}

	$return->{'infolevel'} = $infolevel;

	return $return;
}

sub prettify_field_name {
	return lc(shift);
}

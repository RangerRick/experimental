#!/usr/bin/perl

my $KDEVERSION              = '4.5.2';
my $KDEDIRECTORY            = 'stable/%v/src/';
my $KDERELNUM               = 1;
my $KDEI18NRELNUM           = 1;
my $SOURCEDIRECTORYAPPEND   = "";
my $KOVERSION               = '2.2.2';
my $KODIRECTORY             = 'stable/koffice-%v/src/';
my $KORELNUM                = '1';
my $KOI18NRELNUM            = 1;
my $KOSOURCEDIRECTORYAPPEND = "";
my $VERBOSE                 = 0;
my $DRYRUN                  = 0;
#my $KDERENAME               = '%n-%v.tar.bz2';
my $MD5DEEP                 = `which md5deep`;
chomp($MD5DEEP);

my @kdepackages;
my @kopackages;

my %MAPPINGS;

for my $arg (@ARGV) {
	$VERBOSE = 1 if ($arg eq "-v");
	$DRYRUN  = 1 if ($arg eq "-d");
}

die "run 'fink install md5deep'" if (not -x $MD5DEEP);

my (@KDEI18N, @KOI18N);
opendir(DIR, "/sw/src") or die "can't read from /sw/src: $!\n";
while (my $file = readdir(DIR)) {
	next unless ($file =~ /kde-l10n-.*-${KDEVERSION}.tar.(gz|bz2)/);
	push(@KDEI18N, $file);
}
closedir(DIR);

opendir(DIR, "/sw/src") or die "can't read from /sw/src: $!\n";
while (my $file = readdir(DIR)) {
	next unless ($file =~ /koffice-l10n-.*-${KOVERSION}.tar.(gz|bz2)/);
	push(@KOI18N, $file);
}
closedir(DIR);

open(MAPPING, "i18n-mappings.txt") or die "can't read i18n-mappings.txt: $!\n";
while (my $line = <MAPPING>) {
	my ($key, $value) = $line =~ /^\s*(\S+)\s*=\s*(.+?)\s*$/;
	$MAPPINGS{$key} = $value;
}
close(MAPPING);

for my $i18n (@KDEI18N) {
	my ($shortname) = $i18n =~ /kde-l10n-([^\-]+)-${KDEVERSION}.*.tar.(gz|bz2)/;
	if (exists $MAPPINGS{$shortname}) {
		my ($md5) = `$MD5DEEP /sw/src/$i18n` =~ /^\s*(\S+)\s+/;
		my $normalized = lc($MAPPINGS{$shortname});
		$normalized =~ s#[^a-zA-Z]+#-#g;
		$normalized =~ s#-*$##;
#		my $replaces = "koffice-i18n-${normalized}, khangman, kturtle";
#		$replaces .= ", kde-i18n-norwegian-nyorsk"     if ($normalized eq "norwegian-nynorsk");
#		$replaces .= ", kde-i18n-serbian-latin-script" if ($normalized eq "serbian");
#		$replaces .= ", kde-i18n-serbian"              if ($normalized eq "serbian-latin-script");
		my $filename = $i18n;
		$filename =~ s#${KDEVERSION}#\%v#g;
		push(@kdepackages, "kde4-l10n-${normalized}");
		my $contents = <<END;
Info4: <<
Package: kde4-l10n-${normalized}-\%type_pkg\[kde\]
Version: ${KDEVERSION}
Revision: ${KDEI18NRELNUM}

Description: KDE4 - languages for $MAPPINGS{$shortname}
DescDetail: Language files for the K Desktop Environment: $MAPPINGS{$shortname}

Type: kde (x11 mac)
License: GPL/LGPL
Maintainer: Benjamin Reed <kde4-l10n-${normalized}\@fink.raccoonfink.com>

Depends: <<
	kdelibs4-\%type_pkg\[kde\] (>= %v-${KDERELNUM}),
	(\%type_pkg\[kde\] = x11) xfonts-intl,
<<
BuildDepends: <<
	automoc-\%type_pkg\[kde\] (>= 0.9.89-0),
	cmake (>= 2.6.3-1),
	fink (>= 0.28.0-1),
	gettext-tools (>= 0.17-1),
	kdelibs4-\%type_pkg\[kde\]-dev (>= %v-${KDERELNUM}),
	libgettext3-dev,
	(\%type_pkg\[kde\] = x11) xfonts-intl,
<<

Source: mirror:kde:${KDEDIRECTORY}kde-l10n/${filename}
#SourceDirectory: kde-l10n-${shortname}-%v${SOURCEDIRECTORYAPPEND}
Source-MD5: $md5

CompileScript: <<
#!/bin/sh -ev

	export KDE4_PREFIX="\%p" KDE4_TYPE="\%type_pkg\[kde\]"
	. \%p/sbin/kde4-buildenv.sh

	mkdir -p build
	pushd build
		cmake \$KDE4_CMAKE_ARGS ..
		make
	popd
<<
InstallScript: <<
#!/bin/sh -ev

	pushd build
		make -j1 install/fast DESTDIR="\%d"
	popd

	mkdir -p \%i/share/doc/kde-installed-packages
	touch \%i/share/doc/kde-installed-packages/kde4-l10n-${normalized}-\%type_pkg\[kde\]
<<
<<
END
		print $contents if ($VERBOSE);
		my $infofile = "kde4-l10n-${normalized}.info";
		unless ($DRYRUN) {
			open(FILEOUT, ">po/$infofile") or die "can't write to $infofile: $!\n";
			print FILEOUT $contents;
			close(FILEOUT);
		}
	} else {
		print "ERROR: no name mapping for $i18n!\n";
	}
}

for my $i18n (@KOI18N) {
	my ($shortname) = $i18n =~ /koffice-l10n-([^\-]+)-${KOVERSION}.*.tar.(gz|bz2)/;
	if (exists $MAPPINGS{$shortname}) {
		my ($md5) = `$MD5DEEP /sw/src/$i18n` =~ /^\s*(\S+)\s+/;
		my $normalized = lc($MAPPINGS{$shortname});
		$normalized =~ s#[^a-zA-Z]+#-#g;
		$normalized =~ s#-*$##;
		my $filename = $i18n;
		$filename =~ s#${KOVERSION}#\%v#g;
		push(@kopackages, "koffice2-l10n-${normalized}");
		my $contents = <<END;
Info4: <<
Package: koffice2-l10n-${normalized}-\%type_pkg\[kde\]
Version: ${KOVERSION}
Revision: ${KOI18NRELNUM}

Description: KDE4 - KOffice languages for $MAPPINGS{$shortname}
DescDetail: Language files for the KDE office suite: $MAPPINGS{$shortname}

Type: kde (x11 mac)
License: GPL/LGPL
Maintainer: Benjamin Reed <koffice2-l10n-${normalized}\@fink.raccoonfink.com>

Depends: <<
	koffice2-\%type_pkg\[kde\]-base (>= %v-${KORELNUM}),
<<
BuildDepends: <<
	automoc-\%type_pkg\[kde\] (>= 0.9.89-0),
	cmake (>= 2.6.3-1),
	fink (>= 0.28.0-1),
	gettext-tools (>= 0.17-1),
	koffice2-\%type_pkg\[kde\]-dev (>= %v-${KORELNUM}),
	libgettext3-dev,
<<

Source: mirror:kde:${KODIRECTORY}koffice-l10n/${filename}
#SourceDirectory: koffice-l10n-${shortname}-%v${SOURCEDIRECTORYAPPEND}
Source-MD5: $md5

CompileScript: <<
#!/bin/sh -ev

	export KDE4_PREFIX="\%p" KDE4_TYPE="\%type_pkg\[kde\]"
	. \%p/sbin/kde4-buildenv.sh

	mkdir -p build
	pushd build
		cmake \$KDE4_CMAKE_ARGS ..
		make
	popd
<<
InstallScript: <<
#!/bin/sh -ev

	pushd build
		make -j1 install/fast DESTDIR="\%d"
	popd

	mkdir -p \%i/share/doc/kde-installed-packages
	touch \%i/share/doc/kde-installed-packages/koffice2-l10n-${normalized}-\%type_pkg\[kde\]
<<
<<
END
		print $contents if ($VERBOSE);
		my $infofile = "koffice2-l10n-${normalized}.info";
		unless ($DRYRUN) {
			open(FILEOUT, ">po/$infofile") or die "can't write to $infofile: $!\n";
			print FILEOUT $contents;
			close(FILEOUT);
		}
	} else {
		print "ERROR: no name mapping for $i18n!\n";
	}
}

unless ($DRYRUN) {
	for my $type ('x11', 'mac') {
		my $packagelist = join(', ', map { $_ . '-' . $type . " (>= ${KDEVERSION}-${KDEI18NRELNUM})" } @kdepackages);
		open(FILEOUT, ">po/bundle-kde4-l10n-$type.info") or die "can't write to bundle-kde4-l10n-$type.info: $!\n";
		print FILEOUT <<END;
Package: bundle-kde4-l10n-$type
Version: ${KDEVERSION}
Revision: ${KDEI18NRELNUM}
Type: bundle
Depends: $packagelist
Description: KDE4 - all language support
DescDetail: <<
This package doesn't install any files of itself, but instead makes
sure that all KDE4 language files get installed.
<<
Maintainer: Benjamin Reed <bundle-kde4-l10n\@fink.raccoonfink.com>
END
		close(FILEOUT);

		$packagelist = join(', ', map { $_ . '-' . $type . " (>= ${KOVERSION}-${KOI18NRELNUM})" } @kopackages);
		open(FILEOUT, ">po/bundle-koffice2-l10n-$type.info") or die "can't write to bundle-koffice2-l10n-$type.info: $!\n";
		print FILEOUT <<END;
Package: bundle-koffice2-l10n-$type
Version: ${KOVERSION}
Revision: ${KOI18NRELNUM}
Type: bundle
Depends: $packagelist
Description: KOffice2 - all language support
DescDetail: <<
This package doesn't install any files of itself, but instead makes
sure that all KOffice language files get installed.
<<
Maintainer: Benjamin Reed <bundle-koffice2-l10n\@fink.raccoonfink.com>
END
		close(FILEOUT);
	}

}

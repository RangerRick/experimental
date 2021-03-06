#!/usr/bin/perl

my $KDEVERSION              = '3.5.10';
my $KDEDIRECTORY            = 'stable/%v/src/';
my $KDERELNUM               = 1;
my $KDEI18NRELNUM           = 1;
my $SOURCEDIRECTORYAPPEND   = "";
my $KOVERSION               = '1.6.3';
my $KODIRECTORY             = 'stable/koffice-%v/src/koffice-l10n/';
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

opendir(DIR, "/sw/src") or die "can't read from /sw/src: $!\n";
my @KDEI18N = sort(grep(/kde-i18n-.*-${KDEVERSION}.*.tar.(gz|bz2)/, readdir(DIR)));
closedir(DIR);

opendir(DIR, "/sw/src") or die "can't read from /sw/src: $!\n";
my @KOI18N = sort(grep(/koffice-l10n-.*-${KOVERSION}.*.tar.(gz|bz2)/, readdir(DIR)));
closedir(DIR);

open(MAPPING, "i18n-mappings.txt") or die "can't read i18n-mappings.txt: $!\n";
while (my $line = <MAPPING>) {
	my ($key, $value) = $line =~ /^\s*(\S+)\s*=\s*(.+?)\s*$/;
	$MAPPINGS{$key} = $value;
}
close(MAPPING);

for my $i18n (@KDEI18N) {
	my ($shortname) = $i18n =~ /kde-i18n-([^\-]+)-${KDEVERSION}.*.tar.(gz|bz2)/;
	if (exists $MAPPINGS{$shortname}) {
		my ($md5) = `$MD5DEEP /sw/src/$i18n` =~ /^\s*(\S+)\s+/;
		my $normalized = lc($MAPPINGS{$shortname});
		$normalized =~ s#[^a-zA-Z]+#-#g;
		$normalized =~ s#-*$##;
		my $replaces = "koffice-i18n-${normalized}, khangman, kturtle";
		$replaces .= ", kde-i18n-norwegian-nyorsk"     if ($normalized eq "norwegian-nynorsk");
		$replaces .= ", kde-i18n-serbian-latin-script" if ($normalized eq "serbian");
		$replaces .= ", kde-i18n-serbian"              if ($normalized eq "serbian-latin-script");
		my $filename = $i18n;
		$filename =~ s#${KDEVERSION}#\%v#g;
		my $sourcerename = "";
		if ($KDERENAME) {
			$sourcerename = 'SourceRename: ' . $KDERENAME;
		}
		push(@kdepackages, "kde-i18n-${normalized}");
		my $contents = <<END;
Package: kde-i18n-${normalized}
Source: mirror:kde:${KDEDIRECTORY}kde-i18n/${filename}
$sourcerename
SourceDirectory: kde-i18n-${shortname}-%v${SOURCEDIRECTORYAPPEND}
Description: KDE - languages for $MAPPINGS{$shortname}
DescDetail: Language files for the K Desktop Environment: $MAPPINGS{$shortname}
Source-MD5: $md5
Version: ${KDEVERSION}
Revision: ${KDEI18NRELNUM}
Replaces: ${replaces}
Depends: kdelibs3-unified (>= %v-${KDERELNUM}), xfonts-intl
BuildDepends: fink (>= 0.17.1-1), arts-dev, kdebase3-unified-dev (>= %v-${KDERELNUM}), kdelibs3-unified-dev (>= %v-${KDERELNUM}), libxml2, libxslt, xfonts-intl
Maintainer: Benjamin Reed <kde-i18n-${normalized}\@fink.racoonfink.com>
PatchScript: perl -pi -e 's,doc/HTML,doc/kde,g' configure
CompileScript: (export HOME=/tmp; export KDEDIR=%p; sh configure %c; find . -name \\*.bz2 -exec touch {} \\;; make)
InstallScript: <<
  make -j1 install DESTDIR=%d
  mkdir -p %i/share/doc/kde-installed-packages
  touch %i/share/doc/kde-installed-packages/kde-i18n-${normalized}
<<
License: GPL/LGPL
END
		print $contents if ($VERBOSE);
		my $infofile = "kde-i18n-${normalized}.info";
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
		my $replaces = "kde-i18n-${normalized}";
		$replaces .= ", koffice-i18n-norwegian-nyorsk" if ($normalized eq "norwegian-nynorsk");
		my $filename = $i18n;
		$filename =~ s#${KOVERSION}#\%v#g;
		push(@kopackages, "koffice-i18n-${normalized}");
		my $contents = <<END;
Package: koffice-i18n-${normalized}
Source: mirror:kde:${KODIRECTORY}${filename}
SourceDirectory: koffice-l10n-${shortname}-%v${KOSOURCEDIRECTORYAPPEND}
Description: KDE - KOffice languages for $MAPPINGS{$shortname}
DescDetail: Language files for the KDE office suite: $MAPPINGS{$shortname}
Source-MD5: $md5
Version: ${KOVERSION}
Revision: ${KOI18NRELNUM}
Replaces: $replaces
Depends: kdelibs3-unified (>= ${KDEVERSION}-${KDERELNUM}), xfonts-intl, koffice-base (>= ${KOVERSION}-${KORELNUM})
BuildDepends: fink (>= 0.17.1-1), arts-dev, kdebase3-unified-dev (>= ${KDEVERSION}-${KDERELNUM}), kdelibs3-unified-dev (>= ${KDEVERSION}-${KDERELNUM}), koffice-dev (>= ${KOVERSION}-${KORELNUM}), libxml2, libxslt, xfonts-intl
Maintainer: Benjamin Reed <koffice-i18n-${normalized}\@fink.racoonfink.com>
PatchScript: perl -pi -e 's,doc/HTML,doc/kde,g' configure
CompileScript: (export HOME=/tmp; export KDEDIR=%p; sh configure %c; find . -name \\*.bz2 -exec touch {} \\;; make)
InstallScript: <<
  make -j1 install DESTDIR=%d
  mkdir -p %i/share/doc/kde-installed-packages
  touch %i/share/doc/kde-installed-packages/koffice-i18n-${normalized}
<<
License: GPL/LGPL
END
		print $contents if ($VERBOSE);
		my $infofile = "koffice-i18n-${normalized}.info";
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
	my $packagelist = join(', ', map { $_ . " (>= ${KDEVERSION}-${KDEI18NRELNUM})" } @kdepackages);
	open(FILEOUT, ">po/bundle-kde-i18n.info") or die "can't write to bundle-kde-i18n.info: $!\n";
	print FILEOUT <<END;
Package: bundle-kde-i18n
Version: ${KDEVERSION}
Revision: ${KDEI18NRELNUM}
Type: bundle
Depends: $packagelist
Description: KDE - all language support
DescDetail: <<
This package doesn't install any files of itself, but instead makes
sure that all KDE language files get installed.
<<
Maintainer: Benjamin Reed <bundle-kde-i18n\@fink.racoonfink.com>
END
	close(FILEOUT);

	$packagelist = join(', ', map { $_ . " (>= ${KOVERSION}-${KOI18NRELNUM})" } @kopackages);
	open(FILEOUT, ">po/bundle-koffice-i18n.info") or die "can't write to bundle-koffice-i18n.info: $!\n";
	print FILEOUT <<END;
Package: bundle-koffice-i18n
Version: ${KOVERSION}
Revision: ${KOI18NRELNUM}
Type: bundle
Depends: $packagelist
Description: KDE - all language support for KOffice
DescDetail: <<
This package doesn't install any files of itself, but instead makes
sure that all KOffice language files get installed.
<<
Maintainer: Benjamin Reed <bundle-koffice-i18n\@fink.racoonfink.com>
END
	close(FILEOUT);
}

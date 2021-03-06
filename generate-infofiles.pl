#!/usr/bin/perl

use strict;

#use lib '/32sw/lib/perl5';
#use lib '/32sw/lib/perl5/darwin';

use Clone qw(clone);
use File::Basename;
use File::Find;
use File::Path;
use Cwd 'abs_path';
use Fink;
use Fink::PkgVersion;
use Fink::Services qw(&read_properties_var &pkglist2lol &lol2pkglist);
use IO::Handle;
use Data::Dumper;

Fink->import;

my $path = abs_path(dirname($0));

my @files = @ARGV;
my %files;

my $package_lookup = {
	'all' => {
		'^boost1.35.systempython$'        => 'boost1.41.cmake',
		'^boost1.35.systempython-shlibs$' => 'boost1.41.cmake-shlibs',
		'^gettext-tools-0.17$'            => 'gettext-tools',
		'^intltool$'                      => 'intltool40',
		'^libevent1$'                     => 'libevent2',
		'^libevent1-shlibs$'              => 'libevent2-shlibs',
		'^libevent1.4$'                   => 'libevent2',
		'^libevent1.4-shlibs$'            => 'libevent2-shlibs',
		'^libexiv2$'                      => 'libexiv2-0.19',
		'^libexiv2-shlibs$',              => 'libexiv2-0.19-shlibs',
		'^libexiv2-0.18$'                 => 'libexiv2-0.19',
		'^libexiv2-shlibs-0.18$',         => 'libexiv2-0.19-shlibs',
		'^libgettext3-dev$'               => 'libgettext8-dev',
		'^libgettext3-shlibs$'            => 'libgettext8-shlibs',
		'^libjpeg$'                       => 'libjpeg8',
		'^libjpeg-shlibs$'                => 'libjpeg8-shlibs',
		'^libpng3$'                       => 'libpng16',
		'^libpng3-shlibs$'                => 'libpng16-shlibs',
		'^libpng14$'                      => 'libpng16',
		'^libpng14-shlibs$'               => 'libpng16-shlibs',
		'^libpng15$'                      => 'libpng16',
		'^libpng15-shlibs$'               => 'libpng16-shlibs',
		'^libtool14$',                    => 'libtool2',
		'^pango1-xft2-shlibs$'            => 'pango1-xft2-ft219-shlibs',
		'^pango1-xft2-dev$'               => 'pango1-xft2-ft219-dev',
		'^pango1-xft2$'                   => 'pango1-xft2-ft219',
		'^vte-dev$'                       => 'vte9-dev',
		'^vte-shlibs$'                    => 'vte9-shlibs',
	},
};

my $version_lookup = {
	'all' => {
		'^akonadi-.*?(-dev|-shlibs)?$'        => [ '1.5.1',        '1'    ],
		'^ant-base$'                          => [ '1.8.1',        '1'    ],
		'^ant-jdbc$'                          => [ '1.8.1',        '1'    ],
		'^ant-optional$'                      => [ '1.8.1',        '1'    ],
		'^arts(-dev|-shlibs)?$'               => [ '1.5.10',       '10'   ],
		'^atk1(-dev|-shlibs)?$'               => [ '1.28.0',       '1'    ],
		'^autoconf$'                          => [ '2.63',         '1'    ],
		'^automoc-.*$'                        => [ '0.9.89',       '0.999999.1' ],
		'^blitz-(mac|x11)(-dev|-shlibs)?$'    => [ '0.0.4',        '3'    ],
		'^cairo(-dev|-shlibs)?$'              => [ '1.8.10',       '3'    ],
		'^cairomm1.*$'                        => [ '1.8.2',        '1'    ],
		'^cmake$'                             => [ '2.8.2',        '1'    ],
		'^cocoa-sharp$'                       => [ '0.9.5',        '1'    ],
		'^commons-beanutils$',                => [ '1.8.3',        '1'    ],
		'^commons-codec$'                     => [ '1.4',          '1'    ],
		'^commons-collections$'               => [ '3.2.1',        '1'    ],
		'^commons-dbcp$',                     => [ '1.3',          '1'    ],
		'^commons-digester$',                 => [ '2.1',          '1'    ],
		'^commons-jxpath$',                   => [ '1.3',          '1'    ],
		'^commons-lang$'                      => [ '2.5',          '1'    ],
		'^commons-logging$',                  => [ '1.1.1',        '1'    ],
		'^commons-pool$',                     => [ '1.5.5',        '1'    ],
		'^dbunit$'                            => [ '2.4.8',        '1'    ],
		'^dbus(1.3)?(-dev|-shlibs)?$'         => [ '1.2.24',       '1'    ],
		'^dbus-glib1.2(-dev|-shlibs)?$'       => [ '0.84',         '1'    ],
		'^docbook-xsl$'                       => [ '1.76.1',       '1'    ],
		'^fink$'                              => [ '0.30.2',       '1'    ],
		'^fink-package-precedence$'           => [ '0.7',          '1'    ],
		'^flag-dedup$'                        => [ '0.2',          '1'    ],
		'^flag-sort$'                         => [ '0.4',          '1'    ],
		'^freetype219(-shlibs)?$'             => [ '2.4.4',        '2'    ],
		'^fontconfig2(-dev|-shlibs)?$'        => [ '2.8.0',        '6'    ],
		'^gecko-sharp(-firefox.|-seamonkey)?$'=> [ '2.0',          '1044' ],
		'^gecko-sharp1(-firefox.|-seamonkey)?$'=> [ '0.6',         '1033' ],
		'^gettext-tools$'                     => [ '0.17',         '1'    ],
		'^glew(-shlibs)?$'                    => [ '1.5.1',        '1'    ],
		'^glib2(-dev|-shlibs)?$'              => [ '2.22.0',       '1'    ],
		'^gmp(-shlibs)?$'                     => [ '4.3.2',        '8'    ],
		'^gmp5(-shlibs)?$'                    => [ '5.0.1',        '8'    ],
		'^gnome-desktop-sharp2$'              => [ '2.24.0',       '1'    ],
		'^gnome-panel(-shlibs|-dev)?$'        => [ '2.24.0',       '1'    ],
		'^gnome-sharp2$'                      => [ '2.24.0',       '1'    ],
		'^gnome-vfs2-unified(-dev|-shlibs)?$' => [ '1:2.24.2',     '1'    ],
		'^grantlee(-dev|-shlibs)?$'           => [ '0.1.8',        '1'    ],
		'^gst-plugins-bad-0.10.*$'            => [ '0.10.22',      '1'    ],
		'^gst-plugins-base-0.10.*$'           => [ '0.10.34',      '1'    ],
		'^gst-plugins-good-0.10.*$'           => [ '0.10.29',      '1'    ],
		'^gst-plugins-ugly-0.10.*$'           => [ '0.10.18',      '1'    ],
		'^gst-python-0.10.*$'                 => [ '0.10.21',      '1'    ],
		'^gstreamer-0.10.*$'                  => [ '0.10.34',      '1'    ],
		'^gtk.2(-dev|-shlibs)?$'              => [ '2.18.0',       '1'    ],
		'^gtk-doc$'                           => [ '1.17',         '2'    ],
		'^gtk-sharp(2|-monodoc)$'             => [ '2.12.9',       '1'    ],
		'^gtkhtml3.14(-dev|-shlibs)?$'        => [ '3.26.2',       '1'    ],
		'^gtksourceview2(-dev|-shlibs)?$'     => [ '2.6.2',        '2'    ],
		'^hsqldb$'                            => [ '1.8.1.1',      '1'    ],
		'^junit-addons$'                      => [ '1.4',          '1'    ],
		'^jsch$'                              => [ '0.1.43',       '1'    ],
		'^jzlib$'                             => [ '1.0.7',        '3'    ],
		'^kde4-buildenv$'                     => [ '4.6.0',        '1'    ],
		'^kdebase4.*$'                        => [ '4.6.3',        '1'    ],
		'^kdeedu4.*$'                         => [ '4.6.3',        '1'    ],
		'^kdegraphics4.*$'                    => [ '4.6.3',        '1'    ],
		'^kdelibs4.*$'                        => [ '4.6.3',        '1'    ],
		'^kdemultimedia4.*$'                  => [ '4.6.3',        '1'    ],
		'^kdepim4.*$'                         => [ '4.4.7',        '1'    ],
		'^kdepimlibs4.*$'                     => [ '4.6.3',        '1'    ],
		'^kde.*3.*$'                          => [ '3.5.10',       '10'   ],
		'^kipi-plugins4.*$'                   => [ '1.9.0',        '1'    ],
		'^kjsembed.*$'                        => [ '3.5.10',       '10'   ],
		'^libart2(-dev|-shlibs)?$'            => [ '2.3.20',       '1'    ],
		'^libattica.*$'                       => [ '0.2.0',        '1'    ],
		'^libcdparanoia0-dev$'                => [ '3a9.8',        '11'   ],
		'^libdbusmenu-qt.*$'                  => [ '0.8.0',        '1'    ],
		'^libgdiplus.*$'                      => [ '2.6.2',        '1'    ],
		'^libgnome2(-dev|-shlibs)?$'          => [ '2.24.0',       '1'    ],
		'^libgnomecanvas2(-dev|-shlibs)?$'    => [ '2.26.0',       '1'    ],
		'^libgnomeprint2.2(-dev|-shlibs)?$'   => [ '2.18.6',       '1'    ],
		'^libgnomeprintui2.2(-dev|-shlibs)?$' => [ '2.18.4',       '1'    ],
		'^libgnomeui2(-dev|-shlibs)?$'        => [ '2.24.0',       '1'    ],
		'^libidn(-bin|-java|-shlibs)?$'       => [ '1.22',         '1'    ],
		'^libkdcraw-7.*$'                     => [ '4.6.3',        '1'    ],
		'^libkexiv2-7.*$'                     => [ '4.6.3',        '1'    ],
		'^libkholiday.*$'                     => [ '4.6.3',        '1'    ],
		'^libkipi-6.*$'                       => [ '4.6.3',        '1'    ],
		'^libknotificationitem1.*$'           => [ '4.3.4',        '1'    ],
		'^libksane-0.*$'                      => [ '4.6.3',        '1'    ],
		'^libmal10(-shlibs)?$'                => [ undef,          '+'    ],
		'^libmath\+\+(-dev|-shlibs)?$'        => [ '0.0.4',        '1001' ],
		'^libmpfr1(-shlibs)?$'                => [ '2.4.2',        '3'    ],
		'^libmpfr4(-shlibs)?$'                => [ '3.0.1',        '1'    ],
		'^liboil-0.3(-dev|-shlibs)?$'         => [ '0.3.17',       '2'    ],
		'^libpng3(-shlibs)?$'                 => [ '1.2.8',        '1'    ],
		'^libpng14(-shlibs)?$'                => [ '1.4.1',        '2'    ],
		'^libpng15(-shlibs)?$'                => [ '1.5.2',        '1'    ],
		'^libpqxx2(-dev|-shlibs)?$'           => [ '1:2.6.8',      '1'    ],
		'^libraptor1(-dev|-shlibs)?$'         => [ '1.4.21',       '1'    ],
		'^librasqal(-dev|-shlibs)?$'          => [ '0.9.16',       '4'    ],
		'^librasqal2(-dev|-shlibs)?$'         => [ '0.9.21',       '1'    ],
		'^librrd4(-shlibs)?$'                 => [ '1.4.4',        '1'    ],
		'^librsvg2(-bin|-dev|-shlibs)?$'      => [ '2.24.0',       '1'    ],
		'^libwnck1.22(-dev|-shlibs)?$'        => [ '2.26.2',       '1'    ],
		'^libwpd-0.8.*$'                      => [ '0.8.14',       '1'    ],
		'^libxine1(-shlibs)?$'                => [ '1.1.19',       '1'    ],
		'^libxml2(-shlibs)?$'                 => [ '2.6.32',       '1'    ],
		'^marble4.*$'                         => [ '4.6.3',        '1'    ],
		'^mockobjects$',                      => [ '0.09',         '1'    ],
		'^mono(-dev|-shlibs|-tools)?$'        => [ '2.6.2',        '1'    ],
		'^monodevelop.*$'                     => [ '2.2',          '1'    ],
		'^nant$'                              => [ '0.86',         '0'    ],
		'^orc(-shlibs)?$'                     => [ '0.4.14',       '1'    ],
		'^oxygen-icons.*$'                    => [ '4.6.3',        '1'    ],
		'^pango1-xft2-ft219(-dev|-shlibs)?$'  => [ '1.24.5',       '4'    ],
		'^pcre(-bin|-shlibs)?$'               => [ '7.6',          '1'    ],
		'^phonon(-shlibs)?$'                  => [ '4.5.0',        '4'    ],
		'^pixman(-shlibs)?$'                  => [ '0.16.0',       '1'    ],
		'^pkgconfig$'                         => [ '0.23',         '1'    ],
		'^poppler[24]-qt4$'                   => [ '0.6.4',        '4'    ],
		'^postgresql\S+$'                     => [ undef,          '+'    ],
		'^qca2.*$'                            => [ '2.0.3',        '1'    ],
		'^qimageblitz.*$'                     => [ '0.0.6',        '1'    ],
		'^qgpgme1.*$'                         => [ '4.6.3',        '1'    ],
		'^qt3.*$'                             => [ '3.3.8',        '2000' ],
		'^qt4-.*$'                            => [ '4.7.3',        '2'    ],
		'^qtwebkit-.*$'                       => [ '2.0.0',        '4'    ],
		'^qtscriptgenerator.*'                => [ '0.1.0',        '3'    ],
		'^redland(-dev|-shlibs)?$'            => [ '1.0.12',       '1'    ],
		'^rrdtool(-dev|-tcl)?$'               => [ '1.4.4',        '1'    ],
		'^shared-desktop-ontologies$'         => [ '0.6.0',        '1'    ],
		'^shared-mime-info$'                  => [ '0.51',         '1'    ],
		'^soprano.*?(-dev|-shlibs)?$'         => [ '2.6.0',        '1'    ],
		'^sqlite3(-dev|-shlibs)?$'            => [ '3.7.6.2',      '1'    ],
		'^strigi-gui.*?(-dev|-shlibs)?$'      => [ '0.7.2',        '1'    ],
		'^taglib-extras.*$'                   => [ '1.0.1',        '1'    ],
		'^taglib(-shlibs)?$'                  => [ '1.6.3',        '1'    ],
		'^unsermake$'                         => [ '0.4',          '0.20060316.1' ],
		'^virtuoso$'                          => [ '6.1.2',        '1'    ],
		'^vte9?(-dev|-shlibs)?$'              => [ '0.20.5',       '1'    ],
		'^webkit-sharp$'                      => [ '0.3',          '1'    ],
		'^xalan-j.*$'                         => [ '2.7.1',        '1'    ],
		'^xerces-j.*$'                        => [ '2.10.0',       '1'    ],
		'^xft2(-dev|-shlibs)?$'               => [ '2.2.0',        '1'    ],
	},
};

my @KEYS = (
	'Package', 'Version', 'Revision', 'Epoch', 'Architecture', 'Distribution',
		'Description', 'Type', 'License', 'Maintainer', '<CR>',
	'Depends', 'RuntimeDepends', 'BuildDepends', 'BuildConflicts', 'Provides',
		'Conflicts', 'Replaces', 'Recommends', 'Suggests', 'Enhances', 'Pre-Depends',
		'Essential', 'BuildDependsOnly', 'GCC', 'InfoTest', '<CR>',
	'CustomMirror', 'Source', 'Source<N>', 'SourceDirectory', 'Source<N>Directory',
		'NoSourceDirectory', 'SourceExtractDir', 'Source<N>ExtractDir', 'SourceRename',
		'Source<N>Rename', 'Source-MD5', 'Source<N>-MD5', 'TarFilesRename',
		'Tar<N>FilesRename', 'UpdateConfigGuess', 'UpdateConfigGuessInDirs',
		'UpdateLibtool', 'UpdateLibtoolInDirs', 'UpdatePoMakefile', 'Patch',
		'PatchScript', 'PatchFile', 'PatchFile-MD5', 'PatchFile<N>', 'PatchFile<N>-MD5', '<CR>',
	'Set<S>', 'NoSet<S>', 'UseMaxBuildJobs', 'ConfigureParams', 'DefaultScript', 'CompileScript', '<CR>',
	'UpdatePOD', 'InstallScript', 'NoPerlTests', 'AppBundles', 'JarFiles', 'DocFiles',
		'RuntimeVars', 'SplitOff', 'SplitOff<N>', 'SplitOff<S>', 'Files', 'Shlibs', '<CR>',
	'PreInstScript', 'PostInstScript', 'PreRmScript', 'PostRmScript', 'ConfFiles',
		'InfoDocs', 'DaemonicFile', 'DaemonicName', '<CR>',
	'Homepage', 'DescDetail', 'DescUsage', 'DescPackaging', 'DescPort',
);

my @TREES = qw( 10.4 10.7 );

my $APPEND_USAGE = '^arts|kde\S+3|kdevelop$|koffice$|koffice-|bundle-kde$|bundle-kde-|kgpg';

if (not @files) {
	find(sub {
		push(@files, $File::Find::name);
	}, $path . '/common', $path . '/3rdparty/common');
}

FILELOOP: for my $file (@files) {
	next if ($file eq "-p");
	if ($file !~ /^\//) {
		$file = $path . '/' . $file;
	}
	my ($dir, $filename) = (dirname($file), basename($file));

	next if ($file =~ /\/\.svn\//);
	next unless ($file =~ /\.(info|info\.in|patch)$/);

	my $matched = 1;
	next if (not $matched);
	next if ($file =~ /notready/);

	if ($file =~ /\.info\.in$/) {
		if (open (FILEIN, $file)) {
			my $noext = $filename;
			$noext =~ s/\.info\.in$//;
			my $x11 = IO::Handle->new();
			my $mac = IO::Handle->new();
			my $in_x11   = 0;
			my $in_mac   = 0;
			my $in_0     = 0;
			my $in_ifdef = 0;
			my $line;
			if (open($x11, '>' . $dir . '/.' . $noext . '-x11.info')) {
				if (open($mac, '>' . $dir . '/.' . $noext . '-mac.info')) {
					while ($line = <FILEIN>) {
						#print "$in_x11 $in_mac $in_0 $in_ifdef $line";
						if ($in_x11) {
							if ($line =~ /^\s*\#else\s*$/) {
								$in_x11 = 0;
								$in_mac = 1;
							} elsif ($in_ifdef == 0 and $line =~ /^\s*\#endif\s*$/) {
								$in_x11 = 0;
								$in_mac = 0;
							} elsif ($line =~ /^\s*\#ifn?def\s.*$/) {
								$in_ifdef++;
								print $x11 $line;
							} elsif ($line =~ /^\s*\#endif\s*$/) {
								$in_ifdef--;
								print $x11 $line;
							} else {
								print $x11 $line;
							}
						} elsif ($in_mac) {
							if ($line =~ /^\s*\#else\s*$/) {
								$in_mac = 0;
								$in_x11 = 1;
							} elsif ($in_ifdef == 0 and $line =~ /^\s*\#endif\s*$/) {
								$in_x11 = 0;
								$in_mac = 0;
							} elsif ($line =~ /^\s*\#ifn?def\s.*$/) {
								$in_ifdef++;
								print $mac $line;
							} elsif ($line =~ /^\s*\#endif\s*$/) {
								$in_ifdef--;
								print $mac $line;
							} else {
								print $mac $line;
							}
						} elsif ($in_0) {
							if ($line =~ /^\s*\#else\s*$/) {
								$in_0 = 0;
							} elsif ($in_ifdef == 0 and $line =~ /^\s*\#endif\s*/) {
								$in_0 = 0;
							} elsif ($line =~ /^\s*\#ifn?def\s.*$/) {
								$in_ifdef++;
							} elsif ($line =~ /^\s*\#endif\s*$/) {
								$in_ifdef--;
							}
						} elsif ($in_ifdef > 0) {
							if ($line =~ /^\s*\#endif\s*/) {
								$in_ifdef--;
							}
							print $x11 $line;
							print $mac $line;
						} else {
							if ($line =~ /^\s*\#ifdef TYPE_X11\s*$/) {
								$in_x11 = 1;
							} elsif ($line =~ /^\s*\#ifdef TYPE_MAC\s*$/) {
								$in_mac = 1;
							} elsif ($line =~ /^\s*\#if 0\s*$/) {
								$in_0 = 1;
							} elsif ($line =~ /^\s*\#ifn?def\s.*$/) {
								$in_ifdef++;
								print $x11 $line;
								print $mac $line;
							} elsif ($line =~ /^\s*\#endif\s*$/) {
								$in_ifdef--;
								print $x11 $line;
								print $mac $line;
							} else {
								print $x11 $line;
								print $mac $line;
							}
						}
					}
					close($x11);
					close($mac);
					handle_file($dir, '.' . $noext . '-x11.info');
					handle_file($dir, '.' . $noext . '-mac.info');
				} else {
					warn "unable to write to $noext-mac.info: $!\n";
					close($x11);
					next;
				}
			} else {
				warn "unable to write to $noext-x11.info: $!\n";
				next;
			}
		} else {
			warn "unable to read from $file: $!\n";
			next;
		}
	} else {
		handle_file($dir, $filename);
	}
}

sub handle_file {
	my $dir      = shift;
	my $filename = shift;
	my $file     = $dir . '/' . $filename;
	my $parse    = 1;

	print $file, "\n";

	my $contents;
	if (open (FILEIN, $file)) {
		my $splitoff_count = "";
		while (my $line = <FILEIN>) {
			if ($line =~ /^\s*SplitOff([^\d].*)$/) {
				$line =~ s/SplitOff([^\d].*):/SplitOff${splitoff_count}:/i;
				if ($splitoff_count eq "") {
					$splitoff_count = 2;
				} else {
					$splitoff_count++;
				}
			}
			if ($line =~ /^\s*#define\s+NOPARSE/) {
				$parse = 0;
			} else {
				$contents .= $line;
			}
		}
		close (FILEIN);
	} else {
		warn "unable to read from $file: $!\n";
		return;
	}

	if (not $parse) {
		for my $tree (@TREES) {
			my $todir = $dir;
			$todir =~ s#/common/#/${tree}/#;
			$todir =~ s#/3rdparty/common/#/3rdparty/${tree}/#;
			mkdir_p($todir) unless (-d $todir);

			if (open (FILEOUT, '>' . $todir . '/' . $filename)) {
				print FILEOUT $contents;
				close (FILEOUT);
			}
		}
	} elsif ($file =~ /\.info$/) {
		my $properties = info_hash_from_var(
			$file,
			$contents,
			{ case_sensitive => 1 },
		);

#		print Dumper($properties), "\n";

		for my $tree (@TREES) {
			next if ($file =~ /postgresql73/ and $tree ne "10.3");

			my $treeproperties = clone($properties);
			$treeproperties->{'Tree'} = $tree;

			if (exists $treeproperties->{'Distribution'}) {
				my @dists = split(/\s*,\s*/, $treeproperties->{'Distribution'});
				next unless grep {/\b${tree}$/} @dists;
			}

			$treeproperties = transform_fields($treeproperties, clone($treeproperties), 1);

			my $todir = $dir;
			$todir =~ s#/common/#/${tree}/#;
			$todir =~ s#/3rdparty/common/#/3rdparty/${tree}/#;
			mkdir_p($todir) unless (-d $todir);

			my $info = serialize_to_info($treeproperties) . "\n";
			my $outfilename = $filename;
			$outfilename =~ s/^\.//;

			if ($tree < 10.7 and $outfilename =~ /-10\.[789]\.info(\.in)?$/) {
				next;
			}
			if ($tree >= 10.7 and $outfilename =~ /-10\.[6789]\.info(\.in)?$/) {
				$outfilename =~ s/-10\.[6789](\.info(\.in)?)$/$1/;
			}

			if (open (FILEOUT, '>' . $todir . '/' . $outfilename)) {
				print FILEOUT $info;
				close (FILEOUT);
			}
		}

	} elsif ($file =~ /\.patch$/) {
		for my $tree (@TREES) {
			next if ($file =~ /postgresql73/ and $tree ne "10.3");

			if (open (FILEIN, $file)) {
				my $header = <FILEIN>;
				chomp($header);
				close(FILEIN);
				if ($header =~ /^\s*Distribution:\s*(.*?)\s*$/) {
					my $dists = $1;
					if (not grep {/^${tree}$/} split(/\s*,\s*/, $dists)) {
						next;
					}
				}
			}
			my $todir = $dir;
			$todir =~ s#/common/#/${tree}/#;
			$todir =~ s#/3rdparty/common/#/3rdparty/${tree}/#;
			mkdir_p($todir) unless (-d $todir);

			if (open (FILEOUT, '>' . $todir . '/' . $filename)) {
				print FILEOUT transform_patch($tree, $contents);
				close (FILEOUT);
			}
		}

	} else {
		warn "unhandled file: $file\n";
	}

}

sub stringwithnumber {
	my ($a_prefix, $a_number) = $a =~ /^(.+?)(\d*)$/;
	my ($b_prefix, $b_number) = $b =~ /^(.+?)(\d*)$/;
	if ($a_prefix eq $b_prefix) {
		return $a_number <=> $b_number;
	}
	return $a cmp $b;
}

sub transform_fields {
	my $packagehash = shift;
	my $properties  = shift;
	my $toplevel    = shift || 0;

	my $current_splitoff = 1;
	for my $field (keys %$properties) {
		my $lcfield = lc($field);
		no strict qw(refs);
		if ($field =~ /^splitoff/i) {
			my $contents = $properties->{$field};
			if ($field =~ /^splitoff([^\d]+)$/i) {
				delete $properties->{$field};
				$field = "SplitOff" . ++$current_splitoff;
			}
			$properties->{$field} = transform_fields($packagehash, $contents);
		} elsif (defined &{"transform_$lcfield"}) {
			$properties->{$field} = &{"transform_$lcfield"}($packagehash, $properties->{$field});
			if ($properties->{$field} eq "") {
				delete $properties->{$field};
			}
		} else {
			#warn "unhandled field: $field\n";
		}
	}

	if ($toplevel and not exists $properties->{'UseMaxBuildJobs'}) {
		if (exists $properties->{'NoSetMAKEFLAGS'}) {
			$properties->{'UseMaxBuildJobs'} = 'false';
		} else {
			$properties->{'UseMaxBuildJobs'} = 'true';
		}
	}

	if (exists $properties->{'Type'} and $properties->{'Type'} =~ /^perl\(/ and $properties->{'Tree'} ge "10.4") {
		if (exists $properties->{'Architecture'}) {
			die "type = perl, but architecture is already set!\n";
		} else {
			$properties->{'Architecture'} = '(%type_pkg[perl] = 581) powerpc, (%type_pkg[perl] = 584) powerpc';
		}
		if (exists $properties->{'Distribution'}) {
			warn "type = perl, but distribution is already set!\n";
		} else {
			$properties->{'Distribution'} = '(%type_pkg[perl] = 581) 10.4, (%type_pkg[perl] = 584) 10.4, (%type_pkg[perl] = 586) 10.4, (%type_pkg[perl] = 586) 10.5, (%type_pkg[perl] = 5100) 10.5, (%type_pkg[perl] = 5100) 10.6, (%type_pkg[perl] = 5123) 10.7';
		}
	}

	if ($packagehash->{'Package'} =~ /$APPEND_USAGE/i) {
		$properties->{'DescUsage'} = transform_descusage($packagehash, $properties->{'DescUsage'});
	}

	return $properties;
}

sub print_indent {
	my $field_name = shift;
	my $text       = shift;
	my $indent     = shift || 0;

	$text =~ s/^\n+//gsi;
	$text =~ s/\n+$//gsi;

	my $return = "";

	if ($text =~ /\n/) {
		$return .= "\t" x $indent . $field_name . ": <<\n";
		if ($field_name =~ /^(builddepends|compilescript|conffiles|conflicts|custommirror|depends|enhances|files|patchscript|recommends|replaces|runtimedepends|shlibs|suggests)$/i) {
			my $heredocs = 0;
			for my $line (split(/\n/, $text)) {
				if ($line =~ /^END$/) {
					$heredocs = 1;
					last;
				}
			}
			if ($heredocs) {
				$return .= $text . "\n";
			} else {
				for my $line (split(/\n/, $text)) {
					$line =~ s/^\s+//;
					$return .= "\t" x ($indent + 1) . $line . "\n";
				}
			}
		} else {
			$return .= $text . "\n";
		}
		$return .= "\t" x $indent . "<<\n";
	} else {
		$return .= "\t" x $indent . $field_name . ": " . $text . "\n";
	}

	return $return;
}

sub serialize_to_info {
	my $package = clone(shift);
	my $indent  = shift || 0;

	#print Dumper($package), "\n";
	my $output = "";

	delete $package->{'Tree'};
	my $infolevel = int($package->{'InfoLevel'});
	delete $package->{'InfoLevel'};

	$output .= "Info${infolevel}: <<\n" if ($infolevel >= 2 and not $indent);

	for my $key (@KEYS) {
		if ($key eq "<CR>") {
			$output .= "\n" unless ($output =~ /\n\n$/gs or $indent);
		} elsif ($key =~ /<N>/) {
			my $regex = $key;
			$regex =~ s/<N>/\\d\+/gs;
			for my $field (sort stringwithnumber keys %$package) {
				if ($field =~ /^\s*${regex}\s*$/gsi) {
					if (ref $package->{$field}) {
						$output .= print_indent($field, serialize_to_info($package->{$field}, $indent + 1), $indent);
					} else {
						$output .= print_indent($field, $package->{$field}, $indent);
					}
					delete $package->{$field};
					#warn "$key matched $field (/^$regex\$/i\n";
				} else {
					#warn "$key did not match $field (/^$regex\$/i\n";
				}
			}
		} elsif ($key =~ /<S>/) {
			my $regex = $key;
			$regex =~ s/<S>/\.\+/gs;
			for my $field (sort stringwithnumber keys %$package) {
				if ($field =~ /^\s*${regex}\s*$/gsi) {
					if (ref $package->{$field}) {
						$output .= print_indent($field, serialize_to_info($package->{$field}, $indent + 1), $indent);
					} else {
						$output .= print_indent($field, $package->{$field}, $indent);
					}
					delete $package->{$field};
					#warn "$key matched $field (/^$regex\$/i\n";
				} else {
					#warn "$key did not match $field (/^$regex\$/i\n";
				}
			}
		} else {
			for my $field (keys %$package) {
				if ($field =~ /^\s*${key}\s*$/gsi) {
					if (ref $package->{$field}) {
						$output .= print_indent($key, serialize_to_info($package->{$field}, $indent + 1), $indent);
					} else {
						$output .= print_indent($key, $package->{$field}, $indent);
					}
					delete $package->{$field};
				}
			}
		}
	}

	for my $key (sort stringwithnumber keys %$package) {
		die "ERROR: '$key' is missing from \@KEYS!\n";
	}

	$output =~ s/\n\n+/\n\n/gsi;
	$output .= "<<\n" if ($infolevel >= 2 and not $indent);

	# do a second pass to reorder Source: lines, 'cause doing it
	# in a generic way will take an insane amount of code  :P
	my $final_output = '';
	my $done_source  = 0;
	my $in_source    = 0;
	my %source_items;
	for my $line (split(/\n/, $output))
	{
		if ($line =~ /^[^:]*Source[^:]*:/ and not $done_source)
		{
			if (not $in_source)
			{
				$final_output .= "<<<<SOURCE_PLACEHOLDER>>>>\n";
				$in_source = 1;
			}
			my ($key, $value) = $line =~ /^(\s*[^\:]+):(.*)$/;
			$source_items{$key} = $value;
			next;
		}
		elsif ($in_source)
		{
			$in_source = 0;
		}
		$final_output .= $line . "\n";
	}

	my $source_lines = join("\n", map { $_ = $_ . ":" . $source_items{$_} } sort(keys(%source_items)));
	$final_output =~ s/<<<<SOURCE_PLACEHOLDER>>>>/$source_lines/gs;
	return $final_output;
}

sub prettify_field_name {
	my $field = shift;

	for my $key (@KEYS) {
		if ($key =~ /<N>/) {
			my $regex = $key;
			$regex =~ s/<N>/\(\\d\+\)/gs;
			if (my ($number) = $field =~ /^${regex}$/gsi) {
				my $field_name = $key;
				$field_name =~ s/<N>/$number/gsi;
				return $field_name;
			}
		} elsif (my ($set, $var) = $field =~ /^(NoSet|Set)(.*)$/i) {
			if ($set =~ /^no/i) {
				return "NoSet" . uc($var);
			} else {
				return "Set" . uc($var);
			}
		} elsif ($key =~ /<S>/i) {
			my $regex = $key;
			$regex =~ s/<S>/\(\.\+\)/gsi;
			if (my ($string) = $field =~ /^${regex}$/i) {
				my $field_name = $key;
				$field_name =~ s/<S>/$string/gsi;
				return $field_name;
			}
		} elsif ($field =~ /^\s*${key}\s*$/gsi) {
			# warn "prettify: $key =~ /^${field}\$/gsi matched\n";
			return $key;
		} else {
			# warn "prettify: $key =~ /^${field}\$/gsi did not match\n";
		}
	}
	warn "prettify: no match for '$field'\n";
	return $field;
}

sub transform_architecture {
	my $tree = shift->{'Tree'};
	my $arch = shift;

	return undef if ($tree >= 10.7);
	return $arch;
}

sub transform_builddepends {
	return transform_depends(@_);
}

sub transform_compilescript {
	my $tree          = shift->{'Tree'};
	my $compilescript = shift;

	if ($tree eq '10.4') {
		# I really don't like having these hardcoded here, need to figure out a way to
		# make it more configurable
		$compilescript =~ s/(gcc|g\+\+)-3.3/$1/gs;
		$compilescript =~ s/USE_EXCEPTIONS=\"[^\"]+\"//gs;
	}

	return $compilescript;
}

sub transform_configureparams {
	my $tree   = shift->{'Tree'};
	my $params = shift;

	if ($tree eq '10.4') {
		$params =~ s/--disable-java//gs;
	}

	return $params;
}

sub transform_conflicts {
	transform_depends(@_);
}

sub transform_custommirror {
	my $packagehash = shift;
	my $contents    = shift;

	if ($contents =~ /^\s*rangermirror\s*$/gsi) {
		if (open (RANGER, "rangermirror.txt")) {
			$contents = "";
			while (<RANGER>) {
				next if (/CustomMirror:/i);
				next if (/^\s*\<\<\s*$/);
				$contents .= $_;
			}
			chomp($contents);
			close(RANGER);
		}
	}
	return $contents;
}

sub transform_depends {
	my $packagehash = shift;
	my $depends     = pkglist2lol(shift);
	my @newdepends;

	for my $dep (@$depends) {
		my @newdep;
		for my $pkg (@$dep) {
			my $newdep = transform_dependency($packagehash, $pkg);
			push(@newdep, $newdep) if (defined $newdep);
		}
		push(@newdepends, \@newdep);
	}

	my $list = lol2pkglist(\@newdepends);
	$list =~ s/\s*,\s*/,\n/gs;
	return $list;
}

sub transform_dependency {
	my $packagehash = shift;
	my $dep_spec    = shift;
	my $delete      = 0;
	my $tree        = $packagehash->{'Tree'};

	my ($prefix, $package, $comparator, $version, $revision);
	if ($dep_spec =~ s/^\s*\(([^\)]+)\)\s+//) {
		$prefix = $1;
	}
	if (($package, $comparator, $version, $revision) = $dep_spec =~ /^(\S+)\s+\(([\>\=\<]+)\s*(\S+)\-(\S+)\)$/) {
		#print "transform_dependency[$dep_spec]: $package matched long-form dep\n";
	} elsif (($package) = $dep_spec =~ /^(\S+)$/) {
		#print "transform_dependency[$dep_spec]: $package matched short-form dep\n";
	} elsif (($package, $comparator, $version) = $dep_spec =~ /^(\S+)\s+\(([\>\=\<]+)\s*([^\-\s]+)\)$/) {
		#print "transform_dependency[$dep_spec]: $package matched incorrect dep\n";
		$revision = 0;
	} elsif ($dep_spec =~ /^\#/) {
		# don't do anything, it's a comment
	} else {
		warn "transform_dependency[$dep_spec]: unhandled dependency specification\n";
	}

	my $matched = 0;
	for my $tree_iterator ($tree, 'all') {
		last if ($matched);
		if (exists $package_lookup->{$tree_iterator}) {
			for my $key (keys %{$package_lookup->{$tree_iterator}}) {
				my $replace = $package_lookup->{$tree_iterator}->{$key};
				if ($package =~ /$key/i) {
					if (not defined $replace) {
						$delete++;
					} else {
						$package =~ s/$key/$replace/gsi;
					}
				}
			}
		}
		if (exists $version_lookup->{$tree_iterator} and $comparator =~ /\>/) {
			#print "checking in $tree_iterator\n";
	
			for my $key (keys %{$version_lookup->{$tree_iterator}}) {
				if ($package =~ /$key/i) {
					#print "transform_dependency[$dep_spec]: $package matches $key\n";
					my ($newversion, $newrevision) = @{$version_lookup->{$tree_iterator}->{$key}};
					if (defined $version and defined $revision and $revision ne '%r' and $newrevision eq '+') {
						$revision = transform_revision( $packagehash, $revision );
					} elsif (defined $newversion and defined $newrevision and $revision ne '%r') {
						$version  = $newversion;
						$revision = $newrevision;
					} else {
						if ((not defined $version and not defined $revision) or ($version eq '%v' and $revision eq '%r')) {
							# it's OK to do nothing here
						} else {
							warn "transform_dependency[$dep_spec]: not sure how to handle ($newversion, $newrevision) when version = $version and revision = $revision\n";
						}
					}
					$matched++;
					last;
				} else {
					#print "transform_dependency[$dep_spec]: $package does not match $key\n";
				}
			}
		}
	}

	if (defined $package and defined $version and defined $revision) {
		$comparator = '>=' unless (defined $comparator);
		$dep_spec = $package . ' (' . $comparator . ' ' . $version . '-' . $revision . ')';
		$dep_spec = '(' . $prefix . ') ' . $dep_spec if (defined $prefix);
	} elsif (defined $package) {
		$dep_spec = $package;
		$dep_spec = '(' . $prefix . ') ' . $dep_spec if (defined $prefix);
	}

	#print "transform_dependency: returning $dep_spec\n";

	return undef if ($delete);
	return $dep_spec;
}

sub transform_descusage {
	my $packagehash = shift;
	my $descusage   = shift;

	if ($packagehash->{'Package'} =~ /$APPEND_USAGE/i) {
		if (open (FILEIN, $path . '/kdedesc.txt')) {
			local $/ = undef;
			if ($descusage !~ /^[\s\n]*$/gsi) {
				die "descusage is not empty, overwriting\n";
			}
			$descusage = <FILEIN>;
			close (FILEIN);
		} else {
			die "unable to open kdedesc.txt: $!\n";
		}
	}

	return $descusage;
}

sub transform_distribution {
	my $tree = shift->{'Tree'};
	my $distribution = shift;

	# return undef if ($tree >= 10.7);
	return $distribution;
}

sub transform_enhances {
	return transform_depends(@_);
}

sub transform_files {
	my $tree  = shift->{'Tree'};
	my $files = shift;

	my @newlines;

	for my $line (split(/\r?\n/, $files)) {
		if ($tree eq "10.3") {
			next if ($line =~ /libkfontinst/i);
		}
		push(@newlines, $line);
	}

	return join("\n", @newlines);
}

sub transform_gcc {
	my $tree = shift->{'Tree'};
	my $gcc  = shift;

	if ($tree ge "10.4") {
		$gcc = "4.0";
	} else {
		$gcc = "3.3";
	}

	return $gcc;
}

sub transform_maintainer {
	my $packagehash = shift;
	my $text        = shift;

	$text =~ s/racoonfink.com/raccoonfink.com/g;
	return $text;
}

sub transform_patch {
	# transform_patch doesn't get a $packagehash, just the tree
	my $tree = shift;
	my $text = shift;

	if ($tree eq "10.4") {
		$text =~ s/g(cc|\+\+)-3\.3/g$1-4.0/gi;
		$text =~ s/-fno-coalesce//gs;
	}

	return $text;
}

sub transform_patchscript {
	my $tree = shift->{'Tree'};
	my $text = shift;

	if ($tree eq "10.4") {
		$text =~ s/g(cc|\+\+)-3\.3/g$1-4.0/gi;
		$text =~ s/-fno-coalesce//gs;
	}

	return $text;
}

sub transform_recommends {
	return transform_depends(@_);
}

sub transform_replaces {
	return transform_depends(@_);
}

sub transform_revision {
	my $packagehash = shift;
	my $revision    = shift;
	my $tree        = $packagehash->{'Tree'};

	if ($revision =~ /notransform/i) {
		$revision =~ s/\s*notransform:\s*//i;
		return $revision;
	}

	if ($tree eq '10.3') {
		$revision = revision_add($revision, 10);
	} elsif ($tree eq '10.4') {
		$revision = revision_add($revision, 0);
	} elsif ($tree eq '10.7') {
		$revision = revision_add($revision, 30);
	} else {
		warn "unhandled tree '$tree'\n";
	}
	return $revision;
}

sub transform_runtimedepends {
	return transform_depends(@_);
}

sub transform_setcc {
	my $tree  = shift->{'Tree'};
	my $setcc = shift;

	if ($tree eq '10.4') {
		$setcc =~ s/3\.3/4.0/gs;
	}

	return $setcc;
}

sub transform_setcflags {
	my $tree = shift->{'Tree'};
	my $text = shift;

	if ($tree eq "10.3") {
		$text =~ s/\-D_POLL_EMUL_H_//gs;
	}

	return $text;
}

sub transform_setcppflags {
	transform_setcflags(@_);
}

sub transform_setcxx {
	transform_setcc(@_);
}

sub transform_setcxxflags {
	transform_setcflags(@_);
}

sub transform_shlibs {
	my $packagehash = shift;
	my $shlibs      = shift;
	my $tree        = $packagehash->{'Tree'};
	my @newlines;

	for my $line (split(/\r?\n/, $shlibs)) {
		if ($tree eq "10.3") {
			next if ($line =~ /libkfontinst/i);
		}

		# whoo!  crazy lexing!
		my $newline;
		while ($line =~ /\G(.+?\(\S+\s+\S+\-)([^\-]+)\)/gsi) {
			my ($rest, $revision) = ($1, $2);
			$newline .= $rest . transform_revision( $packagehash, $revision ) . ')';
		}
		$line =~ /\G\(.*$/;
		$newline .= $1;

		push(@newlines, $line);
	}

	return join("\n", @newlines);
}

sub transform_suggests {
	return transform_depends(@_);
}

sub transform_type {
	my $tree = shift->{'Tree'};
	my $type = shift;
	if ($type =~ /^perl\s*\(0\)/i) {
		my @versions = qw(5.6.0 5.6.1 5.8.0 5.8.1 5.8.4 5.8.5 5.8.6 5.8.8);
		if ($tree =~ /^10.3/) {
			@versions = qw(5.6.0 5.8.0 5.8.1 5.8.4 5.8.6);
		} elsif ($tree =~ /^10.4/) {
			@versions = qw(5.8.1 5.8.4 5.8.6 5.8.8 5.10.0);
		} elsif ($tree >= 10.7) {
			@versions = qw(5.12.3);
		}
		$type =~ s/perl\s*\(0\)/perl(@versions)/;
	} elsif ($type =~ /^python\s*\(0\)/i) {
		my @versions = qw(2.3 2.4 2.5 2.6 2.7);
		if ($tree =~ /^10.4/) {
			@versions = qw(2.3 2.4 2.5 2.6 2.7);
		}
		$type = "python(@versions)";
	} elsif ($type =~ /^java\s\(0\)/i) {
		if ($tree =~ /^10.3/) {
			$type = "java(1.4)";
		} else {
			$type = "java(1.5)";
		}
	}

	return $type;
}

sub transform_version {
	my $packagehash = shift;
	my $version     = shift;
	return $version;
}

sub revision_add {
	my $revision = shift;
	my $amount   = shift;

	if (my ($pre, $post) = $revision =~ /^(.*\.)(\d+)$/) {
		$post += $amount;
		$revision = $pre . $post;
	} else {
		$revision += $amount;
	}
	return $revision;
}

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
		#print "$key = $newkey\n";
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

	$return->{'InfoLevel'} = $infolevel;

	return $return;
}

sub mkdir_p {
	my $dir = shift;

	eval { mkpath($dir, 0, 0775) };
	if ($@) {
		warn "unable to create $dir: $!\n";
	} else {
		return 1;
	}
	return;
}

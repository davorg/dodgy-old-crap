#!/usr/bin/perl -Tw
#
# ms-env.pl
# 
# A simple script to get information about the Perl environment on a
# web server.
#
# Copyright (c) 1998, 1999, Magnum Solutions Ltd, All rights reserved.
#
# This script is free software; you are free to redistibute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: ms-env.pl,v 1.4 2000/08/23 20:33:32 dave Exp $
# 
# $Log: ms-env.pl,v $
# Revision 1.4  2000/08/23 20:33:32  dave
# Fixed so it _works_ in taint mode!
#
# Revision 1.3  2000/08/23 20:05:00  dave
# Added taint mode.
#
# Revision 1.2  2000/06/04 17:31:04  dave
# Renamed 'copying' and 'readme' to 'COPYING' and 'README'.
# Added header info.
#
#

use lib '.';

use CGI qw(:standard);
use File::Find;
use strict;
use diagnostics;

$ENV{PATH} = '/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'}; 

my $VERSION = sprintf "%d.%02d", '$Revision: 1.4 $ ' =~ /(\d+)\.(\d+)/;

print header, "\n";
print start_html(-dtd=>'-//W3C//DTD HTML 4.0 Transitional//EN',
		 -title=>"Perl Environment: $ENV{SERVER_NAME}"), "\n";

print h1("Perl Environment: $ENV{SERVER_NAME}"), "\n";

print p("Perl Version: $]"), "\n";

print p("CGI.pm Version: $CGI::VERSION"), "\n";

print p("Library Path (\@INC):"), "\n";

print ul(li([@INC])), "\n";

print p('Modules:'), "\n";

my @mods;
my $list;
my $dir;
foreach (@INC) {
  @mods = ();
  $dir = $_;
  find({wanted => \&wanted, untaint => 1}, $_);

  $list .= ul(li($dir),
	      ul(li([sort @mods])));
}

print $list, "\n";

sub wanted {
  return unless /\.pm$/;

  push @mods, $File::Find::name;
}



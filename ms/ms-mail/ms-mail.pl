#!/usr/bin/perl -wT
#
# ms-mail.pl
# 
# A simple (but flexible) form mail script.
#
# Copyright (c) 1998, 1999,2000, Magnum Solutions Ltd, All rights reserved.
#
# This script is free software; you are free to redistibute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: ms-mail.pl,v 1.3 2000/08/31 22:16:10 dave Exp dave $
# 
# $Log: ms-mail.pl,v $
# Revision 1.3  2000/08/31 22:16:10  dave
# Added taint flag.
#
#
# Revision 1.2  2000/06/04 17:26:56  dave
# Renamed 'copying' and 'readme' to 'COPYING' and 'README'.
# Added header info.
#

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Mail::Mailer;
use Sys::Hostname;
use strict;

$|++;

my $VERSION = sprintf "%d.%02d", '$Revision: 1.3 $ ' =~ /(\d+)\.(\d+)/;

# Set the subject for the mail using a sensible default
# if one hasn't been set.
my $title = param('mailtitle') || 'Form Data Response';

# Set the address to send the mail to. The default here
# is only really useful for testing on a local system.
my $mailto = param('mailto') || $ENV{USER} || 'nobody';

# Set who the mail will be from. The default should be
# fine in most cases.
my $mailfrom = param('mailfrom') || 'webmaster@' . hostname;

# Set a template page to display once the mail has
# been sent. A template overrides a the value of 'nextpage'.
my $template;
$template = "$ENV{'DOCUMENT_ROOT'}/" . param('template')
  if param('template');

# Set a next page to display once the mail has been 
# sent. This is ignored if a template has been set.
my $nextpage = param('nextpage');

# and remove those entries from the data.
Delete('mailtitle');
Delete('mailto');
Delete('mailfrom');
Delete('nextpage');
Delete('template');

# Send the mail using Mail::Mailer
my $mail = Mail::Mailer->new('sendmail');

$mail->open({To=>$mailto, 
	     From=>$mailfrom,
	     Subject=>"$title"});

$mail->print("Data from WWW form follows:\n\n");

# Build up a table of all the parameters
my $rows;
foreach (param) {
  $mail->print("$_ :\t", join("\n\t", param($_)), "\n");
  $rows .= Tr(td("$_:"),
	      td(param($_)));
}

my $table = table({-border=>1}, $rows);

# Send other potentially interesting information.
$mail->print("\nOther Information:\n");
$mail->print("\n------------------\n");
$mail->print("HTTP From: $ENV{'HTTP_FROM'}\n") 
  if defined $ENV{'HTTP_FROM'};
$mail->print("Remote host: $ENV{'REMOTE_HOST'}\n")
  if defined $ENV{'REMOTE_HOST'};
$mail->print("Remote IP address: $ENV{'REMOTE_ADDR'}\n")
  if defined $ENV{'REMOTE_ADDR'};
$mail->print("--------------------------------------\n");

# Send the mail.
$mail->close;

print header, "\n";
if (defined $template) {
  if (open(TEMPLATE, $template)) {
    while (<TEMPLATE>) {
      s/||TABLE||/$table/e;
      print;
    }
  } else {
    &print_default("Can\'t open $template ($!)");
  }
} elsif (defined $nextpage)  {
  print "Location: $nextpage\n\n";
} else {
  &print_default;
}

# that's it quit and go home...
exit ;

sub print_default {
  print start_html(-title=>'Message Sent'), "\n";
  print h1('Message Sent'), "\n";

  print p(shift), "\n" if @_;;

  print p('We have registered the following data:'), "\n";
  print $table;
}

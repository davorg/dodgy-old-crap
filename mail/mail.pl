#!/usr/bin/perl -w 

use strict; 
use CGI qw(:standard); 

print header; 

my $mailprog = '/usr/sbin/sendmail'; 

my $recipient = 'dave@dave.org.uk'; 

open (MAIL, "|$mailprog -t") or &dienice("Can't access $mailprog: $!\n"); 

print MAIL "To: $recipient\n"; 
print MAIL "Reply-to: ", param('email'), ' (', param('name'), ")\n"; 
print MAIL "Subject: Form Data\n\n"; 

foreach (param) { 
  my ($key) = /^req(.*)$/; 

  print MAIL "$key = ", param($_), "\n"; 
} 

close(MAIL); 

print <<EndHTML; 

       <h2>Thank You</h2> 

       Thank you for applying. Your application has been delivered.<p> 

       Return to our <a href="../homemain.html">home page</a>. 

       </body></html> 

EndHTML

sub dienice { 

  my ($errmsg) = @_; 

  print "<h2>Error</h2>\n"; 
  print "$errmsg<p>\n"; 
  print "</body></html>\n"; 

  exit; 
} 

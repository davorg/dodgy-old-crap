#!/usr/local/bin/perl -w

use lib '.';

use Fcntl;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use AnyDBM_File;
use FreezeThaw qw(freeze thaw);

$|++;

$VERSION = sprintf "%d.%02d", '$Revision: 2.0 $ ' =~ /(\d+)\.(\d+)/;

my %comments;

umask 0;

my $file = param('file') || 'guest';

tie %comments, 'AnyDBM_File', $file, O_RDWR | O_CREAT, 0777;

if (param('new_user')) {
  my $rec = {};
  my $now = time;
  $rec->{user} = param('new_user');
  $rec->{email} = param('new_email');
  $rec->{text} = param('new_text');
    
  $comments{$now} = freeze $rec;

  param('new_user', '');
  param('new_email', '');
  param('new_text', '');
}

print header, "\n";

if (param('template')) {
  my $err = 0;
  my $template = "$ENV{DOCUMENT_ROOT}/" . param('template');
  open(TEMPLATE, $template) || do {$err = $!};

  if ($err)  {
    &display_default($template, $err);
  } else {
    while (<TEMPLATE>) {
      if (/!!FORM!!/) {
	&display_form;
      } elsif (/!!COMMENTS!!/) {
	&display_comments;
      } else {
	print;
      }
    }
  }
} else {
  &display_default;
}

sub display_form {
  print start_form, "\n";
  print hidden(-name=>'template', -value=>param('template'))
    if defined(param('template'));
  print hidden(-name=>'start', -value=>0)
    if defined(param('start'));
  print hidden(-name=>'numb', -value=>param('numb'))
    if defined(param('numb'));
  print hidden(-name=>'file', -value=>$file);
  print p('Your Name: ', 
	  textfield(-name=>new_user, -size=>30)), "\n";
  print p('Your Email: ',
	  textfield(-name=>new_email, 
		    -size=>30,
		    -default=>'')), "\n";
  print p('Your Comments:',
	  br,
	  textarea(-name=>new_text, 
		   -rows=>5, -cols=>50)), "\n";
  print submit(-value=>'Submit Entry'), "\n";
  print reset, "\n";
  print end_form, "\n";
}

sub display_comments {
  my ($k, $v);
  my $comments = "";
  my $then;
  my $thing;

  my $start = param('start') || 0;
  my $numb = param('numb') || keys %comments;
    
  my $i = 0;

  foreach $k (reverse sort keys %comments) {
    next unless $i++ >= $start;
    last if $i > ($start + $numb);

    $v = $comments{$k};
    $then = localtime $k;
	
    ($thing) = thaw($v);
	
    $thing->{user} =~ s/</&lt;/g;
    $thing->{email} =~ s/</&lt;/g;
    $thing->{text} =~ s/</&lt;/g;
    $thing->{text} =~ s/\n/<BR>/g;
	
    $comments .= p(strong($thing->{user}),
		   em($then),
		   br,
		   a({-href=>"mailto:$thing->{email}"},
		     $thing->{email}),
		   br,
		   $thing->{text})
      . hr . "\n";
  }
    
  my ($newest, $newer, $older, $oldest) = ('', '', '', '', '');

  if ($start != 0) {
    my $href = url . "?start=0&numb=$numb";
    $href .= "&file=" . param('file') if param('file');
    $href .= "&template=" . param('template') if param('template');

    $newest = a({-href=>$href}, '[<<Newest entries]');
  }

  if ($start - $numb >= 0) {
    my $href = url . "?start=" . ($start - $numb) . "&numb=$numb";
    $href .= "&file=" . param('file') if param('file');
    $href .= "&template=" . param('template') if param('template');
    
    $newer = a({-href=>$href}, '{< Newer entries]');
  }

  if ($start + $numb < keys %comments) {
    my $href = url . "?start=" . ($start + $numb) . "&numb=$numb";
    $href .= "&file=" . param('file') if param('file');
    $href .= "&template=" . param('template') if param('template');
    
    $older .= a({-href=>$href}, '[Older entries >]');
  }

  if ($start < ((keys %comments) - $numb)) {
    my $href = url . "?start=" . ((keys %comments) - $numb) 
      . "&numb=$numb";
    $href .= "&file=" . param('file') if param('file');
    $href .= "&template=" . param('template') if param('template');
    
    $oldest = a({-href=>$href}, '[Oldest entries >>]');
  }

  print p(join ' ', ($newest, $newer, $older, $oldest)), "\n";
      
  print $comments;
     
  print p(join ' ', ($newest, $newer, $older, $oldest)), "\n";
}

sub display_default {
  print start_html(-dtd=>'-//W3C//DTD HTML 4.0 Transitional//EN',
		   -title=>'Guest Book'), "\n";
  print h1('Guest Book');
    
  if (@_)  {
    print p("Can\'t open template: $_[0]. Error: $_[1]."), "\n";
  }

  &display_form;
  
  print hr, "\n";
  
  &display_comments;  

  print address('ms-guest v1.3',
		br,
		'&copy; 1998,',
		a({href=>'http://www.mag-sol.com'},
		  'Magnum Solutions Ltd.')), "\n";
    
}

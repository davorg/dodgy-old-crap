#!/usr/local/bin/perl -w

use lib '.';

use Fcntl;
use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use AnyDBM_File;
use FreezeThaw qw(freeze thaw);

my $page = CGI->new;

my %comments;

umask 0;

my $file = $page->param('file') || 'guest';

tie %comments, "AnyDBM_File", $file, O_RDWR | O_CREAT, 0777;

print $page->header, "\n";
print $page->start_html(-dtd=>'-//W3C//DTD HTML 4.0 Transitional//EN',
                        -title=>'Guest Book Maintenance'), "\n";
print $page->h1('Guest Book Maintenance'), "\n";

my $mode = $page->param('mode');
$page->delete('mode');
$mode = 'list' unless defined($mode);

my $entry;

if ($mode eq 'list') {
  &list_entries;
} elsif ($mode eq 'save') {
  $entry->{user} = $page->param('user');
  $entry->{email} = $page->param('email');
  $entry->{text} = $page->param('text');
  $entry->{time} = $page->param('time');

  $comments{$entry->{time}} = freeze($entry);
  
  print $page->p('Entry saved');

  print &show_entry($entry);
} elsif ($mode eq 'delete') {
  delete $comments{$page->param('time')};
  &list_entries;
} elsif ($mode eq 'edit') {
  ($entry) = thaw($comments{$page->param('time')});
  $entry->{time} = $page->param('time');
  print $page->start_form(-action=>"e-guest.pl"), "\n";
  &edit_entry($entry);
  print $page->hidden(-name=>'file', -value=>$file), "\n";
  print $page->hidden(-name=>'mode', -value=>'save'), "\n";
  print $page->submit(-value=>'Save');
  print $page->reset;
  
  print $page->end_form, "\n";
}

print $page->p($page->a({href=>"e-guest.pl?mode=list"},
			'List current entries')), "\n";

sub show_entry {
  my $entry = shift;
  my $text = $entry->{text};
    
  $text =~ s/\n/<BR>/g;

  $entry->{user} =~ s/</&lt;/g;
  $entry->{email} =~ s/</&lt;/g;
  $entry->{text} =~ s/</&lt;/g;
  $text =~ s/</&lt;/g;

  $page->table($page->Tr($page->td('Date: '),
			 $page->td(scalar localtime($entry->{time}))),
	       $page->Tr($page->td('User: '),
			 $page->td($entry->{user})),
	       $page->Tr($page->td('Email: '),
			 $page->td($entry->{email})),
	       $page->Tr($page->td('Comments: '),
			 $page->td($text)));
}

sub edit_entry {
  my $old = scalar(@_);
  my $entry = shift if $old;

  print $page->p('Old...'), "\n";
  print $page->table($page->Tr($page->td('Date: '),
			       $page->td(scalar localtime($entry->{time}))),
		     $page->Tr($page->td('User: '),
			       $page->td($page->textfield(-name=>'user',
							  -value=>$entry->{user},
							  -size=>20))),
		     $page->Tr($page->td('Email: '),
			       $page->td($page->textfield(-name=>'email',
							  -value=>$entry->{email},
							  -size=>20))),
		     $page->Tr($page->td('Comments: '),
			       $page->td($page->textarea(-name=>'text',
							 -rows=>10,
							 -columns=>50,
							 -value=>$entry->{text})))),
  "\n";

  print $page->hidden(-name=>'time', -value=>$entry->{time}), "\n";
}

sub small_form {
  my ($action, $req) = @_;

  $page->start_form(-action=>"e-guest.pl"). 
    $page->hidden(-name=>'file', -value=>$file) .
      $page->hidden(-name=>'time', -value=>$entry->{time}, -override=>1) . 
	$page->hidden(-name=>'mode', -value=>lc $action) . 
	  $page->hidden(-name=>'start', -value=>$start) .
	    $page->hidden(-name=>'numb', -value=>$numb) .
	      $page->submit(-value=>$action) . 
		$page->end_form;
}

sub list_entries {
  my ($row, @rows);
 
  my $start = $page->param('start') || 0;
  my $numb = $page->param('numb') || keys %comments;
    
  my $i = 0;

  foreach (reverse sort keys %comments) {
    next unless $i++ >= $start;
    last if $i > ($start + $numb);

    ($entry) = thaw($comments{$_});
    $entry->{time} = $_;

    $row = $page->Tr($page->td(&show_entry($entry)),
		     $page->td(&small_form('Edit', $entry),
			       &small_form('Delete', $entry)));
    
    push @rows, $row;
  }

  my ($newest, $newer, $older, $oldest) = ('', '', '', '', '');

  if ($start != 0) {
    my $href = $page->url . "?start=0&numb=$numb";
    $href .= "&file=" . $page->param('file') if $page->param('file');
    $href .= "&template=" . $page->param('template') 
      if $page->param('template');

    $newest = $page->a({-href=>$href}, "Newest entries");
  }

  if ($start - $numb >= 0) {
    my $href = $page->url . "?start=" . ($start - $numb) . "&numb=$numb";
    $href .= "&file=" . $page->param('file') if $page->param('file');
    $href .= "&template=" . $page->param('template') 
      if $page->param('template');
    
    $newer = $page->a({-href=>$href}, "<< Newer entries");
  }

  if ($start + $numb < keys %comments) {
    my $href = $page->url . "?start=" . ($start + $numb) . "&numb=$numb";
    $href .= "&file=" . $page->param('file') if $page->param('file');
    $href .= "&template=" . $page->param('template') 
      if $page->param('template');
    
    $older .= $page->a({-href=>$href}, "Older entries >>");
  }

  if ($start < ((keys %comments) - $numb)) {
    my $href = $page->url . "?start=" . ((keys %comments) - $numb) 
      . "&numb=$numb";
    $href .= "&file=" . $page->param('file') if $page->param('file');
    $href .= "&template=" . $page->param('template') 
      if $page->param('template');
    
    $oldest = $page->a({-href=>$href}, "Oldest entries");
  }

  print $page->p(join ' ', ($newest, $newer, $older, $oldest)), "\n";

  print $page->table({-border=>1},
		     @rows), "\n";

  print $page->p(join ' ', ($newest, $newer, $older, $oldest)), "\n";
}

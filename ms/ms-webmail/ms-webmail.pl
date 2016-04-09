#!/usr/local/bin/perl -w

use strict;
use CGI qw(header param);
use CGI::Carp qw(fatalsToBrowser);
use Template;

my $tt = Template->new(INCLUDE_PATH => "$ENV{DOCUMENT_ROOT}/tt");

if (param) {
  unless (param('pop') && param('user') && param('pass')) {
    error('Insufficient login parameters');
    exit;
  }
  
  if (param('Compose')) {
    &compose;
  } elsif (param('List')) {
    &list;
  } elsif (param('Read')) {
    &read;
  } elsif (param('Delete')) {
    &delete;
    &list;
  } elsif (param('Send')) {
    &send;
    &list;
  } elsif (param('Reply')) {
    &reply;
  }
} else {
  &login;
}

sub login {
  print header;
  $tt->process('login.tt')
    || die $tt->error;
}

sub error {
  print header;
  $tt->process('error.tt', { errors => [@_] })
    || die $tt->error;
  die join('<br>', @_);
}

sub compose {
  print header;
  my %defaults = ( to => '',
		   cc => '',
		   from => 'Dave Cross <dave@dave.org.uk>',
		   subject => '',
		   body => '',
		   ref => '',
		   @_,
		   conn => { pop => param('pop'),
			     user => param('user'),
			     pass => param('pass') });

  foreach (qw/to cc from subject body ref/) {
    $defaults{$_} =~ s/\"/&quot;/g;
    $defaults{$_} =~ s/</&lt;/g;
  }

  $tt->process('compose.tt', \%defaults)
    || die $tt->error;
}

sub list {
  require Mail::POP3Client;

  my $pop = Mail::POP3Client->new(HOST => param('pop'), 
				  USER => param('user'),
				  PASSWORD => param('pass'),
				  AUTH_MODE => 'PASS')
    || error(Mail::POP3Client->Message);

  print header;

  my $count = $pop->Count;
  error(sprintf('Error connecting to server: %s %s %s', 
		param('pop'), param('user'), param('pass')))
    if $count == -1;

  my @mails;
  foreach (1 .. $count) {
    my %headers;
    foreach ($pop->Head($_, 0)) {
      my ($head, $data) = split(':\s*', $_, 2);
      $data =~ s/</&lt;/g;
      $headers{$head} = $data;
    }

    $headers{Subject} = 'No subject'
      unless $headers{Subject} =~ /\S/;

    push @mails, { id => $_,
		   headers => \%headers };
  }

  $tt->process('list.tt', { mails => \@mails,
			    conn => { pop => param('pop'),
				      user => param('user'),
				      pass => param('pass') }})
    || die $tt->error;
}

sub read {
  require Mail::POP3Client;

  my $pop = Mail::POP3Client->new(HOST => param('pop'), 
				  USER => param('user'),
				  PASSWORD => param('pass'),
				  AUTH_MODE => 'PASS')
    || error(Mail::POP3Client->Message);

  print header;

  my (%headers);
  my ($head, $data);
  foreach ($pop->Head(param('id'), 0)) {
    if (/^\S/) {
      ($head, $data) = split(':\s*', $_, 2);
      $data =~ s/</&lt;/g;
      $headers{$head} = $data;
    } else {
      s/^\s+/ /;
      s/</&lt;/g;
      $headers{$head} .= $_;
    }
  }
  
  my $body = join "\n", $pop->Body(param('id'), 0);
  $body =~ s/</&lt;/g;
  
  $tt->process('read.tt', { mail => { id => param('id'), 
				      headers => \%headers,
				      body => $body },
			    conn => { pop => param('pop'),
				      user => param('user'),
				      pass => param('pass') }})
    || die $tt->error;
}

sub delete {
  require Mail::POP3Client;

  my $pop = Mail::POP3Client->new(HOST => param('pop'), 
				  USER => param('user'),
				  PASSWORD => param('pass'),
				  AUTH_MODE => 'PASS')
    || error(Mail::POP3Client->Message);

  $pop->Delete(param('id')) || error($pop->Message);
}

sub send {
  require Mail::Mailer;

  my $m = Mail::Mailer->new('sendmail');

  my %headers = ( To => [split /;/, param('to')], 
		  Cc => [split /;/, param('cc')],
		  From => param('from'),
		  Subject => param('subject'),
		  'X-Mailer' => 'ms-webmail');

  $headers{References} = param('ref') if param('ref');

  $m->open(\%headers);

  $m->print(param('body'));

  $m->close;
}

sub reply {
  require Mail::POP3Client;

  my $pop = Mail::POP3Client->new(HOST => param('pop'), 
				  USER => param('user'),
				  PASSWORD => param('pass'),
				  AUTH_MODE => 'PASS')
    || error(Mail::POP3Client->Message);

  require Text::Autoformat;
  Text::Autoformat->import;

  my (%headers);
  my ($head, $data);
  foreach ($pop->Head(param('id'), 0)) {
    if (/^\S/) {
      ($head, $data) = split(':\s*', $_, 2);
      $data =~ s/</&lt;/g;
      $headers{$head} = $data;
    } else {
      s/^\s+/ /;
      s/</&lt;/g;
      $headers{$head} .= $_;
    }
  }

  my $body = 'At ' . $headers{Date} . ", " . $headers{From} . " wrote:\n";
  $body .= join "\n", map { "> $_" } $pop->Body(param('id'), 0);
  autoformat($body);

  unless ($headers{Subject} =~ /^Re:/i) {
    $headers{Subject} = "Re: $headers{Subject}";
  }

  &compose(to => $headers{'Reply-To'} || $headers{'From'},
	   subject => $headers{'Subject'},
	   body => $body,
	   ref => $headers{'References'} . ' ' .$headers{'Message-Id'});
}

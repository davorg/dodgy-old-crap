#!/usr/local/bin/perl -w
#
# $Id: webged.pl,v 1.2 2001/09/10 17:18:04 dave Exp $
#
# Script to produce web pages based on a GEDCOM file'
#
# $Log: webged.pl,v $
# Revision 1.2  2001/09/10 17:18:04  dave
# Various fixes and enhancements.
#
# Revision 1.1  2001/09/10 16:16:31  dave
# Initial revision
#
#

use strict;
use Template;

my $VERSION = sprintf "%d.%02d", '$Revision: 1.2 $ ' =~ /(\d+)\.(\d+)/;

my %sex = ( M => 'Male',
	    F => 'Female',
	    U => 'Unknown' );

my $ged_base;

# Work out whether or not we've been called as a CGI script...
my $cgi = exists $ENV{DOCUMENT_ROOT};
my $href;

# ...and take appropriate action
if ($cgi) {
  require CGI;
  CGI->import(qw(param header));

  $ged_base = param('family');

  print &header;

  $href = sub {
    "webged.pl?family=$ged_base&person=" . shift;
  };
} else {
  $ged_base = shift;

  $href = sub {
    shift() . '.html';
  }
}

my $data_dir = '.';
my $dstr = "$data_dir/$ged_base.dd";
my $ged_file = "$ged_base.ged";

# Get the family data structure either by parsing the GEDCOM file
# or loading it from a prebuilt version
my $family;
if (!-f $dstr or -M $dstr > -M $ged_file) {
  $family = build_dstr($ged_base, $data_dir);
} else {
  $family = load_dstr($dstr);
}

my $tt = Template->new({INCLUDE_PATH => './tt',
			OUTPUT_PATH => "./out/$ged_base",
			PRE_PROCESS => ['main.cfg', "$ged_base.cfg", 'header'],
			POST_PROCESS => 'footer',
			VARIABLES => {version => $VERSION}});

if ($cgi) {
  # Called as a CGI script, therefore we only need to generate one
  # page. This is a person if we have a person parameter or the index
  # page otherwise
  my $person = param('person');
  my $family = param('family');

  if ($person) {
    $tt->process('person.tt', { person => $family->{people}{$person},
				href => $href })
      || die $tt->error;
  } elsif ($family) {
    $tt->process('family.tt', { family => $family->{families}{$family},
				href => $href });
  } else {
    $tt->process('index.tt', {family => $family,
			      href => $href})
      || die $tt->error;
  }
} else {
  # Called as a standalone program, therefore we need to generate
  # all pages
  $tt->process('index.tt', {family => $family,
			    href => $href}, 'index.html')
    || die $tt->error;;

  foreach (keys %{$family->{people}}) {
    $tt->process('person.tt', { person => $family->{people}{$_},
				href => $href }, "$_.html")
      || die $tt->error;
  }

  foreach (keys %{$family->{families}}) {
    $tt->process('family.tt', { family => $family->{families}{$_},
				href => $href }, "$_.html")
      || die $tt->error;
  }
}

sub build_dstr {
  my ($ged_base, $data_dir) = @_;

  require Gedcom;

  my $ged = Gedcom->new(gedcom_file => "$data_dir/$ged_base.ged");

  warn "Invalid GEDCOM file: $data_dir/$ged_file\n" 
    unless $ged->validate;

  my %family;

  foreach ($ged->individuals) {
    my $rec;

    $rec->{name} = $_->cased_name;

    $rec->{sex} = $sex{$_->sex};

    $rec->{birth}{date} = $_->get_value('birth date');
    $rec->{birth}{place} = $_->get_value('birth place');
    $rec->{death}{date} = $_->get_value('death date');
    $rec->{death}{place} = $_->get_value('death place');

    if ($_->father) {
      $rec->{father}{id} = $_->father->{xref};
      $rec->{father}{name} = $_->father->cased_name;
    }

    if ($_->mother) {
      $rec->{mother}{id} = $_->mother->{xref};
      $rec->{mother}{name} = $_->mother->cased_name;
    }

    foreach my $child ($_->children) {
      push @{$rec->{children}}, { id => $child->{xref},
				  name => $child->cased_name };
    }

    foreach my $spouse ($_->husband, $_->wife) {
      my @ind_fams = $_->fams;
      my @spo_fams = $spouse->fams;
      my (%union, %isect);

      foreach my $fam (@ind_fams, @spo_fams) {
	my $f = $fam->{xref};
	$union{$f}++ && $isect{$f}++;
      }

      push @{$rec->{spouses}}, { id => $spouse->{xref},
				 name => $spouse->cased_name,
				 fam => (keys %isect)[0] };
    }

    $family{people}{$_->{xref}} = $rec;
  }

  foreach ($ged->families) {
    my $rec;

    if ($_->husband) {
      $rec->{husband}{id} = $_->husband->{xref};
      $rec->{husband}{name} = $_->husband->cased_name;
    }

    if ($_->wife) {
      $rec->{wife}{id} = $_->wife->{xref};
      $rec->{wife}{name} = $_->wife->cased_name;
    }

    $rec->{date} = $_->get_value('marriage date');
    $rec->{place} = $_->get_value('marriage place');

    foreach my $c ($_->children) {
      push @{$rec->{children}}, { id => $c->{xref},
				  name => $c->cased_name,
				  birth => $c->get_value('birth date') || '' };
    }

    $family{families}{$_->{xref}} = $rec;
  }

  open(DSTR, ">$data_dir/$ged_base.dd")
    || die "can't open dd file for output: $!\n";

  require Data::Dumper;

  print DSTR Data::Dumper->Dump([\%family], [qw(*family)]);

  \%family;
}

sub load_dstr {
  my $dstr = shift;

  my %family;

  open(DSTR, $dstr)
    || die "Can't open dd file for input: $!\n";

  my $eval;

  {
    local $/;

    $eval = <DSTR>;
  }

  eval $eval;

  return \%family;
}

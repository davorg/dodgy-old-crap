#!/usr/bin/perl -w
use strict;

open SPAM, "$ENV{HOME}/Mail/caughtspam" or die $!;

my %count;
while (<SPAM>) {
  next unless /SPAM: Content analysis\D*(\d+\.?\d?)/;

  $count{$1}++;
}

foreach (sort {$a <=> $b} keys %count) {
  print "$_ : $count{$_}\n";
}

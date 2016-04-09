#!/usr/bin/perl -w

use strict;
use HTML::TreeBuilder;

my $file = shift || die "No file!\n";

my $t = HTML::TreeBuilder->new_from_file($file);

# Look for any header tags. That is, tags whose name matchs /^h\d/i
# The second criteria to look_up eliminates any tags that are inside
# a <div class="front">
my @h = $t->look_down( sub { $_[0]->attr('_tag') =~ /^h\d/i; }, 
		       sub { ! $_[0]->look_up( sub { $_[0]->attr('_tag') eq 'div' && $_[0]->attr('class') eq 'front'} ) } );

# Keep a note of the previous header level number
my ($last_i) = 0;

# Create a new <ul> ... </ul>
my $list = HTML::Element->new('ul');
my $curr_list = $list;

foreach (@h) {
  # Grab the header level number
  my ($i) = $_->attr('_tag') =~ /(\d)/;

  # Create a new <a name="..."> tag and insert at the start of the 
  # header tag
  my $a = HTML::Element->new('a', 'name' => $_->as_text);
  $_->unshift_content($a);

  # Create a new list item and a new <a href="..."> tag that references
  # the <a name="..."> tag that we created earlier.
  # Insert the <a> tag within the <li> tag.
  my $item = HTML::Element->new('li');
  my $href = HTML::Element->new('a', 'href', '#' . $_->as_text);
  $href->push_content($_->as_text);
  $item->push_content($href);

  # Build the correct structure of lists
  if ($last_i == $i) {

  } elsif ($last_i < $i) {
    my $new_list = HTML::Element->new('ul');
    $curr_list->push_content($new_list);
    $curr_list = $new_list;
  } else {
    $curr_list = $curr_list->parent;
  }

  $curr_list->push_content($item);

  $last_i = $i;
}

my $body = $t->look_down(_tag => 'div',
			 class => 'body');

die "Can't find insertion point\n" unless $body;

my $nav = HTML::Element->new('div', class => 'nav');
$nav->push_content($list);

# print $nav->as_HTML(undef, '  ');

$body->preinsert($nav);

print $t->as_HTML(undef, '  ', {});

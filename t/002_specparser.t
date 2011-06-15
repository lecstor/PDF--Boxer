#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;
use Data::Dumper;
use PDF::API2;
use XML::Simple;
use XML::Parser;

use lib 'lib';

use_ok('PDF::Boxer');
use_ok('PDF::Boxer::Doc');
use_ok('PDF::Boxer::SpecParser');

my $spec = <<'__EOP__';
<box name="Main" background="#FFBBBB" max_width="595" max_height="842">
  <box name="Header" border="1" height="80" background="lightblue">
    <box name="Header Left" padding="20" width="200">
      <text name="Text Tax Invoice" size="36" color="black">Tax Invoice</text>
    </box>
    <box name="Header Right" padding="5">
      <text name="Address1" padding="3" height="20" align="right" size="20" color="black">
        Eight Degrees Off Centre
      </text>
      <text name="Address2" padding="3" height="30" align="right" size="14" color="black">
        3 Bondi Cres, Kewarra Beach, Qld 4879
        (07) 4055 6926  enquiries@eightdegrees.com.au
      </text>
    </box>
  </box>
  <box name="Content" border="1" background="lightgreen" height="650"></box>
  <box name="Footer" background="grey" border="1"></box>
</box>
__EOP__

my $parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($spec);

#warn Data::Dumper->Dumper($spec);

my $boxer = PDF::Boxer->new({
  doc => PDF::Boxer::Doc->new({ file => 'test_invoice.pdf' }),
});

$boxer->add_to_pdf($spec);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;
use Data::Dumper;

use lib 'lib';

use_ok('PDF::Boxer');
use_ok('PDF::Boxer::Doc');
use_ok('PDF::Boxer::SpecParser');

my $spec = <<'__EOP__';
<box name="Main" max_width="595" max_height="842">
  <box name="Header" border="3" border_color="orange" pressure_height="0">
    <box name="Header Left" padding="0" width="320" border_color="blue" border="3" pressure_height="0">
      <image src="t/lecstor.gif" name="Lecstor Logo" border="3" border_color="purple" align="center" valign="center" padding="10" scale="60" />
    </box>
    <box name="Header Right" padding="10" border="3" border_color="green" pressure_height="0">
      <text name="Address1" padding="3" border="1" align="right" size="20" border_color="steelblue">
        Lecstor Pty Ltd
      </text>
      <text name="Address2" padding="3" align="right" border="3" border_color="grey" size="14" color="black">
        ABN: 13 526 716 639
        123 Example St, Somewhere, Qld 4879
        (07) 4055 6926  jason@lecstor.com
      </text>
    </box>
  </box>
  <box name="Details" border="1" height="80" border_color="red" pressure_height="0">
    <box name="Recipient" width="300" padding="20" border="1"  pressure_height="0">
      <text size="14" border="1" pressure_height="0" >
        Video Ezy Edgecliff
        Shop 1A Edgecliff Centre, New South Head Road
        Edgecliff NSW 2027
      </text>
    </box>
    <box name="Invoice" padding="20" border="1" border_color="red" pressure_height="0">
      <text size="14" align="right" border="1" pressure_height="0">
        Tax Invoice No. 242
        Issued 01/01/2011
        Due 14/01/2011
      </text>
    </box>
  </box>
</box>
__EOP__

#  <box name="Content" border="1" height="550"></box>
#  <box name="Footer" border="1"></box>

my $parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($spec);

#warn Data::Dumper->Dumper($spec);

my $boxer = PDF::Boxer->new({
  debug => 1,
  doc => PDF::Boxer::Doc->new({ file => 'test_invoice.pdf' }),
});

$boxer->add_to_pdf($spec);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

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
<box name="Main" max_width="595" max_height="842" pressure_width="1">
  <box name="Header" pressure_width="1" background="lightblue">
    <box name="Header Left" padding="0" width="320">
      <image src="t/lecstor.gif" name="Lecstor Logo" align="center" valign="center" padding="10" scale="60" />
    </box>
    <box name="Header Right" padding="10" border="0" border_color="green" pressure_width="1">
      <text name="Address1" padding="3" border="1" align="right" size="20" border_color="steelblue">
        Lecstor Pty Ltd
      </text>
      <text name="Address2" padding="3" align="right" border="0" border_color="grey" size="14" color="black">
        ABN: 12 345 678 910
        123 Example St, Somewhere, Qld 4879
        (07) 4055 6926  jason@lecstor.com
      </text>
    </box>

    <box name="Details" border="1" height="80" pressure_width="1">
      <box name="Recipient" width="300" padding="20">
        <text name="Address" size="14">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
      </box>
      <box name="Invoice" padding="20" pressure_width="1">
        <text name="Issued" size="14" align="right">
          Tax Invoice No. 123
          Issued 01/01/2011
          Due 14/01/2011
        </text>
      </box>
    </box>
  </box>
  <box name="Content" border="3" pressure_width="1" pressure_height="1"></box>
  <box name="Footer" border="3" pressure_width="1">
    <text name="FootText" size="14">
      Mr G Client
      Shop 2 Some Centre, Retail Rd
      Somewhere, NSW 2000
    </text>
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

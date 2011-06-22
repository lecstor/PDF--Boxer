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
<column name="Main" max_width="595" max_height="842">
  <column name="Header">
    <row name="Head">
      <box name="Header Left" padding="0" width="320">
        <image src="t/lecstor.gif" name="Lecstor Logo" align="center" valign="center" padding="10" scale="60" />
      </box>
      <column name="Header Right" grow="1" padding="10" border="1" border_color="green">
        <text name="Address1" padding="3" border="1" align="right" size="20" border_color="steelblue">
          Lecstor Pty Ltd
        </text>
        <text name="Address2" padding="3" align="right" border="1" border_color="grey" size="14" color="black">
          ABN: 12 345 678 910
          123 Example St, Somewhere, Qld 4879
          (07) 4055 6926  jason@lecstor.com
        </text>
      </column>
    </row>
    <row name="Details" border="1" height="80">
      <box name="Recipient" width="300" padding="20" border="1">
        <text name="Address" size="14" border="1">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
      </box>
      <box name="Invoice" class="max_width" padding="20" border="1">
        <text name="Issued" size="14" align="right" border="1">
          Tax Invoice No. 123
          Issued 01/01/2011
          Due 14/01/2011
        </text>
      </box>
    </row>
  </column>
  <grid name="Content" grow="1" border="1">
    <row name="Content Row 1">
      <text name="Content Row 1 Column1">
        blah blah
      </text>
      <text name="Content Row 1 Column2">
        blah blah blah
      </text>
      <text name="Content Row 1 Column3">
        blah blah
      </text>
      <text name="Content Row 1 Column4">
        blah blah blah blah
      </text>
      <text name="Content Row 1 Column5">
        blah blah
      </text>
    </row>
    <row name="Content Row 2">
      <text name="Content Row 2 Column1">
        blah blah
      </text>
      <text name="Content Row 2 Column2">
        blah blah
      </text>
      <text name="Content Row 2 Column3">
        blah blah blah blah blah
      </text>
      <text name="Content Row 2 Column4">
        blah blah blah blah
      </text>
      <text name="Content Row 2 Column5">
        blah blah
      </text>
    </row>
  </grid>
  <row name="Footer" class="max_width" border="1" padding="5">
    <text name="FootText" size="14">
      Mr G Client
      Shop 2 Some Centre, Retail Rd
      Somewhere, NSW 2000
    </text>
  </row>
</column>
__EOP__

#  <box name="Content" border="1" height="550"></box>
#  <box name="Footer" border="1"></box>

my $parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($spec);

#warn Data::Dumper->Dumper($spec);

my $boxer = PDF::Boxer->new({
  debug => { adjust =>  { dump => {
    Address1 => 1, Address2 => 1, 'Header Right' => 1, 'Header Left' => 1,
    Head => 1, Header => 1,
  }}},
  doc => PDF::Boxer::Doc->new({ file => 'test_invoice.pdf' }),
});

$boxer->add_to_pdf($spec);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

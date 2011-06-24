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
      <column name="Header Right" grow="1" padding="10" border_color="green">
        <text name="Address1" padding="3" align="right" size="20" border_color="steelblue">
          Lecstor Pty Ltd
        </text>
        <text name="Address2" padding="3" align="right" border_color="grey" size="14" color="black">
          ABN: 12 345 678 910
          123 Example St, Somewhere, Qld 4879
          (07) 4055 6926  jason@lecstor.com
        </text>
      </column>
    </row>
    <row name="Details">
      <box name="Recipient" width="300" padding="20">
        <text name="Address" size="14">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
      </box>
      <column name="Invoice" padding="10">
        <text name="Issued" size="16" font="Helvetica-Bold" align="right">
          Tax Invoice No. 123
        </text>
        <text name="Issued" size="14" align="right">
          Issued 01/01/2011
          Due 14/01/2011

          Page 1 of 3
        </text>
      </column>
    </row>
  </column>
  <grid name="Content" grow="1" padding="10">
    <row name="Content Row 1" padding="2" font="Helvetica-Bold">
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
      <text name="Content Row 1 Column5" align="right">
        $1999.99
      </text>
    </row>
    <row name="Content Row 2" padding="2">
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
      <text name="Content Row 2 Column5" align="right">
        $999.99
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
  doc => PDF::Boxer::Doc->new({ file => 'test_specparser.pdf' }),
});

$boxer->add_to_pdf($spec);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

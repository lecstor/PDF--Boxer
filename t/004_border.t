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
<doc name="Main" max_width="595" max_height="842">

  <column name="BORDER 2" border="2" border_color="red">

    <text border="2" border_color="green">
      PDF::Boxer
    </text>

    <text align="center" border="2" border_color="blue">
      PDF::Boxer
    </text>

    <text align="right" border_color="green" padding="10 20">
      PDF::Boxer
    </text>

    <column grow="1">
      <text grow="1"></text>
      <text align="center">
        PDF::Boxer
        multi
        line
      </text>
      <text grow="1"></text>
    </column>

    <row border="5" border_color="purple" margin="5 10 0 10">
      <text border="1" border_color="orange" padding="10 5">
        PDF::Boxer
      </text>
      <text align="center" border="1" border_color="orange" padding="10">
        PDF::Boxer
      </text>
    </row>

  </column>

  <column>
    <text align="center">
      PDF::Boxer
    </text>
  </column>

  <column>
    <text align="center" valign="center">
      PDF::Boxer
    </text>
  </column>

</doc>
__EOP__

my $parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($spec);

#warn p($parser->xml_parser->parse($spec));
#warn p($spec);
#exit;

#warn Data::Dumper->Dumper($spec);

my $boxer = PDF::Boxer->new( doc => { file => 'test_layout.pdf' } );

$boxer->add_to_pdf($spec);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

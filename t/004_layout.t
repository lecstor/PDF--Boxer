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

  <column name="Page" border="1">

    <row name="Header">
      <text border="1" padding="10">
        Header Text Left
      </text>
      <text align="center" border="1" border_color="green" grow="1" padding="10">
        Header Text Right Centered
      </text>
    </row>

    <row name="Content" grow="1">
      <column grow="1">
        <text padding="10">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam feugiat suscipit magna vel scelerisque. Morbi at lacus et dui consectetur lacinia in non quam. Morbi nec mi eget turpis facilisis auctor. Etiam vitae nunc lorem. Vivamus commodo tellus vitae orci vehicula blandit fermentum tellus gravida. Nullam tincidunt nunc id tortor fringilla id consequat tortor ultricies. Duis sit amet purus eu lorem posuere congue sit amet sed ante. Vivamus accumsan mattis luctus.

          Fusce pharetra nunc vitae odio varius ac feugiat metus luctus. Sed pulvinar placerat enim, a viverra lectus dictum at. Sed faucibus, libero sit amet tristique fringilla, sapien purus sollicitudin mauris, ut tincidunt neque tellus sed dui. Proin fringilla viverra mauris, non malesuada purus ultricies non. Aenean enim purus, convallis nec adipiscing et, blandit ac risus. Fusce eu cursus velit. Maecenas blandit sem vel tortor iaculis venenatis. Vestibulum fermentum lacus eu enim vulputate ultricies sed ac odio. Sed aliquam lobortis hendrerit. Praesent turpis justo, laoreet nec sollicitudin ut, feugiat nec est. Suspendisse scelerisque euismod turpis ut vulputate.

          Etiam interdum urna quis mi convallis congue. Nam tortor eros, interdum eu imperdiet in, ullamcorper mollis nibh. Proin ac molestie libero. Aenean mollis leo vehicula metus fermentum dictum. Integer eros lacus, posuere a rutrum nec, adipiscing id dui. Donec facilisis justo vitae tellus hendrerit blandit. Donec vehicula venenatis lectus eu ornare. Aenean consequat dictum felis, nec lobortis nulla congue sed.

        </text>
      </column>

      <column width="200">
        <text align="center" padding="10">
          Lorem ipsum
          dolor sit amet,
          consectetur
          adipiscing elit.
        </text>
        <text align="center" padding="10">
          Fusce pharetra
          nunc vitae odio
          varius ac
          feugiat metus
          luctus.
        </text>
        <text align="center" padding="10">
          Etiam interdum
          urna quis mi
          convallis congue.
          Nam tortor eros,
          interdum eu
          imperdiet in,
          ullamcorper
          mollis nibh.
        </text>
      </column>
    </row>

    <row name="Footer">
      <text border="1" padding="10">
        Footer Text Left
      </text>
      <text align="center" border="1" border_color="green" grow="1" padding="10">
        Footer Text Right Centered
      </text>
    </row>

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

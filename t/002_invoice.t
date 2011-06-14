#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;
use PDF::API2;

use lib 'lib';

use_ok('PDF::Boxer');
use_ok('PDF::Boxer::Doc');

my $box = {
  name => 'Main',
  background => '#FFBBBB',
  max_width => '595',
  max_height => '842',
  contents => [
    {
      name => 'Header',
#      margin => 5,
      border => 1,
#      padding => 7,
      height => 80,
      display => 'block',
      background => 'lightblue',
#      width => 380,
      contents => [
        {
          name => 'Header Left',
          margin => 0,
          border => 1,
          padding => 20,
          width => 200,
          contents => [
            { type => 'Text', name => 'Text Tax Invoice', value => ['Tax Invoice'], size => 36, color => 'black' },
          ],
        },
        {
          name => 'Header Right',
          border => 1,
          padding => 2,
          display => 'block',
          contents => [
            {
              type => 'Text', display => 'block',
              name => 'Text Header Address1',
              align => 'right',
              value => ['Eight Degrees Off Centre'],
              size => 20, color => 'black',
              border => 1,
            },
            {
              type => 'Text', display => 'block',
              name => 'Text Header Address2',
              border => 1,
              align => 'right', value => [
                '3 Bondi Cres, Kewarra Beach, Qld 4879',
                '(07) 4055 6926  enquiries@eightdegrees.com.au',
              ], size => 14, color => 'black'
            },
          ],
        },
      ]
    },
  ],
};

my $boxer = PDF::Boxer->new({
  doc => PDF::Boxer::Doc->new({ file => 'test_invoice.pdf' }),
});

$boxer->add_to_pdf($box);

$boxer->doc->pdf->save;
$boxer->doc->pdf->end();

done_testing();

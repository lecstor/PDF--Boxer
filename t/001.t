#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;
use PDF::API2;

use lib 'lib';

use_ok('PDF::Box');
use_ok('PDF::Box::Doc');

my $doc = PDF::Box::Doc->new({ file => 'test.pdf' });

my $bus = [
  '3 Bondi Cres, Kewarra Beach, Qld 4879',
  '(07) 4055 6926  enquiries@eightdegrees.com.au',
];

my $box = PDF::Box->new({
  debug => 1,
  doc => $doc,
  background => '#FFBBBB',
  contents => [
    {
#      margin => 5,
      border => 2,
#      padding => 7,
      height => 80,
      display => 'block',
      background => 'lightblue',
#      width => 380,
      contents => [
        {
          margin => 5,
          border => 0,
          padding => 20,
          width => 250,
          contents => [
            {
#              width => "300",
              contents => [
                { type => 'Text', value => ['Tax Invoice'], size => 36, color => 'black' },
              ],
            },
          ],
        },
        {
          margin => 0,
          border => 0,
          padding => 10,
          display => 'block',
#          width => 300,
          contents => [
            {
#              width => "300",
              contents => [
                { type => 'Text', align => 'right', value => ['Eight Degrees Off Centre'], size => 20, color => 'black' },
                { type => 'Text', align => 'right', value => $bus, size => 14, color => 'black' },
              ],
            },
          ],
        },
      ]
    },
    {
      margin => 5,
      border => 5,
      height => 50,
      background => 'green',
      padding => 7,
      width => 200,
      contents => [
        {
          width => "300",
          contents => [
            { type => 'Text', align => 'centre', value => ['Tgax Invoice'], size => 26, color => 'white' },
          ],
        },
      ],
    },
  ],
});

#print p($box)."\n";


ok( $box, 'new box' );

$box->render(0,842);

#print p($box)."\n";
#print p($_)."\n" foreach @{$box->contents};

$doc->pdf->save;
$doc->pdf->end();



done_testing();

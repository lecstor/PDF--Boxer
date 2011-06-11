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

my $box = PDF::Box->new({
  debug => 1,
  doc => $doc,
  contents => [
    {
      margin => 5,
      border => 1,
      height => 50,
      background => 'blue',
      padding => 7,
      contents => [
        {
          width => "300",
          contents => [
            { type => 'Text', align => 'centre', value => 'Tax Invoice' },
          ],
        },
      ],
    },
  ],
});

ok( $box, 'new box' );

$box->inflate;
$box->render;

print p($box)."\n";
print p($_)."\n" foreach @{$box->contents};

$doc->pdf->save;
$doc->pdf->end();



done_testing();

#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;


use lib 't/lib';
use lib 'lib';

use_ok('PDF::Boxer::Size');

my $size = PDF::Boxer::Size->new({
  max_height => 150,
  max_width => 100,
});
ok( $size, 'new model' );
is( $size->width, 100, 'width' );
is( $size->height, 150, 'height' );
is( $size->padding_width, 100, 'padding_width' );
is( $size->padding_height, 150, 'padding_height' );
is( $size->border_width, 100, 'border_width' );
is( $size->border_height, 150, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

$size = PDF::Boxer::Size->new({
  max_height => 150,
  max_width => 100,
  margin => [10,10,10,10],
});
ok( $size, 'new model' );
is( $size->width, 80, 'width' );
is( $size->height, 130, 'height' );
is( $size->padding_width, 80, 'padding_width' );
is( $size->padding_height, 130, 'padding_height' );
is( $size->border_width, 80, 'border_width' );
is( $size->border_height, 130, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

$size = PDF::Boxer::Size->new({
  max_height => 150,
  max_width => 100,
  margin => [10,10,10,10],
  padding => [10,10,10,10],
});
ok( $size, 'new model' );
is( $size->width, 60, 'width' );
is( $size->height, 110, 'height' );
is( $size->padding_width, 80, 'padding_width' );
is( $size->padding_height, 130, 'padding_height' );
is( $size->border_width, 80, 'border_width' );
is( $size->border_height, 130, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

$size = PDF::Boxer::Size->new({
  max_height => 150,
  max_width => 100,
  margin => [10,10,10,10],
  padding => [10,10,10,10],
  border => [5,5,5,5],
});
ok( $size, 'new model' );
is( $size->width, 50, 'width' );
is( $size->height, 100, 'height' );
is( $size->padding_width, 70, 'padding_width' );
is( $size->padding_height, 120, 'padding_height' );
is( $size->border_width, 80, 'border_width' );
is( $size->border_height, 130, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

$size = PDF::Boxer::Size->new({
  max_height => 150,
  max_width => 100,
  margin => [10,5,10,5],
  padding => [5,10,5,10],
  border => [5,5,5,5],
});
ok( $size, 'new model' );
is( $size->width, 60, 'width' );
is( $size->height, 110, 'height' );
is( $size->padding_width, 80, 'padding_width' );
is( $size->padding_height, 120, 'padding_height' );
is( $size->border_width, 90, 'border_width' );
is( $size->border_height, 130, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

$size = PDF::Boxer::Size->new({
  max_height => 200,
  max_width => 150,
  height => 110,
  width => 60,
  margin => [10,5,10,5],
  padding => [5,10,5,10],
  border => [5,5,5,5],
});
ok( $size, 'new model' );
is( $size->width, 60, 'width' );
is( $size->height, 110, 'height' );
is( $size->padding_width, 80, 'padding_width' );
is( $size->padding_height, 120, 'padding_height' );
is( $size->border_width, 90, 'border_width' );
is( $size->border_height, 130, 'border_height' );
is( $size->margin_width, 100, 'margin_width' );
is( $size->margin_height, 150, 'margin_height' );

#print p($size)."\n";


done_testing();

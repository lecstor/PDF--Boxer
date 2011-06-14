#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;


use lib 't/lib';
use lib 'lib';

use_ok('PDF::Boxer::Position');

my $pos = PDF::Boxer::Position->new({
  margin_left => 0,
  margin_top => 0,
});
ok( $pos, 'new pos' );

is( $pos->margin_left, 0, 'margin_left' );
is( $pos->margin_top, 0, 'margin_top' );
is( $pos->border_left, 0, 'border_left' );
is( $pos->border_top, 0, 'border_top' );
is( $pos->padding_left, 0, 'padding_left' );
is( $pos->padding_top, 0, 'padding_top' );
is( $pos->content_left, 0, 'content_left' );
is( $pos->content_top, 0, 'content_top' );

$pos = PDF::Boxer::Position->new({
  margin_left => 0,
  margin_top => 0,
  margin => [3,3,3,3],
  border => [5,5,5,5],
  padding => [7,7,7,7],
});
ok( $pos, 'new pos' );

is( $pos->margin_left, 0, 'margin_left' );
is( $pos->margin_top, 0, 'margin_top' );
is( $pos->border_left, 3, 'border_left' );
is( $pos->border_top, -3, 'border_top' );
is( $pos->padding_left, 8, 'padding_left' );
is( $pos->padding_top, -8, 'padding_top' );
is( $pos->content_left, 15, 'content_left' );
is( $pos->content_top, -15, 'content_top' );

#print p($pos)."\n";


done_testing();

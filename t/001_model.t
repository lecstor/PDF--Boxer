#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;


use lib 'lib';

use_ok('PDF::Box::Model');

my $model = PDF::Box::Model->new({
  max_height => 150,
  max_width => 100,
});
ok( $model, 'new model' );
is( $model->width, 100, 'width' );
is( $model->height, 150, 'height' );
is( $model->padding_width, 100, 'padding_width' );
is( $model->padding_height, 150, 'padding_height' );
is( $model->border_width, 100, 'border_width' );
is( $model->border_height, 150, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

$model = PDF::Box::Model->new({
  max_height => 150,
  max_width => 100,
  margin => 10,
});
ok( $model, 'new model' );
is( $model->width, 80, 'width' );
is( $model->height, 130, 'height' );
is( $model->padding_width, 80, 'padding_width' );
is( $model->padding_height, 130, 'padding_height' );
is( $model->border_width, 80, 'border_width' );
is( $model->border_height, 130, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

$model = PDF::Box::Model->new({
  max_height => 150,
  max_width => 100,
  margin => 10,
  padding => 10,
});
ok( $model, 'new model' );
is( $model->width, 60, 'width' );
is( $model->height, 110, 'height' );
is( $model->padding_width, 80, 'padding_width' );
is( $model->padding_height, 130, 'padding_height' );
is( $model->border_width, 80, 'border_width' );
is( $model->border_height, 130, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

$model = PDF::Box::Model->new({
  max_height => 150,
  max_width => 100,
  margin => 10,
  padding => 10,
  border => 5,
});
ok( $model, 'new model' );
is( $model->width, 50, 'width' );
is( $model->height, 100, 'height' );
is( $model->padding_width, 70, 'padding_width' );
is( $model->padding_height, 120, 'padding_height' );
is( $model->border_width, 80, 'border_width' );
is( $model->border_height, 130, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

$model = PDF::Box::Model->new({
  max_height => 150,
  max_width => 100,
  margin => '10 5',
  padding => '5 10',
  border => 5,
});
ok( $model, 'new model' );
is( $model->width, 60, 'width' );
is( $model->height, 110, 'height' );
is( $model->padding_width, 80, 'padding_width' );
is( $model->padding_height, 120, 'padding_height' );
is( $model->border_width, 90, 'border_width' );
is( $model->border_height, 130, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

$model = PDF::Box::Model->new({
  max_height => 200,
  max_width => 150,
  height => 110,
  width => 60,
  margin => '10 5',
  padding => '5 10',
  border => 5,
});
ok( $model, 'new model' );
is( $model->width, 60, 'width' );
is( $model->height, 110, 'height' );
is( $model->padding_width, 80, 'padding_width' );
is( $model->padding_height, 120, 'padding_height' );
is( $model->border_width, 90, 'border_width' );
is( $model->border_height, 130, 'border_height' );
is( $model->margin_width, 100, 'margin_width' );
is( $model->margin_height, 150, 'margin_height' );

#print p($model)."\n";


done_testing();

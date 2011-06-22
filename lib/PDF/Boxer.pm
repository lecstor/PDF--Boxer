package PDF::Boxer;
use Moose;
use namespace::autoclean;

use PDF::Boxer::Content::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::Image;
use PDF::Boxer::Content::Row;
use PDF::Boxer::Content::Column;
use PDF::Boxer::Content::Grid;
use Try::Tiny;
use DDP;
use Scalar::Util qw/weaken/;

has 'debug'   => ( isa => 'HashRef', is => 'ro', default => sub{{}} );

has 'doc' => ( isa => 'Object', is => 'ro' );

has 'content_margin_left' => ( isa => 'Int', is => 'rw', default => 0 );
has 'content_margin_top'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_content_margin_top{ shift->max_height }

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

has 'sibling_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_sibling_box' ); 

has 'box_stack' => ( isa => 'ArrayRef', is => 'ro', default => sub{[]} ); 

sub parent_box{
  my ($self) = @_;
  return $self->box_stack->[0];
}

sub add_to_pdf{
  my ($self, $spec) = @_;

  my $weak_me = $self;
  weaken($weak_me);
  $spec->{boxer} = $weak_me;
  $spec->{debug} = $self->debug;

  my $class = 'PDF::Boxer::Content::'.$spec->{type};
  my $node = $class->new($spec);
  $node->calculate_minimum_size;
  $node->size_and_position;

  $node->render;
  return $node;
}



=head1 NAME

PDF::Boxer

=head1 SYNOPSIS

  $boxer = PDF::Boxer->new({
    doc => PDF::Boxer::Doc->new({ file => 'test.pdf' }),
  });

  $box => {
    max_width => '595',
    max_height => '842',
    contents => [
      {
        padding => 5,
        height => 80,
        display => 'block',
        background => 'lightblue',
        contents => [
          {
            margin => '10 5',
            border => 1,
            padding => '5 10 15 20',
            width => 200,
            contents => [
              {
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
            contents => [
              {
                contents => [
                  { type => 'Text', align => 'right', value => ['Eight Degrees Off Centre'], size => 20, color => 'black' },
                  { type => 'Text', align => 'right', value => [
                    '3 Bondi Cres, Kewarra Beach, Qld 4879',
                    '(07) 4055 6926  enquiries@eightdegrees.com.au'], size => 14, color => 'black' },
                ],
              },
            ],
          },
        ]
      },
    ],
  };

  $boxer->add_to_pdf($box);

=head1 DESCRIPTION

Use a type of "box model" layout to create PDFs.

=head1 BOX NOTES

=cut

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut



























package PDF::Boxer;
use Moose;
use namespace::autoclean;

use PDF::Boxer::Doc;
use PDF::Boxer::Content::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::TextBlock;
use PDF::Boxer::Content::Image;
use PDF::Boxer::Content::Row;
use PDF::Boxer::Content::Column;
use PDF::Boxer::Content::Grid;
use Try::Tiny;
use DDP;
use Scalar::Util qw/weaken/;

has 'debug'   => ( isa => 'HashRef', is => 'ro', default => sub{{}} );

has 'doc' => ( isa => 'Object', is => 'ro' );

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

has 'box_register' => ( isa => 'HashRef', is => 'ro', default => sub{{}} ); 

sub register_box{
  my ($self, $box) = @_;
  return unless $box->name;
  weaken($box);
  $self->box_register->{$box->name} = $box;
}

sub box_lookup{
  my ($self, $name) = @_;
  return $self->box_register->{$name};
}

sub add_to_pdf{
  my ($self, $spec) = @_;

  my $weak_me = $self;
  weaken($weak_me);
  $spec->{boxer} = $weak_me;
  $spec->{debug} = $self->debug;

  my $class = 'PDF::Boxer::Content::'.$spec->{type};
  my $node = $class->new($spec);
  $self->register_box($node);
  $node->initialize;
#  $node->ruler_h;
  $node->render;
  return $node;
}

__PACKAGE__->meta->make_immutable;

1;

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

=head1 METHODS

=item add_to_pdf

  $boxer->add_to_pdf($spec);

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut



























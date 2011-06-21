package PDF::Boxer;
use Moose;
use namespace::autoclean;

use PDF::Boxer::Content::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::Image;
use PDF::Boxer::Content::Row;
use PDF::Boxer::Content::Column;
use Try::Tiny;
use DDP;
use Scalar::Util qw/weaken/;

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );

has 'doc' => ( isa => 'Object', is => 'ro' );

has 'content_margin_left' => ( isa => 'Int', is => 'rw', default => 0 );
has 'content_margin_top'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_content_margin_top{ shift->max_height }

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

#has 'parent_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_parent_box' ); 
has 'sibling_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_sibling_box' ); 

has 'box_stack' => ( isa => 'ArrayRef', is => 'ro', default => sub{[]} ); 

sub parent_box{
  my ($self) = @_;
  return $self->box_stack->[0];
}

sub add_to_pdf{
  my ($self, $spec) = @_;

warn p($spec);

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

sub inflate{
  my ($self, $spec, $parent, $older) = @_;

#  $spec->{parent} = $weak_parent;

  my $class = 'PDF::Boxer::Content::'.$spec->{type};
  my $node = $class->new($spec);



  my $contents = delete $spec->{contents};

#  my $parent = $self->parent_box;
  if ($parent){
    my $weak_parent = $parent;
    weaken($weak_parent); 
    $spec->{parent} = $weak_parent;
    $spec->{max_width}   = $parent->width;
    $spec->{max_height}  = $parent->height;
    $spec->{margin_left} = $parent->content_left;
    $spec->{margin_top}  = $parent->content_top;

    if ($older){
      if ($older->pressure_width){
        my $margin_top = $older->margin_bottom - 1;
        $margin_top = 0 if $margin_top < 0;
        $spec->{margin_top} = $margin_top;
      } else {
        my $max_width = $parent->width - $older->margin_right - 1;
        $max_width = 0 if $max_width < 0;
        $spec->{max_width}   = $max_width;
        $spec->{margin_left} = $older->margin_right + 1;
      }
    }

  } else {
    $spec->{max_width}   = $self->max_width;
    $spec->{max_height}  = $self->max_height;
    $spec->{margin_left} = 0;
    $spec->{margin_top}  = $self->max_height;
  }

  $spec->{debug} = $self->debug;
  $spec->{boxer} = $self;

  $spec->{older} = $older if $older;

  $class = 'PDF::Boxer::Content::'.$spec->{type};

#  warn "Create Node with Spec:\n".p($spec)."\n";
#  warn "Create Node with Spec:\n".Data::Dumper->Dumper($spec)."\n";

  $node = $class->new($spec);
  warn sprintf "\n\nFresh Node: %s\n", $node->name;
  $node->dump_all;

#  $parent->add_to_children($node) if $parent;

  $node->auto_adjust('child');
  warn sprintf "\n\nAdjust Fresh Node: %s\n", $node->name;
  $node->dump_all;

  my $child;
  foreach(@$contents){
    $child = $self->inflate($_, $node, $child);
    $node->add_to_children($child);
  }

  my $younger;    
  foreach my $node (reverse @{$node->children}){
    if ($younger){
      my $weak_younger = $younger;
      weaken($weak_younger); 
      $node->younger($weak_younger);
    }
    $younger = $node;
  }

  return $node;

}

sub auto_adjust{
  my ($self, $node, $type) = @_;
  $node->auto_adjust($type);
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



























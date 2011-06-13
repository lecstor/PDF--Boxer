package PDF::Box;
use Moose;
use namespace::autoclean;

with 'PDF::Box::Role::BoxModel';

use PDF::Box::Content::Text;

use constant DBG => 1;

has 'doc' => ( isa => 'Object', is => 'ro' );
has 'debug' => ( isa => 'Bool', is => 'ro' );

has 'background' => ( isa => 'Str', is => 'ro' );
has 'display' => ( isa => 'Str', is => 'ro' );



# do we minimise width and height around content
# or fill the available space?
has 'minimise_width' => ( isa => 'Bool', is => 'ro', default => 0 );
has 'minimise_height' => ( isa => 'Bool', is => 'ro', default => 1 );

has 'contents' => ( isa => 'ArrayRef', is => 'ro' );

has 'start_x' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'start_y' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
# default to starting at top left of box.
sub _build_start_x{ 0 }
sub _build_start_y{
  my ($self) = @_;
  my $y = $self->max_height;
  warn "start_y: $y\n" if DBG;
  return $y;
}

has 'x' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'y' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_x{
  my ($self) = @_;
  my $x = $self->start_x + $self->margin + $self->border + $self->padding;
  warn "x: $x\n" if DBG;
  return $x;
}
sub _build_y{
  my ($self) = @_;
  my $y = $self->start_y - $self->margin - $self->border - $self->padding;
  warn "y: $y\n" if DBG;
  return $y;
}

has 'content_x' => ( isa => 'Num', is => 'rw' );
has 'content_y' => ( isa => 'Num', is => 'rw' );

sub render{
  my ($self, $x, $y) = @_;

  $self->start_x($x) if defined $x;
  $self->start_y($y) if defined $y;

  my $border_x = $x + $self->margin->[3];
warn "##### x: $x";
warn "##### border x: $border_x";
  my $border_y = $y - $self->margin_height;

  my $gfx = $self->doc->gfx;

    $gfx->linewidth(1);
    $gfx->strokecolor('blue');
    $gfx->move($x, $y);
    $gfx->line($x+3, $y);
    $gfx->stroke;
    $gfx->move($x, $y);
    $gfx->line($x, $y-3);
    $gfx->stroke;

  warn sprintf 'fill: %s x: %s y: %s rect: %s %s %s %s',
    $self->background, $x, $y, $border_x, $border_y, $self->border_width, $self->border_height
    if $self->debug;

  if ($self->background){
    $gfx->fillcolor($self->background);
    $gfx->rect($border_x, $border_y, $self->border_width, $self->border_height);
    $gfx->fill;
  }

  if (my $width = $self->border->[0]){
    $gfx->linewidth($width);
    $gfx->strokecolor('black');
    $gfx->rect($border_x, $border_y, $self->border_width, $self->border_height);
    $gfx->stroke;
  }

  $self->content_x($self->start_x - 1 + $self->margin->[3] + $self->border->[3] + $self->padding->[3]);
  $self->content_y($self->start_y + 1 - ($self->margin->[0] + $self->border->[0] + $self->padding->[0]));

  if ($self->contents){
    foreach(@{$self->contents}){
      $_ = $self->inflate_content($_);
      my ($x,$y) = $_->render($self->content_x,$self->content_y);
      $self->content_x($x);
      $self->content_y($y);
    }
  }

  my ($return_x, $return_y);
  if ($self->display eq 'block'){
    $return_x = $self->start_x;
    $return_y = $self->start_y - $self->margin_height;
  } else {
    $return_x = $self->start_x + $self->margin_width + 1;
    $return_y = $self->start_y;
  }

  return ($return_x, $return_y);
}

sub add_to_contents{
  my ($self, $content) = @_;
  $content = $self->inflate_content($content);
  push(@{$self->contents}, $content);
  return $content;
}

sub inflate_content{
  my ($self, $content) = @_;
  my $type = 'String';
  if (ref $content eq 'HASH'){
    $type = delete $content->{type};
  }

  my $args = {
#########################################################
    start_x => 0,
    start_y => 0,
    max_width => $self->width,
    max_height => $self->height,
#########################################################
    doc => $self->doc,
    debug => $self->debug,
    %$content
  };

  # assume it's a box by default
  if (!defined $type || !$type || $type eq 'Box'){
    return $self->new($args);
  }
  if ($type =~ s/^\+//){
    return $type->new($args);
  }
  $type = 'PDF::Box::Content::'.$type;
  return $type->new($args);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

PDF::Box

=head1 DESCRIPTION

Define a box which can be added to a PDF::API2 page.
A Box's contents may be text, images, or other boxes..

=head1 SYNOPSIS

  $box = PDF::Box->new({
    border => 1,
    contents => [
      {
        width => "50%",
        contents => [
          { type => 'text', align => 'centre', value => 'Tax Invoice' },
        ],
      },
      {
        contents => [
          {
            type => 'text', align => 'centre', value => [
              'EDOC',
              '123 Some St, Somewhere, Qld 4879',
              'Australia',
            ],
          }
        ],
      },
    }
  });

  $pdf = PDF::API2->new( -file => 'my.pdf' );


=cut

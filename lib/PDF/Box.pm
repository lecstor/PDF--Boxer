package PDF::Box;
use Moose;
use namespace::autoclean;

use PDF::Box::Content::Text;

use constant DBG => 1;

has 'doc' => ( isa => 'Object', is => 'ro' );
has 'debug' => ( isa => 'Bool', is => 'ro' );

has 'border'   => ( isa => 'Int', is => 'ro', default => 0 );
has 'padding'  => ( isa => 'Int', is => 'ro', default => 0 );
has 'margin'   => ( isa => 'Int', is => 'ro', default => 0 );
has 'background' => ( isa => 'Str', is => 'ro' );

has 'width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_width{ shift->available_width }
sub _build_height{ shift->available_height }


# do we minimise width and height around content
# or fill the available space?
has 'minimise_width' => ( isa => 'Bool', is => 'ro', default => 0 );
has 'minimise_height' => ( isa => 'Bool', is => 'ro', default => 1 );

has 'contents' => ( isa => 'ArrayRef', is => 'ro' );

# total space available to this box
has 'available_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'available_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_available_width{
  my ($self) = @_;
  my $width = $self->doc->page_width;
  warn "available_width: $width\n" if DBG;
  return $width;
}
sub _build_available_height{
  my ($self) = @_;
  my $height = $self->doc->page_height;
  warn "available_height: $height\n" if DBG;
  return $height;
}

# outer edge of margin 
has 'outer_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'outer_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_outer_width{
  my ($self) = @_;
  my $width = 0;
  # width has been set manually
  $width = $self->width if $self->width;
  # do we have enough room for the specified width;
  $width = $self->available_width if $width > $self->available_width;
  $width ||= $self->available_width;
  warn "outer_width: $width\n" if DBG;
  return $width;
}
sub _build_outer_height{
  my ($self) = @_;
  my $height = 0;
  # height has been set manually
  $height = $self->height if $self->height;
  # do we have enough room for the specified height;
  $height = $self->available_height if $height > $self->available_height;
  $height ||= $self->available_height;
  warn "outer_hight: $height\n" if DBG;
  return $height;
}

# border lengths 
has 'border_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_border_width{
  my ($self) = @_;
  my $width = $self->outer_width - ($self->margin*2);
  warn "border_width: $width\n" if DBG;
  return $width;
}
sub _build_border_height{
  my ($self) = @_;
  my $height = $self->outer_height - ($self->margin*2);
  warn "border_height: $height\n" if DBG;
  return $height;
}

# inner width of padding
has 'inner_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'inner_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_inner_width{
  my ($self) = @_;
  my $width = $self->outer_width - (($self->margin + $self->border + $self->padding)*2);
  warn "inner_width: $width\n" if DBG;
  return $width;
}
sub _build_inner_height{
  my ($self) = @_;
  my $height = $self->outer_height - (($self->margin + $self->border + $self->padding)*2);
  warn "inner_height: $height\n" if DBG;
  return $height;
}

has 'start_x' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'start_y' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
# default to starting at top left of box.
sub _build_start_x{ 0 }
sub _build_start_y{
  my ($self) = @_;
  my $y = $self->available_height;
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

has 'content_x' => ( isa => 'Int', is => 'rw' );
has 'content_y' => ( isa => 'Int', is => 'rw' );


sub inflate{
  my ($self) = @_;
  my ($x,$y) = $self->render(0,842);
#  $self->content_x($x);
#  $self->content_y($y);


  if ($self->contents){
    foreach(@{$self->contents}){
      $_ = $self->inflate_content($_);
#      my ($x,$y) = $_->render($self->content_x,$self->content_y);
      ($x,$y) = $_->render($x,$y);
#      $self->content_x($x);
#      $self->content_y($y);
    }
  }
}

sub render{
  my ($self, $x, $y) = @_;

  $self->start_x($x) if defined $x;
  $self->start_y($y) if defined $y;

  my $border_x = $x + $self->margin;
  my $border_y = $y - $self->margin - $self->border_height;

  my $gfx = $self->doc->gfx;

  warn sprintf 'fill: %s x: %s y: %s rect: %s %s %s %s',
    $self->background, $x, $y, $border_x, $border_y, $self->border_width, $self->border_height
    if $self->debug;

  if ($self->border || $self->background){
    $gfx->rect($border_x, $border_y, $self->border_width, $self->border_height);
    #          left       bottom                  width         height
  }

  if ($self->background){
    $gfx->fillcolor($self->background);
#    $gfx->rect($self->x, $self->y-$self->available_height, $self->width, $self->height);
    #          left      bottom                            width         height
    $gfx->fill;
  }

  if (my $width = $self->border){
    $gfx->linewidth($width);
    $gfx->strokecolor('black');
    $gfx->stroke;
  }

  $x += $self->padding;
  $y -= $self->padding;

  if ($self->contents){
    foreach(@{$self->contents}){
      $_ = $self->inflate_content($_);
#      my ($x,$y) = $_->render($self->content_x,$self->content_y);
      ($x,$y) = $_->render($x,$y);
#      $self->content_x($x);
#      $self->content_y($y);
    }
  }

  return (
    $self->start_x + $self->outer_width, #self->x + $self->margin + $self->border + $self->padding,
    $self->start_y, # - $self->margin - $self->border - $self->padding
  );
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
    available_width => $self->inner_width,
    available_height => $self->inner_height,
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

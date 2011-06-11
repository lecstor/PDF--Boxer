package PDF::Box;
use Moose;
use namespace::autoclean;

use PDF::Box::Content::Text;

has 'doc' => ( isa => 'Object', is => 'ro' );
has 'debug' => ( isa => 'Bool', is => 'ro' );

has 'border'   => ( isa => 'Int', is => 'ro' );
has 'padding'  => ( isa => 'Int', is => 'ro', default => 0 );
has 'margin'   => ( isa => 'Int', is => 'ro', default => 0 );
has 'background' => ( isa => 'Str', is => 'ro' );

has 'contents' => ( isa => 'ArrayRef', is => 'ro' );

has 'width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_width{ shift->available_width }
sub _build_height{ shift->available_height }

has 'available_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'available_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_available_width{ shift->doc->page_width }
sub _build_available_height{ shift->doc->page_height }

has 'available_inner_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'available_inner_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_available_inner_width{
  my ($self) = @_;
  return $self->available_width - (($self->margin + $self->border + $self->padding)*2);
}
sub _build_available_inner_height{
  my ($self) = @_;
  return $self->available_height - (($self->margin + $self->border + $self->padding)*2);
}

has 'start_x' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'start_y' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
# default to starting at top left of box.
sub _build_start_x{ 0 }
sub _build_start_y{ shift->available_height }

has 'x' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'y' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_x{
  my ($self) = @_;
  return $self->start_x + $self->margin + $self->border + $self->padding;
}
sub _build_y{
  my ($self) = @_;
  return $self->start_y - $self->margin - $self->border - $self->padding;
}

sub inflate{
  my ($self) = @_;
  if ($self->contents){
    foreach(@{$self->contents}){
      $_ = $self->inflate_content($_);
      $_->render;
    }
  }
}

sub render{
  my ($self) = @_;
  my $gfx = $self->doc->gfx;

  if ($self->background){
    warn sprintf 'fill: %s y: %s rect: %s %s %s %s',
      $self->background, $self->y, $self->x, $self->y-$self->height, $self->width, $self->height
      if $self->debug;
    $gfx->fillcolor($self->background);
    $gfx->rect($self->x, $self->y-$self->height, $self->width, $self->height);
    #          left      bottom                  width         height
    $gfx->fill;
  }

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
  # assume it's a box by default
  if (!defined $type || !$type || $type eq 'Box'){
    return $self->new({
#########################################################
      start_x => 0,
      start_y => 0,
      available_width => $self->available_inner_width,
      available_height => $self->available_inner_height,
#########################################################
      doc => $self->doc,
      debug => $self->debug,
      %$content
    });
  }
  if ($type =~ s/^\+//){
    return $type->new($content);
  }
  $type = 'PDF::Box::Content::'.$type;
  return $type->new($content);
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

package PDF::Boxer::Content::Image;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Box';

#has 'img_width' => ( isa => 'Int', is => 'ro' );
#has 'img_height' => ( isa => 'Int', is => 'ro' );
has 'src' => ( isa => 'Str', is => 'ro' );
has 'scale' => ( isa => 'Num', is => 'ro' );
has 'format' => ( isa => 'Str', is => 'ro', lazy_build => 1 );

has 'align' => ( isa => 'Str', is => 'ro' );
has 'valign' => ( isa => 'Str', is => 'ro' );


sub _build_format{
  my ($self) = @_;
  return unless $self->src;
  my ($ext) = $self->src =~ /\.([^\.]+)$/;
  return $ext;
}

around 'render' => sub{
  my ($orig, $self) = @_;

  die $self->src.": $!" unless -f $self->src;

  $self->dump_all;

  my $pdf = $self->boxer->doc->pdf;
  my $method = 'image_'.$self->format;

  my $img = $self->boxer->doc->pdf->$method($self->src);

  my $img_width = $img->width;
  my $img_height = $img->height;

  my $gfx = $self->boxer->doc->gfx;

  my $x = $self->content_left;
  my $y = $self->content_top-$self->height;

  my @args;
  if (my $sc = $self->scale){
    @args = ($sc/100);
    $img_width = $img_width * $sc / 100;
    $img_height = $img_height * $sc / 100;
  } else {
    @args = ($self->width, $self->height);
  } 

  if (my $al = $self->valign){
    if ($al eq 'top'){
      $y = $self->content_top - $img_height;
    } elsif ($al eq 'center'){
      my $bc = $self->content_top - ($self->content_height / 2);
      my $ic = $img_height / 2;
      $y = $bc - $ic;
    }
  }

  if (my $al = $self->align){
    if ($al eq 'right'){
      $x = $self->content_right - $img_width;
    } elsif ($al eq 'center'){
      my $bc = $self->content_left + ($self->content_width / 2);
      my $ic = $img_width / 2;
      $x = $bc - $ic;      
    }
  }

  $gfx->image($img, $x, $y, @args);

  $self->height($img_height);

  $self->$orig();


};

sub dump_attr{
  my ($self) = @_;
  my @lines = (
    '== Image Attr ==',
    (sprintf 'width: %s', $self->width),
    (sprintf 'height: %s', $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

__PACKAGE__->meta->make_immutable;

1;

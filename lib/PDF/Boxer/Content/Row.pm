package PDF::Boxer::Content::Row;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Content::Box';

sub _build_pressure_width{ 1 }
sub _build_pressure_height{ 1 }


sub calculate_minimum_size{
  my ($self) = @_;

  my @kids = $self->propagate('calculate_minimum_size');

  # the main box should stay wide open.
  return unless $self->parent;

  my ($width, $height);
  if (@kids){
    ($width, $height) = $self->kids_min_size;
  } else {
    $width = $self->has_width ? $self->width : 0;
    $height = $self->has_height ? $self->height : 0;
  }

  $self->adjust({
     width => $width,
     height => $height,
  }, 'self');

#  warn $self->dump_size;

}

sub size_and_position{
  my ($self) = @_;

  my ($width, $height) = $self->kids_min_size;

  my $kids = $self->children;


#confess "kid (".$self->name.") width > parent (".$self->parent->name.") width: ".$self->width.' - '.$width
#  if $self->width < $width;
  if (@$kids){
    my $space = $self->width - $width;
    my ($has_grow,$grow,$grow_all);
    my ($space_each);
    if ($space > 0){
      foreach my $kid (@$kids){
        $has_grow++ if $kid->grow;
      }
      if (!$has_grow){
        $grow_all = 1;
        $has_grow = @$kids;
      }
      $space_each = int($space/$has_grow);
    }

    my $top = $self->content_top;
    my $left = $self->content_left;

    my $kheight = $self->content_height;

    foreach my $kid (@$kids){
      my $kwidth = $kid->margin_width;
      if ($grow_all || $kid->grow){
        $kwidth += $space_each;
      }
      $kid->adjust({
        margin_left => $left,
        margin_top => $top,
        margin_width => $kwidth,
        margin_height => $kheight,
      },'parent');
      $left += $kwidth;
    }
    $self->propagate('size_and_position');
  }

#  warn $self->dump_all;

  return; 
}


sub kids_min_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $width += $_->margin_width;
    $height = $height ? (sort { $b <=> $a } ($_->margin_height,$height))[0] : $_->margin_height;
warn sprintf "ROW kids (%s) margin_width: %s width: $width height: %s\n", $_->name, $_->margin_width, $height;
  }
  return ($width, $height);
}

__PACKAGE__->meta->make_immutable;

1;

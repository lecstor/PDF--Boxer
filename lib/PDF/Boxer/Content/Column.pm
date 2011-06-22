package PDF::Boxer::Content::Column;
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

  return ($width, $height);
}

sub size_and_position{
  my ($self) = @_;

  my ($width, $height) = $self->kids_min_size;

  my $kids = $self->children;

  if (@$kids){
    my $space = $self->height - $height;
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

    my $kwidth = $self->content_width;

    foreach my $kid (@$kids){
      my $kheight = $kid->margin_height;
      if ($grow_all || $kid->grow){
        $kheight += $space_each;
      }
      $kid->adjust({
        margin_left => $left,
        margin_top => $top,
        margin_width => $kwidth,
        margin_height => $kheight,
      },'parent');
      $top -= $kheight;
    }

    $self->propagate('size_and_position');
  }

  return 1;
}

sub kids_min_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $height+= $_->margin_height;
    $width = $width ? (sort { $b <=> $a } ($_->margin_width,$width))[0] : $_->margin_width;
  }
  return ($width, $height);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut


package PDF::Boxer::Content::Column;
use Moose;
use namespace::autoclean;
use Scalar::Util qw!weaken!;

extends 'PDF::Boxer::Content::Box';

sub get_default_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $height+= $_->margin_height;
    $width = $width ? (sort { $b <=> $a } ($_->margin_width,$width))[0] : $_->margin_width;
  }
  return ($width, $height);
}

sub update_children{
  my ($self) = @_;
  $self->update_kids_size     if $self->size_set;
  $self->update_kids_position if $self->position_set;
  foreach my $kid (@{$self->children}){
    $kid->update;
  }
  return 1;
}

sub update_kids_size{
  my ($self) = @_;
  my ($kids_width, $kids_height) = $self->get_default_size;
  my $kids = $self->children;
  if (@$kids){
    my $space = $self->height - $kids_height;
    my ($has_grow,$grow,$grow_all);
    my $space_each = 0;
#    if ($space > 0){
      foreach my $kid (@$kids){
        $has_grow++ if $kid->grow;
      }
      if (!$has_grow){
        $grow_all = 1;
        $has_grow = @$kids;
      }
      $space_each = int($space/$has_grow);
#    }

    my $kwidth = $self->content_width;

    foreach my $kid (@$kids){
      my $kheight = $kid->margin_height;
      if ($grow_all || $kid->grow){
        $kheight += $space_each;
      }
      $kid->set_margin_size($kwidth, $kheight);
#      $kid->update;
    }

  }
}

sub update_kids_position{
  my ($self) = @_;
  my $kids = $self->children;

  if (@$kids){
    my $top = $self->content_top;
    my $left = $self->content_left;
    foreach my $kid (@$kids){
      $kid->move($left, $top);
#      $kid->update;
      $top -= $kid->margin_height;
    }
  }

}

sub child_adjusted_height{
  my ($self, $child) = @_;
  weaken($child) if $child;
  $self->update_kids_position;
  unless($self->grow){
    my $kid = $self->children->[-1];
    my $kid_mb = $kid->margin_bottom;
    if ($self->content_bottom != $kid_mb){
warn sprintf "self bottom: %s kid bottom: %s kid: %s\n", $self->content_bottom, $kid_mb, $kid->name;
warn sprintf "  %s + %s - %s\n", $self->margin_height, $self->content_bottom, $kid_mb;
      my $height = $self->margin_height + $self->content_bottom - $kid_mb;
      $self->set_height($height);
      $self->parent->child_adjusted_height($self) if $self->parent;
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__




sub set_minimum_size{
  my ($self) = @_;

  my @kids = $self->propagate('set_minimum_size');

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

sub position{
  my ($self) = @_;
  my $kids = $self->children;
  my $top = $self->content_top;
  my $left = $self->content_left;

  foreach my $kid (@$kids){
    my $kheight = $kid->margin_height;
    $kid->adjust({
      margin_left => $left,
      margin_top => $top,
    },'parent');
    $top -= $kheight;
  }
}

sub tighten{
  my ($self) = @_;
  $self->propagate('tighten');
  $self->position;

  my $kid = $self->children->[-1];
  $self->adjust({
    content_bottom => $kid->margin_bottom,
  },'self');

}


sub float_kids{
  my ($self) = @_;
  my $kids = $self->children;

  if (@$kids){
 

  }

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


package PDF::Boxer::Content::Row;
use Moose;
use namespace::autoclean;
use Scalar::Util qw!weaken!;

extends 'PDF::Boxer::Content::Box';

sub get_default_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $width += $_->margin_width;
    $height = $height ? (sort { $b <=> $a } ($_->margin_height,$height))[0] : $_->margin_height;
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

sub update_kids_position{
  my ($self, $args) = @_;

  my $kids = $self->children;

  if (@$kids){

    my $top = $self->content_top;
    my $left = $self->content_left;

    foreach my $kid (@$kids){
      $kid->move($left, $top);
#      $kid->update;
      $left += $kid->margin_width;
    }
  }

  return 1; 
}

sub update_kids_size{
  my ($self, $args) = @_;

  my $kids = $self->children;

  my ($kids_width, $kids_height) = $self->get_default_size;
warn sprintf "default size: %s x %s\n", $kids_width, $kids_height;
warn sprintf "  my width: %s\n", $self->width;

  if (@$kids){
    my $space = $self->width - $kids_width;
warn sprintf "  free space: %s\n", $space;
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
warn sprintf "  space each: %s\n", $space_each;

    my $kheight = $self->content_height;

    foreach my $kid (@$kids){
      my $kwidth = $kid->margin_width;
      if ($grow_all || $kid->grow){
        $kwidth += $space_each;
      }
      $kid->set_margin_size($kwidth, $kheight);
#      $kid->update;
    }
  }

  return 1; 
}

sub set_kids_minimum_width{
  my ($self, $args) = @_;
  my $kids = $self->children;
  if ($args->{min_widths} && @{$args->{min_widths}}){
    if (@$kids){
      my @widths = @{$args->{min_widths}};
      foreach my $kid (@$kids){
        my $width = shift @widths;
        $kid->set_margin_width($width);
      }
    }
  }
}


sub child_adjusted_height{
  my ($self, $child) = @_;
  weaken($child) if $child;
  my $low = 5000;
  foreach(@{$self->children}){
    $low = $_->margin_bottom if defined $_->margin_bottom && $_->margin_bottom < $low;
  }
  if ($self->content_bottom != $low){
warn sprintf "self bottom: %s kid bottom: %s\n", $self->content_bottom, $low;
warn sprintf "  %s + %s - %s\n", $self->margin_height, $self->content_bottom, $low;
    my $height = $self->margin_height + $self->content_bottom - $low;
    $self->set_height($height);
    $self->parent->child_adjusted_height($self);
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
  my ($self, $args) = @_;

  $self->set_kids_minimum_width($args);

  my $kids = $self->children;

  my ($width, $height) = $self->kids_min_size;

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

  return 1; 
}

sub tighten{
  my ($self) = @_;
  $self->propagate('tighten');

  my $kids = $self->children;
  my $margin_bottom = 0;
  if (@$kids){
    foreach(@$kids){
      $margin_bottom ||= $_->margin_bottom;
      $margin_bottom = $_->margin_bottom if $_->margin_bottom < $margin_bottom;
    }


warn ($self->name || 'noname')." ########### kids: $margin_bottom me: ".$self->content_bottom;

    $self->cross_hairs($self->margin_left, $margin_bottom,'blue');
    $self->cross_hairs($self->margin_left, $self->content_bottom,'green');

    my $change = $margin_bottom - $self->content_bottom;
    my $height = $self->height - $change;

    $self->adjust({
      height => $height,
    },'self');

    warn "Content Bottom: ". $self->content_bottom;

  }

}

sub set_kids_minimum_width{
  my ($self, $args) = @_;
  my $kids = $self->children;
  if ($args->{min_widths} && @{$args->{min_widths}}){
    if (@$kids){
      my @widths = @{$args->{min_widths}};
      foreach my $kid (@$kids){
        my $width = shift @widths;
        $kid->adjust({ margin_width => $width });
      }
    }
  }
}

sub kids_min_size{
  my ($self) = @_;
  my @kids = @{$self->children};
  my ($width, $height) = (0,0);
  foreach(@kids){
    $width += $_->margin_width;
    $height = $height ? (sort { $b <=> $a } ($_->margin_height,$height))[0] : $_->margin_height;
  }
  return ($width, $height);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut



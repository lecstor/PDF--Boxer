package PDF::Boxer::Content::Grid;
use Moose;
use namespace::autoclean;
use DDP;

extends 'PDF::Boxer::Content::Column';


sub size_and_position{
  my ($self) = @_;

  my ($width, $height) = $self->kids_min_size;

  my $kids = $self->children;

  if (@$kids){
    # calculate minumum widths of cells (kids)
    my @row_highs;
    foreach my $row (@$kids){
      my @cells;
      foreach my $cell (@{$row->children}){
        push(@cells, $cell->margin_width);
      }
#      $row_highs[scalar @cells-1] unless @row_highs;
      my $idx = 0;
      foreach my $val (@cells){
        $row_highs[$idx] = $val if $val || 0 > $row_highs[$idx] || 0;
        $idx++;
      }
    }

    my $space = $self->height - $height;
    my ($has_grow,$grow,$grow_all);
    my ($space_each);
    if ($space < $height/10){
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

    $self->propagate('size_and_position', { min_widths => \@row_highs });
  }

  return 1;
}






__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut


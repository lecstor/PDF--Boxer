package PDF::Boxer::Role::SizePosition;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp qw(carp croak confess cluck);

requires qw!margin border padding children!;

subtype 'HCoord',
    as 'Int',
    where { $_ >= 0 && $_ <= 595 },
    message { "HCoord '$_' out of bounds" };

subtype 'VCoord',
    as 'Int',
    where { $_ >= 0 && $_ <= 842 },
    message { "VCoord '$_' out of bounds" };

has 'max_width' => ( isa => 'HCoord', is => 'rw' );
has 'max_height' => ( isa => 'VCoord', is => 'rw' );

has 'width' => ( isa => 'HCoord', is => 'rw', lazy_build => 1, ); #trigger => \&_width_set );
has 'height' => ( isa => 'VCoord', is => 'rw', lazy_build => 1, ); #trigger => \&_height_set );

has 'margin_left' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_left_set );
has 'margin_top'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_top_set );

has 'margin_right' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'margin_bottom'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'border_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'border_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'padding_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'padding_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'content_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'content_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'content_right' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'content_bottom'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'margin_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'margin_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'border_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'border_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'padding_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'padding_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );


has 'grow' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'attribute_rels' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );

sub _build_attribute_rels{
  return {
    max_width     => [qw! margin_right content_right margin_width border_width padding_width !],
    max_height    => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    width         => [qw! margin_right content_right margin_width border_width padding_width !],
    height        => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    margin_left   => [qw! margin_right border_left padding_left content_left !],
    margin_top    => [qw! margin_bottom border_top padding_top content_top content_bottom !],
    margin_right  => [qw! margin_left border_left padding_left content_left content_right !],
    margin_bottom => [qw! margin_top border_top padding_top content_top content_bottom !],
    margin_width  => [qw! width margin_right content_right border_width padding_width !],
    margin_height => [qw! height margin_bottom content_bottom border_height padding_height !],
  }
}

=item adjust

takes values for any of the predefined size and location attributes.
Decides what to do about it..

=cut


sub adjust{
  my ($self, $spec, $sender) = @_;

  if ($self->debug->{adjust}{dump}{$self->name}){
    cluck $self->name." adjust from $sender ".Data::Dumper->Dumper($spec);
  }

  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
    foreach ( @{$self->attribute_rels->{$attr}} ){
      next if $spec->{$_}; # don't clear anything which is in the spec
      my $clear = 'clear_'.$_;
      $self->$clear();
    }
  }

}

sub _build_margin_left{
  my ($self) = @_;
  if ($self->has_content_left){
    return $self->content_left - $self->padding->[3] - $self->border->[3] - $self->margin->[3];
  } elsif ($self->has_margin_right && $self->has_margin_width){
    return $self->margin_right - $self->margin_width;
  } elsif ($self->has_content_right && $self->has_content_width){
    return $self->content_right - $self->content_width;
  }

  confess "unable to build margin_left for ".$self->name;
}

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
}

sub _build_margin_top{
  my ($self) = @_;
  if ($self->has_content_top){
    return $self->content_top + $self->padding->[0] + $self->border->[0] + $self->margin->[0];
  } elsif ($self->has_margin_bottom && $self->has_margin_height){
    return $self->margin_bottom - $self->margin_height;
  } elsif ($self->has_content_bottom && $self->has_content_height){
    return $self->content_bottom - $self->content_height;
  }

  confess "unable to build margin_top for ".$self->name;
}

sub _build_margin_bottom{
  my ($self) = @_;
  return $self->margin_top - $self->margin_height;
}

sub _build_border_left{
  my ($self) = @_;
  return $self->margin_left + $self->margin->[3];
}

sub _build_border_top{
  my ($self) = @_;
  return $self->margin_top - $self->margin->[0];
}

sub _build_padding_left{
  my ($self) = @_;
  return $self->border_left + $self->border->[3];
}

sub _build_padding_top{
  my ($self) = @_;
  return $self->border_top - $self->border->[0];
}

sub _build_content_left{
  my ($self) = @_;
  return $self->padding_left + $self->padding->[3];
}

sub _build_content_top{
  my ($self) = @_;
  return $self->padding_top - $self->padding->[0];
}

sub _build_content_right{
  my ($self) = @_;
  return $self->content_left + $self->width;
}

sub _build_content_bottom{
  my ($self) = @_;
  return $self->content_top - $self->height;
}

sub _build_width{
  my ($self) = @_;
  if ($self->has_margin_width){
    return $self->margin_width - (($self->padding->[3] + $self->border->[3] + $self->margin->[3])*2);
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left - (($self->padding->[3] + $self->border->[3] + $self->margin->[3])*2);
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  die "unable to build width";
}

sub _build_height{
  my ($self) = @_;
  if ($self->has_margin_height){
    return $self->margin_height
      - ($self->padding->[0] + $self->padding->[2]
        + $self->border->[0] + $self->border->[2] 
        + $self->margin->[0] + $self->margin->[2]);
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left
      - ($self->padding->[0] + $self->padding->[2]
        + $self->border->[0] + $self->border->[2] 
        + $self->margin->[0] + $self->margin->[2]);
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  die "unable to build height";
}

sub content_width{ shift->width }
sub content_height{ shift->height }

sub _build_padding_width{
  my ($self) = @_;
  return $self->width + $self->padding->[1] + $self->padding->[3];
}

sub _build_padding_height{
  my ($self) = @_;
  return $self->height + $self->padding->[0] + $self->padding->[2];
}

sub _build_border_width{
  my ($self) = @_;
  return $self->padding_width + $self->border->[1] + $self->border->[3];
}

sub _build_border_height{
  my ($self) = @_;
  return $self->padding_height + $self->border->[0] + $self->border->[2];
}

sub _build_margin_width{
  my ($self) = @_;
  return $self->border_width + $self->margin->[1] + $self->margin->[3];
}

sub _build_margin_height{
  my ($self) = @_;
  return $self->border_height + $self->margin->[0] + $self->margin->[2];
}


sub dump_size{
  my ($self) = @_;
  my @lines = (
    '== Size: '.$self->name.' ==',
    (sprintf 'Max: %s x %s', $self->max_width, $self->max_height),
    (sprintf 'Margin: %s x %s', $self->margin_width, $self->margin_height),
    (sprintf 'Border: %s x %s', $self->border_width, $self->border_height),
    (sprintf 'Padding: %s x %s', $self->padding_width, $self->padding_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
    (sprintf 'Pressure: %s x %s', $self->pressure_width, $self->pressure_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}


sub dump_position{
  my ($self) = @_;
  my @lines = (
    '== Pos: '.$self->name.' ==',
    (sprintf 'Margin: %s %s %s %s', $self->margin_top, $self->margin_right, $self->margin_bottom, $self->margin_left),
    (sprintf 'Border: %s x %s', $self->border_left, $self->border_top),
    (sprintf 'Padding: %s x %s', $self->padding_left, $self->padding_top),
    (sprintf 'Content: %s x %s', $self->content_left, $self->content_top),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut


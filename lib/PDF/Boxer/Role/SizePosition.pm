package PDF::Boxer::Role::SizePosition;
use Moose::Role;

use Carp qw(cluck);

requires qw!margin border padding children!;

has 'max_width' => ( isa => 'Int', is => 'rw', required => 1 );
has 'max_height' => ( isa => 'Int', is => 'rw', required => 1 );

has 'width' => ( isa => 'Int', is => 'rw', lazy_build => 1, ); #trigger => \&_width_set );
has 'height' => ( isa => 'Int', is => 'rw', lazy_build => 1, ); #trigger => \&_height_set );

has 'margin_left' => ( isa => 'Int', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_left_set );
has 'margin_top'  => ( isa => 'Int', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_top_set );

has 'margin_right' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'margin_bottom'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'border_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'content_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'content_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'content_right' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'content_bottom'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'margin_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'margin_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'border_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );


has 'pressure' => ( isa => 'Bool', is => 'ro', default => 0 );
has 'pressure_width' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );
has 'pressure_height' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );

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

sub _build_notify_rels{
  return {
    max_width => {
      younger => { margin_right => 'margin_left' },
    },
    max_height => {
      younger => [qw! margin_bottom !],
      parent => [qw! margin_bottom !],
    },
    width => {
      younger => [qw! margin_right !],
      parent => [qw! margin_right !],
    },
    height => {
      younger => [qw! margin_bottom !],
    },
    margin_left => {
      younger => [qw! margin_right !],
    },
  };
}

=item adjust

takes values for any of the predefined size and location attributes.
Decides what to do about it..

=cut


sub adjust{
  my ($self, $spec, $sender) = @_;

  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
    foreach ( @{$self->attribute_rels->{$attr}} ){
      next if $spec->{$_}; # don't clear anything which is in the spec
      my $clear = 'clear_'.$_;
      $self->$clear();
    }
    if ($attr eq 'max_width'){
      $self->clear_width if $self->pressure_width && !$spec->{width};
    }
    if ($attr eq 'max_height'){
      $self->clear_height if $self->pressure_height && !$spec->{height};
    }
  }

  foreach my $attr (keys %$spec){
#    if ($attr eq 'max_width'){
#      $self->younger->adjust({ margin_left => $self->margin_right + 1 }) if ! $self->pressure_width;
#    }
#    if ($attr eq 'max_height'){
#      $self->younger->adjust({ margin_top => $self->margin_bottom - 1 }) if ! $self->pressure_width;
#    }
    if ($sender ne 'younger' && $self->younger){
      if ($attr eq 'width' || $attr eq 'margin_width'){
        $self->younger->adjust({ margin_left => $self->margin_right + 1 }, 'older') if ! $self->pressure_width;
      }
      if ($attr eq 'height' || $attr eq 'margin_height'){
        $self->younger->adjust({ margin_top => $self->margin_bottom - 1 }, 'older') if $self->pressure_width;
      }
      if ($attr eq 'margin_left'){
        $self->younger->adjust({ margin_left => $self->margin_right + 1 }, 'older') if ! $self->pressure_width;
      }
      if ($attr eq 'margin_right'){
        $self->younger->adjust({ margin_left => $self->margin_right + 1 }, 'older') if ! $self->pressure_width;
      }
      if ($attr eq 'margin_bottom'){
        $self->younger->adjust({ margin_top => $self->margin_bottom - 1 }, 'older') if ! $self->pressure_width;
      }
    }

    if ($sender ne 'older' && $self->older){
      if ($attr eq 'margin_left'){
        $self->older->adjust({ margin_right => $self->margin_left - 1 }, 'younger' ) if ! $self->older->pressure_width;
      }
      if ($attr eq 'margin_right'){
        $self->older->adjust({ margin_left => $self->margin_right + 1 }, 'younger' ) if ! $self->older->pressure_width;
      }
    }

  }

  warn "== Adjust Done ==\n";
  warn $self->dump_position;
  warn $self->dump_size;

}

sub clear_position{
  my ($self) = @_;
  my $meth;
  foreach (qw!margin_right margin_bottom border_left border_top padding_left padding_top
             content_left content_top content_right content_bottom!){
    $meth = "clear_$_";
    $self->$meth();
  }
}

sub clear_size{
  my ($self) = @_;
  my $meth;
  foreach(qw!margin_width margin_height
             border_width border_height padding_width padding_height!){
    $meth = "clear_$_";
    $self->$meth();
  }
}

sub _margin_left_set{
  my ($self, $new, $old) = @_;
  $self->clear_position;
  die "margin_left < 0" if $new < 0;
}
sub _margin_top_set{
  my ($self, $new, $old) = @_;
  $self->clear_position;
  cluck "margin_top $new < 0" if $new < 0;
}

sub _build_margin_left{
  my ($self) = @_;
  return $self->margin_right - $self->margin_width;
}

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
}

sub _build_margin_top{
  my ($self) = @_;
  return $self->margin_bottom + $self->margin_height;
}

sub _build_margin_bottom{
  my ($self) = @_;
warn sprintf "margin bottom = %s - %s", $self->margin_top, $self->margin_height;
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

warn sprintf "Content right: %s + %s", $self->content_left, $self->width;

  return $self->content_left + $self->width;
}

sub _build_content_bottom{
  my ($self) = @_;
  return $self->content_top - $self->height;
}



sub _width_set{ shift->clear }
sub _height_set{ shift->clear }

sub _build_width{
  my ($self) = @_;
  my $val;
  if ($self->pressure_width){
    $val = $self->padding_width - ($self->padding->[1] + $self->padding->[3]);
  } else {
    $val = $self->_width_from_child;
warn ">>>>> Size build width min: $val\n"; 
  }
  return $val;
}

sub _build_height{
  my ($self) = @_;
  my $val;
  if ($self->pressure_height){
    $val = $self->padding_height - ($self->padding->[0] + $self->padding->[2]);
  } else {
    $val = $self->_height_from_child;
warn ">>>>> Size build height min: $val\n"; 
  }
  return $val;
}

sub _height_from_child{
  my ($self) = @_;
  my $low_child_margin_bottom = 0;
  if (my $child = $self->children->[-1]){
    warn "Child: ".$child->name."\n";
    $low_child_margin_bottom = $child->margin_bottom;
  }
warn "Height from child: ".$self->content_top." - $low_child_margin_bottom\n";
  return $self->content_top - $low_child_margin_bottom;
}

sub _width_from_child{
  my ($self) = @_;
  my $right_child_margin_right = 0;
  if (my $child = $self->children->[-1]){
    warn "Child: ".$child->name."\n";
    $right_child_margin_right = $child->margin_right;
  }
  my $content_right = $right_child_margin_right + 1;
warn "Width from child: ".$self->content_left." - $content_right\n";
  return $content_right - $self->content_left;
#  return $self->content_left - $content_right;
}

sub content_width{ shift->width }
sub content_height{ shift->height }

sub _build_padding_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->width + $self->padding->[1] + $self->padding->[3];
  } elsif ($self->pressure_width) {
    $val = $self->border_width - ($self->border->[1] + $self->border->[3]);
  } else {
    $val = $self->width + $self->padding->[1] + $self->padding->[3];
#    die "Minimise Box not implemented yet..";
  }
  return $val;
}

sub _build_padding_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->height + $self->padding->[0] + $self->padding->[2];
  } elsif ($self->pressure_height) {
    $val = $self->border_height - ($self->border->[0] + $self->border->[2]);
  } else {
    $val = $self->height + $self->padding->[0] + $self->padding->[2];
  }
  return $val;
}

sub _build_border_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->padding_width + $self->border->[1] + $self->border->[3];
  } elsif ($self->pressure_width) {
    $val = $self->margin_width - ($self->margin->[1] + $self->margin->[3]);
  } else {
    $val = $self->padding_width + $self->border->[1] + $self->border->[3];
  }
  return $val;
}

sub _build_border_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->padding_height + $self->border->[0] + $self->border->[2];
  } elsif ($self->pressure_height) {
    $val = $self->margin_height - ($self->margin->[0] + $self->margin->[2]);
  } else {
    $val = $self->padding_height + $self->border->[0] + $self->border->[2];
  }
  return $val;
}

sub _build_margin_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->border_width + $self->margin->[1] + $self->margin->[3];
  } elsif ($self->pressure_width) {
    $val = $self->max_width;
  } else {
    $val = $self->border_width + $self->margin->[1] + $self->margin->[3];
  }
  return $val;
}

sub _build_margin_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->border_height + $self->margin->[0] + $self->margin->[2];
  } elsif ($self->pressure_height) {
    $val = $self->max_height;
  } else {
    $val = $self->border_height + $self->margin->[0] + $self->margin->[2];
  }
  return $val;
}

sub _build_pressure_width{ shift->pressure }
sub _build_pressure_height{ shift->pressure }

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


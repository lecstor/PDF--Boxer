package PDF::Boxer::Role::Size;
use Moose::Role;

requires qw!margin border padding!;

has 'max_width' => ( isa => 'Int', is => 'ro', required => 1 );
has 'max_height' => ( isa => 'Int', is => 'ro', required => 1 );

has 'pressure' => ( isa => 'Bool', is => 'ro', default => 1 );
has 'pressure_width' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );
has 'pressure_height' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );

has 'width' => ( isa => 'Int', is => 'rw', lazy_build => 1, trigger => \&_width_set );
has 'height' => ( isa => 'Int', is => 'rw', lazy_build => 1, trigger => \&_height_set );

has 'margin_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'margin_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'border_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub clear_size{
  my ($self) = @_;
  my $meth;
  foreach(qw!margin_width margin_height
             border_width border_height padding_width padding_height!){
    $meth = "clear_$_";
    $self->$meth();
  }
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
  my $content_bottom = $low_child_margin_bottom + 1;
warn "Height from child: ".$self->content_top." - $content_bottom\n";
  return $self->content_top - $content_bottom;
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
    die "Minimise Box not implemented yet..";
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
    '== Size ==',
    (sprintf 'Max: %s x %s', $self->max_width, $self->max_height),
    (sprintf 'Margin: %s x %s', $self->margin_width, $self->margin_height),
    (sprintf 'Border: %s x %s', $self->border_width, $self->border_height),
    (sprintf 'Padding: %s x %s', $self->padding_width, $self->padding_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}




1;

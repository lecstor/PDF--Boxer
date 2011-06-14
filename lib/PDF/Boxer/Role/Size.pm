package PDF::Boxer::Role::Size;
use Moose::Role;

requires qw!margin border padding!;

has 'max_width' => ( isa => 'Int', is => 'ro', required => 1 );
has 'max_height' => ( isa => 'Int', is => 'ro', required => 1 );

has 'width' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'height' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'margin_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'margin_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'border_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_width{
  my ($self) = @_;
  return $self->padding_width - ($self->padding->[1] + $self->padding->[3]);
}

sub _build_height{
  my ($self) = @_;
  return $self->padding_height - ($self->padding->[0] + $self->padding->[2]);
}

sub _build_padding_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->width + $self->padding->[1] + $self->padding->[3];
  } else {
    $val = $self->border_width - ($self->border->[1] + $self->border->[3]);
  }
  return $val;
}

sub _build_padding_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->height + $self->padding->[0] + $self->padding->[2];
  } else {
    $val = $self->border_height - ($self->border->[0] + $self->border->[2]);
  }
  return $val;
}

sub _build_border_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->padding_width + $self->border->[1] + $self->border->[3];
  } else {
    $val = $self->margin_width - ($self->margin->[1] + $self->margin->[3]);
  }
  return $val;
}

sub _build_border_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->padding_height + $self->border->[0] + $self->border->[2];
  } else {
    $val = $self->margin_height - ($self->margin->[0] + $self->margin->[2]);
  }
  return $val;
}

sub _build_margin_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->border_width + $self->margin->[1] + $self->margin->[3];
  } else {
    $val = $self->max_width;
  }
  return $val;
}

sub _build_margin_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->border_height + $self->margin->[0] + $self->margin->[2];
  } else {
    $val = $self->max_height;
  }
  return $val;
}

sub dump_size{
  my ($self) = @_;
  my @lines = (
    '== Size ==',
    (sprintf 'Margin: %s x %s', $self->margin_width, $self->margin_height),
    (sprintf 'Border: %s x %s', $self->border_width, $self->border_height),
    (sprintf 'Padding: %s x %s', $self->padding_width, $self->padding_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}




1;

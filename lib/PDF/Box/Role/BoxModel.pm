package PDF::Box::Role::BoxModel;
use Moose::Role;

has 'max_width' => ( isa => 'Int', is => 'ro', required => 1 );
has 'max_height' => ( isa => 'Int', is => 'ro', required => 1 );

has 'margin'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'border'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'padding'  => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );

has 'width' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'height' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'margin_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'margin_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'border_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub BUILDARGS{
  my ($class, $args) = @_;

  foreach my $attr (qw! margin border padding !){
    next unless exists $args->{$attr};
    my $arg = $args->{$attr};
    if (ref($arg)){
      unless (ref($arg) eq 'ARRAY'){
        die "Arg to $attr must be string or array reference";
      }
    } else {
      $arg = [split(/\s+/, $arg)];
    }
    my $val = [$arg->[0]];
    $val->[1] = defined $arg->[1] ? $arg->[1] : $val->[0];
    $val->[2] = defined $arg->[2] ? $arg->[2] : $val->[0];
    $val->[3] = defined $arg->[3] ? $arg->[3] : $val->[1];

    $args->{$attr} = $val;
  }

  return $args;
}

sub BUILD{
  my ($self) = @_;
  die sprintf "not enough room for width: mw: %s > %s", $self->margin_width, $self->max_width if $self->has_width && $self->margin_width > $self->max_width;
  die "not enough room for height" if $self->has_height && $self->margin_height > $self->max_height;
}

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






1;

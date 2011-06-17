package PDF::Boxer::Role::Position;
use Moose::Role;

use Carp qw(cluck);

requires qw!margin border padding!;

has 'margin_left' => ( isa => 'Int', is => 'rw', required => 1, trigger => \&_margin_left_set );
has 'margin_top'  => ( isa => 'Int', is => 'rw', required => 1, trigger => \&_margin_top_set );

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

sub clear_position{
  my ($self) = @_;
  my $meth;
  foreach (qw!margin_right margin_bottom border_left border_top padding_left padding_top
             content_left content_top content_right content_bottom!){
    $meth = "clear_$_";
    $self->$meth();
  }
}

sub _margin_left_set{
  my ($self, $new, $old) = @_;
  $self->clear;
  die "margin_left < 0" if $new < 0;
}
sub _margin_top_set{
  my ($self, $new, $old) = @_;
  $self->clear;
  cluck "margin_top $new < 0" if $new < 0;
}

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
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

warn sprintf "Content right: %s + %s", $self->content_left, $self->width;

  return $self->content_left + $self->width;
}

sub _build_content_bottom{
  my ($self) = @_;
  return $self->content_top - $self->height;
}

sub dump_position{
  my ($self) = @_;
  my @lines = (
    '== Pos ==',
    (sprintf 'Margin: %s %s %s %s', $self->margin_top, $self->margin_right, $self->margin_bottom, $self->margin_left),
    (sprintf 'Border: %s x %s', $self->border_left, $self->border_top),
    (sprintf 'Padding: %s x %s', $self->padding_left, $self->padding_top),
    (sprintf 'Content: %s x %s', $self->content_left, $self->content_top),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

1;


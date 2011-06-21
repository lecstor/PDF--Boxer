package PDF::Boxer::SpecParser;
use Moose;
use namespace::autoclean;

use XML::Parser;

has 'clean_whitespace' => ( isa => 'Bool', is => 'ro', default => 1 );

has 'xml_parser' => ( isa => 'XML::Parser', is => 'ro', lazy_build => 1 );

sub _build_xml_parser{
  XML::Parser->new(Style => 'Tree');
}

sub parse{
  my ($self, $xml) = @_;
  my $data = $self->xml_parser->parse($xml);

  my $spec = {};
  $self->mangle_spec($spec, $data);
  $spec = $spec->{children}[0];

  return $spec;
}

sub mangle_spec{
  my ($self, $spec, $data) = @_;
  while(@$data){
    my $tag = shift @$data;
    my $element = shift @$data;
    if ($tag eq '0'){
      next if $element =~ /^[\s\n\r]*$/;
      
      if ($self->clean_whitespace){
        $element =~ s/^[\s\n\r]+//;
        $element =~ s/[\s\n\r]+$//;
      }
      my @el = split(/\n/,$element);
      if ($self->clean_whitespace){
        foreach(@el){
          s/^\s+//;
          s/\s+$//;
        }
      }
      $spec->{type} = 'Text';
      $spec->{value} = \@el;
    } elsif (lc($tag) eq 'image'){
#warn Data::Dumper->Dumper($spec, $element);
      $element->[0]{type} = 'Image';
      push(@{$spec->{children}}, shift @$element);
    } elsif (lc($tag) eq 'row'){
      $element->[0]{type} = 'Row';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } elsif (lc($tag) eq 'column'){
      $element->[0]{type} = 'Column';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } else {
      $element->[0]{type} = 'Box';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;

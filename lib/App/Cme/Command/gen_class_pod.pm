# ABSTRACT: Generates pod doc from model files

package App::Cme::Command::gen_class_pod ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;
use Config::Model::Utils::GenClassPod;

sub command_names {
    my $self = shift ;
    return ( 'gen-class-pod' , $self->SUPER::command_names );
}

sub description {
    return << "EOD"
Generate pod documentation from configuration models found in ./lib directory
EOD

}

sub execute {
    my ($self, $opt, $args) = @_;
    gen_class_pod(@$args);
    return;
}

1;


=head1 SYNOPSIS

 cme gen-class-pod [ Foo ... ]

=head1 DESCRIPTION

This command scans C<./lib/Config/Model/models/*.d>
and generate pod documentation for each file found there using
L<Config::Model::generate_doc|Config::Model/"generate_doc ( top_class_name , [ directory ] )">

You can also pass one or more class names. C<gen_class_pod> will write
the documentation for each passed class and all other classes used by
the passed classes.

=head1 SEE ALSO

L<cme>, L<Config::Model::Utils::GenClassPod>

=cut

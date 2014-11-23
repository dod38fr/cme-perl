# ABSTRACT: Generates pod doc from model files

package App::Cme::Command::gen_class_pod ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;
use Config::Model::Utils::GenClassPod;

sub description {
    return << "EOD"
Generate pod documentation from configuration models found in ./lib directory
EOD

}

sub execute {
    gen_class_pod;
}

1;


=head1 SYNOPSIS

 cme gen-class-pod

=head1 DESCRIPTION

This command scans C<./lib/Config/Model/models>
and generate a pod documentation for each C<.pl> found there using
L<Config::Model::generate_doc|Config::Model/"generate_doc ( top_class_name , [ directory ] )">

=head1 SEE ALSO

L<cme>, L<Config::Model::Utils::GenClassPod>

=cut

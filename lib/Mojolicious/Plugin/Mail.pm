package Mojolicious::Plugin::Mail;

use strict;
use warnings;

use MojoX::Renderer::Mail;
use base 'Mojolicious::Plugin';

our $VERSION = '0.01';

sub register {
	my ($self, $app, $conf) = @_;
	
	$app->renderer->add_handler(
		mail => MojoX::Renderer::Mail->build( %$conf ),
	);
	
	$app->renderer->add_helper(
		mail => sub {
			my $self  = shift;
			$self->render( handler => 'mail', @_ );
		},
	);
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Mail - Mail Mojolicious Plugin using MojoX::Renderer::Mail

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin(mail => {
        from     => 'sharifulin@gmail.com',
        encoding => 'base64',
        how      => 'sendmail',
        howargs  => [ '/usr/sbin/sendmail -t' ],
    });
    
    # Mojolicious::Lite
    plugin 'mail';
    
    # send mail
    $self->helper(mail => {
        mail => {
            To      => '"Анатолий Шарифулин" sharifulin@gmail.com',
            Subject => 'Тест письмо',
            Type    => 'text/html',
            Data    => "<p>Привет!</p>",
        },
        attach => [ ... ],
    });
    

=head1 DESCRIPTION

L<Mojolicous::Plugin::Mail> is a plugin to send mail using MojoX::Renderer::Mail.

=head1 METHODS

L<Mojolicious::Plugin::Mail> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

	$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<MojoX::Renderer::Mail>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-mail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-Plugin-JsonToXml>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/MojoX-Renderer-Mail/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=MojoX-Renderer-Mail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Renderer-Mail>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/MojoX-Renderer-Mail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-Mail>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-Mail>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

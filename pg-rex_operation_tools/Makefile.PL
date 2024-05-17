use strict;
use File::Copy "cp";
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $release;
my $lib_command;

if ($^O ne 'linux') {
    die("$^O OS unsupported");
}

$release = `cat /etc/redhat-release 2> /dev/null`
    or die("unsupported linux distribution other than Redhat");

if ($release !~ /Red Hat Enterprise Linux release (\d+)/ &&
    $release !~ /CentOS (?:Linux )?release (\d+)/) {
    die("can't get RedHat Linux release");
}
if (($1 eq '8') || ($1 eq '9')) {
    $lib_command = 'lib.in/command-rhel8.pm';
}
else {
    die("RedHat Linux $1 unsupported");
}

cp($lib_command, 'lib/PGRex/command.pm')
    or die("copy failed ($lib_command): $!");

WriteMakefile(
    NAME              => 'pg-rex_operation_tools',
    VERSION           => '15.1',
    PREREQ_PM         => { 'Net::OpenSSH' => 0.62, 'IO::Tty' => 1.11 },
    PREFIX            => '/usr/local',
    INST_BIN          => 'bin',
    INST_LIB          => 'lib',
    INST_MAN1DIR      => 'man/html'
);

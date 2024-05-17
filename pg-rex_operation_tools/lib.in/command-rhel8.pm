#!/usr/bin/perl
#####################################################################
# Function: command.pm
#
#
# 概要:
# PG-REX 運用補助ツールで使用するコマンドのパスの宣言の集まり
# (RHEL7向け)
#
# 特記事項:
# なし
#
# Copyright (c) 2012-2023, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#
#####################################################################
package PGRex::command;

use warnings;
use strict;

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw ($LS $CAT $CP $SU $RM $PS $GREP $ECHO $IFCONFIG $PING $READLINK
                  $MV $LN $UNAME $WHOAMI $WHICH $STTY
                  $CRM_ATTRIBUTE $CRM_RESOURCE $SYNC $TAIL
                  $CRM_NODE $GZIP $BZIP2 $LSOF $KILL $TAR $AWK $PACEMAKERD $PCS);

our $LS            = "/bin/ls";
our $CAT           = "/bin/cat";
our $CP            = "/bin/cp";
our $SU            = "/bin/su";
our $RM            = "/bin/rm";
our $PS            = "/bin/ps";
our $GREP          = "/bin/grep";
our $ECHO          = "/bin/echo";
our $IFCONFIG      = "/sbin/ifconfig";
our $PING          = "/bin/ping";
our $READLINK      = "/bin/readlink";
our $MV            = "/bin/mv";
our $LN            = "/bin/ln";
our $UNAME         = "/bin/uname";
our $WHOAMI        = "/usr/bin/whoami";
our $WHICH         = "/usr/bin/which";
our $STTY          = "/bin/stty";
our $CRM_ATTRIBUTE = "/usr/sbin/crm_attribute";
our $CRM_RESOURCE  = "/usr/sbin/crm_resource";
our $SYNC          = "/bin/sync";
our $TAIL          = "/usr/bin/tail";
our $CRM_NODE      = "/usr/sbin/crm_node";
our $GZIP          = "/usr/bin/gzip";
our $BZIP2         = "/usr/bin/bzip2";
our $LSOF          = "/usr/bin/lsof";
our $KILL          = "/usr/bin/kill";
our $TAR           = "/usr/bin/tar";
our $AWK           = "/usr/bin/awk";
our $PACEMAKERD    = "/usr/sbin/pacemakerd";
our $PCS           = "/usr/sbin/pcs";

1;

#!/usr/bin/perl
#####################################################################
# Function: en.pm
#
#
# Summary:
# List of Messages for non-Japanese locale used by PG-REX operation
# tools
# 
# Note:
# none
#
# Copyright (c) 2012-2023, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#
#####################################################################
use warnings;
use strict;

use constant {

    PRIMARYSTART_USAGE  => <<_PRIMARYSTART_USAGE_,
PG-REX primary start tool
This is executed on the node that will start as a primary.

Usage:
  pg-rex_primary_start [-h][-v][XmlFilePath]

XmlFilePath      reflect the xml file in the case of first startup

Options:
  -h, --help       show this help, then quit
  -v, --version    show this version, then quit

_PRIMARYSTART_USAGE_

    PRIMARYSTART_MS0001  => "Ctrl-C is ignored.\n",
    PRIMARYSTART_MS0002  => "No such xml file specified in the argument.\n",
    PRIMARYSTART_MS0004  => "Failed to read xml file.\n",
    PRIMARYSTART_MS0007  => "[0]. Checking Pacemaker and Corosync has stopped\n",
    PRIMARYSTART_MS0008  => "...[NG]\n",
    PRIMARYSTART_MS0009  => "Pacemaker or Corosync has already started on this node.\n",
    PRIMARYSTART_MS0010  => "...[OK]\n",
    PRIMARYSTART_MS0011  => "[0]. Checking primary has not started on another node\n",
    PRIMARYSTART_MS0013  => "Primary has started on another node.\n",
    PRIMARYSTART_MS0014  => "[0]. Checking PGSQL lock file\n",
    PRIMARYSTART_MS0015  => "There is PGSQL lock file (\"[0]\").\n",
    PRIMARYSTART_MS0016  => "HA cluster already exists.\n".
                            "These are recreated, but are you sure? (y/N) ",
    PRIMARYSTART_MS0017  => "Exit.\n",
    PRIMARYSTART_MS0018  => "[0]. Destroying the HA cluster\n",
    PRIMARYSTART_MS0019  => "[0]. Starting Pacemaker\n",
    PRIMARYSTART_MS0020  => "[0]. Reflecting xml file\n",
    PRIMARYSTART_MS0021  => "[0]-seconds timeout occurred while checking the startup of the Pacemaker.\n".
                           "[1] is not running.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    PRIMARYSTART_MS0022  => "[0]. Checking primary has started\n",
    PRIMARYSTART_MS0023  => "Resource has failed while the startup of the Pacemaker.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    PRIMARYSTART_MS0026  => "Primary has started on the node ([0]).\n",
    PRIMARYSTART_MS0027  => "[0]. Checking to be able to start up as a primary\n",
    PRIMARYSTART_MS0028  => "The value of [0]-data-status on this node is \"[1]\".\n".
                           "Pacemaker cannot start as a primary unless this value is \"LATEST\" or \"STREAMING|SYNC\", or has been registered for reasons as first startup.\n",
    PRIMARYSTART_MS0029  => "root@[0]'s password:",
    PRIMARYSTART_MS0030  => "\nPassword has been entered.\n",
    PRIMARYSTART_MS0032  => "Failed to reflect xml file.\n".
                           "Should stop Pacemaker so check the content of \"[0]\".\n",
    
    PRIMARYSTART_MS0033  => "Should specify the parameter of \"[1]\" of ResourceID (\"[0]\") in xml file.\n",
    PRIMARYSTART_MS0034  => "This database cluster is incompletely rewinded by pg-rex_standby_start. Startup failed.\n",
    PRIMARYSTART_MS0035  => "[0]. Creating the HA cluster.\n",
    PRIMARYSTART_MS0036  => "[0] does not exist on this node.\n",

    STANDBYSTART_USAGE  => <<_STANDBYSTART_USAGE_,
PG-REX single-step starter  for standby node
Run this script on the node to be standby to start.

Usage:
  pg-rex_standby_start [[-n] [-r] [-b] | -c] [-d] [-s] [-h] [-v]

Options:
  -n, --normal                    start this node as it is as standby. when
                                  specified along with the options -r, -b,
                                  the first available option is chosen in
                                  the order of -n, -r, -b
  -r, --rewind                    start this node as standby after running
                                  pg_rewind
  -b, --basebackup                start this node as standby from a new basebackup
                                  taken from the peer node as the primary
  -d, --dry-run                   run without changing data and executing nodes
  -c, --check-only                show the condition of database clusters
  -s, --shared-archive-directory  assume that primary and standby share the same
                                  WAL archive directory
  -h, --help                      show this help, then quit
  -v, --version                   show the version, then quit

_STANDBYSTART_USAGE_

    STANDBYSTART_MS0001   => "Ctrl-C is ignored.\n",
    STANDBYSTART_MS0004   => "[0]. Checking Pacemaker and Corosync has stopped\n",
    STANDBYSTART_MS0005   => "...[NG]\n",
    STANDBYSTART_MS0006   => "Pacemaker or Corosync has already started on this node.\n",
    STANDBYSTART_MS0007   => "...[OK]\n",
    STANDBYSTART_MS0008   => "[0]. Checking primary has started on another node\n",
    STANDBYSTART_MS0010   => "Primary has not started on another node.\n",
    STANDBYSTART_MS0011   => "[0]. Checking connecting to another node with IC-LAN\n",
    STANDBYSTART_MS0012   => "There is no connection response of IC-LAN.\n",
    STANDBYSTART_MS0013   => "[0]. Checking PGSQL lock file\n",
    STANDBYSTART_MS0014   => "There is PGSQL lock file (\"[0]\").\n".
                           "In the case, this node may have previously started as a primary.\n".
                           "Should check whether you really want to start as a standby.\n",
    STANDBYSTART_MS0015   => "[0]. Taking a base backup from primary\n",
    STANDBYSTART_MS0018   => "Failed to execute readlink command.\n",
    STANDBYSTART_MS0019   => "[0]. Synchronizing with the archive directory on the primary\n",
    STANDBYSTART_MS0021   => "[0]. Starting Pacemaker (Number of WAL segments for restore: [1])\n",
    STANDBYSTART_MS0022   => "[0]. Checking standby has started\n",
    STANDBYSTART_MS0024   => "Resource has failed while the startup of the Pacemaker.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    STANDBYSTART_MS0029   => "Standby has started on the node ([0]).\n",
    STANDBYSTART_MS0032   => "Can not continue processing because file exists in archive directory: [0]\n",
    STANDBYSTART_MS0033   => "Database cluster does not exist.\n",
    STANDBYSTART_MS0034   => "[0]. Checking the status of database cluster\n",
    STANDBYSTART_MS0035   => "Failed to get DB cluster version.\n",
    STANDBYSTART_MS0036   => "DB cluster version ([0]) does not match the PostgreSQL version ([1]).\n",
    STANDBYSTART_MS0037   => "Database identifier on this node is different from another ([0] != [1]).\n",
    STANDBYSTART_MS0038   => "TimeLineID on this node is larger than another ([0] > [1]).\n",
    STANDBYSTART_MS0040   => "Could not find wal file on another node: [0]\n",
    STANDBYSTART_MS0041   => "This node is advancing in XLOG location against the peer node ([0] > [1]).\n",
    STANDBYSTART_MS0042   => "No timeline history files found on another node.\n",
    STANDBYSTART_MS0043   => "There are no history that has passed through TimeLineID on this node in the content of history file (\"[0]\") of TimeLineID on another node.\n",
    STANDBYSTART_MS0044   => "There are no history that has passed through the location of xlog on this node in the content of history file (\"[0]\") of TimeLineID on another node.\n",
    STANDBYSTART_MS0045   => "This node needs to be reinitialized from a new base backup.\n",
    STANDBYSTART_MS0046   => "[0]-seconds timeout occurred while checking the startup of the Pacemaker.\n",
    STANDBYSTART_MS0047   => "Synchronous replication of [0] is not established.\n".
                           "Should check the status of [0].\n",
    STANDBYSTART_MS0048   => "[0] is not running.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    STANDBYSTART_MS0049   => "Failed to process archived history file (Unexpected extension: [0]).\n",
    STANDBYSTART_MS0050   => "[0].[1] Checking if this node can start without change\n",
    STANDBYSTART_MS0051   => "[0].[1] Checking if this node can start after running pg_rewind\n",
    STANDBYSTART_MS0052   => "[0].[1] Checking if it is ready to run pg_basebackup\n",
    STANDBYSTART_MS0053   => "Promoted LSNs for TimelineID = [0] on both nodes are not identical.\n",
    STANDBYSTART_MS0055   => "full_page_writes on the peer node should be 'on'.\n",
    STANDBYSTART_MS0056   => "This database cluster must be initialized with --data-checksums, otherwise wal_log_hints must be 'on'.\n",
    STANDBYSTART_MS0057   => "pg_rewind is not available, try the other choices.\n",
    STANDBYSTART_MS0058   => "\nNone of the specified methods are able to be performed.\n",
    STANDBYSTART_MS0059   => "\nFollowing methods are available to start this node as standby\n",
    STANDBYSTART_MS0060   => "n) Start as it is\n",
    STANDBYSTART_MS0061   => "r) Start after running pg_rewind\n",
    STANDBYSTART_MS0062   => "b) Start from a new base backup\n",
    STANDBYSTART_MS0063   => "q) quit\n",
    STANDBYSTART_MS0064   => "Make a choice among the options ([0]) ",
    STANDBYSTART_MS0065   => "quit starting this node.\n",
    STANDBYSTART_MS0066   => "Invalid value.\n",
    STANDBYSTART_MS0067   => "\nStarting the database as it is.\n",
    STANDBYSTART_MS0068   => "\nStarting after performing pg_rewind.\n",
    STANDBYSTART_MS0069   => "\nStarting from a new base backup.\n",
    STANDBYSTART_MS0070   => "[0]. Rewinding the database cluster\n",
    STANDBYSTART_MS0071   => "Running pg_rewind.\n",
    STANDBYSTART_MS0072   => "Unable to rewind to the promoted point of the peer node.pg_rewind not available.\n",
    STANDBYSTART_MS0073   => "Failed to establish an ssh connection ([0]) - Aborting rewind\n",
    STANDBYSTART_MS0074   => "pg_rewind failed to connect to the peer\n - TCP Forwarding may be disabled in sshd_config on the peer server\n",
    STANDBYSTART_MS0075   => "This database cluster is incompletely rewinded by pg-rex_standby_start.\n",
    STANDBYSTART_MS0076   => "WAL files with future XLOG location of the peer node found in archive directory.\n",
    STANDBYSTART_MS0077   => "Skip synchronizing the archive directory because standby's archive directory is newer than primary.\n",
    STANDBYSTART_MS0078   => "The archive log \"[0]\" that synchronize is incomplete.\n",
    STANDBYSTART_MS0079   => "The archive log \"[0]\" is unexpected extension (Unexpected extension: [1]).\nSkipping the integrity check of the archive log.\n",
    STANDBYSTART_MS0080   => "WAL directory of the base backup is not empty.\n",
    STANDBYSTART_MS0081   => "Primary's archive directory has WAL that is advancing than current LSN of the primary node.\n",
    STANDBYSTART_MS0083   => "WAL file of pg_wal is inappropriate. If start the Standby on this state, archive log will be lost.\n",
    STANDBYSTART_MS0084   => "-c option is specified, non-interactive options(-n,-r,-b) are ignored.\n",
    STANDBYSTART_MS0085   => "Peer node has promoted in the past of this node.\n",
    STANDBYSTART_MS0086   => "...[SKIP]\n",
    STANDBYSTART_MS0087   => "Timeline hitory file for timeline ID [0] not found on another node: [1]\n",
    STANDBYSTART_MS0089   => "[0] does not exist on this node.\n",
    STANDBYSTART_MS0099   => "Internal Error.\n",

    STOP_USAGE  => <<_STOP_USAGE_,
PG-REX stop tool
This is executed on the node that will stop.

Usage:
  pg-rex_stop [-f][-h][-v]

Options:
  -f, --fast       stop without executing CHECKPOINT and sync command
  -h, --help       show this help, then quit
  -v, --version    show this version, then quit

_STOP_USAGE_

    STOP_MS0001         => "Ctrl-C is ignored.\n",
    STOP_MS0004         => "Pacemaker and Corosync has already stopped.\n",
    STOP_MS0005         => "Could not check the status of PostgreSQL.\n".
                           "Stopping Pacemaker.\n",
    STOP_MS0006         => "Stopping primary.\n",
    STOP_MS0007         => "Stopping standby.\n",
    STOP_MS0009         => "Exit.\n",
    STOP_MS0010         => "1. Stopping Pacemaker\n",
    STOP_MS0011         => "...[OK]\n",
    STOP_MS0012         => "2. Checking Pacemaker has stopped\n",
    STOP_MS0013         => "...[NG]\n",
    STOP_MS0014         => "[0]-seconds timeout occurred while checking the stopping processing of the Pacemaker.\n".
                           "Should check these processes of Pacemaker and Corosync with ps command whether they have stopped successfully.\n",
    STOP_MS0015         => "Pacemaker has stopped on the node ([0]).\n",
    STOP_MS0016         => "[0] has stopped on the node ([1]).\n",
    STOP_MS0018         => "Standby has already started.\n",
    STOP_MS0019         => "we recommend to use pg-rex_switchover command when you want to stop primary with the purpose of switchover.\n",
    STOP_MS0020         => "If you continue with this operation, then a failover occurs, but are you sure? (y/N) ",

    ARCHDELETE_USAGE  => <<_ARCDELETE_USAGE_,
PG-REX remove archive log tool

Usage:
  pg-rex_archivefile_delete {-m|-r}[-f][-D DBclusterFilepath][-h][-v]
                            [[Hostname:]BasebackupPath]

Hostname        the hostname of remote server that exists a base backup

BasebackupPath  the fullpath of remote server that exists a base backup
    Caution:  You will not be able to use a base backup older than one specified.

Options:
  -m, --move                         execute as a move mode
  -r, --remove                       execute as a remove mode
  (You must specify either move mode or remove.)
  -f, --force                        execute without contacts
  -D, --dbcluster=DBclusterFilepath  the fullpath of database cluster
  -h, --help                         show this help, then quit
  -v, --version                      show this version, then quit

_ARCDELETE_USAGE_

    ARCHDELETE_MS0001   => "Ctrl-C is ignored.\n",
    ARCHDELETE_MS0002   => "Should specify move mode or remove in the argument.\n",
    ARCHDELETE_MS0003   => "\n**** 1. Ready to run ****\n",
    ARCHDELETE_MS0004   => "Running move mode.\n",
    ARCHDELETE_MS0005   => "Running remove mode.\n",
    ARCHDELETE_MS0006   => "The input format of the backup path is invalid : \"[0]\"\n",
    ARCHDELETE_MS0007   => "Please input a remote server name that has a base backup.\n".
                           "(If empty, set \"localhost\")\n".
                           "> ",
    ARCHDELETE_MS0008   => "The input format of the remote server is invalid : \"[0]\"\n",
    ARCHDELETE_MS0009   => "Please input a fullpath of the base backup.\n".
                           "(If empty, set no backup path.\n".
                           " In the case, you cannot use a base backup older than one specified because the archive log is removed.)\n".
                           "> ",
    ARCHDELETE_MS0010   => "The input format of the fullpath of this base backup is invalid : \"[0]\"\n",
    ARCHDELETE_MS0011   => "Remote server \"[0]\", Backup path\"[1]\".\n".
                           "Are you sure? (y/N) : ",
    ARCHDELETE_MS0012   => "Exit.\n",
    ARCHDELETE_MS0013   => "Reading pg-rex_tools.conf.\n",
    ARCHDELETE_MS0015   => "Getting both node names.\n",
    ARCHDELETE_MS0016   => "Reading cib.xml.\n",
    ARCHDELETE_MS0018   => "Remove the archive log on the basis of the current database cluster(\"[2]\") on this node(\"[0]\") or another(\"[1]\") if you run without specifying the backup path.\n".
                           "Do you want to delete the archive log? (y/N) : ",
    ARCHDELETE_MS0019   => "\n**** 2. Get wal file names ****\n",
    ARCHDELETE_MS0020   => "Getting first wal file name that needs to recovery from the backup specified.\n",
    ARCHDELETE_MS0021   => "No such directory (\"[0]\").\n",
    ARCHDELETE_MS0022   => "The format of fist line of the backup label file (\"[0]\") is invalid.\n",
    ARCHDELETE_MS0023   => " \"[0]\" \n",
    ARCHDELETE_MS0024   => "Getting first wal file name that needs to recovery from the database cluster (\"[1]\") on this node (\"[0]\").\n",
    ARCHDELETE_MS0025   => "Failed to get first wal file name because the result of pg_controldata command is empty.\n",
    ARCHDELETE_MS0026   => "Getting first wal file name that needs to recovery from the database cluster (\"[1]\") on another node (\"[0]\").\n",
    ARCHDELETE_MS0027   => "\n**** 3. Calculate the deletion target ****\n",
    ARCHDELETE_MS0028   => "No the deletion target.\n",
    ARCHDELETE_MS0029   => "Setted \"[0]\" to the deletion target.\n",
    ARCHDELETE_MS0030   => "\n**** 4. Remove the archive log ****\n",
    ARCHDELETE_MS0031   => "Could not find the archive directory (\"[0]\").\n",
    ARCHDELETE_MS0032   => "Added \"[0]\" to the list of the deletion target.\n",
    ARCHDELETE_MS0033   => "The list of the deletion target is empty.\n",
    ARCHDELETE_MS0034   => "The directory where you want to move the archive log (\"[0]\") already exist.\n",
    ARCHDELETE_MS0035   => "Failed to creating the directory where you want to move the archive log (\"[0]\").\n",
    ARCHDELETE_MS0036   => "Failed to change the owner of the directory where you want to move the archive log (\"[0]\").\n",
    ARCHDELETE_MS0037   => "Created the directory where you want to move the archive log.\n",
    ARCHDELETE_MS0038   => "Failed to move the file (\"[0]\").\n",
    ARCHDELETE_MS0039   => " -- move -- [0] \n",
    ARCHDELETE_MS0040   => "Succeeded moving the archive log.\n".
                           "These are in the directory (\"[0]\").\n",
    ARCHDELETE_MS0041   => "Failed to remove the file (\"[0]\").\n",
    ARCHDELETE_MS0042   => " -- remove -- [0] \n",
    ARCHDELETE_MS0043   => "Succeeded removing the archive log.\n",
    ARCHDELETE_MS0044   => "Failed to get DB cluster path.\n".
                           "Should specify the fullpath of DB cluster with \"-D\" option.\n",
    ARCHDELETE_MS0045   => "\n**** 4. Move the archive log ****\n",
    ARCHDELETE_MS0046   => "Failed to connect to the server that has a base backup by ssh.\n",

    SWITCHOVER_USAGE  => <<_SWITCHOVER_USAGE_,
This is tool to switch primary and standby of PG-REX
  
Usage:
  pg-rex_switchover [-h][-v]

Options:
  -h, --help      show this help, then quit
  -v, --version   show this version, then quit

_SWITCHOVER_USAGE_

    SWITCHOVER_MS0001   => "Ctrl-C is ignored.\n",
    SWITCHOVER_MS0002   => "**** Ready to run ****\n",
    SWITCHOVER_MS0003   => "[0]. Reading pg-rex_tools.conf and get both node names.\n",
    SWITCHOVER_MS0004   => "...[OK]\n",
    SWITCHOVER_MS0005   => "...[NG]\n",
    SWITCHOVER_MS0008   => "[0]. Checking the HA cluster status of current and after switchover.\n",
    SWITCHOVER_MS0009   => "Can not switchover because the HA cluster status does not meet the following conditions.\n".
                           " (1) Pacemaker, Corosync and PostgreSQL is running on both nodes\n".
                           " (2) Primary and standby are present\n".
                           " (3) PostgreSQL is the state of synchronous replication\n",
    SWITCHOVER_MS0010   => "[ Current HA cluster status ]\n",
    SWITCHOVER_MS0011   => "[ HA cluster status of current and after switchover ]\n",
    SWITCHOVER_MS0012   => "Availability is not guaranteed during executing to switchover.\n",
    SWITCHOVER_MS0013   => "In addition, There are multi standby on the node ([0]).\n",
    SWITCHOVER_MS0014   => "Do you want to continue ? (y/N) ",
    SWITCHOVER_MS0015   => "Exit.\n",
    SWITCHOVER_MS0017   => "[0]. Executing CHECKPOINT.\n",
    SWITCHOVER_MS0018   => "**** Execute to switchover ****\n",
    SWITCHOVER_MS0019   => "[0]. Stopping monitoring by Pacemaker.\n",
    SWITCHOVER_MS0020   => "[0]. Stopping PostgreSQL on the primary node ([1]).\n",
    SWITCHOVER_MS0021   => "[0]. Starting monitoring by Pacemaker, and executing to switchover.\n",
    SWITCHOVER_MS0022   => "[0]. Checking that [1] becomes the new primary.\n",
    SWITCHOVER_MS0023   => "[0]-seconds timeout occurred while checking the startup of the Resources.\n".
                           "[1] is not running.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    SWITCHOVER_MS0026   => "[0]. Stopping Pacemaker on the node ([1]).\n",
    SWITCHOVER_MS0027   => "[0]-seconds timeout occurred while checking the shutdown of Pacemaker and PostgreSQL.\n".
                           "If you check details of Pacemaker status, please execute pcs status --full command.\n",
    SWITCHOVER_MS0028   => "[0]. Starting standby on the node ([1]).\n",
    SWITCHOVER_MS0030   => "**** Standby has started on the node ([0]) ****\n",
    SWITCHOVER_MS0031   => "***************************************\n".
                           "**** Switchover has been completed ****\n".
                           "***************************************\n",
    SWITCHOVER_MS0032   => "Failed to execute \"[0]\" command.\n",
    SWITCHOVER_MS0033   => "**** Primary has started on the node ([0]) ****\n",

    COMMON_MS0001       => "Failed to execute pcs status --full command.\n",
    COMMON_MS0003       => "Should specify the parameter of \"[1]\" of ResourceID (\"[0]\") in cib.xml.\n",
    COMMON_MS0004       => "Should specify [0] in pg-rex_tools.conf.\n",
    COMMON_MS0005       => "Should specify [0] of fullpath in pg-rex_tools.conf.\n",
    COMMON_MS0006       => "Should specify STONITH which is setting only enable in pg-rex_tools.conf.\n",
    COMMON_MS0007       => "Should specify [0] which is setting two IPAddress separated by a comma in pg-rex_tools.conf.\n",
    COMMON_MS0008       => "Failed to get the value of own IPAddress.\n",
    COMMON_MS0009       => "No IP addresses for this node found in [0]: [1]\n",
    COMMON_MS0010       => "No IP addresses for peer node found in [0]: [1]\n",
    COMMON_MS0011       => "Failed to execute \"[0]\" command.\n",
    COMMON_MS0013       => "Failed to parse the location of xlog.\n",
    COMMON_MS0014       => "Failed to get the value by pg_controldata command.\n",
    COMMON_MS0015       => "Failed to get the name of another node.\n",
    COMMON_MS0016       => "Failed to connect to another node by ssh.\n",
    COMMON_MS0018       => "Failed to execute scp command.\n",
    COMMON_MS0021       => "Should specify IPADDR_STANDBY which is setting either enable or disable in pg-rex_tools.conf.\n",
    COMMON_MS0022       => "Should specify STONITH_ResourceID which is setting two ResourceID separated by a comma in pg-rex_tools.conf.\n",
    COMMON_MS0023       => "Failed to read cib.xml (\"[0]\").\n",
    COMMON_MS0024       => "Failed to read config file (\"[0]\").\n",
    COMMON_MS0026       => "You are running in \"[0]\" user.\n".
                           "Should try again in root user.\n",
    COMMON_MS0028       => "Failed to write config file (\"[0]\").\n",
    COMMON_MS0029       => "[0]@[1]'s password:",
    COMMON_MS0030       => "\nPassword has been entered.\n",
    COMMON_MS0031       => "Could not find password file (\"[0]\").\n",
    COMMON_MS0032       => "Failed to read password file (\"[0]\").\n",
    COMMON_MS0033       => "Content of password file (\"[0]\") is invalid.\n",
    COMMON_MS0034       => "Should specify [0] which is setting either\n".
                           "manual, passfile or nopass in pg-rex_tools.conf.\n",
    COMMON_MS0035       => "Authority of the password file \"[0]\" is not 600.\n",
    COMMON_MS0036       => "Not found PostgreSQL commands in \"[0]\". : [1]\n",
    COMMON_MS0037       => "PostgreSQL [0] is not supported.\n".
                           "Please use version 15.\n",
    COMMON_MS0038       => "Pacemaker [0] is not supported.\n".
                           "Please use version 2.\n",
    COMMON_MS0039       => "Not found network interface to correspond to bindnetaddr ([1]) on [0].\n",
    COMMON_MS0040       => "Failed to get IP address belonging to bindnetaddr ([1]) on [0].\n",
    COMMON_MS0044       => "Could not check the status of archive directory: [0]\n",
    COMMON_MS0045       => "The format of fist line of the backup label file is invalid: [0]\n",
    COMMON_MS0046       => "DB cluster status check failed: [0]\n",
    COMMON_MS0047       => "There are processes accessing the DB cluster.\n[0]",
    COMMON_MS0048       => "Failed to create lock file([0]). : [1]\n",
    COMMON_MS0049       => "[0] has already started on this node.\n",
    COMMON_MS0050       => "Failed to create lock file([0]).\n",
    COMMON_MS0051       => "Failed to delete lock file([0]). : [1]\n",
    COMMON_MS0052       => "[0] is not in IPv4 format.\n",
    COMMON_MS0053       => "[0] not found. : [1]\n",
    COMMON_MS0054       => "The size of archivefile([0]) is 0\n",
    COMMON_MS0055       => "The size of archive file([0]) is not match the information of control file([1]).\n",
    COMMON_MS0056       => "Could not parse output from lsof command.[0]\n",
    COMMON_MS0057       => "The setting value of the setting parameter [0] is invalid.\n",
    COMMON_MS0058       => "File [0] has invalid permissions. Should be 600.\n",
};

1;

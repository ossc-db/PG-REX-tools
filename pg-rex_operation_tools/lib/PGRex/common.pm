#!/usr/bin/perl
#####################################################################
# Function: common.pm
#
# 概要:
# PG-REX 便利ツールから呼び出すモジュールの集まり
# 
# 特記事項:
# なし
#
# Copyright (c) 2012-2023, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#
#####################################################################
package PGRex;

use warnings;
use strict;
use Net::OpenSSH;
use PGRex::command;
use Class::Struct;
use Fcntl;
use Fcntl ':mode';
use Errno;


BEGIN {
    if ($ENV{'LANG'} =~ m/ja/i){
        eval qq{
            use PGRex::Po::ja;
        };
    }
    else{
        eval qq{
            use PGRex::Po::en;
        };
    }
};

struct Ssh_info => {
    address => '$',
    user => '$',
    pass => '$'
};

struct Pg_dir_state => {
    pgdata_exist  => '$',
    pgarch_empty  => '$'
};

use constant {
    VERSIONNUM       => "15.1",
    VERSIONINFO      => "[0] (pg-rex_operation_tools) [1]\n",
    CONFIG_PATH      => "/etc/",
    CONFIG_FILENAME  => "pg-rex_tools.conf",
    CIB_PATH         => "/var/lib/pacemaker/cib/",
    CIB_FILENAME     => "cib.xml",
    HACF_PATH        => "/etc/corosync/",
    HACF_FILENAME    => "corosync.conf",
    RA_TMPDIR        => "/var/lib/pgsql/tmp",
    LOCK_FILENAME    => "PGSQL.lock",
    PID_FILENAME     => "pg-rex_tools.pid",
    PID_FILEDIR      => "/var/run",
    STANDBY_SIGNAL   => "standby.signal",
    RECOVERY_SIGNAL  => "recovery.signal"
};

our $additional_information_mode = 0;

sub pacemaker_running{
    my ($ssh_info) = @_;
    my $result;
    my @results;
    my $commnad;

    $commnad = "$PS aux | $GREP -P \"(pacemakerd|corosync)\" | $GREP -v \"grep\"";

    if ($ssh_info) {
        @results = ssh_exec_command($ssh_info, $commnad);
        $result = $results[0];
    }
    else {
        $result = `$commnad`;
    }

    # Pacemaker または Corosync のプロセスを発見したら1を返却する
    if ($result ne ""){
        return 1;
    }
    return 0;
}


sub pacemaker_online{
    my ($my_node) = @_;
    my @results;
    my @crm_results;
    my $exit_code;

    $results[0] = `$PCS status --full 2>&1`;
    $results[1] = $? >> 8;

    $exit_code = $results[1];
    # Pacemaker が起動している場合は $exit_code = 0 、起動していない場合は $exit_code = 1
    if ($exit_code != 0 && $exit_code != 1){
        printlog("ERROR", COMMON_MS0001);
    }

    # pcs status --full の結果を行ごとの配列に格納する
    @crm_results = split (/\n/, $results[0]);

    # Pacemaker が Online だったら1を返却する
    foreach my $line (@crm_results){
        # pcs status --full の結果に「Online: [ ～ <マシンのホスト名>」の行が存在すると OK
        if ($line =~ /Online\:\s+\[(\s+\S+)?\s.*$my_node\s+/
            || $line =~ /Node $my_node .*: online,/){
            return 1;
        }
    }
    return 0;

}


sub pgrex_failed_action{
    my ($target_node, $pg_primitive_resource_id) = @_;
    my @results;
    my @crm_results;
    my $exit_code;

    $results[0] = `$PCS status --full 2>&1`;
    $results[1] = $? >> 8;

    $exit_code = $results[1];
    # Pacemaker が起動している場合は $exit_code = 0 、起動していない場合は $exit_code = 1
    if ($exit_code != 0 && $exit_code != 1){
        printlog("ERROR", COMMON_MS0001);
    }

    # pcs status --full の結果を行ごとの配列に格納する
    @crm_results = split (/\n/, $results[0]);

    my $line_count = 0;
    my $line_tmp = 0;
    # pcs status --full の結果に failed Action の内容が存在していたら1を返却する
    foreach my $line (@crm_results){
        $line_count++;

        # pcs status --full の結果に「Failed Resource Actions:」の行が存在した後、
        # 1行後に「<PostgreSQLのPrimitiveのリソースID> ～ on <マシンのホスト名>」の行が存在する場合、
        # PG-REXリソースの故障が発生したと判断し、1 を返却する
        if ($line =~ /Failed\s+Resource\s+Actions:/){
            $line_tmp = $line_count;
        }
        if ($line =~ /${pg_primitive_resource_id}_\S+_[0-9]+\s+on\s+$target_node/ && $line_count == $line_tmp + 1){
            return 1;
        }
    }
    return 0;

}

sub primary_running{
    my ($my_node, $primary_resource_id, $pg_primitive_resource_id, $ssh_info) = @_;
    my @results;
    my $command;

    ##
    # 以下の条件を満たしたとき結果を OK とする
    #   *  コマンド
    #     「crm_resource -r <PrimaryリソースID> -W 2> /dev/null | grep " <マシンのホスト名> "」
    #      の結果が"resource <PrimaryリソースID> is running on: <マシンのホスト名> Primary"である
    #   *  コマンド
    #     「crm_attribute -l forever -N <マシンのホスト名> --name <PostgreSQLのPrimitiveのリソースID>-data-status -G -q」
    #      の結果が"LATEST"である
    #   *  コマンド
    #     「crm_attribute -t status -N <マシンのホスト名> --name <PostgreSQLのPrimitiveのリソースID>-status -G -q」
    #      の結果が"PRI"である
    ##

    $command = "$CRM_RESOURCE -r $primary_resource_id -W 2> /dev/null | $GREP \" $my_node \"";
    if ($ssh_info){
        @results = ssh_exec_command($ssh_info, $command);
    }
    else {
        $results[0] = `$command`;
        chomp $results[0];
    }
    if ($results[0] ne "resource $primary_resource_id is running on: $my_node Master"){
        return 0;
    }

    $command = "$CRM_ATTRIBUTE -l forever -N $my_node --name ${pg_primitive_resource_id}-data-status -G -q 2> /dev/null";
    if ($ssh_info){
        @results = ssh_exec_command($ssh_info, $command);
    }
    else {
        $results[0] = `$command`;
        chomp $results[0];
    }
    if ($results[0] ne "LATEST"){
        return 0;
    }

    $command = "$CRM_ATTRIBUTE -t status -N $my_node --name ${pg_primitive_resource_id}-status -G -q 2> /dev/null";
    if ($ssh_info){
        @results = ssh_exec_command($ssh_info, $command);
    }
    else {
        $results[0] = `$command`;
        chomp $results[0];
    }
    if ($results[0] ne "PRI"){
        return 0;
    }

    return 1;
}


sub standby_running{
    my ($my_node, $primary_resource_id, $pg_primitive_resource_id, $error_code) = @_;
    my $command;
    my $result;
    my $pgsql_data_status;
    my $pgsql_status;

    ##
    # 以下の条件を満たしたとき結果を OK とする
    #   *  コマンド
    #     「crm_resource -r <PrimaryリソースID> -W 2> /dev/null | grep " <マシンのホスト名>"」
    #      の結果が"resource <PrimaryリソースID> is running on: <マシンのホスト名>"である
    #   *  コマンド
    #     「crm_attribute -l forever -N <マシンのホスト名> --name <PostgreSQLのPrimitiveのリソースID>-data-status -G -q」
    #      の結果が"STREAMING|SYNC"である
    #   *  コマンド
    #     「crm_attribute -t status -N <マシンのホスト名> --name <PostgreSQLのPrimitiveのリソースID>-status -G -q」
    #      の結果が"HS:SYNC"である
    ##

    $command = "$CRM_RESOURCE -r $primary_resource_id -W 2> /dev/null | $GREP \" $my_node\$\"";
    $result = `$command`;
    chomp $result;

    if ($result ne "resource $primary_resource_id is running on: $my_node"){
        if ($error_code){
            $$error_code = 1;
        }
        return 0;
    }

    $command = "$CRM_ATTRIBUTE -l forever -N $my_node --name ${pg_primitive_resource_id}-data-status -G -q 2> /dev/null";
    $pgsql_data_status = `$command`;
    chomp $pgsql_data_status;

    $command = "$CRM_ATTRIBUTE -t status -N $my_node --name ${pg_primitive_resource_id}-status -G -q 2> /dev/null";
    $pgsql_status = `$command`;
    chomp $pgsql_status;

    if ($pgsql_data_status ne "STREAMING|SYNC" || $pgsql_status ne "HS:sync"){
        if ($error_code){
            $$error_code = 2;
        }
        return 0;
    }

    return 1;

}


sub vip_running{
    my ($my_node, $resource_id) = @_;
    my $result;

    ##
    # 以下の条件を満たしたとき結果を OK とする
    #   *  コマンド
    #     「crm_resource -r <リソースID> -W 2> /dev/null」
    #      の結果が"resource <リソースID> is running on: <マシンのホスト名>"である
    ##

    $result = `$CRM_RESOURCE -r $resource_id -W 2> /dev/null`;
    chomp $result;
    if ($result ne "resource $resource_id is running on: $my_node"){
        return 0;
    }

    return 1;

}


sub stonith_running{
    my ($my_node, $resource_id) = @_;
    my $result;

    ##
    # 以下の条件を満たしたとき結果を OK とする
    #   *  コマンド
    #     「crm_resource -r <リソースID_1> -W 2> /dev/null」
    #     「crm_resource -r <リソースID_2> -W 2> /dev/null」
    #      のどちらも実行して、どちらかの結果が
    #      "resource <指定したリソースID> is running on: <マシンのホスト名>"である
    ##

    $result = `$CRM_RESOURCE -r $resource_id->[0] -W 2> /dev/null`;
    chomp $result;
    if ($result eq "resource $resource_id->[0] is running on: $my_node"){
        return 1;
    }

    $result = `$CRM_RESOURCE -r $resource_id->[1] -W 2> /dev/null`;
    chomp $result;
    if ($result eq "resource $resource_id->[1] is running on: $my_node"){
        return 1;
    }

    return 0;

}


sub ping_running{
    my ($my_node, $resource_id) = @_;
    my $result;
    my @resource_id;
    my $array_num;
    my $resource_check_count = 0;

    ##
    # 以下の条件を指定されたリソースの数だけ満たしたとき結果を OK とする
    #   *  コマンド
    #     「crm_resource -r <リソースID> -W 2> /dev/null | grep " <マシンのホスト名>"」
    #      の結果が"resource <リソースID> is running on: <マシンのホスト名>"である
    ##

    @resource_id = split(/\s*,\s*/, $resource_id);
    $array_num = scalar(@resource_id);
    
    foreach my $id (@resource_id){
        $result = `$CRM_RESOURCE -r $id -W 2> /dev/null | $GREP \" $my_node\"`;
        chomp $result;
        if ($result eq "resource $id is running on: $my_node"){
            $resource_check_count ++;
        }
    }

    if ($resource_check_count == $array_num){
        return 1;
    }
    
    return 0;

}

sub read_cib{
    my ($cib_path, $pg_primitive_resource_id, $kill_when_no_data) = @_;
    my @cib_strings;
    my %cib_value;
    my $my_node;
    my $my_node_id;
    my $my_pgsql_data_status_id;
    my @check_key_list = ("pgdata", "repuser");
    my $result;
    my $param_name;
    my $param_value;

    $my_node = exec_command("$UNAME -n");
    chomp $my_node;

    # tmpdir のデフォルト値を設定する
    $cib_value{'tmpdir'} = RA_TMPDIR;

    open (FILE, $cib_path) or printlog("ERROR", COMMON_MS0023, $cib_path);
    @cib_strings = <FILE>;
    close (FILE);

    # PostgreSQL のリソース部分からパラメータ値を取得
    foreach my $line (@cib_strings){
        # <PostgreSQLのPrimitiveのリソースID>-instance_attributes format : 
        #     <nvpair name="<name>" value="<value>" id="<PostgreSQLのPrimitiveのリソースID>-instance_attributes-<文字列>" />
        #     ※neme, value, id タグの順番が変わっても対応できるようにパラメータ値を取得する
        if ($line =~ /.*id=\"$pg_primitive_resource_id-instance_attributes-\S+\"/){
            if ($line =~ /\s+name=\"([^\"\s]+)\"/){
                $param_name = $1;
            }
            if ($line =~ /\s+value=\"([^\"]+)\"/){
                $param_value = $1;
            }
            if ($param_name && $param_value) {
                $cib_value{$param_name} = $param_value;
            }

        }
        # node id format : 
        #     <node (id="<node id>" type="<type>" uname="<node name>")>
        #     ※()の中のタグの順番は不定
        if ($line =~ /uname=\"$my_node\"/ && $line =~ /id=\"([^\"\s]+)\"/){
            $my_node_id = $1;
            $my_pgsql_data_status_id = "nodes-".$my_node_id."-".$pg_primitive_resource_id."-data-status";
        }
    }

    foreach my $line (@cib_strings){
        if ($my_pgsql_data_status_id && $line =~ /id=\"$my_pgsql_data_status_id\"/ && $line =~ /value=\"([^\"\s]+)\"/){
            $cib_value{'pgsql_data_status'} = $1;
        }
    }
    
    foreach my $key (@check_key_list){
        if (!exists($cib_value{$key}) && $kill_when_no_data){
            printlog("ERROR", COMMON_MS0003, $pg_primitive_resource_id, $key);
        }
    }

    return %cib_value;
}


sub read_config{
    my ($config_path) = @_;
    my @config_strings;
    my %config_value;
    my @check_key_list = ("Archive_dir", "D_LAN_IPAddress", 
                         "PG_REX_Primary_ResourceID","PG_REX_Primitive_ResourceID","IC_LAN_IPAddress","HACLUSTER_NAME");
    my $result;

    $config_value{'STONITH'} = "enable";
    $config_value{'IPADDR_STANDBY'} = "enable";
    $config_value{'PEER_NODE_SSH_PASS_MODE'} = "manual";
    $config_value{'BACKUP_NODE_SSH_PASS_MODE'} = "manual";
    
    open (FILE, $config_path) or printlog("ERROR", COMMON_MS0024, $config_path);
    @config_strings = <FILE>;
    close (FILE);

    foreach my $line (@config_strings){
        # コメントの削除
        # comment format : #<comment>
        $line =~ s/\#.*//g;

        # 行末の空白の削除
        # space format : <space><\n>
        $line =~ s/\s+$//g;

        # 全角の空白を半角空白に変換
        # two-byte characterspace format : <two-byte character space>
        $line =~ s/　/ /g;

        # environment setting value format : <<value name> = <parameter>> or <<value name> = <parameter>,<parameter>>
        if ($line =~ /^\s*(\S+)\s*=\s*(.+)$/){
            $config_value{$1} = $2;
        }
    }

    foreach my $key (@check_key_list) {
        if (!exists($config_value{$key})){
            printlog("ERROR", COMMON_MS0004, $key);
        }
    }
    if ($config_value{'Archive_dir'} !~ /^\//){
        printlog("ERROR", COMMON_MS0005, "Archive_dir");
    }
    if ($config_value{'STONITH'} ne "enable"){
        printlog("ERROR", COMMON_MS0006);
    }
    if ($config_value{'IPADDR_STANDBY'} ne "enable" && $config_value{'IPADDR_STANDBY'} ne "disable"){
        printlog("ERROR", COMMON_MS0021);
    }
    if ($config_value{'PEER_NODE_SSH_PASS_MODE'} ne "manual" && $config_value{'PEER_NODE_SSH_PASS_MODE'} ne "passfile"
        && $config_value{'PEER_NODE_SSH_PASS_MODE'} ne "nopass" ){
       printlog("ERROR", COMMON_MS0034, "PEER_NODE_SSH_PASS_MODE");
    }
    if ($config_value{'BACKUP_NODE_SSH_PASS_MODE'} ne "manual" && $config_value{'BACKUP_NODE_SSH_PASS_MODE'} ne "passfile"
        && $config_value{'BACKUP_NODE_SSH_PASS_MODE'} ne "nopass" ){
       printlog("ERROR", COMMON_MS0034, "BACKUP_NODE_SSH_PASS_MODE");
    }
    if ($config_value{'PEER_NODE_SSH_PASS_MODE'} eq "passfile"){
        if (!defined($config_value{'PEER_NODE_SSH_PASS_FILE'})){ 
          printlog("ERROR", COMMON_MS0004, "PEER_NODE_SSH_PASS_FILE");
        }
        if ($config_value{'PEER_NODE_SSH_PASS_FILE'} !~ /^\//){
          printlog("ERROR", COMMON_MS0005, "PEER_NODE_SSH_PASS_FILE");
        }
        my $mode = (stat($config_value{'PEER_NODE_SSH_PASS_FILE'} ))[2];
        my $passfile_rwx = sprintf ("%o", S_IMODE($mode));
        if ($passfile_rwx ne "600"){
          printlog("ERROR", COMMON_MS0058, $config_value{'PEER_NODE_SSH_PASS_FILE'});
        }
    }
    if ($config_value{'BACKUP_NODE_SSH_PASS_MODE'} eq "passfile"){
        if (!defined($config_value{'BACKUP_NODE_SSH_PASS_FILE'})){
          printlog("ERROR", COMMON_MS0004, "BACKUP_NODE_SSH_PASS_FILE");
        }
        if ($config_value{'BACKUP_NODE_SSH_PASS_FILE'} !~ /^\//){
          printlog("ERROR", COMMON_MS0005, "BACKUP_NODE_SSH_PASS_FILE");
        }
        my $mode = (stat($config_value{'BACKUP_NODE_SSH_PASS_FILE'} ))[2];
        my $passfile_rwx = sprintf ("%o", S_IMODE($mode));
        if ($passfile_rwx ne "600"){
          printlog("ERROR", COMMON_MS0058, $config_value{'BACKUP_NODE_SSH_PASS_FILE'});
        }
    }
    # IPADDR_STANDBY が disable の場合、IPADDR_STANDBY_ResourceID の値を空にする
    if ($config_value{'IPADDR_STANDBY'} eq "disable"){
        $config_value{'IPADDR_STANDBY_ResourceID'} = "";
    }

    # STONITH が enable の場合、 Group のリソース ID を配列に分解しハッシュに格納する
    # また、disable の場合、STONITH_ResourceID の値を空にする
    if ($config_value{'STONITH'} eq "enable" && exists($config_value{'STONITH_ResourceID'})){
        my @stonith_resources = split(/\s*,\s*/, $config_value{'STONITH_ResourceID'});
        if (scalar(@stonith_resources) != 2){
            printlog("ERROR", COMMON_MS0022);
        }
        $config_value{'STONITH_ResourceID'} = [$stonith_resources[0], $stonith_resources[1]];
    }
    else{
        $config_value{'STONITH_ResourceID'} = "";
    }

    my @ifconfig_ip = ();
    # ","で区切られた D-LAN の IP アドレスをそれぞれ配列に格納
    my @dlan_ipaddr = split(/\s*,\s*/, $config_value{'D_LAN_IPAddress'});
    if (scalar(@dlan_ipaddr) != 2){
        printlog("ERROR", COMMON_MS0007, "D_LAN_IPAddress");
    }

    # IC_LAN_IPAddressのパース
    my $iclan_ipaddr1;
    my $iclan_ipaddr2;
    # IC_LAN_IPAddressのIC-LANが1つで、下記の形式の場合
    # (IPアドレス)
    if ( $config_value{'IC_LAN_IPAddress'} =~ /^\s*\(\s*([^\)]+)\s*\)\s*$/){
        $iclan_ipaddr1 = $1;
        $iclan_ipaddr1  =~ s/^ *(.*?) *$/$1/;
    # IC_LAN_IPAddressのIC-LANが2つで、下記の形式の場合
    # (IPアドレス,IPアドレス)
    } elsif ( $config_value{'IC_LAN_IPAddress'} =~ /^\s*\(\s*([^\)]+)\s*\)\s*,\s*\(\s*([^\)]+)\s*\)\s*$/ ) {
        $iclan_ipaddr1 = $1;
        $iclan_ipaddr2 = $2;
        $iclan_ipaddr1  =~ s/^ *(.*?) *$/$1/;
        $iclan_ipaddr2  =~ s/^ *(.*?) *$/$1/;
    } else {
        printlog("ERROR", COMMON_MS0057, "IC_LAN_IPAddress");
    }

    # ","で区切られた IC-LAN の IP アドレスをそれぞれ配列に格納
    my @iclan_ipaddr1 = split(/\s*,\s*/, $iclan_ipaddr1);
    if (scalar(@iclan_ipaddr1) != 2){
        printlog("ERROR", COMMON_MS0007, "IC_LAN_IPAddress");
    }
    my @iclan_ipaddr2;
    if(defined($iclan_ipaddr2)){
        @iclan_ipaddr2 = split(/\s*,\s*/, $iclan_ipaddr2);
        if (scalar(@iclan_ipaddr2) != 2){
            printlog("ERROR", COMMON_MS0007, "IC_LAN_IPAddress");
        }
    }

    # コマンド実行マシンに設定してある IP アドレスを配列に格納
    $result = `$IFCONFIG | $GREP -P "inet (addr:)?"`;
    my @ifconfig_strings = split(/\n/, $result);
    foreach my $line (@ifconfig_strings){
        # IP address format(RHEL6) : <inet addr:<value>>
        # IP address format(RHEL7) : <inet <value>>
        if ($line =~ /inet\s(addr:)?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/) {
            push (@ifconfig_ip , $2);
        }
    }
    if (!scalar(@ifconfig_ip)){
        printlog("ERROR", COMMON_MS0008);
    }

    foreach my $line (@dlan_ipaddr){
        if (grep {$_ eq $line} @ifconfig_ip){
            $config_value{'My_D_LAN_IPAddress'} = $line;
        }
        else {
            $config_value{'Another_D_LAN_IPAddress'} = $line;
        }
    }

    if (!exists($config_value{'My_D_LAN_IPAddress'})){
        printlog("ERROR", COMMON_MS0009, "D_LAN_IPAddress", $config_value{'D_LAN_IPAddress'});
    }
    if (!exists($config_value{'Another_D_LAN_IPAddress'})){
        printlog("ERROR", COMMON_MS0010, "D_LAN_IPAddress", $config_value{'D_LAN_IPAddress'});
    }

    foreach my $line (@iclan_ipaddr1){
        if (grep {$_ eq $line} @ifconfig_ip){
            $config_value{'My_IC_LAN_IPAddress1'} = $line;
        }
        else {
            $config_value{'Another_IC_LAN_IPAddress1'} = $line;
        }
    }

    if (!exists($config_value{'My_IC_LAN_IPAddress1'})){
        printlog("ERROR", COMMON_MS0009, "IC_LAN_IPAddress", "($iclan_ipaddr1)");
    }
    if (!exists($config_value{'Another_IC_LAN_IPAddress1'})){
        printlog("ERROR", COMMON_MS0010, "IC_LAN_IPAddress", "($iclan_ipaddr1)");
    }

    if (defined($iclan_ipaddr2)){
        foreach my $line (@iclan_ipaddr2){
            if (grep {$_ eq $line} @ifconfig_ip){
                $config_value{'My_IC_LAN_IPAddress2'} = $line;
            }
            else {
                $config_value{'Another_IC_LAN_IPAddress2'} = $line;
            }
        }

        if (!exists($config_value{'My_IC_LAN_IPAddress2'})){
            printlog("ERROR", COMMON_MS0009, "IC_LAN_IPAddress", "($iclan_ipaddr2)");
        }
        if (!exists($config_value{'Another_IC_LAN_IPAddress2'})){
            printlog("ERROR", COMMON_MS0010, "IC_LAN_IPAddress", "($iclan_ipaddr2)");
        }
    }
    if ( $config_value{'HACLUSTER_NAME'} !~ /^[_0-9A-Za-z]+[\-_0-9A-Za-z]*$/){
        printlog("ERROR", COMMON_MS0057, "HACLUSTER_NAME");
    }

    return %config_value;
}


sub exec_command {
    my ($command) = @_;
    my $result;
    my $exit_code;

    $result = `$command`;
    $exit_code = $? >> 8;
    if ($exit_code != 0){
        printlog("ERROR", COMMON_MS0011, $command);
    }

    return $result;
}


sub ssh_exec_command {
    my ($ssh_info, $command, $no_exit_flag) = @_;
    my @results;
    my $ssh;

    if ($ssh_info->pass() eq ""){
        $ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user());
    }
    else{
        $ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user(), password => $ssh_info->pass());
    }
    if (defined($no_exit_flag)){
        $ssh->error and $results[2] = $ssh->error;
    } else {
        $ssh->error and printlog("ERROR", COMMON_MS0016);
    }

    $results[0] = $ssh->capture($command);
    $results[1] = $? >> 8;
    if ($results[0]){
        chomp $results[0];
    }

    return @results;
}

sub scp_exec_command {
    my ($ssh_info, $remote, $local) = @_; 
    my $ssh;

    if ($ssh_info->pass() eq ""){
        $ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user());
    }
    else{
        $ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user(), password => $ssh_info->pass());
    }
    $ssh->error and printlog("ERROR", COMMON_MS0016);

    $ssh-> scp_get({copy_attrs => 1}, $remote, $local) or $ssh->error and printlog("ERROR", COMMON_MS0018);

    return 0;
}


sub get_xlog_filename{
    my ($xlog_location, $this_time_line_id) = @_;
    my $uxlog_id;
    my $uxrec_off;
    my $xlog_id;
    my $xlog_seg;
    my $xlog_filename;
    
    # XLOG 位置の情報をパース
    # xlog location format : <xlogid>/<xrecoff>
    # <xlogid>と<xrecoff>は16進数
    if ($xlog_location !~ /^([0-9A-F]+)\/([0-9A-F]+)$/){
        printlog("ERROR", COMMON_MS0013);
    }
    $uxlog_id = $1;
    $uxrec_off = $2;

    # 一つ前のセグメントを取得
    # $xlog_segは、上で取得した16進数の値から1を引いて5桁以下をシフトした値になる
    $xlog_id = hex($uxlog_id);
    my $uxrec_off_tmp = hex($uxrec_off);
    $xlog_seg = sprintf("%d", ($uxrec_off_tmp - 1)/(16 ** 6));

    # 一つ前のセグメントの WAL ファイル名を取得
    $xlog_filename = sprintf("%08X%08X%08X", $this_time_line_id, $xlog_id, $xlog_seg);

    return $xlog_filename;
}

sub compare_lsn{
    my ($lsn1, $lsn2) = @_;
    my $lsn1_left_field;
    my $lsn1_right_field;
    my $lsn2_left_field;
    my $lsn2_right_field;

    if ($lsn1 !~ /^([0-9A-F]+)\/([0-9A-F]+)$/){
        printlog("ERROR", COMMON_MS0013);
    }
    $lsn1_left_field = hex($1);
    $lsn1_right_field = hex($2);

    if ($lsn2 !~ /^([0-9A-F]+)\/([0-9A-F]+)$/){
        printlog("ERROR", COMMON_MS0013);
    }
    $lsn2_left_field = hex($1);
    $lsn2_right_field = hex($2);

    if ($lsn1_left_field > $lsn2_left_field){
        return 1;
    } elsif ($lsn1_left_field == $lsn2_left_field){
        if ($lsn1_right_field > $lsn2_right_field){
            return 1;
        } elsif ($lsn1_right_field == $lsn2_right_field){
            return 0;
        } else {
            return -1;
        }
    } else {
        return -1;
    }
}

sub get_controldata_value{
    my (@controldata_strings) = @_;
    my %controldata_value;
    my @check_key_list = ("pg_control last modified", "Database system identifier", "Latest checkpoint's TimeLineID", "Latest checkpoint's REDO location", "Latest checkpoint's REDO WAL file");

	my @key_val;

	foreach my $line (@controldata_strings) {
		@key_val = split(/:/, $line);
		($controldata_value{$key_val[0]} = $key_val[1]) =~ s/^ *(.*?) *$/$1/;
	}

    foreach my $key (@check_key_list) {
        if (!exists($controldata_value{$key})){
            printlog("ERROR", COMMON_MS0014);
        }
    }


    return \%controldata_value;
}

sub get_start_wal_filename {
    my ($backup_label_path, @backup_label_strings) = @_;

    # backup_label file first line format : START WAL LOCATION: <xlog location> (file <file name>)
    if (!$backup_label_strings[0] || $backup_label_strings[0] !~ /^START\s+WAL\s+LOCATION:\s+[0-9A-F\/]+\s+\(file\s([0-9A-F]+)\)\s*$/){
        printlog("ERROR", COMMON_MS0045, $backup_label_path);
    }
    return $1;
}

sub get_recoverywal {
    my (@controldata_strings) = @_;
    my $wal = '';

    my $controldata_value = (get_controldata_value(@controldata_strings));

    $wal = get_xlog_filename($controldata_value->{"Latest checkpoint's REDO location"}, $controldata_value->{"Latest checkpoint's TimeLineID"});

    return $wal;
}

sub get_restore_archivewal_num {
    my ($dbcluster_dir, $archive_dir, $start_wal_filename) = @_;
    my $latest_archive_walfile;
    my $xlog_id1 = 0;
    my $xlog_id2 = 0;
    my $segment_id1 = 0;
    my $segment_id2 = 0;
    my $result;
    my $wal_segment_num;

    $result = `$LS -lH $archive_dir | $GREP -P \"[0-9A-F]{24}\$\" | $TAIL -1`;
    if ($result && $result =~ /.*([0-9A-F]{24})$/){
        $latest_archive_walfile = $1;
        chomp $latest_archive_walfile;
    }

    if ($latest_archive_walfile && $latest_archive_walfile =~ /^[0-9A-F]{8}([0-9A-F]{8})([0-9A-F]{8})$/){
        $xlog_id1 = $1;
        $segment_id1 = $2;
    }

    if ($start_wal_filename && $start_wal_filename =~ /^[0-9A-F]{8}([0-9A-F]{8})([0-9A-F]{8})$/){
        $xlog_id2 = $1;
        $segment_id2 = $2;
    }

    $wal_segment_num = (256 * (hex($xlog_id1) - hex($xlog_id2)) + hex($segment_id1) - hex($segment_id2) + 1);
    if ($wal_segment_num < 0){
        $wal_segment_num = 0;
    }
    return $wal_segment_num;
}

sub get_node{
    my ($ssh_info) = @_;
    my @results;
    my $exec_user;
    my %node_value = ("my_node"      => '',
                      "another_node" => '');

    $node_value{'my_node'} = exec_command("$UNAME -n");
    chomp $node_value{'my_node'};

    if ($ssh_info->user()){
        $exec_user = $ssh_info->user();
    }
    else{
        $exec_user = "root";
    }

    @results = ssh_exec_command($ssh_info, "$UNAME -n");
    $node_value{'another_node'} = $results[0];
    chomp $node_value{'another_node'};

    if (!$node_value{'another_node'}){
        printlog("ERROR", COMMON_MS0015);
    }

    return %node_value;
}


sub get_pg_version_num {
    my ($postgres_path, $exec_user) = @_;
    my $result;
    my $pg_command_user = "postgres";
    my $version_num;

    if (defined($exec_user) && $exec_user ne "root"){
        $result = exec_command("$postgres_path --version");
    } else {
        $result = exec_command("$SU - $pg_command_user -c  \"$postgres_path --version\"");
    }

    $result =~ /(\d+)(?:[^\.]+)?(?:\.(\d+)(?:[^\.]+)?)?(?:\.(\d+))?$/;
    if ($1 >= 10){
        # PostgreSQL 10以上の場合
        # $1 : Major Version
        # $2 : Minor Version
        # $2が未定義の場合は、betaまたはrc版
        if (!defined($2)){
            $version_num = 10000 * $1;
        }
        else{
            $version_num = 10000 * $1 + $2;
        }
    }
    else{
        # PostgreSQL 9.6以下の場合
        # $1.$2 : Major Version
        # $3    : Minor Version
        # $3が未定義の場合は、betaまたはrc版
        if (!defined($3)){
            $version_num = 100 * (100 * $1 + $2);
        }
        else{
            $version_num = 100 * (100 * $1 + $2) + $3;
        }
    }
    return $version_num;
}

sub check_support_version {
    my ($postgres_path, $exec_user) = @_;
    my @version_factor;
    my $version_num;

    # Pacemaker がサポート対象バージョンであるかを確認する
    @version_factor = split(/\./, get_pm_version());
    if (!($version_factor[0] == 2)){
        printlog("ERROR", COMMON_MS0038, get_pm_version());
    }

    # PostgreSQL がサポート対象バージョンであるかを確認する
    $version_num = get_pg_version_num($postgres_path, $exec_user);
    if (int($version_num / 10000) != 15){
        if ($version_num >= 100000) {
            printlog("ERROR", COMMON_MS0037, int($version_num / 10000));
        } else {
            printlog("ERROR", COMMON_MS0037, sprintf("%d.%d",
                int($version_num / 10000), int(($version_num / 100) % 100)));
        }
    }
}

sub get_pg_command_path {
    my ($pg_path, $exec_user) = @_;
    my @command_list = ("postgres", "psql", "pg_controldata", "pg_basebackup", "pg_waldump", "pg_rewind");
    my $pg_command_user = "postgres";
    my %command_path;
    my $pg_config_path;
    my $pgbin;
    my @missing_commands = ();
    my $exit_code;

    # PostgreSQL の bin ディレクトリのパスを pg_config から取得する
    # PGPATH が指定されている場合は PGPATH 配下の pg_config を使用する
    # PGPATH が指定されていない場合は PATH 経由の pg_config を使用する
    if ($pg_path) {
        $pg_config_path = File::Spec->catfile($pg_path, "pg_config");
        $pgbin = `$pg_config_path --bindir 2> /dev/null`;
    } else {
        $pg_config_path = "pg_config";
        if (!$exec_user || $exec_user eq "root") {
            $pgbin = `$SU - $pg_command_user -c "$pg_config_path --bindir 2> /dev/null"`;
        } else {
            $pgbin = `$pg_config_path --bindir 2> /dev/null`;
        }
    }
    $exit_code = $? >> 8;
    if ($exit_code != 0) {
        printlog("ERROR", COMMON_MS0011, $pg_config_path);
    }
    chomp $pgbin;

    # PostgreSQLコマンドのコマンドパスを生成して返却する
    # 存在しないコマンドがある場合は異常終了する
    foreach (@command_list) {
        $command_path{$_} = File::Spec->catfile($pgbin, $_);
        `$WHICH $command_path{$_} 2> /dev/null`;
        $exit_code = $? >> 8;
        if ($exit_code != 0) {
            push(@missing_commands, $_);
        }
    }

    printlog("DEBUG", "PostgreSQL command path :\n[0]\n", join("\n", values %command_path));

    if (@missing_commands) {
        printlog("ERROR", COMMON_MS0036, $pgbin, join(',', @missing_commands));
    }

    return %command_path;
}

sub get_pm_version{
    my $result;
    my @results;

    $result = exec_command("$PACEMAKERD --version");

    @results = split(/\s/,$result);
    chomp $results[1];

    return $results[1];
}

sub get_pg_dir_state {
    my ($dbcluster_dir, $archive_dir) = @_;
    my %pg_dir_state;

    my $pg_dir_state = new Pg_dir_state();

    $pg_dir_state->pgdata_exist(0);
    $pg_dir_state->pgarch_empty(0);

    if (-d $dbcluster_dir && -f $dbcluster_dir."/postgresql.conf"){
        $pg_dir_state->pgdata_exist(1);
    }

    if (-d $archive_dir){
        opendir my $dh, $archive_dir or printlog("ERROR", COMMON_MS0044, $archive_dir);
        if (! grep {$_ ne '.' && $_ ne '..'} readdir $dh){
            $pg_dir_state->pgarch_empty(1);
        }
        closedir($dh);
    }
    else {
        $pg_dir_state->pgarch_empty(1);
    }
    return $pg_dir_state;
}

sub check_user{
    my $result;

    $result = exec_command("$WHOAMI");
    chomp $result;
    if ($result ne "root"){
        printlog("ERROR", COMMON_MS0026, $result);
    }
}


sub printlog {
    my ($log_level, $message, @values) = @_;

    for (my $count=0; $count < scalar(@values); $count++){
        $message =~ s/\[$count\]/$values[$count]/g;
    }

    if ($log_level eq "ERROR"){
        print $message;
		exit(1);
    }
	elsif ($log_level eq "DEBUG"){
		if ($PGRex::common::additional_information_mode) {
			print $message;
		}
	}
    else{
        print $message;
    }

}


sub get_ssh_passwd {
    # PG-REX相手ノードへの ssh 接続の為の情報を取得
    my ($another_dlan_ipaddr, $ssh_pass_mode, $ssh_pass_file) = @_;
    my $exec_user;
    my $passwd;
    my @file_stat;
    my $file_permission;

    $exec_user = exec_command("$WHOAMI");
    chomp $exec_user;

    if ($ssh_pass_mode eq "manual"){
        printlog("LOG", COMMON_MS0029, $exec_user, $another_dlan_ipaddr);
        `$STTY -echo`;
        $passwd = <STDIN>;
        chomp $passwd;
        `$STTY echo`;
        printlog("LOG", COMMON_MS0030);
    }
    elsif ($ssh_pass_mode eq "nopass"){
        $passwd = "";
    }
    else {
        if (! -f $ssh_pass_file){
            printlog("ERROR", COMMON_MS0031, $ssh_pass_file);
        }
        # パスワードファイルの権限が600に設定されているかの確認
        @file_stat = stat($ssh_pass_file);
        $file_permission = substr((sprintf "%03o", $file_stat[2]), -3);
        if ($file_permission ne "600"){
             printlog("ERROR", COMMON_MS0035, $ssh_pass_file);
        }

        open (FILE, $ssh_pass_file) or printlog("ERROR", COMMON_MS0032, $ssh_pass_file);
        $passwd = <FILE>;
        close (FILE);
        
        if (!defined($passwd)){
            printlog("ERROR", COMMON_MS0033, $ssh_pass_file);
        }
        
        chomp $passwd;

        if ( $passwd eq "" ){
            printlog("ERROR", COMMON_MS0033, $ssh_pass_file);
        }
    }

    return $passwd;
}


sub check_dbcluster_access {
    my ($cluster_path) = @_;
    my %procs;
    my $result = "";

	stat $LSOF || printlog("ERROR", COMMON_MS0053, $LSOF, $!);

    open my $in, '-|', "$LSOF +D $cluster_path -F cuLR0 2> /dev/null" || printlog("ERROR", COMMON_MS0046, $!);
	# Suppress display of stderr only, because error of lsof command is unknown

    my $pid = 0;
    while (<$in>) {
        while (/([a-zA-Z])([^\x00]+)\x00/g) {
            if ($1 eq "p") {
                $pid = $2;
            } elsif ($pid == 0 || ($1 ne 'f' && defined $procs{$pid}{$1})) {
                printlog("ERROR", COMMON_MS0056, ": $_\n");
            } else {
                $procs{$pid}{$1} .= ', ' if (defined $procs{$pid}{$1});
                $procs{$pid}{$1} .= $2;
            }
        }
    }
    close $in;

    if (keys %procs) {
        foreach my $key (keys %procs) {
            # filter out forked children
            next if (defined $procs{$procs{$key}{R}});

            $result .= "PID: $key / COMMAND: $procs{$key}{c}, USER=$procs{$key}{L}($procs{$key}{u})\n";
        }
        printlog("ERROR", COMMON_MS0047, $result);
    }
}


sub create_pid_file {
    my $pid_fullname = PID_FILEDIR."/".PID_FILENAME;
    my $pid;
    my $exit_code;

    for(my $ntries = 0; ; $ntries++) {

        # create pid file
        if (sysopen my $handle, "$pid_fullname", O_WRONLY|O_CREAT|O_EXCL) {
            print $handle "$$";
            close $handle;
            return;
        } elsif ($! != Errno::EEXIST) {
            printlog("ERROR", COMMON_MS0048, PID_FILENAME, $!);
        }

		if ($ntries > 5) {
			last;
		}
		$ntries != 0 && sleep 1;

        # check pid file
		open FILE, "< $pid_fullname" || continue;
		$pid = <FILE>; # If it can not read, $pid is UNDEF
		close FILE;

		# other pg-rex_tool has already started
		if (defined($pid)) {
			chomp $pid;
			if ($pid ne "") {
				`$KILL -s 0 $pid 2> /dev/null`;
				$exit_code = $? >> 8;
				if ($exit_code == 0) {
					printlog("ERROR", COMMON_MS0049, $pid);
				}
			}
		}

        # unlink pid file
        unlink $pid_fullname;
		if ($! == Errno::EISDIR) {
			printlog("ERROR", COMMON_MS0051, $!);
		}
    }

    printlog("ERROR", COMMON_MS0050, PID_FILENAME);
}

sub unlink_pid_file {
    my $pid_fullname = PID_FILEDIR."/".PID_FILENAME;

    if (!unlink $pid_fullname) {
        printlog("LOG", COMMON_MS0051, PID_FILENAME, $!);
    }
}

sub is_ipv4_format{
    # 引数に指定されたIPアドレスがIPv4の形式であるかを確認する
    # IPv4の形式の場合は、戻り値に「0」を返却する
    # IPv4の形式でない場合は、戻り値に「1」を返却する
    # チェック対象のIPアドレスは、コマンド実行結果から取得しているため、
    # 厳密なIPv4の正規表現でIPアドレスであるかは確認しない
    my ($ipaddr) = @_;
    if ($ipaddr =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/){
        return 1; # OK
    } else {
        return 0; # NG
    }
}

# ローカルとリモートのディレクトリの差分から、サイズ情報を含む同期対象ファイルを取得する
# 返却値のsync_filesはkeyが同期対象ファイル名、valueがファイルサイズのハッシュ
sub get_sync_files {
	my ($ssh_info, $remote_dir, $local_dir, $local_flag) = @_;
	my @local_ls = ();
	my @remote_ls = ();
	my @sync_filelist_to_remote = ();
	my @sync_filelist_to_local = ();
	my %cnt = ();
	my %sync_files = ();

	# ローカルのアーカイブ一覧取得
	@local_ls = `$LS -go $local_dir | $AWK '{print \$3,\$7}'`;
	chomp @local_ls;
	shift(@local_ls);

	# リモートのアーカイブ一覧取得
	my $command = "$LS -go $remote_dir | $AWK '{print \$3,\$7}'";
	my @results = ssh_exec_command($ssh_info, $command);
	@remote_ls = split(/\n/, $results[0]);
	shift(@remote_ls);

	# ハッシュの初期化
	map { $cnt{$_}-- } @remote_ls;

	# ローカルにのみ存在するものおよびファイルサイズが異なるものを抽出
	@sync_filelist_to_remote = grep { ++$cnt{$_} == 1 } @local_ls;

	# ローカルを基準にする場合は、上記で抽出したリストから返却値用のハッシュを生成する
	# ローカルを基準にしない場合は、リモートにのみ存在するものおよびファイルサイズが異なるものを抽出し、
	# 返却値用のハッシュを生成する
	if ($local_flag) {
		foreach (@sync_filelist_to_remote){
			if ($_ =~ /^\s*(\d+)\s(.+)$/ ) {
				$sync_files{$2} = $1;
			}
		}
	} else {
		@sync_filelist_to_local = grep { $cnt{$_} == -1 } @remote_ls;
		foreach (@sync_filelist_to_local){
			if ($_ =~ /^\s*(\d+)\s(.+)$/ ) {
				$sync_files{$2} = $1;
			}
		}
	}
	
	return %sync_files;
}

# ローカルのアーカイブファイルをリモートへ送信する
sub send_archive {
	my ($ssh_info, $dir, $bytes_per_wal_segment, $sync_targets) = @_;
	my $ssh;

	if ($ssh_info->pass() eq ""){
		$ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user());
	} else {
		$ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user(), password => $ssh_info->pass());
	}
	$ssh->error and printlog("ERROR", COMMON_MS0016);

	foreach my $name (sort keys %$sync_targets){
		my $size = $$sync_targets{$name};
		if ((my $ret = check_archivefile_size($name, $size, $bytes_per_wal_segment)) > 0 ){
			if ($ret == 1) {
				# アーカイブWALのサイズが制御ファイルの"Bytes per WAL segment"と一致しない
				printlog("ERROR", COMMON_MS0055, $name, $bytes_per_wal_segment);
			}
			if ($ret == 2) {
				# アーカイブWAL以外のサイズが0
				printlog("ERROR", COMMON_MS0054, $name);
			}
		}
		open(my $LOCAL, "$TAR czf - -C $dir $name |");
		my $REMOTE = $ssh->pipe_in("$TAR mzxvf - -C $dir");
		while (my $line = <$LOCAL>) {
			print($REMOTE $line);
		}
		close $LOCAL;
		close $REMOTE;
	}
	undef $ssh;
}

# リモートのアーカイブファイルをローカルに受信する
sub receive_archive {
	my ($ssh_info, $dir, $bytes_per_wal_segment, $sync_targets) = @_;
	my $ssh;

	if ($ssh_info->pass() eq ""){
		$ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user());
	} else {
		$ssh = Net::OpenSSH->new($ssh_info->address(), user => $ssh_info->user(), password => $ssh_info->pass());
	}
	$ssh->error and printlog("ERROR", COMMON_MS0016);

	foreach my $name (sort keys %$sync_targets){
		my $size = $$sync_targets{$name};
		if ((my $ret = check_archivefile_size($name, $size, $bytes_per_wal_segment)) > 0 ){
			if ($ret == 1) {
				# アーカイブWALのサイズが制御ファイルの"Bytes per WAL segment"と一致しない
				printlog("ERROR", COMMON_MS0055, $name, $bytes_per_wal_segment);
			}
			if ($ret == 2) {
				# アーカイブWAL以外のサイズが0
				printlog("ERROR", COMMON_MS0054, $name);
			}
		}
		my $REMOTE = $ssh->pipe_out("$TAR czf - -C $dir $name");
		open(my $LOCAL, "| $TAR mzxvf - -C $dir");
		while (my $line = <$REMOTE>) {
			print($LOCAL $line);
		}
		close $REMOTE;
		close $LOCAL;
	}
	undef $ssh;
}

# アーカイブファイルのサイズの妥当性を確認する (正常であれば0を返却する)
#  - アーカイブWALの場合、指定されたサイズと一致することを確認する
#    一致しない場合は1を返却する
#  - アーカイブWAL以外の場合、サイズが0でないことを確認する
#    サイズが0の場合は2を返却する
# 
# ※  圧縮されたアーカイブWALはサイズが0でないことを確認する 
sub check_archivefile_size {
	my ($name, $size, $expected_size) = @_;

	# アーカイブWALのサイズ確認
	if ($name =~ /^[0-9A-F]{24}$/) {
		if ($size != $expected_size){
			return 1;
		}
	}

	# アーカイブWAL以外のサイズ確認
	if ($name =~ /^([0-9A-F]{24})(\.gz|\.bz2)$/ || 
	    $name =~ /^(.*)(\.history|\.partial|\.backup)(\.gz|\.bz2)?$/) {
		if ($size == 0){
			return 2;
		}
	}

	return 0;
}

1;

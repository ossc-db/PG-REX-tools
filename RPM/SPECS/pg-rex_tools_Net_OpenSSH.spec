Name: Net_OpenSSH
Version: 0.62
Release: 1%{?dist}
Group: Development/Tools
URL: http://search.cpan.org/dist/Net-OpenSSH/
Packager: NIPPON TELEGRAPH AND TELEPHONE CORPORATION
License: The Perl 5 License (Artistic 1 & GPL 1) http://dev.perl.org/licenses/
Summary: Perl SSH client package implemented on top of OpenSSH.
Summary(ja): PerlでOpenSSHのラッパとして実装された SSHクライアントパッケージ。
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: x86_64
Source0: Net-OpenSSH-0.62.tar.gz

%define __check_files %{nil}

%description
Built for PG-REX operation scripts.

%description -l ja
PG-REX運用スクリプトで使用するためにビルド。

%prep
%setup -n Net-OpenSSH-0.62

%build
/usr/bin/perl Makefile.PL
/usr/bin/make

%install
/usr/bin/make DESTDIR=${RPM_BUILD_ROOT} pure_install

%clean
/bin/rm -rf ${RPM_BUILD_DIR}/*

%files
%defattr(-,root,root)
/usr



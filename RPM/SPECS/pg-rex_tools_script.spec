Name:        pg-rex_operation_tools_script
Version:     15.1
Release:     1%{?dist}
Group:       Development/Tools
Packager:    NIPPON TELEGRAPH AND TELEPHONE CORPORATION
License:     BSD
Summary:     PG-REX operation tools. 
Summary(ja): PG-REX 運用補助ツール
Buildroot:   %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:   noarch
Source0:     pg-rex_operation_tools-%{version}.tar.gz
Provides:    perl(PGRex::common)

%define PREFIX /usr/local

%{?perl_default_filter}

%description
PG-REX operation tools.

%prep
%setup -q -n pg-rex_operation_tools-%{version}

%build
perl Makefile.PL PREFIX=%{PREFIX}
make

%install
rm -rf %{buildroot}


make DESTDIR=${RPM_BUILD_ROOT} pure_install
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
%{_fixperms} %{buildroot}/*
mkdir %{buildroot}/etc
cp pg-rex_tools.conf %{buildroot}/etc/

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{PREFIX}/bin/pg-rex_primary_start
%{PREFIX}/bin/pg-rex_standby_start
%{PREFIX}/bin/pg-rex_stop
%{PREFIX}/bin/pg-rex_archivefile_delete
%{PREFIX}/bin/pg-rex_switchover
%{PREFIX}/share/perl5/PGRex/command.pm
%{PREFIX}/share/perl5/PGRex/common.pm
%{PREFIX}/share/perl5/PGRex/Po/en.pm
%{PREFIX}/share/perl5/PGRex/Po/ja.pm
/etc/pg-rex_tools.conf

#%defattr(0644,root,root)
%{PREFIX}/share/man/man1/pg-rex_tools_manual-ja.html

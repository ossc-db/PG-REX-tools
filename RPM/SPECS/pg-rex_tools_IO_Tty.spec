Name: IO_Tty
Version: 1.11
Release: 1%{?dist}
Group: Development/Tools
URL: http://search.cpan.org/dist/IO-Tty/
Packager:  NIPPON TELEGRAPH AND TELEPHONE CORPORATION
License: The Perl 5 License (Artistic 1 & GPL 1) http://dev.perl.org/licenses/
Summary: Perl Low-level allocate a pseudo-Tty.
Summary(ja): Perlでの仮想TTY低レベル割り当て。
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: x86_64
Source0: IO-Tty-%{version}.tar.gz

%{?perl_default_fileter}

%description
Built for PG-REX operation scripts.

%description -l ja
PG-REX運用スクリプトで使用するためにビルド。

%prep
%setup -q -n IO-Tty-%{version}

%build
perl Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}"
make %{?_smp_mflags}

%install
/usr/bin/make DESTDIR=${RPM_BUILD_ROOT} pure_install
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
%{_fixperms} %{buildroot}/*

%clean
/bin/rm -rf ${RPM_BUILD_DIR}/*

%files
%defattr(-,root,root)
%doc ChangeLog README
%{perl_vendorarch}/auto/IO/
%{perl_vendorarch}/IO/
%{_mandir}/man3/*.3pm*

Name:       tzdata-timed

Summary:    Data files for the time daemon, timed
Version:    2021a
Release:    1
License:    Public Domain
BuildArch:  noarch
URL:        https://github.com/sailfishos/tzdata-timed
Source0:    %{name}-%{version}.tar.bz2
Requires:   tzdata

%description
Timed daemon datafiles that combine information about time zones,
and mobile country codes.

%prep
%setup -q -n %{name}-%{version}

%build
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%make_install

%files
%defattr(-,root,root,-)
%{_datadir}/tzdata-timed

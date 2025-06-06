Name:       tzdata-timed
Summary:    Data files for the time daemon, timed
Version:    2025b
Release:    1
License:    Public Domain
BuildArch:  noarch
BuildRequires: pcre2-tools
URL:        https://github.com/sailfishos/tzdata-timed
Source0:    %{name}-%{version}.tar.bz2
Requires:   tzdata

%description
Timed daemon datafiles that combine information about time zones,
and mobile country codes.

%prep
%autosetup -n %{name}-%{version}

%build
%make_build

%install
%make_install

%files
%{_datadir}/tzdata-timed

# SPEC file overview:
# https://docs.fedoraproject.org/en-US/quick-docs/creating-rpm-packages/#con_rpm-spec-file-overview
# Fedora packaging guidelines:
# https://docs.fedoraproject.org/en-US/packaging-guidelines/

Name: bootupd8r
Version: 1
Release: 8%{?dist}
Summary: Updates boot loaders

License: GPLv3
URL:     https://github.com/marta-lewandowska/bootupd8r

BuildRequires: git
BuildRequires: make

Source0: bootupd8r-%{version}.tar.xz

# For %%_userunitdir and %%systemd_* macros
BuildRequires:  systemd-rpm-macros

BuildArch: noarch

%{?systemd_requires}

%description
bootupd8r creates a fallback mechanism on UEFI for installing new boot loaders.

%prep
%autosetup -S git_am

%install
install -m 0755 -d %{buildroot}%{_prefix}/lib/bootloader
install -m 0755 -d %{buildroot}%{_sbindir}
install -m 0755 -t %{buildroot}%{_sbindir} bootupd8r
install -m 0755 -d %{buildroot}%{_unitdir}
install -m 0644 -t %{buildroot}%{_unitdir} bootupd8r.service
install -m 0755 -d %{buildroot}%{_presetdir}
install -m 0644 -t %{buildroot}%{_presetdir} 91-bootupd8r.preset

%files
%defattr(-,root,root,-)
%dir %{_prefix}/lib/bootloader
%{_sbindir}/bootupd8r
%{_unitdir}/bootupd8r.service
%{_presetdir}/91-bootupd8r.preset

%post
%systemd_post bootupd8r.service

%preun
%systemd_preun bootupd8r.service

%postun
%systemd_postun bootupd8r.service
rm -rf /boot/efi/EFI_NEW/

%posttrans
. %{_sbindir}/bootupd8r create_boot_path

%changelog
* Mon Dec 15 2025 Marta Lewandowska <mlewando@redhat.com> - 1-8
- Lots of little fixes

* Fri Dec 12 2025 Marta Lewandowska <mlewando@redhat.com> - 1-7
- Maybe get the systemd stuff right finally

* Tue Dec 09 2025 Marta Lewandowska <mlewando@redhat.com> - 1-6
- Hopefully fix systemd stuff and some hardening

* Fri Dec 05 2025 Marta Lewandowska <mlewando@redhat.com> - 1-5
- Rename b directory and related changes

* Fri Nov 28 2025 Marta Lewandowska <mlewando@redhat.com> - 1-4
- Fix a bunch of dumb stuff that keeps this from working

* Thu Nov 27 2025 Marta Lewandowska <mlewando@redhat.com> - 1-3
- Add support for config file and consistent install_bootloader

* Mon Nov 24 2025 Pavel Valena <pvalena@redhat.com> - 1-2
- Fixup _unitdir ownership.

* Fri Nov 21 2025 Pavel Valena <pvalena@redhat.com>
- Fixes to Makefile and spec file

* Fri Nov 14 2025 Marta Lewandowska <mlewando@redhat.com>
- First trial of bootupdr

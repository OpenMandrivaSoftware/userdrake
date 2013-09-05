%define debug_package %{nil}
Summary:	A graphical interface for administering users and groups
Name:		userdrake
Version:	1.13.2
Release:	7
#cvs source
# http://www.mandrivalinux.com/en/cvs.php3
Source0:	%{name}-%{version}.tar.lzma
URL:		http://people.mandriva.com/~daouda/mandrake/userdrake.html
License:	GPL
Group:		System/Configuration/Other
Requires:	drakxtools
Requires:	libuser
Requires:	usermode-consoleonly
Requires:	transfugdrake
Suggests:	xguest
BuildRequires:	gettext
BuildRequires:	perl-devel
BuildRequires:	pkgconfig(libuser)
BuildRequires:	pkgconfig(glib-2.0)
BuildRequires:	pam-devel

%description
Userdrake is a user-friendly and powerful tool for administrating users and 
groups. It depends on the libuser library. 

%prep
%setup -q
		
%build
cd USER
%{__perl} Makefile.PL INSTALLDIRS=vendor 
cd ..
make OPTIMIZE="%{optflags} -w" 

%install
make PREFIX=%{buildroot} install 

cd USER
%makeinstall_std
cd ..

#install lang
%find_lang userdrake


mkdir -p %{buildroot}%{_datadir}/applications
cat > %{buildroot}%{_datadir}/applications/mandriva-userdrake.desktop <<EOF
[Desktop Entry]
Name=User Administration
Comment=Add or remove users and groups
Exec=/usr/bin/userdrake
Icon=userdrake
Type=Application
StartupNotify=true
Categories=GTK;System;X-MandrivaLinux-CrossDesktop;
NoDisplay=true
EOF

# consolehelper configuration
ln -sf %{_bindir}/consolehelper %{buildroot}%{_bindir}/userdrake
ln -sf %{_bindir}/userdrake %{buildroot}%{_bindir}/drakuser
mkdir -p %{buildroot}%{_sysconfdir}/pam.d
ln -sf %{_sysconfdir}/pam.d/mandriva-simple-auth %{buildroot}%{_sysconfdir}/pam.d/userdrake
mkdir -p %{buildroot}%{_sysconfdir}/security/console.apps/
cat > %{buildroot}%{_sysconfdir}/security/console.apps/userdrake <<EOF
USER=root
PROGRAM=/usr/sbin/userdrake
FALLBACK=false
SESSION=true
EOF

# userdrake <-> drakuser
ln -s %{_sysconfdir}/pam.d/userdrake %{buildroot}%{_sysconfdir}/pam.d/drakuser
ln -s %{_sysconfdir}/security/console.apps/userdrake \
        %{buildroot}%{_sysconfdir}/security/console.apps/drakuser

%files -f userdrake.lang
%doc README COPYING RELEASE_NOTES
%config(noreplace) %{_sysconfdir}/sysconfig/userdrake
%config(noreplace) %{_sysconfdir}/pam.d/userdrake
%config(noreplace) %{_sysconfdir}/security/console.apps/userdrake
# two symlinks in sysconfdir
%{_sysconfdir}/pam.d/drakuser
%{_sysconfdir}/security/console.apps/drakuser
%{_prefix}/bin/*
%{_prefix}/sbin/*
%{_datadir}/userdrake
%{_mandir}/man3/USER*
%{_datadir}/applications/mandriva-*.desktop
%{perl_vendorarch}/USER.pm
%{perl_vendorarch}/auto/USER
%{_iconsdir}/*.png
%{_miconsdir}/*.png
%{_liconsdir}/*.png



%changelog
* Tue May 10 2011 Funda Wang <fwang@mandriva.org> 1.13.2-4mdv2011.0
+ Revision: 673273
- tweak br

  + Oden Eriksson <oeriksson@mandriva.com>
    - mass rebuild

* Sun Aug 01 2010 Funda Wang <fwang@mandriva.org> 1.13.2-3mdv2011.0
+ Revision: 564291
- rebuild for new perl 5.12.1

* Thu Jul 22 2010 Pascal Terjan <pterjan@mandriva.org> 1.13.2-2mdv2011.0
+ Revision: 556905
- Use toplevel Makefile, to get the defines
- define PACKAGE_NAME, it is used by libuser definition of _
- update translations

* Tue Feb 02 2010 Thierry Vignaud <tv@mandriva.org> 1.13-1mdv2010.1
+ Revision: 499543
- do not crash when trying to rename a user to an already existing name
- make libuser binding i18n aware
- refactorization for readability (please test)
- use libuser translations

* Wed Oct 21 2009 Christophe Fergeau <cfergeau@mandriva.com> 1.12-1mdv2010.0
+ Revision: 458573
- 1.12:
- refresh user list when adding/removing xguest

* Sat Oct 17 2009 Thierry Vignaud <tv@mandriva.org> 1.11-1mdv2010.0
+ Revision: 458036
- enable to install/uninstall xguest account from 'actions' menu (#54498)

* Wed Oct 14 2009 Thierry Vignaud <tv@mandriva.org> 1.10-2mdv2010.0
+ Revision: 457243
- Suggests xguest

* Tue Sep 08 2009 AurÃ©lien Lefebvre <alefebvre@mandriva.com> 1.10-1mdv2010.0
+ Revision: 433756
- added password weakness check
- userdrake specfile update
- specfile updated

  + Thierry Vignaud <tv@mandriva.org>
    - bump require on drakxtools for new API

* Wed Apr 15 2009 Thierry Vignaud <tv@mandriva.org> 1.9.1-1mdv2009.1
+ Revision: 367506
- translation updates

* Mon Mar 30 2009 Thierry Vignaud <tv@mandriva.org> 1.9-1mdv2009.1
+ Revision: 362306
- do not crash if some face images are missing (#45024)
- translation updates

* Sat Mar 07 2009 Antoine Ginies <aginies@mandriva.com> 1.8-3mdv2009.1
+ Revision: 351445
- rebuild

* Mon Sep 22 2008 Thierry Vignaud <tv@mandriva.org> 1.8-2mdv2009.0
+ Revision: 287080
- translation updates

* Wed Jun 18 2008 Thierry Vignaud <tv@mandriva.org> 1.7-2mdv2009.0
+ Revision: 225911
- rebuild

  + Pixel <pixel@mandriva.com>
    - rpm filetriggers deprecates update_menus/update_scrollkeeper/update_mime_database/update_icon_cache/update_desktop_database/post_install_gconf_schemas

* Thu Apr 03 2008 Thierry Vignaud <tv@mandriva.org> 1.7-1mdv2008.1
+ Revision: 192103
- translation updates

* Tue Mar 25 2008 Thierry Vignaud <tv@mandriva.org> 1.6-1mdv2008.1
+ Revision: 190124
- translation updates

* Mon Mar 10 2008 Thierry Vignaud <tv@mandriva.org> 1.5-1mdv2008.1
+ Revision: 183759
- renamed Uzbek translations to follow the libc standard (#35090)
- updated translation

* Tue Jan 15 2008 Thierry Vignaud <tv@mandriva.org> 1.4-2mdv2008.1
+ Revision: 152167
- rebuild for new perl
- drop old menu
- kill re-definition of %%buildroot on Pixel's request

  + Olivier Blin <oblin@mandriva.com>
    - restore BuildRoot

* Wed Oct 03 2007 Thierry Vignaud <tv@mandriva.org> 1.4-1mdv2008.0
+ Revision: 95024
- updated translation

* Fri Sep 28 2007 Thierry Vignaud <tv@mandriva.org> 1.3-3mdv2008.0
+ Revision: 93602
- updated translation
- Requires transfugdrake in order to be able to check for windows partitions

* Mon Sep 24 2007 Thierry Vignaud <tv@mandriva.org> 1.2.11-3mdv2008.0
+ Revision: 92528
- enable to run migration assistant when adding a user

* Tue Sep 18 2007 Thierry Vignaud <tv@mandriva.org> 1.2.10-3mdv2008.0
+ Revision: 89787
- hide menu entry

* Thu Sep 13 2007 Andreas Hasenack <andreas@mandriva.com> 1.2.10-2mdv2008.0
+ Revision: 84834
- use new common pam config files for usermode/consolehelper

* Mon Sep 03 2007 Thierry Vignaud <tv@mandriva.org> 1.2.10-1mdv2008.0
+ Revision: 78601
- translation snapshot
- fix menu entry category (#33075)

* Fri Aug 31 2007 Andreas Hasenack <andreas@mandriva.com> 1.2.9-2mdv2008.0
+ Revision: 77136
- userdrake/drakuser: ask console user for root password
- also modify menu entry to point to /usr/bin instead of /usr/sbin


* Tue Mar 13 2007 Thierry Vignaud <tvignaud@mandriva.com> 1.2.9-1mdv2007.1
+ Revision: 142367
- translation snapshot

* Mon Mar 12 2007 Thierry Vignaud <tvignaud@mandriva.com> 1.2.8-1mdv2007.1
+ Revision: 141968
- translation snapshot

* Mon Feb 26 2007 Thierry Vignaud <tvignaud@mandriva.com> 1.2.7-1mdv2007.1
+ Revision: 125810
- center error messages on main window
- fix crash when /etc/passwd contains mixed UTF-8 & ISO-Latin1 encoded
  characters (#28888)
- more transientness improvements

* Fri Nov 10 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.6-1mdv2007.1
+ Revision: 80837
- Import userdrake

* Mon Oct 09 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.6-1mdv2007.1
- fix retrieval of expiration date (brown paper bug #21662)
- HIG somewhat first tab of add & edit dialogs

* Sun Sep 17 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.5-1mdv2007.0
- fix menu section
- fix build
- updated translations
- XDG menu

* Fri Jun 09 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.4-1mdv2007.0
- fix linking with libuser (littletux@zarb.org, #22924)

* Fri Jun 02 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.3-1mdv2007.0
- fix "report a bug" entry in menu
- use standard about widget

* Fri Mar 17 2006 Thierry Vignaud <tvignaud@mandriva.com> 1.2.2-1mdk
- cleanups
- assume GECOS data is utf-8 encoded (#4296)
- sub dialogs:
  o make them all really be dialogs
  o center them on their parent window
  o make them transcient to the main window
  o add a 5px border around the window (better looking)
- s/Mandrake/Mandriva/ (pablo)

* Sun Jan 01 2006 Daouda Lo <daouda@mandrakesoft.com> 1.2.1-3mdk
- Rebuild

* Tue Mar 08 2005 Daouda LO <daouda@mandrakesoft.com> 1.2.1-2mdk
- wrap an eval around sensitive home deletion
- home deletion option grayed when deletion might be dangerous (#11453)
- do not use absolute path to Mdk icons (oblin)
- leak patch for extra safefree((char*)self) in XS file (Francois Desarmenien)
- i18n updates

* Mon Feb 21 2005 Thierry Vignaud <tvignaud@mandrakesoft.com> 1.2.1-1mdk
- translation updates

* Wed Jan 26 2005 Daouda LO <daouda@mandrakesoft.com> 1.2-3mdk
- fix 'About' dialog crash 
- cleanups

* Fri Jan 21 2005 Daouda LO <daouda@mandrakesoft.com> 1.2-2mdk
- main loop fixed 
- rebuild against new perl (XS)

* Wed Jan 12 2005 Thierry Vignaud <tvignaud@mandrakesoft.com> 1.2-1mdk
- fix crash when embedded
- show banner when embedded

* Tue Nov 16 2004 Götz Waschk <waschk@linux-mandrake.com> 1.1-4mdk
- rebuild for new perl

* Tue Oct 05 2004 Rafael Garcia-Suarez <rgarciasuarez@mandrakesoft.com> 1.1-3mdk
- rebuild

* Tue Oct 05 2004 Pablo Saratxaga <pablo@mandrakesoft.com> 1.1-2mdk
- updated translations

* Tue Jul 20 2004 Thierry Vignaud <tvignaud@mandrakesoft.com> 1.1-1mdk
- Daouda: restore mouse cursor in sub dialogs
- Olivier Blin:
  o do not crash in Delete when user is in non-existing group (#10242)
  o stop the add process if an error happened when adding a user
  o do not die when removing a non existent directory, just warn (#10241)
  o fix dialogs (#10246):
    * do not quit the whole program on success,
    * wait for the answer to really return the choice made by the user
  o really handle the group choice made by the user
- Thierry Vignaud:
  o get rid of stock icons
  o fix button layouts in dialogs
  o set window icon

* Thu May 27 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-3mdk
- right mouse click on Treeview items to access menu (Edit, Delete)
- don't allow more than 16 char to be consistent with groupadd (tvignaud)

* Tue May 11 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-2mdk
- use md5sum to find current face icon (Oliver Blin) - #9653

* Tue May 11 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-1mdk
- bumped to 1.0 (stable enough)
- random icon display and icon browsing fixes #8085 - #9653 (Olivier
  Blin)


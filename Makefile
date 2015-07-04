
VERSION = 1.14.2
NAME = userdrake
BINNAME = userdrake

PREFIX = /
DATADIR = $(PREFIX)/usr/share
ICONSDIR = $(DATADIR)/icons
SBINDIR = $(PREFIX)/usr/sbin
BINDIR = $(PREFIX)/usr/bin
SYSCONFDIR = $(PREFIX)/etc/sysconfig
SBINREL = ../sbin

SUBDIRS = po
localedir = $(prefix)/usr/share/locale

all: userdrake
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

clean:
	$(MAKE) -C po $@
	rm -f core .#*[0-9]
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

install: all
	$(MAKE) -C po $@
	install -d $(PREFIX)/{/etc/sysconfig,usr/{bin,sbin,share/$(NAME)/pixmaps,share/icons/{mini,large}}}
	install -m755 $(NAME) $(SBINDIR)/
	ln -sf $(SBINREL)/userdrake $(BINDIR)/userdrake
	ln -sf $(SBINREL)/userdrake $(SBINDIR)/drakuser
	install -d $(SYSCONFDIR)
	install -m644 userdrake.prefs $(SYSCONFDIR)/userdrake
	install -m644 pixmaps/*.png $(DATADIR)/$(NAME)/pixmaps
	install -m644 icons/$(NAME)16.png $(ICONSDIR)/mini/$(NAME).png
	install -m644 icons/$(NAME)32.png $(ICONSDIR)/$(NAME).png
	install -m644 icons/$(NAME)48.png $(ICONSDIR)/large/$(NAME).png
	install -m644 icons/*selec*.png $(DATADIR)/$(NAME)/pixmaps
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

dis: dist
dist: clean
	rm -rf $(NAME)-$(VERSION) ./$(NAME)-$(VERSION).tar*
	git archive --prefix=$(NAME)-$(VERSION)/ HEAD | xz -c -T0 > $(NAME)-$(VERSION).tar.xz;

.PHONY: ChangeLog
log: ChangeLog
ChangeLog:
	@if test -d "$$PWD/.git"; then \
	 git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n" > $@.tmp \
	 && mv -f $@.tmp $@ \
	  && git commit ChangeLog -m 'generated changelog' \
	  && if [ -e ".git/svn" ]; then \
	    git svn dcommit ; \
	    fi \
	 || (rm -f  $@.tmp; \
	 echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
	 (test -f $@ || echo git-log is required to generate this file >> $@)); \
	 else \
	 svn2cl --accum --authors ../common/username.xml; \
	 rm -f *.bak;  \
	fi;

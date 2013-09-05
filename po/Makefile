# Installation directories
localedir = $(PREFIX)/usr/share/locale

PGOAL = userdrake

# perl files to search translatable strings in
PL_FILES = $(shell cat POTFILES.in | sed 's,^,../,' )
# C-like files to search translatable strings in
CFILES = ../USER/USER.xs

POFILES = $(shell ls *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

GOALS = $(PGOAL).pot  $(MOFILES)

all: $(GOALS)

install: all
	for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	rm -f *~ *.[oas] *.mo TAGS

%.mo: %.po
	msgfmt -o $@ $<

$(PGOAL).pot: POTFILES.in $(PL_FILES) $(CFILES)
	xgettext -F -n --add-comments \
	--keyword=_ --keyword=__ --keyword=N_ --keyword=N \
	--keyword=gettext \
	--language=C -o placeholder.pot $(CFILES)
	#touch placeholder.pot
	perl_checker -q --generate-pot $(PGOAL)_tmp.pot $(PL_FILES) || rm -f $(PGOAL)_tmp.pot
	[ ! -e $(PGOAL)_tmp.pot ] || msgcat --use-first placeholder.pot $(PGOAL)_tmp.pot > $@
	rm -f placeholder.pot $(PGOAL)_tmp.pot

update_n_merge: $(PGOAL).pot merge

merge:
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $(PGOAL).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done


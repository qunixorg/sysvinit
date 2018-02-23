all install clean distclean:
	$(MAKE) -C src $@

PACKAGE=sysvinit
VERSION=$(shell sed -rn '1s/.*[[:blank:]]\((.*)\)[[:blank:]].*/\1/p' doc/Changelog)
GITLOGIN=$(shell git remote -v | head -n 1 | cut -f 3 -d '/' | cut -f 1 -d '@')
override TMP:=$(shell mktemp -d $(VERSION).XXXXXXXX)
override TARBALL:=$(TMP)/$(PACKAGE)-$(VERSION).tar.bz2
override SFTPBATCH:=$(TMP)/$(VERSION)-sftpbatch
SOURCES=contrib  COPYING  COPYRIGHT  doc  Makefile  man  README  src

dist: $(TARBALL)
	@cp $(TARBALL) .
	@echo "tarball $(PACKAGE)-$(VERSION).tar.bz2 ready"
	rm -rf $(TMP)

upload: $(SFTPBATCH)
	echo @sftp -b $< $(GITLOGIN)@dl.sv.nongnu.org:/releases/$(PACKAGE)
	rm -rf $(TMP)

$(SFTPBATCH): $(TARBALL).sig
	@echo progress > $@
	@echo put $(TARBALL) >> $@
	@echo chmod 664 $(notdir $(TARBALL)) >> $@
	@echo put $(TARBALL).sig >> $@
	@echo chmod 664 $(notdir $(TARBALL)).sig >> $@
	@echo rm  $(PACKAGE)-latest.tar.bz2 >> $@
	@echo symlink $(notdir $(TARBALL)) $(PACKAGE)-latest.tar.bz2 >> $@
	@echo quit >> $@

$(TARBALL).sig: $(TARBALL)
	@gpg -q -ba --use-agent -o $@ $<

$(TARBALL): $(TMP)/$(PACKAGE)-$(VERSION)
	@tar --exclude=.git --bzip2 --owner=nobody --group=nogroup -cf $@ -C $(TMP) $(PACKAGE)-$(VERSION)

$(TMP)/$(PACKAGE)-$(VERSION):
	@mkdir $(TMP)/$(PACKAGE)-$(VERSION)
	@cp -R $(SOURCES) $(TMP)/$(PACKAGE)-$(VERSION)/ 
	@chmod -R a+r,u+w,og-w $@
	@find $@ -type d | xargs -r chmod a+rx,u+w,og-w

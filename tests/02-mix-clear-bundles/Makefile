.PHONY: check clean

check:
	bats ./run.bats

CLEANDIRS = ./update ./test-chroot ./logs ./.repos ./bundles ./update ./mix-bundles ./clr-bundles ./local ./results
CLEANFILES = ./*.log ./run.bats.trs ./yum.conf.in ./builder.conf ./.{c,m}* *.pem
clean:
	sudo rm -rf $(CLEANDIRS) $(CLEANFILES)

TESTMODULES := $(wildcard *Test.st)
LOADSTRING := $(addprefix -f ,$(TESTMODULES))
SUITES := $(basename $(TESTMODULES))

.PHONY: all

all:
	gst-sunit -p DANM $(LOADSTRING) $(SUITES)

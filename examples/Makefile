# all generated file put in here
OBJ_DIR=obj
# this is the makefile to build the rtl
ST_SEARCH_PATH=st

VERILOG_SEARCH_PATH=verilog

# the verilog and doc from danm.
# hard to figure out dependency so always rebuild
$(OBJ_DIR)/%.v $(OBJ_DIR)/%.sod: st/%.st $(OBJ_DIR) FORCE
	@echo "PackageLoader fileInPackage: 'DANM'." > run_$*.st
	@echo "mod := DANMLibrary moduleByName: '$*' fromPaths: {" >> run_$*.st
	@for path in $(ST_SEARCH_PATH); do \
	  echo "'$$path'." >> run_$*.st; \
	done
	@for path in $(VERILOG_SEARCH_PATH); do \
	  echo "'$$path'." >> run_$*.st; \
	done
	@echo "}." >> run_$*.st
ifeq ($(POSTPROCESS),1)
	@echo "mod postProcess." >> run_$*.st
endif
	@echo "mod checkDesign." >> run_$*.st
	@echo "mod generateHTMLAsTopIn: '$(OBJ_DIR)/$*_html'." >> run_$*.st
	@echo "mod generateFullVerilogTo: '$(OBJ_DIR)/$*.v'." >> run_$*.st
	@echo "mod flattenAll." >> run_$*.st
	@echo "mod optimize." >> run_$*.st
	@echo "mod generateFullVerilogTo: '$(OBJ_DIR)/$*_flat.v'." >> run_$*.st
	@gst -f run_$*.st
	@rm -f run_$*.st

all: $(OBJ_DIR)/rr_arbiter.v $(OBJ_DIR)/sync_fifo.v

FORCE:

.PHONY: clean

clean: 
	-rm -rf $(OBJ_DIR)

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

# customize these
PACKAGE_NAME = DANM
SRCS = libs.st \
LineCountingStream.st \
Tokenizer.st \
SimpleExprAST.st \
SimpleExprParser.st \
ExpressionAST.st \
ExpressionUnaryOp.st \
ExpressionBinaryOp.st \
ExpressionCompondOp.st \
ExpressionParser.st \
ModeledExpression.st \
TimeSeries.st \
DANMEntity.st \
DANMPort.st \
DANMLibrary.st \
DANMBlackBox.st \
DANMWire.st \
DANMExpressionWire.st \
DANMAssertion.st \
DANMMonostable.st \
DANMSchematic.st \
DANMSimulator.st \
DANMVCDDumper.st \
schematicBuilding.st \
htmlPrinting.st \
checkDesign.st \
designStatistic.st
#end customize

GST_PACK = gst-package
INSTALL_DIR = ~/.st
TARGET = $(INSTALL_DIR)/$(PACKAGE_NAME).star

.PHONY: install uninstall

install: $(TARGET)

uninstall: 
	rm -f $(TARGET)

$(TARGET): $(SRCS) package.xml
	$(GST_PACK) -t $(INSTALL_DIR) package.xml > /dev/null

package.xml: Makefile
	@echo "<package>" > package.xml
	@echo "  <name>$(PACKAGE_NAME)</name>" >> package.xml
	@for file in $(SRCS); do \
	  echo "  <filein>$$file</filein>" >> package.xml; \
	done
	@echo "" >> package.xml
	@for file in $(SRCS); do \
	  echo "  <file>$$file</file>" >> package.xml; \
	done
	@echo "</package>" >> package.xml



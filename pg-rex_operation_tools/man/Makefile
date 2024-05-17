#

PANDOC = pandoc
PANDOC_OPT = --self-contained --metadata=$(METADATA) --css=$(STYLE)
METADATA = "pagetitle:PG-REX運用補助ツール $(VERSION) 利用マニュアル"

VERSION = 15
STYLE = pg-rex_tools_manual.css
SOURCE = pg-rex_tools_manual-ja.md
MANUAL = html/pg-rex_tools_manual-ja.html

all: $(MANUAL)

$(MANUAL) : $(SOURCE)
	$(PANDOC) $(PANDOC_OPT) $< -o $@

clean :
	- $(RM) $(MANUAL)


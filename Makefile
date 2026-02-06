OUTPUT = README.md
TITLE = "Project Documentation"

.PHONY: all clean

all: $(OUTPUT)

$(OUTPUT):
	@echo "Generating $(OUTPUT)..."
	@echo "# $(TITLE)" > $(OUTPUT)
	@echo "\n## Table of Contents" >> $(OUTPUT)
	@echo "" >> $(OUTPUT)
	@# Find all .md files, excluding README.md itself, and format them as Markdown links
	@find . -name "*.md" ! -name "$(OUTPUT)" | sort | sed 's|^\./||' | while read -r file; do \
		title=$$(head -n 1 "$$file" | sed 's/^# //'); \
		echo "* [$$title]($$file)" >> $(OUTPUT); \
	done
	@echo "\n*Last updated: $$(date)*" >> $(OUTPUT)
	@echo "Done!"

clean:
	rm -f $(OUTPUT)
draft-hardt-gnap-advanced.xml: draft-hardt-gnap-advanced.md
	kramdown-rfc2629 $^ > $@
	xml2rfc $@ --v2v3 -o $@
	xml2rfc $@ --html


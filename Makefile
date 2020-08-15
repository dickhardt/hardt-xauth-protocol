draft-hardt-xauth-protocol.xml: draft-hardt-xauth-protocol.md
	kramdown-rfc2629 $^ > $@
	xml2rfc $@ --v2v3 -o $@
	xml2rfc $@ --html


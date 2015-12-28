src/indoor_top.mltop:
	./mk mltop

indoor_top.top: src/indoor_top.mltop
	./mk top

top: indoor_top.top

%:
	./mk $@

.PHONY: top

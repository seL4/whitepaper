# Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause

#
# Generic paper Makefile
#
# For usage hints, "make help"
#
#  To create a LaTeX diff against the git HEAD revision, use the target
#  "diff" (or "viewdiff").
#  To use a revision other than HEAD, speciff DIFF=x on the
#  make command line to choose the revision x.
#

# Verbosity
ifeq (${V},1)
Q:=
else
Q:=@
endif

.PHONY: all

BIBDIR     ?= /home/disy/lib/BibTeX:../../../bibtex:../bibtex
LaTeXEnv   = TEXINPUTS=".:/home/disy/lib/TeX:/home/disy/lib/ps:${TEXINPUTS}:"
BibTexEnv  = BIBINPUTS=".:${BIBDIR}:${BIBINPUTS}:"
BibFiles   = defs,extra,combined,systems,fm,other

LaTeX      = ${LaTeXEnv} pdflatex -interaction=nonstopmode
# Uncomment the following for "unsw" when using TrueType fonts (which they require)
#LaTeX      = ${LaTeXEnv} lualatex -interaction=nonstopmode
LaTeXdiff  = ./tools/latexdiff
BibTeX     = ${BibTexEnv} bibtex
BibExport  = ./tools/bibexport.sh
Fig2Eps    = fig2dev -L eps
Dia2Eps    = dia -t eps -e
AS         = $(shell which as)
CC         = $(shell which gcc)
GnuPlot	   = gnuplot
Inkscape   = $(shell which inkscape)
Eps2Pdf	   = epstopdf --outfile
PdfView	   = xpdf
Pdf2Ps	   = pdf2ps
Md2Pdf	   = pandoc
RmCR       = tr -d '\r'
sed        = $(shell which sed)
Lpr 	   = lpr
mv	   = mv
awk	   = awk
R	   = R
ToGray	   = convert -colorspace gray

# Use either "report" or "paper", depending on the template.
# To add a further target, simply append the basename of the .tex file here
# NOTE: for the "simple", "report" and "unsw" templates, uncomment the lualatex line above!
TexFiles = $(basename $(wildcard *.tex))
Targets    = whitepaper


# CONFIGURATION OPTIONS
# =====================

# Extra figures that aren't supplied as dia, gnuplot or fig sources
# (eg figures already supplied in PDF, or supplied in EPS).
# List with pdf extensions.
# Note that PDF files should be added to the repo with an additional -shipped extension,
# but should appear here with just the .pdf extension.
ExtraFigs= $(wildcard imgs/*.pdf)


# Any other stuff that may be needed

# END CONFIGURATION OPTIONS
# =========================

Optional = $(addsuffix -diff, $(Targets))
All = $(Targets) $(Optional)
Diffopts= #--type=BWUNDERLINE #-c .latexdiffconfig --append-safecmd="Comment"

Perf_Sources = $(wildcard imgs/*.perf)
Dia_Sources = $(wildcard imgs/*.dia)
Fig_Sources = $(wildcard imgs/*.fig)
Gnuplot_Sources = $(wildcard imgs/*.gnuplot)
SVG_Sources = $(wildcard imgs/*.svg)
R_Sources = $(wildcard imgs/*.r)
Styles = $(wildcard *.sty)  $(wildcard *.cls)
Figures = $(Perf_Sources:.perf=.pdf) $(Dia_Sources:.dia=.pdf) $(Fig_Sources:.fig=.pdf) $(SVG_Sources:.svg=.pdf) $(Gnuplot_Sources:.gnuplot=.pdf)  $(R_Sources:.r=.pdf) $(ExtraFigs)
GreyFigs = $(subst .pdf,-gr.pdf,$(subst imgs/,./,$(wildcard imgs/*.pdf)))

Pdf = $(addsuffix .pdf, $(Targets))
Bib = references.bib
Tex = $(addsuffix .tex, $(Targets))
Diff_Pdf = $(addsuffix .pdf, $(Optional))

.PHONY: FORCE

all: pdf
diff: diff_pdf
FORCE: pdf
ps: $(Ps)
pdf: $(Figures) Makefile $(Pdf)
diff_pdf: $(Figures) Makefile $(Diff_Pdf)
grey:	$(GreyFigs)
gray:	grey

%-gr.pdf:	imgs/%.pdf
	${ToGray} $< $@

%.pdf: %.perf ./tools/bargraph.pl
	@echo $< '->' $@
	${Q} ${BarGraph} -pdf $< > $@

%.pdf: %.eps
	@echo $< '->' $@
	${Q} ${Eps2Pdf} $@ $<

%.pdf: %.ps
	@echo $< '->' $@
	${Q} ${Eps2Pdf} $@ $<

%.eps: %.svg
	@echo $< '->' $@
	${Q} $(if ${Inkscape},,echo "You need inkscape installed to build $@" >&2; exit 1)
	${Q} ${Inkscape} -f $< -D -z -E $@ > /dev/null 2>&1

%.pdf: %.svg
	@echo $< '->' $@
	${Q} $(if ${Inkscape},,echo "You need inkscape installed to build $@" >&2; exit 1)
	${Q} ${Inkscape} -f $< -D -z -A $@ > /dev/null 2>&1

# This target allows you to add figures which have the extension .c_pp that
# correspond to .c sources. Your .c sources can use the lines '/*<*/' and
# '/*>*/' to surround parts of the source you don't want shown in your PDF.
# This allows you to write a .c file that can be compile-checked here and then
# remove extraneous lines for display.
%.c_pp: %.c
	@echo $< '->' $@
	${Q}$(if ${CC},${CC} -c "$<" -o /dev/null,)
	${Q}${sed} -e '/\/\*<\*\//,/\/\*>\*\//d' "$<" >"$@"

%.s_pp: %.s
	@echo $< '->' $@
	${Q}$(if ${AS},${AS} -c "$<" -o /dev/null,)
	${Q}${sed} -e '/\/\*<\*\//,/\/\*>\*\//d' "$<" >"$@"

%.eps: %.dia
	@echo $< '->' $@
	${Q} ${Dia2Eps} $@ $<

%.eps: %.fig
	@echo $< '->' $@
	${Q} ${Fig2Eps} $< $@

%.eps: %.gnuplot
	@echo $< '->' $@
	${Q} ${GnuPlot} $<

%.eps: %.r
	@echo $< '->' $@
	${Q} ${R} --vanilla < $<

%.pdf: %.pdf-shipped
	cp $< $@

%.pdf:	%.md
	$(Md2Pdf) $< -o $@

%.view:	%.pdf
	$(PdfView) $<

view: pdf
	${Q}for i in $(Pdf); do \
		$(PdfView) $$i & \
	done

viewdiff: diff
	${Q}for i in $(Diff_Pdf); do \
		$(PdfView) $$i & \
	done

print: pdf
	${Q}for i in $(Pdf); do \
		$(Lpr) $$i \
	done

clean:
	rm -f *.aux *.toc *.bbl *.blg *.dvi *.log *.pstex* *.eps *.cb *.brf \
		*.rel *.idx *.out *.ps *-diff.* *.mps .log *.diff *.cut tmp.* $(GreyFigs)

realclean: clean
	rm -f *~ *.pdf *.tgz $(Bib)
	git checkout $(Bib)

tar:	realclean
	( p=`pwd` && d=`basename "$$p"` && cd .. && \
	  tar cfz $$d.tgz $$d && \
	  mv $$d.tgz $$d )

help:
	@echo "Main targets: all diff camera view viewdiff print clean realclean tar"
	@echo "'make diff' will show changes to head revision"
	@echo "'make grey' will generate greyscale figures (for B&W readibility check)"
	@echo "'make DIFF=<rev> diff' will show changes to revision <rev>"
	@echo 'Avoid TeX \def with arguments, this breaks latexdiff (use \newcommand)'

##############################################################################

DIFF ?= HEAD

%-diff.dvi: %-diff.tex

%-diff.tex: %.tex FORCE
	@echo "====> Retrieving revision $(DIFF) of $<"
	git show $(DIFF):$<  > $(@:-diff.tex=-$(DIFF)-diff.tex)
	@echo "====> Creating diff of revision $(DIFF) of $<"
	$(LaTeXdiff) $(Diffopts) $(@:-diff.tex=-$(DIFF)-diff.tex) $< | \
	${RmCR} > $@

.PHONY: FORCE
FORCE:

# don't delete %.aux intermediates
.SECONDARY:

##############################################################################

Rerun = '(There were undefined (references|citations)|Rerun to get (cross-references|the bars) right)'
Rerun_Bib = 'No file.*\.bbl|Citation.*undefined'
Undefined = '((Reference|Citation).*undefined)|(Label.*multiply defined)'
Error = '^! '
BibWarn = '^Warning--'
LaTeXWarn = ' [Ww]arning: '

# combine citation commands from all targets into tmp.aux, generate references.bib from this
# WARNING: This will only re-generate references.bib if citations have been
# added or removed, not if an BibTeX entry has been edited.
# It's a good idea to force rebuilding references.bib before submitting!
$(Bib): $(addsuffix .tex, $(Targets))
	@echo "====> Parsing targets for references"
	@cat </dev/null > .log
	@cat </dev/null > all_refs.aux
	${Q}for i in $(Targets); do \
		$(LaTeX) $$i.tex >>.log; \
		cat $$i.aux | grep -e "\(citation\|bibdata\|bibstyle\)" | sed 's/bibdata{references}/bibdata{$(BibFiles)}/g' >> all_refs.aux; \
	done
	@echo "====> Removing duplicate bib entries"
	${Q}cat all_refs.aux | sort -u | sed '/\\bibstyle/d' > tmp.aux
	${Q}grep '\\bibstyle' all_refs.aux | head -1 >> tmp.aux
	${Q}touch references.aux
	${Q}if [ -r references.aux ]; then \
		diff references.aux tmp.aux > references.diff 2> /dev/null; \
	else rm -f references.diff; \
	fi; true
	${Q}if [ -s references.diff ] && [ -e $(Bib) ]; then \
		echo "====> Changed references:"; \
		cat references.diff | grep "citation"; \
		echo -n "These will cause changes to $(Bib), do you want to rebuild this file? (yes/NO): "; \
		read rebuild_refs; \
	fi; \
	if [ "$$rebuild_refs" = "yes" ] || [ -s all_refs.aux -a \! -e $(Bib) ]; then \
		echo "====> Building $(Bib)"; \
		$(BibTexEnv) $(BibExport) -t -o tmp.bib tmp.aux > .log 2>&1; \
		if grep -q 'error message' .log; then \
			cat .log; \
			exit 1; \
		fi; \
		: Clean out junk. Remove following command if you really want it in; \
		: Note: awkward expression because sed is different on Mac and Linux; \
		${sed} <tmp.bib > $(Bib) \
			-e 's/^ *isbn *= *{/  NOisbn = {/' \
			-e 's/^ *issn *= *{/  NOissn = {/' \
			-e 's/^ *editor *= *{/  NOeditor = {/' \
			-e 's/^ *paper[uU]rl *=/  url =/'; \
		cp tmp.aux references.aux; \
	fi;
	${Q}rm -f all_refs.aux tmp.aux references.diff

%.pdf: %.tex $(Bib) $(Figures) $(Styles) Makefile
	${Q}if test $*.bbl -ot $(Bib); then rm -f $*.bbl; fi
	@echo "====> LaTeX first pass: $(<)"
	${Q}$(LaTeX) $< >.log || if egrep -q $(Error) $*.log ; then cat .log; rm $@; false ; fi
	${Q}if egrep -q $(Rerun_Bib) $*.log ; then echo "====> BibTex" && ( $(BibTeX) $* > .log || ( cat .log ; false ) ) && echo "====> LaTeX BibTeX pass" && $(LaTeX) >.log $< || if egrep -q $(Error) $*.log ; then cat .log; rm $@; false ; fi ; fi
	${Q}if egrep -q $(Rerun) $*.log ; then echo "====> LaTeX rerun" && $(LaTeX) >.log $<; fi
	${Q}if egrep -q $(Rerun) $*.log ; then echo "====> LaTeX rerun" && $(LaTeX) >.log $<; fi
	${Q}if egrep -q $(Rerun) $*.log ; then echo "====> LaTeX rerun" && $(LaTeX) >.log $<; fi
	@echo "====> Undefined references and citations in $(<):"
	@egrep -i $(Undefined) $*.log || echo "None."
	@echo "====> Dimensions:"
	@grep "dimension:" $*.log || echo "None."
	@echo "====> Warnings:"
	${Q}bibw=`if test -e $*.blg; then grep -c $(BibWarn) $*.blg; else echo 0; fi`; \
	texw=`grep -c $(LaTeXWarn) $*.log`; \
	if [ "$$bibw" -gt 0 ]; then echo " $$bibw BibTeX\c"; fi; \
	if [ "$$texw" -gt 0 ]; then echo " $$texw LaTeX\c"; fi; \
	if [ "$$bibw$$texw" = 00 ]; then echo "None."; \
	else echo ". 'make warn' will show them."; fi

warn:
	@echo "====> BibTeX warnings from" *.blg
	@grep $(BibWarn) *.blg || echo "None."
	@echo "====> LaTeX warnings from" *.log
	@grep $(LaTeXWarn) *.log || echo "None."

##############################################################################
# Generate a list of FIXMEs
fixmes:
	${Q}for i in $(Tex); do \
		echo "FIXMEs in $$i:"; \
		nl -b a $$i | grep "FIXME{" | nl -b a; \
		echo -n "Total FIXMES: " && grep "FIXME{" $$i | wc -l; \
		echo; \
	done

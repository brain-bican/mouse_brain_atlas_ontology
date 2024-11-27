## Customize Makefile settings for mbao
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile
#
# sh ./run.sh make clean
# sh ./run.sh make prepare_release
#
# MBA : 1
# DMBA : 17
# HBA : 10
# DHBA : 16
# PBA : 8

URIBASE = https://purl.brain-bican.org/ontology

JOBS = 1 # 17 10 16 8
BRIDGES = mba
TARGETS = mba # dmba

LINKML = linkml-data2owl

STRUCTURE_GRAPHS = $(patsubst %, sources/%.json, $(JOBS))
ALL_GRAPH_ONTOLOGIES = $(patsubst sources/%.json,sources/%.ofn,$(STRUCTURE_GRAPHS))
ALL_BRIDGES = $(patsubst %, sources/uberon-bridge-to-%.owl, $(BRIDGES))
SOURCE_TEMPLATES = $(patsubst %, ../templates/%_CCF_to_UBERON_source.tsv, $(TARGETS))
NEW_BRIDGES = $(patsubst %, new-bridges/new-uberon-bridge-to-%.owl, $(TARGETS))


.PHONY: $(COMPONENTSDIR)/all_templates.owl
$(COMPONENTSDIR)/all_templates.owl: clean_files dependencies $(COMPONENTSDIR)/linkouts.owl $(COMPONENTSDIR)/sources_merged.owl
	$(ROBOT) merge -i $(COMPONENTSDIR)/linkouts.owl -i $(COMPONENTSDIR)/sources_merged.owl annotate --ontology-iri $(URIBASE)/$@ convert -f ofn -o $@
	# $(ROBOT) query --input $@ --update $(SPARQLDIR)/declare_mba_disjoint_classes.ru --output $@
.PRECIOUS: $(COMPONENTSDIR)/all_templates.owl

# Installing depedencies so it can run in ODK container
.PHONY: dependencies
dependencies:
	pip3 install -r ../../requirements.txt


LOCAL_CLEAN_FILES = $(ALL_GRAPH_ONTOLOGIES) $(ALL_BRIDGES) $(TMPDIR)/tmp.json $(TMPDIR)/tmp.owl $(COMPONENTSDIR)/sources_merged.owl $(COMPONENTSDIR)/linkouts.owl $(TEMPLATEDIR)/linkouts.tsv $(SOURCE_TEMPLATES) $(NEW_BRIDGES)

# clean previous build files
.PHONY: clean_files
clean_files:
	rm -f $(LOCAL_CLEAN_FILES)

sources/%.json:
	curl -o $@ $(subst %,$(subst sources/,,$@),"http://api.brain-map.org/api/v2/structure_graph_download/%")

../linkml/data/template_%.tsv: sources/%.json
	python3 $(SCRIPTSDIR)/structure_graph_template.py -i $< -o $@
.PRECIOUS: ../linkml/data/template_%.tsv:
# TODO delete

sources/%.ofn: ../linkml/data/template_%.tsv
	$(LINKML) -C Class -s ../linkml/structure_graph_schema.yaml $< -o $@
.PRECIOUS: sources/%.ofn

# download bridges
#sources/uberon-bridge-to-aba.owl:
#	curl -o sources/uberon-bridge-to-aba.obo "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-aba.obo"
#	$(ROBOT) convert -i sources/uberon-bridge-to-aba.obo --format owl -o $@
#	sed -i 's|http://purl.obolibrary.org/obo/ABA_|https://purl.brain-bican.org/ontology/abao/ABA_|g' $@

sources/uberon-bridge-to-dhba.owl:
	curl -o sources/uberon-bridge-to-dhba.owl "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-dhba.owl"
	$(ROBOT) convert -i sources/uberon-bridge-to-dhba.owl --format owl -o $@
	sed -i 's|http://purl.obolibrary.org/obo/DHBA_|https://purl.brain-bican.org/ontology/dhbao/DHBA_|g' $@

sources/uberon-bridge-to-dmba.owl:
	curl -o sources/uberon-bridge-to-dmba.owl "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-dmba.owl"
	$(ROBOT) convert -i sources/uberon-bridge-to-dmba.owl --format owl -o $@
	sed -i 's|http://purl.obolibrary.org/obo/DMBA_|https://purl.brain-bican.org/ontology/dmbao/DMBA_|g' $@

sources/uberon-bridge-to-hba.owl:
	curl -o sources/uberon-bridge-to-hba.owl "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-hba.owl"
	$(ROBOT) convert -i sources/uberon-bridge-to-hba.owl --format owl -o $@
	sed -i 's|http://purl.obolibrary.org/obo/HBA_|https://purl.brain-bican.org/ontology/hbao/HBA_|g' $@

sources/uberon-bridge-to-mba.owl:
	curl -o sources/uberon-bridge-to-mba.owl "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-mba.owl"
	$(ROBOT) convert -i sources/uberon-bridge-to-mba.owl --format owl -o $@
	sed -i 's|http://purl.obolibrary.org/obo/MBA_|https://purl.brain-bican.org/ontology/mbao/MBA_|g' $@

sources/uberon-bridge-to-pba.owl:
	curl -o sources/uberon-bridge-to-pba.owl "https://raw.githubusercontent.com/obophenotype/uberon/master/src/ontology/bridge/uberon-bridge-to-pba.owl"
	$(ROBOT) convert -i sources/uberon-bridge-to-pba.owl --format owl -o $@
	sed -i 's|http://purl.obolibrary.org/obo/PBA_|https://purl.brain-bican.org/ontology/pbao/PBA_|g' $@

# NEW BRIDGES
$(TMPDIR)/%_old_mapping.tsv: sources/uberon-bridge-to-%.owl
	$(ROBOT) query --input $< --query ../sparql/bridge_mappings.sparql $@

../templates/%_CCF_to_UBERON_source.tsv: $(TMPDIR)/%_old_mapping.tsv  ../templates/%_CCF_to_UBERON.tsv
	python ../scripts/mapping_source_template_generator.py -i1 $< -i2 $(word 2, $^) -o $@
.PRECIOUS: ../templates/%_CCF_to_UBERON_source.tsv

new-bridges/new-uberon-bridge-to-%.owl: ../templates/%_CCF_to_UBERON.tsv ../templates/%_CCF_to_UBERON_source.tsv $(MIRRORDIR)/uberon.owl
	$(ROBOT) template --input $(MIRRORDIR)/uberon.owl --template $< --output $(TMPDIR)/sourceless-new-uberon-bridge.owl
	$(ROBOT) template --input $(MIRRORDIR)/uberon.owl --template $(word 2, $^) --output $(TMPDIR)/CCF_to_UBERON_source.owl
	$(ROBOT) merge --input $(TMPDIR)/sourceless-new-uberon-bridge.owl --output $(TMPDIR)/CCF_to_UBERON_source.owl --output $@

# END NEW BRIDGES

$(COMPONENTSDIR)/sources_merged.owl: $(ALL_GRAPH_ONTOLOGIES) $(NEW_BRIDGES)
	$(ROBOT) merge $(patsubst %, -i %, $^) relax annotate --ontology-iri $(URIBASE)/$@ -o $@

# merge uberon + sources, reason & relax (EC -> SC)
$(TMPDIR)/tmp.owl: $(SRC) $(COMPONENTSDIR)/sources_merged.owl
	$(ROBOT) merge $(patsubst %, -i %, $^) relax annotate --ontology-iri $(URIBASE)/$@ -o $@

# Make a json file for use in geneating ROBOT template
$(TMPDIR)/tmp.json: $(TMPDIR)/tmp.owl
	$(ROBOT) convert --input $< -f json -o $@

# Build robot  template - with linkouts and prefLabels
$(TEMPLATEDIR)/linkouts.tsv: $(TMPDIR)/tmp.json
	python $(SCRIPTSDIR)/gen_linkout_template.py $<

# generate OWL from template
$(COMPONENTSDIR)/linkouts.owl: $(TMPDIR)/tmp.owl $(TEMPLATEDIR)/linkouts.tsv
	$(ROBOT) template --template $(word 2, $^) --input $< --add-prefixes template_prefixes.json -o $@




## ONTOLOGY: uberon (remove disjoint classes and properties, they are causing inconsistencies when merged with mba bridge)
.PHONY: mirror-uberon
.PRECIOUS: $(MIRRORDIR)/uberon.owl
mirror-uberon: | $(TMPDIR)
	if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(ROBOT) convert -I http://purl.obolibrary.org/obo/uberon/subsets/mouse-view.owl -o $@.tmp.owl &&\
		$(ROBOT) remove -i $@.tmp.owl --axioms disjoint -o $@.tmp.owl && \
		mv $@.tmp.owl $(TMPDIR)/$@.owl; fi


## Disable '--equivalent-classes-allowed asserted-only' due to MBA inconsistencies
.PHONY: reason_test
reason_test: $(EDIT_PREPROCESSED)
	# $(ROBOT) explain --input $< --reasoner ELK -M unsatisfiability --unsatisfiable all --explanation explanation.md
	# $(ROBOT) reason --input $< --reasoner ELK --equivalent-classes-allowed asserted-only \
	# 	--exclude-tautologies structural --output test.owl && rm test.owl
	$(ROBOT) reason --input $< --reasoner ELK \
		--exclude-tautologies structural --output test.owl && rm test.owl

## Disable '--equivalent-classes-allowed asserted-only' due to MBA inconsistencies
# Full: The full artefacts with imports merged, reasoned.
$(ONT)-full.owl: $(EDIT_PREPROCESSED) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT_RELEASE_IMPORT_MODE) \
		reason --reasoner ELK --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

## Disable '--equivalent-classes-allowed asserted-only' due to MBA inconsistencies
# foo-simple: (edit->reason,relax,reduce,drop imports, drop every axiom which contains an entity outside the "namespaces of interest")
# drop every axiom: filter --term-file keep_terms.txt --trim true
#	remove --select imports --trim false
$(ONT)-simple.owl: $(EDIT_PREPROCESSED) $(OTHER_SRC) $(SIMPLESEED) $(IMPORT_FILES)
	$(ROBOT_RELEASE_IMPORT_MODE) \
		reason --reasoner ELK --exclude-tautologies structural \
		relax \
		remove --axioms equivalent \
		relax \
		filter --term-file $(SIMPLESEED) --select "annotations ontology anonymous self" --trim true --signature true \
		reduce -r ELK \
		query --update ../sparql/inject-subset-declaration.ru --update ../sparql/inject-synonymtype-declaration.ru \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@
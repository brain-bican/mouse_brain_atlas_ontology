# Build Process Flow

Project build process works as follows:

1. Related structure graph is downloaded from Allen, eg. [http://api.brain-map.org/api/v2/structure_graph_download/1.json](http://api.brain-map.org/api/v2/structure_graph_download/1.json)
2. Using the [LinkML-OWL](https://github.com/linkml/linkml-owl) structure graph is converted to the owl. [structure_graph_schema.yaml](https://github.com/hkir-dev/mouse_brain_atlas_ontology/blob/main/src/linkml/structure_graph_schema.yaml) template is utilized for the conversion.
3. Using the [ROBOT](http://robot.obolibrary.org/) ontology templating tool, a [new bridge file](https://github.com/hkir-dev/mouse_brain_atlas_ontology/tree/main/src/templates) template is generated.
4. Using the new bridge template atlas and UBERON terms are manually mapped.
5. A 'sources' ROBOT template is generated to annotate if the mapping derived from the old bride or the new one.
6. Using the [ROBOT](http://robot.obolibrary.org/) ontology templating tool, external links to the related atlas web pages are generated (linkouts.owl). Such as, [http://atlas.brain-map.org/atlas?atlas=138322605#structure=10499](http://atlas.brain-map.org/atlas?atlas=138322605#structure=10499)
7. Finally all ontologies (linkouts.owl, structure graph ontology and the new bridges) are merged and the uberon import module added to the output ontology.

The Uberon import uses a pinned Uberon release (`UBERON_RELEASE` in `src/ontology/mbao.Makefile`). The same release is used by the full-Uberon QC check. See [Uberon pin and full-Uberon QC](uberon-qc.md) for how to bump it before refreshing imports or making a release.
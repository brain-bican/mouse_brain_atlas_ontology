# Uberon pin and full-Uberon QC

MBAO uses one pinned Uberon release for two things:

- **The Uberon import.** `mirror-uberon` downloads that release's `mouse-view.owl` subset and removes its disjointness axioms. This becomes part of `imports/merged_import.owl`.
- **The full-Uberon QC.** `make reason_test_uberon` reasons over `mbao-edit.owl` together with that release's **full** `uberon.owl`. Unlike the import, the full release keeps the disjointness axioms, and it is what CL's release reasons with. The check catches MBA classes that become unsatisfiable when combined with Uberon, for example a class that is part of both the CNS and the PNS (MBA_710, #13). CI runs it on every PR.

The release is set in one place, `src/ontology/mbao.Makefile`:

```make
UBERON_RELEASE = 2026-10-01
```

Both URLs are built from it: `https://github.com/obophenotype/uberon/releases/download/v$(UBERON_RELEASE)/{mouse-view,uberon}.owl`. The `mirror_from` URL in `mbao-odk.yaml` is not used.

Pinning means a new Uberon release can't change the import or fail a PR. Uberon only changes when someone deliberately bumps `UBERON_RELEASE`.

## The known-unsatisfiable list

Some MBA classes are already unsatisfiable with full Uberon (161 of them because of #12). They are listed in `src/ontology/qc_known_unsat_full_uberon.txt`. The header of the list names the Uberon release it was generated for.

`make reason_test_uberon` fails if any of these happen:

| Condition | What to do |
|---|---|
| A class that isn't in the list is unsatisfiable | Fix the mapping that causes it (see "Explaining an unsatisfiable class" below). Don't add the class to the list. |
| A listed class is no longer unsatisfiable | Remove its line from the list in the same PR. A stale line keeps the class exempt, so if it breaks again the check won't notice. |
| The list's header names a different release from `UBERON_RELEASE` | Regenerate the list (see "Bumping the Uberon release" below). |

Rules for the list:

- **Never add a line by hand.** Lines are only added when the list is regenerated during an Uberon bump, and each new line has to be explained in that PR.
- **Removing lines by hand is fine.** Removing a line is how you record a fix.
- The aim is to shrink the list to nothing. Each fix to a mapping should remove lines.

## Everyday PRs

- **CI checks the committed `components/all_templates.owl` (`COMP=false`).** It does not rebuild the component from the templates. A change to `src/templates/mba_CCF_to_UBERON.tsv` only affects this check once the component has been rebuilt with `make components/all_templates.owl`, which needs network access to the Allen API. Until then, the release build is the first place the change is checked.
- **To run the check locally:**

  ```sh
  cd src/ontology
  ROBOT_JAVA_ARGS=-Xmx12G make reason_test_uberon IMP=false PAT=false MIR=false COMP=false
  ```

  The first run downloads the full Uberon file (about 96 MB) to `tmp/uberon-<release>.owl`. Later runs reuse it.

## Explaining an unsatisfiable class

```sh
cd src/ontology
robot merge -i mbao-edit.owl -i tmp/uberon-$(sed -n 's/^UBERON_RELEASE *= *//p' mbao.Makefile).owl \
  explain -M unsatisfiability --unsatisfiable all --explanation explain.md
```

## Bumping the Uberon release (before `refresh-imports` and every release)

Pin first, then refresh. This keeps the import and the QC check on the same Uberon release.

1. Choose the release from <https://github.com/obophenotype/uberon/releases>, for example `v2026-10-01`. Check that it includes both `mouse-view.owl` and `uberon.owl` as release files.
2. In `src/ontology/mbao.Makefile`, set `UBERON_RELEASE` to that release without the `v`, for example `2026-10-01`.
3. Refresh the imports:

   ```sh
   sh run.sh make refresh-imports
   ```

4. Regenerate the known list:

   ```sh
   sh run.sh make reason_test_uberon IMP=false PAT=false MIR=false COMP=false UBERON_QC_UPDATE=true
   ```

   This rewrites `qc_known_unsat_full_uberon.txt` and prints which classes it removed and which it added.
5. Review every added line. Each one is an MBA class that the new Uberon release made unsatisfiable. Explain it, then fix the mapping or open an issue for it, and link the issue in the PR.
6. Open **one PR** with only the `UBERON_RELEASE` change, the refreshed `imports/` and the regenerated list. Don't mix in content changes.
7. Run `make prepare_release` only after that PR is merged.

CI caches the downloaded `uberon.owl` with a cache key based on `UBERON_RELEASE`. Bumping the release downloads the new file once.

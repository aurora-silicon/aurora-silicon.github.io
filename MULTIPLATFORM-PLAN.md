# Multiplatform site review and implementation plan

Reviewed 13 September 2026 against `main` at `1646b0f` and aurorasilicon.org.
Scope: the documentation website's operating-system coverage, not porting the
Windows driver tree, deploying an OS or certifying hardware.

## Findings

| Finding | Impact | Resolution |
| --- | --- | --- |
| Homepage and project/user/developer introductions frame Aurora as Windows-only | Linux work has no clear entry point | Add Windows and Linux platform guides and navigation; revise shared introductions |
| Device states are keyed only by machine; all profiles require Windows Boot Manager | A Linux reader can mistake Windows results for Linux support | Key states by OS, device and feature; require an explicit OS choice and use separate boot milestones |
| Overview and M1 pages say no states exist even though the script records Windows results | Text and interactive catalog contradict each other | Document inherited Windows coverage for j316s/j414s and the Linux recording gap |
| M2 prose suggests results transfer to other chips | Readers may infer untested support | Keep results explicitly scoped to Windows on j414s |
| State meaning is conveyed through colour and hover titles | Touch and keyboard readers cannot readily interpret results | Add visible state labels, a support legend, named dialog and labelled native select |
| Existing states lack exact build/log references | Reports are not reproducible qualification evidence | Preserve them with clear limitations; require evidence for new/changed records |
| User installation and removal pages are placeholders | Merely replacing Windows with Linux could imply a usable shared installer | Keep drafts explicit; introduce OS-specific procedure scope without inventing commands |
| Public research already includes Linux implementations | Renaming all Windows references would destroy technical meaning | Preserve Windows HAL and d3d12agx scope; explain API versus host/target OS |
| Deployment workflow has no PR validation | Broken links or cross-OS state leakage can reach production | Add build, link and browser checks on PRs and gate main deployment on them |

## Chosen structure and completed work

Keep the existing static Zensical site, branding and hardware/research URLs.
Add a small Platforms section instead of duplicating the entire site for each
OS. Hardware identity stays shared, with support results separated by OS.
User/developer entry points distinguish target OS from development-host OS.

Windows records were moved under `STATES.windows` without changing their
feature values or notes. `STATES.linux` starts empty: this review does not
convert private bring-up logs, public source existence or chip-level research
into published per-machine results. Source links in the new contributor map
were checked for public visibility; private repositories are not advertised.

The selector uses native HTML controls, asks for an OS on first use and retains
that choice across instant navigation. It does not detect the visitor's OS or
write a persistent preference. Unknown entries stay Not recorded, and Windows
boot milestones are absent from the Linux view. Existing hardware detail URLs
remain intact, and static support summaries remain readable without JavaScript.

## Style pass

Give Windows and Linux equal prominence with paired platform cards on the
homepage and platform overview. Retain the existing logo, orange/blue palette
and documentation navigation. Use a compact hero, shorter introductory copy
and a brief experimental-status note instead of a large construction notice.
Cards stack on small screens and retain visible keyboard focus.

The support dialog uses aligned feature/status rows with notes beneath each
feature. Labels remain legible without colour or hover. Light and dark themes,
mobile layouts and reduced-motion preferences are covered by the styling.
The existing 404 template also now supplies its missing skip-link target.

## Validation and rollout

1. Build with the pinned Zensical version and check every generated internal
   link and fragment.
2. Exercise Windows/Linux switching, known and unrecorded devices, keyboard
   controls, instant navigation and desktop/mobile viewport sizes in Chromium,
   Firefox and WebKit. Check static content without JavaScript.
3. Open a draft PR for review. Merging to `main` triggers the existing GitHub
   Pages publication path after the new checks pass. No live deployment is part
   of this change.

## Remaining content work

- Have platform maintainers supply publication-ready Linux device results and
  complete the missing evidence on inherited Windows records. Include exact
  device/OS, distribution or Windows version, source/build revisions, firmware,
  test date, behaviour, limitations and logs. Then consider structured evidence
  fields and last-verified dates rather than notes as the catalog grows.
- Validate and write separate installation/removal procedures for each released
  platform and installer. Publish requirements only for tested combinations.
- Refine provisional hardware profiles per machine and add an explicit
  not-applicable state when evidence identifies absent hardware. The current
  catalog does not mark such entries as failures.
- Confirm active branches and component ownership with maintainers before
  expanding the public source map into build-by-build onboarding instructions.
- Update the GitHub repository/org descriptions if desired; the website repo's
  current description still says Windows and DirectX 12. Those external
  descriptions are outside this code change.

These follow-ups need verified content or separate release decisions. They do
not block representing Windows and Linux accurately on the site now.

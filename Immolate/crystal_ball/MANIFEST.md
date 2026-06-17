# Crystal Ball — Immolate divergence manifest

`Immolate/` is a `git subtree` of [SpectralPack/Immolate] (base `26f41ef`). This
folder groups the files **we added** on top of upstream; the table below also
lists the upstream files we **modified in place** (those can't live here — they're
diffs against vendored code — but they're the real surface that conflicts on a
`git subtree pull`, so they're documented here in one spot).

## Added by us (live in this folder)

| File | What |
|------|------|
| `query_parse.h` | Recursive-descent parser: the `{any:[{all:[{atLeast,minAnte,maxAnte,of}]}]}` query JSON → the flat `int32` buffer the kernel reads. Self-contained, included by `immolate.c`. |
| `item_names.h` | Generated host-side `item_from_name()` lookup (enum name → id), included by `query_parse.h`. |
| `gen_item_names.py` | Regenerates `item_names.h` from the upstream `../lib/items.cl` enum. Run: `python3 crystal_ball/gen_item_names.py`. |

## Added by us (must live elsewhere)

| File | Why not here |
|------|--------------|
| `../filters/find_joker.cl` | The query-aware filter. The kernel loader resolves filters as `filters/<name>.cl` relative to the binary, so it must sit in `filters/` with the upstream filters. |

## Upstream files we modified in place (the merge surface)

| File | Our change |
|------|-----------|
| `../immolate.c` | `-j`/`-J` query args; build + bind the query buffer (kernel args 3–4); chunked launch loop with advancing `seed_offset`; `.clbin` program caching. |
| `../search.cl` | Kernel takes `query`, `queryLen`; chunked `num_seeds`/`seed_offset` launches (stays under the GPU watchdog/TDR limit); runtime-gated first-match early-exit. |
| `../lib/immolate.h` | Host helpers (`str_contains_ci`, `<dirent.h>` device listing) used by the backend extensions. |
| `../lib/seed.cl` | `s_print_line`: emit the seed per-character (`%c`) — driver-portable, avoids the `printf("%s")` → `(null)` bug on some OpenCL drivers. |
| `../filters/buggy_seeds.cl` | Trivial brace fix so the filter compiles. |

## Maintenance

```sh
# Pull upstream changes in (conflicts only ever touch the modified files above).
git subtree pull --prefix=Immolate immolate-upstream main --squash
```

After changing the upstream `Item` enum, regenerate the lookup:

```sh
python3 crystal_ball/gen_item_names.py   # rewrites item_names.h
```

[SpectralPack/Immolate]: https://github.com/SpectralPack/Immolate

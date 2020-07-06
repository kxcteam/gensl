# Gensl/gsl: Generic Spell Language

## Roadmap

Version 0.1 Checklist

- [x] basic parsing algorithm
- [ ] basic features
  - [x] string, symbol, bytes, boolean, numeric atoms
  - [x] positional and keyword nodes
  - [x] annotation nodes and annotated datum
  - [x] mixfix syntax
  - [ ] shorthand symbol atoms
  - [ ] complex form styles: list, vector, set, map
- [ ] complete 4 representations (Parsetree, Datatree, Normaltree, Canonicaltree)
  - [ ] pretty-printers for each representations
  - [ ] forgetting and embedding functions between representations
  - [ ] builder for each representation
- [ ] migration to sedlex (no unicode support)
- [ ] perfect unparse (Parsetree --> Wirestring)
- [ ] ordering and equality
  - [ ] canonical ordering
  - [ ] structural equality + semantical equivalence
- [ ] proper testing
  - [ ] proper unit testings
  - [ ] (forget . embed) among representations constitute identity
  - [ ] forgetting functions accepts all inputs
  - [ ] (x : Datatree) => Parsetree => Wirestriing could be parsed back to x
  - [ ] (parse . unparse) and (unparse . parse) constitute identity, except latter may see parsing error

Roadmap to Version 1.0-ish

- [ ] better string support
  - [ ] `(str|..|str)` strings
- [ ] phantom element support
  - [ ] comma, mapsto support
- [ ] representational tree traversal library
  - [ ] datum access via path
  - [ ] zipper library
- [ ] unicode support
  - [ ] unicode symbols
  - [ ] unicode string
  - [ ] proper codepoint range sanity check + normalization handling (NFKC for symbols and NFC for strings)
- [ ] binary encoding
- [ ] canonical hashing
- [ ] hole and partial incorrect input parsing support
- [ ] custom lexer support
- [ ] preprocessor support
  - [ ] preprocessor atom
  - [ ] preprocessor lexing element
  - [ ] preprocessor special forms

Roadmap to Version 2.0-ish

- [ ] pattern support
  - [ ] pattern language design
  - [ ] pattern match support (for schema check and info extraction)
  - [ ] transform via pattern support

Nice to have features

- [ ] conversions to and from JSON
- [ ] conversions to and from language values
  - [ ] ocaml record/list/variant
  - [ ] javascript object/array

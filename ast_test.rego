package ast_test

import future.keywords

import data.p
import data.regal.ast

test_find_vars {
    vars := ast.find_vars(rego.parse_module("p.rego", policy))
    var_names := [var.value | some var in vars]

    var_names == ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t"]
}

policy := `package p

import future.keywords

global := "foo"

allow if {
	a := global
	b := [c | c := input[x]] # can't capture x

	every d in input {
		d == "foo"
	}

	every e, f in input.bar {
		e == f
	}

	some g, h
	input.bar[g][h]
	some i in input
	some j, k in input

	[l, m, n] := [1, 2, 3]

	[o, [p, _]] := [1, [2, 1]]

	some _, [q, r] in [["foo", "bar"], [1, 2]]

	{"x": s} := {"x": 1}

    some [t] in [[1]]
}`
package regal.ast

import future.keywords.contains
import future.keywords.every
import future.keywords.if
import future.keywords.in

# simple assignment, i.e. `x := 100` returns `x`
# always returns a single var, but wrapped in an
# array for consistency
_find_assign_vars(path, value) := var if {
	value[1].type == "var"
	var := [value[1]]
}

# 'destructuring' assignment, i.e. [a, b, c] := [1, 2, 3]
_find_assign_vars(path, value) := var if {
	value[1].type == "array"
	var := [v | some v in value[1].value]
}

# var declared via `some`, i.e. `some x` or `some x, y`
_find_some_decl_vars(path, value) := [v |
	some v in value
	v.type == "var"
]

# Note: the `some` vars check currently does not account for constructs like:
# p := x if some {"x": x} in [{"x": 12}]
# Where `x` _is_ declared inside of an object/array

# single var declared via `some in`, i.e. `some x in y`
_find_some_in_decl_vars(path, value) := var if {
	arr := value[0].value
	count(arr) == 3
	arr[1].type == "var"

	var := [arr[1]]
}

# two vars declared via `some in`, i.e. `some x, y in z`
_find_some_in_decl_vars(path, value) := var if {
	arr := value[0].value
	count(arr) == 4

	var := [v |
		some i in [1, 2]
		v := arr[i]
		v.type == "var"
	]
}

# one or two vars declared via `every`, i.e. `every x in y {}`
# or `every`, i.e. `every x, y in y {}`
_find_every_vars(path, value) := var if {
	key_var := [v | v := value.key; v.type == "var"]
	val_var := [v | v := value.value; v.type == "var"]

	var := array.concat(key_var, val_var)
}

_find_vars(path, value, last) := _find_assign_vars(path, value) if {
	last == "terms"
	value[0].type == "ref"
	value[0].value[0].type == "var"
	value[0].value[0].value == "assign"
}

_find_vars(path, value, last) := _find_some_in_decl_vars(path, value) if {
	last == "symbols"
	value[0].type == "call"
}

_find_vars(path, value, last) := _find_some_decl_vars(path, value) if {
	last == "symbols"
	value[0].type != "call"
}

_find_vars(path, value, last) := _find_every_vars(path, value) if {
	last == "terms"
	value.domain
}

# METADATA
# description: |
#   traverses all nodes under provided path (using `walk`), and returns an array with
#   all variables declared via assignment (:=), `some` or `every`
find_vars(path) := [var |
	 walk(path, [_path, _value])

	some var in _find_vars(_path, _value, _path[count(_path) - 1])
]

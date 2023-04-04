# rego-perf-tuning

In this lab, I wrestle a performance issue encountered when traversing the AST of
a large (~1900 LOC) dummy policy (`p.rego`) in order to extract vars from rule
bodies. The code found in `ast1.rego` was my first attempt, which I consider to
have used idiomatic constructs. The performance was however abysmal, clocking in
evaluation on over 17 seconds! Not good for my purpose. What to do?

Each incremental attempt to improve the performance of evaluation is here provided
in `astX.rego`, where each increment is an improvement over the last. Each policy
may be evaluated using the following series of commands:

```shell
time opa parse --format json --json-include locations p.rego | \
opa eval -I -d astX.rego --profile --format pretty '_ = data.regal.ast.find_vars(input)'
```

**ast1.rego** (original)
```
+--------------+----------+----------+--------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION   |
+--------------+----------+----------+--------------+
| 2.528573396s | 1078782  | 720539   | ast.rego:8   |
| 753.283862ms | 204401   | 1081     | ast.rego:10  |
| 569.340885ms | 155193   | 270      | ast.rego:12  |
| 448.916104ms | 103822   | 52091    | ast.rego:112 |
| 448.491741ms | 103822   | 52271    | ast.rego:108 |
| 435.984725ms | 103822   | 52001    | ast.rego:110 |
| 329.723253ms | 103822   | 52091    | ast.rego:114 |
| 302.383525ms | 52721    | 2070     | ast.rego:123 |
| 201.937ms    | 51912    | 103822   | ast.rego:121 |
| 169.24213ms  | 51911    | 270      | ast.rego:72  |
+--------------+----------+----------+--------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.01s system 129% cpu 0.073 total
opa eval -I -d ast.rego --profile --format pretty   17.18s user 0.29s system 230% cpu 7.593 total
```

**ast2.rego** (one less function call)
```
+--------------+----------+----------+---------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION    |
+--------------+----------+----------+---------------+
| 1.407061236s | 613203   | 409883   | ast2.rego:8   |
| 1.004580951s | 465579   | 310656   | ast2.rego:10  |
| 442.196323ms | 103822   | 52271    | ast2.rego:106 |
| 442.167262ms | 103822   | 52091    | ast2.rego:110 |
| 427.750164ms | 103822   | 52001    | ast2.rego:108 |
| 318.29489ms  | 103822   | 52091    | ast2.rego:112 |
| 287.597566ms | 52721    | 2070     | ast2.rego:121 |
| 195.671925ms | 51912    | 103822   | ast2.rego:119 |
| 166.083201ms | 51911    | 1081     | ast2.rego:85  |
| 165.028668ms | 51911    | 270      | ast2.rego:70  |
+--------------+----------+----------+---------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.02s system 133% cpu 0.074 total
opa eval -I -d ast2.rego --profile --format pretty   13.67s user 0.23s system 229% cpu 6.050 total
```

3,5 seconds saved.

**ast3.rego** (inlined check of last path element)

```
+--------------+----------+----------+---------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION    |
+--------------+----------+----------+---------------+
| 435.339563ms | 103822   | 52271    | ast3.rego:102 |
| 432.555261ms | 103822   | 52091    | ast3.rego:106 |
| 421.12008ms  | 103822   | 52001    | ast3.rego:104 |
| 420.433646ms | 155733   | 104903   | ast3.rego:12  |
| 419.665739ms | 155733   | 104092   | ast3.rego:54  |
| 410.194807ms | 155733   | 104903   | ast3.rego:81  |
| 310.223529ms | 103822   | 52091    | ast3.rego:108 |
| 307.200735ms | 155733   | 104092   | ast3.rego:38  |
| 298.292772ms | 155733   | 104092   | ast3.rego:66  |
| 298.226405ms | 155733   | 104903   | ast3.rego:25  |
+--------------+----------+----------+---------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.01s system 131% cpu 0.074 total
opa eval -I -d ast3.rego --profile --format pretty   10.37s user 0.17s system 216% cpu 4.873 total
````

Another 3 seconds shaved off!

**ast4.rego** (simplify `every` branch to a single function)

```
+--------------+----------+----------+--------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION   |
+--------------+----------+----------+--------------+
| 433.102179ms | 103822   | 52091    | ast4.rego:96 |
| 423.011552ms | 103822   | 52271    | ast4.rego:92 |
| 418.64567ms  | 155733   | 104903   | ast4.rego:12 |
| 418.001428ms | 155733   | 104092   | ast4.rego:54 |
| 414.693943ms | 103822   | 52001    | ast4.rego:94 |
| 304.58294ms  | 155733   | 104092   | ast4.rego:38 |
| 303.244446ms | 155733   | 104092   | ast4.rego:66 |
| 302.281981ms | 155733   | 104903   | ast4.rego:25 |
| 298.368867ms | 103822   | 52091    | ast4.rego:98 |
| 298.109863ms | 155733   | 104903   | ast4.rego:83 |
+--------------+----------+----------+--------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.02s system 128% cpu 0.073 total
opa eval -I -d ast4.rego --profile --format pretty   9.37s user 0.16s system 216% cpu 4.409 total
```

Only 1 second, but fair enough.

**ast5.rego** (move **all** conditional to body of first function)

```
+--------------+----------+----------+--------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION   |
+--------------+----------+----------+--------------+
| 412.112588ms | 155733   | 104903   | ast5.rego:67 |
| 410.694835ms | 155733   | 104092   | ast5.rego:75 |
| 405.401165ms | 155733   | 104092   | ast5.rego:81 |
| 290.036909ms | 155733   | 104903   | ast5.rego:87 |
| 264.581314ms | 52721    | 2070     | ast5.rego:98 |
| 183.543399ms | 51912    | 103822   | ast5.rego:96 |
| 7.283083ms   | 3        | 3        | input        |
| 2.064239ms   | 1081     | 180      | ast5.rego:88 |
| 2.056661ms   | 360      | 360      | ast5.rego:66 |
| 1.623244ms   | 1081     | 540      | ast5.rego:69 |
+--------------+----------+----------+--------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.02s system 127% cpu 0.075 total
opa eval -I -d ast5.rego --profile --format pretty   4.63s user 0.09s system 213% cpu 2.207 total
```

5 seconds down, whoa!

**ast6.rego** (use `else` to avoid extra calls if successful)

```
+--------------+----------+----------+--------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION   |
+--------------+----------+----------+--------------+
| 410.125011ms | 155733   | 104903   | ast6.rego:67 |
| 410.056865ms | 154653   | 103372   | ast6.rego:75 |
| 399.965267ms | 154383   | 103102   | ast6.rego:81 |
| 286.16836ms  | 153843   | 103283   | ast6.rego:87 |
| 265.340941ms | 52721    | 2070     | ast6.rego:98 |
| 185.947135ms | 51912    | 103822   | ast6.rego:96 |
| 7.790291ms   | 3        | 3        | input        |
| 2.088955ms   | 360      | 360      | ast6.rego:66 |
| 1.740907ms   | 721      | 180      | ast6.rego:88 |
| 1.696621ms   | 360      | 270      | ast6.rego:12 |
+--------------+----------+----------+--------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.01s system 128% cpu 0.068 total
opa eval -I -d ast6.rego --profile --format pretty   4.62s user 0.09s system 214% cpu 2.196 total
````

No impact. I supposedly the assertions are cheap enough already.

**ast7.rego** (revert `else` change, move "last" check to outer loop and pass in args)

```
+--------------+----------+----------+--------------+
|     TIME     | NUM EVAL | NUM REDO |   LOCATION   |
+--------------+----------+----------+--------------+
| 353.57539ms  | 208453   | 157802   | ast7.rego:94 |
| 170.063325ms | 51912    | 103822   | ast7.rego:92 |
| 8.321999ms   | 3        | 3        | input        |
| 4.366569ms   | 1081     | 1081     | ast7.rego:63 |
| 1.916717ms   | 360      | 360      | ast7.rego:62 |
| 1.616987ms   | 1081     | 180      | ast7.rego:84 |
| 1.530852ms   | 540      | 540      | ast7.rego:13 |
| 1.451758ms   | 360      | 270      | ast7.rego:12 |
| 1.359224ms   | 1081     | 540      | ast7.rego:65 |
| 1.252534ms   | 1081     | 1081     | ast7.rego:83 |
+--------------+----------+----------+--------------+
opa parse --format json --json-include locations p.rego  0.08s user 0.01s system 129% cpu 0.075 total
opa eval -I -d ast7.rego --profile --format pretty   1.27s user 0.03s system 181% cpu 0.718 total
```

Gooooood damn! Almost 3,5 down and we're now almost under a second.
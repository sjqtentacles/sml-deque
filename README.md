# sml-deque

[![CI](https://github.com/sjqtentacles/sml-deque/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-deque/actions/workflows/ci.yml)

A purely functional double-ended queue (deque) for Standard ML.

Elements can be pushed and popped at either end. `sml-deque` uses the classic
two-list (banker's) representation -- a front list and a reversed back list,
rebalanced by splitting whichever side grows while the other empties -- giving
**O(1) amortised** cost at both ends. Every operation is persistent.

## Portability

Pure Standard ML using only the Basis library -- no FFI, no threads. Verified
on **MLton** and **Poly/ML**.

## Building and testing

```sh
make test        # build + run the suite under MLton (default)
make test-poly   # run the suite under Poly/ML
make all-tests   # run under both
make clean
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-deque
smlpkg sync
```

Then reference the library basis from your own `.mlb`:

```
lib/github.com/sjqtentacles/sml-deque/deque.mlb
```

For Poly/ML, `use` the `deque.sig` and `deque.sml` sources in order.

## Usage

```sml
val d = Deque.fromList [1, 2, 3]            (* head = front *)

(* queue (FIFO): push back, pop front *)
val d1 = Deque.pushBack (4, d)              (* 1 2 3 4 *)
val SOME (x, d2) = Deque.popFront d1        (* x = 1   *)

(* stack (LIFO): push front, pop front *)
val s = Deque.pushFront (0, d)              (* 0 1 2 3 *)
val SOME (y, _) = Deque.popFront s          (* y = 0   *)

val f = Deque.peekFront d                   (* SOME 1  *)
val b = Deque.peekBack d                    (* SOME 3  *)
val r = Deque.toList (Deque.rev d)          (* [3,2,1] *)

(* cheap O(1) end views that never rebalance *)
val fv = Deque.frontView d                  (* SOME 1  *)

(* treat it as a sequence *)
val third  = Deque.nth d 2                  (* SOME 3  *)
val doubled = Deque.map (fn x => x * 2) d    (* 2 4 6   *)
val total  = Deque.foldl (op +) 0 d         (* 6       *)
val evens  = Deque.filter (fn x => x mod 2 = 0) d
val joined = Deque.append (d, Deque.fromList [4,5])
val same   = Deque.equal (op =) (d, Deque.fromList [1,2,3])   (* true *)
```

`toList o fromList` is the identity (the list head is the deque front).
`equal`/`append`/`map`/`foldl`/`foldr`/`filter` all work over the logical
front-to-back sequence, independent of the internal front/back split, so two
deques built differently compare `equal` as long as their sequences match.

## API summary

| Function | Description |
| --- | --- |
| `empty : 'a deque` | The empty deque. |
| `isEmpty : 'a deque -> bool` | Whether the deque is empty. |
| `size : 'a deque -> int` | Number of elements. |
| `pushFront / pushBack : 'a * 'a deque -> 'a deque` | Push at an end. |
| `popFront / popBack : 'a deque -> ('a * 'a deque) option` | Pop at an end. |
| `peekFront / peekBack : 'a deque -> 'a option` | Look at an end (via pop). |
| `frontView / backView : 'a deque -> 'a option` | O(1) end view, no rebalance. |
| `nth : 'a deque -> int -> 'a option` | Element at a logical index. |
| `fromList : 'a list -> 'a deque` | Build (head = front). |
| `toList : 'a deque -> 'a list` | Front-to-back list. |
| `rev : 'a deque -> 'a deque` | Reverse the deque. |
| `map : ('a -> 'b) -> 'a deque -> 'b deque` | Map (order preserved). |
| `app : ('a -> unit) -> 'a deque -> unit` | Apply front to back. |
| `foldl / foldr : ('a * 'b -> 'b) -> 'b -> 'a deque -> 'b` | Fold front→back / back→front. |
| `filter : ('a -> bool) -> 'a deque -> 'a deque` | Keep matching elements. |
| `append : 'a deque * 'a deque -> 'a deque` | Concatenate. |
| `equal : ('a * 'a -> bool) -> 'a deque * 'a deque -> bool` | Compare sequences. |

## License

MIT. See [LICENSE](LICENSE).

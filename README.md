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
```

`toList o fromList` is the identity (the list head is the deque front).

## API summary

| Function | Description |
| --- | --- |
| `empty : 'a deque` | The empty deque. |
| `isEmpty : 'a deque -> bool` | Whether the deque is empty. |
| `size : 'a deque -> int` | Number of elements. |
| `pushFront / pushBack : 'a * 'a deque -> 'a deque` | Push at an end. |
| `popFront / popBack : 'a deque -> ('a * 'a deque) option` | Pop at an end. |
| `peekFront / peekBack : 'a deque -> 'a option` | Look at an end. |
| `fromList : 'a list -> 'a deque` | Build (head = front). |
| `toList : 'a deque -> 'a list` | Front-to-back list. |
| `rev : 'a deque -> 'a deque` | Reverse the deque. |

## License

MIT. See [LICENSE](LICENSE).

(* deque.sml

   Implementation of DEQUE as a banker's two-list deque.

   A deque is (front, sizeFront, back, sizeBack) where `front` is in
   front-to-back order and `back` is in back-to-front order (its head is the
   last element). The logical sequence is `front @ rev back`.

   Invariant maintained after every pop: if one side is empty and the other
   has more than one element, we rebalance by splitting the non-empty side in
   half so neither end can degrade to O(n) per operation. Pushes never break
   the invariant. *)

structure Deque :> DEQUE =
struct
  (* front, |front|, back (reversed), |back| *)
  type 'a deque = 'a list * int * 'a list * int

  val empty : 'a deque = ([], 0, [], 0)

  fun isEmpty (_, fn_, _, bn) = fn_ + bn = 0
  fun size (_, fn_, _, bn) = fn_ + bn

  (* rebalance when one side is empty but the other has > 1 element *)
  fun balance (d as (f, fn_, b, bn)) =
      if fn_ = 0 andalso bn > 1 then
        (* back holds everything (in reverse). Logical seq = rev b.
           Put first half in front (in order), keep second half as back. *)
        let
          val seq = List.rev b              (* logical front-to-back *)
          val n = bn
          val h = n div 2
          fun take (0, _, acc) = List.rev acc
            | take (k, x :: xs, acc) = take (k - 1, xs, x :: acc)
            | take (_, [], acc) = List.rev acc
          fun drop (0, xs) = xs
            | drop (k, _ :: xs) = drop (k - 1, xs)
            | drop (_, []) = []
          val front = take (h, seq, [])
          val rest  = drop (h, seq)          (* front-to-back *)
          val back  = List.rev rest          (* back-to-front *)
        in
          (front, h, back, n - h)
        end
      else if bn = 0 andalso fn_ > 1 then
        let
          val seq = f                        (* logical front-to-back *)
          val n = fn_
          val h = n div 2
          fun take (0, _, acc) = List.rev acc
            | take (k, x :: xs, acc) = take (k - 1, xs, x :: acc)
            | take (_, [], acc) = List.rev acc
          fun drop (0, xs) = xs
            | drop (k, _ :: xs) = drop (k - 1, xs)
            | drop (_, []) = []
          val front = take (h, seq, [])
          val rest  = drop (h, seq)
          val back  = List.rev rest
        in
          (front, h, back, n - h)
        end
      else d

  fun pushFront (x, (f, fn_, b, bn)) = (x :: f, fn_ + 1, b, bn)
  fun pushBack  (x, (f, fn_, b, bn)) = (f, fn_, x :: b, bn + 1)

  fun popFront (f, fn_, b, bn) =
      (case f of
           x :: f' => SOME (x, balance (f', fn_ - 1, b, bn))
         | [] =>
             (* front empty: the only element(s) are in back *)
             (case List.rev b of
                  [] => NONE
                | x :: rest => SOME (x, balance (rest, bn - 1, [], 0))))

  fun popBack (f, fn_, b, bn) =
      (case b of
           x :: b' => SOME (x, balance (f, fn_, b', bn - 1))
         | [] =>
             (case List.rev f of
                  [] => NONE
                | x :: rest => SOME (x, balance ([], 0, rest, fn_ - 1))))

  fun peekFront d =
      (case popFront d of SOME (x, _) => SOME x | NONE => NONE)
  fun peekBack d =
      (case popBack d of SOME (x, _) => SOME x | NONE => NONE)

  fun fromList xs = (xs, List.length xs, [], 0)

  fun toList (f, _, b, _) = f @ List.rev b

  fun rev (f, fn_, b, bn) = (b, bn, f, fn_)
end

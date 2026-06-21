(* deque.sig

   A purely functional double-ended queue (deque).

   Elements can be pushed and popped at either end. The implementation is the
   classic two-list (banker's) deque: a front list and a reversed back list,
   rebalanced by splitting whichever list grows while the other empties. This
   gives O(1) amortised cost at both ends and is fully portable.

   `fromList` reads its argument front-to-back: the head of the list is the
   front of the deque, so `toList o fromList` is the identity.

   All operations are persistent. *)

signature DEQUE =
sig
  type 'a deque

  val empty   : 'a deque
  val isEmpty : 'a deque -> bool
  val size    : 'a deque -> int

  val pushFront : 'a * 'a deque -> 'a deque
  val pushBack  : 'a * 'a deque -> 'a deque

  (* Pop from an end: the element and the remaining deque, or NONE if empty. *)
  val popFront : 'a deque -> ('a * 'a deque) option
  val popBack  : 'a deque -> ('a * 'a deque) option

  val peekFront : 'a deque -> 'a option
  val peekBack  : 'a deque -> 'a option

  (* fromList: head of list = front of deque. *)
  val fromList : 'a list -> 'a deque
  val toList   : 'a deque -> 'a list

  (* Reverse the deque (front becomes back). *)
  val rev : 'a deque -> 'a deque
end

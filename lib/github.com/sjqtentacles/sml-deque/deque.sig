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

  (* Cheap O(1) views of the ends that never rebalance (unlike peekFront/
     peekBack, which are defined via the rebalancing pops). *)
  val frontView : 'a deque -> 'a option
  val backView  : 'a deque -> 'a option

  (* The element at logical index i (0 = front), or NONE if out of range. *)
  val nth : 'a deque -> int -> 'a option

  (* fromList: head of list = front of deque. *)
  val fromList : 'a list -> 'a deque
  val toList   : 'a deque -> 'a list

  (* Reverse the deque (front becomes back). *)
  val rev : 'a deque -> 'a deque

  (* Traversals over the logical front-to-back sequence. *)
  val map   : ('a -> 'b) -> 'a deque -> 'b deque
  val app   : ('a -> unit) -> 'a deque -> unit
  val foldl : ('a * 'b -> 'b) -> 'b -> 'a deque -> 'b   (* front to back *)
  val foldr : ('a * 'b -> 'b) -> 'b -> 'a deque -> 'b   (* back to front *)
  val filter : ('a -> bool) -> 'a deque -> 'a deque

  (* Concatenate: all of the first deque's elements precede the second's. *)
  val append : 'a deque * 'a deque -> 'a deque
  (* Structural equality of the logical sequences under an element equality. *)
  val equal : ('a * 'a -> bool) -> 'a deque * 'a deque -> bool
end

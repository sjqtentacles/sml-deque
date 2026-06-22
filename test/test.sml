(* Tests for sml-deque, standardized on the shared sml-test Harness. *)

structure Tests =
struct
  open Harness

structure D = Deque

fun forceSome (SOME x) = x
  | forceSome NONE = raise Fail "expected SOME"

fun run () =
  let
    (* ---- empty ---- *)
    val () = check "empty isEmpty" (D.isEmpty D.empty)
    val () = check "empty size 0" (D.size D.empty = 0)
    val () = check "empty toList []" (D.toList D.empty = ([] : int list))
    val () = check "empty popFront NONE"
                   (case D.popFront (D.empty : int D.deque) of NONE => true | _ => false)
    val () = check "empty popBack NONE"
                   (case D.popBack (D.empty : int D.deque) of NONE => true | _ => false)
    val () = check "empty peekFront NONE"
                   ((D.peekFront (D.empty : int D.deque)) = NONE)
    val () = check "empty peekBack NONE"
                   ((D.peekBack (D.empty : int D.deque)) = NONE)

    (* ---- fromList / toList identity ---- *)
    val () = check "fromList toList identity"
                   (D.toList (D.fromList [1,2,3,4,5]) = [1,2,3,4,5])
    val () = check "fromList size" (D.size (D.fromList [1,2,3,4,5]) = 5)
    val () = check "fromList singleton" (D.toList (D.fromList [7]) = [7])

    (* ---- push ends ---- *)
    val d = D.pushBack (3, D.pushBack (2, D.pushBack (1, D.empty)))
    val () = check "pushBack order" (D.toList d = [1,2,3])
    val e = D.pushFront (3, D.pushFront (2, D.pushFront (1, D.empty)))
    val () = check "pushFront order" (D.toList e = [3,2,1])
    val () = check "peekFront" (D.peekFront d = SOME 1)
    val () = check "peekBack" (D.peekBack d = SOME 3)

    (* ---- FIFO: pushBack + popFront ---- *)
    val () =
      let
        fun enq (q, []) = q
          | enq (q, x :: xs) = enq (D.pushBack (x, q), xs)
        val q0 = enq (D.empty, [1,2,3,4,5])
        fun drain (q, acc) =
            case D.popFront q of
                NONE => List.rev acc
              | SOME (x, q') => drain (q', x :: acc)
      in
        check "FIFO order (pushBack/popFront)" (drain (q0, []) = [1,2,3,4,5])
      end

    (* ---- LIFO: pushFront + popFront ---- *)
    val () =
      let
        fun push (q, []) = q
          | push (q, x :: xs) = push (D.pushFront (x, q), xs)
        val q0 = push (D.empty, [1,2,3,4,5])
        fun drain (q, acc) =
            case D.popFront q of
                NONE => List.rev acc
              | SOME (x, q') => drain (q', x :: acc)
      in
        check "LIFO order (pushFront/popFront)" (drain (q0, []) = [5,4,3,2,1])
      end

    (* ---- pop from both ends ---- *)
    val () =
      let
        val q = D.fromList [10, 20, 30, 40]
        val (a, q1) = forceSome (D.popFront q)
        val (b, q2) = forceSome (D.popBack q1)
        val (c, q3) = forceSome (D.popFront q2)
        val (e, q4) = forceSome (D.popBack q3)
      in
        check "interleaved pop both ends"
              (a = 10 andalso b = 40 andalso c = 20 andalso e = 30
               andalso D.isEmpty q4)
      end

    (* ---- rev ---- *)
    val () = check "rev" (D.toList (D.rev (D.fromList [1,2,3,4])) = [4,3,2,1])
    val () = check "rev empty" (D.toList (D.rev (D.empty : int D.deque)) = [])
    val () = check "rev rev identity"
                   (D.toList (D.rev (D.rev (D.fromList [1,2,3]))) = [1,2,3])
    val () = check "rev then popFront is old back"
                   (D.peekFront (D.rev (D.fromList [1,2,3])) = SOME 3)

    (* ---- oracle test: random-ish op sequence vs a list model ----
       Model the deque as a plain list; compare toList after each op. *)
    val () =
      let
        (* ops: F=pushFront, B=pushBack, f=popFront, b=popBack *)
        val ops = [#"B",#"B",#"F",#"b",#"B",#"F",#"f",#"B",#"B",#"b",
                   #"F",#"F",#"f",#"f",#"B",#"b",#"f",#"B",#"F",#"b"]
        fun step (c, (dq, model, n)) =
            case c of
                #"F" => (D.pushFront (n, dq), n :: model, n + 1)
              | #"B" => (D.pushBack (n, dq), model @ [n], n + 1)
              | #"f" =>
                  (case (D.popFront dq, model) of
                       (SOME (x, dq'), m :: ms) =>
                         (if x <> m then raise Fail "front mismatch" else ();
                          (dq', ms, n))
                     | (NONE, []) => (dq, model, n)
                     | _ => raise Fail "front empty mismatch")
              | #"b" =>
                  (case (D.popBack dq, List.rev model) of
                       (SOME (x, dq'), m :: ms) =>
                         (if x <> m then raise Fail "back mismatch" else ();
                          (dq', List.rev ms, n))
                     | (NONE, []) => (dq, model, n)
                     | _ => raise Fail "back empty mismatch")
              | _ => (dq, model, n)
        val (finalDq, finalModel, _) =
            List.foldl step (D.empty, [], 0) ops
        val matches = (D.toList finalDq = finalModel)
      in
        check "oracle: op sequence matches list model" matches
      end
      handle Fail _ => check "oracle: op sequence matches list model" false

    (* ---- long alternating sequence stays correct ---- *)
    val () =
      let
        (* push 0..99 alternating ends, then drain from front *)
        fun build (i, q) =
            if i > 99 then q
            else build (i + 1,
                        if i mod 2 = 0 then D.pushBack (i, q)
                        else D.pushFront (i, q))
        val q = build (0, D.empty)
        val () = if D.size q <> 100 then raise Fail "size" else ()
        (* fronts: odds descending 99,97,...,1 ; backs: evens 0,2,...,98 *)
        val expected =
            let fun odds i = if i < 1 then [] else i :: odds (i - 2)
                fun evens i = if i > 98 then [] else i :: evens (i + 2)
            in odds 99 @ evens 0 end
      in
        check "long alternating push sequence" (D.toList q = expected);
        check "long alternating size" (D.size q = 100)
      end

    (* ---- single element edge: pop empties cleanly ---- *)
    val () =
      let
        val q = D.pushFront (1, D.empty)
        val (x, q') = forceSome (D.popBack q)
      in
        check "single popBack empties" (x = 1 andalso D.isEmpty q')
      end
    val () =
      let
        val q = D.pushBack (1, D.empty)
        val (x, q') = forceSome (D.popFront q)
      in
        check "single popFront empties" (x = 1 andalso D.isEmpty q')
      end
  in
    Harness.run ()
  end
end

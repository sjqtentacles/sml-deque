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

    (* ---- frontView / backView (non-rebalancing) ---- *)
    val () = section "frontView / backView"
    val () = check "frontView empty NONE"
                   (D.frontView (D.empty : int D.deque) = NONE)
    val () = check "backView empty NONE"
                   (D.backView (D.empty : int D.deque) = NONE)
    val () = check "frontView matches front" (D.frontView (D.fromList [1,2,3]) = SOME 1)
    val () = check "backView matches back" (D.backView (D.fromList [1,2,3]) = SOME 3)
    val () = check "frontView single" (D.frontView (D.fromList [9]) = SOME 9)
    val () = check "backView single" (D.backView (D.fromList [9]) = SOME 9)
    (* a deque whose front list is empty (all elements pushed to back) *)
    val () =
      let val q = D.pushBack (3, D.pushBack (2, D.pushBack (1, D.empty)))
      in
        check "frontView when front empty" (D.frontView q = SOME 1);
        check "backView when front empty" (D.backView q = SOME 3)
      end
    val () = check "frontView agrees with peekFront"
                   (D.frontView (D.fromList [4,5,6]) = D.peekFront (D.fromList [4,5,6]))

    (* ---- nth ---- *)
    val () = section "nth"
    val nd = D.fromList [10,20,30,40]
    val () = check "nth 0" (D.nth nd 0 = SOME 10)
    val () = check "nth 2" (D.nth nd 2 = SOME 30)
    val () = check "nth last" (D.nth nd 3 = SOME 40)
    val () = check "nth out of range" (D.nth nd 4 = NONE)
    val () = check "nth negative" (D.nth nd ~1 = NONE)
    val () = check "nth empty" (D.nth (D.empty : int D.deque) 0 = NONE)
    (* nth respects logical order even with a mixed front/back deque *)
    val () =
      let val q = D.pushFront (0, D.pushBack (2, D.pushBack (1, D.empty)))
      in check "nth on mixed deque" (D.nth q 0 = SOME 0 andalso D.nth q 2 = SOME 2) end

    (* ---- map / app / foldl / foldr / filter ---- *)
    val () = section "map / app / folds / filter"
    val () = check "map doubles in order"
                   (D.toList (D.map (fn x => x * 2) (D.fromList [1,2,3])) = [2,4,6])
    val () = check "map empty" (D.toList (D.map (fn x => x + 1) (D.empty : int D.deque)) = [])
    val () =
      let val acc = ref []
      in D.app (fn x => acc := x :: !acc) (D.fromList [1,2,3]);
         check "app visits front to back" (List.rev (!acc) = [1,2,3])
      end
    val () = check "foldl front-to-back"
                   (D.foldl (fn (x, a) => a @ [x]) [] (D.fromList [1,2,3]) = [1,2,3])
    val () = check "foldl sum" (D.foldl (fn (x, a) => a + x) 0 (D.fromList [1,2,3,4]) = 10)
    val () = check "foldr back-to-front"
                   (D.foldr (fn (x, a) => a @ [x]) [] (D.fromList [1,2,3]) = [3,2,1])
    val () = check "filter keeps evens"
                   (D.toList (D.filter (fn x => x mod 2 = 0) (D.fromList [1,2,3,4,5,6])) = [2,4,6])
    val () = check "filter all-out empty"
                   (D.isEmpty (D.filter (fn _ => false) (D.fromList [1,2,3])))

    (* ---- append / equal ---- *)
    val () = section "append / equal"
    val () = check "append joins"
                   (D.toList (D.append (D.fromList [1,2], D.fromList [3,4])) = [1,2,3,4])
    val () = check "append left empty"
                   (D.toList (D.append (D.empty, D.fromList [3,4])) = [3,4])
    val () = check "append right empty"
                   (D.toList (D.append (D.fromList [1,2], D.empty)) = [1,2])
    val () = check "append size" (D.size (D.append (D.fromList [1,2,3], D.fromList [4,5])) = 5)
    val eqI = fn (a : int, b) => a = b
    val () = check "equal same" (D.equal eqI (D.fromList [1,2,3], D.fromList [1,2,3]))
    val () = check "equal different content"
                   (not (D.equal eqI (D.fromList [1,2,3], D.fromList [1,2,4])))
    val () = check "equal different length"
                   (not (D.equal eqI (D.fromList [1,2], D.fromList [1,2,3])))
    val () = check "equal empty" (D.equal eqI (D.empty, D.empty))
    (* equality is by logical sequence, not internal representation *)
    val () =
      let
        val q1 = D.fromList [1,2,3]
        val q2 = D.pushFront (1, D.pushBack (3, D.pushBack (2, D.empty)))
      in check "equal ignores representation" (D.equal eqI (q1, q2)) end
  in
    Harness.run ()
  end
end

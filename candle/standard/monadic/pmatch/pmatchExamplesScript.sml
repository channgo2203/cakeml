open HolKernel boolLib bossLib lcsymtacs
open deepMatchesLib deepMatchesSyntax deepMatchesTheory
open holKernelTheory

val _ = new_theory"pmatchExamples"

(* TODO: stolen from deepMatchesLib.sml; should be exported? *)
val PAIR_EQ_COLLAPSE = prove (
``(((FST x = (a:'a)) /\ (SND x = (b:'b))) = (x = (a, b)))``,
Cases_on `x` THEN SIMP_TAC std_ss [] THEN METIS_TAC[])

val pabs_elim_ss =
    simpLib.conv_ss
      {name  = "PABS_ELIM_CONV",
       trace = 2,
       key   = SOME ([],``UNCURRY (f:'a -> 'b -> bool)``),
       conv  = K (K pairTools.PABS_ELIM_CONV)}

val select_conj_ss =
    simpLib.conv_ss
      {name  = "SELECT_CONJ_SS_CONV",
       trace = 2,
       key   = SOME ([],``$@ (f:'a -> bool)``),
       conv  = K (K (SIMP_CONV (std_ss++boolSimps.CONJ_ss) []))};

val static_ss = simpLib.merge_ss
  [pabs_elim_ss,
   pairSimps.paired_forall_ss,
   pairSimps.paired_exists_ss,
   pairSimps.gen_beta_ss,
   select_conj_ss,
   elim_fst_snd_select_ss,
   boolSimps.EQUIV_EXTRACT_ss,
   simpLib.rewrites [
     some_var_bool_T, some_var_bool_F,
     GSYM boolTheory.F_DEF,
     pairTheory.EXISTS_PROD,
     pairTheory.FORALL_PROD,
     PMATCH_ROW_EQ_NONE,
     PMATCH_ROW_COND_def,
     PAIR_EQ_COLLAPSE,
     oneTheory.one]];

fun rc_ss gl = srw_ss() ++ simpLib.merge_ss (static_ss :: gl)
(* -- *)

val raconv_PMATCH_eq = prove(
  ``^(rhs(concl(SPEC_ALL raconv_def))) =
    CASE (tm1,tm2) OF
    [ ||. (Var _ _, Var _ _) ~> alphavars env tm1 tm2
    ; ||. (Const _ _, Const _ _) ~> (tm1 = tm2)
    ; ||(s1,t1,s2,t2). (Comb s1 t1, Comb s2 t2)
        ~> raconv env s1 s2 ∧ raconv env t1 t2
    ; ||(v1,t1,v2,t2). (Abs v1 t1, Abs v2 t2)
        ~> CASE (v1,v2) OF
           [ ||(n1,ty1,n2,ty2). (Var n1 ty1,Var n2 ty2)
               ~> (ty1 = ty2) ∧ raconv ((v1,v2)::env) t1 t2
           ; ||. _ ~> F
           ]
    ; ||. _ ~> F
    ]``,
  rpt (
  BasicProvers.PURE_CASE_TAC >>
  FULL_SIMP_TAC (rc_ss []) [PMATCH_EVAL, PMATCH_ROW_COND_def,
    PMATCH_INCOMPLETE_def] ))

val raconv_PMATCH =
  raconv_def
  |> CONV_RULE(STRIP_QUANT_CONV(RAND_CONV(REWR_CONV raconv_PMATCH_eq)))
  |> curry save_thm "raconv_PMATCH"

(* --- old version ----

(* stolen from deepMatchesLib.sml TODO *)

val PAIR_EQ_COLLAPSE = prove (
``(((FST x = (a:'a)) /\ (SND x = (b:'b))) = (x = (a, b)))``,
Cases_on `x` THEN SIMP_TAC std_ss [] THEN METIS_TAC[])

val pabs_elim_ss =
    simpLib.conv_ss
      {name  = "PABS_ELIM_CONV",
       trace = 2,
       key   = SOME ([],``UNCURRY (f:'a -> 'b -> bool)``),
       conv  = K (K pairTools.PABS_ELIM_CONV)}

val elim_fst_snd_select_ss =
    simpLib.conv_ss
      {name  = "ELIM_FST_SND_SELECT_CONV",
       trace = 2,
       key   = SOME ([],``$@ (f:'a -> bool)``),
       conv  = K (K ELIM_FST_SND_SELECT_CONV)}

fun rc_ss gl = list_ss ++ simpLib.merge_ss
 (gl @
  [pabs_elim_ss,
   pairSimps.paired_forall_ss,
   pairSimps.paired_exists_ss,
   pairSimps.gen_beta_ss,
   elim_fst_snd_select_ss,
   simpLib.rewrites [
     pairTheory.EXISTS_PROD,
     pairTheory.FORALL_PROD,
     PMATCH_ROW_EQ_NONE,
     PMATCH_ROW_COND_def,
     PAIR_EQ_COLLAPSE,
     oneTheory.one]])

(* -- *)

(*
pure:
  raconv_def -- a lot of redundancy in standard repr
  type_of_def -- one nested case
  dest_var,comb,abs,eq / is_eq -- catch all

monadic:
  mk_comb -- deep nesting (with string literal)
  TRANS_def -- very deep nesting
  MK_COMB_def -- very deep nesting
  ABS_def -- very deep nesting
  BETA_def -- deep nesting, catch all
  EQ_MP_def -- very deep nesting
*)

fun btotal f x = f x handle HOL_ERR _ => false

fun PMATCH_CATCHALL_INTRO_CONV tm = let
  val (x,xs) = dest_PMATCH tm
  fun no_common_el xs ys = not (exists (fn x => mem x ys) xs);
  fun is_indep_pmrach_row tm = let
    val (x,y,z) = dest_PMATCH_ROW tm
    val (x1,x2) = pairSyntax.dest_pabs x
    val (y1,y2) = pairSyntax.dest_pabs y
    val (z1,z2) = pairSyntax.dest_pabs z
    val _ = if y2 = T then () else fail()
    val _ = if y1 = x1 andalso x1 = z1 then () else fail()
    in (no_common_el (free_vars z1) (free_vars z2),(z2,tm)) end
  val ys = map is_indep_pmrach_row xs
  val fixed = filter (not o fst) ys |> map (snd o snd)
  val other = filter fst ys |> map snd
  fun insert x y [] = [(x,[y])]
    | insert x y ((k,ys)::rest) =
        if aconv k x then (k,y::ys)::rest else (k,ys)::insert x y rest
  fun partition [] res = res
    | partition ((x,y)::xs) res = partition xs (insert x y res)
  val parts = partition other []
  val parts = map (fn (x,ys) => (x,ys,length ys)) parts
  fun max [] = 0
    | max (x::xs) = let
    val m = max xs
    in if m < x then x else m end
  val m = max (map #3 parts)
  val t = #1 (first (fn (x,y,l) => m = l) parts)
  val fixed_left = filter (fn (x,y,z) => not (aconv x t)) parts |> map #2
  val v = variant (free_vars t) (mk_var("v",type_of x))
  val last_row = mk_PMATCH_ROW (mk_abs(v,v),mk_abs(v,T),mk_abs(v,t))
  val l = listSyntax.mk_list(fixed @ flatten fixed_left @ [last_row],
                             type_of last_row)
  val l1 = listSyntax.mk_list(xs,type_of last_row)
  val gv = genvar (type_of x)
  val goal = mk_forall(gv,mk_eq(mk_PMATCH gv l1,mk_PMATCH gv l))
  (* set_goal ([],goal) *)
  val lemma = prove(goal,
    gen_tac >>
    SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def] >>
    BasicProvers.EVERY_CASE_TAC >>
    FULL_SIMP_TAC (rc_ss[]) [] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    FULL_SIMP_TAC (rc_ss[]) [] >>
    fs[] >> rw[] >>
    spose_not_then strip_assume_tac >>
    rpt BasicProvers.VAR_EQ_TAC >>
    FULL_SIMP_TAC (rc_ss[]) [] >>
    rpt (
      first_assum(fn th =>
        let val t = find_term(btotal(is_var o rhs o dest_neg))(concl th) in
          Cases_on `^(rhs(dest_neg t))` >> fs[]
        end)))
  in SPEC x lemma end

fun ONCE_BOT_DEPTH_CONV conv tm =
  let val c = ONCE_BOT_DEPTH_CONV conv in
    RATOR_CONV c ORELSEC
    RAND_CONV c ORELSEC
    ABS_CONV c ORELSEC
    conv
  end tm

fun BOT_SWEEP_CONV conv tm =
  let val c = BOT_SWEEP_CONV conv in
    TRY_CONV(RATOR_CONV c) THENC
    TRY_CONV(RAND_CONV c) THENC
    TRY_CONV(ABS_CONV c) THENC
    TRY_CONV conv
  end tm

(*
fun RETRY_SWEEP_CONV P conv tm =
  let
    val c = RETRY_SWEEP_CONV P conv
    val d = RATOR_CONV c ORELSEC
            RAND_CONV c ORELSEC
            ABS_CONV c
    fun r tm = (conv ORELSEC (d THENC r)) tm
  in
    if P tm then r else d
  end tm
*)

val raconv_PMATCH = save_thm("raconv_PMATCH",
  CONV_RULE
  ((funpow 3 (RAND_CONV o funpow 2 ABS_CONV)
     (PMATCH_INTRO_CONV THENC PMATCH_CATCHALL_INTRO_CONV)
    THENC PMATCH_INTRO_CONV THENC PMATCH_CATCHALL_INTRO_CONV)
   |> (STRIP_QUANT_CONV o RAND_CONV))
  raconv_def)
(* slower, more general:
  (PMATCH_INTRO_CONV THENC
   PMATCH_CATCHALL_INTRO_CONV)
  |> BOT_SWEEP_CONV
  |> Lib.with_flag(Feedback.emit_MESG,false)
     (C CONV_RULE raconv_def)
*)

(* general version doesn't work because BOT_SWEEP_CONV finds a too-deep
   case-term first that messes up the rest *)
val type_of_PMATCH = save_thm("type_of_PMATCH",
  (PMATCH_INTRO_CONV THENC
   PMATCH_CATCHALL_INTRO_CONV)
  |> (fn c =>
      (RATOR_CONV o RAND_CONV o funpow 2 ABS_CONV o
       funpow 2 (RAND_CONV o ABS_CONV)) c
      THENC c)
  |> (STRIP_QUANT_CONV o RAND_CONV)
  |> C CONV_RULE type_of_def)

(* PMATCH_INTRO_CONV fails because it doesn't know about :term *)
val t = dest_var_def |> SPEC_ALL |> concl |> rhs
val t' = convert_case t
val go = mk_eq(t,t')
(* set_goal([],go) *)
val th = prove(go,
  rpt(CASE_TAC >> FULL_SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def]) >>
  fs[])

val dest_var_PMATCH = save_thm("dest_var_PMATCH",
  CONV_RULE
    ((REWR_CONV th THENC PMATCH_CATCHALL_INTRO_CONV)
     |> (STRIP_QUANT_CONV o RAND_CONV))
  dest_var_def)

(* PMATCH_INTRO_CONV fails because it doesn't know about :term *)
val t = dest_comb_def |> SPEC_ALL |> concl |> rhs
val t' = convert_case t
val go = mk_eq(t,t')
(* set_goal([],go) *)
val th = prove(go,
  rpt(CASE_TAC >> FULL_SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def]) >>
  fs[])

val dest_comb_PMATCH = save_thm("dest_comb_PMATCH",
  CONV_RULE
    ((REWR_CONV th THENC PMATCH_CATCHALL_INTRO_CONV)
     |> (STRIP_QUANT_CONV o RAND_CONV))
  dest_comb_def)

(* PMATCH_INTRO_CONV fails because it doesn't know about :term *)
val t = dest_abs_def |> SPEC_ALL |> concl |> rhs
val t' = convert_case t
val go = mk_eq(t,t')
(* set_goal([],go) *)
val th = prove(go,
  rpt(CASE_TAC >> FULL_SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def]) >>
  fs[])

val dest_abs_PMATCH = save_thm("dest_abs_PMATCH",
  CONV_RULE
    ((REWR_CONV th THENC PMATCH_CATCHALL_INTRO_CONV)
     |> (STRIP_QUANT_CONV o RAND_CONV))
  dest_abs_def)

(* PMATCH_INTRO_CONV fails because it doesn't know about :term *)
val t = dest_eq_def |> SPEC_ALL |> concl |> rhs
val t' = convert_case t
val go = mk_eq(t,t')
(* set_goal([],go) *)
val th = prove(go,
  rpt(CASE_TAC >> FULL_SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def]) >>
  fs[])

val dest_eq_PMATCH = save_thm("dest_eq_PMATCH",
  CONV_RULE
    ((REWR_CONV th THENC PMATCH_CATCHALL_INTRO_CONV)
     |> (STRIP_QUANT_CONV o RAND_CONV))
  dest_eq_def)

(* PMATCH_INTRO_CONV fails because it doesn't know about :term *)
val t = is_eq_def |> SPEC_ALL |> concl |> rhs
val t' = convert_case t
val go = mk_eq(t,t')
(* set_goal([],go) *)
val th = prove(go,
  rpt(CASE_TAC >> FULL_SIMP_TAC (rc_ss[]) [PMATCH_EVAL, PMATCH_ROW_COND_def]) >>
  fs[] >>
  rw[EQ_IMP_THM])

val is_eq_PMATCH = save_thm("is_eq_PMATCH",
  CONV_RULE
    ((REWR_CONV th THENC PMATCH_CATCHALL_INTRO_CONV)
     |> (STRIP_QUANT_CONV o RAND_CONV))
  is_eq_def)

--------- *)

val _ = export_theory()

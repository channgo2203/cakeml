open preamble ml_translatorTheory ml_translatorLib ml_pmatchTheory patternMatchesTheory
open astTheory libTheory bigStepTheory semanticPrimitivesTheory holKernelTheory;
open terminationTheory ml_progLib ml_progTheory

val _ = new_theory "ml_monadProg";

val _ = temp_type_abbrev("state",``:'ffi semanticPrimitives$state``);

fun auto_prove proof_name (goal,tac) = let
  val (rest,validation) = tac ([],goal) handle Empty => fail()
  in if length rest = 0 then validation [] else let
  in failwith("auto_prove failed for " ^ proof_name) end end

fun D th = let
  val th = th |> DISCH_ALL |> PURE_REWRITE_RULE [AND_IMP_INTRO]
  in if is_imp (concl th) then th else DISCH T th end

(* a few basics *)

val _ = (use_full_type_names := false);

val _ = register_type ``:'a # 'b``;
val _ = register_type ``:'a list``;
val _ = register_type ``:'a option``;

val _ = ml_prog_update (open_module "Kernel");

(* construct type refinement invariants *)

val _ = register_type ``:type``;

val MEM_type_size = prove(
  ``!ts t. MEM t ts ==> type_size t < type1_size ts``,
  Induct \\ FULL_SIMP_TAC (srw_ss()) [] \\ REPEAT STRIP_TAC \\ RES_TAC
  \\ EVAL_TAC \\ FULL_SIMP_TAC std_ss [] \\ DECIDE_TAC);

val type_ind = store_thm("type_ind",
  ``(!s ts. (!t. MEM t ts ==> P t) ==> P (Tyapp s ts)) /\
    (!v. P (Tyvar v)) ==> !x. P x``,
  REPEAT STRIP_TAC \\ completeInduct_on `type_size x`
  \\ REPEAT STRIP_TAC \\ FULL_SIMP_TAC std_ss [PULL_FORALL]
  \\ Cases_on `x` \\ FULL_SIMP_TAC std_ss []
  \\ Q.PAT_X_ASSUM `!x1 x2. bb` MATCH_MP_TAC
  \\ REPEAT STRIP_TAC \\ Q.PAT_X_ASSUM `!x.bbb` MATCH_MP_TAC
  \\ EVAL_TAC \\ IMP_RES_TAC MEM_type_size \\ DECIDE_TAC);

val TYPE_TYPE_def = fetch "-" "TYPE_TYPE_def"

val LIST_TYPE_NO_CLOSURES = prove(
  ``!xs v.
      (!x v. MEM x xs /\ p x v ==> no_closures v) /\
      LIST_TYPE p xs v ==> no_closures v``,
  Induct \\ FULL_SIMP_TAC std_ss [LIST_TYPE_def]
  \\ REPEAT STRIP_TAC \\ FULL_SIMP_TAC std_ss [no_closures_def,EVERY_DEF,MEM]
  \\ METIS_TAC []);

val LIST_TYPE_11 = prove(
  ``!P ts v1 us v2.
      (!x1.
       MEM x1 ts ==>
        !v1 x2 v2.
          P x1 v1 /\ P x2 v2 ==>
          types_match v1 v2 /\ ((v1 = v2) <=> (x1 = x2))) /\
    LIST_TYPE P ts v1 /\ LIST_TYPE P us v2 ==>
    types_match v1 v2 /\ ((v1 = v2) = (ts = us))``,
  STRIP_TAC \\ Induct \\ Cases_on `us` \\ FULL_SIMP_TAC (srw_ss()) []
  \\ SIMP_TAC (srw_ss()) [LIST_TYPE_def,types_match_def,ctor_same_type_def]
  \\ FULL_SIMP_TAC (srw_ss()) [PULL_EXISTS,types_match_def,ctor_same_type_def]
  \\ METIS_TAC []);

val CHAR_IMP_no_closures = prove(
  ``CHAR x v ==> no_closures v``,
  SIMP_TAC std_ss [CHAR_def,no_closures_def]);

val STRING_IMP_no_closures = prove(
  ``STRING_TYPE x v ==> no_closures v``,
  SIMP_TAC std_ss [STRING_TYPE_def,no_closures_def]);

val EqualityType_thm = prove(
  ``EqualityType abs <=>
      (!x1 v1. abs x1 v1 ==> no_closures v1) /\
      (!x1 v1 x2 v2. abs x1 v1 /\ abs x2 v2 ==> types_match v1 v2 /\
                                                (v1 = v2 <=> x1 = x2))``,
  SIMP_TAC std_ss [EqualityType_def] \\ METIS_TAC []);

val STRING_TYPE_lemma = prove(
  ``EqualityType (STRING_TYPE)``,
  METIS_TAC (eq_lemmas ()));

val EqualityType_TYPE = prove(
  ``EqualityType TYPE_TYPE``,
  SIMP_TAC std_ss [EqualityType_thm] \\ STRIP_TAC THEN1
   (HO_MATCH_MP_TAC type_ind
    \\ FULL_SIMP_TAC std_ss [TYPE_TYPE_def]
    \\ REPEAT STRIP_TAC
    \\ FULL_SIMP_TAC std_ss [no_closures_def,EVERY_DEF]
    \\ IMP_RES_TAC (LIST_TYPE_NO_CLOSURES |> GEN_ALL)
    \\ METIS_TAC [CHAR_IMP_no_closures,STRING_IMP_no_closures])
  \\ HO_MATCH_MP_TAC type_ind \\ reverse STRIP_TAC THEN1
   (REPEAT STRIP_TAC
    \\ Cases_on `x2` \\ FULL_SIMP_TAC (srw_ss()) [TYPE_TYPE_def]
    \\ FULL_SIMP_TAC (srw_ss()) [types_match_def,ctor_same_type_def]
    \\ ASSUME_TAC STRING_TYPE_lemma
    \\ FULL_SIMP_TAC std_ss [EqualityType_def] \\ RES_TAC)
  \\ REPEAT GEN_TAC \\ STRIP_TAC \\ REPEAT GEN_TAC \\ STRIP_TAC
  \\ Cases_on `x2` \\ FULL_SIMP_TAC (srw_ss()) [TYPE_TYPE_def]
  \\ FULL_SIMP_TAC (srw_ss()) [types_match_def,ctor_same_type_def]
  \\ MATCH_MP_TAC (METIS_PROVE [] ``(b1 /\ (x1 = y1)) /\ (b2 /\ (x2 = y2)) ==>
       (b1 /\ b2) /\ ((x1 /\ x2 <=> y1 /\ y2))``)
  \\ STRIP_TAC THEN1
   (ASSUME_TAC STRING_TYPE_lemma
    \\ FULL_SIMP_TAC std_ss [EqualityType_def] \\ RES_TAC
    \\ ASM_SIMP_TAC std_ss [])
  \\ MATCH_MP_TAC LIST_TYPE_11
  \\ Q.EXISTS_TAC `TYPE_TYPE`
  \\ FULL_SIMP_TAC std_ss []
  \\ REPEAT STRIP_TAC \\ RES_TAC)
  |> store_eq_thm;

val _ = register_type ``:term``;
val _ = register_type ``:thm``;
val _ = register_type ``:update``;

val _ = register_exn_type ``:hol_exn``;

val HOL_EXN_TYPE_def = theorem"HOL_EXN_TYPE_def"

(*
  fetch "-" "TYPE_TYPE_def";
  fetch "-" "TERM_TYPE_def";
  fetch "-" "THM_TYPE_def";
*)

(* definition of EvalM *)

val isRefv_def = Define `
  isRefv P x = ?v. (x = Refv v) /\ P v`;

val HOL_STORE_def = Define `
  HOL_STORE s refs <=>
    4 <= LENGTH s /\
    isRefv ((LIST_TYPE (PAIR_TYPE STRING_TYPE NUM))
            refs.the_type_constants) (EL 0 s) /\
    isRefv ((LIST_TYPE (PAIR_TYPE STRING_TYPE TYPE_TYPE))
            refs.the_term_constants) (EL 1 s) /\
    isRefv (LIST_TYPE THM_TYPE refs.the_axioms) (EL 2 s) /\
    isRefv (LIST_TYPE UPDATE_TYPE refs.the_context) (EL 3 s)`;

val EvalM_def = Define `
  EvalM env exp P <=>
    !(s:unit state) refs. HOL_STORE s.refs refs ==>
             ?s2 res refs2. evaluate F env s exp (s2,res) /\
                            P (refs,s) (refs2,s2,res) /\ HOL_STORE s2.refs refs2`;

(* refinement invariant for ``:'a M`` *)

val _ = type_abbrev("M", ``:hol_refs -> 'a hol_result # hol_refs``);

val HOL_MONAD_def = Define `
  HOL_MONAD (a:'a->v->bool) (x:'a M) (state1:hol_refs,s1:unit state)
                                     (state2:hol_refs,s2:unit state,
                                      res: (v,v) result) =
    case (x state1, res) of
      ((HolRes y, st), Rval v) => (st = state2) /\ a y v
    | ((HolErr e, st), Rerr (Rraise v)) => (st = state2) /\
                                              HOL_EXN_TYPE e v
    | _ => F`

(* return *)

val EvalM_return = store_thm("EvalM_return",
  ``Eval env exp (a x) ==>
    EvalM env exp (HOL_MONAD a (ex_return x))``,
  SIMP_TAC std_ss [Eval_def,EvalM_def,HOL_MONAD_def,ex_return_def]
  \\ REPEAT STRIP_TAC \\ Q.LIST_EXISTS_TAC [`s`,`Rval res`,`refs`]
  \\ IMP_RES_TAC (evaluate_empty_state_IMP
                  |> INST_TYPE [``:'ffi``|->``:unit``])
  \\ FULL_SIMP_TAC (srw_ss()) []);

(* bind *)

val EvalM_bind = store_thm("EvalM_bind",
  ``EvalM env e1 (HOL_MONAD b (x:'b M)) /\
    (!x v. b x v ==> EvalM (write name v env) e2 (HOL_MONAD a ((f x):'a M))) ==>
    EvalM env (Let (SOME name) e1 e2) (HOL_MONAD a (ex_bind x f))``,
  SIMP_TAC std_ss [EvalM_def,HOL_MONAD_def,ex_return_def] \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC std_ss [PULL_EXISTS] \\ RES_TAC
  \\ Cases_on `x refs` \\ Cases_on `q`
  \\ Cases_on `res` \\ FULL_SIMP_TAC (srw_ss()) [] THEN1
   (FULL_SIMP_TAC (srw_ss()) [] \\ REPEAT STRIP_TAC
    \\ Q.MATCH_ASSUM_RENAME_TAC `x refs = (HolRes res1,r)`
    \\ Q.MATCH_ASSUM_RENAME_TAC `evaluate F env s e1 (s2,Rval (state1))`
    \\ FULL_SIMP_TAC std_ss [PULL_FORALL]
    \\ Q.PAT_X_ASSUM `!xx.bbb` (MP_TAC o Q.SPECL [`res1`,`state1`,`s2`,`r`])
    \\ FULL_SIMP_TAC std_ss [] \\ STRIP_TAC
    \\ Q.LIST_EXISTS_TAC [`s2'`,`res`,`refs2'`]
    \\ FULL_SIMP_TAC std_ss [] \\ reverse STRIP_TAC
    \\ FULL_SIMP_TAC (srw_ss()) [ex_bind_def]
    \\ ONCE_REWRITE_TAC [evaluate_cases]
    \\ FULL_SIMP_TAC (srw_ss()) [] \\ DISJ1_TAC
    \\ FULL_SIMP_TAC std_ss [opt_bind_def,write_def]
    \\ Q.LIST_EXISTS_TAC [`state1`,`s2`]
    \\ ASM_SIMP_TAC std_ss [])
  THEN1
   (FULL_SIMP_TAC (srw_ss()) [] \\ REPEAT STRIP_TAC
    \\ Q.MATCH_ASSUM_RENAME_TAC `x refs = (HolErr res1,r)`
    \\ Q.MATCH_ASSUM_RENAME_TAC `evaluate F env s e1 (s1,Rerr (state1))`
    \\ FULL_SIMP_TAC std_ss [PULL_FORALL]
    \\ Q.LIST_EXISTS_TAC [`s1`,`Rerr state1`,`refs2`]
    \\ FULL_SIMP_TAC std_ss [] \\ STRIP_TAC
    \\ FULL_SIMP_TAC (srw_ss()) [ex_bind_def]
    \\ ONCE_REWRITE_TAC [evaluate_cases] \\ FULL_SIMP_TAC (srw_ss()) []));

(* function abstraction and application *)

val any_evaluate_closure_def = Define `
  any_evaluate_closure (s1,input) cl (s2,output) =
     ?env exp.
       (do_opapp [cl;input] = SOME (env,exp)) /\
       evaluate F env s1 exp (s2,output)`

val _ = type_abbrev("H",``:'a -> hol_refs # unit state ->
                                 hol_refs # unit state # (v,v) result -> bool``);

val PURE_def = Define `
  PURE a (x:'a) (refs1:hol_refs,s1:unit state) (refs2,s2,res:(v,v) result) =
    ?v:v. (res = Rval v) /\ (refs1 = refs2) /\ (s1 = s2) /\ a x v`;

val ArrowP_def = Define `
  (ArrowP : 'a H -> 'b H -> ('a -> 'b) -> v -> bool) a b f c =
     !x refs1 s1 refs2 s2 (res:(v,v) result).
       a x (refs1,s1) (refs2,s2,res) /\ HOL_STORE s1.refs refs1 ==>
       (refs2 = refs1) /\ (s2 = s1) /\
       ?v s3 res3 refs3.
         (res = Rval v) /\ any_evaluate_closure (s2,v) c (s3,res3) /\
         b (f x) (refs1,s1) (refs3,s3,res3) /\ HOL_STORE s3.refs refs3`;

val ArrowM_def = Define `
  (ArrowM : 'a H -> 'b H -> ('a -> 'b) H) a b = PURE (ArrowP a b)`;

val _ = add_infix("-M->",400,HOLgrammars.RIGHT)
val _ = overload_on ("-M->",``ArrowM``)

val evaluate_list_cases = let
  val lemma = evaluate_cases |> CONJUNCTS |> el 2
  in CONJ (``evaluate_list a5 a6 a7 [] (a9,Rval a10)``
           |> SIMP_CONV (srw_ss()) [Once lemma])
          (``evaluate_list a5 a6 a7 (x::xs) (a9,Rval a10)``
           |> SIMP_CONV (srw_ss()) [Once lemma]) end

val EvalM_ArrowM = store_thm("EvalM_ArrowM",
  ``EvalM env x1 ((a -M-> b) f) ==>
    EvalM env x2 (a x) ==>
    EvalM env (App Opapp [x1;x2]) (b (f x))``,
  SIMP_TAC std_ss [EvalM_def,ArrowM_def,ArrowP_def,PURE_def] \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC std_ss [PULL_EXISTS]
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ Q.PAT_X_ASSUM `!s. bbb` MP_TAC
  \\ Q.PAT_X_ASSUM `!s. bbb` (MP_TAC o Q.SPECL [`s`,`refs`])
  \\ FULL_SIMP_TAC std_ss [] \\ STRIP_TAC \\ STRIP_TAC
  \\ `!x. evaluate F env s x1 x = (x = (s,Rval v))` by
       METIS_TAC [determTheory.big_exp_determ]
  \\ FULL_SIMP_TAC (srw_ss()) [evaluate_list_cases,PULL_EXISTS]
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`s`,`refs`])
  \\ FULL_SIMP_TAC std_ss [] \\ STRIP_TAC
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`x`,`refs`,`s`,`refs2`,`s2`,`res`])
  \\ FULL_SIMP_TAC std_ss [] \\ REPEAT STRIP_TAC \\ SRW_TAC [] []
  \\ `!x. evaluate F env s x2 x <=> (x = (s,Rval v'))` by
       METIS_TAC [determTheory.big_exp_determ]
  \\ FULL_SIMP_TAC (srw_ss()) [] \\ POP_ASSUM (K ALL_TAC)
  \\ Q.LIST_EXISTS_TAC [`s3`,`res3`,`refs3`] \\ FULL_SIMP_TAC std_ss []
  \\ DISJ1_TAC \\ FULL_SIMP_TAC std_ss [any_evaluate_closure_def]);

val EvalM_Fun = store_thm("EvalM_Fun",
  ``(!v x. a x v ==> EvalM (write name v env) body (b (f x))) ==>
    EvalM env (Fun name body) ((PURE a -M-> b) f)``,
  SIMP_TAC std_ss [EvalM_def,ArrowM_def,ArrowP_def,PURE_def,Eq_def]
  \\ REPEAT STRIP_TAC
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ FULL_SIMP_TAC (srw_ss()) [PULL_EXISTS,PULL_FORALL]
  \\ FULL_SIMP_TAC (srw_ss())
       [any_evaluate_closure_def,do_app_def,do_opapp_def,write_def]);

val EvalM_Fun_Eq = store_thm("EvalM_Fun_Eq",
  ``(!v. a x v ==> EvalM (write name v env) body (b (f x))) ==>
    EvalM env (Fun name body) ((PURE (Eq a x) -M-> b) f)``,
  SIMP_TAC std_ss [EvalM_def,ArrowM_def,ArrowP_def,PURE_def,Eq_def]
  \\ REPEAT STRIP_TAC
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ FULL_SIMP_TAC (srw_ss()) [PULL_EXISTS,PULL_FORALL]
  \\ FULL_SIMP_TAC (srw_ss())
       [any_evaluate_closure_def,do_app_def,do_opapp_def,write_def]);

val Eval_IMP_PURE = store_thm("Eval_IMP_PURE",
  ``Eval env exp (P x) ==> EvalM env exp (PURE P x)``,
  SIMP_TAC std_ss [Eval_def,EvalM_def,PURE_def,PULL_EXISTS]
  \\ REPEAT STRIP_TAC \\ Q.EXISTS_TAC `res`
  \\ IMP_RES_TAC (evaluate_empty_state_IMP
                  |> INST_TYPE [``:'ffi``|->``:unit``])
  \\ ASM_SIMP_TAC std_ss []);

val TYPE_TYPE_EXISTS = prove(
  ``?ty v. TYPE_TYPE ty v``,
  Q.EXISTS_TAC `Tyvar (strlit [])`
  \\ fs [fetch "-" "TYPE_TYPE_def", STRING_TYPE_def]);

val TERM_TYPE_EXISTS = prove(
  ``?tm v. TERM_TYPE tm v``,
  STRIP_ASSUME_TAC TYPE_TYPE_EXISTS
  \\ Q.EXISTS_TAC `Var (strlit []) ty`
  \\ fs [fetch "-" "TERM_TYPE_def",STRING_TYPE_def]
  \\ Q.EXISTS_TAC `v` \\ FULL_SIMP_TAC std_ss []);

val HOL_STORE_EXISTS = store_thm("HOL_STORE_EXISTS",
  ``?(s:unit state) refs. HOL_STORE s.refs refs``,
  SIMP_TAC std_ss [HOL_STORE_def]
  \\ Q.EXISTS_TAC `<| refs :=
                   [Refv (Conv (SOME ("nil",TypeId (Short "list"))) []);
                    Refv (Conv (SOME ("nil",TypeId (Short "list"))) []);
                    Refv (Conv (SOME ("nil",TypeId (Short "list"))) []);
                    Refv (Conv (SOME ("nil",TypeId (Short "list"))) [])]|>`
  \\ FULL_SIMP_TAC (srw_ss()) [LENGTH,EL,HD,TL,isRefv_def]
  \\ Q.EXISTS_TAC `<| the_type_constants := [] ;
                      the_term_constants := [] ;
                      the_context        := [] ;
                      the_axioms         := [] |>`
  \\ FULL_SIMP_TAC (srw_ss()) [LIST_TYPE_def]);

val LOOKUP_VAR_EvalM_IMP = store_thm("LOOKUP_VAR_EvalM_IMP",
  ``(!env. LOOKUP_VAR n env v ==> EvalM env (Var (Short n)) (PURE P g)) ==>
    P g v``,
  fs [LOOKUP_VAR_def,lookup_var_def,EvalM_def,PURE_def,AND_IMP_INTRO,
      Once evaluate_cases,PULL_EXISTS,lookup_var_id_def,PULL_FORALL]
  \\ rw [] \\ pop_assum match_mp_tac
  \\ qexists_tac `<|v := [n,v]|>` \\ fs []
  \\ metis_tac [HOL_STORE_EXISTS]);

val EvalM_Fun_PURE_IMP = store_thm("EvalM_Fun_PURE_IMP",
  ``EvalM env (Fun n exp) (PURE P f) ==>
    P f (Closure env n exp)``,
  fs [EvalM_def,PURE_def,PULL_EXISTS,evaluate_Fun]
  \\ rw [] \\ pop_assum match_mp_tac \\ metis_tac [HOL_STORE_EXISTS])

val EvalM_ArrowM_IMP = store_thm("EvalM_ArrowM_IMP",
  ``EvalM env (Var x) ((a -M-> b) f) ==>
    Eval env (Var x) (ArrowP a b f)``,
  SIMP_TAC std_ss [ArrowM_def,EvalM_def,Eval_def,PURE_def,PULL_EXISTS]
  \\ REPEAT STRIP_TAC \\ STRIP_ASSUME_TAC HOL_STORE_EXISTS
  \\ RES_TAC \\ Q.EXISTS_TAC `v` \\ ASM_SIMP_TAC std_ss []
  \\ NTAC 2 (POP_ASSUM MP_TAC) \\ ONCE_REWRITE_TAC [evaluate_cases]
  \\ SIMP_TAC (srw_ss()) []);

val EvalM_PURE_EQ = store_thm("EvalM_PURE_EQ",
  ``EvalM env (Fun n exp) (PURE P x) = Eval env (Fun n exp) (P x)``,
  REPEAT STRIP_TAC \\ EQ_TAC \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC std_ss [Eval_IMP_PURE]
  \\ FULL_SIMP_TAC std_ss [Eval_def,EvalM_def,PURE_def,PULL_EXISTS]
  \\ STRIP_ASSUME_TAC HOL_STORE_EXISTS \\ RES_TAC
  \\ Q.EXISTS_TAC `v` \\ FULL_SIMP_TAC std_ss []
  \\ POP_ASSUM MP_TAC \\ POP_ASSUM MP_TAC
  \\ ONCE_REWRITE_TAC [evaluate_cases]
  \\ SIMP_TAC (srw_ss()) []);

val EvalM_Var_SIMP = store_thm("EvalM_Var_SIMP",
  ``EvalM (write n x env) (Var (Short y)) p =
    if n = y then EvalM (write n x env) (Var (Short y)) p
             else EvalM env (Var (Short y)) p``,
  SIMP_TAC std_ss [EvalM_def] \\ SRW_TAC [] []
  \\ ASM_SIMP_TAC (srw_ss()) [Once evaluate_cases]
  \\ ASM_SIMP_TAC (srw_ss()) [Once evaluate_cases,write_def,lookup_var_id_def]);

val option_CASE_LEMMA2 = prove(
  Pmatch.with_classic_heuristic Term
  `!topt. (case topt of NONE => v | SOME z => v) = v`,
  Cases \\ SRW_TAC [] [] \\ Cases_on `x` \\ SRW_TAC [] []);

val EvalM_Recclosure = store_thm("EvalM_Recclosure",
  ``(!v. a n v ==>
         EvalM (write name v (write_rec [(fname,name,body)] env2))
               body (b (f n))) ==>
    LOOKUP_VAR fname env (Recclosure env2 [(fname,name,body)] fname) ==>
    EvalM env (Var (Short fname)) ((PURE (Eq a n) -M-> b) f)``,
  NTAC 2 STRIP_TAC \\ IMP_RES_TAC LOOKUP_VAR_THM
  \\ POP_ASSUM MP_TAC \\ POP_ASSUM (K ALL_TAC) \\ POP_ASSUM MP_TAC
  \\ FULL_SIMP_TAC std_ss [Eval_def,Arrow_def,EvalM_def,ArrowM_def,PURE_def,
    PULL_EXISTS,ArrowP_def] \\ REPEAT STRIP_TAC
  \\ POP_ASSUM MP_TAC \\ POP_ASSUM MP_TAC \\ ONCE_REWRITE_TAC [evaluate_cases]
  \\ FULL_SIMP_TAC (srw_ss()) [AppReturns_def,Eq_def,do_app_def,do_opapp_def,
       evaluate_closure_def,any_evaluate_closure_def,option_CASE_LEMMA2]
  \\ REPEAT STRIP_TAC \\ FULL_SIMP_TAC (srw_ss()) []
  \\ SIMP_TAC (srw_ss()) [Once find_recfun_def,Eval_def]
  \\ FULL_SIMP_TAC (srw_ss()) [build_rec_env_def,FOLDR,
       write_rec_def,write_def]);

val IND_HELP = store_thm("IND_HELP",
  ``!env cl.
      LOOKUP_VAR x env cl /\
      EvalM env (Var (Short x)) ((b1 -M-> b2) f) ==>
      EvalM (write x cl cl_env) (Var (Short x)) ((b1 -M-> b2) f)``,
  SIMP_TAC std_ss [EvalM_def,Eval_def,ArrowM_def,PURE_def,PULL_EXISTS,LOOKUP_VAR_def]
  \\ ONCE_REWRITE_TAC [evaluate_cases]
  \\ SIMP_TAC (srw_ss()) [option_CASE_LEMMA2]
  \\ REPEAT STRIP_TAC \\ RES_TAC
  \\ FULL_SIMP_TAC (srw_ss()) [lookup_var_id_def,write_def,lookup_var_def]
  \\ POP_ASSUM MP_TAC \\ FULL_SIMP_TAC std_ss []);

val write_rec_one = store_thm("write_rec_one",
  ``write_rec [(x,y,z)] env = write x (Recclosure env [(x,y,z)] x) env``,
  SIMP_TAC std_ss [write_rec_def,write_def,build_rec_env_def,FOLDR]);

(* Eq simps *)

val EvalM_FUN_FORALL = store_thm("EvalM_FUN_FORALL",
  ``(!x. EvalM env exp (PURE (p x) f)) ==>
    EvalM env exp (PURE (FUN_FORALL x. p x) f)``,
  SIMP_TAC std_ss [EvalM_def,Eq_def,PURE_def] \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC std_ss [AppReturns_def,FUN_FORALL,PULL_EXISTS]
  \\ RES_TAC \\ POP_ASSUM (STRIP_ASSUME_TAC o Q.SPEC `ARB`)
  \\ Q.EXISTS_TAC `v` \\ FULL_SIMP_TAC std_ss [] \\ REPEAT STRIP_TAC
  \\ RES_TAC \\ POP_ASSUM MP_TAC
  \\ `!x. evaluate F env s exp x = (x = (s,Rval v))` by
       METIS_TAC [determTheory.big_exp_determ]
  \\ FULL_SIMP_TAC (srw_ss()) []);

val EvalM_FUN_FORALL_EQ = store_thm("EvalM_FUN_FORALL_EQ",
  ``(!x. EvalM env exp (PURE (p x) f)) =
    EvalM env exp (PURE (FUN_FORALL x. p x) f)``,
  REPEAT STRIP_TAC \\ EQ_TAC \\ FULL_SIMP_TAC std_ss [EvalM_FUN_FORALL]
  \\ fs [EvalM_def,PURE_def,PULL_EXISTS,FUN_FORALL] \\ METIS_TAC []);

val M_FUN_FORALL_PUSH1 = prove(
  ``(FUN_FORALL x. ArrowP a (PURE (b x))) = (ArrowP a (PURE (FUN_FORALL x. b x)))``,
  FULL_SIMP_TAC std_ss [ArrowP_def,FUN_EQ_THM,AppReturns_def,FUN_FORALL,
    Eval_def,any_evaluate_closure_def,PURE_def] \\ REPEAT STRIP_TAC \\ reverse EQ_TAC
  THEN1 METIS_TAC [evaluate_11_Rval]
  \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC std_ss [PULL_FORALL] \\ RES_TAC
  \\ POP_ASSUM (fn th => STRIP_ASSUME_TAC (Q.SPEC `ARB` th) THEN ASSUME_TAC th)
  \\ FULL_SIMP_TAC std_ss [] \\ POP_ASSUM MP_TAC
  \\ Q.PAT_X_ASSUM `s2 = s3` ASSUME_TAC \\ FULL_SIMP_TAC (srw_ss()) []
  \\ `!x. evaluate F env s3 exp x = (x = (s3,Rval v))`
       by METIS_TAC [determTheory.big_exp_determ]
  \\ FULL_SIMP_TAC (srw_ss()) [PULL_EXISTS]
  \\ REPEAT STRIP_TAC \\ Q.LIST_EXISTS_TAC [`refs3`,`v`]
  \\ FULL_SIMP_TAC std_ss []) |> GEN_ALL;

val M_FUN_FORALL_PUSH2 = prove(
  ``(FUN_FORALL x. ArrowP ((PURE (a x))) b) =
    (ArrowP (PURE (FUN_EXISTS x. a x)) b)``,
  FULL_SIMP_TAC std_ss [ArrowP_def,FUN_EQ_THM,AppReturns_def,
    FUN_FORALL,FUN_EXISTS,PURE_def] \\ METIS_TAC []) |> GEN_ALL;

val FUN_EXISTS_Eq = prove(
  ``(FUN_EXISTS x. Eq a x) = a``,
  SIMP_TAC std_ss [FUN_EQ_THM,FUN_EXISTS,Eq_def]) |> GEN_ALL;

val M_FUN_QUANT_SIMP = save_thm("M_FUN_QUANT_SIMP",
  LIST_CONJ [FUN_EXISTS_Eq,M_FUN_FORALL_PUSH1,M_FUN_FORALL_PUSH2]);

(* failwith *)

val EvalM_failwith = store_thm("EvalM_failwith",
  ``!x a.
      (lookup_cons "Fail" env = SOME (1,TypeExn (Long "Kernel" "Fail"))) ==>
      Eval env exp1 (STRING_TYPE x) ==>
      EvalM env (Raise (Con (SOME (Short "Fail")) [exp1]))
        (HOL_MONAD a (failwith x))``,
  rw[Eval_def,EvalM_def,HOL_MONAD_def,failwith_def] >>
  rw[Once evaluate_cases] >>
  rw[Once evaluate_cases] >>
  srw_tac[boolSimps.DNF_ss][] >> disj1_tac >>
  rw[Once evaluate_cases,PULL_EXISTS] >>
  rw[Once(CONJUNCT2 evaluate_cases)] >>
  IMP_RES_TAC (evaluate_empty_state_IMP
               |> INST_TYPE [``:'ffi``|->``:unit``]) >>
  rw[do_con_check_def,build_conv_def] >>
  fs [lookup_cons_def] >>
  fs [lookup_alist_mod_env_def] >>
  fs[HOL_EXN_TYPE_def,id_to_n_def] >>
  METIS_TAC[]);

(* clash *)

val EvalM_raise_clash = store_thm("EvalM_raise_clash",
  ``!x a.
      (lookup_cons "Clash" env = SOME (1,TypeExn (Long "Kernel" "Clash"))) ==>
      Eval env exp1 (TERM_TYPE x) ==>
      EvalM env (Raise (Con (SOME (Short "Clash")) [exp1]))
        (HOL_MONAD a (raise_clash x))``,
  rw[Eval_def,EvalM_def,HOL_MONAD_def,raise_clash_def] >>
  rw[Once evaluate_cases] >>
  rw[Once evaluate_cases] >>
  srw_tac[boolSimps.DNF_ss][] >> disj1_tac >>
  rw[Once evaluate_cases,PULL_EXISTS] >>
  rw[Once(CONJUNCT2 evaluate_cases)] >>
  rw[do_con_check_def,build_conv_def] >>
  fs [lookup_cons_def] >>
  fs [lookup_alist_mod_env_def] >>
  fs[HOL_EXN_TYPE_def,id_to_n_def] >>
  METIS_TAC[evaluate_empty_state_IMP]);

(* otherwise *)

val EvalM_otherwise = store_thm("EvalM_otherwise",
  ``!n. EvalM env exp1 (HOL_MONAD a x1) ==>
        (!i. EvalM (write n i env) exp2 (HOL_MONAD a x2)) ==>
        EvalM env (Handle exp1 [(Pvar n,exp2)]) (HOL_MONAD a (x1 otherwise x2))``,
  SIMP_TAC std_ss [EvalM_def] \\ REPEAT STRIP_TAC
  \\ SIMP_TAC (srw_ss()) [Once evaluate_cases]
  \\ Q.PAT_X_ASSUM `!s refs. bb ==> bbb` (MP_TAC o Q.SPECL [`s`,`refs`])
  \\ FULL_SIMP_TAC std_ss [] \\ REPEAT STRIP_TAC
  \\ Cases_on `res` THEN1
   (Q.LIST_EXISTS_TAC [`s2`,`Rval a'`,`refs2`]
    \\ FULL_SIMP_TAC (srw_ss()) []
    \\ FULL_SIMP_TAC std_ss [HOL_MONAD_def]
    \\ Cases_on `x1 refs` \\ FULL_SIMP_TAC (srw_ss()) []
    \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) [otherwise_def])
  \\ Q.PAT_X_ASSUM `HOL_MONAD xx yy t1 t2` MP_TAC
  \\ SIMP_TAC std_ss [Once HOL_MONAD_def] \\ STRIP_TAC
  \\ Cases_on `x1 refs` \\ FULL_SIMP_TAC (srw_ss()) []
  \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) [otherwise_def]
  \\ Cases_on `e` \\ FULL_SIMP_TAC (srw_ss()) [otherwise_def]
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`a'`,`s2`,`refs2`])
  \\ FULL_SIMP_TAC std_ss [] \\ STRIP_TAC
  \\ Q.LIST_EXISTS_TAC [`s2'`,`res`,`refs2'`]
  \\ FULL_SIMP_TAC (srw_ss()) [HOL_MONAD_def]
  \\ DISJ2_TAC \\ DISJ1_TAC
  \\ Q.LIST_EXISTS_TAC [`s2`,`a'`] \\ ASM_SIMP_TAC std_ss []
  \\ SIMP_TAC (srw_ss()) [Once evaluate_cases,pat_bindings_def,pmatch_def]
  \\ FULL_SIMP_TAC (srw_ss()) [write_def]);

(* handle_clash *)

val EvalM_handle_clash = store_thm("EvalM_handle_clash",
  ``!n. (lookup_cons "Clash" env = SOME (1,TypeExn (Long "Kernel" "Clash"))) ==>
        EvalM env exp1 (HOL_MONAD a x1) ==>
        (!t v.
          TERM_TYPE t v ==>
          EvalM (write n v env) exp2 (HOL_MONAD a (x2 t))) ==>
        EvalM env (Handle exp1 [(Pcon (SOME (Short "Clash")) [Pvar n],exp2)])
          (HOL_MONAD a (handle_clash x1 x2))``,
  SIMP_TAC std_ss [EvalM_def] \\ REPEAT STRIP_TAC
  \\ SIMP_TAC (srw_ss()) [Once evaluate_cases]
  \\ Q.PAT_X_ASSUM `!s refs. HOL_STORE s.refs refs ==> bbb` (MP_TAC o Q.SPECL [`s`,`refs`])
  \\ FULL_SIMP_TAC std_ss [] \\ REPEAT STRIP_TAC
  \\ Cases_on `res` THEN1
   (Q.LIST_EXISTS_TAC [`s2`,`Rval a'`,`refs2`]
    \\ FULL_SIMP_TAC (srw_ss()) []
    \\ FULL_SIMP_TAC std_ss [HOL_MONAD_def]
    \\ Cases_on `x1 refs` \\ FULL_SIMP_TAC (srw_ss()) []
    \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) [handle_clash_def])
  \\ Q.PAT_X_ASSUM `HOL_MONAD xx yy t1 t2` MP_TAC
  \\ SIMP_TAC std_ss [Once HOL_MONAD_def] \\ STRIP_TAC
  \\ Cases_on `x1 refs` \\ FULL_SIMP_TAC (srw_ss()) []
  \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) [handle_clash_def]
  \\ Cases_on `e` \\ FULL_SIMP_TAC (srw_ss()) [handle_clash_def]
  \\ Cases_on `h` >> fs[HOL_EXN_TYPE_def] >>
  srw_tac[boolSimps.DNF_ss][] >> disj2_tac >> disj1_tac >>
  simp[Once (CONJUNCT2 evaluate_cases),PULL_EXISTS,pat_bindings_def] >>
  first_assum(match_exists_tac o concl) >>
  simp[pmatch_def] >> fs[lookup_cons_def] >>
  fs[same_tid_def,id_to_n_def,same_ctor_def] >- (
    simp[Once evaluate_cases,HOL_MONAD_def,HOL_EXN_TYPE_def] ) >>
  res_tac >> fs[write_def] >>
  first_assum(match_exists_tac o concl) >>
  rw[] >>
  fs[HOL_MONAD_def] >>
  Cases_on`x2 t r`>>fs[]>>
  Cases_on`q`>>fs[]>>
  Cases_on`res`>>fs[]>>
  Cases_on`e`>>fs[])

(* if *)

val EvalM_If = store_thm("EvalM_If",
  ``(a1 ==> Eval env x1 (BOOL b1)) /\
    (a2 ==> EvalM env x2 (a b2)) /\
    (a3 ==> EvalM env x3 (a b3)) ==>
    (a1 /\ (CONTAINER b1 ==> a2) /\ (~CONTAINER b1 ==> a3) ==>
     EvalM env (If x1 x2 x3) (a (if b1 then b2 else b3)))``,
  SIMP_TAC std_ss [EvalM_def,NUM_def,BOOL_def] \\ SIMP_TAC std_ss [CONTAINER_def]
  \\ REPEAT STRIP_TAC \\ FULL_SIMP_TAC std_ss []
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ Cases_on `b1` \\ FULL_SIMP_TAC std_ss [] \\ RES_TAC
  THEN1
   (Q.LIST_EXISTS_TAC [`s2`,`res`,`refs2`] \\ ASM_SIMP_TAC std_ss []
    \\ DISJ1_TAC
    \\ Q.EXISTS_TAC `Boolv T` \\ ASM_SIMP_TAC (srw_ss()) [do_if_def]
    \\ Q.EXISTS_TAC `s` \\ FULL_SIMP_TAC std_ss [Eval_def]
    \\ IMP_RES_TAC (evaluate_empty_state_IMP
                    |> INST_TYPE [``:'ffi``|->``:unit``])
    \\ FULL_SIMP_TAC std_ss [])
  THEN1
   (Q.LIST_EXISTS_TAC [`s2`,`res`,`refs2`] \\ ASM_SIMP_TAC std_ss []
    \\ DISJ1_TAC
    \\ Q.EXISTS_TAC `Boolv F` \\ ASM_SIMP_TAC (srw_ss()) [do_if_def,Boolv_11]
    \\ Q.EXISTS_TAC `s` \\ FULL_SIMP_TAC std_ss [Eval_def]
    \\ IMP_RES_TAC (evaluate_empty_state_IMP
                    |> INST_TYPE [``:'ffi``|->``:unit``])
    \\ FULL_SIMP_TAC std_ss []));

val Eval_Var_SIMP2 = store_thm("Eval_Var_SIMP2",
  ``Eval (write x i env) (Var (Short y)) p =
      if x = y then p i else Eval env (Var (Short y)) p``,
  SIMP_TAC (srw_ss()) [Eval_def,Once evaluate_cases] \\ SRW_TAC [] []
  \\ ASM_SIMP_TAC (srw_ss()) [Eval_def,Once evaluate_cases]
  \\ ASM_SIMP_TAC (srw_ss()) [Eval_def,
       Once evaluate_cases,lookup_var_id_def,write_def]);

val EvalM_Let = store_thm("EvalM_Let",
  ``Eval env exp (a res) /\
    (!v. a res v ==> EvalM (write name v env) body (b (f res))) ==>
    EvalM env (Let (SOME name) exp body) (b (LET f res))``,
  SIMP_TAC std_ss [Eval_def,Arrow_def,EvalM_def] \\ REPEAT STRIP_TAC
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ RES_TAC \\ Q.LIST_EXISTS_TAC [`s2`,`res''`,`refs2`]
  \\ FULL_SIMP_TAC std_ss [LET_DEF] \\ DISJ1_TAC
  \\ FULL_SIMP_TAC (srw_ss()) []
  \\ Q.LIST_EXISTS_TAC [`res'`,`s`]
  \\ IMP_RES_TAC (evaluate_empty_state_IMP
                  |> INST_TYPE [``:'ffi``|->``:unit``])
  \\ FULL_SIMP_TAC std_ss [opt_bind_def,write_def]);

(* PMATCH *)

val EvalM_PMATCH_NIL = store_thm("EvalM_PMATCH_NIL",
  ``!b x xv a.
      Eval env x (a xv) ==>
      CONTAINER F ==>
      EvalM env (Mat x []) (b (PMATCH xv []))``,
  rw[CONTAINER_def]);

val pmatch_ignore_empty_store = prove(
  ``(pmatch cenv empty_store p r eenv = Match x) ==>
    (pmatch cenv s p r eenv = Match x)``,
  REPEAT STRIP_TAC
  \\ IMP_RES_TAC pmatch_empty_store
  \\ fs []);

val pmatch_ignore_empty_store_No_match = prove(
  ``(pmatch cenv empty_store p r eenv = No_match) ==>
    (pmatch cenv s p r eenv = No_match)``,
  REPEAT STRIP_TAC
  \\ IMP_RES_TAC pmatch_empty_store
  \\ fs []);

val EvalM_PMATCH = store_thm("EvalM_PMATCH",
  ``!b a x xv.
      ALL_DISTINCT (pat_bindings p []) ⇒
      (∀v1 v2. pat v1 = pat v2 ⇒ v1 = v2) ⇒
      Eval env x (a xv) ⇒
      (p1 xv ⇒ EvalM env (Mat x ys) (b (PMATCH xv yrs))) ⇒
      EvalPatRel env a p pat ⇒
      (∀env2 vars.
        EvalPatBind env a p pat vars env2 ∧ p2 vars ⇒
        EvalM env2 e (b (res vars))) ⇒
      (∀vars. PMATCH_ROW_COND pat (K T) xv vars ⇒ p2 vars) ∧
      ((∀vars. ¬PMATCH_ROW_COND pat (K T) xv vars) ⇒ p1 xv) ⇒
      EvalM env (Mat x ((p,e)::ys))
        (b (PMATCH xv ((PMATCH_ROW pat (K T) res)::yrs)))``,
  rw[Eval_def,EvalM_def] >>
  rw[Once evaluate_cases,PULL_EXISTS] >> fs[] >>
  `!result. evaluate F env s x result <=> (result = (s,Rval res'))` by
      METIS_TAC [determTheory.big_exp_determ,evaluate_empty_state_IMP] >>
  rw[Once evaluate_cases,PULL_EXISTS] >>
  Cases_on`∃vars. PMATCH_ROW_COND pat (K T) xv vars` >> fs[] >- (
    imp_res_tac pmatch_PMATCH_ROW_COND_Match >>
    ntac 3 (pop_assum kall_tac) >>
    fs[EvalPatRel_def] >>
    first_x_assum(qspec_then`vars`mp_tac)>>simp[] >>
    qpat_x_assum`p1 xv ⇒ X`kall_tac >>
    fs[EvalPatBind_def,PMATCH_ROW_COND_def,PULL_EXISTS] >>
    first_x_assum(qspec_then`vars`mp_tac)>>simp[] >> strip_tac >>
    first_x_assum(fn th => first_assum(strip_assume_tac o MATCH_MP th)) >>
    srw_tac[boolSimps.DNF_ss][] >> disj1_tac >>
    imp_res_tac Pmatch_imp_pmatch >>
    imp_res_tac Pmatch_SOME_const >>
    fs[pmatch_def] >>
    qpat_x_assum`X = Match Y` mp_tac >> BasicProvers.CASE_TAC >>
    fs[GSYM AND_IMP_INTRO] >>
    first_x_assum(fn th => first_assum(strip_assume_tac o MATCH_MP th)) >>
    rfs[] >>
    `(∃vars'. pat vars' = pat vars) = T` by metis_tac[] >>
    fs[] >> rfs[] >>
    simp[PMATCH_def,PMATCH_ROW_def,PMATCH_ROW_COND_def] >>
    `(some x. pat x = pat vars) = SOME vars` by (
      simp[optionTheory.some_def] >>
      METIS_TAC[] ) >>
    imp_res_tac pmatch_ignore_empty_store >>
    simp[] >> fs[] >> rw[] >>
    `env with v := env2.v = env2` by simp[environment_component_equality] >>
    fs[pmatch_def]) >>
  FIRST_X_ASSUM (MP_TAC o Q.SPECL [`s:unit state`,`refs`]) >> fs [] >>
  REPEAT STRIP_TAC >>
  qpat_x_assum`evaluate F X Y (Mat A B) R`mp_tac >>
  simp[Once evaluate_cases] >> strip_tac >>
  imp_res_tac (determTheory.big_exp_determ) >> fs[] >> rw[] >>
  `!reslut. evaluate_match F env s res' ys
         (Conv (SOME ("Bind",TypeExn (Short "Bind"))) []) result <=>
            (result = (s2,res''))` by
               METIS_TAC [determTheory.big_exp_determ] >>
  fs [] >> srw_tac[boolSimps.DNF_ss][] >> disj2_tac >> disj1_tac >>
  simp[PMATCH_def,PMATCH_ROW_def] >>
  imp_res_tac pmatch_PMATCH_ROW_COND_No_match >>
  imp_res_tac Pmatch_imp_pmatch >>
  fs[pmatch_def] >>
  pop_assum mp_tac >> BasicProvers.CASE_TAC >>
  imp_res_tac pmatch_ignore_empty_store_No_match >> fs [] >- METIS_TAC[] >>
  fs[EvalPatRel_def] >>
  first_x_assum(fn th => first_x_assum(mp_tac o MATCH_MP th)) >>
  simp[Once evaluate_cases] >>
  `empty_state.refs = empty_store` by EVAL_TAC >>
  rw[]);

(* ref 0 *)

val init_type_constants_def = Define `
  init_type_constants = [(strlit"bool",0); (strlit"fun",2:num)]`

val init_type_constants_v = translate init_type_constants_def

val the_type_constants_def = Define `
    the_type_constants = Loc 0`;

(* for debugging:
val s = ref ml_progLib.init_state
val _ = ml_prog_update (fn k => (s := k; k))
val k = !s
*)

val _ = ml_prog_update (fn k => let
  val lemma = prove(
    ``evaluate F ^(get_env k) ^(get_state k)
        (App Opref [Var (Short "init_type_constants")])
        (^(get_state k) with refs := [Refv init_type_constants_v],
         Rval (the_type_constants))``,
    ntac 5 (fs [Once evaluate_cases,PULL_EXISTS,do_app_def,store_alloc_def,
        EVAL ``lookup_var_id (Short "init_type_constants") ^(get_env k)``])
    \\ EVAL_TAC \\ fs [])
  in add_Dlet lemma "the_type_constants" [the_type_constants_def] k end)

(* ref 1 *)

val init_term_constants_def = Define `
  init_term_constants = [(strlit"=",
    Tyapp (strlit"fun")
      [Tyvar (strlit"A");
       Tyapp (strlit"fun")
         [Tyvar (strlit"A");
          Tyapp (strlit"bool") []]])]`

val init_term_constants_v = translate init_term_constants_def

val the_term_constants_def = Define `
    the_term_constants = Loc 1`;

(* for debugging:
val s = ref ml_progLib.init_state
val _ = ml_prog_update (fn k => (s := k; k))
val k = !s
*)

val _ = ml_prog_update (fn k => let
  val lemma = prove(
    ``evaluate F ^(get_env k) ^(get_state k)
        (App Opref [Var (Short "init_term_constants")])
        (^(get_state k) with refs := [Refv init_type_constants_v;
                                      Refv init_term_constants_v],
         Rval (the_term_constants))``,
    ntac 5 (fs [Once evaluate_cases,PULL_EXISTS,do_app_def,store_alloc_def,
        EVAL ``lookup_var_id (Short "init_term_constants") ^(get_env k)``])
    \\ EVAL_TAC \\ fs [])
  in add_Dlet lemma "the_term_constants" [the_term_constants_def] k end)

(* ref 2 *)

val init_axioms_def = Define `
  init_axioms = []:thm list`

val init_axioms_v = translate init_axioms_def

val the_axioms_def = Define `
    the_axioms = Loc 2`;

(* for debugging:
val s = ref ml_progLib.init_state
val _ = ml_prog_update (fn k => (s := k; k))
val k = !s
*)

val _ = ml_prog_update (fn k => let
  val lemma = prove(
    ``evaluate F ^(get_env k) ^(get_state k)
        (App Opref [Var (Short "init_axioms")])
        (^(get_state k) with refs := [Refv init_type_constants_v;
                                      Refv init_term_constants_v;
                                      Refv init_axioms_v],
         Rval (the_axioms))``,
    ntac 5 (fs [Once evaluate_cases,PULL_EXISTS,do_app_def,store_alloc_def,
        EVAL ``lookup_var_id (Short "init_axioms") ^(get_env k)``])
    \\ EVAL_TAC \\ fs [])
  in add_Dlet lemma "the_axioms" [the_axioms_def] k end)

(* ref 3 *)

val init_context_def = Define `
  init_context = ^(rhs(concl(holSyntaxTheory.init_ctxt_def)))`

val init_context_v = translate init_context_def

val the_context_def = Define `
    the_context = Loc 3`;

(* for debugging:
val s = ref ml_progLib.init_state
val _ = ml_prog_update (fn k => (s := k; k))
val k = !s
*)

val _ = ml_prog_update (fn k => let
  val lemma = prove(
    ``evaluate F ^(get_env k) ^(get_state k)
        (App Opref [Var (Short "init_context")])
        (^(get_state k) with refs := [Refv init_type_constants_v;
                                      Refv init_term_constants_v;
                                      Refv init_axioms_v;
                                      Refv init_context_v],
         Rval (the_context))``,
    ntac 5 (fs [Once evaluate_cases,PULL_EXISTS,do_app_def,store_alloc_def,
        EVAL ``lookup_var_id (Short "init_context") ^(get_env k)``])
    \\ EVAL_TAC \\ fs [])
  in add_Dlet lemma "the_context" [the_context_def] k end)

(* read and update refs *)

fun read_tac n =
  SIMP_TAC std_ss [Eval_def]
  \\ ONCE_REWRITE_TAC [evaluate_cases]
  \\ SIMP_TAC (srw_ss()) [option_CASE_LEMMA2]
  \\ REPEAT STRIP_TAC \\ POP_ASSUM MP_TAC
  \\ SIMP_TAC std_ss [EvalM_def]
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ fs [the_type_constants_def,
       the_term_constants_def,the_axioms_def,the_context_def,
       PULL_EXISTS,evaluate_list_cases,do_app_def,
       store_lookup_def,option_CASE_LEMMA2]
  \\ REPEAT STRIP_TAC \\ FULL_SIMP_TAC std_ss [HOL_STORE_def]
  \\ `0 < LENGTH s.refs` by DECIDE_TAC
  \\ `1 < LENGTH s.refs` by DECIDE_TAC
  \\ `2 < LENGTH s.refs` by DECIDE_TAC
  \\ `3 < LENGTH s.refs` by DECIDE_TAC
  \\ FULL_SIMP_TAC std_ss []
  \\ Q.LIST_EXISTS_TAC [`s`,`Rval (case EL ^n s.refs of Refv v => v)`,`refs`]
  \\ FULL_SIMP_TAC std_ss []
  \\ FULL_SIMP_TAC (srw_ss()) [HOL_MONAD_def,get_the_type_constants_def,
        get_the_term_constants_def,get_the_axioms_def,
        get_the_context_def,EL,isRefv_def]
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ fs []
  \\ fs[state_component_equality];

val get_type_constants_thm = store_thm("get_the_type_constants_thm",
  ``lookup_var_id (Short "the_type_constants") env = SOME the_type_constants ==>
    EvalM env (App Opderef [Var (Short "the_type_constants")])
      (HOL_MONAD (LIST_TYPE (PAIR_TYPE STRING_TYPE NUM))
                 get_the_type_constants)``,
  read_tac ``0:num``);

val get_term_constants_thm = store_thm("get_the_term_constants_thm",
  ``lookup_var_id (Short "the_term_constants") env = SOME the_term_constants ==>
    EvalM env (App Opderef [Var (Short "the_term_constants")])
      (HOL_MONAD (LIST_TYPE (PAIR_TYPE STRING_TYPE TYPE_TYPE))
                 get_the_term_constants)``,
  read_tac ``1:num``);

val get_the_axioms_thm = store_thm("get_the_axioms_thm",
  ``lookup_var_id (Short "the_axioms") env = SOME the_axioms ==>
    EvalM env (App Opderef [Var (Short "the_axioms")])
      (HOL_MONAD (LIST_TYPE THM_TYPE) get_the_axioms)``,
  read_tac ``2:num``);

val get_the_context_thm = store_thm("get_the_context_thm",
  ``lookup_var_id (Short "the_context") env = SOME the_context ==>
    EvalM env (App Opderef [Var (Short "the_context")])
      (HOL_MONAD (LIST_TYPE UPDATE_TYPE) get_the_context)``,
  read_tac ``3:num``);

fun update_tac n r =
  SIMP_TAC (srw_ss()) [option_CASE_LEMMA2]
  \\ STRIP_TAC \\ POP_ASSUM MP_TAC
  \\ SIMP_TAC std_ss [EvalM_def]
  \\ ONCE_REWRITE_TAC [evaluate_cases] \\ SIMP_TAC (srw_ss()) []
  \\ SIMP_TAC (srw_ss()) [Once evaluate_cases]
  \\ SIMP_TAC std_ss [Eval_def] \\ REPEAT STRIP_TAC
  \\ fs [evaluate_list_cases,PULL_EXISTS]
  \\ `evaluate F env s exp (s,Rval res)` by
        METIS_TAC [evaluate_empty_state_IMP]
  \\ `!x. evaluate F env s exp x = (x = (s,Rval res))` by
        METIS_TAC [determTheory.big_exp_determ]
  \\ fs [] \\ SIMP_TAC (srw_ss()) [Once do_app_def]
  \\ FULL_SIMP_TAC std_ss [option_CASE_LEMMA2,PULL_EXISTS]
  \\ FULL_SIMP_TAC std_ss [the_type_constants_def,the_axioms_def,
       the_term_constants_def,the_context_def]
  \\ `0 < LENGTH s.refs` by FULL_SIMP_TAC(srw_ss()++ARITH_ss)[HOL_STORE_def]
  \\ `1 < LENGTH s.refs` by FULL_SIMP_TAC(srw_ss()++ARITH_ss)[HOL_STORE_def]
  \\ `2 < LENGTH s.refs` by FULL_SIMP_TAC(srw_ss()++ARITH_ss)[HOL_STORE_def]
  \\ `3 < LENGTH s.refs` by FULL_SIMP_TAC(srw_ss()++ARITH_ss)[HOL_STORE_def]
  \\ ASM_SIMP_TAC (srw_ss()) [store_assign_def]
  \\ EXISTS_TAC``(s:unit state) with refs := LUPDATE (Refv res) ^n s.refs``
  \\ Q.LIST_EXISTS_TAC [`Rval (Conv NONE [])`,r]
  \\ fs []
  \\ SIMP_TAC (srw_ss()) [Once evaluate_cases]
  \\ fs [store_v_same_type_def]
  \\ FULL_SIMP_TAC std_ss [HOL_STORE_def,EL_LUPDATE]
  \\ fs [HOL_STORE_def,EL_LUPDATE,isRefv_def]
  \\ EVAL_TAC
  \\ simp[state_component_equality];

val set_the_type_constants_thm = store_thm("set_the_type_constants_thm",
  ``lookup_var_id (Short "the_type_constants") env = SOME the_type_constants ==>
    Eval env exp (LIST_TYPE (PAIR_TYPE STRING_TYPE NUM) x) ==>
    EvalM env (App Opassign [Var (Short "the_type_constants"); exp])
      ((HOL_MONAD UNIT_TYPE) (set_the_type_constants x))``,
  update_tac ``0n`` `refs with the_type_constants := x`);

val set_the_term_constants_thm = store_thm("set_the_term_constants_thm",
  ``lookup_var_id (Short "the_term_constants") env = SOME the_term_constants ==>
    Eval env exp (LIST_TYPE (PAIR_TYPE STRING_TYPE TYPE_TYPE) x) ==>
    EvalM env (App Opassign [Var (Short "the_term_constants"); exp])
      ((HOL_MONAD UNIT_TYPE) (set_the_term_constants x))``,
  update_tac ``1n`` `refs with the_term_constants := x`);

val set_the_axioms_thm = store_thm("set_the_axioms_thm",
  ``lookup_var_id (Short "the_axioms") env = SOME the_axioms ==>
    Eval env exp (LIST_TYPE THM_TYPE x) ==>
    EvalM env (App Opassign [Var (Short "the_axioms"); exp])
      ((HOL_MONAD UNIT_TYPE) (set_the_axioms x))``,
  update_tac ``2n`` `refs with the_axioms := x`);

val set_the_context_thm = store_thm("set_the_context_thm",
  ``lookup_var_id (Short "the_context") env = SOME the_context ==>
    Eval env exp (LIST_TYPE UPDATE_TYPE x) ==>
    EvalM env (App Opassign [Var (Short "the_context"); exp])
      ((HOL_MONAD UNIT_TYPE) (set_the_context x))``,
  update_tac ``3n`` `refs with the_context := x`);

val _ = (print_asts := true);

val _ = export_theory();

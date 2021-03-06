open preamble
     closLangTheory closSemTheory closPropsTheory
     clos_relationTheory clos_relationPropsTheory
     clos_removeTheory

val _ = new_theory"clos_removeProof";

val _ = Parse.bring_to_front_overload"Let"{Name="Let",Thy="closLang"};

(* TODO: move *)
val FOLDL_acc = Q.prove(
  `∀l f m l0.
     FOLDL (λ(n,a) e. (n + 1n, f n e::a)) (m,l0) l =
       let (nr0, lr0) = FOLDL (λ(n,a) e. (n + 1, f (n + m) e::a)) (0,[]) l
       in (nr0 + m, lr0 ++ l0)`,
  Induct >- simp[] >> simp_tac (srw_ss()) [] >>
  pop_assum (fn th => simp[SimpLHS, Once th] >> simp[SimpRHS, Once th]) >>
  simp[UNCURRY]);

val FPAIR = Q.prove(
  `(λ(a,b). (f a, g b)) = f ## g`,
  simp[FUN_EQ_THM, FORALL_PROD]);

val code_locs_MAPi = Q.store_thm(
  "code_locs_MAPi",
  `∀f. code_locs (MAPi f xs) = FLAT (MAPi (λn x. code_locs [f n x]) xs)`,
  Induct_on `xs` >> simp[code_locs_def] >>
  simp[Once closPropsTheory.code_locs_cons, SimpLHS] >>
  simp[combinTheory.o_DEF]);

val code_loc'_def = Define`
  code_loc' x = code_locs [x]
`;

val code_loc'_THM = save_thm(
  "code_loc'_THM[simp]",
  CONJ (code_locs_def |> SIMP_RULE (srw_ss()) [GSYM code_loc'_def, LET_THM])
       (code_locs_cons |> REWRITE_RULE [GSYM code_loc'_def]))

val code_locs_FLAT_MAP = Q.store_thm(
  "code_locs_FLAT_MAP",
  `code_locs xs = FLAT (MAP code_loc' xs)`,
  Induct_on `xs` >> simp[]);

val code_locs_MEM_SUBSET = Q.store_thm(
  "code_locs_MEM_SUBSET",
  `MEM x xs ⇒ set (code_loc' x) ⊆ set (code_locs xs)`,
  simp[SUBSET_DEF] >> Induct_on `xs` >> dsimp[] >> rpt strip_tac >>
  simp[Once code_locs_cons]);

val res_rel_trans = Q.store_thm(
  "res_rel_trans",
  `res_rel w (evaluate t1) (evaluate t2) ∧ res_rel w (evaluate t2) (evaluate t3) ⇒
   res_rel w (evaluate t1) (evaluate t3)`,
  simp[SimpL ``$/\``, SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
  simp[res_rel_rw] >> rpt var_eq_tac >>
  qpat_x_assum `res_rel _ _ (evaluate t3)` mp_tac >>
  simp[res_rel_cases] >> dsimp[res_rel_rw] >>
  metis_tac [val_rel_trans, LIST_REL_trans, evaluate_timeout_clocks0]);

(* -- *)

val remove_fv = Q.store_thm("remove_fv",
  `∀xs cs l. remove xs = (cs, l) ⇒ ∀n. fv n cs ⇔ has_var n l`,
  ho_match_mp_tac remove_ind >> simp[remove_def, fv_def, fv1_thm, UNCURRY] >>
  rpt strip_tac
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      rename1 `FST (remove(e'::es))` >> Cases_on `remove(e'::es)` >> full_simp_tac(srw_ss())[])
  >- (rename1 `FST (remove[E1])` >> Cases_on `remove [E1]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> full_simp_tac(srw_ss())[] >>
      rename1 `FST (remove[E2])` >> Cases_on `remove[E2]` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
      imp_res_tac remove_SING >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
      rename1 `FST (remove[E3])` >> Cases_on `remove[E3]` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
      imp_res_tac remove_SING >> full_simp_tac(srw_ss())[])
  >- (rename1 `FST (remove[E1])` >> Cases_on `remove[E1]` >> full_simp_tac(srw_ss())[] >>
      simp[db_varsTheory.FOLDR_mk_Union_UNZIP, FPAIR, FST_UNZIP_MAPi, combinTheory.o_ABS_R,
           SND_UNZIP_MAPi] >>
      simp_tac (srw_ss() ++ COND_elim_ss)[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> dsimp[fv_MAPi, EXISTS_MEM, MEM_MAPi] >>
      eq_tac >> fs[] >> dsimp[] >> qx_gen_tac `i` >>
      rename1 `i < LENGTH xs` >> Cases_on `i < LENGTH xs` >> simp[] >>
      `MEM (EL i xs) xs` by metis_tac[MEM_EL] >> srw_tac[][const_0_def, fv_def, fv1_thm] >>
      Cases_on `remove [EL i xs]` >> full_simp_tac(srw_ss())[] >> imp_res_tac remove_SING >> srw_tac[][] >>
      fs[] >> metis_tac[FST,SND,HD,fv1_intro])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> fs[])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> fs[])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> rename1 `FST (remove xs)` >>
      Cases_on `remove xs` >> full_simp_tac(srw_ss())[])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> fs[])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove[e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >>
      rename1 `no_overlap (LENGTH fns) e'frees` >>
      Cases_on `no_overlap (LENGTH fns) e'frees` >> full_simp_tac(srw_ss())[] >> srw_tac[][]
      >- (simp[fv_def, fv1_thm, LENGTH_REPLICATE, const_0_def]) >>
      simp[fv_def, fv1_thm, MAP_MAP_o, pairTheory.o_UNCURRY_R, combinTheory.o_ABS_R] >>
      dsimp[EXISTS_MEM, MEM_MAP, EXISTS_PROD] >>
      rename1 `has_var (n + LENGTH fns)` >>
      Cases_on `has_var (n + LENGTH fns) e'frees` >> simp[] >>
      eq_tac >> dsimp[] >> qx_genl_tac [`m`, `fb`] >> strip_tac >>
      first_x_assum (qspecl_then [`m`, `fb`] mp_tac) >> simp[] >>
      Cases_on `remove [fb]` >> simp[] >> imp_res_tac remove_SING >> srw_tac[][] >>
      full_simp_tac(srw_ss())[] >> metis_tac[SND,FST,HD])
  >- (rename1 `FST (remove[e])` >> Cases_on `remove [e]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >>
      rename1 `FST (remove[e2])` >> Cases_on `remove [e2]` >> full_simp_tac(srw_ss())[] >>
      imp_res_tac remove_SING >> srw_tac[][] >> fs[])
)

val mustkeep_def = Define`
  mustkeep n e vset ⇔ has_var n vset ∨ ¬pure e
`;
val rm1_def = Define`
  rm1 vset n i e = if mustkeep (n + i) e vset then HD (FST (remove [e]))
                 else const_0
`;

val rm1_o_SUC = Q.prove(
  `rm1 keeps n o SUC = rm1 keeps (n + 1)`,
  simp[FUN_EQ_THM, ADD1, rm1_def]);

val keepval_rel_def = Define`
  keepval_rel tyit c w kis i v1 v2 =
    if i ∈ kis then val_rel tyit c w v1 v2
    else v2 = Number 0
`;

val keepval_rel_o_SUC = Q.store_thm(
  "keepval_rel_o_SUC",
  `keepval_rel tyit c w kis o SUC =
      keepval_rel tyit c w (kis o SUC)`,
  simp[keepval_rel_def, FUN_EQ_THM, SPECIFICATION]);

val ELplus1 = Q.prove(
  `EL (n + 1) l = EL n (TL l)`,
  simp[GSYM ADD1, EL]);

val evaluate_MAPrm1 = Q.prove(
  `(∀e i es' vs. MEM e es ∧ mustkeep i e keeps ∧ remove [e] = (es', vs) ⇒
                 exp_rel (:'ffi) w [e] es') ∧
   LIST_REL (val_rel (:'ffi) i w) env1 env2 ∧
   state_rel i w (s1:'ffi closSem$state) s2 ∧ j ≤ i ⇒
     case evaluate (es, env1, s1 with clock := j) of
     | (Rval vs, s) =>
          ∃vs' s'.
            evaluate (MAPi (rm1 keeps b) es, env2, s2 with clock := j) =
              (Rval vs', s') ∧
            state_rel s.clock w s s' ∧ s.clock = s'.clock ∧
            LIST_RELi (keepval_rel (:'ffi) s.clock w
                         { i | mustkeep (b + i) (EL i es) keeps })
                      vs
                      vs'
     | (Rerr e, s) =>
          res_rel w
            (Rerr e, s)
            (evaluate (MAPi (rm1 keeps b) es, env2, s2 with clock := j))`,
  map_every qid_spec_tac [`env2`, `env1`, `b`, `w`, `i`, `j`, `s2`, `s1`] >>
  Induct_on `es` >> simp[evaluate_def, LIST_RELi_thm]
  >- metis_tac[val_rel_mono] >>
  rpt gen_tac >> rename1 `evaluate(e::es,_,_)` >>
  ONCE_REWRITE_TAC [evaluate_CONS] >> dsimp[] >> strip_tac >> full_simp_tac(srw_ss())[] >>
  Cases_on `evaluate ([e], env1, s1 with clock := j)` >> simp[] >>
  rename1 `evaluate([e], env1, _) = (result, s1')` >>
  reverse (Cases_on `result`) >> simp[]
  >- (rename1 `evaluate _ = (Rerr error, s1')` >>
      Cases_on `error` >> dsimp[res_rel_rw, eqs, pair_case_eq]
      >- (disj2_tac >> simp[rm1_def] >>
          asm_simp_tac (srw_ss() ++ COND_elim_ss)
            [evaluate_def, const_0_def,
             do_app_def] >> dsimp[] >> csimp[] >>
          reverse (Cases_on `mustkeep b e keeps`)
          >- (full_simp_tac(srw_ss())[mustkeep_def] >>
              IMP_RES_THEN (qspecl_then [`s1 with clock := j`, `env1`] mp_tac)
                           pure_correct >>
              simp[]) >>
          simp[] >> rename1 `remove [e]` >> Cases_on `remove [e]` >>
          imp_res_tac remove_SING >> var_eq_tac >> full_simp_tac(srw_ss())[] >>
          rename1 `remove [e] = ([e'], _)` >>
          first_x_assum (qspec_then `b` mp_tac) >> simp[] >>
          simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
          disch_then (qspecl_then [`i`, `env1`, `env2`, `s1`, `s2`] mp_tac) >>
          simp[] >> disch_then (qspec_then `j` mp_tac) >> simp[res_rel_rw] >>
          metis_tac[]) >>
      rename1 `evaluate _ = (Rerr (Rabort ab), s1')` >>
      Cases_on `ab` >> dsimp[res_rel_rw, pair_case_eq, eqs] >> disj2_tac >>
      simp[rm1_def] >>
      asm_simp_tac (srw_ss() ++ COND_elim_ss ++ CONJ_ss)
        [evaluate_def, const_0_def, do_app_def] >>
      reverse (Cases_on `mustkeep b e keeps`) >> simp[]
      >- (full_simp_tac(srw_ss())[mustkeep_def] >>
          IMP_RES_THEN (qspecl_then [`s1 with clock := j`, `env1`] mp_tac)
                       pure_correct >> simp[]) >>
      rename1 `remove [e]` >> Cases_on `remove [e]` >>
      imp_res_tac remove_SING >> var_eq_tac >> full_simp_tac(srw_ss())[] >>
      first_x_assum (qspec_then `b` mp_tac) >> simp[] >>
      simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
      disch_then (qspecl_then [`i`, `env1`, `env2`, `s1`, `s2`] mp_tac) >>
      simp[] >> disch_then (qspec_then `j` mp_tac) >> simp[res_rel_rw]) >>
  rename1 `evaluate _ = (Rval r1list, s1')` >>
  `∃r1. r1list = [r1]` by metis_tac[evaluate_SING] >> var_eq_tac >> simp[] >>
  `∃r1' s1''. evaluate (es,env1,s1') = (r1',s1'')`
     by metis_tac[pair_CASES] >> simp[] >>
  reverse (Cases_on `r1'`) >> simp[]
  >- (rename1 `evaluate(es,env1,s1') = (Rerr err, s1'')` >>
      Cases_on `err` >> simp[res_rel_rw]
      >- (simp[rm1_def] >> reverse (Cases_on `mustkeep b e keeps`) >> simp[]
          >- (dsimp[const_0_def, evaluate_def,
                    do_app_def, rm1_o_SUC, pair_case_eq, eqs] >>
              full_simp_tac(srw_ss())[mustkeep_def] >>
              IMP_RES_THEN (qspecl_then [`s1 with clock := j`, `env1`] mp_tac)
                           pure_correct >> simp[] >> srw_tac[][] >>
              first_x_assum
                (qspecl_then [`s1`, `s2`, `j`, `i`, `w`, `b + 1`, `env1`, `env2`]
                             mp_tac) >>
              simp[res_rel_rw] >> asm_rewrite_tac[]) >>
          Cases_on `remove[e]` >> imp_res_tac remove_SING >> var_eq_tac >>
          full_simp_tac(srw_ss())[] >> first_x_assum (qspec_then `b` mp_tac) >> simp[] >>
          simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
          disch_then (qspecl_then [`i`, `env1`, `env2`, `s1`, `s2`] mp_tac) >>
          simp[] >> disch_then (qspec_then `j` mp_tac) >>
          dsimp[res_rel_rw, rm1_o_SUC] >> rpt strip_tac >>
          rename1 `state_rel s1'.clock _ s1' s2'` >>
          first_x_assum (qspecl_then [`s1'`, `s2'`, `s2'.clock`, `s2'.clock`,
                                      `w`, `b + 1`, `env1`, `env2`] mp_tac) >>
          full_simp_tac(srw_ss())[] >> asm_rewrite_tac[] >>
          `s1' with clock := s2'.clock = s1' ∧
           s2' with clock := s2'.clock = s2'`
            by simp[state_component_equality] >>
          dsimp[res_rel_rw, eqs, pair_case_eq] >> disch_then irule >>
          irule val_rel_mono_list >> qexists_tac `i` >> simp[] >>
          imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >> simp[]) >>
      rename1 `evaluate (es,_,_) = (Rerr (Rabort abt), _)` >>
      Cases_on `abt` >> simp[res_rel_rw] >>
      simp[rm1_def] >> reverse (Cases_on `mustkeep b e keeps`) >> simp[]
      >- (dsimp[const_0_def, evaluate_def,
                do_app_def, rm1_o_SUC, pair_case_eq, eqs] >>
          full_simp_tac(srw_ss())[mustkeep_def] >>
          IMP_RES_THEN (qspecl_then [`s1 with clock := j`, `env1`] mp_tac)
                       pure_correct >> simp[] >> srw_tac[][] >>
          first_x_assum
            (qspecl_then [`s1`, `s2`, `j`, `i`, `w`, `b + 1`, `env1`, `env2`]
                         mp_tac) >>
          simp[res_rel_rw] >> asm_rewrite_tac[]) >>
      Cases_on `remove[e]` >> imp_res_tac remove_SING >> var_eq_tac >>
      full_simp_tac(srw_ss())[] >> first_x_assum (qspec_then `b` mp_tac) >> simp[] >>
      simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
      disch_then (qspecl_then [`i`, `env1`, `env2`, `s1`, `s2`] mp_tac) >>
      simp[] >> disch_then (qspec_then `j` mp_tac) >>
      dsimp[res_rel_rw, rm1_o_SUC] >> rpt strip_tac >>
      rename1 `state_rel s1'.clock _ s1' s2'` >>
      first_x_assum (qspecl_then [`s1'`, `s2'`, `s2'.clock`, `s2'.clock`,
                                  `w`, `b + 1`, `env1`, `env2`] mp_tac) >>
      full_simp_tac(srw_ss())[] >> asm_rewrite_tac[] >>
      `s1' with clock := s2'.clock = s1' ∧
       s2' with clock := s2'.clock = s2'`
        by simp[state_component_equality] >>
      dsimp[res_rel_rw, eqs, pair_case_eq] >> disch_then irule >>
      irule val_rel_mono_list >> qexists_tac `i` >> simp[] >>
      imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >> simp[]) >>
  simp[rm1_def] >> reverse (Cases_on `mustkeep b e keeps`) >> simp[]
  >- (dsimp[const_0_def, evaluate_def,
            do_app_def, rm1_o_SUC, pair_case_eq, eqs] >>
      full_simp_tac(srw_ss())[mustkeep_def] >>
      IMP_RES_THEN (qspecl_then [`s1 with clock := j`, `env1`] mp_tac)
                   pure_correct >> simp[] >> srw_tac[][] >>
      first_x_assum
        (qspecl_then [`s1`, `s2`, `j`, `i` ,`w`, `b + 1`, `env1`, `env2`]
                     mp_tac) >>
      simp[res_rel_rw] >>
      simp[LIST_RELi_thm, combinTheory.o_ABS_L, ADD1, keepval_rel_def,
           keepval_rel_o_SUC, GSPEC_o, ELplus1] >>
      metis_tac[]) >>
  Cases_on `remove[e]` >> imp_res_tac remove_SING >> var_eq_tac >>
  full_simp_tac(srw_ss())[] >> first_x_assum (qspec_then`b` mp_tac) >> simp[] >>
  simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
  disch_then (qspecl_then [`i`, `env1`, `env2`, `s1`, `s2`] mp_tac) >>
  simp[] >> disch_then (qspec_then `j` mp_tac) >>
  dsimp[res_rel_rw, rm1_o_SUC] >> rpt strip_tac >>
  dsimp[LIST_RELi_thm, combinTheory.o_ABS_L, ADD1, eqs, pair_case_eq,
        keepval_rel_o_SUC, GSPEC_o, ELplus1, keepval_rel_def] >>
  rename1 `state_rel s1'.clock _ s1' s2'` >>
  first_x_assum (qspecl_then [`s1'`, `s2'`, `s2'.clock`, `s2'.clock`,
                              `w`, `b + 1`, `env1`, `env2`] mp_tac) >>
  full_simp_tac(srw_ss())[] >> asm_rewrite_tac[] >>
  `s1' with clock := s2'.clock = s1' ∧
   s2' with clock := s2'.clock = s2'`
    by simp[state_component_equality] >>
  dsimp[res_rel_rw, eqs, pair_case_eq] >>
  `LIST_REL (val_rel (:'ffi) s2'.clock w) env1 env2`
     by (irule val_rel_mono_list >> qexists_tac `i` >> simp[] >>
         imp_res_tac evaluate_clock >> lfs[]) >>
  dsimp[] >> rpt strip_tac >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] >>
  irule (hd (CONJUNCTS val_rel_mono)) >>
  qexists_tac `s2'.clock` >> simp[] >>
  imp_res_tac evaluate_clock >> lfs[])

val every_Fn_vs_NONE_CONS = Q.store_thm(
  "every_Fn_vs_NONE_CONS",
  `every_Fn_vs_NONE (e::es) ⇔ every_Fn_vs_NONE [e] ∧ every_Fn_vs_NONE es`,
  Cases_on `es` >> simp[every_Fn_vs_NONE_def]);

val evaluate_app_SING = Q.store_thm(
  "evaluate_app_SING",
  `evaluate_app opt x y z = (Rval rs, s) ==> ∃r. rs = [r]`,
  strip_tac >> imp_res_tac evaluate_app_IMP_LENGTH >>
  Cases_on `rs` >> full_simp_tac(srw_ss())[LENGTH_NIL]);

val optCASE_NONE_T = Q.prove(
  `option_CASE opt T f ⇔ (∀r. opt = SOME r ⇒ f r)`,
  Cases_on `opt` >> simp[]);

val optCASE_NONE_F = Q.prove(
  `option_CASE opt F f ⇔ ∃r. opt = SOME r ∧ f r`,
  Cases_on `opt` >> simp[]);

(* not true as stated because say max_app is 10 and vs1 and vs2 have 5
   elements each.  Then the closure with no arguments so far can't be
   applied to 11 arguments, but the closure with vs1 and vs2 already there
   can certainly be applied to 6 arguments.


val Recclosure_addargs = Q.store_thm(
  "Recclosure_addargs",
  `pos < LENGTH fns ∧
   val_rel (:'ffi) i
     (Recclosure opt [] env1 fns pos) (Recclosure opt [] env2 fns pos) ∧
   LIST_REL (val_rel (:'ffi) i) vs1 vs2 ∧ LENGTH vs2 < FST (EL pos fns) ⇒
   val_rel (:'ffi) i (Recclosure opt vs1 env1 fns pos)
                     (Recclosure opt vs2 env2 fns pos)`,
  strip_tac >>
  simp[val_rel_rw, is_closure_def, check_closures_def, optCASE_NONE_T,
       optCASE_NONE_F, clo_can_apply_def, clo_to_partial_args_def,
       clo_to_num_params_def, clo_to_loc_def, rec_clo_ok_def,
       dest_closure_def, revtakerev, revdroprev] >>
  dsimp[UNCURRY, bool_case_eq] >> rpt strip_tac >- full_simp_tac(srw_ss())[]
  >- (imp_res_tac LIST_REL_LENGTH >> full_simp_tac(srw_ss())[] >>
      simp[exec_rel_rw, evaluate_ev_def] >>
      rename1 `j < i` >> qx_gen_tac `k` >> reverse COND_CASES_TAC
      >- (simp[res_rel_rw] >> metis_tac[DECIDE``0n≤x``,val_rel_mono]) >>
      simp[] >>
      `∃N fb. EL pos fns = (N,fb)` by metis_tac[pair_CASES] >> full_simp_tac(srw_ss())[] >>
      rename1 `LIST_REL (val_rel (:'ffi) j) vs11 vs21` >> strip_tac >>
      qpat_x_assum `val_rel (:'ffi) _ _ _` mp_tac >>
      simp[val_rel_rw, is_closure_def, check_closures_def,
           clo_can_apply_def, clo_to_partial_args_def,
           clo_to_num_params_def, clo_to_loc_def, rec_clo_ok_def] >>
      rename1 `state_rel j s1 s2` >>
      rename1 `check_loc lopt` >>
      disch_then (qspecl_then [`j`, `vs11 ++ vs1`, `vs21 ++ vs2`] mp_tac) >>
      simp[] >>
      disch_then (qspecl_then [`s1`, `s2`, `lopt`] mp_tac) >> simp[] >>
      impl_tac
      >- (irule EVERY2_APPEND_suff >> simp[] >>
          irule val_rel_mono_list >> qexists_tac `i` >> simp[]) >>
      simp[dest_closure_def] >> Cases_on `lopt` >> full_simp_tac(srw_ss())[check_loc_def] >>
      simp[optCASE_NONE_T] >> simp[exec_rel_rw, evaluate_ev_def]
*)

val unused_vars_correct = Q.store_thm(
  "unused_vars_correct",
  `∀i es env1 env2 (s1:'ffi closSem$state) s2 kis j.
      state_rel i w s1 s2 ∧ j ≤ i ∧
      (∀v. fv v es ⇒ v ∈ kis) ∧ every_Fn_vs_NONE es ∧
      LIST_RELi (λk v1 v2. k ∈ kis ⇒ val_rel (:'ffi) i w v1 v2) env1 env2 ⇒
      res_rel w (evaluate(es,env1,s1 with clock := j))
                (evaluate(es,env2,s2 with clock := j))`,
  gen_tac >> completeInduct_on `i` >>
  full_simp_tac(srw_ss())[GSYM RIGHT_FORALL_IMP_THM, AND_IMP_INTRO] >> qx_gen_tac `es` >>
  completeInduct_on `exp3_size es` >>
  full_simp_tac(srw_ss())[GSYM RIGHT_FORALL_IMP_THM, AND_IMP_INTRO] >> Cases_on `es`
  >- (simp[evaluate_def, res_rel_rw] >> metis_tac[val_rel_mono]) >>
  ONCE_REWRITE_TAC [fv_cons, evaluate_CONS, every_Fn_vs_NONE_CONS] >>
  dsimp[] >> rpt gen_tac >>
  rename1 `exp3_size es + (closLang$exp_size e + 1)` >>
  reverse (Cases_on `es`)
  >- (rename1 `exp3_size (e2::es) + (closLang$exp_size e1 + 1)` >>
      srw_tac[][] >>
      first_assum
        (qspecl_then [`[e1]`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`] mp_tac) >>
      simp[] >> simp[SimpL ``$==>``, res_rel_cases] >>
      strip_tac >> simp[res_rel_rw] >>
      rename1 `evaluate(_, env1, _) = (_, s11)` >>
      rename1 `evaluate(_, env2, _) = (_, s21)` >>
      imp_res_tac evaluate_SING >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
      imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
      `s21.clock = i ∨ s21.clock < i` by simp[]
      >- (first_x_assum
           (qspecl_then [`e2::es`, `env1`, `env2`, `s11`, `s21`, `kis`, `i`]
                        mp_tac) >> simp[exp_size_def] >> full_simp_tac(srw_ss())[] >>
          `s11 with clock := i = s11 ∧ s21 with clock := i = s21`
             by simp[state_component_equality] >> simp[] >>
          impl_tac >- metis_tac[] >>
          simp[SimpL ``$==>``, res_rel_cases] >> strip_tac >>
          simp[res_rel_rw] >> srw_tac[][] >> irule (CONJUNCT1 val_rel_mono) >>
          qexists_tac `s21.clock` >> simp[] >> imp_res_tac evaluate_clock) >>
      first_x_assum
        (qspecl_then [`s21.clock`, `e2::es`, `env1`, `env2`, `s11`, `s21`,
                      `kis`, `s21.clock`] mp_tac) >> simp[] >>
      impl_tac
      >- (conj_tac >- metis_tac[] >>
          full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> rpt strip_tac >>
          irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >> simp[]) >>
      `s11 with clock := s21.clock = s11 ∧ s21 with clock := s21.clock = s21`
        by simp[state_component_equality] >> simp[] >>
      simp[SimpL ``$==>``, res_rel_cases] >> strip_tac >> simp[res_rel_rw] >>
      irule (CONJUNCT1 val_rel_mono) >> qexists_tac `s21.clock` >> simp[] >>
      imp_res_tac evaluate_clock) >>
  simp[fv_def, fv1_thm, evaluate_def] >>
  Cases_on `e` >> simp[fv_def, fv1_thm, evaluate_def] >> strip_tac >>
  imp_res_tac LIST_RELi_LENGTH >> simp[]
  >- ((* var *) srw_tac[][] >> simp[res_rel_rw] >>
      full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> conj_tac
      >- (irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >> simp[]) >>
      irule (last (CONJUNCTS val_rel_mono)) >> qexists_tac `i` >> simp[])
  >- ((* If *)
      rename1 `evaluate([gd],env1,_)` >> full_simp_tac(srw_ss())[DISJ_IMP_THM, FORALL_AND_THM] >>
      first_assum
        (qspecl_then [`[gd]`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`] mp_tac) >>
      simp[exp_size_def] >> simp[SimpL ``$==>``, res_rel_cases] >>
      strip_tac >> simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[] >>
      rpt var_eq_tac >> reverse COND_CASES_TAC
      >- (reverse COND_CASES_TAC >> simp[] >> var_eq_tac >> full_simp_tac(srw_ss())[] >>
          rename1 `(_, env1, s11)` >> rename1 `([e1], env2, s21)` >>
          `res_rel w (evaluate ([e1], env1, s11 with clock := s21.clock))
                     (evaluate ([e1], env2, s21 with clock := s21.clock))`
            by (imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
                Cases_on `s21.clock = i`
                >- (first_x_assum
                      (qspecl_then [`[e1]`, `env1`, `env2`, `s11`, `s21`,
                                    `kis`, `i`] mp_tac) >> simp[exp_size_def] >>
                    full_simp_tac(srw_ss())[] >> rveq >> simp[]) >>
                `s21.clock < i` by simp[] >>
                first_x_assum
                  (qspecl_then [`s21.clock`, `[e1]`, `env1`, `env2`, `s11`,
                                `s21`, `kis`, `s21.clock`] mp_tac) >>
                simp[] >> disch_then irule >> lfs[LIST_RELi_EL_EQN] >>
                metis_tac[DECIDE ``x:num < y ⇒ x ≤ y``, val_rel_mono]) >>
          pop_assum mp_tac >>
          simp[SimpL ``$==>``, res_rel_cases] >>
          `s11 with clock := s21.clock = s11 ∧
           s21 with clock := s21.clock = s21`
            by simp[state_component_equality] >> simp[] >>
          strip_tac >> simp[res_rel_rw] >>
          imp_res_tac evaluate_SING >> srw_tac[][] >> full_simp_tac(srw_ss())[]) >>
      var_eq_tac >> full_simp_tac(srw_ss())[] >> var_eq_tac >>
      rename1 `(_, env1, s11)` >> rename1 `([E], env2, s21)` >>
      `res_rel w (evaluate ([E], env1, s11 with clock := s21.clock))
                 (evaluate ([E], env2, s21 with clock := s21.clock))`
        by (imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
            Cases_on `s21.clock = i`
            >- (first_x_assum
                  (qspecl_then [`[E]`, `env1`, `env2`, `s11`, `s21`,
                                `kis`, `i`] mp_tac) >> simp[exp_size_def] >>
                full_simp_tac(srw_ss())[] >> rveq >> simp[]) >>
            `s21.clock < i` by simp[] >>
            first_x_assum
              (qspecl_then [`s21.clock`, `[E]`, `env1`, `env2`, `s11`,
                            `s21`, `kis`, `s21.clock`] mp_tac) >>
            simp[] >> disch_then irule >> lfs[LIST_RELi_EL_EQN] >>
            metis_tac[DECIDE ``x:num < y ⇒ x ≤ y``, val_rel_mono]) >>
      pop_assum mp_tac >>
      simp[SimpL ``$==>``, res_rel_cases] >>
      `s11 with clock := s21.clock = s11 ∧
       s21 with clock := s21.clock = s21`
        by simp[state_component_equality] >> simp[] >>
      strip_tac >> simp[res_rel_rw] >>
      imp_res_tac evaluate_SING >> srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- ((* Let *)
      rename1 `(bexps,env1,_)` >> full_simp_tac(srw_ss())[DISJ_IMP_THM, FORALL_AND_THM] >>
      first_assum
        (qspecl_then [`bexps`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`]
                     mp_tac) >> simp[exp_size_def] >>
      simp[SimpL ``$==>``, res_rel_cases] >> strip_tac >> simp[res_rel_rw] >>
      rename1 `([E], bvs1 ++ env1, s11)` >>
      rename1 `([E], bvs2 ++ env2, s21)` >>
      `res_rel w (evaluate ([E], bvs1 ++ env1, s11))
                 (evaluate([E], bvs2 ++ env2, s21))`
        by (imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
            `s11 with clock := s21.clock = s11 ∧
             s21 with clock := s21.clock = s21`
              by simp[state_component_equality] >>
            `s21.clock = i ∨ s21.clock < i` by simp[]
            >- (first_x_assum
                  (qspecl_then [`[E]`, `bvs1 ++ env1`, `bvs2 ++ env2`,
                                `s11`, `s21`,
                                `count (LENGTH bvs2) ∪
                                  IMAGE ((+) (LENGTH bvs2)) kis`,
                                `s21.clock`] mp_tac) >>
                simp[exp_size_def] >> disch_then irule
                >- (qx_gen_tac `V` >> strip_tac >> Cases_on `V < LENGTH bvs2` >>
                    simp[] >> qexists_tac `V - LENGTH bvs2` >> simp[] >>
                    imp_res_tac evaluate_length_imp >> full_simp_tac(srw_ss())[] >>
                    first_x_assum irule >> simp[])
                >- (irule LIST_RELi_APPEND_I
                    >- (csimp[LIST_RELi_EL_EQN] >> full_simp_tac(srw_ss())[LIST_REL_EL_EQN]) >>
                    simp[combinTheory.o_ABS_L] >>
                    imp_res_tac LIST_REL_LENGTH >> simp[]) >> full_simp_tac(srw_ss())[]) >>
            first_x_assum
              (qspecl_then [`s21.clock`, `[E]`, `bvs1 ++ env1`, `bvs2 ++ env2`,
                            `s11`, `s21`,
                            `count (LENGTH bvs2) ∪
                               IMAGE ((+) (LENGTH bvs2)) kis`,
                            `s21.clock`] mp_tac) >> simp[] >>
            imp_res_tac evaluate_length_imp >> full_simp_tac(srw_ss())[] >>
            disch_then irule
            >- (qx_gen_tac `V` >> strip_tac >> Cases_on `V < LENGTH bvs2` >>
                simp[] >> qexists_tac `V - LENGTH bvs2` >> simp[]) >>
            irule LIST_RELi_APPEND_I
            >- (csimp[LIST_RELi_EL_EQN] >> full_simp_tac(srw_ss())[LIST_REL_EL_EQN]) >>
            simp[combinTheory.o_ABS_L] >> full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> rpt strip_tac >>
            irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >> simp[]) >>
      pop_assum mp_tac >> simp[SimpL ``$==>``, res_rel_cases] >> strip_tac >>
      simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[])
  >- ((* Raise *) full_simp_tac(srw_ss())[exp_size_def] >> rename1 `fv1 _ E` >>
      first_x_assum
        (qspecl_then [`[E]`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`]
                     mp_tac) >>
      simp[exp_size_def] >> simp[SimpL ``$==>``, res_rel_cases] >>
      rpt strip_tac >> simp[res_rel_rw] >> imp_res_tac evaluate_SING >>
      srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- ((* Handle *) full_simp_tac(srw_ss())[exp_size_def, DISJ_IMP_THM, FORALL_AND_THM] >>
      rename1 `evaluate([body],env1,_)` >>
      rename1 `fv1 (_ + 1) hndlr` >>
      first_assum
        (qspecl_then [`[body]`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`]
                     mp_tac) >> simp[exp_size_def] >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >- (imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[]) >>
      rename1 `state_rel s21.clock w s11 s21` >>
      rename1 `val_rel (:'ffi) s21.clock w exn1 exn2` >>
      `s11 with clock := s21.clock = s11 ∧ s21 with clock := s21.clock = s21`
        by simp[state_component_equality] >> simp[] >>
      `res_rel w (evaluate([hndlr],exn1::env1,s11))
                 (evaluate([hndlr],exn2::env2,s21))`
        by (Cases_on `s21.clock = i`
            >- (var_eq_tac >>
                first_assum
                  (qspecl_then [`[hndlr]`, `exn1::env1`, `exn2::env2`,
                                `s11`, `s21`,
                                `0 INSERT IMAGE SUC kis`, `s21.clock`]
                               mp_tac) >> simp[exp_size_def] >>
                disch_then irule >- simp[Once FORALL_NUM, ADD1] >>
                simp[LIST_RELi_thm, combinTheory.o_ABS_L]) >>
            imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
            `s21.clock < i` by simp[] >>
            first_x_assum
              (qspecl_then [`s21.clock`, `[hndlr]`, `exn1::env1`, `exn2::env2`,
                            `s11`, `s21`, `0 INSERT IMAGE SUC kis`,
                            `s21.clock`] mp_tac) >>
            simp[LIST_RELi_thm, combinTheory.o_ABS_L] >>
            disch_then irule >- simp[Once FORALL_NUM, ADD1] >>
            full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> rpt strip_tac >>
            irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >> simp[]) >>
      pop_assum mp_tac >> simp[SimpL ``$==>``, res_rel_cases] >>
      rpt strip_tac >> simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[])
  >- ((* Tick *) full_simp_tac(srw_ss())[exp_size_def] >> rename1 `fv1 _ E` >>
      srw_tac[][] >- (simp[res_rel_rw] >> metis_tac[DECIDE ``0n ≤ x``, val_rel_mono])>>
      simp[dec_clock_def] >>
      first_x_assum
        (qspecl_then [`[E]`, `env1`, `env2`, `s1`, `s2`, `kis`, `j - 1`]
                     mp_tac) >>
      simp[exp_size_def] >> simp[SimpL ``$==>``, res_rel_cases] >>
      rpt strip_tac >> simp[res_rel_rw] >>
      imp_res_tac evaluate_SING >> srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- ((* Call *) full_simp_tac(srw_ss())[exp_size_def] >> rename1 `fv _ args` >>
      first_x_assum
        (qspecl_then [`args`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`]
                     mp_tac) >>
      simp[exp_size_def] >> simp[SimpL ``$==>``, res_rel_cases] >>
      rpt strip_tac >> simp[res_rel_rw] >>
      rename1 `closSem$find_code fnum res1 s11.code` >>
      Cases_on `find_code fnum res1 s11.code` >- simp[res_rel_rw] >> simp[] >>
      rename1 `find_code fnum res1 s11.code = SOME pp` >>
      Cases_on `pp` >> simp[] >>
      rename1 `find_code fnum res1 s11.code = SOME (env11,b1)` >>
      rename1 `state_rel s21.clock _ s11 s21` >>
      rename1 `find_code fnum res2 s21.code` >>
      qspecl_then [`s21.clock`, `n0`, `fnum`, `res1`, `s11`, `env11`, `b1`, `res2`,
                   `s21`] mp_tac find_code_related >> simp[] >> dsimp[] >>
      srw_tac[][] >- (simp[res_rel_rw] >> metis_tac[DECIDE``0n≤x``,val_rel_mono]) >>
      full_simp_tac(srw_ss())[exec_rel_rw, evaluate_ev_def] >>
      pop_assum (qspec_then `s21.clock - (n0+1)` mp_tac) >> simp[] >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw, dec_clock_def] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[])
  >- ((* App *) full_simp_tac(srw_ss())[exp_size_def, FORALL_AND_THM, DISJ_IMP_THM] >>
      srw_tac[][] >> rename1 `exp3_size args` >>
      first_assum
        (qspecl_then [`args`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`]
                     mp_tac) >>
      simp[exp_size_def] >> simp[SimpL ``$==>``, res_rel_cases] >>
      rpt strip_tac >> simp[res_rel_rw] >> rename1 `fv1 _ f` >>
      rename1 `state_rel s21.clock _ s11 s21` >>
      `res_rel w (evaluate([f],env1,s11)) (evaluate([f],env2,s21))`
        by (Cases_on `s21.clock < i`
            >- (first_x_assum
                  (qspecl_then [`s21.clock`, `[f]`, `env1`, `env2`, `s11`,
                                `s21`, `kis`, `s21.clock`] mp_tac) >>
                simp[] >> impl_tac
                >- (lfs[LIST_RELi_EL_EQN] >> rpt strip_tac >>
                    irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >>
                    simp[]) >>
                `s11 with clock := s21.clock = s11 ∧
                 s21 with clock := s21.clock = s21` suffices_by simp[] >>
                simp[state_component_equality]) >>
            imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >> `s21.clock = i` by simp[] >>
            first_x_assum
              (qspecl_then [`[f]`, `env1`, `env2`, `s11`, `s21`, `kis`,
                            `s21.clock`] mp_tac) >> simp[exp_size_def] >>
            var_eq_tac >> simp[] >>
            `s11 with clock := s21.clock = s11 ∧
             s21 with clock := s21.clock = s21` suffices_by simp[] >>
            simp[state_component_equality]) >>
      pop_assum mp_tac >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[] >>
      rename1 `state_rel s22.clock _ s12 s22` >> rpt var_eq_tac >>
      rename1 `evaluate_app opt fr1 argr1 s12` >>
      rename1 `evaluate_app opt fr2 argr2 s22` >>
      Cases_on `argr1 = []` >- full_simp_tac(srw_ss())[evaluate_def, res_rel_rw] >>
      `res_rel w (evaluate_app opt fr1 argr1 s12)
                 (evaluate_app opt fr2 argr2 s22)`
        by (irule res_rel_evaluate_app >> simp[] >>
            full_simp_tac(srw_ss())[LIST_REL_EL_EQN] >>
            rpt strip_tac >> irule (CONJUNCT1 val_rel_mono) >>
            qexists_tac `s21.clock` >> simp[] >> imp_res_tac evaluate_clock) >>
      pop_assum mp_tac >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >> imp_res_tac evaluate_app_SING >> full_simp_tac(srw_ss())[])
  >- ((* Fn *) full_simp_tac(srw_ss())[exp_size_def] >> rpt var_eq_tac >> srw_tac[][] >>
      simp[res_rel_rw] >>
      TRY (imp_res_tac state_rel_max_app \\ fs[] \\ NO_TAC) >>
      reverse conj_tac >- metis_tac[val_rel_mono] >>
      rename1 `every_Fn_vs_NONE [body]` >>
      rename1 `N ≤ s1.max_app` >>
      rename1 `Closure opt [] env1 N body` >>
      Q.UNDISCH_THEN `j ≤ i` mp_tac >>
      `∀j vs1 vs2.
         j ≤ i ∧ LIST_REL (val_rel (:'ffi) j w) vs1 vs2 ∧ LENGTH vs2 < N ⇒
         val_rel (:'ffi) j w (Closure opt vs1 env1 N body)
                             (Closure opt vs2 env2 N body)`
        suffices_by (rpt strip_tac >> first_x_assum irule >> simp[]) >>
      gen_tac >>
      completeInduct_on `j` >> rpt strip_tac >> lfs[] >>
      simp[val_rel_rw, is_closure_def] >> conj_tac
      >- (simp[check_closures_def, clo_can_apply_def, clo_to_partial_args_def,
               clo_to_num_params_def, clo_to_loc_def, rec_clo_ok_def] >>
          rpt strip_tac >> imp_res_tac LIST_REL_LENGTH >> full_simp_tac(srw_ss())[]) >>
      simp[dest_closure_def, revtakerev, revdroprev, optCASE_NONE_F,
           optCASE_NONE_T] >>
      dsimp[bool_case_eq] >> conj_tac
      >- (rpt strip_tac >> imp_res_tac LIST_REL_LENGTH >> simp[] >> full_simp_tac(srw_ss())[] >>
          simp[exec_rel_rw, evaluate_ev_def] >>
          rename1 `k < j` >> reverse (srw_tac[][])
          >- (simp[res_rel_rw] >> metis_tac[DECIDE``0n≤x``,val_rel_mono]) >>
          TRY (imp_res_tac state_rel_max_app \\ fs[] \\ NO_TAC) >>
          rename1 `N ≤ k' + (LENGTH vs2 + 1)` >>
          rename1 `LIST_REL (val_rel (:'ffi) k _) vs11 vs21` >>
          rename1 `state_rel k _ s11 s21` >>
          first_assum
            (qspecl_then [
               `k`, `[body]`,
               `DROP (LENGTH vs21 + LENGTH vs2 - N) vs11 ++ vs1 ++ env1`,
               `DROP (LENGTH vs21 + LENGTH vs2 - N) vs21 ++ vs2 ++ env2`
             ] mp_tac) >>
          disch_then
            (qspecl_then [`s11`, `s21`,
                          `count N ∪ IMAGE ((+) N) kis`,
                          `k' + (LENGTH vs2 + 1) - N`]
                         mp_tac) >> simp[] >> impl_tac
          >- (conj_tac
              >- (qx_gen_tac `v` >> strip_tac >>
                  Cases_on `v < N` >> simp[] >> qexists_tac `v - N` >>
                  simp[]) >>
              lfs[LIST_RELi_EL_EQN, LIST_REL_EL_EQN] >>
              dsimp[EL_APPEND2, EL_APPEND1, EL_DROP] >>
              reverse strip_tac
              >- (rpt strip_tac >> irule (CONJUNCT1 val_rel_mono) >>
                  qexists_tac `i` >> simp[]) >>
              qx_gen_tac `kk` >> rpt strip_tac >>
              Cases_on `kk < LENGTH vs21 - (LENGTH vs2 + LENGTH vs21 - N)`
              >- simp[EL_APPEND1, EL_DROP] >>
              simp[EL_APPEND2] >> lfs[] >>
              irule (CONJUNCT1 val_rel_mono) >> qexists_tac `j` >>
              simp[]) >>
          simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
          simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[] >>
          Cases_on `N = LENGTH vs2 + LENGTH vs21` >> simp[res_rel_rw] >>
          irule res_rel_evaluate_app >> simp[] >>
          lfs[LIST_REL_EL_EQN, EL_TAKE] >> rpt strip_tac >>
          irule (CONJUNCT1 val_rel_mono) >> qexists_tac `k` >> simp[] >>
          imp_res_tac evaluate_clock >> lfs[]) >>
      rpt strip_tac >> imp_res_tac LIST_REL_LENGTH >> full_simp_tac(srw_ss())[] >>
      simp[exec_rel_rw, evaluate_ev_def] >> rpt strip_tac >>
      TRY (imp_res_tac state_rel_max_app \\ fs[] \\ NO_TAC) >>
      reverse COND_CASES_TAC >> simp[res_rel_rw]
      >- metis_tac[DECIDE``0n≤x``,val_rel_mono] >>
      reverse conj_tac
      >- (rename1 `state_rel _ _ s11 s21` >> rename1 `ii < j` >>
          irule (val_rel_mono |> CONJUNCTS |> last) >> qexists_tac `ii` >>
          simp[]) >>
      first_x_assum irule >> simp[] >>
      irule EVERY2_APPEND_suff
      >- (rename1 `ii < j` >> irule val_rel_mono_list >> qexists_tac `ii` >>
          simp[]) >>
      irule val_rel_mono_list >> qexists_tac `j` >> simp[])
  >- ((* Letrec *) full_simp_tac(srw_ss())[exp_size_def] >>
      rename1 `every_Fn_vs_NONE (MAP SND fns)` >> COND_CASES_TAC >> simp[] >>
      rename1 `Recclosure opt [] env1 fns` >>
      qabbrev_tac
        `fns1_E = GENLIST (Recclosure opt [] env1 fns) (LENGTH fns)` >>
      qabbrev_tac
        `fns2_E = GENLIST (Recclosure opt [] env2 fns) (LENGTH fns)` >>
      rename1 `evaluate([body],fns1_E ++ _, _)` >>
      `LIST_REL (val_rel (:'ffi) i w) fns1_E fns2_E` suffices_by
        (strip_tac >>
         first_x_assum
           (qspecl_then [`[body]`, `fns1_E ++ env1`, `fns2_E ++ env2`,
                         `s1`, `s2`,
                         `count (LENGTH fns) ∪ IMAGE ((+) (LENGTH fns)) kis`,
                         `j`] mp_tac) >> simp[exp_size_def] >>
         impl_tac
         >- (conj_tac
             >- (qx_gen_tac `vv` >> Cases_on `vv < LENGTH fns` >> simp[] >>
                 strip_tac >> qexists_tac `vv - LENGTH fns` >> simp[]) >>
             irule LIST_RELi_APPEND_I
             >- full_simp_tac(srw_ss())[Abbr`fns1_E`,Abbr`fns2_E`,LIST_REL_EL_EQN, LIST_RELi_EL_EQN] >>
             simp[combinTheory.o_ABS_L, Abbr`fns1_E`, Abbr`fns2_E`]) >>
         simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
         simp[res_rel_rw] >> imp_res_tac evaluate_SING >> full_simp_tac(srw_ss())[] >>
         imp_res_tac state_rel_max_app \\ fs[]) >>
      rpt var_eq_tac >>
      simp[Abbr`fns1_E`, Abbr`fns2_E`] >>
      `∀k vs1 vs2.
        LIST_REL (val_rel (:'ffi) k w) vs1 vs2 ∧ k ≤ i ⇒
        LIST_REL (val_rel (:'ffi) k w)
                 (GENLIST (Recclosure opt vs1 env1 fns) (LENGTH fns))
                 (GENLIST (Recclosure opt vs2 env2 fns) (LENGTH fns))`
      suffices_by
        (disch_then (qspecl_then [`i`, `[]`, `[]`] mp_tac) >> simp[]) >>
      gen_tac >> completeInduct_on `k` >> rpt strip_tac >>
      simp[LIST_REL_EL_EQN] >> qx_gen_tac `pos` >> strip_tac >>
      simp[val_rel_rw, is_closure_def, check_closures_def,
           clo_can_apply_def, clo_to_partial_args_def,
           clo_to_num_params_def, clo_to_loc_def, rec_clo_ok_def] >> conj_tac
      >- (rpt gen_tac >> strip_tac >> imp_res_tac LIST_REL_LENGTH >>
          full_simp_tac(srw_ss())[] >> strip_tac >> full_simp_tac(srw_ss())[]) >>
      qx_genl_tac [`kk`, `vs11`, `vs21`, `s11`, `s21`, `lopt`] >>
      strip_tac >> simp[optCASE_NONE_T, optCASE_NONE_F] >>
      dsimp[dest_closure_def, UNCURRY, bool_case_eq, revtakerev,
            revdroprev] >>
      imp_res_tac LIST_REL_LENGTH >> simp[] >>
      `∃N fb. EL pos fns = (N,fb)` by metis_tac[pair_CASES] >> simp[] >>
      reverse (rpt strip_tac)
      >- (simp[exec_rel_rw, evaluate_ev_def] >> qx_gen_tac `k3` >>
          reverse (srw_tac[][]) >> simp[res_rel_rw]
          >- metis_tac[DECIDE``0n≤x``,val_rel_mono] >>
          qmatch_abbrev_tac `val_rel _ kN _ _ _ ∧ state_rel kN _ _ _` >>
          `kN ≤ kk` by simp[Abbr`kN`] >>
          reverse conj_tac >- metis_tac[val_rel_mono] >>
          first_x_assum (qspec_then `kN` mp_tac) >> simp[] >>
          disch_then (qspecl_then [`vs11 ++ vs1`, `vs21 ++ vs2`] mp_tac) >>
          impl_tac
          >- (irule EVERY2_APPEND_suff >> simp[] >>
              metis_tac[val_rel_mono_list,
                        DECIDE ``x ≤ y ∧ y < z ⇒ x ≤ z:num``]) >>
          simp[LIST_REL_EL_EQN]) >>
      TRY (imp_res_tac state_rel_max_app \\ fs[] \\ NO_TAC) >>
      simp[exec_rel_rw, evaluate_ev_def, revdroprev, revtakerev] >>
      qx_gen_tac `k3` >> reverse (srw_tac[][]) >> simp[res_rel_rw]
      >- metis_tac[DECIDE``0n≤x``,val_rel_mono] >>
      first_assum(qspecl_then [`k3 + (LENGTH vs2 + 1) - N`, `[fb]`] mp_tac) >>
      simp[] >>
      disch_then (qspecl_then [
        `DROP (LENGTH vs2 + LENGTH vs21 - N) vs11 ++ vs1 ++
         GENLIST (Recclosure opt [] env1 fns) (LENGTH fns) ++ env1`,
        `DROP (LENGTH vs2 + LENGTH vs21 - N) vs21 ++ vs2 ++
         GENLIST (Recclosure opt [] env2 fns) (LENGTH fns) ++ env2`,
        `s11`, `s21`,
        `count (N + LENGTH fns) ∪ IMAGE ((+) (N + LENGTH fns)) kis`,
        `k3 + (LENGTH vs2 + 1) - N`] mp_tac) >>
      impl_tac
      >- (simp[] >> rpt strip_tac
          >- (irule (val_rel_mono |> CONJUNCTS |> last) >>
              qexists_tac `kk` >> simp[])
          >- (rename1 `vv < N + LENGTH fns` >>
              Cases_on `vv < N + LENGTH fns` >> simp[] >>
              qexists_tac `vv - (N + LENGTH fns)` >> simp[] >>
              first_x_assum irule >> disj1_tac >>
              simp[EXISTS_MEM, EXISTS_PROD] >>
              map_every qexists_tac [`N`, `fb`] >> simp[] >>
              metis_tac[MEM_EL])
          >- (full_simp_tac(srw_ss())[Once every_Fn_vs_NONE_EVERY, EVERY_MEM] >>
              full_simp_tac(srw_ss())[FORALL_PROD, MEM_MAP, PULL_EXISTS] >> metis_tac[MEM_EL])
          >- (rpt (irule LIST_RELi_APPEND_I)
              >- ((* vs{2,1}1 *) full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> dsimp[EL_DROP] >>
                  full_simp_tac(srw_ss())[LIST_REL_EL_EQN] >> rpt strip_tac >>
                  irule (CONJUNCT1 val_rel_mono) >>
                  qexists_tac `kk` >> simp[])
              >- ((* vs1/2 *)simp[combinTheory.o_ABS_L, LIST_RELi_EL_EQN] >>
                  full_simp_tac(srw_ss())[LIST_REL_EL_EQN] >> rpt strip_tac >>
                  irule (CONJUNCT1 val_rel_mono) >>
                  qexists_tac `k` >> simp[])
              >- ((* recclosures *) simp[combinTheory.o_ABS_L, LIST_RELi_EL_EQN] >>
                  first_x_assum
                    (qspec_then `k3 + (LENGTH vs2 + 1) - N` mp_tac) >>
                  simp[] >> disch_then (qspecl_then [`[]`, `[]`] mp_tac) >>
                  simp[LIST_REL_EL_EQN])
              >- ((* env1/2 *) simp[combinTheory.o_ABS_L] >>
                  full_simp_tac(srw_ss())[LIST_RELi_EL_EQN] >> rpt strip_tac >>
                  irule (CONJUNCT1 val_rel_mono) >> qexists_tac `i` >>
                  simp[]))) >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >> imp_res_tac evaluate_SING >> rpt var_eq_tac >>
      full_simp_tac(srw_ss())[] >>
      Cases_on `N = LENGTH vs2 + LENGTH vs21` >> simp[]
      >- simp[res_rel_rw] >>
      irule res_rel_evaluate_app >> simp[] >>
      lfs[LIST_REL_EL_EQN, EL_TAKE, LENGTH_TAKE] >> rpt strip_tac >>
      imp_res_tac evaluate_clock >> full_simp_tac(srw_ss())[] >>
      irule (CONJUNCT1 val_rel_mono) >> qexists_tac `kk` >> simp[])
  >- ((* Op *) full_simp_tac(srw_ss())[exp_size_def] >>
      rename1 `evaluate(args,_,s1 with clock := j)` >>
      first_x_assum
        (qspecl_then [`args`, `env1`, `env2`, `s1`, `s2`, `kis`, `j`] mp_tac) >>
      simp[] >> simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >>
      rename1 `state_rel s21.clock _ s11 s21`>>
      rename1 `LIST_REL (val_rel (:'ffi) s21.clock _) rv1 rv2` >>
      rename1 `do_app opn (REVERSE rv1) s11` >>
      qspecl_then [`s21.clock`, `w`, `opn`, `rv1`, `rv2`, `s11`, `s21`] mp_tac
                  res_rel_do_app >> simp[] >>
      simp[SimpL ``$==>``, res_rel_cases] >> rpt strip_tac >>
      simp[res_rel_rw] >> full_simp_tac(srw_ss())[pair_case_eq, eqs] >> srw_tac[][] >> full_simp_tac(srw_ss())[]))

val unused_vars_correct2 = Q.prove(
  `∀i es1 env1 (s1:'ffi closSem$state) es2 env2 s2 kis j.
      (∀v. fv v es2 ⇒ v ∈ kis) ∧ every_Fn_vs_NONE es2 ∧
      exp_rel (:'ffi) s1.max_app es1 es2 ∧
      LIST_RELi (λk v1 v2. k ∈ kis ⇒ val_rel (:'ffi) i s1.max_app v1 v2) env1 env2 ∧
      state_rel i s1.max_app s1 s2 ∧ j ≤ i ⇒
      res_rel s1.max_app
        (evaluate(es1,env1,s1 with clock := j))
        (evaluate(es2,env2,s2 with clock := j))`,
  rpt strip_tac >> irule res_rel_trans >>
  qexists_tac `(es2,env1,s2 with clock := j)` >> reverse conj_tac
  >- (irule unused_vars_correct >> metis_tac[state_rel_refl,state_rel_max_app]) >>
  qpat_x_assum `exp_rel _ _ _ _` mp_tac >> simp[exp_rel_thm] >>
  disch_then irule >> metis_tac[val_rel_refl])

val every_Fn_vs_NONE_const_0 = Q.store_thm("every_Fn_vs_NONE_const_0[simp]",
  `every_Fn_vs_NONE [const_0]`,
  EVAL_TAC)

val every_Fn_vs_NONE_remove = Q.store_thm("every_Fn_vs_NONE_remove",
  `∀es es' s.
   every_Fn_vs_NONE es ⇒
   remove es = (es',s) ⇒
   every_Fn_vs_NONE es'`,
  ho_match_mp_tac remove_ind >>
  srw_tac[][remove_def] >> full_simp_tac(srw_ss())[LET_THM] >>
  rpt(first_assum(split_uncurry_arg_tac o lhs o concl) >> full_simp_tac(srw_ss())[]) >>
  imp_res_tac remove_SING >>
  rpt var_eq_tac >> full_simp_tac(srw_ss())[] >>
  every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
  rpt(first_assum(split_uncurry_arg_tac o lhs o concl) >> full_simp_tac(srw_ss())[]) >> srw_tac[][] >>
  ONCE_REWRITE_TAC[every_Fn_vs_NONE_EVERY] >>
  simp[EVERY_REPLICATE,EVERY_MAP,UNCURRY] >>
  simp[GSYM every_Fn_vs_NONE_EVERY] >>
  full_simp_tac(srw_ss())[db_varsTheory.FOLDR_mk_Union_UNZIP,FPAIR,LET_THM,UNCURRY,FST_UNZIP_MAPi,
     SND_UNZIP_MAPi,o_ABS_R] >> rpt var_eq_tac >>
  ONCE_REWRITE_TAC[every_Fn_vs_NONE_EVERY] >>
  simp[EVERY_MEM,MEM_MAPi,PULL_EXISTS] >> srw_tac[][] >>
  simp[UNCURRY] >> srw_tac[][] >>
  full_simp_tac(srw_ss())[MEM_EL,PULL_EXISTS] >>
  last_x_assum(match_mp_tac o MP_CANON) >>
  asm_exists_tac >> simp[] >>
  srw_tac[QUANT_INST_ss[pair_default_qp]][] >>
  full_simp_tac(srw_ss())[Once every_Fn_vs_NONE_EVERY,EVERY_MAP,EVERY_MEM,MEM_EL,PULL_EXISTS] >>
  metis_tac[remove_SING,HD,SND,PAIR]);

(* Simplifies away the SNDs and stuff in compile_def*)
val make_SND_tac =
  simp[MAP_MAP_o,o_DEF]>>
  strip_tac>>
  qmatch_goalsub_abbrev_tac ` MAP f (ZIP (es,ls))`>>
  `f = SND` by
    fs[FUN_EQ_THM,Abbr`f`,SND,FORALL_PROD]>>
  `LENGTH es = LENGTH ls` by
    (fs[Abbr`ls`]>>
    metis_tac[remove_LENGTH,LENGTH_MAP,FST,PAIR])>>
  fs[MAP_ZIP,Abbr`ls`]>>
  qmatch_goalsub_abbrev_tac `remove(MAP g es)`>>
  `g = SND o SND` by
    fs[FUN_EQ_THM,Abbr`g`,SND,FORALL_PROD]>>
  simp[o_DEF]

val every_Fn_vs_NONE_compile = Q.store_thm("every_Fn_vs_NONE_compile",
  `∀do_remove es es' s.
   every_Fn_vs_NONE (MAP (SND o SND) es) ⇒
   clos_remove$compile do_remove es = es' ⇒
   every_Fn_vs_NONE (MAP (SND o SND) es')`,
   Cases>>fs[clos_removeTheory.compile_def]>>
   make_SND_tac>>
   metis_tac[PAIR,FST,every_Fn_vs_NONE_remove])

val evaluate_REPconst0s = Q.store_thm(
  "evaluate_REPconst0s",
  `evaluate (REPLICATE N const_0, E, s) = (Rval (REPLICATE N (Number 0)), s)`,
  simp[const_0_def] >> Induct_on `N` >> simp[evaluate_def, REPLICATE] >>
  simp[Once evaluate_CONS] >> simp[evaluate_def, do_app_def]);

val no_overlap_DISJOINT = Q.store_thm(
  "no_overlap_DISJOINT",
  `no_overlap n l ⇔ DISJOINT (count n) { v | has_var v l }`,
  Induct_on `n` >> simp[no_overlap_def, COUNT_SUC] >> metis_tac[]);

val remove_correct = Q.store_thm("remove_correct",
  `∀es es' s.
    every_Fn_vs_NONE es ⇒
    remove es = (es',s) ⇒
    exp_rel (:'ffi) w es es'`,
  ho_match_mp_tac remove_ind >>
  srw_tac[][remove_def] >> full_simp_tac(srw_ss())[LET_THM] >>
  rpt(first_assum(split_uncurry_arg_tac o lhs o concl) >> full_simp_tac(srw_ss())[]) >>
  imp_res_tac remove_SING >>
  rpt var_eq_tac >> full_simp_tac(srw_ss())[] >>
  TRY (rename1`Let` >>
       lfs[db_varsTheory.FOLDR_mk_Union_UNZIP, FPAIR, PAIR_MAP, FST_UNZIP_MAPi,
           SND_UNZIP_MAPi, combinTheory.o_ABS_R] >> srw_tac[][] >>
       simp_tac (srw_ss() ++ COND_elim_ss) [] >>
       simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
       qx_genl_tac [`i`, `env1`, `env2`, `s1`, `s2`] >>
       strip_tac >>
       asm_simp_tac (srw_ss() ++ ETA_ss)
         [evaluate_def, GSYM mustkeep_def,
          rm1_def |> GSYM |> SPEC_ALL
                  |> Q.INST [`n` |-> `0`] |> SIMP_RULE (srw_ss()) []] >>
       qx_gen_tac `j` >> strip_tac >>
       rename1 `remove [body] = ([body'], keeps)` >>
       rename1 `MEM _ es` >> mp_tac (Q.INST [`b` |-> `0`] evaluate_MAPrm1) >>
       simp[] >> full_simp_tac(srw_ss())[GSYM mustkeep_def] >>
       `∀e. MEM e es ⇒ every_Fn_vs_NONE [e]`
          by full_simp_tac(srw_ss())[Once every_Fn_vs_NONE_EVERY, EVERY_MEM] >> full_simp_tac(srw_ss())[] >>
       full_simp_tac(srw_ss())[PULL_FORALL, AND_IMP_INTRO, GSYM CONJ_ASSOC] >> asm_rewrite_tac[] >>
       `∃r1 s1'. evaluate (es,env1,s1 with clock := j) = (r1,s1')`
          by metis_tac[pair_CASES] >> simp[] >>
       reverse (Cases_on `r1`) >> simp[]
       >- (rename1 `evaluate _ = (Rerr err, s1')` >>
           Cases_on `err` >> dsimp[res_rel_rw, eqs, pair_case_eq] >>
           rename1 `evaluate _ = (Rerr (Rabort abt), s1')` >>
           Cases_on `abt` >> dsimp[res_rel_rw]) >>
       dsimp[] >> rpt strip_tac >> full_simp_tac(srw_ss())[] >>
       rename1 `state_rel s21.clock _ s11 s21` >>
       rename1 `vs1 ++ env1` >> rename1 `vs2 ++ env2` >>
       qspecl_then [`s21.clock`, `[body]`, `vs1 ++ env1`, `s11`, `[body']`,
                    `vs2 ++ env2`, `s21`] mp_tac unused_vars_correct2 >>
       `every_Fn_vs_NONE [body']` by metis_tac[every_Fn_vs_NONE_remove] >>
       simp[] >>
       disch_then (qspecl_then [`{ i | fv1 i body' }`, `s21.clock`] mp_tac) >>
       simp[] >>
       `s11 with clock := s21.clock = s11 ∧
        s21 with clock := s21.clock = s21` by simp[state_component_equality] >>
       imp_res_tac state_rel_max_app >>
       imp_res_tac evaluate_const >> fs[] >>
       simp[] >> disch_then irule >>
       qpat_x_assum `LIST_RELi _ vs1 vs2` mp_tac >>
       simp[LIST_RELi_EL_EQN, keepval_rel_def, mustkeep_def] >>
       rpt strip_tac >- imp_res_tac LIST_REL_LENGTH >>
       Cases_on `k < LENGTH vs2` >> simp[EL_APPEND2, EL_APPEND1]
       >- metis_tac[remove_fv,fv1_intro] >>
       full_simp_tac(srw_ss())[LIST_REL_EL_EQN] >> irule (CONJUNCT1 val_rel_mono) >>
       qexists_tac `i` >> simp[] >> imp_res_tac evaluate_clock >> lfs[]) >>
  TRY (rename1`Letrec` >>
       lfs[MAP_MAP_o, combinTheory.o_ABS_R, pairTheory.o_UNCURRY_R] >>
       rename1 `remove [body] = ([body'], body'frees)` >>
       Cases_on `no_overlap (LENGTH fns) body'frees` >> full_simp_tac(srw_ss())[]
       >- (srw_tac[][] >> simp[exp_rel_def, exec_rel_rw, evaluate_ev_def] >>
           qx_genl_tac [`i`, `env1`, `env2`, `s1`, `s2`] >> strip_tac >>
           qx_gen_tac `j` >> strip_tac >>
           simp[evaluate_def, evaluate_REPconst0s] >> srw_tac[][] >>
           imp_res_tac state_rel_max_app >> rveq >>
           irule unused_vars_correct2 >> simp[]
           >- metis_tac[every_Fn_vs_NONE_remove] >>
           map_every qexists_tac
             [`i`, `IMAGE ((+) (LENGTH fns)) UNIV`] >> simp[] >>
           conj_tac
           >- (full_simp_tac(srw_ss())[no_overlap_DISJOINT] >> qx_gen_tac `V` >>
               first_assum (assume_tac o MATCH_MP remove_fv) >>
               strip_tac >> `has_var V body'frees` by rev_full_simp_tac(srw_ss())[] >>
               full_simp_tac(srw_ss())[DISJOINT_DEF, EXTENSION] >>
               `¬(V < LENGTH fns)` by metis_tac[] >>
               qexists_tac `V - LENGTH fns` >> simp[]) >>
           irule LIST_RELi_APPEND_I
           >- simp[LIST_RELi_EL_EQN, LENGTH_REPLICATE] >>
           full_simp_tac(srw_ss())[LIST_REL_EL_EQN, LIST_RELi_EL_EQN]) >>
       srw_tac[][] >> simp[UNCURRY] >>
       FIRST (map irule (List.drop(CONJUNCTS compat, 2))) >> simp[] >>
       full_simp_tac(srw_ss())[Once every_Fn_vs_NONE_EVERY, LIST_REL_EL_EQN, EL_MAP, EVERY_MEM,
          MEM_MAP, PULL_EXISTS, FORALL_PROD] >>
       qx_gen_tac `mm` >> strip_tac >>
       `∃mn mf. EL mm fns = (mn, mf)` by metis_tac[pair_CASES] >> full_simp_tac(srw_ss())[] >>
       `∃mf' mf'frees. remove [mf] = ([mf'], mf'frees)`
          by metis_tac[remove_SING, pair_CASES] >> simp[] >>
       metis_tac[MEM_EL]) >>
 metis_tac[compat]);

val compile_correct = Q.store_thm("compile_correct",
  `∀do_remove es es' s.
    every_Fn_vs_NONE (MAP (SND o SND) es) ⇒
    clos_remove$compile do_remove es = es' ⇒
    LIST_REL (λ(n,m,e) (n',m',e'). n = n' ∧ m = m' ∧ exp_rel (:'ffi) w [e] [e']) es es'`,
  reverse Cases>>fs[clos_removeTheory.compile_def]
  >-
    (rw[]>>
    match_mp_tac refl_list_rel_refl>>
    simp[FORALL_PROD,exp_rel_refl])>>
  Induct>>rw[]>- EVAL_TAC>>
  fs[Once every_Fn_vs_NONE_CONS]>>
  simp[Once remove_CONS]>>
  PairCases_on`h`>>fs[]>>
  imp_res_tac remove_correct>>
  Cases_on`remove [h2]`>>fs[]>>
  imp_res_tac remove_SING>>
  fs[]);

val k_intro = Q.prove(`(λn. x) = K x`, simp[FUN_EQ_THM])

val code_locs_const_0 = Q.store_thm("code_locs_const_0[simp]",
  `code_locs [const_0] = []`,
  EVAL_TAC)

val code_loc'_const_0 = Q.store_thm(
  "code_loc'_const_0[simp]",
  `code_loc' const_0 = []`,
  simp[const_0_def]);

val code_locs_REPLICATE_const_0 = Q.store_thm("code_locs_REPLICATE_const_0[simp]",
  `code_locs (REPLICATE n const_0) = []`,
  Induct_on`n`>>srw_tac[][REPLICATE,code_locs_def]>>
  srw_tac[][code_locs_cons])

val code_locs_FST_remove_sing = Q.store_thm(
  "code_locs_FST_remove_sing",
  `code_locs (FST (remove [e])) = code_loc' (HD (FST (remove [e])))`,
  Cases_on `remove [e]` >> imp_res_tac remove_SING >> simp[]);

fun qccase q = rename1 q >> Cases_on q

val remove_distinct_locs = Q.store_thm("remove_distinct_locs",
  `∀es.
    set (code_locs (FST (remove es))) ⊆ set (code_locs es) ∧
    (ALL_DISTINCT (code_locs es) ⇒ ALL_DISTINCT (code_locs (FST (remove es))))`,
  ho_match_mp_tac remove_ind >> simp[remove_def, code_locs_def] >>
  rpt conj_tac >> rpt gen_tac >> disch_then strip_assume_tac
  >- (rename1 `remove[x]` >> Cases_on `remove[x]` >> full_simp_tac(srw_ss())[] >>
      rename1 `remove (y::xs)` >> Cases_on `remove(y::xs)` >>
      full_simp_tac(srw_ss())[code_locs_append, ALL_DISTINCT_APPEND] >> full_simp_tac(srw_ss())[SUBSET_DEF] >>
      metis_tac[])
  >- ((* if *) qccase `remove[x1]` >> full_simp_tac(srw_ss())[] >>
      qccase `remove[x2]` >> full_simp_tac(srw_ss())[] >>
      qccase `remove[x3]` >> full_simp_tac(srw_ss())[] >> imp_res_tac remove_SING >>
      srw_tac[][code_locs_def, LET_THM, ALL_DISTINCT_APPEND] >>
      full_simp_tac(srw_ss())[SUBSET_DEF] >> metis_tac[])
  >- ((* let *) qccase `remove[body]` >> full_simp_tac(srw_ss())[] >>
      simp[db_varsTheory.FOLDR_mk_Union_UNZIP, ALL_DISTINCT_APPEND, FPAIR, FST_UNZIP_MAPi,
           combinTheory.o_ABS_R] >>
      simp[code_locs_MAPi, MEM_FLAT, MEM_MAPi, PULL_EXISTS, SUBSET_DEF] >>
      imp_res_tac remove_SING >> var_eq_tac >> full_simp_tac(srw_ss())[code_locs_FST_remove_sing] >>
      srw_tac[][]
      >- metis_tac[MEM_EL, SUBSET_DEF, code_locs_MEM_SUBSET]
      >- metis_tac[MEM_EL, SUBSET_DEF, code_locs_MEM_SUBSET]
      >- metis_tac[MEM_EL, SUBSET_DEF, code_locs_MEM_SUBSET]
      >- (simp[ALL_DISTINCT_FLAT, MEM_MAPi, EL_MAPi, PULL_EXISTS] >>
          lfs[code_locs_FLAT_MAP, ALL_DISTINCT_FLAT, MEM_MAP, PULL_EXISTS,
              EL_MAP, MEM_FLAT] >> conj_tac >- (srw_tac[][] >> metis_tac[MEM_EL]) >>
          srw_tac[][] >>
          rename1 `j < LENGTH xs` >> rename1 `i < j` >>
          `i < LENGTH xs` by simp[] >>
          `MEM (EL i xs) xs ∧ MEM (EL j xs) xs` by metis_tac[MEM_EL] >>
          metis_tac[SUBSET_DEF])
      >- (pop_assum mp_tac >> srw_tac[][] >>
          full_simp_tac(srw_ss())[code_locs_FLAT_MAP, MEM_FLAT, PULL_EXISTS, MEM_MAP] >>
          metis_tac[MEM_EL, SUBSET_DEF]))
  >- ((* raise *) qccase `remove[exn]` >> imp_res_tac remove_SING >>
      var_eq_tac >> full_simp_tac(srw_ss())[])
  >- ((* tick *) qccase `remove[tickc]` >> imp_res_tac remove_SING >>
      var_eq_tac >> full_simp_tac(srw_ss())[])
  >- ((* Op *) qccase `remove args` >> full_simp_tac(srw_ss())[])
  >- ((* App *) qccase `remove [f]` >> imp_res_tac remove_SING >>
      var_eq_tac >> full_simp_tac(srw_ss())[] >>
      qccase `remove args` >> full_simp_tac(srw_ss())[ALL_DISTINCT_APPEND, SUBSET_DEF] >>
      metis_tac[])
  >- ((* Fn *) qccase `remove[body]` >> imp_res_tac remove_SING >>
      var_eq_tac >> full_simp_tac(srw_ss())[ALL_DISTINCT_APPEND] >>
      full_simp_tac(srw_ss())[SUBSET_DEF] >> metis_tac[])
  >- ((* Letrec *) qccase `remove[body]` >> imp_res_tac remove_SING >>
      var_eq_tac >> full_simp_tac(srw_ss())[code_locs_FST_remove_sing] >>
      srw_tac[][]
      >- full_simp_tac(srw_ss())[SUBSET_DEF]
      >- (simp[MAP_MAP_o, combinTheory.o_ABS_R, pairTheory.o_UNCURRY_R,
               UNCURRY] >>
          qmatch_abbrev_tac `S1 ⊆ S2 ∪ _ ∪ _` >>
          `S1 ⊆ S2` suffices_by simp[SUBSET_DEF] >>
          simp[Abbr`S1`, Abbr`S2`, SUBSET_DEF] >>
          dsimp[code_locs_FLAT_MAP, MEM_FLAT, MEM_MAP, FORALL_PROD,
                EXISTS_PROD] >> full_simp_tac(srw_ss())[SUBSET_DEF]>> metis_tac[])
      >- simp[SUBSET_DEF]
      >- full_simp_tac(srw_ss())[SUBSET_DEF]
      >- full_simp_tac(srw_ss())[ALL_DISTINCT_APPEND]
      >- (simp[ALL_DISTINCT_APPEND, MAP_MAP_o, combinTheory.o_ABS_R,
               pairTheory.o_UNCURRY_R] >> simp[UNCURRY] >>
          simp[MEM_GENLIST] >> full_simp_tac(srw_ss())[ALL_DISTINCT_APPEND] >> dsimp[] >>
          simp[code_locs_FLAT_MAP, ALL_DISTINCT_FLAT, EL_MAP, MEM_MAP] >>
          dsimp[FORALL_PROD, MEM_FLAT, MEM_MAP] >> rpt strip_tac
          >- (full_simp_tac(srw_ss())[ALL_DISTINCT_FLAT, code_locs_FLAT_MAP, MEM_MAP, PULL_EXISTS,
                 FORALL_PROD] >> metis_tac[])
          >- (lfs[ALL_DISTINCT_FLAT, code_locs_FLAT_MAP, MEM_MAP, PULL_EXISTS,
                  FORALL_PROD, UNCURRY, EL_MAP] >>
              rename1 `bb < LENGTH fns` >>
              rename1 `aa < bb` >>
              `(∃aan aaf. EL aa fns = (aan, aaf)) ∧
               (∃bbn bbf. EL bb fns = (bbn, bbf))` by metis_tac[PAIR] >>
              full_simp_tac(srw_ss())[] >> `aa < LENGTH fns` by simp[] >>
              metis_tac[SUBSET_DEF, MEM_EL, FST, SND])
          >- (lfs[MEM_GENLIST, DISJ_IMP_THM, FORALL_AND_THM, PULL_EXISTS,
                  code_locs_FLAT_MAP, MEM_MAP, MEM_FLAT, FORALL_PROD] >>
              metis_tac[SUBSET_DEF])
          >- (lfs[code_locs_FLAT_MAP, MEM_MAP, MEM_FLAT, FORALL_PROD,
                  DISJ_IMP_THM, FORALL_AND_THM, PULL_EXISTS] >>
              metis_tac[SUBSET_DEF])
          >- (lfs[MEM_GENLIST, DISJ_IMP_THM, FORALL_AND_THM, PULL_EXISTS] >>
              metis_tac[SUBSET_DEF])))
  >- ((* handle *)
      qccase `remove [E1]` >> imp_res_tac remove_SING >> var_eq_tac >> full_simp_tac(srw_ss())[] >>
      qccase `remove [E2]` >> imp_res_tac remove_SING >> var_eq_tac >> full_simp_tac(srw_ss())[] >>
      full_simp_tac(srw_ss())[SUBSET_DEF, ALL_DISTINCT_APPEND] >> metis_tac[])
  >- ((* call *) qccase `remove args` >> full_simp_tac(srw_ss())[]))

val compile_distinct_locs = Q.store_thm("compile_distinct_locs",
  `∀do_remove es.
    set (code_locs (MAP (SND o SND) (clos_remove$compile do_remove es))) ⊆
    set (code_locs (MAP (SND o SND) es)) ∧
    (ALL_DISTINCT (code_locs (MAP (SND o SND) es)) ⇒
     ALL_DISTINCT (code_locs (MAP (SND o SND) (clos_remove$compile do_remove es))))`,
  Cases>>fs[clos_removeTheory.compile_def]>>
  make_SND_tac>>
  metis_tac[FST,PAIR,remove_distinct_locs])

val every_Fn_SOME_const_0 = Q.store_thm("every_Fn_SOME_const_0[simp]",
  `every_Fn_SOME [const_0]`,
  EVAL_TAC)

val every_Fn_SOME_remove = Q.store_thm("every_Fn_SOME_remove",
  `∀es es' s.
   every_Fn_SOME es ⇒
   remove es = (es',s) ⇒
   every_Fn_SOME es'`,
  ho_match_mp_tac remove_ind >>
  srw_tac[][remove_def] >> full_simp_tac(srw_ss())[LET_THM] >>
  rpt(first_assum(split_uncurry_arg_tac o lhs o concl) >> full_simp_tac(srw_ss())[]) >>
  imp_res_tac remove_SING >>
  rpt var_eq_tac >> full_simp_tac(srw_ss())[] >>
  every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
  rpt(first_assum(split_uncurry_arg_tac o lhs o concl) >> full_simp_tac(srw_ss())[]) >> srw_tac[][] >>
  ONCE_REWRITE_TAC[every_Fn_SOME_EVERY] >>
  simp[EVERY_REPLICATE,EVERY_MAP,UNCURRY] >>
  simp[GSYM every_Fn_SOME_EVERY] >>
  full_simp_tac(srw_ss())[db_varsTheory.FOLDR_mk_Union_UNZIP,FPAIR,LET_THM,UNCURRY,FST_UNZIP_MAPi,
     SND_UNZIP_MAPi,o_ABS_R] >> rpt var_eq_tac >>
  ONCE_REWRITE_TAC[every_Fn_SOME_EVERY] >>
  simp[EVERY_MEM,MEM_MAPi,PULL_EXISTS] >> srw_tac[][] >>
  simp[UNCURRY] >> srw_tac[][] >>
  full_simp_tac(srw_ss())[MEM_EL,PULL_EXISTS] >>
  last_x_assum(match_mp_tac o MP_CANON) >>
  asm_exists_tac >> simp[] >>
  srw_tac[QUANT_INST_ss[pair_default_qp]][] >>
  full_simp_tac(srw_ss())[Once every_Fn_SOME_EVERY,EVERY_MAP,EVERY_MEM,MEM_EL,PULL_EXISTS] >>
  metis_tac[remove_SING,HD,SND,PAIR]);

val every_Fn_SOME_compile = Q.store_thm("every_Fn_SOME_compile",
  `∀do_remove es es'.
   every_Fn_SOME (MAP (SND o SND) es) ⇒
   clos_remove$compile do_remove es = es' ⇒
   every_Fn_SOME (MAP (SND o SND) es')`,
  Cases>>fs[clos_removeTheory.compile_def]>>
  make_SND_tac>>
  metis_tac[FST,PAIR,every_Fn_SOME_remove])

val _ = export_theory();

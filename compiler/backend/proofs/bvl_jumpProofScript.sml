open preamble bvl_jumpTheory bvlSemTheory bvlPropsTheory;

val _ = new_theory"bvl_jumpProof";

val evaluate_JumpList = prove(
  ``!n xs k.
      k < LENGTH xs ==>
      (evaluate ([JumpList n xs],Number (&(n+k))::env,s) =
       evaluate ([EL k xs],Number (&(n+k))::env,s))``,
  recInduct JumpList_ind \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[]
  \\ SIMP_TAC std_ss [Once JumpList_def,LET_DEF]
  \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[evaluate_def,do_app_def]
  \\ Q.ISPEC_THEN`xs`strip_assume_tac SPLIT_LIST
  \\ FULL_SIMP_TAC std_ss []
  \\ `(LENGTH ys = 0) ==> LENGTH zs <> 0` by (full_simp_tac(srw_ss())[] \\ DECIDE_TAC)
  \\ NTAC 2 (POP_ASSUM MP_TAC) \\ NTAC 3 (POP_ASSUM (K ALL_TAC))
  \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[TAKE_LENGTH_APPEND,DROP_LENGTH_APPEND]
  \\ Cases_on `k < LENGTH ys` \\ full_simp_tac(srw_ss())[]
  \\ IMP_RES_TAC EL_APPEND1 \\ full_simp_tac(srw_ss())[]
  \\ `k - LENGTH ys < LENGTH zs` by DECIDE_TAC \\ RES_TAC
  \\ `n + LENGTH ys + (k - LENGTH ys) = n + k` by DECIDE_TAC
  \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[NOT_LESS]
  \\ IMP_RES_TAC EL_APPEND2 \\ full_simp_tac(srw_ss())[]);

val evaluate_Jump = store_thm("evaluate_Jump",
  ``(evaluate ([x],env,s) = (Rval [Number (&n)],t)) /\
    n < LENGTH xs ==>
    (evaluate ([Jump x xs],env,s) =
     evaluate ([EL n xs],Number (&n) :: env,t))``,
  full_simp_tac(srw_ss())[evaluate_def,Jump_def] \\ REPEAT STRIP_TAC
  \\ IMP_RES_TAC evaluate_JumpList
  \\ POP_ASSUM (ASSUME_TAC o Q.SPECL [`t`,`0`]) \\ full_simp_tac(srw_ss())[]);

val _ = export_theory();

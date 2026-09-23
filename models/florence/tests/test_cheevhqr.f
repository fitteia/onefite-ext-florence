      PROGRAM TEST_CHEEVHQR
C     Split-real-arithmetic rewrite of CHEEVHQ: CHTRIDR (Householder
C     tridiagonalization) + TRIDQLR (implicit QL), both operating on
C     separate real/imaginary DOUBLE PRECISION arrays instead of
C     native COMPLEX*16 - matching a structural technique observed by
C     analyzing (not copying) the original NAG code, which never used
C     native complex arithmetic either. This is a well-known, generic
C     1970s-80s Fortran performance idiom (compilers of that era, and
C     to some extent still today, don't always optimize native complex
C     arithmetic as well as manually-unrolled real arithmetic) - not
C     NAG-specific IP. Every formula here is re-derived from CHTRID/
C     TRIDQL_Z's own already-verified complex formulas by hand-
C     expanding each complex multiply/add into its real and imaginary
C     components; nothing is transcribed from NAG's source.
      IMPLICIT NONE
      LOGICAL ALLPASS
      ALLPASS = .TRUE.
      CALL CASE_DIAGONAL(ALLPASS)
      CALL CASE_NONDIAGONAL(ALLPASS)
      CALL SWEEP_VS_ZHEEV(ALLPASS)
      IF (ALLPASS) THEN
         WRITE(*,*) 'PASS: CHEEVHQR known-answer + sweep tests'
      ELSE
         WRITE(*,*) 'FAIL: CHEEVHQR known-answer + sweep tests'
         STOP 1
      ENDIF
      END

      SUBROUTINE CASE_DIAGONAL(ALLPASS)
      IMPLICIT NONE
      LOGICAL ALLPASS
      INTEGER N, I, J, INFO
      PARAMETER (N=3)
      DOUBLE PRECISION AR(N,N), AI(N,N), W(N), EXPECT(N), ERR
      DO 20 J = 1, N
         DO 10 I = 1, N
            AR(I,J) = 0.0D0
            AI(I,J) = 0.0D0
   10    CONTINUE
   20 CONTINUE
      AR(1,1) = 2.0D0
      AR(2,2) = 3.0D0
      AR(3,3) = 5.0D0
      EXPECT(1) = 2.0D0
      EXPECT(2) = 3.0D0
      EXPECT(3) = 5.0D0
      CALL CHEEVHQR(N, AR, AI, N, W, INFO)
      ERR = 0.0D0
      DO 30 I = 1, N
         ERR = MAX(ERR, DABS(W(I)-EXPECT(I)))
   30 CONTINUE
      WRITE(*,*) 'CASE_DIAGONAL info=', INFO, ' err=', ERR
      IF (INFO.NE.0 .OR. ERR.GT.1.0D-12) THEN
         WRITE(*,*) '  CASE_DIAGONAL FAIL'
         ALLPASS = .FALSE.
      ELSE
         WRITE(*,*) '  CASE_DIAGONAL PASS'
      ENDIF
      RETURN
      END

      SUBROUTINE CASE_NONDIAGONAL(ALLPASS)
      IMPLICIT NONE
      LOGICAL ALLPASS
      INTEGER N, INFO
      PARAMETER (N=2)
      DOUBLE PRECISION AR(N,N), AI(N,N), W(N)
      DOUBLE PRECISION SQ2, ERR
      SQ2 = DSQRT(2.0D0)
      AR(1,1) = 0.0D0
      AI(1,1) = 0.0D0
      AR(2,2) = 0.0D0
      AI(2,2) = 0.0D0
      AR(1,2) = 1.0D0
      AI(1,2) = -1.0D0
      AR(2,1) = 1.0D0
      AI(2,1) = 1.0D0
      CALL CHEEVHQR(N, AR, AI, N, W, INFO)
      ERR = MAX(DABS(W(1)-(-SQ2)), DABS(W(2)-SQ2))
      WRITE(*,*) 'CASE_NONDIAGONAL info=', INFO, ' err=', ERR
      IF (INFO.NE.0 .OR. ERR.GT.1.0D-12) THEN
         WRITE(*,*) '  CASE_NONDIAGONAL FAIL'
         ALLPASS = .FALSE.
      ELSE
         WRITE(*,*) '  CASE_NONDIAGONAL PASS'
      ENDIF
      RETURN
      END

      SUBROUTINE SWEEP_VS_ZHEEV(ALLPASS)
      IMPLICIT NONE
      LOGICAL ALLPASS
      INTEGER NMAX, NTRIAL, N, ITRIAL, I, J, K, INFO, INFOZ
      PARAMETER (NMAX=30, NTRIAL=30)
      DOUBLE PRECISION AR(NMAX,NMAX), AI(NMAX,NMAX)
      DOUBLE PRECISION ARSAVE(NMAX,NMAX), AISAVE(NMAX,NMAX)
      DOUBLE PRECISION ARREC(NMAX,NMAX), AIREC(NMAX,NMAX)
      COMPLEX*16 ZA(NMAX,NMAX), WORK(4*NMAX)
      DOUBLE PRECISION RWORK(3*NMAX-2)
      DOUBLE PRECISION W(NMAX), WZ(NMAX)
      DOUBLE PRECISION EIGERR, RECERR, WORSTEIG, WORSTREC
      DOUBLE PRECISION X, Y

      WORSTEIG = 0.0D0
      WORSTREC = 0.0D0

      DO 200 N = 2, NMAX
         DO 190 ITRIAL = 1, NTRIAL
            DO 110 J = 1, N
               CALL RANDOM_NUMBER(X)
               ARSAVE(J,J) = 2.0D0*X-1.0D0
               AISAVE(J,J) = 0.0D0
               DO 100 I = J+1, N
                  CALL RANDOM_NUMBER(X)
                  CALL RANDOM_NUMBER(Y)
                  ARSAVE(I,J) = 2.0D0*X-1.0D0
                  AISAVE(I,J) = 2.0D0*Y-1.0D0
                  ARSAVE(J,I) = ARSAVE(I,J)
                  AISAVE(J,I) = -AISAVE(I,J)
  100          CONTINUE
  110       CONTINUE

            DO 130 J = 1, N
               DO 120 I = 1, N
                  AR(I,J) = ARSAVE(I,J)
                  AI(I,J) = AISAVE(I,J)
                  ZA(I,J) = DCMPLX(ARSAVE(I,J),AISAVE(I,J))
  120          CONTINUE
  130       CONTINUE

            CALL CHEEVHQR(N, AR, AI, NMAX, W, INFO)
            CALL ZHEEV('V','L',N,ZA,NMAX,WZ,WORK,4*NMAX,RWORK,INFOZ)

            IF (INFO.NE.0 .OR. INFOZ.NE.0) THEN
               WRITE(*,*) 'SWEEP: solver failure N=',N,
     *                    ' trial=',ITRIAL,' info=',INFO,
     *                    ' infoz=',INFOZ
               ALLPASS = .FALSE.
               GOTO 190
            ENDIF

            EIGERR = 0.0D0
            DO 140 I = 1, N
               EIGERR = MAX(EIGERR, DABS(W(I)-WZ(I)))
  140       CONTINUE
            IF (EIGERR.GT.WORSTEIG) WORSTEIG = EIGERR

C           Reconstruction: AR/AI now hold eigenvectors (real/imag).
C           AREC = V * diag(W) * V^H should equal the original matrix.
            DO 165 J = 1, N
               DO 160 I = 1, N
                  ARREC(I,J) = 0.0D0
                  AIREC(I,J) = 0.0D0
                  DO 150 K = 1, N
C                    term = V(I,K)*W(K)*conj(V(J,K))
C                    V(I,K)=(AR(I,K),AI(I,K)), conj(V(J,K)) =
C                    (AR(J,K),-AI(J,K))
                     ARREC(I,J) = ARREC(I,J) + W(K)*
     *                    (AR(I,K)*AR(J,K) + AI(I,K)*AI(J,K))
                     AIREC(I,J) = AIREC(I,J) + W(K)*
     *                    (AI(I,K)*AR(J,K) - AR(I,K)*AI(J,K))
  150             CONTINUE
  160          CONTINUE
  165       CONTINUE

            RECERR = 0.0D0
            DO 180 J = 1, N
               DO 170 I = 1, N
                  RECERR = MAX(RECERR, DABS(ARREC(I,J)-ARSAVE(I,J)))
                  RECERR = MAX(RECERR, DABS(AIREC(I,J)-AISAVE(I,J)))
  170          CONTINUE
  180       CONTINUE
            IF (RECERR.GT.WORSTREC) WORSTREC = RECERR

            IF (EIGERR.GT.1.0D-9 .OR. RECERR.GT.1.0D-9) THEN
               WRITE(*,*) 'SWEEP FAIL N=',N,' trial=',ITRIAL,
     *                    ' eigerr=',EIGERR,' recerr=',RECERR
               ALLPASS = .FALSE.
            ENDIF
  190    CONTINUE
  200 CONTINUE

      WRITE(*,*) 'SWEEP worst eigerr=', WORSTEIG,
     *           ' worst recerr=', WORSTREC
      IF (WORSTEIG.LE.1.0D-9 .AND. WORSTREC.LE.1.0D-9) THEN
         WRITE(*,*) '  SWEEP PASS'
      ELSE
         WRITE(*,*) '  SWEEP FAIL'
      ENDIF
      RETURN
      END

      SUBROUTINE CHEEVHQR(N, AR, AI, LDA, W, INFO)
C     Complex Hermitian eigensolver, split-real-arithmetic version:
C     CHTRIDR (Householder tridiagonalization) + TRIDQLR (implicit QL
C     with Wilkinson shifts), both using separate real/imaginary
C     DOUBLE PRECISION arrays instead of COMPLEX*16 throughout - see
C     this file's top-of-file comment for why. AR/AI(LDA,N) Hermitian
C     on entry (both triangles populated); on exit hold the
C     eigenvectors (real/imaginary parts), sorted to match W ascending.
      IMPLICIT NONE
      INTEGER N, LDA, INFO
      DOUBLE PRECISION AR(LDA,N), AI(LDA,N), W(N)
      DOUBLE PRECISION D(N), E(N)
      INTEGER I, J, K
      DOUBLE PRECISION TK1

      CALL CHTRIDR(N, AR, AI, LDA, D, E, INFO)
      IF (INFO.NE.0) RETURN
      CALL TRIDQLR(N, D, E, AR, AI, LDA, INFO)
      IF (INFO.NE.0) RETURN

      DO 20 I = 1, N-1
         K = I
         DO 10 J = I+1, N
            IF (D(J).LT.D(K)) K = J
   10    CONTINUE
         IF (K.NE.I) THEN
            E(1) = D(I)
            D(I) = D(K)
            D(K) = E(1)
            DO 15 J = 1, N
               TK1 = AR(J,I)
               AR(J,I) = AR(J,K)
               AR(J,K) = TK1
               TK1 = AI(J,I)
               AI(J,I) = AI(J,K)
               AI(J,K) = TK1
   15       CONTINUE
         ENDIF
   20 CONTINUE

      DO 30 I = 1, N
         W(I) = D(I)
   30 CONTINUE
      RETURN
      END

      SUBROUTINE TRIDQLR(N, D, E, ZR, ZI, LDZ, INFO)
C     Same recurrence as TRIDQL (real symmetric tridiagonal, implicit
C     QL with Wilkinson shifts - all of that is already real
C     arithmetic, unaffected by this rewrite). Only the eigenvector
C     accumulation changes: ZR/ZI (real/imaginary parts) are rotated
C     together in the same loop, since rotating a complex vector by a
C     real Givens rotation decomposes exactly into two independent
C     real rotations on its real and imaginary parts - an elementary
C     mathematical fact, not an implementation choice borrowed from
C     anywhere.
      IMPLICIT NONE
      INTEGER N, LDZ, INFO
      DOUBLE PRECISION D(N), E(N), ZR(LDZ,N), ZI(LDZ,N)
      INTEGER I, K, L, M, ITER
      DOUBLE PRECISION B, C, F, G, P, R, S, DD, HR, HI

      INFO = 0
      IF (N.EQ.1) RETURN
      E(N) = 0.0D0

      DO 50 L = 1, N
         ITER = 0
   10    CONTINUE
         DO 20 M = L, N-1
            DD = DABS(D(M)) + DABS(D(M+1))
            IF (DABS(E(M)) .LE. 1.0D-15*DD) GOTO 30
   20    CONTINUE
         M = N
   30    CONTINUE
         IF (M.EQ.L) GOTO 50

         IF (ITER.EQ.30) THEN
            INFO = 1
            RETURN
         ENDIF
         ITER = ITER + 1

         G = (D(L+1)-D(L)) / (2.0D0*E(L))
         R = DSQRT(G*G+1.0D0)
         IF (G.GE.0.0D0) THEN
            G = D(M) - D(L) + E(L)/(G+DABS(R))
         ELSE
            G = D(M) - D(L) + E(L)/(G-DABS(R))
         ENDIF
         S = 1.0D0
         C = 1.0D0
         P = 0.0D0

         DO 40 I = M-1, L, -1
            F = S*E(I)
            B = C*E(I)
            IF (DABS(F).GE.DABS(G)) THEN
               C = G/F
               R = DSQRT(C*C+1.0D0)
               E(I+1) = F*R
               S = 1.0D0/R
               C = C*S
            ELSE
               S = F/G
               R = DSQRT(S*S+1.0D0)
               E(I+1) = G*R
               C = 1.0D0/R
               S = S*C
            ENDIF
            G = D(I+1) - P
            R = (D(I)-G)*S + 2.0D0*C*B
            P = S*R
            D(I+1) = G + P
            G = C*R - B

            DO 35 K = 1, N
               HR = ZR(K,I+1)
               ZR(K,I+1) = S*ZR(K,I) + C*HR
               ZR(K,I) = C*ZR(K,I) - S*HR
               HI = ZI(K,I+1)
               ZI(K,I+1) = S*ZI(K,I) + C*HI
               ZI(K,I) = C*ZI(K,I) - S*HI
   35       CONTINUE
   40    CONTINUE

         D(L) = D(L) - P
         E(L) = G
         E(M) = 0.0D0
         GOTO 10
   50 CONTINUE

      RETURN
      END

      SUBROUTINE CHTRIDR(N, AR, AI, LDA, D, E, INFO)
C     Householder tridiagonalization, split-real-arithmetic version of
C     CHTRID. Every formula here is CHTRID's own (already independently
C     verified) complex arithmetic hand-expanded into real/imaginary
C     components - see this file's top comment.
      IMPLICIT NONE
      INTEGER N, LDA, INFO
      DOUBLE PRECISION AR(LDA,N), AI(LDA,N)
      DOUBLE PRECISION D(N), E(N)
      INTEGER I, J, K, M
      DOUBLE PRECISION NRM, VNORM2, ZMAG, CDX1
      DOUBLE PRECISION X1R, X1I, PHASE1R, PHASE1I, BETAR, BETAI
      DOUBLE PRECISION TAU, ALPHASCR, ALPHASCI
      DOUBLE PRECISION VR(N), VI(N), WR(N), WI(N), PR(N), PI(N)
      DOUBLE PRECISION ZR, ZI, YR, YI
      DOUBLE PRECISION QR(N,N), QI(N,N)

      INFO = 0

      DO 20 J = 1, N
         DO 10 I = 1, N
            QR(I,J) = 0.0D0
            QI(I,J) = 0.0D0
   10    CONTINUE
         QR(J,J) = 1.0D0
   20 CONTINUE

      IF (N.LE.2) GOTO 400

      DO 300 K = 1, N-2
         M = N - K
         NRM = 0.0D0
         DO 30 I = K+1, N
            NRM = NRM + AR(I,K)**2 + AI(I,K)**2
   30    CONTINUE
         NRM = DSQRT(NRM)
         IF (NRM.EQ.0.0D0) GOTO 300

         X1R = AR(K+1,K)
         X1I = AI(K+1,K)
         CDX1 = DSQRT(X1R*X1R+X1I*X1I)
         IF (CDX1.EQ.0.0D0) THEN
            PHASE1R = 1.0D0
            PHASE1I = 0.0D0
         ELSE
            PHASE1R = X1R/CDX1
            PHASE1I = X1I/CDX1
         ENDIF
         BETAR = -PHASE1R*NRM
         BETAI = -PHASE1I*NRM

         VR(1) = X1R - BETAR
         VI(1) = X1I - BETAI
         DO 40 I = 2, M
            VR(I) = AR(K+I,K)
            VI(I) = AI(K+I,K)
   40    CONTINUE
         VNORM2 = 0.0D0
         DO 50 I = 1, M
            VNORM2 = VNORM2 + VR(I)**2 + VI(I)**2
   50    CONTINUE
         IF (VNORM2.EQ.0.0D0) GOTO 300
         TAU = 2.0D0/VNORM2

         DO 70 I = 1, M
            WR(I) = 0.0D0
            WI(I) = 0.0D0
            DO 60 J = 1, M
               WR(I) = WR(I) + AR(K+I,K+J)*VR(J) - AI(K+I,K+J)*VI(J)
               WI(I) = WI(I) + AR(K+I,K+J)*VI(J) + AI(K+I,K+J)*VR(J)
   60       CONTINUE
            WR(I) = WR(I)*TAU
            WI(I) = WI(I)*TAU
   70    CONTINUE

         ALPHASCR = 0.0D0
         ALPHASCI = 0.0D0
         DO 80 I = 1, M
            ALPHASCR = ALPHASCR + VR(I)*WR(I) + VI(I)*WI(I)
            ALPHASCI = ALPHASCI + VR(I)*WI(I) - VI(I)*WR(I)
   80    CONTINUE
         ALPHASCR = ALPHASCR*TAU*0.5D0
         ALPHASCI = ALPHASCI*TAU*0.5D0

         DO 90 I = 1, M
            PR(I) = WR(I) - (ALPHASCR*VR(I)-ALPHASCI*VI(I))
            PI(I) = WI(I) - (ALPHASCR*VI(I)+ALPHASCI*VR(I))
   90    CONTINUE

         DO 110 J = 1, M
            DO 100 I = 1, M
               AR(K+I,K+J) = AR(K+I,K+J)
     *              - (VR(I)*PR(J)+VI(I)*PI(J))
     *              - (PR(I)*VR(J)+PI(I)*VI(J))
               AI(K+I,K+J) = AI(K+I,K+J)
     *              - (VI(I)*PR(J)-VR(I)*PI(J))
     *              - (PI(I)*VR(J)-PR(I)*VI(J))
  100       CONTINUE
  110    CONTINUE

         AR(K+1,K) = BETAR
         AI(K+1,K) = BETAI
         AR(K,K+1) = BETAR
         AI(K,K+1) = -BETAI
         DO 120 I = K+2, N
            AR(I,K) = 0.0D0
            AI(I,K) = 0.0D0
            AR(K,I) = 0.0D0
            AI(K,I) = 0.0D0
  120    CONTINUE

         DO 140 I = 1, N
            ZR = 0.0D0
            ZI = 0.0D0
            DO 130 J = 1, M
               ZR = ZR + QR(I,K+J)*VR(J) - QI(I,K+J)*VI(J)
               ZI = ZI + QR(I,K+J)*VI(J) + QI(I,K+J)*VR(J)
  130       CONTINUE
            ZR = ZR*TAU
            ZI = ZI*TAU
            DO 135 J = 1, M
               QR(I,K+J) = QR(I,K+J) - (ZR*VR(J)+ZI*VI(J))
               QI(I,K+J) = QI(I,K+J) - (ZI*VR(J)-ZR*VI(J))
  135       CONTINUE
  140    CONTINUE
  300 CONTINUE

  400 CONTINUE
      DO 410 I = 1, N
         D(I) = AR(I,I)
  410 CONTINUE
      DO 420 I = 1, N-1
         E(I) = 0.0D0
  420 CONTINUE

      IF (N.GE.2) THEN
         PR(1) = 1.0D0
         PI(1) = 0.0D0
         DO 430 K = 1, N-1
            YR = AR(K+1,K)*PR(K) - AI(K+1,K)*PI(K)
            YI = AR(K+1,K)*PI(K) + AI(K+1,K)*PR(K)
            ZMAG = DSQRT(YR*YR+YI*YI)
            IF (ZMAG.EQ.0.0D0) THEN
               PR(K+1) = 1.0D0
               PI(K+1) = 0.0D0
            ELSE
               PR(K+1) = YR/ZMAG
               PI(K+1) = YI/ZMAG
            ENDIF
            E(K) = ZMAG
  430    CONTINUE
         DO 450 I = 1, N
            DO 440 K = 1, N
               ZR = QR(I,K)*PR(K) - QI(I,K)*PI(K)
               ZI = QR(I,K)*PI(K) + QI(I,K)*PR(K)
               QR(I,K) = ZR
               QI(I,K) = ZI
  440       CONTINUE
  450    CONTINUE
      ENDIF

      DO 470 J = 1, N
         DO 460 I = 1, N
            AR(I,J) = QR(I,J)
            AI(I,J) = QI(I,J)
  460    CONTINUE
  470 CONTINUE

      RETURN
      END
